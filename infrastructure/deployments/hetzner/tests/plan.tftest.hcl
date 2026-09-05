mock_provider "hcloud" {
  mock_data "hcloud_image" { defaults = { id = "123456" } }
}
variables {
  foundry_hostname        = "foundry.example.test"
  foundry_image           = "ghcr.io/felddy/foundryvtt:14.367.0"
  cloudflared_image       = "cloudflare/cloudflared:2026.8.0"
  foundry_license_key     = "test-placeholder"
  foundry_admin_key       = "test-placeholder"
  cloudflare_tunnel_token = "test-placeholder"
}
run "default_topology_plan" {
  command = plan
  assert {
    condition     = output.foundry_url == "https://foundry.example.test" && output.server_summary.volume_size == 20
    error_message = "The default plan must retain the documented hostname and data volume."
  }
}

run "provider_contract" {
  command = plan
  module { source = "../../modules/providers/hetzner" }
  assert {
    condition     = hcloud_server.foundry[0].location == "fsn1" && hcloud_volume.foundry_data[0].location == "fsn1"
    error_message = "The legacy datacenter must resolve to the same supported location for server and volume."
  }
  assert {
    condition     = startswith(hcloud_server.foundry[0].user_data, "#cloud-config")
    error_message = "Hetzner user_data must contain raw cloud-config, not base64."
  }
}
run "explicit_location" {
  command = plan
  variables { location = "nbg1" }
  assert {
    condition     = output.server_summary.location == "nbg1"
    error_message = "The explicit location must override the legacy datacenter."
  }
}
