pipeline {
  agent any
  options { timestamps() }

  environment {
    // Resolve the managed tool at runtime (Pipeline step, not a shell command)
    SCANNER_HOME = tool name: 'SonarScanner', type: 'hudson.plugins.sonar.SonarRunnerInstallation'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('SonarQube Scan') {
      steps {
        withCredentials([string(credentialsId: 'final', variable: 'SONAR_TOKEN')]) {
          withSonarQubeEnv('sonar') {
            sh '''
              "$SCANNER_HOME/bin/sonar-scanner" \
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
        timeout(time: 5, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }
    }

    stage('Install gcloud (if needed)') {
      steps {
        sh '''
          set -euo pipefail
          if ! command -v gcloud >/dev/null 2>&1; then
            GCLOUD_DIR="$WORKSPACE/.gcloud"
            mkdir -p "$GCLOUD_DIR"
            cd "$GCLOUD_DIR"
            TAR=google-cloud-cli-linux-x86_64.tgz
            curl -fsSL -o "$TAR" https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-472.0.0-linux-x86_64.tar.gz
            tar xzf "$TAR"
            export PATH="$GCLOUD_DIR/google-cloud-sdk/bin:$PATH"
            gcloud --version
          fi
        '''
      }
    }

    stage('GCP Auth (SA)') {
      steps {
        withCredentials([file(credentialsId: 'gcp-sa-key-json', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
          sh '''
            set -euo pipefail
            gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS"
            gcloud config set project codeqa-ahana
          '''
        }
      }
    }

    stage('Run Dataproc Hadoop Job') {
      steps {
        sh '''
          set -euo pipefail
          # example placeholders; adjust to your script/args
          bash ci/run_hadoop_job.sh
        '''
      }
    }
  }

  post {
    failure {
      echo 'Pipeline failed. Check the stage logs above (Sonar, Auth, or Dataproc).'
    }
  }
}

