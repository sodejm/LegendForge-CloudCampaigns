# LegendForge Documentation Index

This index is the navigation hub for LegendForge documentation. It highlights the files that explain the **LegendForge rebrand**, the **multi-system tabletop mission**, and the operational guidance for deploying Foundry VTT infrastructure across clouds.

---

## 📚 Core Documentation

### Main Documentation
- **[README.md](README.md)** - Project overview, setup instructions, architecture, and LegendForge branding
  - Start here for the rebrand overview
  - Includes quick-start deployment instructions
  - Explains the universal tabletop positioning

### New Strategy and Positioning Documents
- **[SUPPORTED_SYSTEMS.md](SUPPORTED_SYSTEMS.md)** - Compatible Foundry systems and operational guidance
  - Lists the major system families LegendForge is designed to host
  - Explains what "system-agnostic infrastructure" means in practice
  - Best for operators planning multi-system campaigns or communities

- **[PROJECT_PHILOSOPHY.md](PROJECT_PHILOSOPHY.md)** - Universal tabletop infrastructure philosophy
  - Explains why LegendForge is not tied to a single ruleset
  - Documents principles around portability, security, and operator clarity
  - Best for understanding the mission and long-term direction

### Attribution and Community Files
- **[ATTRIBUTION.md](ATTRIBUTION.md)** - Comprehensive technical attribution
  - Dependency lists and license notes
  - Infrastructure and security references
  - Best for compliance, audits, and upstream project traceability

- **[CREDITS.md](CREDITS.md)** - Community recognition and acknowledgments
  - Recognizes key maintainers and ecosystem contributors
  - Highlights the broader multi-system tabletop community
  - Best for understanding who makes LegendForge possible

### Platform-Specific Documentation
- **[README_AZURE.md](README_AZURE.md)** - Azure-specific setup and configuration
  - Contains Azure deployment guidance
  - Complements the LegendForge core docs with provider-specific details

### GitHub Wiki Source Pages
- **[wiki/Home.md](wiki/Home.md)** - Wiki landing page and overview
- **[wiki/Quickstart.md](wiki/Quickstart.md)** - Shortest path to a first deployment
- **[wiki/Installation.md](wiki/Installation.md)** - Setup prerequisites and configuration inputs
- **[wiki/Provider-Guide.md](wiki/Provider-Guide.md)** - Provider selection and platform-specific doc links
- **[wiki/How-To.md](wiki/How-To.md)** - Common operator tasks and workflows
- **[wiki/Prompts.md](wiki/Prompts.md)** - Planning and operational checklist prompts
- **[wiki/Use-Cases.md](wiki/Use-Cases.md)** - Common deployment and community scenarios
- **[wiki/Architecture-and-Security.md](wiki/Architecture-and-Security.md)** - Shared architecture and security themes

---

## 🎯 Recommended Reading Paths

### For New Users
1. Read **[README.md](README.md)**
2. Review **[PROJECT_PHILOSOPHY.md](PROJECT_PHILOSOPHY.md)**
3. Scan **[SUPPORTED_SYSTEMS.md](SUPPORTED_SYSTEMS.md)** for your campaign needs

### For Deployment Operators
1. Start with **[README.md](README.md)**
2. Use the relevant provider guide in `deployments/*/README.md`
3. Review **[ATTRIBUTION.md](ATTRIBUTION.md)** for dependency and license context

### For Contributors and Reviewers
1. Read **[PROJECT_PHILOSOPHY.md](PROJECT_PHILOSOPHY.md)** before changing messaging
2. Keep **[DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)** current when adding major docs
3. Update **[ATTRIBUTION.md](ATTRIBUTION.md)** and **[CREDITS.md](CREDITS.md)** when upstream relationships change

---

## 🔗 Quick Links to Key Resources

### Primary Platform Dependencies
| Project | URL | Role in LegendForge |
|---------|-----|----------------------|
| Foundry VTT | https://github.com/foundryvtt | Core virtual tabletop platform |
| felddy/foundryvtt Docker | https://github.com/felddy/foundryvtt-docker | Container runtime image |
| Cloudflare Tunnel | https://www.cloudflare.com/products/tunnel/ | Secure ingress |
| Terraform | https://www.terraform.io/ | Infrastructure as Code |

### Cloud Providers
| Provider | Terraform Provider Registry |
|----------|-----------------------------|
| AWS | https://registry.terraform.io/providers/hashicorp/aws/ |
| Azure | https://registry.terraform.io/providers/hashicorp/azurerm/ |
| Google Cloud | https://registry.terraform.io/providers/hashicorp/google/ |
| Hetzner Cloud | https://registry.terraform.io/providers/hetznercloud/hcloud/ |

### Supporting Infrastructure
| Project | URL | License |
|---------|-----|---------|
| Docker | https://www.docker.com/ | Apache 2.0 / Proprietary |
| Ubuntu Linux | https://ubuntu.com/ | Open Source |
| Cloud-Init | https://cloud-init.io/ | GPL v3 |

---

## 📝 Documentation Coverage Map

### Branding and Positioning
- `README.md`
- `SUPPORTED_SYSTEMS.md`
- `PROJECT_PHILOSOPHY.md`

### Attribution and Compliance
- `ATTRIBUTION.md`
- `CREDITS.md`

### Provider-Specific Guidance
- `deployments/aws/README.md`
- `deployments/azure/README.md`
- `deployments/gcp/README.md`
- `deployments/hetzner/README.md`
- `README_AZURE.md`

### GitHub Wiki Pages
- `wiki/Home.md`
- `wiki/Quickstart.md`
- `wiki/Installation.md`
- `wiki/Provider-Guide.md`
- `wiki/How-To.md`
- `wiki/Prompts.md`
- `wiki/Use-Cases.md`
- `wiki/Architecture-and-Security.md`

---

## 📝 Attribution in Infrastructure

### Deployment Entry Points
The deployment entry points under `deployments/*/main.tf` should continue to reflect upstream dependencies and provider assumptions where appropriate.

### Shared App Layer
The `modules/foundry-app/` area is the clearest expression of the project's system-agnostic design. When this layer changes, update the core docs first.

---

## 📖 How to Use This Documentation

### If You Are Evaluating the Rebrand
- Start with **README.md**
- Continue to **PROJECT_PHILOSOPHY.md**
- Confirm messaging consistency in **DOCUMENTATION_INDEX.md**

### If You Are Planning a New Deployment
- Use **README.md** for setup flow
- Review **SUPPORTED_SYSTEMS.md** for system-family guidance
- Follow the provider-specific README in `deployments/`
- Use the pages under **`wiki/`** when you want GitHub wiki-ready navigation

### If You Are Reviewing Compliance or Upstream Dependencies
- Use **ATTRIBUTION.md** first
- Cross-check **CREDITS.md** for ecosystem acknowledgement
- Confirm that new docs preserve upstream references

---

## 🙏 Special Documentation Priorities

LegendForge docs should consistently communicate:

- The project is **not limited to D&D**
- Foundry is the platform, while systems remain installable choices
- Infrastructure guidance must remain useful across many rulesets
- Attribution and credit are part of maintainable engineering practice

---

## ✅ Documentation Maintenance Rules

When updating LegendForge docs:

1. Preserve the **LegendForge** name consistently
2. Reinforce the **multi-system tabletop** positioning where relevant
3. Keep cloud-provider instructions aligned with real infrastructure behavior
4. Update cross-links whenever a new major document is added
5. Preserve attribution for upstream tools, maintainers, and platforms
6. Avoid collapsing system-agnostic guidance back into single-ruleset assumptions

---

## 📞 Questions?

If you find:
- ❌ Missing or outdated documentation
- 🔗 Broken references
- 📝 Incomplete multi-system coverage
- 🆕 A document that should be indexed here

Please open an issue or submit a pull request.

---

**Last Updated:** June 28, 2026  
**LegendForge Positioning:** Universal tabletop infrastructure for Foundry-compatible systems
