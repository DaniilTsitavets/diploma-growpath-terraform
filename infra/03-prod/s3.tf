data "aws_caller_identity" "current" {}

locals {
  bucket_suffix = data.aws_caller_identity.current.account_id
}

module "s3_frontend" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.18"

  bucket        = "growpath-prod-frontend-${local.bucket_suffix}"
  force_destroy = true

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  attach_deny_insecure_transport_policy = true
  attach_policy                         = true
  policy                                = data.aws_iam_policy_document.frontend_oac.json

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
      bucket_key_enabled = true
    }
  }

  lifecycle_rule = [{
    id      = "expire-noncurrent"
    enabled = true
    filter  = {}

    noncurrent_version_expiration = {
      days = 30
    }

    abort_incomplete_multipart_upload_days = 7
  }]
}

module "s3_media" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.18"

  bucket        = "growpath-prod-media-${local.bucket_suffix}"
  force_destroy = true

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  attach_deny_insecure_transport_policy = true
  attach_policy                         = true
  policy                                = data.aws_iam_policy_document.media_oac.json

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
      bucket_key_enabled = true
    }
  }

  lifecycle_rule = [{
    id      = "abort-multipart"
    enabled = true
    filter  = {}

    abort_incomplete_multipart_upload_days = 7
  }]
}

module "s3_photos" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.18"

  bucket        = "growpath-prod-photos-${local.bucket_suffix}"
  force_destroy = true

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  attach_deny_insecure_transport_policy = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
      bucket_key_enabled = true
    }
  }

  cors_rule = [{
    allowed_methods = ["GET", "HEAD", "PUT"]
    allowed_origins = ["https://${var.domain_name}"]
    allowed_headers = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }]

  lifecycle_rule = [{
    id      = "abort-multipart"
    enabled = true
    filter  = {}

    abort_incomplete_multipart_upload_days = 7
  }]
}
