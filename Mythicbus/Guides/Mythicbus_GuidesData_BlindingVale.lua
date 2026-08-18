-- Mythicbus_GuidesData_BlindingVale.lua
-- Boss-only mechanics: The Blinding Vale (no loot). Data file.

local ADDON, NS = ...

local dungeonKey = "BLINDING_VALE"

local dungeonData = {
  name = "The Blinding Vale",
  bosses = {
    {
      name = "Lightblossom Trinity",
      all = {
        "Soak Lightblossoms so Lightblossom Beam does not give them Light-Gorged stacks.",
        "Avoid Fertile Loam green swirlies.",
        "Interrupt Kezkitt's Light Bolt when possible.",
        "Keep the bosses stacked whenever mechanics allow so the group can cleave efficiently.",
      },
      tank = {
        "Use active mitigation during Bedrock Slam.",
        "Position the bosses together without dragging the group through Fertile Loam.",
      },
      healer = {
        "Watch Thornblade bleed targets and stabilize them quickly.",
        "Use healing cooldowns for Bedrock Slam and the party-wide damage over time that follows.",
      },
      dps = {
        "Help soak Lightblossoms promptly and keep cleave damage on stacked bosses.",
        "Interrupt Light Bolt casts when your kick is available.",
      },
    },
    {
      name = "Ikuzz the Light Hunter",
      all = {
        "Avoid Bloodthorn Roots; if rooted, kill them or use root-removal abilities.",
        "Mind the arena edges when Verdant Stomp knocks players back.",
        "If targeted by Bloodthirsty Gaze, keep distance and guide Ikuzz through roots to clear space.",
        "Use personal defensives for Thorncaller Roar.",
      },
      tank = {
        "Keep Ikuzz close enough to active Bloodthorn Roots so the party can cleave them down.",
        "Maintain positioning that leaves room for Bloodthirsty Gaze kiting.",
      },
      healer = {
        "Save major healing cooldowns for Lightcrazed Frenzy after 50%, especially when Thorncaller Roar overlaps.",
      },
      dps = {
        "Clear Bloodthorn Roots quickly when they trap players or clutter kiting paths.",
        "Use movement and crowd control to survive Bloodthirsty Gaze without letting Ikuzz reach you.",
      },
    },
    {
      name = "Lightwarden Ruia",
      note = "Ruia swaps between Moonkin and Bear forms; at 40%, Spirits of the Vale causes rapid spell casts until death.",
      all = {
        "Spread for Pulverizing Strikes cone targets.",
        "Move Lightfire expirations away from the group so the silence beams have safe lanes.",
        "Interrupt Warden's Wrath during Moonkin form when possible.",
        "Avoid Lightfall ground circles.",
      },
      tank = {
        "Expect heavier melee pressure during Bear form from Mangling Claws.",
        "Keep Ruia positioned so Lightfire beams and Lightfall do not trap the group.",
      },
      healer = {
        "Heal Grievous Thrash targets to full to remove the stacking bleed.",
        "Prepare extra throughput after 40% when Spirits of the Vale accelerates mechanics.",
      },
      dps = {
        "Save interrupts for Warden's Wrath and keep spread discipline for Pulverizing Strikes.",
        "Commit damage after 40% to shorten the Spirits of the Vale burn.",
      },
    },
    {
      name = "Ziekket",
      all = {
        "Kill Awaken the Lightbloom lashers quickly and interrupt or stop their casts.",
        "If targeted by Concentrated Lightbeam, aim it through dead lashers so they do not respawn.",
        "Move out of Lightsap after using Concentrated Lightbeam on lasher corpses.",
        "Soak Lightbloom's Essence orbs before they reach Ziekket, but manage stacks carefully.",
      },
      tank = {
        "Use active mitigation during Thornspike.",
        "Group Lashers quickly so the party can cleave and control them.",
      },
      healer = {
        "Use healing cooldowns as needed for Oozing Xylem's constant party damage.",
        "Spot-heal players carrying high Lightbloom's Essence stacks.",
      },
      dps = {
        "Prioritize Lashers and use stops to prevent dangerous casts.",
        "Coordinate Concentrated Lightbeam paths to clear corpses without clipping players.",
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
