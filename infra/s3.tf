resource "random_string" "suffix" {
  count   = var.enable_s3 ? 1 : 0
  length  = 6
  upper   = false
  special = false
}

resource "aws_s3_bucket" "data" {
  count  = var.enable_s3 ? 1 : 0
  bucket = "${local.name}-data-${random_string.suffix[0].result}"
  tags   = local.tags
}

resource "aws_s3_bucket_versioning" "this" {
  count  = var.enable_s3 && var.s3_enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.data[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = var.enable_s3 ? 1 : 0
  bucket = aws_s3_bucket.data[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  count                   = var.enable_s3 ? 1 : 0
  bucket                  = aws_s3_bucket.data[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
