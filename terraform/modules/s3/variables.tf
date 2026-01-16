variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket to be created"
}

variable "versioning" {
  type        = string
  description = "Versioning status: Enabled or Disabled"
  default     = "Disabled"
}

variable "retention_enabled" {
  type        = bool
  description = "Whether the bucket has a retention policy enabled"
  default     = false
}

variable "retention_days" {
  type        = number
  description = "Number of days data is retained in the bucket"
  default     = null
}

variable "transition_default_minimum_object_size" {
  type        = string
  description = "Minimum object size before lifecycle transitions apply"
  default     = "varies_by_storage_class"

  validation {
    condition = contains(
      ["varies_by_storage_class", "all_storage_classes_128K"],
      var.transition_default_minimum_object_size
    )
    error_message = "Must be one of: varies_by_storage_class, all_storage_classes_128K"
  }
}

variable "kms_master_key_id" {
  type        = string
  description = "KMS key ID for SSE-KMS encryption, null means SSE-S3"
  default     = null
}

variable "bucket_key_enabled" {
  type        = bool
  description = "Whether to enable S3 Bucket Keys for SSE-KMS"
  default     = true
}

variable "custom_policy" {
  type        = string
  description = "Optional custom bucket policy JSON (jsonencode output)"
  default     = null
}

variable "deny_non_tls" {
  type        = bool
  description = "Whether to deny non-TLS (insecure transport) access"
  default     = true
}

variable "tags" {
  type        = map(any)
  description = "Tags applied to the S3 bucket"
  default     = {}
}
