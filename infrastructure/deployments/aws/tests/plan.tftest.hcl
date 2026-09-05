mock_provider "aws" {
  mock_data "aws_availability_zones" { defaults = { names = ["us-east-1a", "us-east-1b"] } }
  mock_data "aws_ami" { defaults = { id = "ami-0123456789abcdef0" } }
  mock_data "aws_iam_policy_document" { defaults = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" } }
}
variables {
  database_username        = "foundry"
  database_password        = "Fixture-only-Password9!"
  foundry_hostname         = "foundry.example.test"
  foundry_image            = "ghcr.io/felddy/foundryvtt:14.367.0"
  cloudflare_tunnel_token  = "test-placeholder"
  foundry_license_key      = "test-placeholder"
  foundry_admin_key        = "test-placeholder"
  route53_zone_id          = "Z0123456789ABCDEFGHIJ"
  create_certificate       = false
  existing_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/00000000-0000-0000-0000-000000000001"
}
run "default_topology_plan" {
  command = plan
}
