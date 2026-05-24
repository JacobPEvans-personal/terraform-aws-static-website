# DNS Module
# Creates Route53 DNS records for CloudFront distributions

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

resource "aws_route53_record" "website_cdn_root_record" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.root_distribution_domain_name
    zone_id                = var.root_distribution_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "website_cdn_redirect_record" {
  count = var.redirect_enabled ? 1 : 0

  zone_id = var.route53_zone_id
  name    = var.redirect_domain
  type    = "A"

  alias {
    name                   = var.redirect_distribution_domain_name
    zone_id                = var.redirect_distribution_hosted_zone_id
    evaluate_target_health = false
  }
}
