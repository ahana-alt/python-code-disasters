pipeline {
  agent any
  options { timestamps() }

  stages {
    stage('Prepare props') {
      steps {
        writeFile file: 'sonar-project.properties', text: '''
sonar.projectKey=python-code-disasters.smoke
sonar.projectName=python-code-disasters.smoke
sonar.sources=smoke
sonar.sourceEncoding=UTF-8
'''.trim() + '\n'
      }
    }

    stage('SonarQube Scan') {
      steps {
        script {
          // Use the SonarScanner tool installed via Manage Jenkins > Tools (name must be exactly 'sonar-scanner')
          def scannerHome = tool 'sonar-scanner'
          // 1) get the token explicitly from Jenkins credentials
          withCredentials([string(credentialsId: 'final', variable: 'SONAR_TOKEN')]) {
            // 2) get server URL etc from the Sonar server named 'sonar'
            withSonarQubeEnv('sonar') {
              sh """
                set -eu
                export PATH="${scannerHome}/bin:\$PATH"
                sonar-scanner \\
                  -Dsonar.host.url="\$SONAR_HOST_URL" \\
                  -Dsonar.login="\$SONAR_TOKEN"
              """
            }
          }
        }
      }
    }
  }
}

