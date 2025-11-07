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

            # Install scanner locally if not present
            SCANNER_DIR="$WORKSPACE/.local/sonar-scanner"
            if [ ! -x "$SCANNER_DIR/bin/sonar-scanner" ]; then
              mkdir -p "$WORKSPACE/.local"
              curl -sSL https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-5.0.1.3006-linux.zip -o /tmp/sonar.zip
              unzip -q -o /tmp/sonar.zip -d "$WORKSPACE/.local"
              mv "$WORKSPACE"/.local/sonar-scanner-* "$SCANNER_DIR"
            fi
            export PATH="$SCANNER_DIR/bin:$PATH"

            # Run scan using Jenkins' Sonar server + token from withSonarQubeEnv
            # (most setups expose SONAR_HOST_URL and SONAR_AUTH_TOKEN)
            if [ -n "${SONAR_AUTH_TOKEN:-}" ]; then
              sonar-scanner \
                -Dsonar.host.url="$SONAR_HOST_URL" \
                -Dsonar.login="$SONAR_AUTH_TOKEN"
            else
              # fallback: older plugins inject only SONAR_HOST_URL
              sonar-scanner -Dsonar.host.url="$SONAR_HOST_URL"
            fi
          '''
        }
      }
    }
  }
}

