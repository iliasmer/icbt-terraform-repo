# module "ec2_summarization" {
#   source = "./modules/ec2-ami-template/"

#   name         = "ec2-summarization"
#   service_name = "Summarization"
#   service_port = 3000
# }

# module "ec2_treatment_recommendation" {
#   source = "./modules/ec2-ami-template/"

#   name         = "ec2-treatment-recommendation"
#   service_name = "Treatment Recommendation"
#   service_port = 3000
# }

# module "ec2_whisper" {
#   source = "./modules/ec2-ami-template/"

#   name          = "ec2-whisper"
#   service_name  = "Whisper"
#   service_port  = 3000
#   volume_size   = 500
#   instance_type = "m6i.2xlarge"
# }