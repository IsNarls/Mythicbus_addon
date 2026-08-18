-- Guides/Mythicbus_GuidesDB.lua
-- Minimal guide database + formatter. Data files call RegisterDungeon() (or queue if DB not loaded yet).

local ADDON, NS = ...

NS.MBUS_GuidesDB = NS.MBUS_GuidesDB or {}
local DB = NS.MBUS_GuidesDB

DB.dungeons = DB.dungeons or {}

-- If a data file loads before the DB, it can queue registrations here.
NS.MBUS_GuidesPending = NS.MBUS_GuidesPending or {}

local function _normRole(role)
  role = tostring(role or ""):upper()
  if role == "TANK" or role == "HEALER" or role == "DAMAGER" then return role end
  return "ALL"
end

function DB:RegisterDungeon(key, data)
  if not key or not data then return end
  self.dungeons[key] = data
end

function DB:GetDungeon(key)
  return self.dungeons[key]
end

function DB:GetDungeonList()
  local t = {}
  for k, v in pairs(self.dungeons) do
    t[#t+1] = { key = k, name = v.name or k }
  end
  table.sort(t, function(a,b) return (a.name or "") < (b.name or "") end)
  return t
end

function DB:GetBossList(dungeonKey)
  local d = self.dungeons[dungeonKey]
  if not d or not d.bosses then return {} end
  local t = {}
  for i, b in ipairs(d.bosses) do
    t[#t+1] = { index = i, name = b.name or ("Boss "..i) }
  end
  return t
end

function DB:GetRoleAuto()
  local r = UnitGroupRolesAssigned and UnitGroupRolesAssigned("player") or "NONE"
  if r == "NONE" then return "ALL" end
  return r
end

local function _addSection(out, title, lines)
  if not lines or #lines == 0 then return end
  out[#out+1] = ("|cff66ccff%s|r"):format(title)
  for _, ln in ipairs(lines) do
    out[#out+1] = (" • %s"):format(ln)
  end
  out[#out+1] = " "
end

-- Returns formatted text for UI display.
function DB:FormatBossText(dungeonKey, bossIndex, role)
  local d = self.dungeons[dungeonKey]
  if not d or not d.bosses or not d.bosses[bossIndex] then return "" end

  role = _normRole(role)
  local b = d.bosses[bossIndex]

  local out = {}
  out[#out+1] = ("|cffffd100%s|r"):format(d.name or dungeonKey)
  out[#out+1] = ("|cff00ffcc%s|r"):format(b.name or ("Boss "..bossIndex))
  if b.note and b.note ~= "" then
    out[#out+1] = ("|cffaaaaaa%s|r"):format(b.note)
  end
  out[#out+1] = " "

  _addSection(out, "All Roles", b.all)

  if role == "TANK" then
    _addSection(out, "Tank", b.tank)
  elseif role == "HEALER" then
    _addSection(out, "Healer", b.healer)
  elseif role == "DAMAGER" then
    _addSection(out, "DPS", b.dps)
  else
    _addSection(out, "Tank", b.tank)
    _addSection(out, "Healer", b.healer)
    _addSection(out, "DPS", b.dps)
  end

  return table.concat(out, "\n")
end

-- Ingest any queued registrations from early-loaded data files.
if NS.MBUS_GuidesPending and #NS.MBUS_GuidesPending > 0 then
  for _, item in ipairs(NS.MBUS_GuidesPending) do
    if item and item.key and item.data then
      DB:RegisterDungeon(item.key, item.data)
    end
  end
  wipe(NS.MBUS_GuidesPending)
end
