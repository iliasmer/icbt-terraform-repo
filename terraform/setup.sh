#cloud-config
package_update: true
packages:
  - docker.io
  - jq

write_files:
  - path: /usr/local/bin/run_bento.sh
    owner: root:root
    permissions: '0755'
    content: |
      #!/usr/bin/env bash
      set -e

      ACR_NAME="acrmlthesis"
      ACR_LOGIN_SERVER="${ACR_NAME}.azurecr.io"
      IMAGE_NAME="summarization:latest"

      echo "=== Getting AAD token ==="
      AAD_TOKEN=$(curl -s -H Metadata:true \
        "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/" \
        | jq -r .access_token)

      echo "=== Exchanging refresh token ==="
      REFRESH_TOKEN=$(curl -s -X POST "https://${ACR_LOGIN_SERVER}/oauth2/exchange" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "grant_type=access_token&service=${ACR_LOGIN_SERVER}&access_token=${AAD_TOKEN}" \
        | jq -r .refresh_token)

      echo "=== Getting ACR access token ==="
      ACCESS_TOKEN=$(curl -s -X POST "https://${ACR_LOGIN_SERVER}/oauth2/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "grant_type=refresh_token&service=${ACR_LOGIN_SERVER}&scope=repository:summarization:pull&refresh_token=${REFRESH_TOKEN}" \
        | jq -r .access_token)

      echo "=== Docker login ==="
      echo $ACCESS_TOKEN | docker login ${ACR_LOGIN_SERVER} \
        -u 00000000-0000-0000-0000-000000000000 --password-stdin

      echo "=== Pulling Bento image ==="
      docker pull ${ACR_LOGIN_SERVER}/${IMAGE_NAME}

      echo "=== Running container ==="
      docker rm -f summarizer >/dev/null 2>&1 || true

      docker run -d \
        --restart always \
        --name summarizer \
        -p 3000:3000 \
        -w /home/bentoml/bento/src \
        ${ACR_LOGIN_SERVER}/${IMAGE_NAME} \
        bash -c "source /app/.venv/bin/activate && bentoml serve service:summarization --host 0.0.0.0 --port 3000"

runcmd:
  - [ bash, /usr/local/bin/run_bento.sh ]
