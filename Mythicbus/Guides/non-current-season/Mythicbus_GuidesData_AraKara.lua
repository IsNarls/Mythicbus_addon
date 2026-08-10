-- Mythicbus_GuidesData_AraKara.lua
-- Boss-only mechanics: Ara-Kara, City of Echoes (no loot). Library/data file.

local ADDON, NS = ...

local dungeonKey = "ARA_KARA_CITY_OF_ECHOES"

local dungeonData = {
  name = "Ara-Kara, City of Echoes",
  bosses = {
    {
      name = "Mini-bosses (Ixin / Nakt / Atik)",
      note = "Mandatory: defeat all three to unlock Avanoxx.",
      all = {
        "Ixin: interrupt Horrifying Shrill (party fear).",
        "Ixin: dodge Web Spray frontal; use spare kicks on Web Bolt.",
        "Nakt: use defensives for Call of the Brood (group-wide AoE).",
        "Nakt: dodge Web Spray frontal; interrupt Web Bolt when possible.",
        "Atik: avoid Poisonous Cloud ground; interrupt Poison Bolt.",
        "Atik: dodge Web Spray frontal.",
      },
      tank = {
        "Keep all frontals faced away from the party; give your group a clean safe lane.",
      },
      healer = {
        "If Call of the Brood overlaps other damage, spot-top aggressively; don’t let the group sit low.",
      },
      dps = {
        "Kick priority: Horrifying Shrill / Poison Bolt (then Web Bolt).",
        "Use stuns to cover missed kicks; don’t tunnel through frontals.",
      },
    },

    {
      name = "Avanoxx",
      all = {
        "Use defensives during Alerting Shrill (group AoE).",
        "Kill Starved Crawlers fast (they fixate). If they reach Avanoxx, she consumes them and gains Insatiable stacks (often lethal).",
        "During Gossamer Onslaught: dodge swirlies and avoid Vile Webbing ground; too many web stacks can trigger Web Wrap (dispellable).",
      },
      tank = {
        "Use major defensives for Voracious Bite (tank buster).",
        "Position Avanoxx away from Starved Crawlers; help control crawlers with CC if they’re close to reaching her.",
      },
      healer = {
        "Plan throughput cooldowns around Alerting Shrill.",
        "During Gossamer Onslaught, triage quickly if anyone stands in Vile Webbing or gets wrapped.",
      },
      dps = {
        "Hard swap to Starved Crawlers; stuns/knockbacks/roots are worth using to prevent a consume.",
      },
    },

    {
      name = "Anub'zekt",
      all = {
        "Avoid Ceaseless Swarm swirlies.",
        "Infestation: use defensives; when the DoT ends it drops a Ceaseless Swarm swirlie—move out immediately.",
        "Interrupt Silken Restraints (from Bloodstained Webmages); cleave webmages down with boss.",
        "If targeted by Burrow Charge, create space—then dodge the follow-up Impale frontal.",
        "At 100 energy: Eye of the Swarm—stay in the intended safe area to avoid extra damage.",
      },
      tank = {
        "Always face Impale away from the group.",
        "Keep webmages/adds pulled into the boss for efficient cleave and stops.",
      },
      healer = {
        "Spot-heal Infestation targets; expect ticking pressure + movement.",
        "Eye of the Swarm can punish mistakes—be ready to stabilize anyone taking extra ticks.",
      },
      dps = {
        "Kick Silken Restraints immediately; coordinate stops if multiple webmages cast at once.",
      },
    },

    {
      name = "Ki'katal the Harvester",
      all = {
        "Dodge Erupting Webs swirlies.",
        "Cultivated Poisons: dispels help, but dispelling triggers dangerous poison waves—coordinate dispels and defensives.",
        "Damage Bloodworkers so they drop Grasping Blood (needed for the 100-energy mechanic).",
        "At 100 energy: Singularity—stand on Grasping Blood to get rooted away from the blast (or use immunity). Afterward, break roots with CC (you don’t have to DPS the root).",
      },
      tank = {
        "Bring Black Blood adds into the boss for cleave; avoid dragging them away from the group’s damage.",
      },
      healer = {
        "Heavy spot-healing for Cultivated Poisons targets; dispel only when the group is ready for the wave (or has defensives).",
      },
      dps = {
        "Help prep enough Grasping Blood drops before Singularity windows.",
        "Save a stop/CC to help break roots if your group is low on answers.",
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
