# General variables

variable "environment" {
  type        = string
  description = "The environment being deployed in"
}

variable "region" {
  type        = string
  description = "The region being deployed in"
  default     = "eu-central-1"
}

# VPC: VPC variables
variable "cidr_block" {
  type        = string
  description = "The IPv4 CIDR block for the VPC"
}

# VPC: private subnets variables
variable "private_subnet_name" {
  type        = list(string)
  description = "The names of the private subnets"
}

variable "private_subnet_cidr" {
  type        = list(string)
  description = "The IPv4 CIDR blocks for the private subnets"
}

variable "private_subnet_azs" {
  type        = list(string)
  description = "The AZs for the private subnets"
}

#VPC Endpoints
variable "endpoint_nr_azs" {
  type        = number
  description = "Number of AZs to deploy the VPC endpoints in"
  default     = 3

  validation {
    condition     = var.endpoint_nr_azs <= length(var.private_subnet_cidr)
    error_message = "endpoint_nr_azs must be <= length(private_subnet_cidr)."
  }
}

# Tags
variable "tags" {
  type        = map(any)
  description = "Tags: both tags and tags_all"
  default     = {}
}
