-- Mythicbus_GuidesData_AltarOfFangs.lua
-- Boss-only mechanics: Altar of Fangs (no loot). Data file.

local ADDON, NS = ...

local dungeonKey = "ALTAR_OF_FANGS"

local dungeonData = {
  name = "Altar of Fangs",
  bosses = {
    {
      name = "Rav'i",
      all = {
        "During Ssscavenging, use defensives and soak Messy Eater puddles before they explode as Carrion Burst.",
        "Watch Triple Shot targets and avoid unnecessary overlap damage.",
        "Dodge the Regurgitate frontal.",
        "Break the Ssscavenging shield quickly to stop the heavy party damage.",
      },
      tank = {
        "Use active mitigation for Hydrastrike.",
        "Move Rav'i away from Fresh Meat corpses so the boss does not gain Scent of Blood or build a larger Ssscavenging shield.",
      },
      healer = {
        "Top the party before Ravenous Stomp.",
        "Use healing cooldowns during Ssscavenging until the shield breaks.",
      },
      dps = {
        "Prioritize breaking the Ssscavenging shield and help soak Messy Eater puddles.",
      },
    },
    {
      name = "The Writhing Coil",
      all = {
        "Interrupt Toxic Barrage casts so the party avoids Toxic Atrophy.",
        "Dodge Burrowing Charge and the follow-up Venom Jet frontal.",
        "During Death Rattle, drag Vine Grip away from the boss until it breaks and starts the intermission.",
        "During Uncoil, damage the Uncoiled Writhes heavily; their remaining health becomes the boss health after Assimilation.",
        "Avoid the Assimilation impact when the writhes reform into the boss.",
      },
      tank = {
        "Use active mitigation before Tail Scythe.",
        "Stack Uncoiled Writhes together during intermission so the group can cleave efficiently.",
      },
      healer = {
        "Prepare sustained healing for Synchronized Venom party rot.",
        "Stabilize players during intermission while interrupts and crowd control are being handled.",
      },
      dps = {
        "Use interrupts and crowd control on Uncoiled Writhes, especially Spiteful Hunt and Toxic Atrophy casts.",
        "Commit burst cooldowns to the intermission so the reformed boss returns with less health.",
      },
    },
    {
      name = "Zul'jan",
      all = {
        "During Ritual of the Fang, soak the four beams before they reach Zul'jan.",
        "Track Ritual Venom stacks and clear them before they expire by taking Boneslicer or Axegrinder intentionally.",
        "Move out after clearing Ritual Venom, because Bloodletting leaves blood pools behind.",
        "Dodge Axegrinder and avoid standing in blood pools.",
      },
      tank = {
        "Use active mitigation for Chop Down.",
        "Position Zul'jan so Ritual of the Fang beam soaks and Bloodletting pools leave usable space.",
      },
      healer = {
        "Use major healing cooldowns for each Ritual of the Fang channel.",
        "Spot-heal players as they clear Ritual Venom stacks.",
      },
      dps = {
        "Help assign and cover Ritual of the Fang beam soaks.",
        "Clear Ritual Venom deliberately and avoid dropping Bloodletting pools in the group's path.",
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
