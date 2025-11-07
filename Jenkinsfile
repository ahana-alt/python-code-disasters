pipeline {
  agent any
  options { timestamps() }

  environment {
    // --- Sonar ---
    SCANNER_HOME = tool name: 'sonar-scanner', type: 'hudson.plugins.sonar.SonarRunnerInstallation'
    SONAR_HOST_URL = 'http://136.114.144.55:9000'    // your Sonar host

    // --- GCP / Dataproc job params (edit if you change something later) ---
    PROJECT_ID    = 'codeqa-ahana'
    REGION        = 'us-central1'
    CLUSTER_NAME  = 'ahana-dp'
    BUCKET        = 'ahana-dp-bkt-1762552295'        // your bucket from previous run
    HADOOP_VER    = '3.3.6'                          // jar we uploaded to GCS
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
            def qg = waitForQualityGate abortPipeline: true, credentialsId: 'final'
            echo "Quality Gate status: ${qg.status}"
          }
        }
      }
    }

    stage('Install gcloud (if needed)') {
      steps {
        sh '''
          set -euo pipefail

          # Install into workspace-local dir so we need no root
          if [ ! -x ".gcloud/google-cloud-sdk/bin/gcloud" ]; then
            rm -rf .gcloud && mkdir -p .gcloud
            curl -sSL https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-472.0.0-linux-x86_64.tar.gz \
              -o .gcloud.tgz
            tar -xzf .gcloud.tgz -C .gcloud
            ./.gcloud/google-cloud-sdk/install.sh --quiet --usage-reporting=false --path-update=false --additional-components
          fi

          # Write a helper PATH file we can source in later stages
          cat > .gcloud-path.sh <<'EOF'
          export PATH="$(pwd)/.gcloud/google-cloud-sdk/bin:$PATH"
          EOF

          # Prove it's available
          . ./.gcloud-path.sh
          gcloud version
        '''
      }
    }

    stage('GCP Auth (SA)') {
      steps {
        withCredentials([file(credentialsId: 'dataproc-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
          sh '''
            set -euo pipefail
            [ -f ".gcloud-path.sh" ] && . ./.gcloud-path.sh || true

            # Activate service account
            gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS"

            # Set project/region (persisted in this workspace)
            gcloud config set core/project "${PROJECT_ID}"
            gcloud config set dataproc/region "${REGION}"

            # Show active account for sanity
            gcloud auth list
          '''
        }
      }
    }

    stage('Run Dataproc Hadoop Job') {
      steps {
        sh '''
          set -euo pipefail
          [ -f ".gcloud-path.sh" ] && . ./.gcloud-path.sh || true

          # Verify cluster exists
          gcloud dataproc clusters describe "${CLUSTER_NAME}" --region="${REGION}" >/dev/null

          # Ensure the streaming jar is present in GCS (we uploaded this earlier)
          gsutil ls "gs://${BUCKET}/jars/hadoop-streaming-${HADOOP_VER}.jar" >/dev/null

          # Push (or refresh) the mapper/reducer into GCS jobs/ (idempotent)
          gsutil cp mapper.py "gs://${BUCKET}/jobs/mapper.py"
          gsutil cp reducer.py "gs://${BUCKET}/jobs/reducer.py"

          # Submit streaming job
          OUTDIR="linecounts-$(date +%s)"
          gcloud dataproc jobs submit hadoop \
            --project="${PROJECT_ID}" \
            --region="${REGION}" \
            --cluster="${CLUSTER_NAME}" \
            --class=org.apache.hadoop.streaming.HadoopStreaming \
            --jars="gs://${BUCKET}/jars/hadoop-streaming-${HADOOP_VER}.jar" \
            -- \
            -files "gs://${BUCKET}/jobs/mapper.py,gs://${BUCKET}/jobs/reducer.py" \
            -mapper "python3 mapper.py" \
            -reducer "python3 reducer.py" \
            -input "gs://${BUCKET}/repo-input" \
            -output "gs://${BUCKET}/${OUTDIR}"

          # Collect lightweight artifacts for grading
          rm -rf artifacts && mkdir -p artifacts
          echo "gs://${BUCKET}/${OUTDIR}" | tee artifacts/output_prefix.txt
          gsutil ls "gs://${BUCKET}/${OUTDIR}/part-*" | tee artifacts/output_files.txt
          gsutil cat "gs://${BUCKET}/${OUTDIR}/part-*" | head -n 50 | tee artifacts/linecounts_head.txt

          # Basic sanity
          test -s artifacts/linecounts_head.txt
        '''
      }
      post {
        always {
          archiveArtifacts artifacts: 'artifacts/**', allowEmptyArchive: true
          echo "Build result: ${currentBuild.currentResult}"
        }
      }
    }
  }

  post {
    failure {
      echo 'Pipeline failed. Check the stage logs above (Sonar, Auth, or Dataproc).'
    }
    success {
      echo 'Pipeline finished successfully'
    }
  }
}

