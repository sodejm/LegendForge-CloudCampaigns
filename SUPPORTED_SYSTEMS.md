# Supported Systems in LegendForge

LegendForge is designed as **system-agnostic infrastructure for Foundry VTT**. That means the infrastructure layer does not assume a specific game engine, ruleset, genre, or campaign style. If a system runs in Foundry and matches your Foundry version, LegendForge is intended to give it a secure, portable, cloud-ready home.

---

## 🧭 Compatibility Model

LegendForge supports tabletop systems at the **infrastructure level**, not by embedding system-specific application logic into Terraform. In practice, that means:

- LegendForge deploys and operates **Foundry VTT**
- Game systems are installed and maintained **inside Foundry**
- The same infrastructure patterns apply whether you run fantasy, horror, sci-fi, investigation, narrative, or mixed-genre campaigns
- Compatibility depends on the specific **Foundry version**, **system package version**, and **module stack** you choose

LegendForge is therefore best understood as **universal hosting infrastructure for Foundry-compatible systems**.

---

## ✅ Commonly Supported System Families

The following systems and system families are explicitly part of the LegendForge documentation focus.

### Dungeons & Dragons
- **D&D 5e**
- Other Foundry-compatible D&D-adjacent content as available in the ecosystem

**Why LegendForge fits:** Strong support for long-running campaigns, asset libraries, and community modules.

### Pathfinder
- **Pathfinder 1e**
- **Pathfinder 2e**

**Why LegendForge fits:** Stable storage, backups, and predictable infrastructure are especially valuable for automation-heavy Pathfinder tables.

### World of Darkness / Storyteller Family
- **Vampire**
- **Werewolf**
- **Hunter**
- Related Storyteller and gothic-horror systems when supported in Foundry

**Why LegendForge fits:** Secure remote access and reliable uptime help story-focused groups preserve persistent worlds and chronicles.

### Fate
- **Fate Core**
- **Fate Accelerated**
- **Fate Condensed**

**Why LegendForge fits:** Narrative-first games benefit from lightweight infrastructure that stays out of the way while keeping journals, scenes, and assets available.

### Powered by the Apocalypse (PbtA)
- PbtA-based games supported by the Foundry ecosystem
- Fiction-first games with custom playbooks, moves, and world-building tools

**Why LegendForge fits:** Flexible infrastructure works well for groups that switch between multiple PbtA campaigns or custom hacks.

### Forbidden Lands
- **Forbidden Lands** and adjacent survival-focused fantasy experiences supported in Foundry

**Why LegendForge fits:** Persistent storage and backup workflows protect hex maps, journals, and long-form campaign progression.

### GUMSHOE and Investigation-Focused Games
- GUMSHOE-derived systems supported by Foundry
- Other investigative or clue-driven systems using Foundry as their platform

**Why LegendForge fits:** Operators can maintain always-available campaign data, notes, and evidence structures with cloud resilience.

---

## 🌐 Additional System Categories LegendForge Can Host

Because LegendForge is infrastructure rather than a rules implementation, it can also support many other Foundry-compatible experiences such as:

- Science fiction systems
- Horror systems
- OSR-style systems
- Narrative indie systems
- School or club multi-campaign environments
- Shared-world community servers
- Experimental or homebrew systems packaged for Foundry

If it is compatible with your Foundry version, LegendForge is designed to host it.

---

## ⚠️ Compatibility Notes and Operator Responsibilities

Before declaring a specific table or world "supported," verify the following:

1. **Foundry Version Compatibility**
   - Confirm your chosen system supports your Foundry release.

2. **Module Stack Compatibility**
   - Multi-system environments often diverge in module needs.
   - Test automation-heavy modules independently per world.

3. **Licensing and Content Access**
   - Some systems, premium modules, and content packs may require their own licenses.
   - LegendForge does not change or bypass those requirements.

4. **Data Migration Planning**
   - Back up world data before upgrading systems or Foundry.
   - Snapshot persistent volumes before major ruleset changes.

5. **Operational Segmentation**
   - Consider separate worlds, separate module profiles, or separate deployments for radically different communities.

---

## 🛠️ Best Practices for Multi-System Operators

- Keep **one clear upgrade policy** for Foundry core
- Document **system-specific module dependencies** outside Terraform
- Use **backups before every major system or module upgrade**
- Validate new rulesets in a test world before production use
- Prefer **stable, well-maintained systems** for shared community deployments
- Use cloud tags, notes, or docs to track which deployment serves which game community

---

## 📚 Related LegendForge Documentation

- [README.md](README.md) - Project overview and quick start
- [PROJECT_PHILOSOPHY.md](PROJECT_PHILOSOPHY.md) - Why system-agnostic infrastructure matters
- [ATTRIBUTION.md](ATTRIBUTION.md) - Upstream projects and compliance notes
- [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md) - Documentation navigation hub

---

## Summary

LegendForge supports **D&D 5e, Pathfinder 1e/2e, World of Darkness, Fate, Powered by the Apocalypse, Forbidden Lands, GUMSHOE, and other Foundry-compatible systems** by staying intentionally **agnostic at the infrastructure layer**.

That is the core promise: **one infrastructure platform, many tabletop worlds**.
