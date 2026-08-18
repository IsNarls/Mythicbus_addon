-- Mythicbus_GuidesData_PitOfSaron.lua
-- Boss-only mechanics: Pit of Saron (no loot). Data file.

local ADDON, NS = ...

local dungeonKey = "PIT_OF_SARON"

local dungeonData = {
  name = "Pit of Saron",
  bosses = {
    {
      name = "Forgemaster Garfrost",
      all = {
        "If targeted by Throw Saronite, place Ore Chunks close together for easier tank Orebreaker routing.",
        "Use defensives during Cryostomp; it is heavy group-wide damage and applies Cryoshards.",
        "During Glacial Overload, line behind Ore Chunks to avoid lethal stack buildup.",
      },
      tank = {
        "Break Ore Chunks efficiently with Orebreaker so multiple chunks do not overlap and wipe the group on Cryostomp.",
      },
      healer = {
        "Use major throughput cooldowns on Cryostomp.",
        "Dispel Cryoshards quickly and stabilize ongoing aura damage.",
      },
      dps = {
        "Prioritize safe Ore Chunk placement and preserve personals for Cryostomp windows.",
      },
    },
    {
      name = "Ick & Krick",
      note = "Both bosses share health (Necrolink), so keep cleave uptime high.",
      all = {
        "Sidestep Plague Globs and avoid Blight ground.",
        "Interrupt Krick's Death Bolt.",
        "During Shade Shift, focus Shades of Krick and stop Shadowbind (or decurse it).",
        "If targeted by Lumbering Fixation, kite away from boss melee range.",
      },
      tank = {
        "Use major defensives for Blight Smash and avoid standing in Blight pools.",
        "Keep both bosses stacked for cleave.",
      },
      healer = {
        "Spot-heal Shadow Lance targets and prepare for Plague Expulsion damage spikes.",
      },
      dps = {
        "Maintain interrupts on Death Bolt/Shadowbind and swap quickly to Shades during Shade Shift.",
      },
    },
    {
      name = "Scourgelord Tyrannus",
      all = {
        "If targeted by Rime Blast, place it on Bone Piles/Infused Bone Piles to simplify Army of the Dead.",
        "Use defensives during Bone Infusion.",
        "During Army of the Dead, prioritize Scourge Plaguespreader and interrupt casts immediately.",
        "Dodge Death's Grasp puddles and Ice Barrage.",
      },
      tank = {
        "Use major defensives for Scourgelord's Brand and avoid Scourgelord's Reckoning hits.",
      },
      healer = {
        "Commit major cooldowns during Bone Infusion damage windows.",
      },
      dps = {
        "Burst priority add targets during Army of the Dead and preserve kicks for dangerous casts.",
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
