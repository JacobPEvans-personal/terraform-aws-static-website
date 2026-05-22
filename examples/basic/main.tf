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
  region = "us-east-1"
}

module "static_website" {
  source = "../.."

  website-domain-main     = var.website-domain-main
  website-domain-redirect = var.website-domain-redirect
  domains-zone-root       = var.domains-zone-root
  support-spa             = var.support-spa

  tags = {
    Environment = "example"
    ManagedBy   = "terraform"
    Example     = "basic"
  }
}
