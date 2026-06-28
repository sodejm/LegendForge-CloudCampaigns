# LegendForge TODO Backlog

This backlog captures upcoming identity, access, and automation enhancements as features, stories, and executable tasks.

## Feature: Unified Authentication

### Story: Centralize authentication flows across Foundry and cloud operations
- [ ] Define a single identity architecture for operator and player access paths.
- [ ] Document supported identity providers and fallback authentication paths.
- [ ] Align Foundry and infrastructure access control requirements under one policy baseline.

### Tasks
- [ ] Inventory all current authentication touchpoints (Foundry app, cloud consoles, admin tooling).
- [ ] Produce an auth architecture decision record for unified identity.
- [ ] Define migration phases from current auth methods to the unified model.

## Feature: Multi-Factor Authentication (MFA) Enforcement

### Story: Enforce MFA on Foundry access
- [ ] Define MFA requirements for Foundry administrator and elevated user roles.
- [ ] Establish policy for enrollment, recovery, and lockout handling.

### Story: Enforce MFA on cloud provider infrastructure access
- [ ] Require MFA for all infrastructure operators across AWS, Azure, GCP, and Hetzner workflows.
- [ ] Define compliance checks to detect non-MFA-authenticated sessions.

### Tasks
- [ ] Create a cross-provider MFA policy matrix with role mapping.
- [ ] Identify provider-specific controls for mandatory MFA enforcement.
- [ ] Add operational runbooks for MFA onboarding and emergency recovery.

## Feature: Optional US-Only Location Lockdown

### Story: Add optional geo-restriction control for US-only IP access
- [ ] Define a configurable geo-access policy that can be enabled or disabled per deployment.
- [ ] Document operator expectations, exceptions, and auditability requirements.

### Tasks
- [ ] Evaluate Cloudflare and provider-native controls for country-based access filtering.
- [ ] Define configuration variables and defaults for optional US-only restrictions.
- [ ] Create an exception-handling process for legitimate non-US operator access.

## Feature: Auto Deployment of Common Campaign Resources

### Story: Standardize campaign bootstrap resources
- [ ] Define baseline campaign resources that should be provisioned automatically.
- [ ] Establish a repeatable deployment profile for shared campaign assets.

### Tasks
- [ ] Catalog common campaign resources (modules, templates, baseline content placeholders).
- [ ] Define versioning strategy for deployable campaign resource bundles.
- [ ] Create validation criteria to confirm resources deploy consistently across cloud targets.

## Feature: Passwordless Authentication Adoption

### Story: Move away from passwords where possible
- [ ] Define passwordless target states for users, operators, and service access.
- [ ] Evaluate private key and passkey options for practical rollout.

### Tasks
- [ ] Identify all password-dependent authentication paths and rank by migration priority.
- [ ] Assess compatibility constraints for passkeys and key-based authentication in existing workflows.
- [ ] Define phased deprecation plan for password-based login where alternatives are viable.

## Feature: Federated Sign-In for All Server Users

### Story: Enable Google and additional federated identity providers for user sign-in
- [ ] Define federated sign-in requirements for all server user personas.
- [ ] Support Google sign-in and document criteria for additional OIDC/SAML providers.

### Tasks
- [ ] Define identity provider integration requirements and claim mapping standards.
- [ ] Design account-linking and first-login provisioning flow for existing users.
- [ ] Define role and group synchronization rules from federated identity claims.
