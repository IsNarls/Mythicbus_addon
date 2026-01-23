-- Mythicbus_GuidesData_Dawnbreaker.lua
-- Boss-only mechanics: The Dawnbreaker (no loot). Data file.
-- Requires Mythicbus_GuidesDB.lua (NS.MBUS_GuidesDB) to be loaded somewhere in your addon.

local ADDON, NS = ...

local dungeonKey = "THE_DAWNBREAKER"

local dungeonData = {
  name = "The Dawnbreaker",
  bosses = {
    {
      name = "Mini-bosses (Vis'coxria / Iken'tak / Ixkreten)",
      note = "Defeat all three before Anub'ikkaj (reduces/avoids their Empowered Might buff on the boss).",
      all = {
        "Ixkreten the Unbreakable: Abyssal Blast hits a random player—use a defensive.",
        "Ixkreten the Unbreakable: run away from Terrifying Slam.",
        "Deathscreamer Iken'tak: Abyssal Blast hits a random player—use a defensive.",
        "Deathscreamer Iken'tak: if targeted by Dark Orb, aim it so it travels the farthest; closer explosions deal more damage.",
        "Ascendant Vis'coxria: casts Abyssal Blast and also Shadowy Decay (group AoE).",
      },
      tank = {
        "Help keep the area clear so targeted players can aim Dark Orb for maximum travel distance.",
      },
      healer = {
        "Expect random-target Abyssal Blast damage; keep the group stable through Shadowy Decay pulses.",
      },
      dps = {
        "If you get Dark Orb, aim it for maximum distance before it collides/explodes.",
        "Respect Terrifying Slam—don’t greed casts.",
      },
    },

    {
      name = "Speaker Shadowcrown",
      all = {
        "Interrupt as many Shadow Bolts as possible.",
        "Dodge Obsidian Beam—getting hit is likely fatal.",
        "If you get Shadow Shroud (absorb), use defensives; once removed, move out of Collapsing Night ground.",
        "At 50% HP and 5% HP: Darkness Comes—use Dragonflying to leave the ship and fly to a nearby Radiant Light to avoid the explosion, then return.",
      },
      tank = {
        "Move the boss away from Collapsing Night puddles so the party has room to dodge Obsidian Beam.",
      },
      healer = {
        "Boss targets a player with Burning Shadows; on removal it applies Shadow Shroud to most of the party—quickly top everyone.",
      },
      dps = {
        "Help kick Shadow Bolts; don’t tunnel—Obsidian Beam is the main lethal check.",
        "During Darkness Comes, mount up immediately and grab Radiant Light before returning to DPS.",
      },
    },

    {
      name = "Anub'ikkaj",
      all = {
        "If targeted by Dark Orb: position so it travels as far as possible before colliding; getting hit will likely kill you (and can apply Dark Scars).",
        "Out-range Terrifying Slam.",
        "Use defensives during Shadowy Decay pulsating AoE.",
      },
      tank = {
        "On Animate Shadows: collect Abyssal Blast droplets and stack them under the boss for cleave.",
        "Use crowd control to stop Congealed Darkness casts from the spawned shadows.",
      },
      healer = {
        "Use major healing cooldowns during Shadowy Decay (whole party taking damage).",
      },
      dps = {
        "If you’re the Dark Orb target, aim it for maximum distance before it collides.",
        "Help stop/CC Congealed Darkness during Animate Shadows; don’t eat Terrifying Slam.",
      },
    },

    {
      name = "Rasha'nan",
      note = "2 phases with Dragonflying: collect Light Fragments to extend Radiant Light and avoid Encroaching Shadows; interrupt Acidic Eruption on the final platform before continuing to Phase 2.",
      all = {
        "Phase 1: prioritize the Arathi Bombs event—pick up Sparking Arathi Bombs and use the special action to Throw Arathi Bomb (each hit chunks boss health to push toward Phase 2).",
        "Sidestep Expel Webs frontal.",
        "Both phases: Rolling Acid targets a random player—aim the wave away from teammates (follow the overhead indicator) to prevent Corrosion splashing the group; you’ll take Acidic Stupor instead.",
        "Phase 2: two players can be targeted by Spinneret's Strands—escape Sticky Webs quickly; lingering in webs increases damage. Escaping triggers Spinneret's Websnap follow-up.",
      },
      tank = {
        "Phase 2: use active mitigation for each Tacky Burst tank buster.",
      },
      healer = {
        "Both phases: plan healing cooldowns for Erosive Spray (group-wide damage + 3 undispellable Lingering Erosion stacks on everyone).",
        "Phase 2: spot-heal players hit by Spinneret's Strands.",
      },
      dps = {
        "Phase 1: bombs are a priority objective—assist bomb pickups/throws whenever possible to push the phase.",
        "If targeted by Rolling Acid, aim it away from the group (use the overhead direction cue).",
        "If you get Spinneret's Strands, move to break out of Sticky Webs ASAP to reduce ticking damage.",
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
