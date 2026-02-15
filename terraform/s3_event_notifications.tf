resource "aws_s3_bucket_notification" "s3_object_created_transcripts" {
  bucket = module.s3_bucket_kth_thesis_documents.id

  lambda_function {
    lambda_function_arn = module.summarization_trigger_lambda.arn
    events = [
      "s3:ObjectCreated:Put",
      "s3:ObjectCreated:CompleteMultipartUpload"
    ]
    filter_prefix = "transcripts/"
  }

  lambda_function {
    lambda_function_arn = module.treatment_recommendation_trigger_lambda.arn
    events = [
      "s3:ObjectCreated:Put",
      "s3:ObjectCreated:CompleteMultipartUpload"
    ]
    filter_prefix = "summaries/"
  }

  lambda_function {
    lambda_function_arn = module.whisper_trigger_lambda.arn
    events = [
      "s3:ObjectCreated:Put",
      "s3:ObjectCreated:CompleteMultipartUpload"
    ]
    filter_prefix = "audio/"
  }

  depends_on = [
    aws_lambda_permission.allow_s3_invoke_whisper_trigger_lambda,
    aws_lambda_permission.allow_s3_invoke_summarization_trigger_lambda,
    aws_lambda_permission.allow_s3_invoke_treatment_recommendation_trigger_lambda
  ]
}

resource "aws_lambda_permission" "allow_s3_invoke_summarization_trigger_lambda" {
  statement_id  = "AllowS3InvokeSummarizationTriggerLambda"
  action        = "lambda:InvokeFunction"
  function_name = module.summarization_trigger_lambda.name
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3_bucket_kth_thesis_documents.arn
}

resource "aws_lambda_permission" "allow_s3_invoke_treatment_recommendation_trigger_lambda" {
  statement_id  = "AllowS3InvokeSummarizationTriggerLambda"
  action        = "lambda:InvokeFunction"
  function_name = module.treatment_recommendation_trigger_lambda.name
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3_bucket_kth_thesis_documents.arn
}

resource "aws_lambda_permission" "allow_s3_invoke_whisper_trigger_lambda" {
  statement_id  = "AllowS3InvokeWhisperTriggerLambda"
  action        = "lambda:InvokeFunction"
  function_name = module.whisper_trigger_lambda.name
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3_bucket_kth_thesis_documents.arn
}