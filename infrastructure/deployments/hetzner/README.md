# Hetzner Foundry VTT deployment

This is the low-cost, single-server LegendForge deployment. Terraform creates a Hetzner private network and firewall, one Ubuntu 22.04 server when compute is enabled, and one ext4 data volume attached to that server. Cloud-init installs Docker and starts `foundry` and `cloudflared` containers; Cloudflare Tunnel provides the intended public ingress.

It is a practical small-instance deployment, not a highly available or managed Foundry service. Read [Operational limits](#operational-limits-and-trade-offs) before using it for an active campaign.

## Topology and security posture

```text
Players -> Cloudflare DNS / Tunnel -> cloudflared container -> foundry container (port 30000)
                                              |
                         outbound tunnel from one Hetzner server
                                              |
                              attached ext4 volume at /opt/foundry/data
```

- **One failure domain:** the module has one `hcloud_server`, one data volume, and no load balancer, replica, managed database, or automatic failover.
- **Ingress:** the Terraform firewall adds no public Foundry rule. The Cloudflare Tunnel token must already be created and configured in Cloudflare so it routes the chosen hostname to the Foundry service. Terraform does not create the Cloudflare tunnel, DNS record, Access policy, or hostname route.
- **SSH:** `admin_ssh_cidr` is `null` by default, which leaves port 22 closed by this Terraform firewall. If break-glass SSH is required, set it to one trusted public address in CIDR notation (for example, `203.0.113.10/32`), keep the scope narrow, and remove it again when finished. This module does **not** install an SSH public key, so ensure access is provisioned by an approved Hetzner-console/manual process before relying on SSH.
- **Secrets:** keep the Cloudflare tunnel token, Foundry credentials, licence key, and admin key in an ignored secrets file or another approved secret store. Do not paste them in shell history, issue comments, Terraform output, or version control.

## Prerequisites

- Terraform 1.0 or later and a Hetzner Cloud account/API token.
- A Cloudflare-managed zone, plus a pre-created Cloudflare Tunnel and hostname route. Obtain its token from Cloudflare; this repository only passes it to `cloudflared`.
- Foundry image and licence configuration, along with an ignored secrets file.
- For backup or restore: an encrypted off-server storage location and a tested administrative access method. The Hetzner console is a manual prerequisite for provider snapshots/backups and recovery operations.

## Configure and deploy

Run these commands from this directory, `infrastructure/deployments/hetzner`. The repository `config/` directory is three levels above it.

```bash
# From repository root, create local configuration files once.
cp config/foundry.auto.tfvars.example config/foundry.auto.tfvars
# Create config/secrets.auto.tfvars through your approved secret-handling process.

cd infrastructure/deployments/hetzner
terraform init
terraform plan \
  -var-file="../../../config/foundry.auto.tfvars" \
  -var-file="../../../config/secrets.auto.tfvars"
terraform apply \
  -var-file="../../../config/foundry.auto.tfvars" \
  -var-file="../../../config/secrets.auto.tfvars"
```

Set `hcloud_token` in the secrets file (the provider is explicitly configured from that variable). Never commit the resulting `*.tfvars` files.

After apply, retrieve the public address and check bootstrap progress:

```bash
terraform output -raw server_public_ipv4
ssh root@"$(terraform output -raw server_public_ipv4)"

# On the server
cloud-init status --long
sudo tail -n 200 /var/log/cloud-init-output.log
cd /opt/foundry && sudo docker compose ps
sudo docker logs --tail=200 foundry
sudo docker logs --tail=200 cloudflared
```

SSH works only when a reachable SSH credential and a narrowly scoped `admin_ssh_cidr` have been deliberately provisioned. If SSH is closed, use the Hetzner console's approved recovery/access path instead.

## Sizing and cost

The Terraform defaults are `cx21`, `fsn1-dc14`, and a 20 GB volume. Treat them as a starting point for a small group, not a capacity commitment: monitor memory, CPU, and `/opt/foundry/data` during sessions, then choose a supported Hetzner server type and increase `data_volume_size_gb` when measured demand requires it.

As of 2026-07-20, repository planning material budgets this deployment at roughly **€6–8/month** for a small server and 20 GB volume, before optional services, taxes, backups, or transfer-related charges. This is an estimate, not a guarantee; confirm the current region, server type, volume, traffic, and backup pricing in the [Hetzner Cloud pricing page](https://www.hetzner.com/cloud/) before applying.

To request a larger data volume, change `data_volume_size_gb` and inspect the
plan before applying. Volume growth and server-type changes are provider
operations with possible restart or maintenance impact; take and verify an
off-server backup first. Increasing the variable grows the Hetzner block
volume, but this module does not grow an existing ext4 filesystem; complete the
manual filesystem step in [Resize](#resize) before relying on the added
capacity. The module also does not expose an in-place server power-state
control, so do not assume a Terraform apply will "pause" a server without
replacement effects.

## Backup and recovery

Terraform state is not a backup. The Foundry data volume contains the state that matters, and the module has no scheduled backup resource.

### Off-server backup procedure

1. **Manual prerequisite:** ensure a tested SSH/console route to the server and an encrypted off-server destination owned by the operator (for example, an approved backup host or object storage workflow). Do not put destination credentials in Terraform variables.
2. Schedule a maintenance window and verify that the expected data volume is mounted. From the repository's `infrastructure/deployments/hetzner` directory, stream the tested archive helper to the server so no permanent script installation is required:

   ```bash
   server_ip="$(terraform output -raw server_public_ipv4)"
   archive_name="foundry-data-$(date +%F).tgz"
   backup_dir="/root/foundry-backups"

   ssh root@"${server_ip}" 'findmnt /opt/foundry/data'
   ssh root@"${server_ip}" "install -d -m 700 ${backup_dir}"
   ssh root@"${server_ip}" 'cd /opt/foundry && docker compose stop foundry'
   ssh root@"${server_ip}" \
     "bash -s -- backup /opt/foundry/data ${backup_dir}/${archive_name}" \
     < ../../../scripts/hetzner-data-archive.sh
   ssh root@"${server_ip}" 'cd /opt/foundry && docker compose start foundry'
   ```

   If Foundry does not restart, keep the maintenance window active and resolve
   that failure before reopening player traffic.

3. Transfer both files to the approved encrypted off-server destination, verify the checksum after transfer, and record the restore instructions and retention date:

   ```bash
   scp root@"${server_ip}":"${backup_dir}/${archive_name}" .
   scp root@"${server_ip}":"${backup_dir}/${archive_name}.sha256" .
   shasum -a 256 -c "${archive_name}.sha256"
   ```

   On Linux, use `sha256sum -c` instead. Remove the server's temporary archive
   and checksum only after the off-server copies verify.
4. Hetzner Server Backups and Snapshots cover only the server's boot disk; they
   exclude attached Volumes, and Hetzner does not provide Volume backups or
   snapshots. They can help reconstruct server configuration, but they do not
   protect `/opt/foundry/data`. The verified off-server application archive is
   the data-recovery copy documented here.
5. Periodically test a restore in a non-production environment. A backup is only trustworthy after a successful restore test.

### Restore procedure

1. **Manual prerequisite:** use the Hetzner console/operator workflow to recover or replace infrastructure as needed, and keep the server isolated from player traffic until validation completes.
2. Apply this deployment to create the server and data volume, then wait for cloud-init and Docker to finish. Confirm the volume mount path with `findmnt`.
3. Verify the off-server checksum, upload both files into a private root-owned
   directory, and stop Foundry. Because the freshly started container may
   already have created `Config`, `Data`, or `Logs`, run the helper's quarantine
   command before restore. It moves application-created content into a private
   `.restore-quarantine.*` directory on the same volume and reports that path;
   it does not delete it. Restore then accepts only the fresh `.formatted`
   marker, empty `lost+found`, and that quarantine directory. It refuses a
   checksum mismatch, unsafe archive paths, symlink inputs, the reserved
   quarantine namespace in an archive, or any other destination content:

   ```bash
   server_ip="$(terraform output -raw server_public_ipv4)"
   archive_name="foundry-data-REPLACE-WITH-BACKUP-DATE.tgz"
   backup_dir="/root/foundry-backups"

   shasum -a 256 -c "${archive_name}.sha256"
   ssh root@"${server_ip}" "install -d -m 700 ${backup_dir}"
   scp "${archive_name}" "${archive_name}.sha256" \
     root@"${server_ip}":"${backup_dir}/"
   ssh root@"${server_ip}" 'findmnt /opt/foundry/data'
   ssh root@"${server_ip}" 'cd /opt/foundry && docker compose stop foundry'
   ssh root@"${server_ip}" \
     "bash -s -- quarantine /opt/foundry/data" \
     < ../../../scripts/hetzner-data-archive.sh
   ssh root@"${server_ip}" \
     "bash -s -- restore ${backup_dir}/${archive_name} /opt/foundry/data" \
     < ../../../scripts/hetzner-data-archive.sh
   ssh root@"${server_ip}" 'cd /opt/foundry && docker compose start foundry'
   ssh root@"${server_ip}" 'docker logs --tail=200 foundry'
   ```

4. Verify worlds, assets, user access, Cloudflare Tunnel connectivity, and
   application logs before reopening access. Keep the reported quarantine
   directory through the rollback window; inspect and remove it only after the
   restored environment and a new off-server backup have been accepted. The
   helper deliberately excludes top-level `.restore-quarantine.*` directories
   from backups, so the rollback copy is not duplicated into future archives.

The Terraform module has no input for attaching an existing restored volume. If recovery requires a provider-restored volume rather than an application-level archive, the attach/import steps are a **manual operator procedure** outside this configuration; plan and test them before an incident.

## Lifecycle operations

Use the same two var files for every command below and inspect `terraform plan` before an apply or destroy.

### Routine monitoring

```bash
# From infrastructure/deployments/hetzner
terraform output

# On the server
df -h /opt/foundry/data
free -h
sudo docker compose -f /opt/foundry/docker-compose.yml ps
sudo docker logs --tail=200 foundry
sudo docker logs --tail=200 cloudflared
```

Also monitor Cloudflare Tunnel status and access logs in the Cloudflare dashboard. The Terraform configuration does not provision monitoring alerts, log retention, health-based recovery, or automatic backups.

### Pause and resume

There is no safe, data-preserving Terraform pause in the current Hetzner module. Setting `compute_enabled=false` removes the server **and** the Terraform-managed data volume because both resources use that setting as their `count`. It can therefore delete Foundry data.

Do not use `compute_enabled=false` as a cost-saving pause unless a tested backup exists and data loss is acceptable. For a short operational pause, use a manual Hetzner-console server power action only after checking its billing and volume consequences; that action is outside Terraform and must be reconciled with state before the next apply. To resume after a manual power action, use the console and then verify the volume mount, Docker containers, and tunnel status.

### Resize

1. Create and verify an off-server backup.
2. Change `server_type` or increase `data_volume_size_gb` in `config/foundry.auto.tfvars`.
3. From this directory, run the normal `terraform plan` command and review whether the provider will stop, replace, or otherwise disrupt the server.
4. Apply only during a maintenance window.
5. When the plan grows `data_volume_size_gb`, SSH to the server and expand the
   existing ext4 filesystem. The cloud-init volume setup exits when it finds an
   already formatted volume, so Terraform does not perform this step:

   ```bash
   data_device="$(findmnt -n -o SOURCE /opt/foundry/data)"
   test "$(findmnt -n -o FSTYPE /opt/foundry/data)" = "ext4"
   sudo resize2fs "${data_device}"
   df -hT /opt/foundry/data
   ```

   Confirm that `df` shows the requested usable size. If the filesystem is not
   ext4 or the source device is unexpected, stop and follow Hetzner's
   [official Volume resize procedure](https://docs.hetzner.com/cloud/volumes/faq/)
   instead of guessing.
6. Verify the application, mount, and tunnel.

Shrinking a volume is not represented by this module; do not attempt it through a smaller variable value without a separate migration and restore plan.

### Temporary game-session scaling

For a planned high-attendance session, measure normal CPU and memory first,
create a verified off-server backup, and plan a larger `server_type`. Apply the
change during a maintenance window before players arrive, then verify the mount,
Foundry, and tunnel using the routine-monitoring commands above. Keep the larger
size through the session and watch CPU, memory, disk, and application logs.

After the session, retain and verify another off-server backup, plan the original
smaller `server_type`, and review whether Terraform will stop or replace the
server before applying. This is operator-scheduled vertical scaling, not
autoscaling; it can cause downtime, and a replacement plan can be destructive.
The data volume cannot be shrunk with this workflow.

### Destroy

```bash
terraform destroy \
  -var-file="../../../config/foundry.auto.tfvars" \
  -var-file="../../../config/secrets.auto.tfvars"
```

Destroying this deployment deletes the server and the Terraform-managed data volume. Confirm that an off-server backup has been verified before running it. The network and firewall are also managed resources and are removed by destroy.

## How Hetzner differs from AWS, Azure, and GCP

The four repository deployments do not provide equivalent operating models.
Use the full
[deployment model comparison](../../../docs/DEPLOYMENT_MODEL_COMPARISON.md)
for selection decisions; the issue-critical differences are summarized here:

| Concern | Hetzner deployment | AWS deployment | Azure deployment | GCP deployment |
| --- | --- | --- | --- | --- |
| **Availability** | One server and one volume, with no failover or autoscaling | Two-instance application baseline behind an ALB and Multi-AZ RDS | Two-instance VM scale set behind a load balancer with database HA enabled | Two-instance managed group behind a load balancer; Cloud SQL is managed, while multi-region is disabled by default |
| **Database** | No managed database; application state remains operator-managed on the attached volume | Managed PostgreSQL RDS with Multi-AZ enabled by default | Managed MySQL flexible server with HA enabled by default | Managed PostgreSQL Cloud SQL; public IP is disabled by default |
| **Backup** | No scheduled backup resource; operators must test off-server archives, and Hetzner Server backups exclude the attached Volume | RDS automated retention and versioned S3 are configured, but no scheduled application-volume snapshot is active | Database backup controls, geo-redundant backup, and Recovery Services VM backup are configured | Cloud SQL automated backups and versioned buckets are configured, but no attached-disk snapshot policy is active |
| **Monitoring** | Console, host, Docker, Foundry, and Cloudflare checks are operator-run; no Terraform-managed alerts or retention | CloudWatch dashboards, logs, and alarms are part of the deployment | Azure Monitor, Log Analytics, Application Insights, and alerts are integrated | Google monitoring, logging, dashboards, and alerts are integrated |

## Operational limits and trade-offs

- **Availability:** one server, one volume, one region, and no failover mean provider, host, network, Cloudflare, Docker, or volume failure can cause an outage.
- **Recovery:** no automated backup or restore orchestration is supplied. Recovery time and data-loss exposure depend on the operator's tested off-server backups and manual console access.
- **Security:** public Foundry access is designed to flow through Cloudflare Tunnel, and SSH is closed by default. Cloudflare routing/Access configuration and secure credential rotation remain operator responsibilities. A broad SSH CIDR weakens the intended posture.
- **Data residency:** choose the Hetzner location deliberately and verify its
  legal, contractual, and organizational fit. Terraform places the server and
  volume in the selected location, but off-server archive storage, Cloudflare
  traffic, support access, and operator downloads can move or copy data
  elsewhere.
- **Support:** this model relies on Hetzner infrastructure support plus
  operator-run Linux, Docker, Foundry, Cloudflare, monitoring, and recovery. It
  does not include the managed database, autoscaling, or integrated operations
  controls present in the hyperscale deployments.
- **Data lifecycle:** the current `compute_enabled` implementation does not retain its managed data volume. Treat all teardown-like operations as destructive unless a reviewed plan proves otherwise.
- **Operations:** there are no Terraform-managed alerts, managed patching, snapshot schedule, autoscaling, or multi-node capacity. Ubuntu package updates and cloud-init run at first boot; ongoing patching and monitoring are operator work.

## Migration path to AWS, Azure, or GCP

This repository does not provide an in-place Terraform migration. Treat a move
as a controlled application-data migration:

1. Select the target deployment using the
   [provider comparison](../../../docs/DEPLOYMENT_MODEL_COMPARISON.md), confirm
   its region, capacity, identity, database, storage, DNS, and cost decisions,
   and deploy it as a separate environment.
2. Test the target with non-production Foundry data and document how the
   Hetzner archive maps to the target provider's persistent application-data
   path. Managed database and object-storage services are separate from the
   single-volume Hetzner layout and require an application-specific import
   plan.
3. Schedule downtime, stop Foundry on Hetzner, create and verify a final
   off-server archive, then restore or import it into the isolated target.
4. Validate worlds, assets, users, modules, licenses, logs, backups, and target
   monitoring before changing Cloudflare/DNS routing.
5. Keep the Hetzner environment and final archive intact through the rollback
   window. Destroy it only after target acceptance and another verified target
   backup.

## References

- [Hetzner Cloud documentation](https://docs.hetzner.cloud)
- [Hetzner Volume limitations](https://docs.hetzner.com/cloud/volumes/overview/)
- [Hetzner Server Backup and Snapshot scope](https://docs.hetzner.com/cloud/servers/backups-snapshots/overview/)
- [Hetzner Cloud Terraform provider](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs)
- [Cloudflare Tunnel documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
- [Foundry VTT Docker image](https://github.com/felddy/foundryvtt-docker)
- [Tested Hetzner data archive helper](../../../scripts/hetzner-data-archive.sh)
