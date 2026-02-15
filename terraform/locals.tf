locals {
  project_name   = "icbt-kth-thesis"
  aws_account_id = "217793907183"

  vpc_id = "vpc-0712a6f1fdfd8fcae"
  subnet_ids = [
    "subnet-05c69dfe9433ee0b7", # eu-central-1a
    "subnet-051c578f4f6e28085", # eu-central-1b
    "subnet-05ed4d45227e7fa6f"  # eu-central-1c
  ]
}