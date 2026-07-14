# Foundry VTT (dnd5e) Integration

LegendForge character records map cleanly to the Foundry VTT **dnd5e** Actor
data model, so storage stays seamless with what your hosted Foundry already
runs. A bidirectional converter ships in `../scripts/to-foundry-dnd5e.mjs`.

## Field mapping

| LegendForge (`character.schema.json`) | Foundry dnd5e Actor |
| --- | --- |
| `characterName` | `name` |
| `id`, `schemaVersion` | `flags.legendforge.*` |
| `attributes.strength` … `charisma` | `system.abilities.{str,dex,con,int,wis,cha}.value` |
| `hitPoints.{current,max,temporary}` | `system.attributes.hp.{value,max,temp}` |
| `armorClass` | `system.attributes.ac.{calc:"flat",flat}` |
| `speed` | `system.attributes.movement.walk` |
| `level` | class Item `system.levels` |
| `characterClass` | class Item `name` |
| `ancestry` / `background` / `alignment` | `system.details.{race,background,alignment}` |
| `experiencePoints` | `system.details.xp.value` |
| `currency.{pp,gp,sp,cp}` | `system.currency.*` |
| `inventory[]` | `items[]` (`loot`, qty/equipped) |
| `notes` | `system.details.biography.value` |

## Export to Foundry

```bash
node prompts/scripts/to-foundry-dnd5e.mjs to \
  prompts/examples/character.example.json > actor.json
```

In Foundry: create/right-click an Actor → **Import Data** → select `actor.json`.
Stable id and schema version are preserved in `flags.legendforge` for re-sync.

## Import from Foundry

Export an actor in Foundry, then:

```bash
node prompts/scripts/to-foundry-dnd5e.mjs from actor.json > character.json
```

The round-trip is lossless for stored fields and re-validates against
`character.schema.json`. See `../examples/foundry-dnd5e-actor.example.json`.
