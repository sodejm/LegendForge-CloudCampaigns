# Prompts

Use these prompts as operator checklists when planning, deploying, or changing a LegendForge environment.

## Before You Deploy

Ask:

- Which provider best matches my budget, region, and operating style?
- Which hostname and Cloudflare zone will players use?
- Do I want Cloudflare Access in front of Foundry?
- Do I need break-glass SSH, or can I leave it closed?
- How much persistent storage should I allocate for worlds, assets, and backups?
- Which Foundry system will I install after deployment?

## Before You Fill Secrets

Ask:

- Am I using scoped Cloudflare API tokens instead of broad credentials?
- Am I using Foundry account credentials or a timed release URL?
- Is the Foundry admin key long, unique, and randomly generated?
- Am I keeping `config/secrets.auto.tfvars` out of version control?

## Before You Apply Terraform

Ask:

- Did I review the provider-specific deployment guide?
- Did I confirm the variable files point at the correct cloud account and domain?
- Do I understand what resources will be created and their estimated cost?
- Do I have a rollback or destroy path if the first apply is wrong?

## Before You Install Systems or Modules

Ask:

- Does this system match my current Foundry version?
- Which modules are required for this world?
- Can I test the module stack in a non-production world first?
- Do I need separate worlds or separate deployments for different communities?

## Before Upgrades

Ask:

- Did I back up the current world data?
- Did I snapshot persistent storage?
- Did I record current Foundry, system, and module versions?
- Am I changing Foundry core, system packages, and modules in a controlled order?

## Before Recovery or Troubleshooting

Ask:

- Is the problem DNS, tunnel ingress, compute health, container startup, or the application itself?
- Did I check Terraform outputs and deployment health first?
- Do I have recent backups and restore points?
- Am I using the safest available admin path for this provider?

## Contributor Prompt

When updating docs or infrastructure, ask:

- Does this keep LegendForge system-agnostic?
- Does this assume D&D-specific behavior where the platform should stay generic?
- Does this preserve security-first defaults?
- Did I update cross-links if I added major documentation?
