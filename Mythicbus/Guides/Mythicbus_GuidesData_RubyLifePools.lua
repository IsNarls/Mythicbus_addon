-- Mythicbus_GuidesData_RubyLifePools.lua
-- Boss-only mechanics: Ruby Life Pools (no loot). Data file.

local ADDON, NS = ...

local dungeonKey = "RUBY_LIFE_POOLS"

local dungeonData = {
  name = "Ruby Life Pools",
  bosses = {
    {
      name = "Melidrussa Chillworn",
      all = {
        "Bait Hailbombs close together to preserve room; touching the ice blocks deals heavy damage.",
        "Move out of Chillstorm quickly and avoid being knocked into Hailbombs when it explodes.",
        "When Awaken Whelps is cast, kill the whelps quickly.",
        "Break Frost Overload quickly to stop its pulsing party damage.",
      },
      tank = {
        "Call for frequent interrupts on Frigid Shard.",
        "Pick up Infused Whelps quickly and stack them on Melidrussa for cleave.",
      },
      healer = {
        "Use healing cooldowns during Chillstorm and top the party before the explosion.",
        "Cover Frost Overload damage until the shield breaks.",
      },
      dps = {
        "Control Hailbomb placement and swap quickly to whelps after Awaken Whelps.",
        "Prioritize breaking Frost Overload over boss damage.",
      },
    },
    {
      name = "Kokia Blazehoof",
      all = {
        "If targeted by Ritual of Blazebinding, place it near the boss without taking the initial impact.",
        "Swap immediately to Blazebound Firestorm when it spawns.",
        "Interrupt Roaring Blaze at all costs.",
        "After the Firestorm dies, run away from Burnout and avoid the Scorched Earth left behind.",
        "Sidestep Molten Boulder or it will deal heavy damage and stun you.",
      },
      tank = {
        "Bring Kokia near the Blazebound Firestorm so DPS can cleave.",
        "Use active mitigation during Searing Blows and watch Searing Wounds bleed stacks.",
      },
      healer = {
        "Use healing cooldowns for Blazebound Firestorm's Inferno.",
        "Watch the tank during Searing Blows and stacked Searing Wounds.",
      },
      dps = {
        "Hard-swap to Blazebound Firestorm and never miss Roaring Blaze interrupts.",
        "Move out before Burnout resolves and avoid fighting in Scorched Earth.",
      },
    },
    {
      name = "Kyrakka and Erkhart Stormvein",
      note = "Two-phase fight: Erkhart starts alone; Kyrakka joins when Erkhart reaches 50%.",
      all = {
        "Dodge Kyrakka's Roaring Firebreath.",
        "Stop casting near the end of Interrupting Cloudburst so you are not locked out.",
        "Use movement carefully during Winds of Change pushback and party damage.",
        "Handle Inferno Spit targets quickly and avoid spreading fire through the group.",
        "Damage Kyrakka whenever she is on the ground during Phase 1; she is the more dangerous target.",
      },
      tank = {
        "Move Erkhart near Kyrakka during Roaring Firebreath so the party can cleave both bosses.",
        "Use mitigation for Stormslam and ask for a quick dispel of the Nature damage taken debuff.",
      },
      healer = {
        "Dispel the tank after each Stormslam debuff.",
        "Top Inferno Spit targets quickly, especially once Phase 2 overlaps it with Interrupting Cloudburst.",
      },
      dps = {
        "Take every safe opportunity to damage Kyrakka while she is grounded.",
        "Avoid cast lockouts from Interrupting Cloudburst and keep fire placements controlled.",
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
