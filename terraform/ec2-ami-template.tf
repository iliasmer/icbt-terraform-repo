# module "ec2_whisper_template" {
#   source = "./modules/ec2-ami-template/"

#   name          = "ec2-whisper-template"
#   service_name  = "Whisper"
#   service_port  = 3000
#   volume_size   = 500
#   instance_type = "m6i.2xlarge"
# }

# module "ec2_summarization_template" {
#   source = "./modules/ec2-ami-template/"

#   name          = "ec2-summarization-template"
#   service_name  = "Summarization"
#   service_port  = 3000
#   instance_type = "m6i.2xlarge"
# }

# module "ec2_pttsd_template" {
#   source = "./modules/ec2-ami-template/"

#   name          = "ec2-pttsd-template"
#   service_name  = "PTTSD"
#   service_port  = 8000
#   instance_type = "t3.medium"
# }
