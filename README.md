# AWS Static Website Terraform Module

[![CI](https://github.com/JacobPEvans/terraform-aws-static-website/workflows/CI/badge.svg)](https://github.com/JacobPEvans/terraform-aws-static-website/actions)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

A modern, secure, and fully tested Terraform module for hosting high-performance static websites on AWS with CloudFront CDN, S3, ACM certificates, and Route53 DNS.

> **👷 For Contributors:** Before making changes, read our [local-first testing policy](./CONTRIBUTING.md#️-critical-local-first-testing-policy). Run `make install-hooks` to automatically validate code before every commit/push. Run `make validate-local` to run all CI checks locally.

## Features

This module provisions and configures:

### Core Infrastructure

- **CloudFront** CDN distributions with HTTPS/TLS 1.2+
- **S3** buckets with encryption, versioning, and logging
- **ACM** wildcard SSL/TLS certificates with automatic DNS validation
- **Route53** DNS records for seamless domain configuration

### Security & Best Practices

- ✅ **Encryption at rest** for all S3 buckets (AES256)
- ✅ **S3 versioning** enabled on all buckets
- ✅ **Public access blocks** configured appropriately
- ✅ **Access logging** for both S3 and CloudFront
- ✅ **TLS 1.2** minimum for all HTTPS connections
- ✅ **Secure bucket policies** with least privilege access
- ✅ **Lambda@Edge support** for custom security headers and behaviors

### Developer Experience

- 🧪 **LocalStack integration** for local testing
- 🧪 **Terratest** integration tests with Go
- 🔄 **Pre-commit hooks** for code quality
- 🔄 **GitHub Actions** CI/CD pipeline
- 📚 **Multiple examples** (basic, SPA, Lambda@Edge)
- 📝 **Auto-generated documentation**

## Requirements

| Name | Version |
|------|---------|
| [Terraform](https://www.terraform.io/downloads.html) | >= 1.5.0 |
| [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest) | ~> 6.0 |

### Prerequisites

1. **AWS Account** with appropriate credentials configured
2. **Route53 Hosted Zone** for your domain
3. **AWS CLI** (optional, for deployment)
4. **Docker** (for LocalStack testing)

## Quick Start

### Basic Static Website

```hcl
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

module "static_website" {
  source = "github.com/jacobpevans/terraform-aws-static-website"

  website-domain-main     = "example.com"
  website-domain-redirect = "www.example.com"
  domains-zone-root       = "example.com"

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }

  providers = {
    aws.us-east-1 = aws.us-east-1
  }
}
```

### Single Page Application (SPA)

```hcl
module "spa_website" {
  source = "github.com/jacobpevans/terraform-aws-static-website"

  website-domain-main = "app.example.com"
  domains-zone-root   = "example.com"
  support-spa         = true  # Enables 404 → index.html redirect

  providers = {
    aws.us-east-1 = aws.us-east-1
  }
}
```

## Important Notes

### US-East-1 Requirement

The module requires an aliased AWS provider for `us-east-1` because:

- ACM certificates for CloudFront **must** be created in `us-east-1`
- These certificates are automatically distributed to all edge locations

This is an AWS requirement, not a module limitation.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `website-domain-main` | Main domain for the website (e.g., `example.com`) | `string` | - | yes |
| `domains-zone-root` | Root domain for Route53 hosted zone | `string` | - | yes |
| `website-domain-redirect` | Domain to redirect to main domain (e.g., `www.example.com`) | `string` | `""` | no |
| `website-additional-domains` | Additional domain aliases (e.g., `["alt.example.com"]`) | `list(string)` | `[]` | no |
| `support-spa` | Enable SPA mode (404 → index.html with 200 status) | `bool` | `false` | no |
| `cloudfront_lambda_function_arn` | ARN of Lambda@Edge function for custom behavior | `string` | `null` | no |
| `cloudfront_lambda_function_event_type` | Lambda@Edge trigger event (`viewer-request`, `viewer-response`, `origin-request`, `origin-response`) | `string` | `"origin-request"` | no |
| `tags` | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `website_cdn_root_id` | CloudFront distribution ID for the main website |
| `website_root_s3_bucket` | Name of the S3 bucket hosting website content |
| `website_logs_s3_bucket` | Name of the S3 bucket storing access logs |
| `website_redirect_s3_bucket` | Name of the S3 bucket handling redirects |

## Examples

See the [`examples/`](./examples/) directory for complete working examples:

- **[Basic](./examples/basic/)** - Simple static website with redirect
- **[SPA](./examples/spa/)** - Single Page Application configuration
- **[Lambda@Edge](./examples/with-lambda/)** - Advanced setup with security headers

## Testing

The module includes comprehensive unit and integration tests using Terratest and LocalStack.

**Quick Start:**

```bash
# Run unit tests (fast, no infrastructure required)
make test-unit

# Run integration tests with LocalStack
make test-local
```

**For detailed testing documentation, see [TESTING.md](./TESTING.md)** which includes:

- Complete setup instructions
- Unit test details
- Integration test details
- LocalStack configuration
- Troubleshooting guide
- CI/CD information

### Quick Testing Commands

```bash
# Unit tests only (2-5 minutes)
make test-unit

# Start LocalStack
make localstack-start

# Run integration tests
make test

# Stop LocalStack
make localstack-stop

# All-in-one: start LocalStack, test, and cleanup
make test-local
```

## Development

### Pre-commit Hooks

Install pre-commit hooks for automatic code quality checks:

```bash
# Install pre-commit
pip install pre-commit

# Install hooks
make pre-commit-install

# Run manually
make pre-commit-run
```

Hooks include:

- Terraform formatting (`terraform fmt`)
- Terraform validation (`terraform validate`)
- TFLint static analysis
- Trivy security scanning
- terraform-docs generation
- Trailing whitespace removal
- Secrets detection (gitleaks)

### Formatting and Validation

```bash
# Format code
make fmt

# Validate configuration
make validate

# Run linter
make lint
```

## CI/CD

This module includes a comprehensive GitHub Actions workflow that:

- ✅ Validates Terraform code
- ✅ Runs TFLint for best practices
- ✅ Scans for security issues with Trivy
- ✅ Runs pre-commit hooks
- ✅ Executes integration tests with LocalStack
- ✅ Generates and validates documentation

See [`.github/workflows/ci.yml`](./.github/workflows/ci.yml) for details.

## Architecture

```
┌─────────────┐
│   Route53   │ (DNS A Records)
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────┐
│   CloudFront Distribution       │ (HTTPS/TLS 1.2+)
│   - ACM Certificate             │
│   - Lambda@Edge (optional)      │
└──────┬──────────────────────────┘
       │
       ▼
┌─────────────────────────────────┐
│   S3 Bucket (Website)           │
│   - Versioning enabled          │
│   - Encryption at rest          │
│   - Access logging              │
└──────┬──────────────────────────┘
       │
       ▼
┌─────────────────────────────────┐
│   S3 Bucket (Logs)              │
│   - Versioning enabled          │
│   - Encryption at rest          │
└─────────────────────────────────┘
```

## Security Best Practices

This module implements AWS security best practices:

1. **Encryption**: All S3 buckets use AES256 encryption at rest
2. **Versioning**: Enabled on all buckets for data recovery
3. **Access Control**: Public access blocks configured appropriately
4. **Logging**: CloudFront and S3 access logs enabled
5. **TLS**: Minimum TLS 1.2 for all HTTPS connections
6. **Least Privilege**: Bucket policies grant minimal required access
7. **Security Headers**: Example Lambda@Edge for HSTS, CSP, etc.

## Migration from Older Versions

This version includes breaking changes for AWS Provider 5.0 compatibility:

- S3 bucket ACL, logging, and website configurations now use separate resources
- Minimum Terraform version increased to 1.5.0
- TLS 1.0 and 1.1 removed (TLS 1.2+ only)

See examples for updated usage patterns.

## Common Issues

### ACM Certificate Validation Timeout

If certificate validation hangs:

1. Verify Route53 hosted zone exists and is correct
2. Check DNS propagation with `dig` or `nslookup`
3. Ensure AWS account has permissions for Route53 record creation

### LocalStack Connection Issues

If tests fail with connection errors:

```bash
# Check LocalStack health
docker-compose ps

# View logs
make localstack-logs
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Run tests and pre-commit hooks
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## Roadmap

- [x] S3 bucket versioning
- [x] S3 bucket encryption
- [x] LocalStack testing infrastructure
- [x] Terratest integration tests
- [x] Pre-commit hooks
- [x] GitHub Actions CI/CD
- [ ] CloudFront Origin Access Control (OAC) instead of public buckets
- [ ] Optional CloudWatch alarms and monitoring
- [ ] Cost optimization recommendations
- [ ] Multi-region failover support

## License

This module is licensed under the Apache License, Version 2.0. See [LICENSE](./LICENSE) for details.

## Authors

- Original module: [@cloudmaniac](https://github.com/cloudmaniac)
- Modernization & testing: [@JacobPEvans](https://github.com/JacobPEvans)

## Acknowledgments

- Blog post describing the original thought process: [My Wordpress to Hugo Migration #2 - Hosting](https://cloudmaniac.net/wordpress-to-hugo-migration-2-hosting/)
- AWS documentation for best practices
- Terraform community for excellent modules and tools

## Support

For issues, questions, or contributions:

- **Issues**: [GitHub Issues](https://github.com/JacobPEvans/terraform-aws-static-website/issues)
- **Discussions**: [GitHub Discussions](https://github.com/JacobPEvans/terraform-aws-static-website/discussions)
