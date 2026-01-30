module "s3_bucket_kth_thesis_documents" {
  source = "./modules/s3"

  bucket_name = "kth-thesis-documents"
}