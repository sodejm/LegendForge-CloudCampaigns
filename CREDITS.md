# LegendForge Credits & Acknowledgments

LegendForge exists because of the open-source community, the Foundry ecosystem, and the maintainers who have built the tools this infrastructure relies on. This document recognizes the people, projects, and communities behind **LegendForge universal tabletop infrastructure**.

---

## ⭐ Core Projects We Depend On

### **Foundry Virtual Tabletop**
The platform at the center of LegendForge.
- **Founder/Developer:** Atropos
- **Website:** https://foundryvtt.com/
- **GitHub:** https://github.com/foundryvtt
- **License:** Proprietary (commercial)
- **Why it matters:** Foundry enables communities to host many tabletop systems on one flexible VTT foundation.

### **felddy/foundryvtt Docker Image**
Makes secure, repeatable Foundry deployments practical.
- **Maintainer:** Felix Fontein (@felddy)
- **GitHub:** https://github.com/felddy/foundryvtt-docker
- **Docker Hub:** https://hub.docker.com/r/felddy/foundryvtt
- **License:** MIT

> Felix Fontein deserves special recognition for maintaining the Docker image that makes portable Foundry operations dramatically simpler.

### **Cloudflare Tunnel**
Provides secure, zero-trust ingress to LegendForge deployments.
- **Organization:** Cloudflare
- **Website:** https://www.cloudflare.com/products/tunnel/
- **Docs:** https://developers.cloudflare.com/cloudflare-one/

### **Terraform**
The Infrastructure-as-Code engine behind the entire platform.
- **Organization:** HashiCorp
- **Website:** https://www.terraform.io/
- **GitHub:** https://github.com/hashicorp/terraform
- **License:** BSL 1.1

---

## 🎲 Recognition for the Multi-System Tabletop Ecosystem

LegendForge is intentionally bigger than a single ruleset. We want to recognize the broader tabletop communities that make a universal infrastructure approach worthwhile:

- **Dungeons & Dragons communities** running 5e and adjacent content
- **Pathfinder communities** supporting both 1e and 2e play
- **World of Darkness storytellers** bringing gothic horror to Foundry
- **Fate creators and tables** using flexible narrative play styles
- **Powered by the Apocalypse communities** with fiction-first campaign structures
- **Forbidden Lands and other Year Zero-inspired groups** running survival-focused play
- **GUMSHOE and investigative play communities** using Foundry for clue-driven campaigns
- **All other Foundry-compatible system maintainers** extending the platform far beyond one genre

---

## 🔧 Cloud Providers and Their Terraform Providers

### **AWS + Terraform Provider**
- **Provider Maintainers:** HashiCorp
- **Registry:** https://registry.terraform.io/providers/hashicorp/aws/

### **Azure + AzureRM Provider**
- **Provider Maintainers:** HashiCorp
- **Registry:** https://registry.terraform.io/providers/hashicorp/azurerm/

### **Google Cloud + Google Provider**
- **Provider Maintainers:** HashiCorp
- **Registry:** https://registry.terraform.io/providers/hashicorp/google/

### **Hetzner Cloud + Provider**
- **Provider Maintainers:** Hetzner Cloud
- **Registry:** https://registry.terraform.io/providers/hetznercloud/hcloud/
- **License:** MIT

> Special kudos to **Hetzner** for maintaining an excellent provider with clear docs and strong cost efficiency for smaller communities.

---

## 📦 Operating System and Runtime Stack

### **Ubuntu Linux**
Base operating system for LegendForge VM instances.
- **Maintainer:** Canonical
- **Website:** https://ubuntu.com/
- **GitHub:** https://github.com/ubuntu
- **License:** Various (open source)

### **Docker**
Container runtime enabling Foundry deployment portability.
- **Maintainers:** Docker Inc. & community
- **Website:** https://www.docker.com/
- **GitHub:** https://github.com/moby/moby
- **License:** Apache 2.0

### **Cloud-Init**
Instance provisioning tool used throughout the platform.
- **Maintainer:** Canonical
- **Website:** https://cloud-init.io/
- **GitHub:** https://github.com/canonical/cloud-init
- **License:** GPL v3

---

## 🔐 Security and Access Tools

### **HashiCorp Vault**
Referenced in documentation for secrets-management patterns.
- **Website:** https://www.vaultproject.io/
- **License:** BSL 1.1

### **AWS Secrets Manager**
Secure secret storage for AWS deployments.

### **Azure Key Vault**
Secure secret storage for Azure deployments.

### **Google Secret Manager**
Secure secret storage for GCP deployments.

---

## 🙏 Specific Recognition

### Felix Fontein (@felddy)
Maintaining the `felddy/foundryvtt-docker` image is invaluable to LegendForge. Thank you for consistent maintenance and updates.

### Atropos
Creating Foundry Virtual Tabletop, a platform that allows many tabletop communities and genres to share one strong technical foundation.

### HashiCorp Team
For Terraform and the provider ecosystem that make reproducible multi-cloud infrastructure realistic for operators and contributors.

### Cloudflare
For providing excellent zero-trust access tooling and a practical tunnel model for self-hosted VTT infrastructure.

### Hetzner
For affordable, high-quality infrastructure that helps smaller groups run dependable tabletop services.

### Foundry System Maintainers
For creating and maintaining the rulesets, sheets, and integrations that let LegendForge serve more than one tabletop audience.

---

## 🔗 How to Support These Projects

If you appreciate the projects and communities LegendForge relies on:

1. **Foundry VTT** - Purchase a license and support development
2. **Felix Fontein** - Star the Docker repository and contribute where possible
3. **HashiCorp** - Use Terraform, provide feedback, and support the ecosystem
4. **Cloudflare** - Use and advocate for secure access tooling
5. **Canonical** - Support Ubuntu and cloud-init
6. **Docker** - Support the container ecosystem
7. **System maintainers** - Star their repos, report bugs constructively, and contribute documentation or fixes

---

## 📝 License Compliance Notes

LegendForge respects and complies with all dependency licenses:

- ✅ **Terraform & HashiCorp Providers:** BSL 1.1 / MPL 2.0
- ✅ **Hetzner Provider:** MIT
- ✅ **Docker:** Apache 2.0 / Proprietary
- ✅ **Cloud-Init:** GPL v3
- ✅ **Ubuntu:** Various open-source licenses
- ✅ **Foundry VTT:** Commercial license required

When using this infrastructure:
- Ensure you have a valid Foundry VTT license
- Review and accept cloud provider terms
- Respect the licensing of any systems, worlds, or premium modules installed in Foundry

---

## 🤝 Contributing Back

If you extend or improve LegendForge:

1. **Share improvements** - Submit PRs to enhance modules and docs
2. **Write documentation** - Help operators understand multi-system usage
3. **Report bugs** - Help upstream maintainers where issues originate
4. **Credit others** - Preserve attribution for upstream work
5. **Join communities** - Participate in Foundry, Terraform, and system-specific discussions

---

## 📚 Community and Ecosystem Appreciation

### Foundry VTT Community
- For creating system packages, modules, and guides that help tables of every genre succeed
- For documenting upgrade paths, troubleshooting patterns, and compatibility expectations
- For proving that one platform can support many different styles of play

### Terraform Community
- For the registry ecosystem, examples, and operational patterns that improve LegendForge modules
- For sharing best practices that translate well into tabletop hosting infrastructure

### Cloud Community Forums
- For architecture discussions and operational advice across AWS, Azure, GCP, and Hetzner
- For making self-hosted infrastructure more approachable to smaller teams and hobby operators

---

## 🌍 Why the Multi-System Mission Matters

LegendForge is not just rebranding a name. It is clarifying the audience:

- Groups that run one long-form campaign
- Communities that host many systems at once
- Operators who migrate between genres and rulesets
- Contributors who want infrastructure docs that do not assume a single game style

That broader mission only works because upstream creators continue to build and maintain the systems, modules, and platform capabilities we depend on.

---

## 📞 Questions or Missing Credits?

If you believe:
- ✉️ A project or person should be credited
- 🐛 A license is listed incorrectly
- 🔗 A link is broken or outdated
- 📝 Information needs clarification

Please open an issue in this repository.

---

**Last Updated:** June 28, 2026
**LegendForge Motto:** Infrastructure for every Foundry-compatible tabletop story
