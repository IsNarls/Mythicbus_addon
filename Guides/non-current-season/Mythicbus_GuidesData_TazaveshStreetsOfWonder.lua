-- Mythicbus_GuidesData_TazaveshStreetsOfWonder.lua
-- Boss-only mechanics: Tazavesh: Streets of Wonder (no loot). Data file.
-- Requires Mythicbus_GuidesDB.lua (NS.MBUS_GuidesDB) somewhere in your addon load order.

local ADDON, NS = ...

local dungeonKey = "TAZAVESH_STREETS_OF_WONDER"

local dungeonData = {
  name = "Tazavesh: Streets of Wonder",
  bosses = {
    {
      name = "Zo'phex the Sentinel",
      all = {
        "Avoid Charged Slash.",
        "During Impound Contraband, pick up your weapon to gain Vigor (25% haste for 12 sec).",
        "Avoid Armed Security ground effects.",
        "Interrogation: boss fixates a random player (often DPS) and traps them in a Containment Cell; use immunity right before the cast to avoid it, otherwise use defensives and be far so the group can free you before the boss reaches you.",
      },
      tank = {
        "Use active mitigation during Fully Armed and Charged Slash.",
      },
      healer = {
        "Spot-heal the player trapped in the Containment Cell.",
        "Top the party before each Impound Contraband cast.",
      },
      dps = {
        "If you get Interrogation, create distance and pre-defensive so your team can break the cell before Zo'phex reaches you.",
        "Pick up your weapon during Impound Contraband for the Vigor haste buff.",
      },
    },

    {
      name = "The Grand Menagerie",
      note = "Timeline-driven: if you fall behind you may overlap bosses; consider Bloodlust if you’re behind.",
      all = {
        "Alcruux: juggle Gluttonous Feast correctly (it jumps to the nearest ally when it expires); you want this on DPS players.",
        "Achillite: Venting Protocol releases Volatile Anima; collecting it grants Devoured Anima stacks (damage buff) to speed the fight up.",
        "Grip of Hunger: use movement speed to avoid the pull ground visual, and dodge the follow-up Grand Consumption.",
        "Venza Goldfuse: run away from Whirling Annihilation (center is lethal).",
        "Chains of Damnation: break/free the fixated person; Freedom/Tiger’s Lust-style effects can help.",
      },
      tank = {
        "Tank Achillite in a corner to make soaking Volatile Anima orbs easier for the group.",
        "Use active mitigation during Achillite’s Flagellation Protocol.",
      },
      healer = {
        "Dispel Achillite’s Purification Protocol from one target; the other debuff must be spot-healed continuously (dangerous detonation).",
      },
      dps = {
        "Help ensure Gluttonous Feast ends up on DPS (positioning matters since it jumps to nearest on expiry).",
        "Grab Volatile Anima for Devoured Anima stacks when safe to accelerate the encounter.",
        "Be ready to break Chains of Damnation quickly (and assist with Freedom-type tools).",
      },
    },

    {
      name = "Mailroom Mayhem",
      all = {
        "Use defensives during Fan Mail.",
        "Soak as many Hazardous Liquids as possible; soaking gives Alchemical Residue (dispellable). If you don’t soak, the room fills with Spilled Liquids ground.",
        "Soak Money Order together as a party.",
        "Unstable Goods: pick up Throw Package and throw it into an active delivery portal—failing causes Unstable Explosion and will wipe the group.",
      },
      tank = {
        "Soak as many Hazardous Liquids as you can (to prevent the room from filling with Spilled Liquids).",
      },
      healer = {
        "Top players during Fan Mail.",
        "Dispel Alchemical Residue on squishier targets first.",
      },
      dps = {
        "Help soak Hazardous Liquids when safe, and keep Money Order stacked/soaked together.",
        "During Unstable Goods, immediately run the Throw Package into an active delivery portal (no delays).",
      },
    },

    {
      name = "Myza's Oasis",
      note = "Before the boss: everyone picks up an instrument. Collect Jazzy stacks from the ground; at 12 stacks it becomes Up Tempo! (massive buff that speeds the fight).",
      all = {
        "Pre-boss: defeat 2 waves. Use defensives if Brawling Patron throws Throw Drink on you; interrupt Disruptive Patron’s Hyperlight Bolt.",
        "During Crowd Control, stay behind the boss or it will absorb your damage.",
        "Final Warning: use cooldowns to break the shield and interrupt Menacing Shout or your group will likely wipe.",
      },
      tank = {
        "Use active mitigation during Zo’gron’s Security Slam.",
      },
      healer = {
        "Keep people healthy during the pre-boss Throw Drink casts (dangerous pressure).",
      },
      dps = {
        "Collect Jazzy stacks to reach Up Tempo! quickly (major tempo increase).",
        "Stay behind the boss during Crowd Control and commit burst to break Final Warning + interrupt Menacing Shout.",
      },
    },

    {
      name = "So'azmi",
      all = {
        "Use defensives during Phase Slash.",
        "Use Deploy Relocators to avoid Shuri damage (most important mechanic; failing is lethal unless you have an immunity/semi-immunity).",
        "Interrupt Double Technique before it goes off (you can delay the interrupt a bit to maximize boss damage).",
      },
      tank = {
        "Stay close together before each Divide cast to ensure maximum uptime on the boss.",
      },
      healer = {
        "Use healing cooldowns for the Phase Slash bleed effect.",
      },
      dps = {
        "Prioritize correct Deploy Relocators usage for Shuri; don’t greed casts.",
        "Coordinate Double Technique interrupts (delay slightly only if safe).",
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
