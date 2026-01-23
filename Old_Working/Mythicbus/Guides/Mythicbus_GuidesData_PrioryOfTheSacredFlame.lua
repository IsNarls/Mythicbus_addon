-- Mythicbus_GuidesData_PrioryOfTheSacredFlame.lua
-- Boss-only mechanics: Priory of the Sacred Flame (no loot). Data file.
-- Requires Mythicbus_GuidesDB.lua (NS.MBUS_GuidesDB) somewhere in your addon load order.

local ADDON, NS = ...

local dungeonKey = "PRIORY_OF_THE_SACRED_FLAME"

local dungeonData = {
  name = "Priory of the Sacred Flame",
  bosses = {
    {
      name = "Pre-event: Mini-bosses before Captain Dailcry",
      note = "Kill Guard Captain Suleyman, High Priest Aemya, and Forge Master Damian to remove lethal boss buffs/guards.",
      all = {
        "There are 3 mini-bosses in the first area; each death calls out a guard and removes Strength in Numbers from Captain Dailcry (and Bound by Fate on Mythic).",
        "If you pull Captain Dailcry with guards up (not recommended):",
        "• Sergeant Shaynemail: heavy tank hit + bleed from Lunging Strike; avoid Brutal Smash AoE.",
        "• Taener Duelmal: interrupt Cinderblast and Fireball.",
        "• Elaena Emberlanz: watch Holy Radiance group damage; tank mind Divine Judgment; interrupt Repentance.",
      },
      tank = {
        "If guards are present, keep boss/guard frontals controlled and give your party space to dodge Brutal Smash and other AoE.",
      },
      healer = {
        "If Elaena is present, be ready for Holy Radiance group damage and react quickly to Repentance/other disruption.",
      },
      dps = {
        "If guards are present, prioritize interrupts (Cinderblast/Fireball/Repentance) and dodge Brutal Smash.",
      },
    },

    {
      name = "Captain Dailcry",
      all = {
        "Avoid Earthshattering Spear frontal.",
        "Interrupt Battle Cry (Enrage).",
        "Use a defensive if targeted by Savage Mauling.",
      },
      tank = {
        "Use active mitigation for Pierce Armor (stacking bleed).",
      },
      healer = {
        "Spot-heal the Savage Mauling target.",
        "Keep everyone healthy after any Holy Radiance casts (if Elaena is involved).",
      },
      dps = {
        "Help interrupt Battle Cry and avoid the Spear frontal; don’t overlap defensives with the Mauling target if healers need externals elsewhere.",
      },
    },

    {
      name = "Baron Braunpyke",
      all = {
        "Avoid the initial ground animation of Hammer of Purity and its follow-up effect.",
        "Interrupt Burning Light.",
        "Move away from Castigator's Detonation ground after the initial hit of Castigator's Shield.",
      },
      tank = {
        "Help soak Sacrificial Pyre stacks (the follow-up Sacrificial Flame is very dangerous). Each soak causes group-wide damage; immunities are excellent here.",
      },
      healer = {
        "At 100 energy the boss casts Vindictive Wrath, empowering abilities—especially dangerous if Sacrificial Flame is active.",
        "Top people quickly when Castigator's Shield is being cast (damage spikes).",
      },
      dps = {
        "Prioritize Burning Light interrupts and keep moving cleanly for Hammer of Purity / Castigator’s Detonation.",
      },
    },

    {
      name = "Prioress Murrpray",
      all = {
        "Interrupt as many Holy Smite casts as possible.",
        "Avoid Holy Flame ground visuals.",
        "If targeted by The Sacred Flame, keep moving to reduce damage and avoid leaving bad ground in the group.",
        "Face away during Blinding Light to reduce damage and avoid being disoriented.",
        "At 50%: Barrier of Light (shield) + boss goes to the upper platform—break the absorb and interrupt Embrace the Light.",
      },
      tank = {
        "Move the boss away from holy ground patches left by The Sacred Flame.",
        "Control the incoming Arathi Neophyte after Barrier of Light.",
      },
      healer = {
        "Use major healing cooldowns during Inner Fire (group-wide damage).",
        "Keep players healthy after each Blinding Light cast.",
      },
      dps = {
        "Kick Holy Smite aggressively; on 50% phase, swap to breaking Barrier of Light and interrupt Embrace the Light ASAP.",
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
