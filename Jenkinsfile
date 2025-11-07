pipeline {
  agent any
  options {
    timestamps()
    ansiColor('xterm')
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  environment {
    // local CLI install location (keeps agents clean)
    SCANNER_URL = 'https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-5.0.1.3006-linux.zip'
    SCANNER_DIR = "${WORKSPACE}/.local/sonar-scanner"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('SonarQube Scan') {
      steps {
        // 1) ensure sonar-scanner is available (self-installed locally)
        sh '''
          set -eu
          if [ ! -x "${SCANNER_DIR}/bin/sonar-scanner" ]; then
            rm -rf "${WORKSPACE}/.local"
            mkdir -p "${WORKSPACE}/.local"
            curl -sSL "$SCANNER_URL" -o /tmp/sonar.zip
            unzip -q /tmp/sonar.zip -d "${WORKSPACE}/.local"
            mv "${WORKSPACE}/.local"/sonar-scanner-* "${SCANNER_DIR}"
          fi
        '''

        // 2) run scanner using the Sonar server named "sonar" (configured in Jenkins)
        withSonarQubeEnv('sonar') {
          sh '''
            set -eu
            export PATH="${SCANNER_DIR}/bin:$PATH"
            # Uses the sonar-project.properties already in your repo:
            #   sonar.projectKey=python-code-disasters
            #   sonar.projectName=python-code-disasters
            sonar-scanner
          '''
        }
      }
    }

    stage('Quality Gate') {
      steps {
        script {
          // This is instant if you add a Sonar webhook to Jenkins: http://<JENKINS-PUBLIC-IP>:8080/sonarqube-webhook/
          timeout(time: 3, unit: 'MINUTES') {
            def qg = waitForQualityGate()
            if (qg.status != 'OK') {
              error "Quality Gate failed: ${qg.status}"
            }
          }
        }
      }
    }
  }
}

