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

echo "=== Pulling treatment recommendation model ==="
docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/treatment-recommendation:latest

echo "=== Running treatment recommendation container ==="
docker rm -f treatment-recommendation >/dev/null 2>&1 || true
docker run -d \
  --restart always \
  --name treatment-recommendation \
  -p 3000:3000 \
  ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/treatment-recommendation:latest

echo "=== Treatment recommendation model initialized ==="

echo "=== Pulling treatment recommendation worker ==="
docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/treatment-recommendation-worker:latest

echo "=== Running treatment recommendation worker (CloudWatch logs) ==="
docker rm -f treatment-recommendation-worker >/dev/null 2>&1 || true
docker run -d \
  --restart always \
  --name treatment-recommendation-worker \
  --network host \
  --log-driver=awslogs \
  --log-opt awslogs-region=eu-central-1 \
  --log-opt awslogs-group=/ec2/treatment-recommendation-worker \
  --log-opt awslogs-create-group=true \
  --log-opt awslogs-stream=$(hostname) \
  -e PYTHONUNBUFFERED=1 \
  -e AWS_REGION=eu-central-1 \
  -e QUEUE_URL=https://sqs.eu-central-1.amazonaws.com/${AWS_ACCOUNT_ID}/kth-treatment-jobs \
  -e INPUT_PREFIX=summaries/ \
  -e OUTPUT_PREFIX=treatment_recommendations/ \
  -e INFERENCE_URL=http://localhost:3000/predict_treatment \
  ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/treatment-recommendation-worker:latest

echo "=== Treatment recommendation worker initialized ==="
