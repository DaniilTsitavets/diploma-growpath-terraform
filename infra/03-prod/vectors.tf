resource "aws_s3vectors_vector_bucket" "kb" {
  vector_bucket_name = "growpath-prod-kb"
  force_destroy      = true

  encryption_configuration {
    sse_type = "AES256"
  }
}
