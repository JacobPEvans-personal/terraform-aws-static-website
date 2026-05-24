terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

# Example Lambda@Edge function for security headers
resource "aws_iam_role" "lambda_edge" {
  name = "lambda-edge-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "edgelambda.amazonaws.com"
          ]
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_edge" {
  role       = aws_iam_role.lambda_edge.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda_edge" {
  type        = "zip"
  output_path = "${path.module}/lambda_edge.zip"

  source {
    content  = <<-EOT
      exports.handler = async (event) => {
        const response = event.Records[0].cf.response;
        const headers = response.headers;

        headers['strict-transport-security'] = [{
          key: 'Strict-Transport-Security',
          value: 'max-age=63072000; includeSubdomains; preload'
        }];
        headers['x-content-type-options'] = [{
          key: 'X-Content-Type-Options',
          value: 'nosniff'
        }];
        headers['x-frame-options'] = [{
          key: 'X-Frame-Options',
          value: 'DENY'
        }];
        headers['x-xss-protection'] = [{
          key: 'X-XSS-Protection',
          value: '1; mode=block'
        }];

        return response;
      };
    EOT
    filename = "index.js"
  }
}

resource "aws_lambda_function" "security_headers" {
  provider         = aws.us-east-1
  filename         = data.archive_file.lambda_edge.output_path
  function_name    = "security-headers-lambda-edge"
  role             = aws_iam_role.lambda_edge.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.lambda_edge.output_base64sha256
  runtime          = "nodejs20.x"
  publish          = true

  tags = {
    Environment = "example"
    ManagedBy   = "terraform"
  }
}

module "static_website_with_lambda" {
  source = "../.."

  website-domain-main                   = var.website-domain-main
  website-domain-redirect               = var.website-domain-redirect
  domains-zone-root                     = var.domains-zone-root
  support-spa                           = var.support-spa
  cloudfront_lambda_function_arn        = aws_lambda_function.security_headers.qualified_arn
  cloudfront_lambda_function_event_type = "viewer-response"

  tags = {
    Environment = "example"
    ManagedBy   = "terraform"
    Example     = "with-lambda"
  }
}
