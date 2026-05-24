# AI Instructions for terraform-aws-static-website

## Project Purpose

Reusable Terraform module that provisions an AWS static website stack:

- **S3** — root content bucket, optional redirect bucket, access logs bucket
- **CloudFront** — distributions in front of each bucket with SPA support
- **ACM** — DNS-validated certificate in `us-east-1`
- **Route53** — alias records into the user's existing hosted zone

The root module wires the four submodules under `modules/`. Public examples
live in `examples/`.

## Tech Stack

- **Terraform** `>= 1.5.0` (pinned via `.terraform-version`)
- **AWS provider** `~> 5.0`
- **Go** + **Terratest** for unit and integration tests under `tests/`
- **LocalStack** Pro-compatible image for offline integration runs
- **pre-commit** with `terraform_fmt`, `terraform_validate`, `tflint`,
  `terraform_docs`, `gitleaks`, `detect-private-key`, generic hygiene hooks

## Conventions

- **No remote backend by default.** Consumers add their own `backend` block.
- **No credentials in hooks.** `terraform validate` runs with `init -backend=false`.
- **CI auth = OIDC only** for any future job needing real AWS access.
- **release-please** drives version bumps from conventional commits.
- **RunsOn v3** self-hosted runners for Linux jobs. Workflows in this
  repo use `format('runs-on={0}/runner=<size>', github.run_id)` (where
  `{0}` is the `format()` placeholder substituted by `github.run_id`),
  with a fork-PR fallback to `ubuntu-latest`. See the canonical label
  catalog in `JacobPEvans/claude-code-plugins`
  (`infra-standards/skills/self-hosted-runners/SKILL.md`).

## Docker-in-CI Exception

Per `~/git/CLAUDE.md` Container deployment decision tree, LXC is the
default for home lab workloads and Docker is the exception. This repo's
integration tests run inside GitHub Actions using LocalStack as a
service container, which is **Docker-only**.

Vendor-only justification: LocalStack distributes only as a Docker image
and there is no native equivalent that emulates S3 + Route53 + ACM +
CloudFront together. Without LocalStack the test matrix would require
real AWS credentials in every PR, which is incompatible with our public
CI policy. The exception is bounded — Docker appears only in CI service
containers and developer-facing `docker-compose.yml` / `Makefile`
targets, never in production deployment paths.

## Dev Workflow

```bash
# One-time
make install-hooks
make pre-commit-install

# Iterate
make fmt              # terraform fmt -recursive
make validate         # terraform init -backend=false && validate
make lint             # tflint --init && tflint --recursive
make test-unit        # Go unit tests, no LocalStack
make test-local       # Boot LocalStack, run full integration tests
make validate-local   # Mirror of CI checks before pushing
```

The dev shell is activated by direnv via `.envrc` (`use flake` style).

## CI Surface

- `terraform-validate.yml` — `fmt -check`, `init -backend=false`, `validate`
- `tflint.yml` — recursive lint with `.tflint.hcl`
- `trivy.yml` — config scan, SARIF upload to GitHub Security
- `osv-scan.yml` — dependency scan
- `unit-tests.yml` — Go unit tests
- `integration-tests.yml` — plan tests on PR, full LocalStack run on push
- `release-please.yml`, `release.yml` — automated release pipeline

## File References

| Need | Location |
| --- | --- |
| Module entry point | `main.tf`, `variables.tf`, `outputs.tf` |
| Submodules | `modules/{s3-buckets,acm-certificate,cloudfront,dns}/` |
| Usage examples | `examples/` |
| Testing guide | `TESTING.md` |
| Contributor guide | `CONTRIBUTING.md` |
| Change history | `CHANGELOG.md` |
| CI workflows | `.github/workflows/` |

## PR Checklist

- [ ] `terraform fmt -check -recursive` passes
- [ ] `terraform validate` passes (with `init -backend=false`)
- [ ] `tflint --recursive` passes
- [ ] `make test-unit` passes (and `test-local` for behavior changes)
- [ ] Conventional commit subject (`feat:`, `fix:`, `chore:`, etc.)
- [ ] No secrets, real AWS account IDs, or user-specific paths
- [ ] README / examples updated for any public-surface change
