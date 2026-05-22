# ACM Certificate Module
# Creates and validates ACM wildcard certificate for CloudFront

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.0"
      configuration_aliases = [aws.us-east-1]
    }
  }
}

resource "aws_acm_certificate" "wildcard_website" {
  provider                  = aws.us-east-1
  domain_name               = var.domain_root
  subject_alternative_names = ["*.${var.domain_root}"]
  validation_method         = "DNS"

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "wildcard_validation" {
  for_each = {
    for dvo in aws_acm_certificate.wildcard_website.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name            = each.value.name
  type            = each.value.type
  zone_id         = var.route53_zone_id
  records         = [each.value.record]
  allow_overwrite = true
  ttl             = 60
}

resource "aws_acm_certificate_validation" "wildcard_cert" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.wildcard_website.arn
  validation_record_fqdns = [for k, v in aws_route53_record.wildcard_validation : v.fqdn]

  timeouts {
    create = "5m"
  }
}
