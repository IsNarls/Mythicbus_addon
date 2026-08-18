-- Mythicbus_GuidesData_SeatOfTheTriumvirate.lua
-- Boss-only mechanics: Seat of the Triumvirate (no loot). Data file.

local ADDON, NS = ...

local dungeonKey = "SEAT_OF_THE_TRIUMVIRATE"

local dungeonData = {
  name = "Seat of the Triumvirate",
  bosses = {
    {
      name = "Zuraal the Ascended",
      all = {
        "Use defensives during Dark Expulsion.",
        "If targeted by Umbra Shift, move away from group before entering the shadow realm.",
        "In the shadow realm, kill adds quickly and avoid avoidable void effects before returning.",
      },
      tank = {
        "Use active mitigation for Null Palm and maintain control when realm shifts split the group.",
      },
      healer = {
        "Prepare for heavy spot-healing on Umbra Shift targets and stabilize after each return.",
      },
      dps = {
        "Swap immediately to realm adds and prioritize safe movement over greed during shift phases.",
      },
    },
    {
      name = "Saprish",
      note = "Stealth and add-control encounter; clean target calling matters more than raw throughput.",
      all = {
        "Identify and interrupt the real Saprish quickly when decoys appear.",
        "Use defensives during Shadow Volley windows.",
        "Control spawned adds with stuns/knockbacks and avoid getting surrounded.",
      },
      tank = {
        "Gather and kite adds cleanly; avoid overstacking avoidable damage while the group identifies priority targets.",
      },
      healer = {
        "Use throughput cooldowns when add pressure overlaps Shadow Volley.",
      },
      dps = {
        "Hard-swap to priority targets, preserve interrupts for dangerous casts, and clear adds quickly.",
      },
    },
    {
      name = "Viceroy Nezhar",
      all = {
        "Use defensives when targeted by Entropic Force and avoid clipping teammates.",
        "Dodge collapsing void zones and keep movement lanes clear for the group.",
        "Prepare for high damage overlaps as the encounter accelerates.",
      },
      tank = {
        "Use major defensives for tank buster windows and keep boss positioned away from active void zones.",
      },
      healer = {
        "Plan major healing cooldowns for overlap windows and random-target spikes.",
      },
      dps = {
        "Maintain uptime while respecting void placement; preserve personals for forced movement overlaps.",
      },
    },
    {
      name = "L'ura",
      all = {
        "Use defensives for Star Augur-style burst windows and avoid unnecessary void hits.",
        "Dodge expanding void zones and maintain spread/stack discipline as mechanics require.",
        "During add phases, swap quickly and interrupt dangerous casts before returning to boss damage.",
      },
      tank = {
        "Use active mitigation on tank hits and reposition boss to maximize safe space.",
      },
      healer = {
        "Rotate cooldowns through repeated burst windows; this fight has sustained rot plus spike damage.",
      },
      dps = {
        "Prioritize add control and kick assignments, then return to boss with clean positioning.",
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
