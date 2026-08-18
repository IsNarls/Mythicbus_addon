-- Mythicbus_GuidesData_Skyreach.lua
-- Boss-only mechanics: Skyreach (no loot). Data file.

local ADDON, NS = ...

local dungeonKey = "SKYREACH"

local dungeonData = {
  name = "Skyreach",
  bosses = {
    {
      name = "Ranjit",
      all = {
        "Do not get hit by Wind Chakram; it is a one-shot.",
        "Use defensives during Fan of Blades (bleed pressure).",
        "Pre-position for Gale Surge knockback and avoid spawned Coalesced Wind orbs.",
        "During Chakram Vortex, keep moving to avoid incoming Gale Surge patterns.",
      },
      tank = {
        "Move the boss away from active Wind Chakram paths so melee can stay safe.",
      },
      healer = {
        "Plan major cooldowns for Fan of Blades windows.",
      },
      dps = {
        "Stay spread enough to react to knockbacks and orb spawns without clipping teammates.",
      },
    },
    {
      name = "Araknath",
      all = {
        "Use defensives before Supernova.",
        "Soak solar beams to prevent Energize/Solar Infusion stacks on the boss.",
        "Soaking beams deals player damage, so rotate personals while soaking.",
        "Dodge Defensive Protocol heat-wave patterns.",
      },
      tank = {
        "Face Fiery Smash away from the party.",
        "Stay in melee range to prevent Blast Wave casts.",
      },
      healer = {
        "Top players before Supernova.",
        "Prioritize beam soakers for spot-healing.",
      },
      dps = {
        "Coordinate beam soaks so coverage is consistent and not overstacked on one player.",
      },
    },
    {
      name = "Rukhran",
      all = {
        "Stack near boss for Sunbreak so Sunwing spawns in cleave range.",
        "Control Burning Pursuit targets with CC and watch Smoldering Egg placement.",
        "Do not allow new Sunwings to spawn on top of Smoldering Egg or they respawn.",
        "Line-of-sight Searing Quills when possible.",
      },
      tank = {
        "Stay in melee to prevent Screech.",
        "Use active mitigation for Burning Claws.",
      },
      healer = {
        "Sunbreak/Sunwing pulses are key group-damage windows; commit healing cooldowns there.",
        "Spot-heal Burning Pursuit targets aggressively.",
      },
      dps = {
        "Hard swap/cleave Sunwing immediately and help with control on Burning Pursuit.",
      },
    },
    {
      name = "High Sage Viryx",
      all = {
        "Interrupt Solar Blast.",
        "Use defensives if targeted by Scorching Ray.",
        "If targeted by Lens Flare, move away and place Blazing Ground puddles cleanly.",
        "Focus down the Cast Down add quickly.",
      },
      tank = {
        "Drag Viryx toward the Cast Down target so the add can be cleaved with boss damage.",
      },
      healer = {
        "Use major throughput cooldowns during Scorching Ray windows.",
      },
      dps = {
        "Respect puddle placement and commit burst to Cast Down targets.",
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
