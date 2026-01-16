resource "aws_lambda_permission" "allow_s3_invoke_summarize_lambda" {
  statement_id  = "AllowS3InvokeSummarizeLambda"
  action        = "lambda:InvokeFunction"
  function_name = module.summarize_trigger_lambda.name
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3_bucket_kth_thesis_documents.arn
}

resource "aws_s3_bucket_notification" "s3_object_created_raw_text" {
  bucket = module.s3_bucket_kth_thesis_documents.id

  lambda_function {
    lambda_function_arn = module.summarize_trigger_lambda.arn
    events = [
        "s3:ObjectCreated:Put",
        "s3:ObjectCreated:CompleteMultipartUpload"
    ]

    filter_prefix       = "raw_text/"
  }

  depends_on = [
    aws_lambda_permission.allow_s3_invoke_summarize_lambda
  ]
}