# module "summarize_trigger_lambda" {
#   source = "./modules/lambda/"

#   lambda_name  = "summarize-trigger-lambda"
#   py_file_name = "summarize-trigger-lambda"
#   source_path  = "${path.module}/lambda_files"
#   output_path  = "${path.module}/lambda_builds"

#   custom_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "s3:GetObject",
#           "s3:PutObject",
#           "s3:ListBucket"
#         ]
#         Resource = [
#           "arn:aws:s3:::kth-thesis-documents",
#           "arn:aws:s3:::kth-thesis-documents/*"
#         ]
#       }
#     ]
#   })
# }

# module "treatment_recommendation_trigger_lambda" {
#   source = "./modules/lambda/"

#   lambda_name  = "treatment-recommendation-trigger-lambda"
#   py_file_name = "treatment-recommendation-trigger-lambda"
#   source_path  = "${path.module}/lambda_files"
#   output_path  = "${path.module}/lambda_builds"

#   custom_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "s3:GetObject",
#           "s3:PutObject",
#           "s3:ListBucket"
#         ]
#         Resource = [
#           "arn:aws:s3:::kth-thesis-documents",
#           "arn:aws:s3:::kth-thesis-documents/*"
#         ]
#       }
#     ]
#   })
# }
