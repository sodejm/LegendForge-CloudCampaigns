#!/usr/bin/env node
/**
 * Convert a LegendForge character record (character.schema.json) to/from a
 * Foundry VTT dnd5e Actor JSON, importable via an Actor's "Import Data".
 *
 * Usage:
 *   node to-foundry-dnd5e.mjs to   character.example.json   > actor.json
 *   node to-foundry-dnd5e.mjs from actor.json               > character.json
 */
import { readFileSync } from "node:fs";

const ABIL = ["strength", "dexterity", "constitution", "intelligence", "wisdom", "charisma"];
const ABBR = { strength: "str", dexterity: "dex", constitution: "con", intelligence: "int", wisdom: "wis", charisma: "cha" };
const INVENTORY_ITEM_TYPE = "loot";

function restoreOptionalString(value, preservedValue) {
  return value === "" && preservedValue === undefined ? undefined : (value ?? preservedValue);
}

function toFoundry(c) {
  const abilities = {};
  for (const a of ABIL) abilities[ABBR[a]] = { value: c.attributes?.[a] ?? 10 };
  const cur = c.currency ?? {};
  return {
    name: c.characterName,
    type: "character",
    flags: { legendforge: { id: c.id, schemaVersion: c.schemaVersion, source: c } },
    system: {
      abilities,
      attributes: {
        hp: { value: c.hitPoints?.current ?? 0, max: c.hitPoints?.max ?? 0, temp: c.hitPoints?.temporary ?? 0 },
        ac: { calc: "flat", flat: c.armorClass ?? 10 },
        movement: { walk: c.speed ?? 30 }
      },
      details: {
        race: c.ancestry ?? "",
        background: c.background ?? "",
        alignment: c.alignment ?? "",
        xp: { value: c.experiencePoints ?? 0 },
        biography: { value: c.notes ?? "" }
      },
      currency: { pp: cur.pp ?? 0, gp: cur.gp ?? 0, sp: cur.sp ?? 0, cp: cur.cp ?? 0 }
    },
    items: [
      { name: c.characterClass, type: "class", system: { levels: c.level ?? 1 } },
      ...(c.inventory ?? []).map(i => ({
        name: i.name, type: "loot",
        flags: { legendforge: { source: i } },
        system: { quantity: i.quantity ?? 1, equipped: !!i.equipped, description: { value: i.notes ?? "" } }
      }))
    ]
  };
}

function fromFoundry(a) {
  const s = a.system ?? {};
  const cls = (a.items ?? []).find(i => i.type === "class");
  const attributes = {};
  for (const full of ABIL) attributes[full] = s.abilities?.[ABBR[full]]?.value ?? 10;
  const preserved = a.flags?.legendforge?.source ?? {};
  const inventory = (a.items ?? []).filter(i => i.type === INVENTORY_ITEM_TYPE).map(i => ({
    ...(i.flags?.legendforge?.source ?? {}),
    name: i.name,
    quantity: i.system?.quantity ?? 1,
    equipped: !!i.system?.equipped,
    notes: restoreOptionalString(i.system?.description?.value, i.flags?.legendforge?.source?.notes)
  }));
  return {
    ...preserved,
    updatedAt: new Date().toISOString(),
    schemaVersion: a.flags?.legendforge?.schemaVersion ?? "1.0.0",
    id: a.flags?.legendforge?.id ?? a.name?.toLowerCase().replace(/\s+/g, "_"),
    system: "dnd5e",
    characterName: a.name,
    characterClass: cls?.name ?? "Adventurer",
    ancestry: restoreOptionalString(s.details?.race, preserved.ancestry),
    background: restoreOptionalString(s.details?.background, preserved.background),
    level: cls?.system?.levels ?? 1,
    experiencePoints: s.details?.xp?.value ?? 0,
    alignment: restoreOptionalString(s.details?.alignment, preserved.alignment),
    attributes,
    hitPoints: { current: s.attributes?.hp?.value ?? 0, max: s.attributes?.hp?.max ?? 1, temporary: s.attributes?.hp?.temp ?? 0 },
    armorClass: s.attributes?.ac?.flat ?? s.attributes?.ac?.value,
    speed: s.attributes?.movement?.walk,
    currency: {
      pp: s.currency?.pp ?? 0,
      gp: s.currency?.gp ?? 0,
      sp: s.currency?.sp ?? 0,
      cp: s.currency?.cp ?? 0
    },
    inventory,
    notes: restoreOptionalString(s.details?.biography?.value, preserved.notes)
  };
}

const [dir, file] = process.argv.slice(2);
const data = JSON.parse(readFileSync(file, "utf8"));
const out = dir === "from" ? fromFoundry(data) : toFoundry(data);
process.stdout.write(JSON.stringify(out, null, 2) + "\n");
