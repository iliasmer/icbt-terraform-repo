module "summarization_trigger_lambda" {
  source = "./modules/lambda/"

  lambda_name  = "summarization-trigger-lambda"
  py_file_name = "summarization-trigger-lambda"
  source_path  = "${path.module}/lambda_files"
  output_path  = "${path.module}/lambda_builds"

  lambda_vars = {
    QUEUE_URL = aws_sqs_queue.summarization_jobs.id
  }

  custom_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::kth-thesis-documents",
          "arn:aws:s3:::kth-thesis-documents/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.summarization_jobs.arn
      }
    ]
  })
}


module "treatment_recommendation_trigger_lambda" {
  source = "./modules/lambda/"

  lambda_name  = "treatment-recommendation-trigger-lambda"
  py_file_name = "treatment-recommendation-trigger-lambda"
  source_path  = "${path.module}/lambda_files"
  output_path  = "${path.module}/lambda_builds"

  lambda_vars = {
    QUEUE_URL = aws_sqs_queue.treatment_jobs.id
  }

  custom_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::kth-thesis-documents",
          "arn:aws:s3:::kth-thesis-documents/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.treatment_jobs.arn
      }
    ]
  })
}

module "whisper_trigger_lambda" {
  source = "./modules/lambda/"

  lambda_name  = "whisper-trigger-lambda"
  py_file_name = "whisper-trigger-lambda"
  source_path  = "${path.module}/lambda_files"
  output_path  = "${path.module}/lambda_builds"

  lambda_vars = {
    QUEUE_URL = aws_sqs_queue.whisper_jobs.id
  }

  custom_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::kth-thesis-documents",
          "arn:aws:s3:::kth-thesis-documents/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.whisper_jobs.arn
      }
    ]
  })
}