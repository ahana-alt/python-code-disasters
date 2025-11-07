pipeline {
  agent any
  options { timestamps() }

  stages {
    stage('SonarQube Scan') {
      steps {
        script {
          def scannerHome = tool 'sonar-scanner'       // Jenkins > Tools name
          withCredentials([string(credentialsId: 'final', variable: 'SONAR_TOKEN')]) {
            withSonarQubeEnv('sonar') {
              sh """
                set -eu
                export PATH="${scannerHome}/bin:\$PATH"
                # If the repo already has sonar-project.properties, Sonar will pick it up.
                # We pass login + host to be explicit.
                sonar-scanner \
                  -Dsonar.host.url="$SONAR_HOST_URL" \
                  -Dsonar.login="$SONAR_TOKEN"
              """
            }
          }
        }
      }
    }

    stage('Quality Gate') {
      steps {
        script {
          // Requires the Sonar webhook to Jenkins to be configured
          timeout(time: 3, unit: 'MINUTES') {
            def qg = waitForQualityGate()  // aborts Pipeline if status != OK
            if (qg.status != 'OK') {
              error "Quality Gate failed: ${qg.status}"
            }
          }
        }
      }
    }
  }
}

