-- Mythicbus_GuidesData_EcoDomeAldani.lua
-- Boss-only mechanics: Eco-Dome Al'dani (no loot). Data file.
-- Requires Mythicbus_GuidesDB.lua (NS.MBUS_GuidesDB) somewhere in your addon load order.

local ADDON, NS = ...

local dungeonKey = "ECO_DOME_ALDANI"

local dungeonData = {
  name = "Eco-Dome Al'dani",
  bosses = {
    {
      name = "Azhiccar",
      all = {
        "When Frenzied Mites appear, stack together and use crowd control to stop their Engorge attacks.",
        "If targeted by Toxic Regurgitation, use a defensive and do NOT stack with others (double-stacking the debuff is dangerous).",
        "At 100 energy: Devour — crowd-control the 2 packs of Frenzied Mites so they don’t reach the boss; if they do, Azhiccar will Feast on them and heal (main fight mechanic).",
      },
      tank = {
        "Stay close to melee so the boss does not cast Thrash.",
      },
      healer = {
        "Keep people topped during Invading Shriek (the cast + mites can spike the party).",
        "Use healing cooldowns during Devour.",
      },
      dps = {
        "When mites spawn: collapse/stack to gather them, then help with stuns/roots/knockbacks to deny Engorge and prevent Devour/Feast value.",
      },
    },

    {
      name = "Taah'bat and A'wazj",
      all = {
        "If targeted by Binding Javelin, use a defensive; if NOT targeted, don’t stand near another player’s anchor to avoid extra damage.",
        "At max energy: Arcane Blitz — aim 6 Warp Strikes toward the boss to break its Incorporeal (damage immunity).",
      },
      tank = {
        "Use active mitigation for Rift Claws.",
      },
      healer = {
        "Use healing cooldowns during Arcane Blitz: Warp Strike stacks + Arcane Overload create heavy group damage.",
      },
      dps = {
        "During Arcane Blitz, help ensure Warp Strikes are aimed into the boss to break Incorporeal quickly.",
        "Do not stand near other players’ Binding Javelin anchors.",
      },
    },

    {
      name = "Soul-Scribe",
      all = {
        "During Whispers of Fate, collect your soul to gain Fatebound; failing to do so gives Wounded Fate.",
        "Avoid Ceremonial Dagger at all times.",
        "Use a defensive during Dread of the Unknown.",
        "At 100 energy: Eternal Weave — collect all your souls for Fatebound while avoiding the frontal.",
      },
      tank = {
        -- Icy-Veins lists no tank-specific note here.
      },
      healer = {
        "Dread of the Unknown is especially dangerous while Echoes of Fate is present—pay close attention to party health and triage quickly.",
      },
      dps = {
        "Prioritize collecting your soul(s) on Whispers of Fate / Eternal Weave while staying safe from the frontal and Ceremonial Dagger.",
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
