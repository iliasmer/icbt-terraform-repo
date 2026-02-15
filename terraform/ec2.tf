module "ec2_whisper" {
  source = "./modules/ec2/"

  name                  = "ec2-whisper"
  vpc_id                = local.vpc_id
  subnet_ids            = local.subnet_ids
  ami_id                = "ami-01ec1f10e97ddbfca"
  service_port          = 3000
  allowed_ingress_cidrs = ["0.0.0.0/0"]
  volume_size           = 500
  min_size              = 0
  max_size              = 1
  desired_capacity      = 0
}

module "ec2_summarization" {
  source = "./modules/ec2/"

  name                  = "ec2-summarization"
  vpc_id                = local.vpc_id
  subnet_ids            = local.subnet_ids
  ami_id                = "ami-0699f0dff2f8177de"
  service_port          = 3000
  allowed_ingress_cidrs = ["0.0.0.0/0"]
  min_size              = 0
  max_size              = 1
  desired_capacity      = 0
}

module "ec2_treatment_recommendation" {
  source = "./modules/ec2/"

  name                  = "ec2-treatment-recommendation"
  vpc_id                = local.vpc_id
  subnet_ids            = local.subnet_ids
  ami_id                = "ami-0a6651c2fd78c6490"
  service_port          = 3000
  allowed_ingress_cidrs = ["0.0.0.0/0"]
  min_size              = 0
  max_size              = 1
  desired_capacity      = 0
}

