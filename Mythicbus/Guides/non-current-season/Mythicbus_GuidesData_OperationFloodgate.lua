-- Mythicbus_GuidesData_OperationFloodgate.lua
-- Boss-only mechanics: Operation: Floodgate (no loot). Data file.
-- Requires Mythicbus_GuidesDB.lua (NS.MBUS_GuidesDB) somewhere in your addon load order.

local ADDON, NS = ...

local dungeonKey = "OPERATION_FLOODGATE"

local dungeonData = {
  name = "Operation: Floodgate",
  bosses = {
    {
      name = "Big M.O.M.M.A.",
      all = {
        "Defeat the 4 Darkfuse Mechadrones and interrupt Maximum Distortion before the boss hits max energy and casts Kill-o-Block Barrier.",
        "Avoid Sonic Boom.",
        "After the 4 Mechadrones die, the boss enters a Jumpstart intermission: it deals party damage and takes 200% increased damage; then it erupts Excessive Electrification patches and resumes.",
      },
      tank = {
        "Position the boss around/near the 4 Darkfuse Mechadrones (for control/uptime) and away from Excessive Electrification ground patches.",
      },
      healer = {
        "Use major healing cooldowns during the Jumpstart intermission (party-wide damage).",
        "If Kill-o-Block Barrier lasts too long, call for externals and commit healing/defensives to survive.",
      },
      dps = {
        "Prioritize interrupts on Maximum Distortion on Mechadrones.",
        "Save burst for Jumpstart intermission (200% increased damage window) when safe.",
      },
    },

    {
      name = "Demolition Duo",
      all = {
        "Defeat both bosses close together to avoid Divided Duo enrage.",
        "Clear bombs using Barreling Charge and/or Kinetic Explosive Gel—if bombs expire, the party takes massive damage and gets Deflagration.",
        "Dodge B.B.B.F.G. frontals from Keeza Quickfuse.",
      },
      tank = {
        "Bront cleaves with Wallop (frontal)—keep it faced away from the party.",
        "Keep both bosses stacked for cleave and to help with even damage.",
      },
      healer = {
        "Dispel Kinetic Explosive Gel on top of a bomb to remove it (the debuff ticks hard—ask the target for a defensive).",
        "If a bomb goes through, use major healing cooldowns for Deflagration damage.",
      },
      dps = {
        "Help keep boss HP even; stop tunneling if one boss is getting too far ahead.",
        "If you can help clear bombs safely (e.g., movement/utility), do it—bomb timers are the wipe condition.",
      },
    },

    {
      name = "Swampface",
      note = "Dungeon gate: you must destroy 5/5 Weapons Stockpiles in the first area to summon this boss.",
      all = {
        "Razorchoke Vines binds 4 players into pairs—stay within 14 yards of your partner or you get pulled together and likely die.",
        "While bound, dodge Mudslide frontal and the waves from Awaken the Swamp without breaking your vine link.",
        "Plan your movement direction before pull so the group rotates cleanly to avoid Mudslide/waves.",
      },
      tank = {
        "Use active mitigation for Sludge Claws.",
      },
      healer = {
        "Use major healing cooldowns through Awaken the Swamp (heavy group-wide damage).",
      },
      dps = {
        "When bound by Razorchoke Vines, focus on clean movement with your partner—don’t panic-sprint and break the 14-yard rule.",
      },
    },

    {
      name = "Geezle Gigazap",
      all = {
        "Use defensives during Turbo Charge and dodge the incoming frontals.",
        "Avoid Dam Rubble ground puddles.",
        "If targeted by Gigazap, stay away from water puddles so you don’t electrify them; this sets up Leaping Sparks handling.",
        "Leaping Sparks: the way to remove it is to lead the spark onto a fresh water puddle.",
      },
      tank = {
        "Use major defensives before each Thunder Punch.",
      },
      healer = {
        "Use major healing cooldowns during Turbo Charge (massive group-wide damage).",
      },
      dps = {
        "If you get Gigazap, kite smartly away from puddles and be ready to path Leaping Sparks into a fresh water puddle.",
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
