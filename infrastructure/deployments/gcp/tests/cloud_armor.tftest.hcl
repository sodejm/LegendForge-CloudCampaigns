mock_provider "google" {}

variables {
  project_name      = "legendforge-fixture"
  domain_name       = "foundry.example.test"
  instance_group_id = "projects/fixture/zones/us-central1-a/instanceGroups/foundry"
  health_check_id   = "projects/fixture/global/healthChecks/foundry"
}

run "active_backend_has_preview_policy" {
  command = apply
  module { source = "../../modules/gcp-loadbalancer" }

  assert {
    condition     = google_compute_backend_service.foundry.security_policy == google_compute_security_policy.foundry.id
    error_message = "The policy must protect the backend actually serving players."
  }
  assert {
    condition = (
      google_compute_url_map.foundry.default_service == google_compute_backend_service.foundry.id &&
      google_compute_url_map.foundry.path_matcher[0].default_service == google_compute_backend_service.foundry.id &&
      alltrue([for route in google_compute_url_map.foundry.path_matcher[0].path_rule : route.service == google_compute_backend_service.foundry.id]) &&
      output.backend_service_id == google_compute_backend_service.foundry.id
    )
    error_message = "Application, asset, WebSocket routes and the exported backend ID must retain the active backend."
  }
  assert {
    condition = (
      google_compute_backend_service.foundry.name == "legendforge-fixture-foundry-backend" &&
      google_compute_backend_service.foundry.protocol == "HTTP" &&
      google_compute_backend_service.foundry.port_name == "foundry" &&
      google_compute_backend_service.foundry.session_affinity == "CLIENT_IP" &&
      google_compute_backend_service.foundry.enable_cdn &&
      google_compute_backend_service.foundry.health_checks == toset([var.health_check_id]) &&
      one(google_compute_backend_service.foundry.backend).group == var.instance_group_id
    )
    error_message = "Policy attachment must preserve backend identity, protocol, port, affinity, CDN, health checks and instance group."
  }
  assert {
    condition = (
      length(google_compute_security_policy.foundry.rule) == 4 &&
      alltrue([for rule in google_compute_security_policy.foundry.rule : rule.priority == 2147483647 ? (rule.action == "allow" && !rule.preview && rule.match[0].versioned_expr == "SRC_IPS_V1" && rule.match[0].config[0].src_ip_ranges == toset(["*"])) : rule.preview]) &&
      toset([for rule in google_compute_security_policy.foundry.rule : rule.priority]) == toset([3000, 3100, 4000, 2147483647])
    )
    error_message = "WAF and rate rules must start in preview before the non-preview default allow rule, with WAF evaluated first."
  }
  assert {
    condition = alltrue([for rule in google_compute_security_policy.foundry.rule : rule.priority == 4000 ? (
      rule.action == "rate_based_ban" &&
      rule.rate_limit_options[0].enforce_on_key == "IP" &&
      rule.rate_limit_options[0].rate_limit_threshold[0].count == 100 &&
      rule.rate_limit_options[0].rate_limit_threshold[0].interval_sec == 60 &&
      rule.rate_limit_options[0].ban_duration_sec == 600 &&
      rule.rate_limit_options[0].conform_action == "allow" &&
      rule.rate_limit_options[0].exceed_action == "deny(429)"
    ) : true])
    error_message = "The initial preview rate rule must retain the documented per-IP threshold and 429 action."
  }
  assert {
    condition = (
      alltrue([for rule in google_compute_security_policy.foundry.rule : rule.priority == 3000 ? (rule.action == "deny(403)" && rule.match[0].expr[0].expression == "evaluatePreconfiguredExpr('sqli-v33-stable')") : true]) &&
      alltrue([for rule in google_compute_security_policy.foundry.rule : rule.priority == 3100 ? (rule.action == "deny(403)" && rule.match[0].expr[0].expression == "evaluatePreconfiguredExpr('xss-v33-stable')") : true]) &&
      google_compute_security_policy.foundry.advanced_options_config[0].log_level == "NORMAL" &&
      !google_compute_security_policy.foundry.adaptive_protection_config[0].layer_7_ddos_defense_config[0].enable
    )
    error_message = "SQLi/XSS rules must precede rate limiting, use normal logging and leave Adaptive Protection opt-in."
  }
}

run "attachment_can_be_disabled" {
  command = apply
  module { source = "../../modules/gcp-loadbalancer" }
  variables { enable_cloud_armor = false }
  assert {
    condition     = google_compute_backend_service.foundry.security_policy == null && output.security_policy_id == google_compute_security_policy.foundry.id
    error_message = "Disabling attachment must detach the active backend while retaining the policy resource and output."
  }
}

run "enforcement_and_tuned_thresholds" {
  command = apply
  module { source = "../../modules/gcp-loadbalancer" }
  variables {
    cloud_armor_preview                 = false
    cloud_armor_rate_limit_count        = 500
    cloud_armor_rate_limit_interval_sec = 120
    cloud_armor_ban_duration_sec        = 300
    enable_adaptive_protection          = true
  }
  assert {
    condition = (
      google_compute_backend_service.foundry.security_policy == google_compute_security_policy.foundry.id &&
      alltrue([for rule in google_compute_security_policy.foundry.rule : !rule.preview]) &&
      google_compute_security_policy.foundry.adaptive_protection_config[0].layer_7_ddos_defense_config[0].enable &&
      alltrue([for rule in google_compute_security_policy.foundry.rule : rule.priority == 4000 ? (
        rule.rate_limit_options[0].rate_limit_threshold[0].count == 500 &&
        rule.rate_limit_options[0].rate_limit_threshold[0].interval_sec == 120 &&
        rule.rate_limit_options[0].ban_duration_sec == 300
      ) : true])
    )
    error_message = "Explicit enforcement, tuned rate limits and Adaptive Protection must be applied independently."
  }
}

run "reject_fractional_count" {
  command = plan
  module { source = "../../modules/gcp-loadbalancer" }
  variables { cloud_armor_rate_limit_count = 1.5 }
  expect_failures = [var.cloud_armor_rate_limit_count]
}
run "reject_zero_count" {
  command = plan
  module { source = "../../modules/gcp-loadbalancer" }
  variables { cloud_armor_rate_limit_count = 0 }
  expect_failures = [var.cloud_armor_rate_limit_count]
}
run "reject_excessive_ban_threshold" {
  command = plan
  module { source = "../../modules/gcp-loadbalancer" }
  variables { cloud_armor_rate_limit_count = 10001 }
  expect_failures = [var.cloud_armor_rate_limit_count]
}
run "reject_unsupported_interval" {
  command = plan
  module { source = "../../modules/gcp-loadbalancer" }
  variables { cloud_armor_rate_limit_interval_sec = 45 }
  expect_failures = [var.cloud_armor_rate_limit_interval_sec]
}
run "reject_unsupported_ban_duration" {
  command = plan
  module { source = "../../modules/gcp-loadbalancer" }
  variables { cloud_armor_ban_duration_sec = 30 }
  expect_failures = [var.cloud_armor_ban_duration_sec]
}
