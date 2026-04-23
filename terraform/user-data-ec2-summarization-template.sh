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

echo "=== Running summarization container 0 ==="
docker rm -f summarization0 >/dev/null 2>&1 || true
docker run -d \
  --restart always \
  --name summarization0 \
  -p 3000:3000 \
  -e OMP_NUM_THREADS=1 \
  -e MKL_NUM_THREADS=1 \
  -e OPENBLAS_NUM_THREADS=1 \
  ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/summarization:latest

echo "=== Running summarization container 1 ==="
docker rm -f summarization1 >/dev/null 2>&1 || true
docker run -d \
  --restart always \
  --name summarization1 \
  -p 3001:3000 \
  -e OMP_NUM_THREADS=1 \
  -e MKL_NUM_THREADS=1 \
  -e OPENBLAS_NUM_THREADS=1 \
  ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/summarization:latest

echo "=== Running summarization container 2 ==="
docker rm -f summarization2 >/dev/null 2>&1 || true
docker run -d \
  --restart always \
  --name summarization2 \
  -p 3002:3000 \
  -e OMP_NUM_THREADS=1 \
  -e MKL_NUM_THREADS=1 \
  -e OPENBLAS_NUM_THREADS=1 \
  ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/summarization:latest

echo "=== Running summarization container 3 ==="
docker rm -f summarization3 >/dev/null 2>&1 || true
docker run -d \
  --restart always \
  --name summarization3 \
  -p 3003:3000 \
  -e OMP_NUM_THREADS=1 \
  -e MKL_NUM_THREADS=1 \
  -e OPENBLAS_NUM_THREADS=1 \
  ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/summarization:latest

echo "=== Running summarization container 4 ==="
docker rm -f summarization4 >/dev/null 2>&1 || true
docker run -d \
  --restart always \
  --name summarization4 \
  -p 3004:3000 \
  -e OMP_NUM_THREADS=1 \
  -e MKL_NUM_THREADS=1 \
  -e OPENBLAS_NUM_THREADS=1 \
  ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/summarization:latest

echo "=== Summarization models initialized ==="

echo "=== Pulling summarization worker ==="
docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/summarization-worker:latest

echo "=== Running summarization worker ==="
docker rm -f summarization-worker >/dev/null 2>&1 || true
docker run -d \
  --restart always \
  --name summarization-worker \
  --network host \
  --log-driver=awslogs \
  --log-opt awslogs-region=eu-central-1 \
  --log-opt awslogs-group=/ec2/summarization-worker \
  --log-opt awslogs-create-group=true \
  --log-opt awslogs-stream=$(hostname) \
  -e PYTHONUNBUFFERED=1 \
  -e AWS_REGION=eu-central-1 \
  -e QUEUE_URL=https://sqs.eu-central-1.amazonaws.com/${AWS_ACCOUNT_ID}/kth-summarization-jobs \
  -e INPUT_PREFIX=transcripts/ \
  -e OUTPUT_PREFIX=summaries/ \
  -e INFERENCE_URLS=http://localhost:3000/summarize,http://localhost:3001/summarize,http://localhost:3002/summarize,http://localhost:3003/summarize,http://localhost:3004/summarize \
  ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/summarization-worker:latest

echo "=== Summarization worker initialized ==="