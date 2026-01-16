output "arn" {
  description = "arn of the bucket"
  value       = aws_s3_bucket.s3_bucket.arn
}

output "id" {
  description = "id of the created bucket"
  value       = aws_s3_bucket.s3_bucket.id
}