-- Mythicbus_GuidesData_AlgetharAcademy.lua
-- Boss-only mechanics: Algeth'ar Academy (no loot). Data file.

local ADDON, NS = ...

local dungeonKey = "ALGETHAR_ACADEMY"

local dungeonData = {
  name = "Algeth'ar Academy",
  bosses = {
    {
      name = "Overgrown Ancient",
      all = {
        "Stack and move together during Germinate so awakened lashers can be cleaved efficiently.",
        "Dodge Branch Out.",
        "Interrupt Ancient Branch Healing Touch; time Branch death so nearby lashers do not get full healed by Abundance.",
        "Prepare defensives for Burst Forth damage windows.",
      },
      tank = {
        "Use active mitigation for Barkbreaker.",
        "Taunt Ancient Branch immediately and collect awakened Hungry Lashers quickly after Burst Forth.",
      },
      healer = {
        "Top party before Burst Forth, especially with Splinterbark bleed active.",
        "Use throughput cooldowns when Burst Forth overlaps active lashers.",
      },
      dps = {
        "Swap and kick Ancient Branch quickly; then finish lashers before Abundance timing punishes the group.",
      },
    },
    {
      name = "Crawth",
      all = {
        "Dodge Overpowering Gust frontal.",
        "At 75% and 45%, score goals and plan arena space around long-term hazards.",
        "Searing Blaze goal triggers Firestorm and 75% boss damage taken, but adds permanent fire motes.",
        "Rushing Winds goal gives haste but adds persistent cyclones.",
        "Use defensives during Deafening Screech.",
      },
      tank = {
        "Use active mitigation for Savage Peck.",
      },
      healer = {
        "Top party for every Deafening Screech.",
        "Searing Blaze creates constant Blistering Fire pressure; reserve cooldowns for overlap moments.",
      },
      dps = {
        "Coordinate goal order for safe space first, then push damage windows during Firestorm vulnerability.",
      },
    },
    {
      name = "Vexamus",
      all = {
        "Soak Arcane Orbs so Vexamus does not gain extra energy.",
        "Manage Oversurge stacks while soaking; rotate soakers instead of overcommitting one player.",
        "Use defensives for Arcane Fissure and dodge follow-up ground pools.",
        "Avoid Corrupted Mana pools from Mana Bombs.",
      },
      tank = {
        "Soak multiple Arcane Orbs when needed with active mitigation.",
        "Face Arcane Expulsion away from party.",
      },
      healer = {
        "Mana Bombs apply heavy party DoT pressure; stabilize targets before Arcane Fissure.",
        "Use major healing cooldowns on Arcane Fissure casts.",
      },
      dps = {
        "Help with orb soaks and keep movement clean after Arcane Fissure knockback.",
      },
    },
    {
      name = "Echo of Doragosa",
      all = {
        "Use defensives when targeted by Energy Bomb.",
        "Run away from Power Vacuum.",
        "Manage Overwhelming Power stacks for haste, but do not greed to 3 stacks at bad times and spawn extra Arcane Rifts.",
        "As fight space shrinks, movement discipline matters more than raw damage.",
      },
      tank = {
        "Tank in a corner and preserve room to control Arcane Rift spawns.",
        "Use active mitigation for Astral Blast.",
      },
      healer = {
        "Spot-heal Energy Bomb targets immediately.",
        "Be ready for Arcane Missiles random-target spikes.",
      },
      dps = {
        "Optimize stacks without forcing extra Arcane Rift spawns; prioritize safe execution in late fight.",
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
