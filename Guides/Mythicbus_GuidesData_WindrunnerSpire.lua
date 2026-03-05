-- Mythicbus_GuidesData_WindrunnerSpire.lua
-- Boss-only mechanics: Windrunner Spire (no loot). Data file.

local ADDON, NS = ...

local dungeonKey = "WINDRUNNER_SPIRE"

local dungeonData = {
  name = "Windrunner Spire",
  bosses = {
    {
      name = "Emberdawn",
      all = {
        "If you get Flaming Updraft, use a defensive and place it near room edges for safer space management.",
        "During Burning Gale, dodge Flaming Twisters and avoid Fire Breath frontal.",
      },
      tank = {
        "Use major defensives during Searing Beak.",
        "Tank boss in a corner to improve team movement during Burning Gale.",
      },
      healer = {
        "Spot-heal Flaming Updraft targets.",
        "Use major healing cooldowns during Burning Gale.",
      },
      dps = {
        "Prioritize clean Updraft placement and maintain uptime while dodging twisters.",
      },
    },
    {
      name = "Derelict Duo",
      note = "Both bosses must die together to avoid Broken Bond Enrage.",
      all = {
        "Interrupt Kalis's Shadow Bolt.",
        "If targeted by Curse of Darkness and it is not dispelled, outrange the Dark Entity spawn or crowd-control it.",
        "During Splattering Spew, use defensives and place Gunk Splatter cleanly.",
        "Use Latch's Heaving Yank interaction to stop Kalis's Debilitating Shriek.",
      },
      tank = {
        "Use active mitigation before each Bone Hack from Latch.",
        "Keep both bosses stacked for cleave.",
      },
      healer = {
        "Use healing cooldowns during Splattering Spew.",
      },
      dps = {
        "Balance damage between both bosses and preserve kicks for Shadow Bolt.",
      },
    },
    {
      name = "Commander Kroluk",
      all = {
        "Bait Reckless Leap with the furthest player and dodge follow-up Falling Rubble.",
        "Stack during Intimidating Shout to avoid fear.",
        "At 66% and 33%, Rallying Bellow deals heavy party damage and spawns adds; boss has Shield Wall and uses Bladestorm until adds die.",
      },
      tank = {
        "Use major defensives during Rampage.",
        "Stack adds quickly each intermission for efficient cleave.",
      },
      healer = {
        "Spot-heal Reckless Leap targets.",
        "Top the party before every Rallying Bellow.",
      },
      dps = {
        "Swap immediately to intermission adds to remove Shield Wall phase faster.",
      },
    },
    {
      name = "The Restless Heart",
      all = {
        "Dodge Arrow Rain.",
        "Clear Squall Leap debuff using Turbulent Arrows knock-up.",
        "Use defensives during Bolt Gale.",
        "Use Turbulent Arrows to avoid the Billowing Wind wave.",
      },
      tank = {
        "Use active mitigation during each Tempest Slash.",
      },
      healer = {
        "Spot-heal Bolt Gale targets.",
        "Use major cooldowns based on Squall Leap stack pressure.",
      },
      dps = {
        "Manage Turbulent Arrow usage so debuff clears and wave dodges stay consistent.",
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
