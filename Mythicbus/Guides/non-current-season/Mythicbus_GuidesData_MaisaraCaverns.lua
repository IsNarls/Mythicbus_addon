-- Mythicbus_GuidesData_MaisaraCaverns.lua
-- Boss-only mechanics: Maisara Caverns (no loot). Data file.

local ADDON, NS = ...

local dungeonKey = "MAISARA_CAVERNS"

local dungeonData = {
  name = "Maisara Caverns",
  bosses = {
    {
      name = "Muro'jin & Nekraxx",
      note = "Keep boss health even and kill both together to avoid Bestial Wrath / Revive Pet recoveries.",
      all = {
        "Use defensives during Infected Pinions, especially if Barrage overlaps.",
        "Dodge Fetid Quillstorm.",
        "If targeted by Carrion Swoop, route into a Freezing Trap and avoid clipping teammates.",
      },
      tank = {
        "Use active mitigation for Flanking Spear.",
        "Keep both bosses stacked for cleave efficiency.",
      },
      healer = {
        "Commit major cooldowns during Infected Pinions windows.",
      },
      dps = {
        "Maintain balanced boss damage so both targets die at the same time.",
      },
    },
    {
      name = "Vordaza",
      all = {
        "Dodge Unmake frontal.",
        "During Final Pursuit, collide Unstable Phantoms together to clear them.",
        "Do not overstack Lingering Dread while clearing phantoms; keep stacks controlled for healer stability.",
        "Save major cooldowns for Necrotic Convergence to break Deathshroud quickly while dodging Coalesced Death orbs.",
      },
      tank = {
        "Use major defensives for each Drain Soul.",
      },
      healer = {
        "This fight has constant rot pressure; save major cooldowns for Lingering Dread overlap and Necrotic Convergence.",
      },
      dps = {
        "Prioritize fast shield break during Necrotic Convergence and clean movement on orb patterns.",
      },
    },
    {
      name = "Rak'tul, Vessel of Souls",
      all = {
        "During Crush Souls, group tighter so Soulbind Totem can be cleaved down efficiently.",
        "Sidestep Volatile Essence and use defensives during Deathgorged Vessel.",
        "During Soulrending Roar, interrupt/CC Malignant Soul to gain Spectral Residue stacks and accelerate the fight.",
      },
      tank = {
        "Use major defensives for Spiritbreaker and watch leap placement to avoid bad Spectral Decay ground.",
        "Keep Rak'tul near the Soulbind Totem for better cleave.",
      },
      healer = {
        "Use major healing cooldowns during Deathgorged Vessel.",
        "Keep the party stabilized during Soulrending Roar as Spectral Residue stacks rise.",
      },
      dps = {
        "Commit interrupts/CC on Malignant Souls and optimize totem cleave during Crush Souls sets.",
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
