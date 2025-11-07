pipeline {
  agent any
  options { timestamps() }

  parameters {
    string(name: 'PROJECT_ID',   defaultValue: 'codeqa-ahana',   description: 'GCP Project')
    string(name: 'REGION',       defaultValue: 'us-central1',    description: 'GCP Region for Dataproc')
    string(name: 'CLUSTER_NAME', defaultValue: 'ahana-dp',       description: 'Dataproc cluster name')
    string(name: 'BUCKET_NAME',  defaultValue: 'ahana-dataproc-demo-bucket', description: 'GCS bucket for job I/O')
  }

  environment {
    // Sonar
    SCANNER_HOME   = tool name: 'sonar-scanner', type: 'hudson.plugins.sonar.SonarRunnerInstallation'
    SONAR_HOST_URL = 'http://136.114.144.55:9000'
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
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

    stage('GCP Auth (SA)') {
      when { environment name: 'QG_OK', value: 'true' }
      steps {
        withCredentials([file(credentialsId: 'dataproc-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
          sh '''
            set -euo pipefail
            gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS"
            gcloud config set core/project "${PROJECT_ID}"
            gcloud config set dataproc/region "${REGION}"
          '''
        }
      }
    }

    stage('Run Dataproc Hadoop Job') {
      when { environment name: 'QG_OK', value: 'true' }
      steps {
        sh '''
          set -euo pipefail
          export REGION="${REGION}"
          export CLUSTER_NAME="${CLUSTER_NAME}"
          export BUCKET_NAME="${BUCKET_NAME}"
          export BUILD_ID="${BUILD_ID}"

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

