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
'''
      }
    }
    stage('SonarQube Scan') {
      steps {
        script {
          def scannerHome = tool 'sonar-scanner'  // from Manage Jenkins > Tools
          withSonarQubeEnv('sonar') {
            sh """
              set -eu
              export PATH="${scannerHome}/bin:\$PATH"
              if [ -n "\${SONAR_AUTH_TOKEN:-}" ]; then
                sonar-scanner -Dsonar.host.url="\$SONAR_HOST_URL" -Dsonar.login="\$SONAR_AUTH_TOKEN"
              else
                sonar-scanner -Dsonar.host.url="\$SONAR_HOST_URL"
              fi
            """
          }
        }
      }
    }
  }
}
