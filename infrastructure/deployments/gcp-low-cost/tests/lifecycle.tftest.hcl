mock_provider "google" {}

variables {
  gcp_project_id = "legendforge-test"
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
    condition     = google_compute_instance.this.desired_status == "RUNNING" && google_compute_instance.this.machine_type == "e2-small"
    error_message = "First boot must run with the minimum supported memory."
  }
  assert {
    condition     = google_compute_instance.this.attached_disk[0].source == google_compute_disk.data.id && google_compute_disk.data.size == 30 && google_compute_instance.this.deletion_protection
    error_message = "Attach the independent retained data disk and protect the VM."
  }
  assert {
    condition     = google_compute_firewall.iap.source_ranges == toset(["35.235.240.0/20"]) && google_compute_instance.this.metadata["enable-oslogin"] == "TRUE"
    error_message = "Operator access must require IAP and OS Login."
  }
  assert {
    condition     = startswith(google_compute_instance.this.metadata["user-data"], "#cloud-config\n")
    error_message = "GCE Ubuntu needs raw cloud-config in the user-data metadata key."
  }
}

run "pause" {
  command = apply
  variables { paused = true }
  assert {
    condition     = google_compute_instance.this.desired_status == "TERMINATED" && output.instance_name == run.first_boot.instance_name && output.data_disk_id == run.first_boot.data_disk_id
    error_message = "Pause must stop the existing VM and retain its disk."
  }
}

run "resume_and_resize" {
  command = plan
  variables {
    paused        = false
    instance_type = "e2-medium"
  }
  assert {
    condition     = google_compute_instance.this.desired_status == "RUNNING" && google_compute_instance.this.machine_type == "e2-medium" && output.data_disk_id == run.first_boot.data_disk_id
    error_message = "Resume and session resizing must preserve the original data disk."
  }
}
