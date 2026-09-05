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
    condition     = output.foundry_url == "https://example.test"
    error_message = "The public URL must use the configured load-balancer domain."
  }
}
