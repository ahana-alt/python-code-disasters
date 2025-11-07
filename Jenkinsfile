pipeline {
  agent any
  options { timestamps() }

  parameters {
    string(name: 'PROJECT_ID',   defaultValue: 'codeqa-ahana',   description: 'GCP Project')
    string(name: 'REGION',       defaultValue: 'us-central1',    description: 'GCP Region for Dataproc')
    string(name: 'CLUSTER_NAME', defaultValue: 'ahana-dp',       description: 'Dataproc cluster name (existing)')
    string(name: 'BUCKET_NAME',  defaultValue: 'ahana-dataproc-demo-bucket', description: 'GCS bucket for job I/O')

    choice(name: 'SA_CRED_KIND', choices: ['file','text'], description: 'How the SA key is stored in Jenkins')
    string(name: 'DATAPROC_SA_FILE_CRED_ID', defaultValue: 'dataproc-sa-key',     description: 'ID of Secret file cred (JSON key)')
    string(name: 'DATAPROC_SA_B64_CRED_ID',  defaultValue: 'dataproc-sa-key-b64', description: 'ID of Secret text cred (base64 of JSON key)')
  }

  environment {
    // Sonar (tool must exist in Manage Jenkins → Global Tool Configuration)
    SCANNER_HOME   = tool name: 'sonar-scanner', type: 'hudson.plugins.sonar.SonarRunnerInstallation'
    SONAR_HOST_URL = 'http://136.114.144.55:9000'
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('SonarQube Scan') {
      steps {
        // Your Sonar token in Jenkins as Secret Text (ID: final)
        withCredentials([string(credentialsId: 'final', variable: 'SONAR_TOKEN')]) {
          withSonarQubeEnv('sonar') {
            sh '''
              set -euo pipefail
              export PATH="$SCANNER_HOME/bin:$PATH"
              sonar-scanner \
                -Dsonar.projectKey=python-code-disasters \
                -Dsonar.projectName=python-code-disasters \
                -Dsonar.sources=. \
                -Dsonar.host.url="$SONAR_HOST_URL" \
                -Dsonar.token="$SONAR_TOKEN"
            '''
          }
        }
      }
    }

    stage('Quality Gate') {
      steps {
        timeout(time: 3, unit: 'MINUTES') {
          script {
            def qg = waitForQualityGate abortPipeline: false, credentialsId: 'final'
            echo "Quality Gate status: ${qg.status}"
            if (qg.status == 'OK') {
              env.QG_OK = 'true'
            } else {
              env.QG_OK = 'false'
              currentBuild.result = 'UNSTABLE'
              echo "Skipping Dataproc job because quality gate is ${qg.status}"
            }
          }
        }
      }
    }

    // Install Google Cloud SDK locally in the workspace if it's not present
    stage('Ensure gcloud') {
      when { environment name: 'QG_OK', value: 'true' }
      steps {
        sh '''
          set -euo pipefail

          if command -v gcloud >/dev/null 2>&1; then
            echo "gcloud already present:"
            gcloud version || true
            exit 0
          fi

          GCLOUD_DIR="$WORKSPACE/.gcloud"
          SDK_DIR="$GCLOUD_DIR/google-cloud-sdk"
          mkdir -p "$GCLOUD_DIR"
          cd "$GCLOUD_DIR"

          TAR="google-cloud-cli-linux-x86_64.tgz"
          # Pin to a recent stable; update if needed
          curl -fsSL -o "$TAR" https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-472.0.0-linux-x86_64.tar.gz
          tar xzf "$TAR"
          "$SDK_DIR/install.sh" --quiet || true

          # Persist PATH for later stages in this build
          echo "export PATH=\\"$SDK_DIR/bin:$PATH\\"" > "$WORKSPACE/.gcloud-path.sh"
          . "$WORKSPACE/.gcloud-path.sh"

          gcloud version
        '''
      }
    }

    stage('GCP Auth (SA)') {
      when { environment name: 'QG_OK', value: 'true' }
      steps {
        script {
          if (params.SA_CRED_KIND == 'file') {
            withCredentials([file(credentialsId: params.DATAPROC_SA_FILE_CRED_ID, variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
              sh '''
                set -euo pipefail
                [ -f "$WORKSPACE/.gcloud-path.sh" ] && . "$WORKSPACE/.gcloud-path.sh" || true

                gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS"
                gcloud config set core/project "${PROJECT_ID}"
                gcloud config set dataproc/region "${REGION}"

                gcloud auth list
              '''
            }
          } else {
            withCredentials([string(credentialsId: params.DATAPROC_SA_B64_CRED_ID, variable: 'SA_KEY_B64')]) {
              sh '''
                set -euo pipefail
                [ -f "$WORKSPACE/.gcloud-path.sh" ] && . "$WORKSPACE/.gcloud-path.sh" || true

                echo "$SA_KEY_B64" | base64 -d > sa.json
                export GOOGLE_APPLICATION_CREDENTIALS="$PWD/sa.json"
                gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS"
                gcloud config set core/project "${PROJECT_ID}"
                gcloud config set dataproc/region "${REGION}"

                gcloud auth list
              '''
            }
          }
        }
      }
    }

    stage('Run Dataproc Hadoop Job') {
      when { environment name: 'QG_OK', value: 'true' }
      steps {
        sh '''
          set -euo pipefail
          [ -f "$WORKSPACE/.gcloud-path.sh" ] && . "$WORKSPACE/.gcloud-path.sh" || true

          export REGION="${REGION}"
          export CLUSTER_NAME="${CLUSTER_NAME}"
          export BUCKET_NAME="${BUCKET_NAME}"
          export BUILD_ID="${BUILD_ID}"

          # Optional visibility
          gcloud dataproc clusters list --region="${REGION}" || true
          gsutil ls || true

          ci/run_hadoop_job.sh
        '''
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'dataproc-output.txt', onlyIfSuccessful: false
      echo "Build result: ${currentBuild.currentResult}"
    }
  }
}

