assume role <role_name>
source icbtenv/bin/activate   
cd summarizarion 

# 1) Authenticate Docker to ECR
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin 217793907183.dkr.ecr.eu-central-1.amazonaws.com

# 2) Build the Bento
bentoml build

# 3) Containerize the Bento (use the tag printed by the previous command)
bentoml containerize summarization:latest

# 4) Tag the image for ECR
docker tag summarization:bbnel3hvjs5pt77w 217793907183.dkr.ecr.eu-central-1.amazonaws.com/summarization:latest

# 5) Push to ECR
docker push 217793907183.dkr.ecr.eu-central-1.amazonaws.com/summarization:latest
