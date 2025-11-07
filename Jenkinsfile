pipeline {
  agent any
  options { timestamps() }

  stages {
    stage('SonarQube Scan') {
      steps {
        script {
          def scannerHome = tool 'sonar-scanner'     // Jenkins > Tools name
          withCredentials([string(credentialsId: 'final', variable: 'SONAR_TOKEN')]) {
            withSonarQubeEnv('sonar') {
              sh '''
                set -eu
                export PATH="${scannerHome}/bin:$PATH"
                sonar-scanner \
                  -Dsonar.host.url="$SONAR_HOST_URL" \
                  -Dsonar.token="$SONAR_TOKEN"
              '''
            }
          }
        }
      }
    }

    stage('Quality Gate') {
      steps {
        script {
          timeout(time: 3, unit: 'MINUTES') {
            def qg = waitForQualityGate()  // uses the *server* token you set in step 3
            if (qg.status != 'OK') {
              error "Quality Gate failed: ${qg.status}"
            }
          }
        }
      }
    }
  }
}

