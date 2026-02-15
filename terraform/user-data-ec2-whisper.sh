#!/bin/bash
set -e

AWS_REGION="eu-central-1"

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
  curl \
  gnupg \
  lsb-release \
  ubuntu-drivers-common

echo "=== Enabling Docker ==="
systemctl enable docker
systemctl start docker

echo "=== Allow ubuntu user to use Docker ==="
usermod -aG docker ubuntu || true

GPU_ARGS=""
echo "=== Checking for NVIDIA GPU ==="
if lspci | grep -qi nvidia; then
  echo "NVIDIA GPU detected, installing driver + container toolkit"

  echo "=== Installing NVIDIA driver ==="
  ubuntu-drivers autoinstall || true

  echo "=== Adding NVIDIA Container Toolkit repository ==="
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
    | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

  distribution="$(. /etc/os-release; echo $${ID}$${VERSION_ID})"
  curl -fsSL "https://nvidia.github.io/libnvidia-container/$${distribution}/libnvidia-container.list" \
    | sed "s#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g" \
    > /etc/apt/sources.list.d/nvidia-container-toolkit.list

  apt-get update -y
  apt-get install -y nvidia-container-toolkit

  echo "=== Configuring Docker to use NVIDIA runtime ==="
  /usr/bin/nvidia-ctk runtime configure --runtime=docker
  systemctl restart docker

  echo "=== GPU sanity check ==="
  nvidia-smi || true

  if docker info 2>/dev/null | grep -qi 'Runtimes:.*nvidia'; then
    GPU_ARGS="--gpus all"
    echo "Docker NVIDIA runtime detected, will use GPU"
  else
    echo "WARNING: NVIDIA runtime not visible to Docker, running CPU-only"
  fi
else
  echo "WARNING: No NVIDIA GPU detected, running CPU-only"
fi

echo "=== Logging in to ECR ==="
aws ecr get-login-password --region "$${AWS_REGION}" \
  | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com

echo "=== Pulling whisper model ==="
docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/whisper:latest

echo "=== Running whisper container ==="
docker rm -f whisper >/dev/null 2>&1 || true
docker run -d \
  --restart always \
  --name whisper \
  $${GPU_ARGS} \
  --log-driver=awslogs \
  --log-opt awslogs-region=eu-central-1 \
  --log-opt awslogs-group=/ec2/whisper \
  --log-opt awslogs-create-group=true \
  --log-opt awslogs-stream=$(hostname) \
  -p 3000:3000 \
  -e PYTHONUNBUFFERED=1 \
  ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/whisper:latest

echo "=== Whisper model initialized ==="

echo "=== Pulling whisper worker ==="
docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/whisper-worker:latest

echo "=== Running whisper worker (CloudWatch logs) ==="
docker rm -f whisper-worker >/dev/null 2>&1 || true
docker run -d \
  --restart always \
  --name whisper-worker \
  --network host \
  --log-driver=awslogs \
  --log-opt awslogs-region=eu-central-1 \
  --log-opt awslogs-group=/ec2/whisper-worker \
  --log-opt awslogs-create-group=true \
  --log-opt awslogs-stream=$(hostname) \
  -e PYTHONUNBUFFERED=1 \
  -e AWS_REGION=eu-central-1 \
  -e QUEUE_URL=https://sqs.eu-central-1.amazonaws.com/${AWS_ACCOUNT_ID}/kth-whisper-jobs \
  -e INPUT_PREFIX=audio/ \
  -e OUTPUT_PREFIX=transcripts/ \
  -e INFERENCE_URL=http://localhost:3000/transcribe \
  ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/whisper-worker:latest

echo "=== Whisper worker initialized ==="
