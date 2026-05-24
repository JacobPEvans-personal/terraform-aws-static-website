# Terraform AWS Static Website Module
# Main configuration that orchestrates all submodules

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

# Data source for Route53 hosted zone
data "aws_route53_zone" "main" {
  name         = var.domains-zone-root
  private_zone = false
}

# S3 Buckets Module
module "s3_buckets" {
  source = "./modules/s3-buckets"

  domain_name   = var.website-domain-main
  support_spa   = var.support-spa
  force_destroy = true
  tags = merge(var.tags, {
    ManagedBy = "terraform"
    Module    = "s3-buckets"
  })
}

# ACM Certificate Module
module "acm_certificate" {
  source = "./modules/acm-certificate"

  providers = {
    aws.us-east-1 = aws.us-east-1
  }

  domain_root     = var.domains-zone-root
  route53_zone_id = data.aws_route53_zone.main.zone_id
  tags = merge(var.tags, {
    ManagedBy = "terraform"
    Module    = "acm-certificate"
  })
}

# CloudFront Distributions Module
module "cloudfront" {
  source = "./modules/cloudfront"

  domain_name                      = var.website-domain-main
  aliases                          = concat([var.website-domain-main], var.website-additional-domains)
  root_bucket_id                   = module.s3_buckets.root_bucket_id
  root_bucket_website_endpoint     = module.s3_buckets.root_bucket_website_endpoint
  redirect_bucket_id               = module.s3_buckets.redirect_bucket_id
  redirect_bucket_website_endpoint = module.s3_buckets.redirect_bucket_website_endpoint
  logs_bucket_domain_name          = module.s3_buckets.logs_bucket_domain_name
  acm_certificate_arn              = module.acm_certificate.certificate_arn
  support_spa                      = var.support-spa
  lambda_function_arn              = var.cloudfront_lambda_function_arn
  lambda_function_event_type       = var.cloudfront_lambda_function_event_type
  redirect_enabled                 = var.website-domain-redirect != null && var.website-domain-redirect != ""
  redirect_domain                  = var.website-domain-redirect != null ? var.website-domain-redirect : ""
  tags = merge(var.tags, {
    ManagedBy = "terraform"
    Module    = "cloudfront"
  })

  depends_on = [module.acm_certificate]
}

# DNS Records Module
module "dns" {
  source = "./modules/dns"

  route53_zone_id                      = data.aws_route53_zone.main.zone_id
  domain_name                          = var.website-domain-main
  redirect_domain                      = var.website-domain-redirect != null ? var.website-domain-redirect : ""
  redirect_enabled                     = var.website-domain-redirect != null && var.website-domain-redirect != ""
  root_distribution_domain_name        = module.cloudfront.root_distribution_domain_name
  root_distribution_hosted_zone_id     = module.cloudfront.root_distribution_hosted_zone_id
  redirect_distribution_domain_name    = module.cloudfront.redirect_distribution_domain_name
  redirect_distribution_hosted_zone_id = module.cloudfront.redirect_distribution_hosted_zone_id

  depends_on = [module.cloudfront]
}
