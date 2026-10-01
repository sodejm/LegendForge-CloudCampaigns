mock_provider "google" {
  mock_data "google_client_config" { defaults = { project = "legendforge-fixture" } }
  mock_data "google_project" { defaults = { number = "123456789012" } }
}
mock_provider "google-beta" {}
variables {
  gcp_project_id          = "legendforge-fixture"
  foundry_license_key     = "test-placeholder"
  foundry_admin_key       = "test-placeholder"
  cloudflare_tunnel_token = "test-placeholder"
  foundry_hostname        = "foundry.example.test"
  domain_name             = "example.test"
}
run "default_topology_plan" {
  command = plan
  assert {
    condition     = toset(var.admin_source_ranges) == toset(["35.235.240.0/20"])
    error_message = "The standard deployment must default administrator access to IAP."
  }
  assert {
    condition     = var.enable_cloud_armor && var.cloud_armor_preview && !var.enable_adaptive_protection
    error_message = "Standard deployments must attach the policy in preview with Adaptive Protection opt-in."
  }
  assert {
    condition     = output.foundry_url == "https://example.test"
    error_message = "The public URL must use the configured load-balancer domain."
  }
}

run "reject_invalid_root_rate_controls" {
  command = plan
  variables {
    cloud_armor_rate_limit_count        = 10001
    cloud_armor_rate_limit_interval_sec = 45
    cloud_armor_ban_duration_sec        = 30
  }
  expect_failures = [var.cloud_armor_rate_limit_count, var.cloud_armor_rate_limit_interval_sec, var.cloud_armor_ban_duration_sec]
}
