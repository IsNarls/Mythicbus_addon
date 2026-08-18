-- Mythicbus_GuidesData_MurderRow.lua
-- Boss-only mechanics: Murder Row (no loot). Data file.

local ADDON, NS = ...

local dungeonKey = "MURDER_ROW"

local dungeonData = {
  name = "Murder Row",
  bosses = {
    {
      name = "Kystia Manaheart",
      all = {
        "Focus Nibbles to 20% to trigger Chaotic Burst; Kystia takes heavily reduced damage before this phase.",
        "Use major offensive and defensive cooldowns during Chaotic Burst, when Kystia takes increased damage but pulses party damage.",
        "Dodge Fel Spray frontal.",
        "Run away from Fel Nova when Kystia teleports to a player and begins casting.",
        "Interrupt, stun, or otherwise stop Mirror Images when they spawn.",
      },
      tank = {
        "Keep Kystia Manaheart and Nibbles stacked so the party can cleave both targets.",
      },
      healer = {
        "Dispel Corroding Spittle from Nibbles quickly.",
        "Use major healing cooldowns during each Chaotic Burst phase.",
      },
      dps = {
        "Prioritize pushing Nibbles to 20%, then burst Kystia during Chaotic Burst.",
        "Use stops on Mirror Images before their casts get out of control.",
      },
    },
    {
      name = "Zaen Bladesorrow",
      all = {
        "Hide behind Forbidden Freight before Murder in a Row finishes or you risk lethal damage and a heavy bleed.",
        "Use Fire Bomb to remove Volatile Barrels and prevent Fel-Infused Freight stacks from building.",
        "Do not let multiple Volatile Barrels remain active; stacked Fel-Infused Freight can overwhelm healing.",
        "Keep a clear path to safe Forbidden Freight before each Murder in a Row cast.",
      },
      tank = {
        "Use active mitigation for Envenom and watch the follow-up Heartstop Poison effect.",
        "Position Zaen so the group can reach Forbidden Freight without crossing hazards.",
      },
      healer = {
        "Top the party during Killing Spree.",
        "Use healing cooldowns during Fel-Infused Freight, especially if multiple stacks are active.",
      },
      dps = {
        "Handle Fire Bomb assignments quickly to clear Volatile Barrels.",
        "Prioritize survival and line-of-sight timing during Murder in a Row.",
      },
    },
    {
      name = "Xathuux the Annihilator",
      all = {
        "If targeted by Axe Toss, move close to Xathuux so the party can cleave the Axe.",
        "Kill the Axe quickly to prevent stacking Fel Lightning damage.",
        "Use defensives before Infernal Crush impacts.",
        "Avoid Burning Steps on the ground.",
      },
      tank = {
        "Use active mitigation for Legion Strike.",
        "Move Xathuux near the Axe quickly so the group can cleave both targets.",
      },
      healer = {
        "Use major healing cooldowns before Infernal Crush.",
        "Watch the group if Fel Lightning stacks build from a slow Axe kill.",
      },
      dps = {
        "Swap to the Axe immediately and kill it before Fel Lightning stacks become dangerous.",
        "Keep Burning Steps placement controlled while maintaining uptime.",
      },
    },
    {
      name = "Lithiel Cinderfury",
      all = {
        "Interrupt Chaos Bolt.",
        "Focus the Furious Vilefiend when Lithiel casts Summon Vilefiend.",
        "During Fingers of Gul'dan, use interrupts, stuns, and other stops on Wild Imps.",
        "Use Demonic Gateway to bypass Malefic Wave.",
        "Avoid the large Infernal; getting hit can be lethal.",
      },
      tank = {
        "Never get hit by the large Infernal NPC.",
        "Position Lithiel so the group can access Demonic Gateway for Malefic Wave.",
      },
      healer = {
        "Save players hit by Malefic Wave; it leaves a dangerous DoT.",
        "Stabilize the group when add casts or Infernal movement force heavy disruption.",
      },
      dps = {
        "Prioritize Furious Vilefiend and stop Wild Imp casts during Fingers of Gul'dan.",
        "Maintain interrupts on Chaos Bolt without missing Malefic Wave gateway timing.",
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
