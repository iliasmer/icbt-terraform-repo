# General variables
variable "customer" {
  type        = string
  description = "Customer being deployed"
}

variable "environment" {
  type        = string
  description = "The environment being deployed in"
}

variable "region" {
  type        = string
  description = "The region being deployed in"
}

variable "custom_vpc_resource_prefix" {
  type        = string
  description = "Custom prefix for naming VPC resources"
  default     = null
  nullable    = true
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

# VPC: public subnets variables
variable "public_subnet_name" {
  type        = list(string)
  description = "The names of the public subnets"
}

variable "public_subnet_cidr" {
  type        = list(string)
  description = "The IPv4 CIDR blocks for the public subnets"
}

variable "public_subnet_azs" {
  type        = list(string)
  description = "The AZs for the public subnets"
}

# VPC: Private zone variables
variable "private_hosted_zone_name" {
  type        = string
  description = "Name of the private hosted zone"
  default     = null
  nullable    = true
}

variable "associated_vpc_id" {
  type        = list(string)
  description = "List of associated vpc IDs"
  default     = []
}

# VPC flowlog variables
variable "enable_vpc_flow_log" {
  type        = bool
  description = "Enable VPC flow log: True or False"
  default     = false
}

variable "log_group_name_suffix" {
  type        = string
  description = "A unique name suffix for the flow log log group. Must match existing suffix for DAF import"
}

variable "flow_log_role_name_suffix" {
  type        = string
  description = "A unique name suffix for the flow log role. Must match existing suffix for DAF import"
}

variable "vpc_flow_log_traffic_type" {
  type        = string
  description = "VPC flowlog traffic type: ALL or REJECT"
  default     = "REJECT"
}

variable "vpc_flow_log_retention_in_days" {
  type        = number
  description = "Specifies the number of days you want to retain log events in the specified log group"
  default     = 14
}
#VPC Endpoints
variable "endpoint_nr_azs" {
  type        = number
  description = "Number of AZs to deploy the VPC endpoints in"
  default     = 3
}

variable "enable_sqs_endpoint" {
  type        = bool
  description = "Enable SQS VPC endpoint"
  default     = false
}

variable "enable_sns_endpoint" {
  type        = bool
  description = "Enable SNS VPC endpoint"
  default     = false
}

variable "enable_ecr_endpoints" {
  type        = bool
  description = "Enable ECR VPC endpoints"
  default     = false
}

variable "ssm_parameter_suffix_extension" {
  type        = string
  description = "Optional extension in the path of the ssm parameter used in vpc"
  default     = ""
}

# Tags
variable "tags" {
  type        = map(any)
  description = "Tags: both tags and tags_all"
  default     = {}
}
