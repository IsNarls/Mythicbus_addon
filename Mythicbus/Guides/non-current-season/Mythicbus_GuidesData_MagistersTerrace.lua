-- Mythicbus_GuidesData_MagistersTerrace.lua
-- Boss-only mechanics: Magister's Terrace (no loot). Data file.

local ADDON, NS = ...

local dungeonKey = "MAGISTERS_TERRACE"

local dungeonData = {
  name = "Magister's Terrace",
  bosses = {
    {
      name = "Selin Fireheart",
      all = {
        "Stop Fel Explosion whenever possible.",
        "Destroy Fel Crystals quickly to reduce Selin's mana recovery.",
        "Use defensives during Drain Mana windows if casts overlap or interrupts are missed.",
      },
      tank = {
        "Keep Selin positioned so the group can swap to nearby crystals without overmoving.",
      },
      healer = {
        "Prepare for spikes if Fel Explosion is not interrupted.",
      },
      dps = {
        "Hard swap to crystals and maintain kick order on Selin.",
      },
    },
    {
      name = "Vexallus",
      all = {
        "Use defensives during Arcane Shock pressure.",
        "Kill Pure Energy adds quickly; if they reach players they increase incoming damage.",
        "At low health, expect sustained group damage from Overload-style end phase pressure.",
      },
      tank = {
        "Hold boss centered to keep add spawns visible and simplify pickup/cleave paths.",
      },
      healer = {
        "Ramp healing for late-fight damage as Vexallus intensifies.",
      },
      dps = {
        "Swap instantly to Pure Energy and preserve personal defensives for execute phase.",
      },
    },
    {
      name = "Priestess Delrissa",
      note = "Priority-control encounter with multiple adds.",
      all = {
        "Assign crowd control and interrupt targets before pull.",
        "Focus dangerous caster/healer adds first.",
        "Use stops on high-impact casts and avoid overlapping enemy cooldown windows.",
      },
      tank = {
        "Control melee adds and keep pressure off healer by peeling priority threats.",
      },
      healer = {
        "Expect chaotic incoming damage; use externals proactively on focused targets.",
      },
      dps = {
        "Follow kill order and save interrupts/stops for assigned targets.",
      },
    },
    {
      name = "Kael'thas Sunstrider",
      all = {
        "Interrupt Fireball whenever possible.",
        "Move out of Flame Strike immediately.",
        "Use defensives for Phoenix/Fire damage overlaps and kill Phoenix eggs quickly.",
        "Spread for Pyroblast setup and coordinate emergency stops if kicks are unavailable.",
      },
      tank = {
        "Face Kael'thas safely and reposition to keep Flame Strike out of melee clumps.",
      },
      healer = {
        "Plan cooldowns for Phoenix + Pyroblast overlap windows.",
      },
      dps = {
        "Kick Fireball, clear Phoenix eggs, and avoid delaying movement out of Flame Strike.",
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
