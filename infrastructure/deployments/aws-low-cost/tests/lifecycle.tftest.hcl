mock_provider "aws" {
  mock_data "aws_ami" {
    defaults = { id = "ami-0123456789abcdef0" }
  }
  mock_resource "aws_ebs_volume" {
    defaults = { id = "vol-0123456789abcdef0" }
  }
}

variables {
  app = {
    hostname       = "foundry.example.test"
    foundry_image  = "ghcr.io/felddy/foundryvtt:14.367.0"
    tunnel_image   = "cloudflare/cloudflared:2026.8.0"
    tunnel_token   = "test-placeholder"
    license_key    = "test-placeholder"
    admin_password = "test-placeholder"
    username       = "test-placeholder"
    password       = "test-placeholder"
  }
}

run "first_boot" {
  command = apply
  assert {
    condition     = aws_ec2_instance_state.this.state == "running" && aws_instance.this.instance_type == "t3.small"
    error_message = "First boot must run with the minimum supported memory."
  }
  assert {
    condition     = aws_ebs_volume.data.encrypted && aws_ebs_volume.data.size == 30 && aws_volume_attachment.data.volume_id == aws_ebs_volume.data.id
    error_message = "Foundry must use the independent encrypted data volume."
  }
  assert {
    condition     = length(aws_security_group.this.ingress) == 0 && aws_instance.this.metadata_options[0].http_tokens == "required"
    error_message = "Require IMDSv2 and keep inbound access closed."
  }
  assert {
    condition     = startswith(module.app.user_data, "#cloud-config\n") && length(module.app.user_data) <= 16384
    error_message = "EC2 needs unencoded cloud-config within its 16 KiB user-data limit."
  }
}

run "pause" {
  command = apply
  variables { paused = true }
  assert {
    condition     = aws_ec2_instance_state.this.state == "stopped" && !aws_ec2_instance_state.this.force
    error_message = "Pause must request a graceful stop."
  }
  assert {
    condition     = output.instance_id == run.first_boot.instance_id && output.data_disk_id == run.first_boot.data_disk_id
    error_message = "Pause must preserve VM and data-disk identity."
  }
}

run "resume_and_resize" {
  command = plan
  variables {
    paused        = false
    instance_type = "t3.medium"
  }
  assert {
    condition     = aws_ec2_instance_state.this.state == "running" && aws_instance.this.instance_type == "t3.medium" && output.instance_id == run.first_boot.instance_id && output.data_disk_id == run.first_boot.data_disk_id
    error_message = "Resume and session resizing must keep the original VM and data disk."
  }
}
