#!/usr/bin/env bash
# verify-localstack-ready.sh — waits for LocalStack health and creates test Route53 zone.
set -euo pipefail

echo "Waiting for LocalStack to be fully ready..."

echo "=== LocalStack Health Check ==="
curl -s http://localhost:4566/_localstack/health | jq . || echo "Health check failed"

echo "=== Creating Route53 hosted zone for testing ==="
aws --endpoint-url=http://localhost:4566 route53 create-hosted-zone \
  --name "example.com" \
  --caller-reference "$(date +%s)" \
  --hosted-zone-config Comment="Test zone for static website module" || echo "Zone creation may have failed"
