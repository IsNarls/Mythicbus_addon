local ADDON, NS = ...
MythicbusDB = MythicbusDB or {
  -- ["Name-Realm"] = { class=, spec=, ilvl=0, rio=0, key={mapID=,level=}, week=, updated= }
  members = {},
  -- ["Name-Realm"] = {
  --   wantRole="T/H/D letters", min=, max=, targetMaps={},
  --   kind="ANY_DUNGEON|ANY_DELVE|DUNGEON|DELVE", delve="Delve Name",
  --   dungeonCode="", dungeon="",
  --   ts=, updated=
  -- }
  queue   = {},
  leader  = {},
  version = "0.4.3",
}
MythicbusDB.members = MythicbusDB.members or {}
MythicbusDB.queue = MythicbusDB.queue or {}
MythicbusDB.leader = MythicbusDB.leader or {}

-- ===== Constants / Utils =====
local PREFIX = "MBUS1"

local function now() return time() end
local function weekID() return tonumber(date("!%G%V")) end
local function serverEpoch() return math.floor((GetServerTime() or now()) / 300) end
local LEADER_REELECT_SOON_WINDOW = 60
local LEADER_INSTANCE_HOLD_WINDOW = 120
local INVITE_ACK_TIMEOUT = 45
local function me()
  local n, r = UnitFullName("player")
  if not r or r == "" then r = GetRealmName():gsub("%s+","") end
  return n.."-"..r
end
local function iAmGuildMasterLeader()
  local _, _, rankIndex = GetGuildInfo("player")
  return tonumber(rankIndex) == 0
end

local function iAmInInstance()
  return IsInInstance and select(1, IsInInstance()) or false
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

local function parseNameCSV(csv)
  local out = {}
  for raw in string.gmatch(tostring(csv or ""), "([^,]+)") do
    raw = tostring(raw or "")
    if raw ~= "" then
      local n, r = strsplit("-", raw, 2)
      if not r or r == "" then r = GetRealmName():gsub("%s+", "") end
      if n and n ~= "" then
        out[#out + 1] = n .. "-" .. r:gsub("%s+", "")
      end
    end
  end
  return out
end

local function serializeNames(names)
  local out = {}
  for _, name in ipairs(names or {}) do
    name = tostring(name or "")
    if name ~= "" then
      local n, r = strsplit("-", name, 2)
      if not r or r == "" then r = GetRealmName():gsub("%s+", "") end
      if n and n ~= "" then
        out[#out + 1] = n .. "-" .. r:gsub("%s+", "")
      end
    end
  end
  return table.concat(out, ",")
end

local function encodeField(v)
  v = tostring(v or "")
  v = v:gsub("%%", "%%25")
  v = v:gsub(";", "%%3B")
  return v
end

local function decodeField(v)
  v = tostring(v or "")
  v = v:gsub("%%3[Bb]", ";")
  v = v:gsub("%%25", "%%")
  return v
end

local function normalizeWantRoleLetters(v)
  v = tostring(v or ""):upper()
  if v == "" or v == "AUTO" or v == "A" then return "A" end
  local set = {}
  for ch in v:gmatch("%a") do
    if ch == "T" or ch == "H" or ch == "D" then set[ch] = true end
  end
  local out = ""
  for _, ch in ipairs({"T", "H", "D"}) do
    if set[ch] then out = out .. ch end
  end
  return out ~= "" and out or "A"
end

local function normalizeRange(minLvl, maxLvl)
  local min = tonumber(minLvl) or 0
  local max = tonumber(maxLvl) or 0
  if min < 0 then min = 0 end
  if max < 0 then max = 0 end
  if min > max then min, max = max, min end
  return min, max
end

local function canonicalFullName(raw)
  raw = tostring(raw or "")
  if raw == "" then return "" end
  local n, r = strsplit("-", raw, 2)
  if r and r ~= "" then
    return n .. "-" .. r:gsub("%s+", "")
  end
  return n .. "-" .. GetRealmName():gsub("%s+", "")
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

local function myLeaderScore()
  -- Achievement points + random tie-breaker (1..1000), per election pulse.
  local ap = tonumber(GetTotalAchievementPoints and GetTotalAchievementPoints() or 0) or 0
  local bonus = math.random(1, 1000)
  return ap + bonus
end

local function secondsToNextEpoch()
  local s = GetServerTime() or now()
  local rem = s % 300
  return 300 - rem
end

local function iAmCurrentElectedLeader()
  local L = MythicbusDB.leader or {}
  return canonicalFullName(L.name or "") == canonicalFullName(me())
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
    q.kind or "", encodeField(q.delve or ""),
    encodeField(q.dungeonCode or ""), encodeField(q.dungeon or "")
  }, ";")
  C_ChatInfo.SendAddonMessage(PREFIX, payload, "GUILD")
  q.updated = now()
end

local function sendQueueSyncRequest()
  local payload = table.concat({"QSYNCREQ", me(), tostring(now())}, ";")
  C_ChatInfo.SendAddonMessage(PREFIX, payload, "GUILD")
end

local leaderCandidates = {}
-- Matching principles:
-- 1) Build full parties as 1 tank / 1 healer / 3 dps around one anchor.
-- 2) Pair "any" with specific activity, but enforce ilvl +/-8 and target key +/-1.
-- 3) Guild Master has leader bias whenever online and not in an instance.
-- 4) Delves form 3-player groups and can use any role composition.
local function chooseLeader(epoch)
  local set = leaderCandidates[epoch]
  if not set then return nil end
  local best
  for cname, c in pairs(set) do
    local cForced = (((c.forced or 0) == 1) and ((c.inInstance or 0) == 0) and 1) or 0
    local eligible = MythicbusDB.queue[cname]
    if cForced == 1 then
      eligible = true
    end
    if eligible then
      if not best then
        best = c
      else
        local bForced = (((best.forced or 0) == 1) and ((best.inInstance or 0) == 0) and 1) or 0
        local better = false
        if cForced ~= bForced then
          better = cForced > bForced
        elseif (c.score or 0) ~= (best.score or 0) then
          better = (c.score or 0) > (best.score or 0)
        else
          better = (c.name or "") < (best.name or "")
        end
        if better then best = c end
      end
    end
  end
  return best
end

local function applyLeader(epoch)
  local winner = chooseLeader(epoch)
  if not winner then return end
  if type(MythicbusDB) ~= "table" then MythicbusDB = {} end
  if type(MythicbusDB.leader) ~= "table" then MythicbusDB.leader = {} end
  MythicbusDB.leader.epoch = epoch
  MythicbusDB.leader.name = winner.name
  MythicbusDB.leader.score = winner.score
  MythicbusDB.leader.forced = winner.forced
  MythicbusDB.leader.updated = now()
end

local function sendLeaderPulse()
  local epoch = serverEpoch()
  local name = me()
  local score = myLeaderScore()
  local forced = iAmGuildMasterLeader() and 1 or 0
  local inInstance = iAmInInstance() and 1 or 0

  leaderCandidates[epoch] = leaderCandidates[epoch] or {}
  leaderCandidates[epoch][name] = {
    name = name,
    score = score,
    forced = forced,
    inInstance = inInstance,
    updated = now(),
  }
  applyLeader(epoch)

  local payload = table.concat({
    "LEADERPULSE",
    tostring(epoch),
    name,
    tostring(score),
    tostring(forced),
    tostring(inInstance),
    tostring(now()),
  }, ";")
  C_ChatInfo.SendAddonMessage(PREFIX, payload, "GUILD")
  if NS.RefreshUI then NS.RefreshUI() end
end

local function isLeaderName(name)
  local L = MythicbusDB.leader or {}
  return canonicalFullName(name) == canonicalFullName(L.name or "")
end

local function sendKillQueue(targetName)
  targetName = canonicalFullName(targetName)
  if targetName == "" then return false end
  local payload = table.concat({"KILLQ", targetName, tostring(now())}, ";")
  C_ChatInfo.SendAddonMessage(PREFIX, payload, "GUILD")
  return true
end

local function sendLeaderReselect(reason)
  local payload = table.concat({"LEADERRESELECT", me(), tostring(reason or ""), tostring(now())}, ";")
  C_ChatInfo.SendAddonMessage(PREFIX, payload, "GUILD")
end

local function sendInviteNotice(targetName, inviteesCSV)
  local payload = table.concat({"INVITE", me(), canonicalFullName(targetName), tostring(now()), tostring(inviteesCSV or "")}, ";")
  C_ChatInfo.SendAddonMessage(PREFIX, payload, "GUILD")
end

local function sendInviteReady(leaderName)
  local payload = table.concat({"INVREADY", canonicalFullName(leaderName), me(), tostring(now())}, ";")
  C_ChatInfo.SendAddonMessage(PREFIX, payload, "GUILD")
end

local function sendInviteDeclined(leaderName)
  local payload = table.concat({"INVDECLINE", canonicalFullName(leaderName), me(), tostring(now())}, ";")
  C_ChatInfo.SendAddonMessage(PREFIX, payload, "GUILD")
end

local function sendInviteAccepted(leaderName)
  local payload = table.concat({"INVACCEPT", canonicalFullName(leaderName), me(), tostring(now())}, ";")
  C_ChatInfo.SendAddonMessage(PREFIX, payload, "GUILD")
end

local function invitePlayer(name)
  if C_PartyInfo and C_PartyInfo.InviteUnit then
    C_PartyInfo.InviteUnit(name)
  elseif InviteUnit then
    InviteUnit(name)
  end
end

local function iterGroupMembers()
  local out = {}
  if IsInRaid() then
    for i = 1, GetNumGroupMembers() do
      local unit = "raid" .. i
      local n, r = UnitFullName(unit)
      if n and n ~= "" then
        if not r or r == "" then r = GetRealmName():gsub("%s+", "") end
        out[#out + 1] = n .. "-" .. r
      end
    end
  elseif IsInGroup() then
    out[#out + 1] = me()
    for i = 1, GetNumSubgroupMembers() do
      local unit = "party" .. i
      local n, r = UnitFullName(unit)
      if n and n ~= "" then
        if not r or r == "" then r = GetRealmName():gsub("%s+", "") end
        out[#out + 1] = n .. "-" .. r
      end
    end
  end
  return out
end

local function prunePendingInvites()
  NS._pendingInvites = NS._pendingInvites or {}
  NS._pendingInviteRequests = NS._pendingInviteRequests or {}
  local cutoff = now() - INVITE_ACK_TIMEOUT
  for name, ts in pairs(NS._pendingInvites) do
    if (tonumber(ts) or 0) < cutoff then
      NS._pendingInvites[name] = nil
    end
  end
  for name, ts in pairs(NS._pendingInviteRequests) do
    if (tonumber(ts) or 0) < cutoff then
      NS._pendingInviteRequests[name] = nil
    end
  end
  if NS._pendingGroupInvite and (tonumber(NS._pendingGroupInvite.ts) or 0) < cutoff then
    NS._pendingGroupInvite = nil
  end
end

local function hasPendingInvites()
  prunePendingInvites()
  for _ in pairs(NS._pendingInvites or {}) do return true end
  for _ in pairs(NS._pendingInviteRequests or {}) do return true end
  if NS._pendingGroupInvite and (tonumber(NS._pendingGroupInvite.ts) or 0) > 0 then return true end
  return false
end

local function chooseInviteCaptain(picks)
  local bestName
  local bestTs
  for _, name in ipairs(picks or {}) do
    local q = MythicbusDB.queue[name]
    local ts = q and tonumber(q.ts) or math.huge
    if not bestName or ts < bestTs or (ts == bestTs and name < bestName) then
      bestName = name
      bestTs = ts
    end
  end
  return bestName
end

local function leaderMatchTick()
  if not NS.IsLocalLeader() then return end
  local myQueue = MythicbusDB.queue[me()]
  if not myQueue then return end
  if IsInGroup() or IsInRaid() then return end
  if hasPendingInvites() then return end
  local myKind = tostring((myQueue and myQueue.kind) or ""):upper()
  local desiredSlots = (myKind == "DELVE" or myKind == "ANY_DELVE") and 2 or 4
  local picks = {}

  if NS.BuildGroupFor then
    local group = NS.BuildGroupFor(me(), desiredSlots + 1) or {}
    for _, member in ipairs(group) do
      local target = canonicalFullName(member.name)
      if target ~= me() and MythicbusDB.queue[target] then
        picks[#picks + 1] = target
      end
    end
  elseif NS.GetMyMatches then
    local matches = NS.GetMyMatches(10) or {}
    for _, m in ipairs(matches) do
      local target = canonicalFullName(m.name)
      if target ~= me() and MythicbusDB.queue[target] then
        picks[#picks + 1] = target
        if #picks >= desiredSlots then break end
      end
    end
  end

  if #picks < desiredSlots then return end

  local captain = chooseInviteCaptain(picks)
  if not captain or captain == "" then return end

  local invitees = { me() }
  for _, target in ipairs(picks) do
    if canonicalFullName(target) ~= captain then
      invitees[#invitees + 1] = target
    end
  end

  NS._pendingInviteRequests = NS._pendingInviteRequests or {}
  NS._pendingGroupInvite = {
    captain = captain,
    members = invitees,
    ts = now(),
  }
  sendInviteNotice(captain, serializeNames(invitees))
  NS._pendingInviteRequests[captain] = now()
end

StaticPopupDialogs["MBUS_GROUP_INVITE_REQUEST"] = StaticPopupDialogs["MBUS_GROUP_INVITE_REQUEST"] or {
  text = "%s wants to invite you to a Mythicbus group. Accept?",
  button1 = "Accept",
  button2 = "Decline",
  timeout = 30,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = STATICPOPUP_NUMDIALOGS,
  OnAccept = function(self, data)
    local leaderName = data and data.leaderName
    local inviteTargets = data and data.inviteTargets
    NS._pendingInvites = NS._pendingInvites or {}
    for _, target in ipairs(inviteTargets or {}) do
      target = canonicalFullName(target)
      if target ~= "" and target ~= me() then
        invitePlayer(target)
        NS._pendingInvites[target] = now()
      end
    end
    if leaderName and leaderName ~= "" then
      sendInviteReady(leaderName)
    end
    NS._pendingLeaderInviteFrom = nil
    NS._pendingLeaderInviteAt = nil
  end,
  OnCancel = function(self, data)
    local leaderName = data and data.leaderName
    if leaderName and leaderName ~= "" then
      sendInviteDeclined(leaderName)
    end
    NS._pendingLeaderInviteFrom = nil
    NS._pendingLeaderInviteAt = nil
  end,
}

-- ===== API exposed to UI =====
-- kind ∈ {"ANY_DUNGEON","ANY_DELVE","DUNGEON","DELVE"}; delveName is used when kind == "DELVE"
-- dungeonCode/dungeonName are used when kind == "DUNGEON"
function NS.QueueMe(wantRoleLetters, minLvl, maxLvl, mapsCSV, kind, delveName, dungeonCode, dungeonName)
  local name = me()
  local wantRole = normalizeWantRoleLetters(wantRoleLetters)
  local minN, maxN = normalizeRange(minLvl, maxLvl)

  local existing = MythicbusDB.queue[name]
  local firstTs = existing and existing.ts or now()

  MythicbusDB.queue[name] = {
    wantRole   = wantRole,
    min        = minN,
    max        = maxN,
    targetMaps = parseCSVints(mapsCSV),
    kind       = kind,          -- may be nil for legacy callers
    delve      = tostring(delveName or ""), -- only meaningful when kind == "DELVE"
    dungeonCode = tostring(dungeonCode or ""),
    dungeon    = tostring(dungeonName or ""),
    ts         = firstTs,
    updated    = now(),
  }

  -- Initial broadcast of QUEUE (match heartbeat shape)
  local payload = table.concat({
    "QUEUE", name, wantRole,
    minN, maxN,
    serializeMaps(MythicbusDB.queue[name].targetMaps),
    firstTs,
    kind or "",
    encodeField(delveName or ""),
    encodeField(dungeonCode or ""),
    encodeField(dungeonName or "")
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

function NS.GetCurrentLeader()
  local L = MythicbusDB.leader or {}
  return L.name, L.epoch, L.score, L.forced
end

function NS.IsLocalLeader()
  local L = MythicbusDB.leader or {}
  if iAmGuildMasterLeader() then
    return not iAmInInstance()
  end
  return (L.name or "") == me()
end

function NS.SendKillQueue(targetName)
  if not NS.IsLocalLeader() then return false end
  return sendKillQueue(targetName)
end

-- ===== Ingestors =====
local function ingestHELLO(parts, sender)
  -- Old:  HELLO;name;class;spec;rio;map;lvl;week;updated               (#=9)
  -- New:  HELLO;name;class;spec;ilvl;rio;map;lvl;week;updated         (#=10)
  local n = #parts
  local name, class, spec = parts[2], parts[3], parts[4]
  if canonicalFullName(name) ~= canonicalFullName(sender) then return end
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

local function ingestQUEUE(parts, sender)
  -- QUEUE;name;wantRole;min;max;mapsCSV;ts;[kind];[delve];[dungeonCode];[dungeonName]
  local _, name, wantRole, minLvl, maxLvl, mapsCSV, tsStr, kind, delve, dungeonCode, dungeonName = unpack(parts)
  if canonicalFullName(name) ~= canonicalFullName(sender) then return end
  local incomingMin, incomingMax = normalizeRange(minLvl, maxLvl)
  local incomingTs = tonumber(tsStr) or now()

  local q = MythicbusDB.queue[name] or { targetMaps = {} }
  q.ts         = q.ts and math.min(q.ts, incomingTs) or incomingTs
  q.wantRole   = normalizeWantRoleLetters(wantRole or q.wantRole)
  q.min        = incomingMin
  q.max        = incomingMax
  q.updated    = now()
  q.targetMaps = parseCSVints(mapsCSV)

  -- Optional new fields (present when sender supports activity kinds)
  if kind  and kind  ~= "" then q.kind  = kind  end
  if delve and delve ~= "" then q.delve = decodeField(delve) end
  if dungeonCode and dungeonCode ~= "" then q.dungeonCode = decodeField(dungeonCode) end
  if dungeonName and dungeonName ~= "" then q.dungeon = decodeField(dungeonName) end

  MythicbusDB.queue[name] = q
end

local function ingestLEAVE(parts, sender)
  local _, name = unpack(parts)
  if canonicalFullName(name) ~= canonicalFullName(sender) then return end
  MythicbusDB.queue[name] = nil
end

local function ingestQueueSyncReq(parts, sender)
  local _, name = unpack(parts)
  if canonicalFullName(name) ~= canonicalFullName(sender) then return end
  if MythicbusDB.queue[me()] then sendMyQueue() end
end

local function ingestLeaderPulse(parts, sender)
  -- LEADERPULSE;epoch;name;score;forced;[inInstance];updated
  local _, epochStr, name, scoreStr, forcedStr, inInstStr, updStr = unpack(parts)
  if canonicalFullName(name) ~= canonicalFullName(sender) then return end

  local epoch = tonumber(epochStr) or serverEpoch()
  local score = tonumber(scoreStr) or 0
  local forced = tonumber(forcedStr) or 0
  local inInstance = tonumber(inInstStr)
  local upd = tonumber(updStr)

  -- Backward compatibility with older pulse shape (no inInstance field).
  if inInstance == nil then
    inInstance = 0
    upd = tonumber(inInstStr) or now()
  end
  if upd == nil then upd = now() end

  leaderCandidates[epoch] = leaderCandidates[epoch] or {}
  leaderCandidates[epoch][name] = {
    name = name,
    score = score,
    forced = forced,
    inInstance = inInstance,
    updated = upd,
  }
  applyLeader(epoch)
end

local function ingestKillQueue(parts, sender)
  -- KILLQ;targetName;ts
  local _, targetName = unpack(parts)
  if not isLeaderName(sender) then return end
  if canonicalFullName(targetName) ~= canonicalFullName(me()) then return end
  if MythicbusDB.queue[me()] then
    NS.LeaveQueue()
  end
end

local function ingestLeaderReselect(parts, sender)
  local _, from = unpack(parts)
  if canonicalFullName(from) ~= canonicalFullName(sender) then return end
  if MythicbusDB.queue[me()] or (iAmGuildMasterLeader() and not iAmInInstance()) then
    sendLeaderPulse()
  end
end

local function ingestInvite(parts, sender)
  -- INVITE;leaderName;targetName;ts;inviteesCSV
  local _, leaderName, targetName, _, inviteesCSV = unpack(parts)
  if canonicalFullName(leaderName) ~= canonicalFullName(sender) then return end
  if canonicalFullName(targetName) ~= canonicalFullName(me()) then return end
  NS._pendingLeaderInviteFrom = canonicalFullName(leaderName)
  NS._pendingLeaderInviteAt = now()
  local inviteTargets = parseNameCSV(inviteesCSV)
  StaticPopup_Show("MBUS_GROUP_INVITE_REQUEST", leaderName, nil, { leaderName = leaderName, inviteTargets = inviteTargets })
end

local function ingestInviteReady(parts, sender)
  -- INVREADY;leaderName;targetName;ts
  local _, leaderName, targetName = unpack(parts)
  if canonicalFullName(targetName) ~= canonicalFullName(sender) then return end
  if canonicalFullName(leaderName) ~= canonicalFullName(me()) then return end
  if not NS.IsLocalLeader() then return end

  targetName = canonicalFullName(targetName)
  if targetName == "" then return end

  NS._pendingInviteRequests = NS._pendingInviteRequests or {}
  NS._pendingInviteRequests[targetName] = nil
  if NS._pendingGroupInvite and canonicalFullName(NS._pendingGroupInvite.captain or "") == targetName then
    NS._pendingGroupInvite = nil
  end
end

local function ingestInviteAccept(parts, sender)
  -- INVACCEPT;leaderName;targetName;ts
  local _, leaderName, targetName = unpack(parts)
  if canonicalFullName(targetName) ~= canonicalFullName(sender) then return end
  if canonicalFullName(leaderName) ~= canonicalFullName(me()) then return end
  if not NS.IsLocalLeader() then return end
  targetName = canonicalFullName(targetName)
  if targetName ~= "" then
    sendKillQueue(targetName)
    if NS._pendingInvites then NS._pendingInvites[targetName] = nil end
    if NS._pendingInviteRequests then NS._pendingInviteRequests[targetName] = nil end
  end
end

local function ingestInviteDecline(parts, sender)
  -- INVDECLINE;leaderName;targetName;ts
  local _, leaderName, targetName = unpack(parts)
  if canonicalFullName(targetName) ~= canonicalFullName(sender) then return end
  if canonicalFullName(leaderName) ~= canonicalFullName(me()) then return end
  if not NS.IsLocalLeader() then return end
  targetName = canonicalFullName(targetName)
  if targetName ~= "" and NS._pendingInviteRequests then
    NS._pendingInviteRequests[targetName] = nil
  end
  if NS._pendingGroupInvite and canonicalFullName(NS._pendingGroupInvite.captain or "") == targetName then
    NS._pendingGroupInvite = nil
  end
end

local function handleGroupStateTransition()
  local inGroup = IsInGroup() or IsInRaid()
  if NS._wasInGroup == nil then NS._wasInGroup = inGroup return end
  if NS._wasInGroup == inGroup then return end
  NS._wasInGroup = inGroup

  -- Invitee path: I joined group after receiving a leader invite.
  if inGroup and NS._pendingLeaderInviteFrom then
    sendInviteAccepted(NS._pendingLeaderInviteFrom)
    NS._pendingLeaderInviteFrom = nil
    NS._pendingLeaderInviteAt = nil
  end

  -- Leader path: ensure queued group members are removed once grouped.
  if inGroup and NS.IsLocalLeader() then
    for _, gname in ipairs(iterGroupMembers()) do
      gname = canonicalFullName(gname)
      if gname ~= "" and gname ~= me() and MythicbusDB.queue[gname] then
        sendKillQueue(gname)
      end
    end
  end

  -- Any queued player (including leader) leaves queue on group join.
  if inGroup and MythicbusDB.queue[me()] then
    local wasLeader = NS.IsLocalLeader()
    NS.LeaveQueue()
    if wasLeader and secondsToNextEpoch() > LEADER_REELECT_SOON_WINDOW then
      sendLeaderReselect("leader_grouped")
    end
  end
end

local function handleInstanceLeaderTransition()
  local inInstance = iAmInInstance()
  if NS._wasInInstance == nil then
    NS._wasInInstance = inInstance
    return
  end
  if NS._wasInInstance == inInstance then return end
  NS._wasInInstance = inInstance

  -- On leader entering an instance, ask for re-election unless next epoch is close.
  if inInstance and iAmCurrentElectedLeader() then
    if secondsToNextEpoch() >= LEADER_INSTANCE_HOLD_WINDOW then
      sendLeaderReselect("leader_instance")
    end
  end
end

-- ===== Events / Heartbeats / Cleanup =====
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("CHAT_MSG_ADDON")
f:RegisterEvent("BAG_UPDATE_DELAYED")              -- key changed or picked up
f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")        -- ilvl changes
f:RegisterEvent("PLAYER_AVG_ITEM_LEVEL_UPDATE")    -- ilvl changes
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:SetScript("OnEvent", function(_, ev, ...)
  if ev == "PLAYER_LOGIN" then
    local seed = (now() % 100000) + ((GetServerTime() or 0) % 100000)
    if type(math) == "table" and type(math.randomseed) == "function" then
      math.randomseed(seed)
    elseif type(randomseed) == "function" then
      randomseed(seed)
    end
    C_Timer.After(4, sendHello)
    C_Timer.After(5, sendQueueSyncRequest)
    C_Timer.After(7, sendLeaderPulse)
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

    if not NS._leaderTicker then
      NS._leaderEpoch = serverEpoch()
      NS._leaderTicker = C_Timer.NewTicker(5, function()
        handleInstanceLeaderTransition()
        local e = serverEpoch()
        if e ~= NS._leaderEpoch then
          NS._leaderEpoch = e
          leaderCandidates[e] = {}
          sendLeaderPulse()
        end
      end)
    end

    if not NS._matchTicker then
      NS._matchTicker = C_Timer.NewTicker(8, leaderMatchTick)
    end

  elseif ev == "BAG_UPDATE_DELAYED" then
    C_Timer.After(0.5, sendHello)

  elseif ev == "PLAYER_EQUIPMENT_CHANGED" or ev == "PLAYER_AVG_ITEM_LEVEL_UPDATE" then
    C_Timer.After(0.5, sendHello)

  elseif ev == "GROUP_ROSTER_UPDATE" then
    handleGroupStateTransition()

  elseif ev == "CHAT_MSG_ADDON" then
    local prefix, msg, _, sender = ...
    if prefix ~= PREFIX then return end
    local parts = { strsplit(";", msg) }
    local op = parts[1]
    if op == "HELLO" then
      ingestHELLO(parts, sender)
    elseif op == "QUEUE" then
      ingestQUEUE(parts, sender)
    elseif op == "LEAVE" then
      ingestLEAVE(parts, sender)
    elseif op == "QSYNCREQ" then
      ingestQueueSyncReq(parts, sender)
    elseif op == "LEADERPULSE" then
      ingestLeaderPulse(parts, sender)
    elseif op == "KILLQ" then
      ingestKillQueue(parts, sender)
    elseif op == "LEADERRESELECT" then
      ingestLeaderReselect(parts, sender)
    elseif op == "INVITE" then
      ingestInvite(parts, sender)
    elseif op == "INVREADY" then
      ingestInviteReady(parts, sender)
    elseif op == "INVACCEPT" then
      ingestInviteAccept(parts, sender)
    elseif op == "INVDECLINE" then
      ingestInviteDecline(parts, sender)
    end
    if NS.RefreshUI then NS.RefreshUI() end
  end
end)

-- ===== Slash commands =====
SLASH_MYTHICBUS1 = "/mbus"
SlashCmdList.MYTHICBUS = function(cmd)
  local raw = tostring(cmd or "")
  local lowered = raw:lower()
  if lowered == "queue" then
    NS.QueueMe("A", 0, 0, "")
  elseif lowered == "leave" then
    NS.LeaveQueue()
  elseif lowered == "sync" then
    sendMyQueue()
  elseif lowered == "hello" then
    sendHello()
  elseif lowered == "leader" then
    local name, epoch = NS.GetCurrentLeader()
    print(("Leader: %s (epoch %s)"):format(name or "unknown", tostring(epoch or "?")))
  elseif lowered == "elect" then
    sendLeaderPulse()
  elseif lowered:sub(1, 5) == "kill " then
    local target = raw:sub(6)
    if target == "" then
      print("Usage: /mbus kill Name-Realm")
    elseif NS.SendKillQueue(target) then
      print(("Sent queue-kill to %s"):format(target))
    else
      print("Only current leader can send queue-kill")
    end
  else
    print("|cff00ff00Mythicbus|r commands:")
    print("/mbus queue  - queue yourself (AUTO, 0-0)")
    print("/mbus leave  - leave queue")
    print("/mbus sync   - rebroadcast your queue")
    print("/mbus hello  - broadcast presence/key")
    print("/mbus leader - show current elected leader")
    print("/mbus elect  - send leader pulse now")
    print("/mbus kill Name-Realm - leader removes target from queue")
  end
end
