-- Mythicbus_GuidesData_HallsOfAtonement_TWW.lua
-- Boss-only mechanics: Halls of Atonement (TWW / Season 3). Data file (no loot).
-- Requires Mythicbus_GuidesDB.lua (NS.MBUS_GuidesDB) somewhere in your addon load order.

local ADDON, NS = ...

local dungeonKey = "HALLS_OF_ATONEMENT_TWW"

local dungeonData = {
  name = "Halls of Atonement",
  bosses = {
    {
      name = "Halkias, the Sin-Stained Goliath",
      all = {
        "Avoid Heave Debris ground impact; stay out of the follow-up Glass Shards ground effect.",
        "Never leave the Light of Atonement radius or you will be feared by Sinlight Visions.",
        "Dodge Refracted Sinlight beams.",
      },
      tank = {
        "Use active mitigation for Crumbling Slam; avoid clipping teammates with it.",
      },
      healer = {
        "Top the party after each Crumbling Slam (it also deals group-wide damage).",
      },
      dps = {
        "Stay inside Light of Atonement at all times; focus on dodging beams and ground.",
      },
    },

    {
      name = "Echelon",
      all = {
        "Avoid Blood Torrent ground effect.",
        "When Undying Stonefiends spawn, interrupt Villainous Bolt and kill them quickly.",
        "If you get Flesh to Stone (not dispellable), you have limited time before you’re stunned: pre-defensive and use Stone Shattering Leap positioning to land on Undying Stonefiends to destroy them (or they will respawn).",
      },
      tank = {
        "Do your best to place the boss on top of any remaining Undying Stonefiends.",
      },
      healer = {
        "Spot-heal players with Flesh to Stone.",
        "Keep the party healthy as Undying Stonefiends die (Volatile Transformation does group-wide damage on death).",
      },
      dps = {
        "Prioritize kicks on Villainous Bolt and help delete Undying Stonefiends.",
        "If you get Flesh to Stone, commit to a good leap that destroys Stonefiends.",
      },
    },

    {
      name = "High Adjudicator Aleez",
      all = {
        "If Ghastly Parishioner fixates you, bring it to a Vessel of Atonement to capture it; the longer it lives, the more Pulse from Beyond damage your party takes (stacking).",
        "Interrupt Anima Bolt.",
        "Avoid Anima Fountain ground effects.",
        "Use defensives if you get Unstable Anima, especially when combined with Ghastly Parishioner pressure.",
      },
      tank = {
        "Pre-position the boss near a Vessel of Atonement so melee can keep uptime while the fixated player captures the spirit.",
      },
      healer = {
        "Use healing cooldowns during Pulse from Beyond, especially at high stacks.",
        "Dispel Unstable Anima as often as you can.",
      },
      dps = {
        "Help interrupts on Anima Bolt; don’t stand in Anima Fountain.",
        "If you’re fixated, run the spirit into a Vessel of Atonement quickly.",
      },
    },

    {
      name = "Lord Chamberlain",
      all = {
        "Avoid being hit by statues during Telekinetic Toss.",
        "Dodge the Unleashed Suffering frontal cone.",
        "Out-range Erupting Torment ground visual.",
        "Use defensives during Telekinetic Repulsion (group-wide damage) and make sure someone soaks the follow-up Ritual of Woe beam so it doesn’t channel to a statue (to avoid further group-wide damage).",
      },
      tank = {
        "Soak as many Ritual of Woe beams as you can (you’re the most durable party member).",
      },
      healer = {
        "Spot-heal Stigma of Pride targets.",
        "Use healing cooldowns during Ritual of Woe (casts twice: at 70% HP and 40% HP).",
      },
      dps = {
        "Be ready to soak Ritual of Woe beams if assigned (especially with defensives/immunities).",
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
