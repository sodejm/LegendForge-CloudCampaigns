mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id       = "00000000-0000-0000-0000-000000000001"
      object_id       = "00000000-0000-0000-0000-000000000002"
      subscription_id = "00000000-0000-0000-0000-000000000003"
    }
  }
}
mock_provider "random" {}
variables {
  foundry_license_key = "test-placeholder"
  database_password   = "Fixture-only-Password9!"
  vm_ssh_public_key   = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQChF2X1jJ5HwUqkzTD0CWQ4VUMn7WJJ8/0Y4ibQr4v2mgRnshELua+8gLDRlAjz66lWMRjsu0cZ5kMBaaVr5NT2BlMXMrWe7xZVFaNY4jM1eIFQt0/JkbVwDWtk6tzxeyyqLmxLlWFRGXUMRZ/dh1u6x3y4oHUWfuvmkiA/KFfdkERhChyzqaLke8DxCKDuFPKA8WKNc3gZhBXcWsS8VeY2q/GWFYHSl4RIcT1hXeODlv1xI9TyN3tTnkIq6+eg1kyfC20mXvJ9uMdcM3C9IP0hdSGzkntdyop1YENSE4IzpGYRYYHe0+b6+muvk5CC3308IxM87D22Xc4158V4/o9t test-fixture-only"
  alert_email         = "operator@example.test"
}
run "default_topology_plan" { command = plan }
