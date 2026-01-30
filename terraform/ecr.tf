resource "aws_ecr_repository" "summarization_model" {
  name = "summarization"
}

resource "aws_ecr_repository" "summarization_worker" {
  name = "summarization-worker"
}

resource "aws_ecr_repository" "treatment_recommendation_model" {
  name = "treatment-recommendation"
}

resource "aws_ecr_repository" "treatment_recommendation_worker" {
  name = "treatment-recommendation-worker"
}
