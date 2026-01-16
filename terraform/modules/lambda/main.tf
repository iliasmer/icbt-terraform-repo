data "aws_caller_identity" "current" {}

resource "random_uuid" "lambda" {
  keepers = {
    for filename in setunion(
      toset([for fn in fileset("./${var.source_path}/", "**") : fn if !endswith(fn, ".zip")]),
    ) :
    filename => filemd5("./${var.source_path}/${filename}")
  }
}

data "archive_file" "lambda_files" {
  type        = "zip"
  source_dir  = var.source_path
  output_path = "${var.output_path}/${var.lambda_name}.zip"
}

resource "aws_lambda_function" "lambda_function" {
  function_name = var.lambda_name
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "${var.py_file_name}.${var.handler_name}"
  runtime       = var.runtime
  timeout       = var.timeout
  architectures = var.architectures
  filename      = data.archive_file.lambda_files.output_path
  layers        = var.layers

  environment {
    variables = var.lambda_vars
  }

  depends_on = [
    aws_iam_role.lambda_execution_role
  ]

  dynamic "file_system_config" {
    for_each = var.file_system_config
    content {
      arn              = file_system_config.value.arn
      local_mount_path = file_system_config.value.local_mount_path
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config == null ? [] : [var.vpc_config]
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  lifecycle {
    replace_triggered_by = [random_uuid.lambda]
    ignore_changes       = [filename]
  }

  tags = var.tags
  timeouts {}
}

resource "aws_cloudwatch_event_rule" "schedule_rule" {
  count               = var.schedule_expression != null ? 1 : 0
  name                = "${var.lambda_name}-schedule-expression"
  description         = "Triggers Lambda according to: ${var.schedule_expression}"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  count     = var.schedule_expression != null ? 1 : 0
  rule      = aws_cloudwatch_event_rule.schedule_rule[0].name
  target_id = aws_lambda_function.lambda_function.function_name
  arn       = aws_lambda_function.lambda_function.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  count         = var.schedule_expression != null ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatchTst"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule_rule[0].arn
}

resource "aws_kms_key" "lambda_logs_key" {
  count                   = var.enable_log_encryption ? 1 : 0
  description             = "KMS key for encrypting CloudWatch logs of ${var.lambda_name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Sid" : "EnableIAMUserPermissions",
        "Effect" : "Allow",
        "Principal" : { "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      {
        "Sid" : "AllowCWLCreateGrant",
        "Effect" : "Allow",
        "Principal" : { "Service" : "logs.eu-central-1.amazonaws.com"
        },
        "Action" : ["kms:CreateGrant"],
        "Resource" : "*",
        "Condition" : {
          "Bool" : { "kms:GrantIsForAWSResource" : "true" }
        }
      },
      {
        "Sid" : "AllowCWLUseOfTheKey",
        "Effect" : "Allow",
        "Principal" : { "Service" : "logs.eu-central-1.amazonaws.com"
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "kms:EncryptionContext:aws:logs:arn" : "arn:aws:logs:eu-central-1:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.lambda_name}*"
          }
        }
      },
      {
        "Sid" : "AllowAccountUseForCWL",
        "Effect" : "Allow",
        "Principal" : { "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "kms:EncryptionContext:aws:logs:arn" : "arn:aws:logs:eu-central-1:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.lambda_name}*"
          }
        }
      }
    ]
  })
}

resource "aws_kms_alias" "lambda_logs_alias" {
  count         = var.enable_log_encryption ? 1 : 0
  name          = "alias/${var.lambda_name}-logs"
  target_key_id = aws_kms_key.lambda_logs_key[0].id
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.lambda_name}"
  retention_in_days = 14
  kms_key_id        = var.enable_log_encryption ? aws_kms_key.lambda_logs_key[0].arn : null

  depends_on = [
    aws_kms_key.lambda_logs_key,
    aws_kms_alias.lambda_logs_alias
  ]
}

resource "aws_iam_role" "lambda_execution_role" {
  name = var.custom_iam_role_name == "" ? "execution_role-${var.lambda_name}" : var.custom_iam_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "lambda.amazonaws.com" },
        Action    = ["sts:AssumeRole"]
      }
    ]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_execution_role.name
}

resource "aws_iam_policy" "lambda_policy" {
  count  = var.custom_policy != null ? 1 : 0
  name   = "${var.lambda_name}-policy"
  policy = var.custom_policy
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  count      = var.custom_policy != null ? 1 : 0
  policy_arn = aws_iam_policy.lambda_policy[0].arn
  role       = aws_iam_role.lambda_execution_role.name
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each   = toset(var.managed_policies)
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = each.value
}

data "aws_iam_policy_document" "lambda_logging" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda-logging-${var.lambda_name}"
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.lambda_logging.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}
