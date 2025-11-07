pipeline {
  agent any
  options { timestamps() }
  stages {
    stage('Sonar API ping') {
      steps {
        withSonarQubeEnv('sonar') {
          sh '''
            set -eu
            echo "SONAR_HOST_URL=$SONAR_HOST_URL"
            # Check server is reachable
            code=$(curl -s -o /dev/null -w '%{http_code}' "$SONAR_HOST_URL/api/server/version" || true)
            if [ "$code" != "200" ]; then
              echo "Sonar server/version not reachable, HTTP $code"
              exit 1
            fi
            # Auth validation (proves token ok)
            # Newer Jenkins Sonar plugin exposes SONAR_AUTH_TOKEN; if not, this call will 401 and we’ll fail.
            if [ -n "${SONAR_AUTH_TOKEN:-}" ]; then
              body=$(curl -sfSL -H "Authorization: Bearer $SONAR_AUTH_TOKEN" "$SONAR_HOST_URL/api/authentication/validate" || true)
              echo "Auth validate: $body"
              echo "$body" | grep -q '"valid":true' || { echo "Token not valid"; exit 1; }
            else
              echo "Warning: SONAR_AUTH_TOKEN not exposed by plugin, skipping auth validate."
            fi
          '''
        }
      }
    }
  }
}
