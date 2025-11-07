pipeline {
  agent any
  options { timestamps() }

  stages {
    stage('SonarQube Scan') {
      steps {
        script {
          def scannerHome = tool 'sonar-scanner'   // Manage Jenkins → Tools name
          withCredentials([string(credentialsId: 'final', variable: 'SONAR_TOKEN')]) {
            sh """
              set -eu
              export PATH="${scannerHome}/bin:\$PATH"
              sonar-scanner \
                -Dsonar.projectKey=python-code-disasters.smoke \
                -Dsonar.projectName=python-code-disasters.smoke \
                -Dsonar.sources=smoke \
                -Dsonar.sourceEncoding=UTF-8 \
                -Dsonar.host.url=http://136.114.144.55:9000 \
                -Dsonar.login=\$SONAR_TOKEN
            """
          }
        }
      }
    }
  }
}
