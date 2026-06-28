# LegendForge Project Philosophy

LegendForge exists to provide **universal tabletop infrastructure for Foundry VTT**. The project is built on a simple belief: the hosting layer for tabletop play should not be locked to a single game system, genre, or community.

---

## Why LegendForge Exists

Many infrastructure projects in the tabletop space begin with a single campaign, a single system, or a single operator. That is a practical starting point, but it often produces documentation and architecture that imply the platform only belongs to one ruleset.

LegendForge moves in the opposite direction.

We believe the infrastructure should be able to support:

- A private D&D 5e campaign
- A Pathfinder community server
- A World of Darkness chronicle
- A Fate one-shot archive
- A PbtA experimentation space
- A rotating set of Foundry-compatible systems managed by one operator or team

The infrastructure should remain dependable even as the stories, players, and rulesets change.

---

## Core Principles

### 1. System-Agnostic by Default
LegendForge is not a rules engine. It is infrastructure.

That means the project focuses on:
- Compute
- Networking
- Storage
- Secrets management
- Backups
- Monitoring
- Operator workflows

Those concerns should work the same way whether the campaign is fantasy, horror, urban mystery, cosmic investigation, or homebrew.

### 2. Foundry-Compatible, Not Rules-Locked
LegendForge is aligned with **Foundry VTT as a platform**. The project intentionally avoids coupling infrastructure documentation to only one system family.

This makes it easier to:
- Host multiple worlds
- Change systems later
- Run several communities on one operational model
- Preserve infra documentation as your content evolves

### 3. Cloud-Neutral Where It Matters
Operators should be able to choose the cloud platform that fits their budget, compliance needs, region, and operational style.

LegendForge therefore values:
- Comparable deployment patterns across AWS, Azure, GCP, and Hetzner
- Reusable module design
- Predictable secrets and networking patterns
- Documentation that explains differences without fragmenting the project mission

### 4. Secure by Default
A tabletop platform still deserves production-minded security.

LegendForge favors:
- Cloudflare Tunnel or equivalent secure ingress patterns
- Minimal public exposure
- Secret isolation
- Break-glass access only when necessary
- Backup discipline before risky changes

Security should not depend on what game system is installed.

### 5. Durable Campaign Operations
Campaigns accumulate history: journals, scenes, maps, actors, handouts, automation, and community habits. Operators need infrastructure that protects that history.

LegendForge prioritizes:
- Persistent storage
- Backup and restore planning
- Safe upgrade workflows
- Operational clarity during migration or recovery

### 6. Documentation as an Operator Tool
Documentation is part of the product.

Good infra docs should help people:
- Understand what the platform is for
- Deploy it safely
- Adapt it to their own communities
- Avoid treating one ruleset as the only valid use case

That is why the LegendForge rebrand matters. The name and documentation should reflect the broader mission.

---

## What LegendForge Is

LegendForge is:

- A **multi-cloud infrastructure codebase**
- A **Foundry VTT hosting platform**
- A **universal tabletop operations layer**
- A **security-conscious deployment model**
- A **foundation for many different campaign types**

## What LegendForge Is Not

LegendForge is not:

- A replacement for Foundry VTT
- A bundled game system distribution
- A collection of proprietary rulebooks or licensed content
- A guarantee that every module combination will work without testing
- A reason to ignore Foundry, system, or module compatibility matrices

---

## The Universal Tabletop Infrastructure Idea

The phrase **"universal tabletop infrastructure"** means the project is built around the shared operational needs of many game systems:

- Reliable access for players and GMs
- Stable storage for campaign artifacts
- Secure remote administration
- Cloud portability
- Repeatable deployment patterns
- Clear recovery workflows

The game layer changes. The infrastructure discipline should not.

---

## Practical Implications for Contributors

When contributing to LegendForge, aim to:

1. Use language that includes multiple systems and genres
2. Avoid assuming D&D-specific workflows are universal
3. Keep infrastructure modules generic unless a provider truly requires specialization
4. Add system-specific examples carefully and label them as examples
5. Preserve licensing, attribution, and upstream credit
6. Prefer operational patterns that help both single-campaign and multi-community operators

---

## Practical Implications for Operators

If you run LegendForge in production or for a private group:

- Treat Foundry core, systems, and modules as separate change domains
- Snapshot before major upgrades
- Document which systems each deployment serves
- Keep module sprawl under control
- Design for recovery, not just initial installation

A flexible platform becomes valuable only when it remains understandable over time.

---

## Closing Statement

LegendForge is built for the idea that **tabletop stories deserve dependable infrastructure regardless of system**.

Whether your table is running heroic fantasy, political horror, investigative mystery, narrative drama, or a rotating schedule of different games, the infrastructure should still be secure, portable, and calm to operate.

That is the point of LegendForge:

**agnostic infrastructure, compatible with any Foundry-supported tabletop world, built to let the stories change without rebuilding the foundation.**
