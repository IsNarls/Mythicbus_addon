-- Mythicbus_GuidesData_NexusPointXenas.lua
-- Boss-only mechanics: Nexus-Point Xenas (no loot). Data file.

local ADDON, NS = ...

local dungeonKey = "NEXUS_POINT_XENAS"

local dungeonData = {
  name = "Nexus-Point Xenas",
  bosses = {
    {
      name = "Chief Corewright Kasreth",
      all = {
        "Do not pass through active Leyline Array zones without defensives.",
        "Outrange Corespark Detonation and avoid lingering Arcane Spill.",
        "If targeted by Reflux Charge, route through Leyline Arrays to destroy as many as possible.",
        "Interrupt Arcane Zap and sidestep Flux Collapse puddles.",
      },
      tank = {
        "Pull Kasreth closer to Leyline Arrays if melee has Reflux Charge to preserve uptime while clearing arrays.",
      },
      healer = {
        "After each Corespark Detonation, prepare group healing for party-wide Sparkburn.",
      },
      dps = {
        "Prioritize clean Reflux Charge paths and maintain kick order on Arcane Zap.",
      },
    },
    {
      name = "Corewarden Nysarra",
      all = {
        "When targeted by Eclipsing Step, manage movement carefully and avoid clipping teammates.",
        "During Null Vanguard, quickly kill the spawned Dreadflail and Grand Nullifier before Lightscar Flare.",
        "During Lightscar Flare, use defensives and commit damage cooldowns; the boss takes massively increased damage.",
      },
      tank = {
        "Use major defensives for Umbral Lash; it applies follow-up Void Gash.",
      },
      healer = {
        "Use healing cooldowns in Lightscar Flare, which applies sustained party damage.",
      },
      dps = {
        "Hard-swap to Null Vanguard adds and reserve burst for Lightscar Flare burn windows.",
      },
    },
    {
      name = "Lothraxion",
      all = {
        "If targeted by Brilliant Dispersion, use a defensive; the follow-up DoT is heavy.",
        "After Brilliant Dispersion resolves, avoid Fractured Image contact and knockback.",
        "During Divine Guile, identify the correct boss image by horns and interrupt the correct shade.",
        "Interrupting the wrong shade or missing the interrupt triggers Core Exposure and high raid damage.",
      },
      tank = {
        "Use major defensives for each Searing Rend.",
      },
      healer = {
        "Plan major healing cooldowns around each Brilliant Dispersion.",
      },
      dps = {
        "Handle Divine Guile correctly and preserve interrupts for the correct shade each phase.",
      },
    },
  },
}

if NS.MBUS_GuidesDB and NS.MBUS_GuidesDB.RegisterDungeon then
  NS.MBUS_GuidesDB:RegisterDungeon(dungeonKey, dungeonData)
else
  NS.MBUS_GuidesPending = NS.MBUS_GuidesPending or {}
  table.insert(NS.MBUS_GuidesPending, { key = dungeonKey, data = dungeonData })
end
