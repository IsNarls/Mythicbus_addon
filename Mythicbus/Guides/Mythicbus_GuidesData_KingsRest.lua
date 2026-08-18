-- Mythicbus_GuidesData_KingsRest.lua
-- Boss-only mechanics: King's Rest (no loot). Data file.

local ADDON, NS = ...

local dungeonKey = "KINGS_REST"

local dungeonData = {
  name = "King's Rest",
  bosses = {
    {
      name = "The Golden Serpent",
      all = {
        "Use defensives during Serpentine Gust channels because they deal group-wide damage.",
        "Spit Gold targets should drop debuffs near each other in a controlled area for cleaner add management.",
        "Avoid Molten Gold left behind after Spit Gold.",
        "During Lucre's Call, kill every Animated Gold before any reach the boss.",
        "Do not let Animated Gold touch the boss or it gains a large Luster shield and dangerous party damage.",
      },
      tank = {
        "Use active mitigation during Tail Thrash.",
        "Drag the boss away from nearby Animated Golds.",
      },
      healer = {
        "Use healing cooldowns during Serpentine Gust.",
        "Watch the party if Animated Gold movement delays the Lucre's Call cleanup.",
      },
      dps = {
        "Swap quickly to Animated Golds during Lucre's Call.",
        "Place Spit Gold carefully so adds spawn where they can be cleaved and controlled.",
      },
    },
    {
      name = "Mchimba the Embalmer",
      all = {
        "Use defensives during Drain Fluids and self-heal to help recover through Desiccation.",
        "If targeted by Burning Ground, move away from nearby party members.",
        "If Entombed, press the active button to show your coffin location.",
        "Free Entombed players quickly to prevent Open Coffin and Finished Mummy spawns.",
        "Interrupt Wretched Discharge from any Finished Mummy.",
      },
      tank = {
        "Stack Finished Mummies near Mchimba so the group can cleave them down.",
      },
      healer = {
        "Focus-heal Drain Fluids targets.",
        "Stabilize Entombed players quickly after they are freed.",
      },
      dps = {
        "Break Entombed players out fast and interrupt Finished Mummy casts.",
        "Keep Burning Ground placements away from the group.",
      },
    },
    {
      name = "The Council of Tribes",
      all = {
        "Move away from Whirling Axes as they spawn and avoid patrolling axes to prevent heavy bleeds.",
        "Use major defensives if targeted by Kula the Butcher's Severing Axe.",
        "Stack together when a player is targeted by Barrel Through.",
        "When Zanazal casts Call of the Elements, kill Explosive Totem before its cast finishes.",
        "Interrupt Poison Nova from Explosive Totem.",
      },
      tank = {
        "When Aka'ali casts Debilitating Backhand, kite away until the debuff expires.",
        "Move Zanazal near Explosive Totem and other priority totems so the group can cleave.",
      },
      healer = {
        "Spot-heal Severing Axe bleed targets.",
        "React quickly to Arc Lightning damage from Zanazal.",
      },
      dps = {
        "Hard-swap to Explosive Totem during Call of the Elements.",
        "Keep interrupts and stops ready for Poison Nova and other dangerous totem casts.",
      },
    },
    {
      name = "Dazar, The First King",
      all = {
        "Use defensives during Gilded Destruction, the highest damage event in the fight.",
        "Leave space between players for Aerial Smash.",
        "Sidestep Impaling Spear.",
        "Interrupt Reban's Deathly Roar.",
        "Sidestep T'zala's Quaking Leap.",
      },
      tank = {
        "Use active mitigation during Blade Combo.",
        "Plan cooldowns or ask for externals when T'zala's Savage Maul overlaps other tank busters.",
      },
      healer = {
        "Use major healing cooldowns during Gilded Destruction.",
        "Watch tank health during Blade Combo and Savage Maul overlap windows.",
      },
      dps = {
        "Interrupt Deathly Roar and keep movement clean around spear and leap mechanics.",
        "Hold defensives for Gilded Destruction if healing cooldown coverage is thin.",
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
