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
          def scannerHome = tool 'sonar-scanner'   // Manage Jenkins → Tools → SonarQube Scanner (name must be exactly this)
          withCredentials([string(credentialsId: 'final', variable: 'SONAR_TOKEN')]) {
            sh """
              set -eu
              export PATH="${scannerHome}/bin:\$PATH"
              sonar-scanner \\
                -Dsonar.host.url=http://136.114.144.55:9000 \\
                -Dsonar.login=\$SONAR_TOKEN
            """
          }
        }
      }
    }
  }
}

