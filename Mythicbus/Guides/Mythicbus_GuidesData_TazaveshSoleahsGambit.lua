-- Mythicbus_GuidesData_TazaveshSoleahsGambit.lua
-- Boss-only mechanics: Tazavesh: So'leah's Gambit (no loot). Data file.
-- Requires Mythicbus_GuidesDB.lua (NS.MBUS_GuidesDB) somewhere in your addon load order.

local ADDON, NS = ...

local dungeonKey = "TAZAVESH_SOLEAHS_GAMBIT"

local dungeonData = {
  name = "Tazavesh: So'leah's Gambit",
  bosses = {
    {
      name = "Hylbrande",
      all = {
        "Avoid Titanic Crash frontal.",
        "If targeted by Purged by Fire, kite it away from the boss for safer Purging Field / ichor management.",
        "Kill Vault Purifiers ASAP: interrupt Valorous Bolt and stop Empowered Defense (it reduces boss damage taken).",
        "During Sanitizing Cycle, one player uses the console while the rest assemble the correct color sequence.",
      },
      tank = {
        "Use active mitigation for Shearing Swings.",
        "Try to stack Vault Purifiers on the boss for better cleave.",
      },
      healer = {
        "Make sure targets about to be hit by Purifying Burst are topped up.",
      },
      dps = {
        -- No explicit DPS section on the page; use All Roles guidance.
      },
    },

    {
      name = "Timecap'n Hooktail",
      all = {
        "Never stay near the water or you can die to Deadly Seas sharks.",
        "Stay stacked so Infinite Breath can clear fixating adds efficiently (adds fixate random players and tend to path the same way).",
      },
      tank = {
        "When Corsair Brute / Corsair Cannoneers spawn, aim Infinite Breath at them to kill them.",
      },
      healer = {
        "Be careful dispelling Time Bomb: dispelling triggers Temporal Detonation (party-wide damage).",
      },
      dps = {
        -- No explicit DPS section on the page; use All Roles guidance.
      },
    },

    {
      name = "So'leah",
      all = {
        "Phase 1: prioritize So'Cartel Assassins; kill them quickly and interrupt Shuriken Blitz.",
        "Phase 2: during Power Overwhelming, use Hyperlight Jolt to break the stars and continue the phase (repeats multiple times).",
        "Out-range Hyperlight Nova from the stars.",
        "Avoid Energy Fragmentation frontals from the stars.",
      },
      tank = {
        -- Page lists '-' for tank.
      },
      healer = {
        "Use major healing cooldowns during Collapsing Star.",
        "Do not let anyone reach more than 1 stack of the Collapsing Star debuff; you have time to manage it (no need to rush).",
      },
      dps = {
        -- No explicit DPS section on the page; use All Roles guidance.
      },
    },
  },
}

-- Register now if DB is loaded; otherwise queue for DB to ingest later.
if NS.MBUS_GuidesDB and NS.MBUS_GuidesDB.RegisterDungeon then
  NS.MBUS_GuidesDB:RegisterDungeon(dungeonKey, dungeonData)
else
  NS.MBUS_GuidesPending = NS.MBUS_GuidesPending or {}
  table.insert(NS.MBUS_GuidesPending, { key = dungeonKey, data = dungeonData })
end
