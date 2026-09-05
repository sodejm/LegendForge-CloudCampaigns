# AWS low-cost Foundry profile

A small campaign profile with one Ubuntu 24.04 host, Foundry plus Cloudflare Tunnel, an independent retained data disk, and declarative stop/start. [Validation evidence](../../../docs/TERRAFORM_VALIDATION.md) covers schema, mock lifecycle, and disk-safety tests. A live deployment and licensed-world restore drill remain operator acceptance checks.

## Resources and trade-offs

`us-east-1` / `us-east-1a`, one `t3.small` (2 vCPU, 2 GB), 20 GB encrypted gp3 boot disk, 30 GB independent encrypted gp3 data volume, one VPC/subnet/internet gateway, ephemeral public IPv4, and an SSM role. The security group has no inbound rules.

The root omits RDS, NAT Gateway, ALB, CloudFront, Route53, S3 buckets, and managed log ingestion. Cloudflare routes, DNS, Access policies, backups, and schedules are configured by the operator. Foundry listens only on the internal Docker network; no application port is published to the host. A public address permits outbound package downloads and tunnel traffic.

This is a single failure domain. The 2 GB size is the Foundry minimum, with limited headroom for systems, modules, and assets; prefer 4 GB after measuring your workload. There is no autoscaling, failover, automatic off-host backup, or shared world filesystem. See the [common workload and cost comparison](../../../docs/DEPLOYMENT_MODEL_COMPARISON.md).

## Prerequisites

Use Terraform 1.7 or later and AWS credentials with EC2, VPC, EBS, and IAM provisioning permissions; AWS CLI and Session Manager plugin for administration.

Have a valid Foundry license and download account, a strong admin password, and reviewed Foundry/cloudflared image versions. Create a remotely managed Cloudflare tunnel and configure its public hostname route to **`http://foundry:30000`**, reachable inside the Compose network. Supply that tunnel token and hostname in `app`. Configure DNS and any Cloudflare Access policy before inviting players. These resources are external to Terraform here.

Secrets are present in Terraform state and instance user data. Restrict those surfaces and use encrypted, access-controlled state with locking. Do not commit variable files, saved plans, tokens, or state.

## Configure, plan, and deploy

From the repository root, choose this directory once:

```bash
cd infrastructure/deployments/aws-low-cost
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars; replace every placeholder and keep paused=false.
terraform init
terraform validate
terraform plan -out=deployment.tfplan
# Review all actions and costs; this next command provisions billable resources.
terraform apply deployment.tfplan
```

Choose region and zone together; the independent data disk is zonal. This is a separate Terraform root: do not reuse state from the standard profile or move resources between profiles without a migration plan. The example tunnel image is intentionally invalid until a reviewed numeric version or digest replaces its placeholder.

## Connect and accept the deployment

From this Terraform directory after apply:

```bash
aws ssm start-session --target "$(terraform output -raw instance_id)" --region us-east-1
```

Use your configured region/zone if changed. Wait for first boot to finish, then verify the data mount, service, public hostname, login, and world persistence using [shared operations](../../../docs/LOW_COST_OPERATIONS.md). A mock plan does not prove IAM authorization, regional capacity, image downloads, tunnel configuration, or a working licensed world.

## Pause, resize, back up, and recover

Set `paused=true` in the existing root/state and review/apply a saved plan that only stops the VM. Record and compare the VM and `data_disk_id` outputs before and after. Set `paused=false` and repeat to resume. Wait for completed first boot before the first pause. Storage and backup costs remain while compute is stopped; the public ephemeral address may change.

For more memory, change `instance_type` to `t3.medium` (or a supported larger t3) in a backed-up maintenance window. Review the plan for replacement, confirm retained disk/instance identity, and test a world after restart. Grow `data_disk_gb` only with the filesystem expansion procedure; do not shrink it.

Follow [backup, restore drills, scheduling, upgrades, and retirement](../../../docs/LOW_COST_OPERATIONS.md). Independent disks and deletion guards are not backups. Cloud-init is first boot only; review image/credential changes separately from pause/resume. To exit this profile, restore an off-host archive into another deployment with separate state, validate a test hostname, then cut over players and retire old resources after acceptance.

## References

- [Standard AWS profile](../aws/README.md)
- [Deployment model and cost comparison](../../../docs/DEPLOYMENT_MODEL_COMPARISON.md)
- [Documentation index](../../../DOCUMENTATION_INDEX.md)
- [Wiki low-cost profiles](../../../wiki/Low-Cost-Profiles.md)
