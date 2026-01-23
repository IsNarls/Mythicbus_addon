local ADDON, NS = ...
MythicbusDB = MythicbusDB or {
  -- ["Name-Realm"] = { class=, spec=, ilvl=0, rio=0, key={mapID=,level=}, week=, updated= }
  members = {},
  -- ["Name-Realm"] = {
  --   wantRole="T/H/D letters", min=, max=, targetMaps={},
  --   kind="ANY_DUNGEON|ANY_DELVE|DUNGEON|DELVE", delve="Delve Name",
  --   ts=, updated=
  -- }
  queue   = {},
  version = "0.4.3",
}

-- ===== Constants / Utils =====
local PREFIX = "MBUS1"

local function now() return time() end
local function weekID() return tonumber(date("!%G%V")) end
local function me()
  local n, r = UnitFullName("player")
  if not r or r == "" then r = GetRealmName():gsub("%s+","") end
  return n.."-"..r
end

local function serializeMaps(maps)
  if not maps or #maps == 0 then return "" end
  local t = {}
  for _,m in ipairs(maps) do t[#t+1] = tostring(m) end
  return table.concat(t, ",")
end

local function parseCSVints(csv)
  local out = {}
  for m in string.gmatch(csv or "", "%d+") do out[#out+1] = tonumber(m) end
  return out
end

-- ===== Keystone (self only) =====
local function myKey()
  local map = C_MythicPlus and C_MythicPlus.GetOwnedKeystoneMapID and C_MythicPlus.GetOwnedKeystoneMapID() or 0
  local lvl = C_MythicPlus and C_MythicPlus.GetOwnedKeystoneLevel and C_MythicPlus.GetOwnedKeystoneLevel() or 0
  return (map or 0), (lvl or 0)
end

-- ===== Comms helpers =====
C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)

local function myILvl()
  local avg, eq = GetAverageItemLevel()
  local val = math.floor(eq or avg or 0)
  if val < 0 then val = 0 end
  return val
end

-- Broadcast presence/key (HELLO)
local function sendHello()
  local map, lvl = myKey()
  local classToken = select(2, UnitClass("player")) or ""
  local spec = GetSpecialization() and select(2, GetSpecializationInfo(GetSpecialization())) or ""
  local rio = 0 -- optional future integration
  local ilvl = myILvl()
  -- New HELLO includes ilvl (parser handles old shape too)
  local payload = table.concat({"HELLO", me(), classToken, spec, ilvl, rio, map, lvl, weekID(), now()}, ";")
  C_ChatInfo.SendAddonMessage(PREFIX, payload, "GUILD")
end

-- Rebroadcast my queue entry (heartbeat)
local function sendMyQueue()
  local name = me()
  local q = MythicbusDB.queue[name]
  if not q then return end
  -- Include kind/delve so clients retain activity choice (dungeons & delves)
  local payload = table.concat({
    "QUEUE", name, q.wantRole or "A",
    tostring(q.min or 0), tostring(q.max or 0),
    serializeMaps(q.targetMaps), tostring(q.ts or now()),
    q.kind or "", q.delve or ""
  }, ";")
  C_ChatInfo.SendAddonMessage(PREFIX, payload, "GUILD")
  q.updated = now()
end

-- ===== API exposed to UI =====
-- kind ∈ {"ANY_DUNGEON","ANY_DELVE","DUNGEON","DELVE"}; delveName is a string when kind == "DELVE"
function NS.QueueMe(wantRoleLetters, minLvl, maxLvl, mapsCSV, kind, delveName)
  local name = me()
  if not wantRoleLetters or wantRoleLetters == "" then wantRoleLetters = "A" end

  local existing = MythicbusDB.queue[name]
  local firstTs = existing and existing.ts or now()

  MythicbusDB.queue[name] = {
    wantRole   = wantRoleLetters,
    min        = tonumber(minLvl) or 0,
    max        = tonumber(maxLvl) or 0,
    targetMaps = parseCSVints(mapsCSV),
    kind       = kind,          -- may be nil for legacy callers
    delve      = delveName,     -- only meaningful when kind == "DELVE"
    ts         = firstTs,
    updated    = now(),
  }

  -- Initial broadcast of QUEUE (match heartbeat shape)
  local payload = table.concat({
    "QUEUE", name, MythicbusDB.queue[name].wantRole,
    MythicbusDB.queue[name].min, MythicbusDB.queue[name].max,
    serializeMaps(MythicbusDB.queue[name].targetMaps),
    firstTs,
    kind or "",
    delveName or ""
  }, ";")
  C_ChatInfo.SendAddonMessage(PREFIX, payload, "GUILD")
  if NS.RefreshUI then NS.RefreshUI() end
end

function NS.LeaveQueue()
  local name = me()
  MythicbusDB.queue[name] = nil
  C_ChatInfo.SendAddonMessage(PREFIX, "LEAVE;"..name, "GUILD")
  if NS.RefreshUI then NS.RefreshUI() end
end

-- ===== Ingestors =====
local function ingestHELLO(parts)
  -- Old:  HELLO;name;class;spec;rio;map;lvl;week;updated               (#=9)
  -- New:  HELLO;name;class;spec;ilvl;rio;map;lvl;week;updated         (#=10)
  local n = #parts
  local name, class, spec = parts[2], parts[3], parts[4]
  local ilvl, rio, map, lvl, wk, upd

  if n >= 10 then
    ilvl = tonumber(parts[5]) or 0
    rio  = tonumber(parts[6]) or 0
    map  = tonumber(parts[7]) or 0
    lvl  = tonumber(parts[8]) or 0
    wk   = tonumber(parts[9]) or weekID()
    upd  = tonumber(parts[10]) or now()
  else
    rio  = tonumber(parts[5]) or 0
    map  = tonumber(parts[6]) or 0
    lvl  = tonumber(parts[7]) or 0
    wk   = tonumber(parts[8]) or weekID()
    upd  = tonumber(parts[9]) or now()
  end

  local M = MythicbusDB.members[name] or {}
  M.class, M.spec = class, spec
  if ilvl and ilvl > 0 then M.ilvl = ilvl end
  M.rio = rio or (M.rio or 0)
  M.key = { mapID = map or 0, level = lvl or 0 }
  M.week, M.updated = wk or weekID(), upd or now()
  MythicbusDB.members[name] = M
end

local function ingestQUEUE(parts)
  -- QUEUE;name;wantRole;min;max;mapsCSV;ts;[kind];[delve]
  local _, name, wantRole, minLvl, maxLvl, mapsCSV, tsStr, kind, delve = unpack(parts)
  local incomingTs = tonumber(tsStr) or now()

  local q = MythicbusDB.queue[name] or { targetMaps = {} }
  q.ts         = q.ts and math.min(q.ts, incomingTs) or incomingTs
  q.wantRole   = wantRole or q.wantRole or "A"
  q.min        = tonumber(minLvl) or q.min or 0
  q.max        = tonumber(maxLvl) or q.max or 0
  q.updated    = now()
  q.targetMaps = parseCSVints(mapsCSV)

  -- Optional new fields (present when sender supports activity kinds)
  if kind  and kind  ~= "" then q.kind  = kind  end
  if delve and delve ~= "" then q.delve = delve end

  MythicbusDB.queue[name] = q
end

local function ingestLEAVE(parts)
  local _, name = unpack(parts)
  MythicbusDB.queue[name] = nil
end

-- ===== Events / Heartbeats / Cleanup =====
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("CHAT_MSG_ADDON")
f:RegisterEvent("BAG_UPDATE_DELAYED")              -- key changed or picked up
f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")        -- ilvl changes
f:RegisterEvent("PLAYER_AVG_ITEM_LEVEL_UPDATE")    -- ilvl changes
f:SetScript("OnEvent", function(_, ev, ...)
  if ev == "PLAYER_LOGIN" then
    C_Timer.After(4, sendHello)
    C_Timer.After(6, function() if MythicbusDB.queue[me()] then sendMyQueue() end end)

    if not NS._hb then
      NS._hb = C_Timer.NewTicker(60, function()
        if MythicbusDB.queue[me()] then sendMyQueue() end
        local cutoff = now() - 300
        local changed = false
        for name, q in pairs(MythicbusDB.queue) do
          if (q.updated or q.ts or 0) < cutoff then
            MythicbusDB.queue[name] = nil
            changed = true
          end
        end
        if changed and NS.RefreshUI then NS.RefreshUI() end
      end)
    end

  elseif ev == "BAG_UPDATE_DELAYED" then
    C_Timer.After(0.5, sendHello)

  elseif ev == "PLAYER_EQUIPMENT_CHANGED" or ev == "PLAYER_AVG_ITEM_LEVEL_UPDATE" then
    C_Timer.After(0.5, sendHello)

  elseif ev == "CHAT_MSG_ADDON" then
    local prefix, msg = ...
    if prefix ~= PREFIX then return end
    local parts = { strsplit(";", msg) }
    local op = parts[1]
    if op == "HELLO" then
      ingestHELLO(parts)
    elseif op == "QUEUE" then
      ingestQUEUE(parts)
    elseif op == "LEAVE" then
      ingestLEAVE(parts)
    end
    if NS.RefreshUI then NS.RefreshUI() end
  end
end)

-- ===== Slash commands =====
SLASH_MYTHICBUS1 = "/mbus"
SlashCmdList.MYTHICBUS = function(cmd)
  cmd = (cmd or ""):lower()
  if cmd == "queue" then
    NS.QueueMe("A", 0, 0, "")
  elseif cmd == "leave" then
    NS.LeaveQueue()
  elseif cmd == "sync" then
    sendMyQueue()
  elseif cmd == "hello" then
    sendHello()
  else
    print("|cff00ff00Mythicbus|r commands:")
    print("/mbus queue  - queue yourself (AUTO, 0-0)")
    print("/mbus leave  - leave queue")
    print("/mbus sync   - rebroadcast your queue")
    print("/mbus hello  - broadcast presence/key")
  end
end
