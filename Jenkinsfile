pipeline {
  agent {
    kubernetes {
      defaultContainer 'jnlp'
      yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:3345.v03dee9b_f88fc-3
  - name: sonar
    image: sonarsource/sonar-scanner-cli:latest
    command: ['cat']
    tty: true
"""
    }
  }

  environment {
    SONAR_HOST = 'http://sonarqube-sonarqube.sonarqube:9000'
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('SonarQube Scan') {
      steps {
        container('sonar') {
          withCredentials([string(credentialsId: 'tokenFinal', variable: 'SONAR_TOKEN')]) {
            sh '''
              set -e
              sonar-scanner \
                -Dsonar.host.url="${SONAR_HOST}" \
                -Dsonar.token="${SONAR_TOKEN}" \
                -Dsonar.projectKey=python-code-disasters \
                -Dsonar.projectName=python-code-disasters \
                -Dsonar.sources=. \
                -Dsonar.sourceEncoding=UTF-8
            '''
          }
        }
      }
    }

    // Optional: Gate build on Sonar quality gate
    // Requires: Manage Jenkins -> SonarQube servers configured
    // and "Wait for Quality Gate" plugin.
    // stage('Quality Gate') {
    //   steps {
    //     timeout(time: 3, unit: 'MINUTES') {
    //       waitForQualityGate abortPipeline: true
    //     }
    //   }
    // }
  }

  post { always { echo "Build result: ${currentBuild.currentResult}" } }
}
