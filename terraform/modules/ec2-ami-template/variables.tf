variable "name" {
  type = string
  description = "name of the ec2 instance"
}

variable "service_name" {
  type = string
  description = "not critical. used only for clean naming."
}

variable "service_port" {
  type = number
  description = "port where the service is hosted, ex: 3000"
}

variable "ami" {
  type = string
  default = "ami-0faab6bdbac9486fb"
}

variable "instance_type" {
  type = string
  default = "t3.medium"
}

variable "volume_size" {
  type = number
  default = 100
}