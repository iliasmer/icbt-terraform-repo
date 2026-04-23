
resource "aws_ecr_repository" "whisper_model" {
  name = "whisper"
}

resource "aws_ecr_repository" "whisper_worker" {
  name = "whisper-worker"
}




resource "aws_ecr_repository" "summarization_model" {
  name = "summarization"
}

resource "aws_ecr_repository" "summarization_worker" {
  name = "summarization-worker"
}




resource "aws_ecr_repository" "pttsd_model" {
  name = "pttsd"
}

resource "aws_ecr_repository" "pttsd_worker" {
  name = "pttsd-worker"
}
