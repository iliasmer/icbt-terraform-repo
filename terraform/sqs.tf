resource "aws_sqs_queue" "whisper_jobs" {
  name                       = "kth-whisper-jobs"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 1209600
}

resource "aws_sqs_queue" "whisper_jobs_dlq" {
  name                      = "kth-whisper-jobs-dlq"
  message_retention_seconds = 1209600
}

resource "aws_sqs_queue_redrive_policy" "whisper_redrive" {
  queue_url = aws_sqs_queue.whisper_jobs.id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.whisper_jobs_dlq.arn
    maxReceiveCount     = 60
  })
}




resource "aws_sqs_queue" "summarization_jobs" {
  name                       = "kth-summarization-jobs"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 1209600
}

resource "aws_sqs_queue" "summarization_jobs_dlq" {
  name                      = "kth-summarization-jobs-dlq"
  message_retention_seconds = 1209600
}

resource "aws_sqs_queue_redrive_policy" "summarization_redrive" {
  queue_url = aws_sqs_queue.summarization_jobs.id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.summarization_jobs_dlq.arn
    maxReceiveCount     = 30
  })
}




resource "aws_sqs_queue" "pttsd_jobs" {
  name                       = "kth-pttsd-jobs"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 1209600
}

resource "aws_sqs_queue" "pttsd_jobs_dlq" {
  name                      = "kth-pttsd-jobs-dlq"
  message_retention_seconds = 1209600
}

resource "aws_sqs_queue_redrive_policy" "pttsd_redrive" {
  queue_url = aws_sqs_queue.pttsd_jobs.id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.pttsd_jobs_dlq.arn
    maxReceiveCount     = 30
  })
}





