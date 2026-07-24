# Installation

This page summarizes the setup inputs and prerequisites needed before your first LegendForge deployment.

## Local Tooling

Install:

- Terraform
- Your provider CLI:
  - `aws`
  - `az`
  - `gcloud`
- A text editor for `*.tfvars`

For Hetzner, Terraform and an API token are sufficient for the basic flow.

## Foundry Requirements

You need:

- A valid Foundry VTT license key
- A Foundry account username/password, or a timed release URL
- A strong admin key for `/setup`
- A target game system or world plan for post-deployment setup

## Cloudflare Requirements

LegendForge assumes a Cloudflare-managed domain and tunnel-based ingress.

Prepare:

- Cloudflare account ID
- Scoped Cloudflare API token
- DNS zone
- Tunnel token
- Optional Cloudflare Access allow-list emails

## Configuration Files

### `config/foundry.auto.tfvars`

This file contains non-secret deployment settings such as:

- hostname
- Cloudflare zone
- access gate emails
- compute enable/disable control
- optional break-glass SSH settings
- data volume size

### `config/secrets.auto.tfvars`

This file contains sensitive values such as:

- Cloudflare credentials
- Foundry download credentials
- Foundry license key
- Foundry admin key

Do not commit this file.

## Provider-Specific Notes

### AWS

- AWS account and CLI credentials
- Route53 if you are using AWS DNS workflows
- Optional remote Terraform backend in S3 with DynamoDB locking

### Azure

- Azure subscription
- Azure CLI login
- SSH key for VM access if required

### GCP

- Billing-enabled GCP project
- Required APIs enabled
- Service account credentials for Terraform

### Hetzner

- `HCLOUD_TOKEN`
- Simple single-provider deployment path

## Security Defaults

- Prefer Cloudflare Tunnel over public exposure
- Keep SSH disabled unless you need break-glass access
- Scope Cloudflare API tokens narrowly
- Treat all secrets as private and rotate them if exposed

## Related Pages

- [Quickstart](Quickstart)
- [Architecture and Security](Architecture-and-Security)
- [Provider Guide](Provider-Guide)
