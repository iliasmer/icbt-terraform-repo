module "ec2_whisper" {
  source = "./modules/ec2/"

  name                  = "ec2-whisper"
  vpc_id                = local.vpc_id
  subnet_ids            = local.subnet_ids
  instance_type         = "m6i.2xlarge"
  ami_id                = "ami-0e28a3b1f8b4f6fd3"
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
  instance_type         = "m6i.2xlarge"
  ami_id                = "ami-0022fd58bd8337cfd"
  service_port          = 3000
  allowed_ingress_cidrs = ["0.0.0.0/0"]
  min_size              = 0
  max_size              = 1
  desired_capacity      = 0
}

module "ec2_pttsd" {
  source = "./modules/ec2/"

  name                  = "ec2-pttsd"
  vpc_id                = local.vpc_id
  subnet_ids            = local.subnet_ids
  ami_id                = "ami-0e012bb5e0f3735d2"
  service_port          = 8000
  allowed_ingress_cidrs = ["0.0.0.0/0"]
  min_size              = 0
  max_size              = 1
  desired_capacity      = 0
}

