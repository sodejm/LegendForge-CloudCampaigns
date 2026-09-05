# AWS and GCP low-cost operations

Applies to [AWS low cost](../infrastructure/deployments/aws-low-cost/README.md) and [GCP low cost](../infrastructure/deployments/gcp-low-cost/README.md). These are single-host deployments with an independent ext4 data disk mounted at `/srv/foundry-data`. Docker configuration is `/opt/legendforge/compose.json`; the `legendforge` systemd unit supervises Foundry and cloudflared together. The disk initializer accepts only the explicitly identified disk, refuses partitions or unknown signatures, and never falls back to the boot disk.

## First boot and everyday checks

Complete initial deployment with `paused=false`. Through SSM (AWS) or IAP/OS Login (GCP), wait for `sudo cloud-init status --wait`, then inspect:

```bash
sudo systemctl status legendforge
findmnt /srv/foundry-data
sudo docker compose -f /opt/legendforge/compose.json ps
sudo docker compose -f /opt/legendforge/compose.json logs --tail=100
```

Confirm the mount is the expected independent disk, not a directory on the boot disk. Open the hostname, log in, create a disposable world, and verify persistence after a service restart. Run `scripts/post-deploy-smoke-test.sh infrastructure/deployments/aws-low-cost` (or `gcp-low-cost`) from the repository root. This checks reachability only; a Cloudflare Access login redirect can pass without establishing Foundry health. No live cloud or licensed Foundry test is claimed by the repository mock tests.

## Back up the world files

Database backups are irrelevant to the local world files in these profiles. Before every upgrade and after sessions, stop `legendforge` so no world writes occur. Verify the mount, then use the repository's tested archive helper, copied to the host:

```bash
sudo systemctl stop legendforge
findmnt /srv/foundry-data
# Choose a private directory OUTSIDE /srv/foundry-data with enough free space.
sudo bash /path/to/hetzner-data-archive.sh backup /srv/foundry-data /private-backups/session.tgz
sudo systemctl start legendforge
```

The helper is [scripts/hetzner-data-archive.sh](../scripts/hetzner-data-archive.sh); its archive format is provider independent. Create the backup directory with mode 0700. The 20 GB boot disk may be too small for an archive of a full 30 GB data disk: check space or use a separate temporary backup disk. Encrypt the archive before off-host transfer, preserve its checksum, restrict access, and verify the checksum after transfer. Retain multiple generations outside this VM and Terraform state. Record the Foundry/image/system/module versions alongside the backup, without credentials. A local archive alone is lost with the host.

A provider snapshot is a second recovery layer. Stop the service, snapshot the **data disk ID** from Terraform outputs, wait for the provider to report completion, then start the service. Account for snapshot charges and retention. Neither root provisions a snapshot schedule, cross-region replication, or an off-host archive destination.

## Restore drill and recovery

Create a separate recovery deployment using another name, separate state, and a test hostname/tunnel. Keep the original disk and verified archive intact. Complete first boot, stop `legendforge`, verify the new data mount, and transfer/decrypt a verified archive. Use the helper's `quarantine /srv/foundry-data` operation to preserve any bootstrap files, then `restore /private-backups/session.tgz /srv/foundry-data`. Inspect the result, restore ownership with `sudo chown -R 1000:1000 /srv/foundry-data`, and start `legendforge`.

Verify login, world loading, uploaded assets, system/module compatibility, and persistence after restart before changing player DNS. Keep the original deployment until the recovered world is accepted. Measure recovery time in this drill; no RTO or RPO is guaranteed by the templates. Follow Foundry license terms when running a recovery copy.

## Pause and resume

Stop active play and back up first. In the same root and state, set `paused=true`, create a saved plan, and confirm it changes only the instance power state. Apply that reviewed plan. Record instance and data disk IDs before and after; they must remain identical. Set `paused=false` and repeat plan/apply to resume, then verify the mount, service, tunnel, and a world.

AWS stops the existing EC2 instance; GCP changes `desired_status` to `TERMINATED` (a stopped VM, not deletion). Neither operation deletes the data disk. Disks, snapshots, and external services continue to incur charges; public ephemeral IPv4 addresses can change, so use the tunnel hostname. First boot must finish before pausing. A pending resize or credential/image change can add actions to the plan: do not treat such a mixed plan as a routine pause.

For a game-night schedule, an operator may run the same reviewed variable/state workflow from an external scheduler with narrowly scoped cloud credentials, an encrypted locking backend, and one writer. Include timezone/DST, early startup and health checks, shutdown grace, missed-run alerts, and emergency override. These roots provision no scheduler; a console power action can drift from Terraform and must be reconciled before the next apply.

## Resize and grow storage

Back up before changing `instance_type` (AWS and GCP). Start with 2 GB only for a small world; 4 GB provides more headroom. Plan a stopped maintenance window, review that no disk or VM replacement is proposed, apply, and confirm the same IDs and data. Burstable/shared CPU is not dedicated capacity.

Increase `data_disk_gb` only after a verified backup. Review/apply the disk expansion, identify the mounted ext4 device with `findmnt -n -o SOURCE /srv/foundry-data`, and use `resize2fs` on that exact device; verify capacity with `df -hT`. Terraform grows the block device, not the filesystem. Never shrink by lowering the variable; migrate to another disk through a tested restore instead.

## Images, credentials, patches, and retirement

Pin reviewed numeric image versions or digests. The examples deliberately require a reviewed cloudflared version. Back up and record the previous Compose file and image digests. Update the protected host Compose/config/token files during a maintenance window, pull the reviewed images, restart `legendforge`, and test a world. Keep the desired inputs in your protected configuration consistent. Reverting an image is insufficient if an application upgrade changed world data: restore the matching backup as needed.

Cloud-init runs on first boot. GCP metadata updates do not rerun it; AWS user-data changes request replacement, which this root's lifecycle guard blocks. Do not remove the guard just to rotate a token or change an image. Plan a controlled host update or a separate replacement-and-restore migration. Operator-managed Ubuntu and Docker patching, reboots, and backup verification remain required.

VM and data disk `prevent_destroy` rules, AWS termination protection, and GCP deletion protection guard accidental replacement/retirement. They are not backups and do not protect against deletion outside Terraform. Retirement requires a separate reviewed change to those protections after independent backup and restore verification. Removing a resource from configuration also removes its lifecycle rule, so review the full plan. Do not use `terraform destroy` as a pause.
