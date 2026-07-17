# LegendForge AI Prompt Library

A curated, system-agnostic store of useful AI prompts and the data schemas that
back them. Just as the rest of LegendForge keeps Foundry VTT hosting portable
across clouds, this library keeps **game-master and player tooling portable
across rulesets** — store reusable prompts, and store/update player and
character information in versioned, validatable JSON.

## 📁 Layout

```
prompts/
├── README.md                         # This file
├── dungeon-masters/
│   └── dnd-5e-strict-dm.md           # Strict, mechanical D&D 5e DM prompt
├── schemas/
│   ├── character.schema.json         # Character profile schema (draft-07)
│   └── player.schema.json            # Player / seat schema (draft-07)
├── integrations/
│   └── foundry-dnd5e.md              # Seamless Foundry VTT dnd5e mapping
├── scripts/
│   └── to-foundry-dnd5e.mjs          # Bidirectional Foundry converter
└── examples/
    ├── character.example.json        # Sample character profile
    ├── foundry-dnd5e-actor.example.json # Same character as a Foundry Actor
    └── player.example.json           # Sample player record
```

## 🎲 Foundry VTT

Character records map 1:1 to the Foundry **dnd5e** Actor model. Convert in
either direction and use Foundry's **Import Data** — see
[`integrations/foundry-dnd5e.md`](integrations/foundry-dnd5e.md).

## 🎲 How it fits the ecosystem

- **D&D-oriented:** schemas target 5e-style character data and may need
  ruleset-specific extensions for broader reuse.
- **Storable & updatable:** every record carries an `id`, `schemaVersion`, and
  `updatedAt` so it can live in a campaign store, be diffed, and be patched.
- **Portable:** plain JSON + Markdown, no engine lock-in.

## ✅ Validating data

Any draft-07 validator works. Example with `ajv`:

```bash
npx --yes --package=ajv-cli --package=ajv-formats ajv validate \
  -c ajv-formats -s prompts/schemas/character.schema.json -d prompts/examples/character.example.json
npx --yes --package=ajv-cli --package=ajv-formats ajv validate \
  -c ajv-formats -s prompts/schemas/player.schema.json -d prompts/examples/player.example.json
```

## ➕ Adding prompts

1. Drop the prompt in the matching role folder (e.g. `dungeon-masters/`).
2. If it consumes data, point it at a schema in `schemas/`.
3. Add an example payload to `examples/` and keep it passing validation.
