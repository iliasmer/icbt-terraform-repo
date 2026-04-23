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

echo "=== Pulling PTTSD model ==="
docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/pttsd:latest

echo "=== Running PTTSD model container 0 ==="
docker rm -f pttsd0 >/dev/null 2>&1 || true
docker run -d \
  --restart always \
  --name pttsd0 \
  -p 8000:8000 \
  ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/pttsd:latest

echo "=== Running PTTSD model container 1 ==="
docker rm -f pttsd1 >/dev/null 2>&1 || true
docker run -d \
  --restart always \
  --name pttsd1 \
  -p 8001:8000 \
  ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/pttsd:latest

echo "=== Running PTTSD model container 2 ==="
docker rm -f pttsd2 >/dev/null 2>&1 || true
docker run -d \
  --restart always \
  --name pttsd2 \
  -p 8002:8000 \
  ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/pttsd:latest

echo "=== Running PTTSD model container 3 ==="
docker rm -f pttsd3 >/dev/null 2>&1 || true
docker run -d \
  --restart always \
  --name pttsd3 \
  -p 8003:8000 \
  ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/pttsd:latest

echo "=== Running PTTSD model container 4 ==="
docker rm -f pttsd4 >/dev/null 2>&1 || true
docker run -d \
  --restart always \
  --name pttsd4 \
  -p 8004:8000 \
  ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/pttsd:latest

echo "=== PTTSD model initialized ==="

echo "=== Pulling PTTSD worker ==="
docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/pttsd-worker:latest

echo "=== Running PTTSD worker (CloudWatch logs) ==="
docker rm -f pttsd-worker >/dev/null 2>&1 || true
docker run -d \
  --restart always \
  --name pttsd-worker \
  --network host \
  --log-driver=awslogs \
  --log-opt awslogs-region=eu-central-1 \
  --log-opt awslogs-group=/ec2/pttsd-worker \
  --log-opt awslogs-create-group=true \
  --log-opt awslogs-stream=$(hostname) \
  -e PYTHONUNBUFFERED=1 \
  -e AWS_REGION=eu-central-1 \
  -e QUEUE_URL=https://sqs.eu-central-1.amazonaws.com/${AWS_ACCOUNT_ID}/kth-pttsd-jobs \
  -e INPUT_PREFIX=summaries/ \
  -e OUTPUT_PREFIX=pttsd_outputs/ \
  -e INFERENCE_URLS=http://localhost:8000/predict/text,http://localhost:8001/predict/text,http://localhost:8002/predict/text,http://localhost:8003/predict/text,http://localhost:8004/predict/text \
  ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/pttsd-worker:latest

echo "=== PTTSD worker initialized ==="