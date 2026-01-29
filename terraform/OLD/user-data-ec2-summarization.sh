#!/bin/bash
set -e

echo "=== Updating system ==="
apt-get update -y

echo "=== Installing SSM Agent ==="
apt-get install -y snapd
snap install amazon-ssm-agent --classic
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent

echo "=== Installing dependencies ==="
apt-get install -y \
  docker.io \
  awscli \
  ca-certificates \
  curl

echo "=== Enabling Docker ==="
systemctl enable docker
systemctl start docker

echo "=== Allow ubuntu user to use Docker ==="
usermod -aG docker ubuntu

echo "=== Logging in to ECR ==="
aws ecr get-login-password --region eu-central-1 \
  | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com

echo "=== Pulling summarization model ==="
docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/summarization:latest

echo "=== Running summarization container ==="
docker rm -f summarization >/dev/null 2>&1 || true
docker run -d \
  --restart always \
  --name summarization \
  -p 3000:3000 \
  ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/summarization:latest

echo "=== Bootstrap completed ==="
