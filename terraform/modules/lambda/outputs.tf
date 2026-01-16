output "arn" {
  description = "The Amazon Resource Name (ARN) identifying your Lambda Function."
  value       = aws_lambda_function.lambda_function.arn
}

output "name" {
  description = "The unique name of your Lambda Function."
  value       = aws_lambda_function.lambda_function.function_name
}

output "invoke_arn" {
  description = "The ARN to be used for invoking Lambda Function from API Gateway - to be used in aws_api_gateway_integration's uri"
  value       = aws_lambda_function.lambda_function.invoke_arn
}

output "role_arn" {
  description = "The unique arn of your Lambda Function's execution role."
  value       = aws_iam_role.lambda_execution_role.arn
}

output "log_group_arn" {
  description = "The unique arn of the lambda's cloudwatch group"
  value       = aws_cloudwatch_log_group.lambda_log_group.arn
}