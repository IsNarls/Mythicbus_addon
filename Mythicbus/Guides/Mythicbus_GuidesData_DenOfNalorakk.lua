-- Mythicbus_GuidesData_DenOfNalorakk.lua
-- Boss-only mechanics: Den of Nalorakk (no loot). Data file.

local ADDON, NS = ...

local dungeonKey = "DEN_OF_NALORAKK"

local dungeonData = {
  name = "Den of Nalorakk",
  bosses = {
    {
      name = "The Hoardmonger",
      all = {
        "Avoid Earthshatter Slam frontal.",
        "During Spoiled Supplies, spread and soak all growing mushrooms before they detonate as Putrid Burst.",
        "Each mushroom soak applies Toxic Spores, so rotate soakers and use defensives if stacks get high.",
        "Prevent missed soaks; Putrid Burst deals heavy party damage and can wipe the group.",
      },
      tank = {
        "Use your durability to help soak extra mushrooms during Spoiled Supplies.",
        "Keep the boss positioned so the group can spread for mushrooms without crossing the frontal.",
      },
      healer = {
        "Use healing cooldowns during Ravenous Bellow.",
        "Watch players with high Toxic Spores stacks after mushroom soaks.",
      },
      dps = {
        "Help cover mushroom soaks quickly and keep movement clean around Earthshatter Slam.",
      },
    },
    {
      name = "Sentinel of Winter",
      all = {
        "Dodge Raging Squall tornadoes.",
        "When Shattering Frostspike spawns Fractured Shivercores, interrupt Winter's Shroud casts.",
        "After a Shivercore dies, one player should soak Rimeshatter to prevent Rime Detonation.",
        "Use Snowdrift from dead Shivercores to become immune to forced movement and reduce Frozen Tempest danger.",
        "Time Shivercore kills so Snowdrift is available for Frozen Tempest.",
      },
      tank = {
        "Position the boss near each Fractured Shivercore so the party can cleave both targets.",
      },
      healer = {
        "Dispel Glacial Torment as often as possible.",
        "Prepare healing for Frozen Tempest windows, especially if Snowdrift timing is missed.",
      },
      dps = {
        "Focus Fractured Shivercores, interrupt Winter's Shroud, and coordinate Rimeshatter soaks.",
      },
    },
    {
      name = "Nalorakk",
      all = {
        "Place Echoing Maul near a corner so the shade phase is easier to control.",
        "During Fury of the War God, stop bear-shades from reaching Zul'jarra in the middle.",
        "Soaking or blocking shades triggers Echoing Fury damage, so use defensives as needed.",
        "During Overwhelming Onslaught, stand behind Nalorakk's shield to avoid lethal damage.",
      },
      tank = {
        "After Overwhelming Onslaught, soak Forceful Slam.",
        "Position Nalorakk to make Echoing Maul placement and shield access reliable.",
      },
      healer = {
        "Keep the party healthy during Overwhelming Onslaught's heavy group-wide damage.",
        "Spot-heal players soaking shades during Fury of the War God.",
      },
      dps = {
        "Help intercept shades during Fury of the War God without overloading one player.",
        "Use defensives when blocking shades or handling Echoing Maul.",
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
