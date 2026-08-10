local ADDON, NS = ...

MythicbusDB = MythicbusDB or {}
MythicbusDB.queue = MythicbusDB.queue or {}

local function me()
  local n, r = UnitFullName("player")
  if not r or r == "" then r = GetRealmName():gsub("%s+", "") end
  return n .. "-" .. r
end

local function normalizeRoleSet(v)
  v = tostring(v or ""):upper()
  if v == "" or v == "AUTO" or v == "A" then
    return { T = true, H = true, D = true }
  end
  local out = {}
  for ch in v:gmatch("%a") do
    if ch == "T" or ch == "H" or ch == "D" then out[ch] = true end
  end
  if not (out.T or out.H or out.D) then
    out.T, out.H, out.D = true, true, true
  end
  return out
end

local function normalizeRange(minV, maxV)
  local minN = tonumber(minV) or 0
  local maxN = tonumber(maxV) or 0
  if minN < 0 then minN = 0 end
  if maxN < 0 then maxN = 0 end
  if minN > maxN then minN, maxN = maxN, minN end
  -- 0-0 means "any"
  if minN == 0 and maxN == 0 then
    return 0, 999
  end
  return minN, maxN
end

local function rangesOverlap(aMin, aMax, bMin, bMax)
  return (aMin <= bMax) and (bMin <= aMax)
end

local function mapsToSet(maps)
  local set = {}
  if not maps then return set end
  for _, id in ipairs(maps) do
    local n = tonumber(id)
    if n and n > 0 then set[n] = true end
  end
  return set
end

local function mapOverlap(aMaps, bMaps)
  local aSet = mapsToSet(aMaps)
  local bSet = mapsToSet(bMaps)
  local aCount, bCount = 0, 0
  for _ in pairs(aSet) do aCount = aCount + 1 end
  for _ in pairs(bSet) do bCount = bCount + 1 end
  if aCount == 0 or bCount == 0 then return true end
  for id in pairs(aSet) do
    if bSet[id] then return true end
  end
  return false
end

local function normalizeKind(q)
  local kind = tostring((q and q.kind) or ""):upper()
  if kind ~= "" then return kind end
  if q and ((q.dungeonCode and q.dungeonCode ~= "") or (q.dungeon and q.dungeon ~= "")) then
    return "DUNGEON"
  end
  if q and q.targetMaps and #q.targetMaps > 0 then
    return "DUNGEON"
  end
  return "ANY_DUNGEON"
end

local function normalizeDungeonCode(v)
  return tostring(v or ""):upper():gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalizeDungeonName(v)
  return tostring(v or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalizeDelveName(v)
  return tostring(v or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
end

local function rolesCompatible(a, b)
  local aSet = normalizeRoleSet(a and a.wantRole)
  local bSet = normalizeRoleSet(b and b.wantRole)
  return (aSet.T and bSet.T) or (aSet.H and bSet.H) or (aSet.D and bSet.D)
end

local function roleOptions(q)
  local set = normalizeRoleSet(q and q.wantRole)
  local out = {}
  if set.T then out[#out + 1] = "T" end
  if set.H then out[#out + 1] = "H" end
  if set.D then out[#out + 1] = "D" end
  return out
end

local function activityCompatible(a, b)
  local ak = normalizeKind(a)
  local bk = normalizeKind(b)

  local aDungeon = ak == "ANY_DUNGEON" or ak == "DUNGEON"
  local bDungeon = bk == "ANY_DUNGEON" or bk == "DUNGEON"
  local aDelve = ak == "ANY_DELVE" or ak == "DELVE"
  local bDelve = bk == "ANY_DELVE" or bk == "DELVE"

  if aDungeon and bDungeon then
    if ak == "ANY_DUNGEON" or bk == "ANY_DUNGEON" then
      return true
    end

    local aCode = normalizeDungeonCode(a and a.dungeonCode)
    local bCode = normalizeDungeonCode(b and b.dungeonCode)
    if aCode ~= "" and bCode ~= "" then
      return aCode == bCode
    end

    local aName = normalizeDungeonName(a and a.dungeon)
    local bName = normalizeDungeonName(b and b.dungeon)
    if aName ~= "" and bName ~= "" then
      return aName == bName
    end

    return mapOverlap(a and a.targetMaps, b and b.targetMaps)
  end

  if aDelve and bDelve then
    if ak == "DELVE" and bk == "DELVE" then
      local aName = normalizeDelveName(a and a.delve)
      local bName = normalizeDelveName(b and b.delve)
      if aName ~= "" and bName ~= "" then
        return aName == bName
      end
    end
    return true
  end

  return false
end

local function levelsCompatible(a, b)
  local aMin, aMax = normalizeRange(a and a.min, a and a.max)
  local bMin, bMax = normalizeRange(b and b.min, b and b.max)
  -- 0-999 means "any" (from 0-0 UI input); allow pairing with any target.
  local aAny = (aMin == 0 and aMax >= 999)
  local bAny = (bMin == 0 and bMax >= 999)
  if aAny or bAny then return true end

  -- Specific target ranges must be within +/-1 key level distance.
  local gap
  if aMax < bMin then
    gap = bMin - aMax
  elseif bMax < aMin then
    gap = aMin - bMax
  else
    gap = 0
  end
  return gap <= 1
end

local function getMemberIlvl(name)
  local members = MythicbusDB and MythicbusDB.members
  local row = members and members[name]
  local ilvl = row and tonumber(row.ilvl) or 0
  if ilvl and ilvl > 0 then return ilvl end
  return nil
end

local function ilvlsCompatible(nameA, nameB)
  local a = getMemberIlvl(nameA)
  local b = getMemberIlvl(nameB)
  if not a or not b then return false end
  return math.abs(a - b) <= 8
end

local function scorePair(nameA, a, nameB, b)
  local score = 0

  if activityCompatible(a, b) then
    score = score + 50
  else
    return 0
  end

  if rolesCompatible(a, b) then
    score = score + 25
  else
    return 0
  end

  if levelsCompatible(a, b) then
    score = score + 20
  else
    return 0
  end

  if ilvlsCompatible(nameA, nameB) then
    score = score + 15
  else
    return 0
  end

  local ak = normalizeKind(a)
  local bk = normalizeKind(b)
  local aCode = normalizeDungeonCode(a and a.dungeonCode)
  local bCode = normalizeDungeonCode(b and b.dungeonCode)
  local aName = normalizeDungeonName(a and a.dungeon)
  local bName = normalizeDungeonName(b and b.dungeon)
  if (ak == "DUNGEON" and bk == "DUNGEON" and (
      (aCode ~= "" and bCode ~= "" and aCode == bCode) or
      (aName ~= "" and bName ~= "" and aName == bName)
    )) or mapOverlap(a and a.targetMaps, b and b.targetMaps) then
    score = score + 5
  end

  return score
end

local function baseCompatible(a, b)
  return activityCompatible(a.queue, b.queue)
    and levelsCompatible(a.queue, b.queue)
    and ilvlsCompatible(a.name, b.name)
end

local function baseScore(a, b)
  local score = 0
  if not activityCompatible(a.queue, b.queue) then return 0 end
  score = score + 50
  if not levelsCompatible(a.queue, b.queue) then return 0 end
  score = score + 20
  if not ilvlsCompatible(a.name, b.name) then return 0 end
  score = score + 15

  local ak = normalizeKind(a.queue)
  local bk = normalizeKind(b.queue)
  local aCode = normalizeDungeonCode(a.queue and a.queue.dungeonCode)
  local bCode = normalizeDungeonCode(b.queue and b.queue.dungeonCode)
  local aName = normalizeDungeonName(a.queue and a.queue.dungeon)
  local bName = normalizeDungeonName(b.queue and b.queue.dungeon)
  if (ak == "DUNGEON" and bk == "DUNGEON" and (
      (aCode ~= "" and bCode ~= "" and aCode == bCode) or
      (aName ~= "" and bName ~= "" and aName == bName)
    )) or mapOverlap(a.queue and a.queue.targetMaps, b.queue and b.queue.targetMaps) then
    score = score + 5
  end

  return score
end

local function canAssignRoles(players)
  local needs = { T = 1, H = 1, D = 3 }
  local sized = {}

  for i, p in ipairs(players) do
    local opts = roleOptions(p.queue)
    sized[i] = { name = p.name, opts = opts, count = #opts }
    if #opts == 0 then return false end
  end

  table.sort(sized, function(a, b)
    if a.count == b.count then return a.name < b.name end
    return a.count < b.count
  end)

  local function remainingNeedTotal()
    return needs.T + needs.H + needs.D
  end

  local function dfs(idx)
    if idx > #sized then
      return remainingNeedTotal() == 0
    end

    local left = #sized - idx + 1
    if remainingNeedTotal() > left then
      return false
    end

    for _, r in ipairs(sized[idx].opts) do
      if needs[r] > 0 then
        needs[r] = needs[r] - 1
        if dfs(idx + 1) then return true end
        needs[r] = needs[r] + 1
      end
    end
    return false
  end

  return dfs(1)
end

function NS.AreQueueEntriesCompatible(nameA, nameB)
  local qA = MythicbusDB.queue and MythicbusDB.queue[nameA]
  local qB = MythicbusDB.queue and MythicbusDB.queue[nameB]
  if not qA or not qB then return false, 0 end
  local score = scorePair(nameA, qA, nameB, qB)
  return score > 0, score
end

function NS.GetMatchesFor(name, limit)
  local out = {}
  limit = tonumber(limit) or 20

  local queue = MythicbusDB.queue or {}
  local mine = queue[name]
  if not mine then return out end

  for otherName, otherQ in pairs(queue) do
    if otherName ~= name then
      local score = scorePair(name, mine, otherName, otherQ)
      if score > 0 then
        out[#out + 1] = {
          name = otherName,
          score = score,
          age = math.max(0, time() - (otherQ.updated or otherQ.ts or time())),
          queue = otherQ,
        }
      end
    end
  end

  table.sort(out, function(a, b)
    if a.score == b.score then return a.name < b.name end
    return a.score > b.score
  end)

  if #out > limit then
    for i = #out, limit + 1, -1 do
      out[i] = nil
    end
  end

  return out
end

function NS.GetMyMatches(limit)
  return NS.GetMatchesFor(me(), limit)
end

local function desiredGroupSizeForQueue(q)
  local kind = normalizeKind(q)
  if kind == "DELVE" or kind == "ANY_DELVE" then
    return 3
  end
  return 5
end

-- Build a valid party around an anchor queue entry.
-- Dungeons use 5 players (1 tank / 1 healer / 3 dps).
-- Delves use 3 players and allow any role composition.
function NS.BuildGroupFor(anchorName, groupSize, searchLimit)
  local queue = MythicbusDB.queue or {}
  local anchor = queue[anchorName]
  if not anchor then return {} end
  groupSize = tonumber(groupSize) or desiredGroupSizeForQueue(anchor)
  if groupSize ~= 5 and groupSize ~= 3 then return {} end

  local candidates = {}
  for otherName, otherQ in pairs(queue) do
    local anchorRow = { name = anchorName, queue = anchor }
    local otherRow = { name = otherName, queue = otherQ }
    if otherName ~= anchorName and baseCompatible(anchorRow, otherRow) then
      candidates[#candidates + 1] = {
        name = otherName,
        score = baseScore(anchorRow, otherRow),
        queue = otherQ,
      }
    end
  end

  table.sort(candidates, function(a, b)
    if a.score == b.score then return a.name < b.name end
    return a.score > b.score
  end)

  local needOthers = groupSize - 1
  local n = #candidates
  if n < needOthers then return {} end
  local maxN = math.min(n, tonumber(searchLimit) or 25)
  if maxN < needOthers then return {} end

  local chosen = {}
  local function search(startIdx)
    if #chosen == needOthers then
      local group = {
        { name = anchorName, queue = anchor, score = 0, anchor = true },
      }
      for _, idx in ipairs(chosen) do
        group[#group + 1] = candidates[idx]
      end
      if groupSize == 3 or canAssignRoles(group) then
        return group
      end
      return nil
    end

    local slotsLeft = needOthers - #chosen
    local lastStart = maxN - slotsLeft + 1
    for i = startIdx, lastStart do
      chosen[#chosen + 1] = i
      local got = search(i + 1)
      if got then return got end
      chosen[#chosen] = nil
    end
    return nil
  end

  local result = search(1)
  if result then
    return result
  end

  return {}
end
