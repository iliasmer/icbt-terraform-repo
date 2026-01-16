# Lambda function variables
variable "lambda_name" {
  type        = string
  description = "Unique name for your Lambda Function"
}

variable "handler_name" {
  type        = string
  description = "Lambda function handler"
  default     = "handler"
}

variable "custom_iam_role_name" {
  type        = string
  description = "Usually used because default name can get too long (>64 chars)"
  default     = ""
}

variable "py_file_name" {
  type        = string
  description = "Python-file that contains the handler"
}

variable "source_path" {
  type        = string
  description = "Path to .py source file with Python code"
}

variable "output_path" {
  type        = string
  description = "Path to .zip output file"
}

variable "enable_log_encryption" {
  type        = bool
  description = "Whether to encrypt CloudWatch logs with a dedicated KMS key"
  default     = false
}

variable "runtime" {
  type    = string
  default = "python3.12"
}

variable "timeout" {
  type        = number
  description = "The amount of time your Lambda Function has to run in seconds"
  default     = 15
}

variable "architectures" {
  type        = list(string)
  description = "ex: arm64"
  default     = ["x86_64"]
}

variable "lambda_vars" {
  type        = map(string)
  description = "Dynamic variables passed to lambda"
  default     = null
}

variable "schedule_expression" {
  type        = string
  description = "Triggers Lambda every X minutes between X and X, depending on the schedule expression"
  default     = null
}

variable "custom_policy" {
  type        = string
  description = "Custom policy (if any)"
  default     = null
}

variable "managed_policies" {
  type        = list(string)
  description = "list of managed policies to be attached"
  default     = []
}

variable "layers" {
  type        = list(string)
  description = "Added lambda layers (if any)"
  default     = []
}

variable "vpc_config" {
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  description = "VPC configuration (subnet_ids, mount path)"
  default     = null
}

variable "file_system_config" {
  type = list(object({
    arn              = string
    local_mount_path = string
  }))
  description = "File system configuration (arn, mount path)"
  default     = []
}


# Tags
variable "tags" {
  type        = map(any)
  description = "Tags: both tags and tags_all"
  default     = {}
}
