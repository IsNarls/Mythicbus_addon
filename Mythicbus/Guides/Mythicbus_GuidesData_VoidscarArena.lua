-- Mythicbus_GuidesData_VoidscarArena.lua
-- Boss-only mechanics: Voidscar Arena (no loot). Data file.

local ADDON, NS = ...

local dungeonKey = "VOIDSCAR_ARENA"

local dungeonData = {
  name = "Voidscar Arena",
  bosses = {
    {
      name = "Taz'Rah",
      all = {
        "If targeted by Nether Dash, stay near the group so Umbral Rupture and Void Fissure placements are easier to manage.",
        "During Dark Bloom, dodge all incoming orbs; getting hit can be lethal.",
        "Keep Void Fissures controlled by rotating the boss around the edge of the arena.",
      },
      tank = {
        "Use active mitigation for Void Blast.",
        "Start near a close wall and rotate clockwise or counter-clockwise to preserve safe space.",
      },
      healer = {
        "Top players before each Umbral Rupture.",
        "Be ready for movement-heavy healing during Dark Bloom orb dodging.",
      },
      dps = {
        "Stay coordinated for Nether Dash placements and avoid spreading Void Fissures through the middle.",
        "Prioritize survival during Dark Bloom over greed damage.",
      },
    },
    {
      name = "Atroxus",
      all = {
        "Dodge Poison Pool puddles during Poison Splash to avoid Mind-Numbing Poison.",
        "Sidestep Noxious Breath frontal.",
        "After each Monstrous Roar, kill the Toxic Creeper quickly before Toxic Aura overwhelms the group.",
      },
      tank = {
        "Use active mitigation before Hulking Claw and call for a poison dispel if needed.",
        "Do not let Toxic Creeper melee you; Sickening Bite can kill you.",
        "Keep Atroxus and Toxic Creeper close enough for cleave without letting the add reach the tank.",
      },
      healer = {
        "Use major healing cooldowns during Toxic Creeper spawns because Toxic Aura deals heavy group damage.",
        "Dispel poison effects frequently when your toolkit allows it.",
      },
      dps = {
        "Swap hard to Toxic Creeper after Monstrous Roar.",
        "Keep frontal and poison puddle movement clean while burning the add.",
      },
    },
    {
      name = "Charonus",
      all = {
        "During Unstable Singularity, position near the stars without being pulled into them accidentally.",
        "Spread for Cosmic Crash so you do not clip party members.",
        "If targeted by Gravitic Orbs, enter stars from Unstable Singularity to destroy them quickly.",
        "Pre-position near a star before Gravitic Orbs to reduce Condensed Mass damage.",
        "If targeted by Void Cascade, keep moving to avoid the frontal.",
      },
      tank = {
        "Use active mitigation for Dark Waves and aim the frontal away from the party.",
        "Position Charonus near the middle of the three Unstable Singularity stars.",
      },
      healer = {
        "Spot-heal Gravitic Orbs targets, especially if they are slow to clear Condensed Mass.",
        "Prepare for movement-heavy healing during Cosmic Crash and Void Cascade.",
      },
      dps = {
        "Clear Gravitic Orbs quickly by entering nearby stars.",
        "Stay spread enough for Cosmic Crash while preserving access to stars.",
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
