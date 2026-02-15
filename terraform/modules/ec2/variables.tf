variable "name" {
  type        = string
  description = "Name prefix for resources"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where SG and ASG will be created"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the ASG (can be multiple AZs)"
}

variable "ami_id" {
  type        = string
  description = "AMI to boot from (your pre-baked AMI)"
}

variable "service_port" {
  type        = number
  description = "Port exposed by your service (example: 3000)"
}

variable "allowed_ingress_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to reach service_port"
  default     = []
}

variable "instance_type" {
  type        = string
  default     = "t3.medium"
}

variable "volume_size" {
  type        = number
  default     = 100
}

variable "min_size" {
  type = number
}

variable "max_size" {
  type = number
}

variable "desired_capacity" {
  type = number
}

variable "health_check_grace_period" {
  type    = number
  default = 300
}




