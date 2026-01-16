provider "aws" {
  region = "eu-central-1"
}

data "aws_caller_identity" "current" {}

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "ilias-merentitis-kth-thesis-tf-state-bucket"
    key     = "global/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }
}

resource "aws_iam_account_alias" "account_guard" {
  account_alias = "${local.project_name}-account"

  lifecycle {
    precondition {
      condition     = data.aws_caller_identity.current.account_id == local.aws_account_id
      error_message = "Wrong AWS account. Expected ${local.aws_account_id}."
    }
  }
}

