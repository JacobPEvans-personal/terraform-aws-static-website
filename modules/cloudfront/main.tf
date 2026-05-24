# CloudFront Module
# Creates CloudFront distributions for website and redirect

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

resource "aws_cloudfront_distribution" "website_cdn_root" {
  enabled             = true
  price_class         = var.price_class
  aliases             = var.aliases
  default_root_object = "index.html"
  wait_for_deployment = false

  origin {
    origin_id   = "origin-bucket-${var.root_bucket_id}"
    domain_name = var.root_bucket_website_endpoint

    custom_origin_config {
      origin_protocol_policy = "http-only"
      http_port              = 80
      https_port             = 443
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  logging_config {
    bucket = var.logs_bucket_domain_name
    prefix = "${var.domain_name}/"
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "origin-bucket-${var.root_bucket_id}"
    min_ttl                = 0
    default_ttl            = 300
    max_ttl                = 1200
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    dynamic "lambda_function_association" {
      for_each = var.lambda_function_arn != null ? [1] : []
      content {
        event_type = var.lambda_function_event_type
        lambda_arn = var.lambda_function_arn
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  custom_error_response {
    error_caching_min_ttl = 300
    error_code            = 404
    response_page_path    = var.support_spa ? "/index.html" : "/404.html"
    response_code         = var.support_spa ? 200 : 404
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [viewer_certificate]
  }
}

resource "aws_cloudfront_distribution" "website_cdn_redirect" {
  count = var.redirect_enabled ? 1 : 0

  enabled             = true
  price_class         = var.price_class
  aliases             = var.redirect_domain != "" ? [var.redirect_domain] : []
  wait_for_deployment = false

  origin {
    origin_id   = "origin-bucket-${var.redirect_bucket_id}"
    domain_name = var.redirect_bucket_website_endpoint

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  logging_config {
    bucket = var.logs_bucket_domain_name
    prefix = "${var.domain_name}-redirect/"
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "origin-bucket-${var.redirect_bucket_id}"
    min_ttl                = 0
    default_ttl            = 300
    max_ttl                = 1200
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [viewer_certificate]
  }
}
