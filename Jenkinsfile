pipeline {
  agent any
  options { timestamps() }

  environment {
    // Sonar scanner tool (Manage Jenkins → Global Tool Configuration)
    SCANNER_HOME = tool name: 'sonar-scanner', type: 'hudson.plugins.sonar.SonarRunnerInstallation'
    SONAR_HOST_URL = 'http://136.114.144.55:9000'

    // Optional: set this if your Hadoop Streaming jar lives elsewhere on your agent/cluster
    // HADOOP_STREAMING_JAR = '/usr/lib/hadoop-mapreduce/hadoop-streaming.jar'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('SonarQube Scan') {
      steps {
        // Using your existing Secret Text credential id: 'final'
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
            // Don’t hard-fail here; we want to branch on status
            def qg = waitForQualityGate abortPipeline: false, credentialsId: 'final'
            echo "Quality Gate status: ${qg.status}"
            if (qg.status == 'OK') {
              env.QG_OK = 'true'
            } else {
              env.QG_OK = 'false'
              currentBuild.result = 'UNSTABLE'
              echo "Skipping Hadoop job because quality gate is ${qg.status}"
            }
          }
        }
      }
    }

    stage('Run Hadoop Job (line counts)') {
      when { environment name: 'QG_OK', value: 'true' }
      steps {
        sh '''
          set -euo pipefail

          # If you set HADOOP_STREAMING_JAR as an env in Jenkins, this will use it.
          # Otherwise ci/run_hadoop_job.sh has a sensible default path.
          if [[ -n "${HADOOP_STREAMING_JAR:-}" ]]; then
            export HADOOP_STREAMING_JAR
          fi

          # Run your Streaming job (expects mapper.py, reducer.py, ci/run_hadoop_job.sh in repo)
          ci/run_hadoop_job.sh
        '''
      }
    }
  }

  post {
    always {
      echo "Build result: ${currentBuild.currentResult}"
    }
  }
}

