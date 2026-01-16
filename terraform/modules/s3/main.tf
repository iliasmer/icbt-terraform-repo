data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.bucket_name

  tags = var.tags
  timeouts {}
}

resource "aws_s3_bucket_versioning" "s3_versioning" {
  bucket = aws_s3_bucket.s3_bucket.id
  versioning_configuration {
    status = var.versioning
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "data_retention_policy" {
  bucket                                 = aws_s3_bucket.s3_bucket.id
  transition_default_minimum_object_size = var.transition_default_minimum_object_size

  rule {
    id = "data_retention_policy_${var.bucket_name}"
    filter {}

    dynamic "expiration" {
      for_each = var.retention_days != null ? [1] : []
      content {
        days = var.retention_days
      }
    }

    dynamic "expiration" {
      for_each = var.retention_days == null ? [1] : []
      content {
        expired_object_delete_marker = false
      }
    }

    status = var.retention_enabled ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_bucket_encryption" {
  bucket = aws_s3_bucket.s3_bucket.id

  dynamic "rule" {
    for_each = var.kms_master_key_id == null ? [1] : []

    content {
      bucket_key_enabled = var.bucket_key_enabled

      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  dynamic "rule" {
    for_each = var.kms_master_key_id != null ? [1] : []

    content {
      bucket_key_enabled = var.bucket_key_enabled

      apply_server_side_encryption_by_default {
        kms_master_key_id = var.kms_master_key_id
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloud_formation_public_access_block" {
  bucket                  = aws_s3_bucket.s3_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "deny_insecure_transport_doc" {
  version = "2012-10-17"
  statement {
    sid    = "AllowSSLRequestsOnly"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.s3_bucket.arn,
      "${aws_s3_bucket.s3_bucket.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
  statement {
    sid    = "AllowManagementByAuthorizedPrincipals"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.s3_bucket.arn,
      "${aws_s3_bucket.s3_bucket.arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "combined_policy_doc" {
  # starts from custom policy (if any)
  source_policy_documents = var.custom_policy != null ? [var.custom_policy] : []

  # if deny_non_tls is true, merge in the entire deny_insecure_transport_doc
  override_policy_documents = var.deny_non_tls ? [data.aws_iam_policy_document.deny_insecure_transport_doc.json] : []
}

resource "aws_s3_bucket_policy" "combined_policy" {
  count  = var.deny_non_tls || var.custom_policy != null ? 1 : 0
  bucket = aws_s3_bucket.s3_bucket.id
  policy = data.aws_iam_policy_document.combined_policy_doc.json
}
