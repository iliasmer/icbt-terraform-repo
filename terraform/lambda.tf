module "summarize_trigger_lambda" {
  source = "./modules/lambda/"

  lambda_name  = "summarize-trigger-lambda"
  py_file_name = "summarize-trigger-lambda"
  source_path  = "${path.module}/lambda_files"
  output_path  = "${path.module}/lambda_builds"
}