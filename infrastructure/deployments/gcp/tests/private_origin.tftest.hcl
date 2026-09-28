mock_provider "google" {}

run "compute_origin_is_private" {
  command = plan

  module {
    source = "../../modules/gcp-compute"
  }

  variables {
    project_name             = "legendforge-fixture"
    foundry_compute_sa_email = "foundry@legendforge-fixture.iam.gserviceaccount.com"
    vpc_network_name         = "foundry-vpc"
    subnet_name              = "foundry-primary-subnet"
    startup_script           = "#cloud-config"
  }

  assert {
    condition = (
      length(google_compute_instance_template.foundry.network_interface) == 1 &&
      length(google_compute_instance_template.foundry.network_interface[0].access_config) == 0 &&
      length(google_compute_instance_template.foundry.network_interface[0].ipv6_access_config) == 0 &&
      google_compute_instance_template.foundry.network_interface[0].subnetwork == var.subnet_name
    )
    error_message = "Foundry must use the private subnet without external IPv4 or IPv6 access configuration."
  }

  assert {
    condition = (
      toset(google_compute_firewall.foundry_lb.source_ranges) == toset(["35.191.0.0/16", "130.211.0.0/22"]) &&
      length(google_compute_firewall.foundry_lb.allow) == 1 &&
      one(google_compute_firewall.foundry_lb.allow).protocol == "tcp" &&
      toset(one(google_compute_firewall.foundry_lb.allow).ports) == toset(["30030"]) &&
      toset(google_compute_firewall.foundry_lb.target_tags) == toset(["foundry-compute"])
    )
    error_message = "The compute backend rule must allow only load balancer and health-check sources on Foundry's TCP port."
  }

  assert {
    condition = (
      google_compute_instance_template.foundry.metadata["enable-oslogin"] == "TRUE" &&
      contains(google_compute_instance_template.foundry.tags, "foundry-compute") &&
      contains(google_compute_instance_template.foundry.tags, "health-check") &&
      google_compute_health_check.foundry_http.http_health_check[0].port == 30030
    )
    error_message = "Private instances must retain OS Login and the tags and port needed for health checks."
  }
}

run "vpc_private_origin_access" {
  command = plan

  module {
    source = "../../modules/gcp-vpc"
  }

  variables {
    project_name = "legendforge-fixture"
  }

  assert {
    condition = (
      toset(google_compute_firewall.allow_loadbalancer.source_ranges) == toset(["35.191.0.0/16", "130.211.0.0/22"]) &&
      length(google_compute_firewall.allow_loadbalancer.allow) == 1 &&
      one(google_compute_firewall.allow_loadbalancer.allow).protocol == "tcp" &&
      toset(one(google_compute_firewall.allow_loadbalancer.allow).ports) == toset(["30030"]) &&
      toset(google_compute_firewall.allow_loadbalancer.target_tags) == toset(["foundry-compute"])
    )
    error_message = "The VPC backend rule must also restrict Foundry ingress to load balancer and health-check sources."
  }

  assert {
    condition = (
      toset(google_compute_firewall.allow_health_checks.source_ranges) == toset(["35.191.0.0/16", "130.211.0.0/22"]) &&
      one(google_compute_firewall.allow_health_checks.allow).protocol == "tcp" &&
      toset(one(google_compute_firewall.allow_health_checks.allow).ports) == toset(["30030"]) &&
      toset(google_compute_firewall.allow_ssh_from_admin.source_ranges) == toset(["35.235.240.0/20"]) &&
      one(google_compute_firewall.allow_ssh_from_admin.allow).protocol == "tcp" &&
      toset(one(google_compute_firewall.allow_ssh_from_admin.allow).ports) == toset(["22"]) &&
      toset(google_compute_firewall.allow_ssh_from_admin.target_tags) == toset(["foundry-compute"])
    )
    error_message = "Health checks must remain reachable and SSH must default to the IAP tunnel source range."
  }

  assert {
    condition = (
      google_compute_subnetwork.foundry_primary.private_ip_google_access &&
      google_compute_subnetwork.foundry_primary.region == google_compute_router.foundry_router.region &&
      google_compute_router_nat.foundry_nat.router == google_compute_router.foundry_router.name &&
      google_compute_router_nat.foundry_nat.region == google_compute_subnetwork.foundry_primary.region &&
      google_compute_router_nat.foundry_nat.nat_ip_allocate_option == "AUTO_ONLY" &&
      google_compute_router_nat.foundry_nat.source_subnetwork_ip_ranges_to_nat == "ALL_SUBNETWORKS_ALL_IP_RANGES"
    )
    error_message = "Private instances must retain Private Google Access and Cloud NAT coverage in their region."
  }
}

run "explicit_admin_ranges_are_preserved" {
  command = plan

  module {
    source = "../../modules/gcp-vpc"
  }

  variables {
    project_name        = "legendforge-fixture"
    admin_source_ranges = ["35.235.240.0/20", "10.8.0.0/24"]
  }

  assert {
    condition     = toset(google_compute_firewall.allow_ssh_from_admin.source_ranges) == toset(var.admin_source_ranges)
    error_message = "Explicit administrator source ranges must remain supported without silently changing them."
  }
}
