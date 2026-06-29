# Quickstart

Use this page when you want the shortest path from repository clone to a running LegendForge deployment.

## Prerequisites

You need:

1. Terraform 1.0 or newer
2. One target cloud platform: AWS, Azure, GCP, or Hetzner
3. A valid Foundry VTT license or Foundry account download credentials
4. A Cloudflare-managed DNS zone
5. A Cloudflare Tunnel token
6. A strong Foundry admin key

## 5-Step Deployment Flow

### 1. Copy the configuration templates

```bash
cp config/foundry.auto.tfvars.example config/foundry.auto.tfvars
cp config/secrets.auto.tfvars.example config/secrets.auto.tfvars
```

### 2. Fill in the non-secret deployment settings

Update:

- `foundry_hostname`
- `cloudflare_zone`
- `access_allowed_emails`
- `compute_enabled`
- `data_volume_size_gb`

### 3. Fill in the secret settings

Update:

- `cloudflare_account_id`
- `cloudflare_api_token`
- `foundry_username` and `foundry_password`, or `foundry_release_url`
- `foundry_license_key`
- `foundry_admin_key`

Keep `config/secrets.auto.tfvars` private.

### 4. Choose a provider and deploy

#### AWS

```bash
cd infrastructure/deployments/aws
terraform init
terraform plan -var-file="../../config/foundry.auto.tfvars" -var-file="../../config/secrets.auto.tfvars"
terraform apply -var-file="../../config/foundry.auto.tfvars" -var-file="../../config/secrets.auto.tfvars"
```

#### Azure

```bash
cd infrastructure/deployments/azure
terraform init
terraform plan -var-file="../../config/foundry.auto.tfvars" -var-file="../../config/secrets.auto.tfvars"
terraform apply -var-file="../../config/foundry.auto.tfvars" -var-file="../../config/secrets.auto.tfvars"
```

#### GCP

```bash
cd infrastructure/deployments/gcp
terraform init
terraform plan -var-file="../../config/foundry.auto.tfvars" -var-file="../../config/secrets.auto.tfvars" -var="project_id=your-project-id"
terraform apply -var-file="../../config/foundry.auto.tfvars" -var-file="../../config/secrets.auto.tfvars" -var="project_id=your-project-id"
```

#### Hetzner

```bash
export HCLOUD_TOKEN="your-hetzner-token"
cd infrastructure/deployments/hetzner
terraform init
terraform plan -var-file="../../config/foundry.auto.tfvars" -var-file="../../config/secrets.auto.tfvars"
terraform apply -var-file="../../config/foundry.auto.tfvars" -var-file="../../config/secrets.auto.tfvars"
```

### 5. Finalize inside Foundry

1. Confirm the instance is reachable through Cloudflare Tunnel
2. Open the Foundry URL
3. Complete Foundry setup with the admin key
4. Install your desired system
5. Create or restore your worlds
6. Add modules only after the base platform is stable

## Best Next Pages

- [Installation](Installation)
- [Provider Guide](Provider-Guide)
- [How-To](How-To)
