# S3 Buckets Module
# Creates all S3 buckets required for the static website

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

## Logs Bucket
resource "aws_s3_bucket" "website_logs" {
  bucket        = "${var.domain_name}-logs"
  force_destroy = var.force_destroy

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "website_logs" {
  bucket = aws_s3_bucket.website_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "website_logs" {
  bucket = aws_s3_bucket.website_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_acl" "website_logs" {
  bucket = aws_s3_bucket.website_logs.id
  acl    = "log-delivery-write"

  depends_on = [aws_s3_bucket_ownership_controls.website_logs]
}

resource "aws_s3_bucket_ownership_controls" "website_logs" {
  bucket = aws_s3_bucket.website_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "website_logs" {
  bucket = aws_s3_bucket.website_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

## Root Bucket
resource "aws_s3_bucket" "website_root" {
  bucket        = "${var.domain_name}-root"
  force_destroy = var.force_destroy

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "website_root" {
  bucket = aws_s3_bucket.website_root.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "website_root" {
  bucket = aws_s3_bucket.website_root.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "website_root" {
  bucket = aws_s3_bucket.website_root.id

  target_bucket = aws_s3_bucket.website_logs.id
  target_prefix = "${var.domain_name}/"
}

resource "aws_s3_bucket_website_configuration" "website_root" {
  bucket = aws_s3_bucket.website_root.id

  index_document {
    suffix = "index.html"
  }

  dynamic "error_document" {
    for_each = var.support_spa ? [] : [1]
    content {
      key = "404.html"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "website_root" {
  bucket = aws_s3_bucket.website_root.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "website_root" {
  bucket = aws_s3_bucket.website_root.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "website_root" {
  bucket = aws_s3_bucket.website_root.id

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "PolicyForWebsiteEndpointsPublicContent"
    Statement = [
      {
        Sid       = "PublicRead"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource = [
          "${aws_s3_bucket.website_root.arn}/*",
          aws_s3_bucket.website_root.arn
        ]
      }
    ]
  })
}

## Redirect Bucket
resource "aws_s3_bucket" "website_redirect" {
  bucket        = "${var.domain_name}-redirect"
  force_destroy = var.force_destroy

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "website_redirect" {
  bucket = aws_s3_bucket.website_redirect.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "website_redirect" {
  bucket = aws_s3_bucket.website_redirect.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "website_redirect" {
  bucket = aws_s3_bucket.website_redirect.id

  target_bucket = aws_s3_bucket.website_logs.id
  target_prefix = "${var.domain_name}-redirect/"
}

resource "aws_s3_bucket_website_configuration" "website_redirect" {
  bucket = aws_s3_bucket.website_redirect.id

  redirect_all_requests_to {
    host_name = var.domain_name
    protocol  = "https"
  }
}

resource "aws_s3_bucket_ownership_controls" "website_redirect" {
  bucket = aws_s3_bucket.website_redirect.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "website_redirect" {
  bucket = aws_s3_bucket.website_redirect.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
