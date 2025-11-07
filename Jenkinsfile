pipeline {
  agent any
  options { timestamps() }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('SonarQube Scan') {
      steps {
        withSonarQubeEnv('sonar') {   
          sh '''
            set -eu
            if ! command -v sonar-scanner >/dev/null 2>&1; then
              curl -sLo /tmp/sonar.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-5.0.1.3006-linux.zip
              rm -rf .local/sonar-scanner
              mkdir -p .local
              unzip -q /tmp/sonar.zip -d .local
              mv .local/sonar-scanner-* .local/sonar-scanner
              export PATH="$PWD/.local/sonar-scanner/bin:$PATH"
            fi
            sonar-scanner
          '''
        }
      }
    }

    // Optional – only works instantly if you add a Sonar webhook to Jenkins
    stage('Quality Gate') {
      steps {
        script {
          timeout(time: 3, unit: 'MINUTES') {
            def qg = waitForQualityGate()
            if (qg.status != 'OK') error "Quality Gate failed: ${qg.status}"
          }
        }
      }
    }
  }
}

