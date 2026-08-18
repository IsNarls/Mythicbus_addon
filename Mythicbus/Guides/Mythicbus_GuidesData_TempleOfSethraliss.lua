-- Mythicbus_GuidesData_TempleOfSethraliss.lua
-- Boss-only mechanics: Temple of Sethraliss (no loot). Data file.

local ADDON, NS = ...

local dungeonKey = "TEMPLE_OF_SETHRALISS"

local dungeonData = {
  name = "Temple of Sethraliss",
  bosses = {
    {
      name = "Adderis and Aspix",
      all = {
        "Watch Storm Blessed; swap to the boss that is not shielded and immune.",
        "Soak Thunder and Lightning as a group so the damage is split across more players.",
        "Place Tempest Winds near the planned safe area without blocking movement.",
        "During Gale Force, avoid being knocked into mobs or existing Tempest Winds.",
      },
      tank = {
        "Use active mitigation for each Overload cast.",
        "Keep positioning stable so the party can soak and recover from Gale Force safely.",
      },
      healer = {
        "Focus-heal Gust targets.",
        "Prepare spot healing after Thunder and Lightning soaks.",
      },
      dps = {
        "Swap promptly when Storm Blessed changes targets.",
        "Help with Thunder and Lightning soaks and keep Tempest Winds placement clean.",
      },
    },
    {
      name = "Merektha",
      all = {
        "Use interrupts, stuns, and other stops to remove A Knot of Snakes quickly.",
        "Kill all snakes after A Knot of Snakes.",
        "Dodge Lingering Storm puddles from Thunder Spit.",
        "During Hatch, cleave the Storm Serpent first because it has much higher health than Toxic Vipers.",
        "Dodge Burrow charge; it can be lethal on high keys.",
      },
      tank = {
        "Use active mitigation for Lightning Bite.",
        "Stack snakes after A Knot of Snakes so the group can cleave them efficiently.",
      },
      healer = {
        "Use major healing cooldowns during Serpentstorm.",
        "Watch the party during snake waves and Lingering Storm movement.",
      },
      dps = {
        "Prioritize snake control and focus the Storm Serpent during Hatch.",
        "Save stops for A Knot of Snakes and avoid Burrow paths.",
      },
    },
    {
      name = "Galvazzt",
      all = {
        "Soak Lightning Spires to prevent Galvazzt from gaining Galvanized stacks.",
        "Rotate defensives for pylon soaks and use the tank for extra coverage.",
        "Use defensives or health potions if low before Induction.",
        "Move out of Induction Field after Induction resolves.",
      },
      tank = {
        "Soak extra pylons when possible, since you are the most durable player.",
        "Keep the boss positioned so all three Lightning Spires are reachable.",
      },
      healer = {
        "Spot-heal players soaking Lightning Spires.",
        "Top the party before each Induction AoE blast.",
      },
      dps = {
        "Help cover Lightning Spire soaks and rotate defensives for repeated hits.",
        "Avoid standing in Induction Field after each blast.",
      },
    },
    {
      name = "Avatar of Sethraliss",
      all = {
        "Kill Essence Defilers quickly so the party can heal Avatar of Sethraliss.",
        "Cleave secondary adds, but do not delay Essence Defiler deaths.",
        "After a Corrupted Guardian dies, soak the follow-up puddles to prevent a wipe.",
        "Interrupt Twisted Hexxer's Flame Shock.",
        "Control Faithless Tormentors so they do not reach the healer and cast Shadowlash.",
      },
      tank = {
        "Pick up Corrupted Guardians quickly and use mitigation for Tainted Strike.",
        "Place Corrupted Guardians near a corner before they die so Unstable Corruption puddles are easier to manage.",
      },
      healer = {
        "Manage Latent Hex carefully; removal or expiration triggers heavy Hex Muck party damage.",
        "If fixated by Faithless Tormentors, kite away from them.",
        "Heal Avatar of Sethraliss once Essence Defilers are dead.",
      },
      dps = {
        "Hard-swap to Essence Defilers and interrupt Flame Shock.",
        "Use crowd control on Faithless Tormentors and help soak Corrupted Guardian puddles.",
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
