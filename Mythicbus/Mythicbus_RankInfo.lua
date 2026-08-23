-- Mythicbus_RankInfo.lua
-- Mythic+ Rating progress => CURRENT rank + NEXT rank
-- Revisions:
--  - No text on the main bar
--  - Score moved to top-left corner
--  - More side padding (cards constrained to bar width)
--  - Current card: NO XP bar (blue bar removed)
--  - Next card: gold XP bar only

local ADDON, NS = ...
MythicbusDB = MythicbusDB or {}
pcall(LoadAddOn, "Blizzard_PanelTemplates")

-- ======================
-- Config
-- ======================
local RATING_CAP = 3400
local NUM_RANKS  = 6

local RANKS = {
  { name="Aisle Seat",       min=0,    max=1499, repairs=25  },
  { name="Window Seat",      min=1500, max=1999, repairs=50  },
  { name="Wheel Enthusiast", min=2000, max=2599, repairs=100 },
  { name="Road Veteran",     min=2600, max=2999, repairs=150 },
  { name="Turbo Driver",     min=3000, max=3399, repairs=200 },
  { name="Bussin",           min=3400, max=999999, repairs=250 }, -- 3400+
}

local CURRENT_SEASON_DUNGEONS = {
  { code = "AOF", name = "Altar of Fangs" },
  { code = "BLV", name = "The Blinding Vale", aliases = { "Blinding Vale" } },
  { code = "DON", name = "Den of Nalorakk" },
  { code = "KR",  name = "King's Rest", aliases = { "Kings Rest" } },
  { code = "MR",  name = "Murder Row" },
  { code = "RLP", name = "Ruby Life Pools" },
  { code = "TOS", name = "Temple of Sethraliss" },
  { code = "VSA", name = "Voidscar Arena" },
}

local RANK_IMAGE_PATH = "Interface/AddOns/" .. ADDON .. "/Images/Rank Images/%d.tga"
local RANK_IMAGE_ASPECT = 0.75
local RING_ICON_SIZE = 68
local CARD_ICON_SIZE = 84
local PIP_SIZE = 42
local RANK_ICON_PADDING = 2
local ILVL_KEY_FLOOR = 240
local ILVL_KEY_CEILING = 295
local ILVL_MIN_KEY = 2
local ILVL_MAX_KEY = 20

local function Clamp(n, a, b)
  if n < a then return a end
  if n > b then return b end
  return n
end

local function FormatGold(g) return ("%dg repairs"):format(tonumber(g) or 0) end

local function GetPlayerEquippedItemLevel()
  if GetAverageItemLevel then
    local avg, equipped = GetAverageItemLevel()
    return tonumber(equipped or avg) or 0
  end
  return 0
end

local function GetItemLevelSuggestedKeyLevel()
  local ilvl = GetPlayerEquippedItemLevel()
  if ilvl <= 0 then return ILVL_MIN_KEY, ilvl end
  if ilvl <= ILVL_KEY_FLOOR then return ILVL_MIN_KEY, ilvl end
  if ilvl >= ILVL_KEY_CEILING then return ILVL_MAX_KEY, ilvl end

  local pct = (ilvl - ILVL_KEY_FLOOR) / (ILVL_KEY_CEILING - ILVL_KEY_FLOOR)
  local key = ILVL_MIN_KEY + (pct * (ILVL_MAX_KEY - ILVL_MIN_KEY))
  return Clamp(math.floor(key + 0.5), ILVL_MIN_KEY, ILVL_MAX_KEY), ilvl
end

local function GetItemLevelCatchupStep(suggestedKeyLevel)
  suggestedKeyLevel = tonumber(suggestedKeyLevel) or ILVL_MIN_KEY
  local keyRange = math.max(0, suggestedKeyLevel - ILVL_MIN_KEY)
  return Clamp(math.floor(keyRange * 0.4), 2, 8)
end

local function NormalizeDungeonName(name)
  local s = tostring(name or ""):lower()
  s = s:gsub("'", "")
  s = s:gsub("[^%w%s]", " ")
  s = s:gsub("%s+", " ")
  s = s:gsub("^%s+", ""):gsub("%s+$", "")
  if s == "magister s terrace" then s = "magisters terrace" end
  return s
end

local function GetRankImagePath(rankIndex)
  rankIndex = Clamp(tonumber(rankIndex) or 1, 1, NUM_RANKS)
  if rankIndex == 4 then
    rankIndex = 6
  elseif rankIndex == 6 then
    rankIndex = 4
  end
  return RANK_IMAGE_PATH:format(rankIndex)
end

local function SetRankIcon(slot, rankIndex)
  if not (slot and slot.tex) then return end
  slot.tex:SetTexture(GetRankImagePath(rankIndex))
  slot.tex:SetTexCoord(0, 1, 0, 1)
  slot.tex:Show()
end

local function FitRankTexture(slot, padding)
  if not (slot and slot.tex) then return end
  padding = padding or RANK_ICON_PADDING
  local slotW, slotH = slot:GetSize()
  local h = math.max(1, (slotH or 0) - (padding * 2))
  local w = math.min(math.floor(h * RANK_IMAGE_ASPECT), math.max(1, (slotW or 0) - (padding * 2)))
  slot.tex:ClearAllPoints()
  slot.tex:SetSize(w, h)
  slot.tex:SetPoint("CENTER")
end

local function GetRankSlotWidth(height)
  return math.floor((height - (RANK_ICON_PADDING * 2)) * RANK_IMAGE_ASPECT) + (RANK_ICON_PADDING * 2)
end

local function GetRankIndexForRating(rating)
  local idx = 1
  for i = #RANKS, 1, -1 do
    if rating >= (RANKS[i].min or 0) then idx = i; break end
  end
  return idx
end

local function GetPlayerMPlusRating()
  if C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
    local s = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
    if s then
      if type(s.currentSeasonScore) == "number" then return s.currentSeasonScore end
      if type(s.rating) == "number" then return s.rating end
    end
  end
  if C_ChallengeMode and C_ChallengeMode.GetOverallDungeonScore then
    local score = C_ChallengeMode.GetOverallDungeonScore()
    if type(score) == "number" then return score end
  end
  return 0
end

local function ReadNumericField(tbl, keys)
  if type(tbl) ~= "table" then return nil end
  for _, key in ipairs(keys) do
    local v = tbl[key]
    if type(v) == "number" then return v end
    if type(v) == "table" then
      local nested = ReadNumericField(v, { "score", "amount", "value", "level", "challengeLevel" })
      if nested then return nested end
    end
  end
  return nil
end

local function ReadBooleanField(tbl, keys)
  if type(tbl) ~= "table" then return nil end
  for _, key in ipairs(keys) do
    local v = tbl[key]
    if type(v) == "boolean" then return v end
    if type(v) == "number" then return v ~= 0 end
    if type(v) == "table" then
      local nested = ReadBooleanField(v, { "completedInTime", "inTime", "timed", "isTimed", "overTime", "isOverTime" })
      if nested ~= nil then return nested end
    end
  end
  return nil
end

local function RunInfoIsTimed(info)
  if type(info) ~= "table" then return false end

  local overTime = ReadBooleanField(info, { "overTime", "isOverTime", "wasOverTime" })
  if overTime ~= nil then return not overTime end

  local timed = ReadBooleanField(info, { "completedInTime", "inTime", "timed", "isTimed", "onTime" })
  if timed ~= nil then return timed end

  return false
end

local function GetChallengeMapName(mapID)
  if not mapID or mapID == 0 then return nil end
  local name
  if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
    name = C_ChallengeMode.GetMapUIInfo(mapID)
  end
  if (not name or name == "") and C_MythicPlus and C_MythicPlus.GetMapInfo then
    local info = C_MythicPlus.GetMapInfo(mapID)
    name = info and info.name
  end
  if (not name or name == "") and C_MythicPlus and C_MythicPlus.GetMapUIInfo then
    name = C_MythicPlus.GetMapUIInfo(mapID)
  end
  return (name and name ~= "") and name or nil
end

local function CollectChallengeMapsByName()
  local byName = {}
  local ids = {}

  if C_ChallengeMode and C_ChallengeMode.GetMapTable then
    ids = C_ChallengeMode.GetMapTable() or {}
  elseif C_MythicPlus and C_MythicPlus.GetMapTable then
    ids = C_MythicPlus.GetMapTable() or {}
  end

  for _, mapID in ipairs(ids) do
    local name = GetChallengeMapName(mapID)
    local key = NormalizeDungeonName(name)
    if key ~= "" and not byName[key] then
      byName[key] = { id = mapID, name = name }
    end
  end

  return byName
end

local function GetSeasonDungeonMaps()
  local byName = CollectChallengeMapsByName()
  local maps = {}

  for _, dungeon in ipairs(CURRENT_SEASON_DUNGEONS) do
    local found = byName[NormalizeDungeonName(dungeon.name)]
    if not found then
      for _, alias in ipairs(dungeon.aliases or {}) do
        found = byName[NormalizeDungeonName(alias)]
        if found then break end
      end
    end
    maps[#maps + 1] = {
      id = found and found.id or nil,
      name = (found and found.name) or dungeon.name,
    }
  end

  return maps
end

local function EstimateBarelyTimedKeyScore(level)
  level = tonumber(level) or 0
  if level <= 0 then return 0 end

  local baseScores = { 0, 40, 45, 55, 60, 65, 75, 80, 85, 100 }
  if level <= 10 then
    return baseScores[level] or 0
  end

  return baseScores[10] + ((level - 10) * 5)
end

local function ApplyBestRun(bestByMap, mapID, level, score)
  mapID = tonumber(mapID) or 0
  level = tonumber(level) or 0
  score = tonumber(score) or 0
  if mapID == 0 or (level == 0 and score == 0) then return end

  local current = bestByMap[mapID]
  if not current or level > (current.level or 0) or score > (current.score or 0) then
    bestByMap[mapID] = {
      level = math.max(level, current and (current.level or 0) or 0),
      score = math.max(score, current and (current.score or 0) or 0),
    }
  end
end

local function ApplyTimedRunInfo(bestByMap, mapID, info)
  if type(info) ~= "table" then return end
  if not RunInfoIsTimed(info) then return end
  local level = ReadNumericField(info, { "bestRunLevel", "level", "mythicLevel", "challengeLevel", "keystoneLevel", "bestLevel" })
  local score = ReadNumericField(info, { "mapScore", "score", "rating", "overAllScore", "overallScore" })
  ApplyBestRun(bestByMap, mapID, level, score)
end

local function CollectTimedBestRunsByMap()
  local bestByMap = {}

  if C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
    local summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
    for _, run in ipairs((summary and summary.runs) or {}) do
      if RunInfoIsTimed(run) then
        local mapID = ReadNumericField(run, { "challengeModeID", "mapChallengeModeID", "mapID", "id" })
        local level = ReadNumericField(run, { "bestRunLevel", "level", "mythicLevel", "challengeLevel" })
        local score = ReadNumericField(run, { "mapScore", "score", "rating" })
        ApplyBestRun(bestByMap, mapID, level, score)
      end
    end
  end

  if C_MythicPlus and C_MythicPlus.GetSeasonBestForMap then
    for _, dungeon in ipairs(GetSeasonDungeonMaps()) do
      if dungeon.id then
        local ok, bestTimed = pcall(C_MythicPlus.GetSeasonBestForMap, dungeon.id)
        if ok then
          ApplyBestRun(bestByMap, dungeon.id,
            ReadNumericField(bestTimed, { "bestRunLevel", "level", "mythicLevel", "challengeLevel", "keystoneLevel", "bestLevel" }),
            ReadNumericField(bestTimed, { "mapScore", "score", "rating", "overAllScore", "overallScore" })
          )
        end
      end
    end
  end

  if C_MythicPlus and C_MythicPlus.GetSeasonBestAffixScoreInfoForMap then
    for _, dungeon in ipairs(GetSeasonDungeonMaps()) do
      if dungeon.id then
        local ok, info = pcall(C_MythicPlus.GetSeasonBestAffixScoreInfoForMap, dungeon.id)
        if not ok then info = nil end
        if RunInfoIsTimed(info) then
          ApplyBestRun(bestByMap, dungeon.id,
            ReadNumericField(info, { "level", "bestRunLevel", "mythicLevel", "challengeLevel" }),
            ReadNumericField(info, { "score", "mapScore", "rating" })
          )
        end

        for _, affixInfo in ipairs((type(info) == "table" and info.affixScoreInfo) or {}) do
          if RunInfoIsTimed(affixInfo) then
            ApplyBestRun(bestByMap, dungeon.id,
              ReadNumericField(affixInfo, { "level", "bestRunLevel", "mythicLevel", "challengeLevel" }),
              ReadNumericField(affixInfo, { "score", "mapScore", "rating" })
            )
          end
        end
      end
    end
  end

  return bestByMap
end

local function GetSuggestedNextKey()
  local bestByMap = CollectTimedBestRunsByMap()
  local dungeons = {}
  local hasAnyResolvedMap = false
  local highestLevel = 0
  local ilvlSuggestedKey, playerItemLevel = GetItemLevelSuggestedKeyLevel()

  for _, dungeon in ipairs(GetSeasonDungeonMaps()) do
    if dungeon.id then
      hasAnyResolvedMap = true

      local best = bestByMap[dungeon.id]
      local currentLevel = best and (best.level or 0) or 0
      local currentScore = EstimateBarelyTimedKeyScore(currentLevel)

      dungeons[#dungeons + 1] = {
        mapID = dungeon.id,
        name = dungeon.name,
        currentLevel = currentLevel,
        currentScore = currentScore,
        hasMapID = true,
      }

      if currentLevel > highestLevel then
        highestLevel = currentLevel
      end
    end
  end

  if not hasAnyResolvedMap or #dungeons == 0 then return nil end

  local ladderTarget = math.max(ILVL_MIN_KEY, math.min(math.max(highestLevel, ILVL_MIN_KEY), ilvlSuggestedKey))
  local lowest
  for _, dungeon in ipairs(dungeons) do
    if dungeon.currentLevel < ladderTarget then
      if not lowest then
        lowest = dungeon
      elseif dungeon.currentLevel < lowest.currentLevel then
        lowest = dungeon
      elseif dungeon.currentLevel == lowest.currentLevel and dungeon.name < lowest.name then
        lowest = dungeon
      end
    end
  end

  local suggestion = lowest
  local targetLevel
  local mode

  if suggestion then
    local catchupStep = GetItemLevelCatchupStep(ilvlSuggestedKey)
    targetLevel = math.max(ILVL_MIN_KEY, math.min(suggestion.currentLevel + catchupStep, ladderTarget))
    mode = "equalize"
  else
    MythicbusDB.rankSuggestion = MythicbusDB.rankSuggestion or {}
    local cache = MythicbusDB.rankSuggestion
    if cache.equalizedLevel ~= ladderTarget or cache.ilvlSuggestedKey ~= ilvlSuggestedKey or not cache.name then
      local pick = dungeons[math.random(#dungeons)]
      cache.equalizedLevel = ladderTarget
      cache.ilvlSuggestedKey = ilvlSuggestedKey
      cache.name = pick and pick.name or nil
    end

    for _, dungeon in ipairs(dungeons) do
      if dungeon.name == cache.name then
        suggestion = dungeon
        break
      end
    end

    suggestion = suggestion or dungeons[1]
    if ilvlSuggestedKey >= ILVL_MAX_KEY and highestLevel >= ILVL_MAX_KEY then
      targetLevel = highestLevel + 1
    else
      targetLevel = math.max(ILVL_MIN_KEY, math.min(ladderTarget + 1, ilvlSuggestedKey))
    end
    mode = "push"
  end

  if not suggestion then return nil end

  local projectedScore = EstimateBarelyTimedKeyScore(targetLevel)
  suggestion.targetLevel = targetLevel
  suggestion.highestLevel = highestLevel
  suggestion.ladderTarget = ladderTarget
  suggestion.ilvlSuggestedKey = ilvlSuggestedKey
  suggestion.playerItemLevel = playerItemLevel
  suggestion.gain = math.max(0, projectedScore - (suggestion.currentScore or 0))
  suggestion.mode = mode

  return suggestion
end

-- ======================
-- Mirror helpers
-- ======================
local function CopyAllPoints(dst, src)
  dst:ClearAllPoints()
  for i = 1, src:GetNumPoints() do
    local p, rel, rp, x, y = src:GetPoint(i)
    dst:SetPoint(p, rel, rp, x, y)
  end
end

local function MirrorFromParent(parent, bf)
  if not parent or not bf then return end
  local w, h = parent:GetSize()
  if w and h and w > 0 and h > 0 then bf:SetSize(w, h) end
  bf:SetScale(parent:GetScale() or 1)
  CopyAllPoints(bf, parent)
end

local function EnsureMirrorHooks(parent, bf)
  if not parent or not bf or bf.__mirrorHooks then return end
  bf.__mirrorHooks = true

  hooksecurefunc(parent, "SetSize",  function() MirrorFromParent(parent, bf) end)
  hooksecurefunc(parent, "SetScale", function() MirrorFromParent(parent, bf) end)
  hooksecurefunc(parent, "SetPoint", function() MirrorFromParent(parent, bf) end)

  parent:HookScript("OnDragStop", function()
    parent:StopMovingOrSizing()
    MirrorFromParent(parent, bf)
  end)
  parent:HookScript("OnSizeChanged", function() MirrorFromParent(parent, bf) end)
  parent:HookScript("OnShow", function() MirrorFromParent(parent, bf) end)

  bf:HookScript("OnShow", function()
    local p = _G.MythicbusFrame
    if p then MirrorFromParent(p, bf) end
  end)
end

-- ======================
-- UI
-- ======================
local BFrame
local RankPips = {}
local ratingTicker

-- layout knobs
local RING_TOP_PAD = 78
local BAR_GAP      = 18
local CARDS_GAP    = 56

local function MakePanelBox(parent, w, h)
  local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  f:SetSize(w, h)
  f:SetBackdrop({
    bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 14,
    insets = { left=3, right=3, top=3, bottom=3 }
  })
  f:SetBackdropColor(0,0,0,0.45)
  f:SetBackdropBorderColor(0.8,0.7,0.2,0.9)
  return f
end

local function MakeIconSlot(parent, size)
  local slot = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  slot:SetSize(GetRankSlotWidth(size), size)
  slot:SetBackdrop({
    bgFile   = "Interface/Buttons/UI-Quickslot2",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = false, edgeSize = 12, insets = { left=2, right=2, top=2, bottom=2 }
  })
  slot:SetBackdropColor(0,0,0,0.25)
  slot:SetBackdropBorderColor(0.7,0.6,0.2,0.8)

  slot.tex = slot:CreateTexture(nil, "ARTWORK")
  FitRankTexture(slot)
  slot.tex:Hide()
  return slot
end

local function MakeRankPip(parent, i)
  local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
  b:SetSize(GetRankSlotWidth(PIP_SIZE), PIP_SIZE)
  b:SetBackdrop({
    bgFile   = "Interface/Buttons/UI-Quickslot2",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = false, edgeSize = 12, insets = { left=2, right=2, top=2, bottom=2 }
  })
  b:SetBackdropColor(0,0,0,0.2)
  b:SetBackdropBorderColor(0.7,0.6,0.2,0.8)

  b.txt = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  b.txt:SetPoint("CENTER", 0, 0)
  b.txt:SetText(tostring(i))

  b.tex = b:CreateTexture(nil, "ARTWORK")
  FitRankTexture(b)
  b.tex:SetTexture(GetRankImagePath(i))
  b.tex:SetTexCoord(0, 1, 0, 1)

  b.txt:Hide()

  b.check = b:CreateTexture(nil, "OVERLAY")
  b.check:SetTexture("Interface/Buttons/UI-CheckBox-Check")
  b.check:SetSize(20, 20)
  b.check:SetPoint("BOTTOMRIGHT", 4, -4)
  b.check:Hide()

  return b
end

local function LayoutRankPips()
  if not (BFrame and BFrame.progressBar) then return end
  local bar = BFrame.progressBar
  local w = bar:GetWidth()
  if not w or w <= 10 then return end

  for i=1,NUM_RANKS do
    local pip = RankPips[i]
    local r = RANKS[i]
    if pip and r then
      pip:ClearAllPoints()
      local x = (Clamp(r.min, 0, RATING_CAP) / RATING_CAP) * w
      pip:SetPoint("CENTER", bar, "LEFT", x, 0)
    end
  end
end

local function MakeRankSummaryCard(parent, titleText)
  local c = MakePanelBox(parent, 320, 170)

  c.header = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  c.header:SetPoint("TOPLEFT", 14, -10)
  c.header:SetText(titleText or "Rank")

  c.iconSlot = MakeIconSlot(c, CARD_ICON_SIZE)
  c.iconSlot:SetPoint("TOPLEFT", 14, -36)

  c.rankName = c:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  c.rankName:SetPoint("TOPLEFT", c.iconSlot, "TOPRIGHT", 12, -6)
  c.rankName:SetJustifyH("LEFT")

  c.repairs = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  c.repairs:SetPoint("TOPLEFT", c.rankName, "BOTTOMLEFT", 0, -2)

  c.range = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  c.range:SetPoint("TOPLEFT", c.repairs, "BOTTOMLEFT", 0, -2)

  c.status = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  c.status:SetPoint("TOPLEFT", c.range, "BOTTOMLEFT", 0, -2)

  c.bar = CreateFrame("StatusBar", nil, c)
  c.bar:SetPoint("BOTTOMLEFT", 14, 14)
  c.bar:SetPoint("BOTTOMRIGHT", -14, 14)
  c.bar:SetHeight(12)
  c.bar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
  c.bar.bg = c.bar:CreateTexture(nil, "BACKGROUND")
  c.bar.bg:SetAllPoints()
  c.bar.bg:SetColorTexture(0.1,0.1,0.1,0.8)

  return c
end

StaticPopupDialogs["MBUS_COPY_SUGGESTED_KEY"] = StaticPopupDialogs["MBUS_COPY_SUGGESTED_KEY"] or {
  text = "Copy suggested key",
  button1 = OKAY,
  hasEditBox = true,
  editBoxWidth = 260,
  whileDead = true,
  hideOnEscape = true,
  OnShow = function(self)
    local editBox = self.editBox or self.EditBox
    if editBox then
      editBox:SetText(self.data or "")
      editBox:HighlightText()
      editBox:SetFocus()
    end
  end,
}

local function OpenPremadeDungeonGroups()
  pcall(LoadAddOn, "Blizzard_GroupFinder")

  if PVEFrame_ShowFrame then
    PVEFrame_ShowFrame("GroupFinderFrame")
  elseif ToggleLFDParentFrame then
    ToggleLFDParentFrame()
  elseif PVEFrame then
    PVEFrame:Show()
  end

  if GroupFinderFrame_ShowGroupFrame and LFGListPVEStub then
    pcall(GroupFinderFrame_ShowGroupFrame, LFGListPVEStub)
  end
end

local function GetSuggestionCopyText(suggestion)
  if not suggestion then return "" end
  return ("+%d %s"):format(tonumber(suggestion.targetLevel) or 0, suggestion.name or "")
end

local function CopySuggestedKey(suggestion)
  local text = GetSuggestionCopyText(suggestion)
  if text == "" then return end
  StaticPopup_Show("MBUS_COPY_SUGGESTED_KEY", nil, nil, text)
end

local function MakeSuggestionPanel(parent)
  local p = MakePanelBox(parent, 600, 54)

  p.header = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  p.header:SetPoint("TOPLEFT", 14, -8)
  p.header:SetText("Suggested Next Key")

  p.keyText = p:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  p.keyText:SetPoint("TOPLEFT", 14, -26)
  p.keyText:SetWidth(230)
  p.keyText:SetJustifyH("LEFT")
  p.keyText:SetText("Loading...")

  p.gainText = p:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  p.gainText:SetPoint("TOPLEFT", 300, -28)
  p.gainText:SetWidth(300)
  p.gainText:SetJustifyH("LEFT")
  p.gainText:SetText("")

  p.findButton = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
  p.findButton:SetSize(28, 24)
  p.findButton:SetPoint("TOPRIGHT", -14, -25)
  p.findButton:SetText("")
  p.findButton:SetScript("OnClick", OpenPremadeDungeonGroups)
  p.findButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Find Groups")
    GameTooltip:AddLine("Open Premade Groups for Dungeons & Raids.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  p.findButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

  p.findButton.icon = p.findButton:CreateTexture(nil, "ARTWORK")
  p.findButton.icon:SetSize(18, 18)
  p.findButton.icon:SetPoint("CENTER")
  if not p.findButton.icon.SetAtlas or not pcall(p.findButton.icon.SetAtlas, p.findButton.icon, "groupfinder-eye-frame") then
    p.findButton.icon:SetTexture("Interface\\LFGFrame\\LFG-Eye")
  end

  p.copyButton = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
  p.copyButton:SetSize(44, 22)
  p.copyButton:SetPoint("LEFT", p.keyText, "RIGHT", 4, -1)
  p.copyButton:SetText("Copy")
  p.copyButton:SetScript("OnClick", function(self)
    CopySuggestedKey(self:GetParent().suggestion)
  end)
  p.copyButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Copy Suggested Key")
    GameTooltip:AddLine("Open a copy box for the suggested dungeon and level.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  p.copyButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

  return p
end

local function LayoutBigCards()
  if not (BFrame and BFrame.progressBar and BFrame.cardsArea) then return end

  local w = BFrame.progressBar:GetWidth() or 600
  local arrowGap = 90
  local cardW = math.floor((w - arrowGap) / 2)
  cardW = Clamp(cardW, 280, 420)

  BFrame.currentCard:SetSize(cardW, 170)
  BFrame.nextCard:SetSize(cardW, 170)

  BFrame.currentCard:ClearAllPoints()
  BFrame.nextCard:ClearAllPoints()
  BFrame.midArrow:ClearAllPoints()

  BFrame.currentCard:SetPoint("TOPLEFT", BFrame.cardsArea, "TOPLEFT", 0, 0)
  BFrame.nextCard:SetPoint("TOPRIGHT",  BFrame.cardsArea, "TOPRIGHT", 0, 0)
  BFrame.midArrow:SetPoint("CENTER", BFrame.cardsArea, "CENTER", 0, -10)

  if BFrame.suggestionPanel then
    BFrame.suggestionPanel:SetWidth(w)
    BFrame.suggestionPanel:ClearAllPoints()
    BFrame.suggestionPanel:SetPoint("TOPLEFT", BFrame.cardsArea, "TOPLEFT", 0, -182)
  end
end

local function EnsureRankWindow()
  if BFrame then return BFrame end

  BFrame = CreateFrame("Frame", "MythicbusBountiesFrame", UIParent, "BasicFrameTemplateWithInset")
  BFrame:SetMovable(true); BFrame:EnableMouse(true)
  BFrame:RegisterForDrag("LeftButton")
  BFrame:SetScript("OnDragStart", BFrame.StartMoving)
  BFrame:SetScript("OnDragStop",  BFrame.StopMovingOrSizing)
  BFrame.TitleText:SetText("Mythicbus – Rating Progress")

  local parent = _G.MythicbusFrame
  if parent and parent:GetWidth() then
    MirrorFromParent(parent, BFrame)
  else
    BFrame:SetSize(560, 540)
    BFrame:SetPoint("CENTER")
  end

  -- Score in top-left corner (no bar text)
  BFrame.scoreText = BFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  BFrame.scoreText:SetPoint("TOPLEFT", 20, -52)
  BFrame.scoreText:SetText("Score: 0")

  -- Top rank box
  BFrame.rankRing = MakePanelBox(BFrame, 200, 120)
  BFrame.rankRing:SetPoint("TOP", 0, -RING_TOP_PAD)

  BFrame.rankLabel = BFrame.rankRing:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  BFrame.rankLabel:SetPoint("TOP", 0, -10)
  BFrame.rankLabel:SetText("Guild Rank")

  BFrame.ringIconSlot = MakeIconSlot(BFrame.rankRing, RING_ICON_SIZE)
  BFrame.ringIconSlot:SetPoint("LEFT", 12, -2)

  BFrame.rankNum = BFrame.rankRing:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
  BFrame.rankNum:SetPoint("CENTER", 24, -6)
  BFrame.rankNum:SetText("1")

  BFrame.rankFrac = BFrame.rankRing:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  BFrame.rankFrac:SetPoint("CENTER", 78, -10)
  BFrame.rankFrac:SetText("1/6")

  BFrame.rankName = BFrame.rankRing:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  BFrame.rankName:SetPoint("BOTTOM", 0, 18)
  BFrame.rankName:SetText("Aisle Seat")

  BFrame.repairText = BFrame.rankRing:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  BFrame.repairText:SetPoint("BOTTOM", 0, 4)
  BFrame.repairText:SetText("25g repairs")

  -- Main bar (NO TEXT ON IT)
  BFrame.progressBar = CreateFrame("StatusBar", nil, BFrame)
  BFrame.progressBar:SetPoint("TOPLEFT", 70, -(RING_TOP_PAD + 120 + BAR_GAP))
  BFrame.progressBar:SetPoint("TOPRIGHT", -70, -(RING_TOP_PAD + 120 + BAR_GAP))
  BFrame.progressBar:SetHeight(18)
  BFrame.progressBar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
  BFrame.progressBar.bg = BFrame.progressBar:CreateTexture(nil, "BACKGROUND")
  BFrame.progressBar.bg:SetAllPoints()
  BFrame.progressBar.bg:SetColorTexture(0.08, 0.08, 0.08, 0.9)

  -- rank pips
  for i=1,NUM_RANKS do
    RankPips[i] = MakeRankPip(BFrame, i)
  end

  -- Cards area is constrained to the BAR width => adds padding at frame edges
  BFrame.cardsArea = CreateFrame("Frame", nil, BFrame)
  BFrame.cardsArea:SetPoint("TOPLEFT",  BFrame.progressBar, "BOTTOMLEFT",  0, -CARDS_GAP)
  BFrame.cardsArea:SetPoint("TOPRIGHT", BFrame.progressBar, "BOTTOMRIGHT", 0, -CARDS_GAP)
  BFrame.cardsArea:SetHeight(190)

  BFrame.currentCard = MakeRankSummaryCard(BFrame.cardsArea, "Current Rank")
  BFrame.nextCard    = MakeRankSummaryCard(BFrame.cardsArea, "Next Rank")
  BFrame.suggestionPanel = MakeSuggestionPanel(BFrame.cardsArea)

  -- Arrow between cards
  BFrame.midArrow = CreateFrame("Frame", nil, BFrame.cardsArea)
  BFrame.midArrow:SetSize(60, 60)
  BFrame.midArrow:EnableMouse(false)
  BFrame.midArrow.txt = BFrame.midArrow:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
  BFrame.midArrow.txt:SetPoint("CENTER", 0, 0)
  BFrame.midArrow.txt:SetText("→") -- placeholder (swap to texture later)

  -- resize handling
  BFrame.progressBar:HookScript("OnSizeChanged", function()
    LayoutRankPips()
    LayoutBigCards()
  end)

  BFrame:HookScript("OnShow", function()
    LayoutRankPips()
    LayoutBigCards()
    if updateBountiesUI then updateBountiesUI() end
  end)

  BFrame:HookScript("OnHide", function()
    if ratingTicker then ratingTicker:Cancel(); ratingTicker = nil end
  end)

  if BFrame.CloseButton then
    BFrame.CloseButton:SetScript("OnClick", function() BFrame:Hide() end)
  end

  if parent then EnsureMirrorHooks(parent, BFrame) end

  local mirrorWaiter = CreateFrame("Frame")
  mirrorWaiter:RegisterEvent("PLAYER_ENTERING_WORLD")
  mirrorWaiter:RegisterEvent("ADDON_LOADED")
  mirrorWaiter:SetScript("OnEvent", function(self)
    local p = _G.MythicbusFrame
    if p then
      MirrorFromParent(p, BFrame)
      EnsureMirrorHooks(p, BFrame)
      self:UnregisterAllEvents()
      self:SetScript("OnEvent", nil)
    end
  end)

  BFrame:Hide()
  return BFrame
end

local function FillSuggestionPanel(panel)
  if not panel then return end

  local suggestion = GetSuggestedNextKey()
  if not suggestion then
    panel.suggestion = nil
    panel.keyText:SetText("No season dungeon data yet")
    panel.gainText:SetText("")
    if panel.findButton then panel.findButton:Disable() end
    if panel.copyButton then panel.copyButton:Disable() end
    return
  end

  panel.suggestion = suggestion
  panel.keyText:SetText(("+%d %s"):format(suggestion.targetLevel, suggestion.name))
  if panel.copyButton then
    local x = math.min((panel.keyText:GetStringWidth() or 0) + 8, 232)
    panel.copyButton:ClearAllPoints()
    panel.copyButton:SetPoint("LEFT", panel.keyText, "LEFT", x, -1)
  end

  panel.gainText:SetText(("Estimated Minium increase +%d score"):format(math.floor((suggestion.gain or 0) + 0.5)))
  if panel.findButton then panel.findButton:Enable() end
  if panel.copyButton then panel.copyButton:Enable() end
end

local function FillCurrentCard(card, r, rating)
  SetRankIcon(card.iconSlot, GetRankIndexForRating(rating))

  card.rankName:SetText(r.name or "Unknown")
  card.repairs:SetText(FormatGold(r.repairs))

  if r.max >= 999999 then
    card.range:SetText(("%d+ rating"):format(r.min))
  else
    card.range:SetText(("%d–%d rating"):format(r.min, r.max))
  end

  local idx = GetRankIndexForRating(rating)
  local nextMin = (RANKS[idx + 1] and RANKS[idx + 1].min) or nil
  if nextMin then
    card.status:SetText(("Current • Next in +%d"):format(math.max(0, nextMin - rating)))
  else
    card.status:SetText("Current • Max rank")
  end

  -- REMOVE CURRENT XP BAR (blue bar gone)
  card.bar:Hide()
end

local function FillNextCard(card, nextRank, currentRank, rating)
  if not nextRank then
    SetRankIcon(card.iconSlot, NUM_RANKS)

    card.rankName:SetText("Max Rank")
    card.repairs:SetText("")
    card.range:SetText("")
    card.status:SetText("You're at the top.")
    card.bar:Show()
    card.bar:SetMinMaxValues(0, 1)
    card.bar:SetValue(1)
    card.bar:SetStatusBarColor(0.2, 0.85, 0.2)
    return
  end

  SetRankIcon(card.iconSlot, GetRankIndexForRating(nextRank.min))

  card.rankName:SetText(nextRank.name or "Unknown")
  card.repairs:SetText(FormatGold(nextRank.repairs))

  if nextRank.max >= 999999 then
    card.range:SetText(("%d+ rating"):format(nextRank.min))
  else
    card.range:SetText(("%d–%d rating"):format(nextRank.min, nextRank.max))
  end

  local need = math.max(0, (nextRank.min or 0) - rating)
  if need == 0 then
    card.status:SetText("Unlocked (rank up!)")
  else
    card.status:SetText(("Need +%d rating"):format(need))
  end

  -- NEXT XP BAR: progress toward next rank from current rank min -> nextRank.min
  local spanStart = currentRank.min or 0
  local spanEnd   = nextRank.min or spanStart
  card.bar:Show()
  card.bar:SetMinMaxValues(spanStart, spanEnd)
  card.bar:SetValue(Clamp(rating, spanStart, spanEnd))
  card.bar:SetStatusBarColor(0.95, 0.8, 0.2) -- gold
end

function updateBountiesUI()
  EnsureRankWindow()

  local rating = math.floor(tonumber(GetPlayerMPlusRating()) or 0)
  local ratingClamped = Clamp(rating, 0, RATING_CAP)

  local rankIdx = GetRankIndexForRating(rating)
  local rank = RANKS[rankIdx] or RANKS[1]
  local nextRank = RANKS[rankIdx + 1]

  -- Score top-left
  if BFrame.scoreText then
    BFrame.scoreText:SetText(("Score: %d"):format(rating))
  end

  -- Top ring
  SetRankIcon(BFrame.ringIconSlot, rankIdx)
  BFrame.rankNum:SetText(tostring(rankIdx))
  BFrame.rankFrac:SetText(("%d/%d"):format(rankIdx, NUM_RANKS))
  BFrame.rankName:SetText(rank.name or "Unknown")
  BFrame.repairText:SetText(FormatGold(rank.repairs))

  -- Main bar (no overlay text)
  BFrame.progressBar:SetMinMaxValues(0, RATING_CAP)
  BFrame.progressBar:SetValue(ratingClamped)
  BFrame.progressBar:SetStatusBarColor(0.95, 0.8, 0.2)

  -- Pips
  for i=1,NUM_RANKS do
    local pip = RankPips[i]
    local r = RANKS[i]
    if pip and r then
      local achieved = rating >= (r.min or 0)
      pip.check:SetShown(achieved)
      if i == rankIdx then
        pip:SetBackdropBorderColor(1.0, 0.9, 0.2, 1.0)
      else
        pip:SetBackdropBorderColor(0.7, 0.6, 0.2, 0.8)
      end
    end
  end

  -- Cards
  FillCurrentCard(BFrame.currentCard, rank, rating)
  FillNextCard(BFrame.nextCard, nextRank, rank, rating)
  FillSuggestionPanel(BFrame.suggestionPanel)

  -- Arrow hide at max
  if nextRank then
    BFrame.midArrow:Show()
  else
    BFrame.midArrow:Hide()
  end

  LayoutRankPips()
  LayoutBigCards()
end

local function EnsureRatingTicker()
  if ratingTicker then return end
  ratingTicker = C_Timer.NewTicker(2.0, function()
    if BFrame and BFrame:IsShown() then updateBountiesUI() end
  end)
end

-- ======================
-- Tabs-as-Nav
-- ======================
local function SetTabs(frame, num)
  if PanelTemplates_SetNumTabs then PanelTemplates_SetNumTabs(frame, num) end
end

local function EnsureMainTabs()
  local parent = _G.MythicbusFrame
  if not parent then return end

  local tab1 = _G.MythicbusFrameTab1
  if not tab1 then
    tab1 = CreateFrame("Button", "MythicbusFrameTab1", parent, "PanelTopTabButtonTemplate")
    tab1:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 30)
    tab1:SetText("Queue")
  end

  local tab2 = _G.MythicbusFrameTab2
  if not tab2 then
    tab2 = CreateFrame("Button", "MythicbusFrameTab2", parent, "PanelTopTabButtonTemplate")
    tab2:SetPoint("LEFT", tab1, "RIGHT", -14, 0)
    tab2:SetText("Ranks")
  end

  local tab3 = _G.MythicbusFrameTab3
  if not tab3 then
    tab3 = CreateFrame("Button", "MythicbusFrameTab3", parent, "PanelTopTabButtonTemplate")
    tab3:SetPoint("LEFT", tab2, "RIGHT", -14, 0)
    tab3:SetText("Talents")
  end

  local tab4 = _G.MythicbusFrameTab4
  if not tab4 then
    tab4 = CreateFrame("Button", "MythicbusFrameTab4", parent, "PanelTopTabButtonTemplate")
    tab4:SetPoint("LEFT", tab3, "RIGHT", -14, 0)
    tab4:SetText("Guides")
  end

  tab3:SetScript("OnClick", function() if NS.ShowTalents then NS.ShowTalents() end end)
  tab4:SetScript("OnClick", function() if NS.ShowGuides then NS.ShowGuides() end end)

  tab1:SetFrameStrata("HIGH"); tab2:SetFrameStrata("HIGH")
  SetTabs(parent, 4)

  tab1:SetScript("OnClick", function()
    local bf = EnsureRankWindow()
    bf:Hide()
    parent:Show(); parent:Raise()
    if PanelTemplates_SetTab then PanelTemplates_SetTab(parent, 1) end
  end)

  tab2:SetScript("OnClick", function()
    local bf = EnsureRankWindow()
    MirrorFromParent(parent, bf)
    updateBountiesUI()
    EnsureRatingTicker()
    parent:Hide()
    bf:Show(); bf:Raise()
    if PanelTemplates_SetTab then PanelTemplates_SetTab(parent, 2) end
    if PanelTemplates_SetTab then PanelTemplates_SetTab(bf, 2) end
  end)
end

local function EnsureRankTabs()
  local bf = EnsureRankWindow()

  local btab1 = _G.MythicbusBountiesFrameTab1
  if not btab1 then
    btab1 = CreateFrame("Button", "MythicbusBountiesFrameTab1", bf, "PanelTopTabButtonTemplate")
    btab1:SetPoint("TOPLEFT", bf, "TOPLEFT", 0, 30)
    btab1:SetText("Queue")
  end

  local btab2 = _G.MythicbusBountiesFrameTab2
  if not btab2 then
    btab2 = CreateFrame("Button", "MythicbusBountiesFrameTab2", bf, "PanelTopTabButtonTemplate")
    btab2:SetPoint("LEFT", btab1, "RIGHT", -14, 0)
    btab2:SetText("Ranks")
  end

  local btab3 = _G.MythicbusBountiesFrameTab3
  if not btab3 then
    btab3 = CreateFrame("Button", "MythicbusBountiesFrameTab3", bf, "PanelTopTabButtonTemplate")
    btab3:SetPoint("LEFT", btab2, "RIGHT", -14, 0)
    btab3:SetText("Talents")
  end

  local btab4 = _G.MythicbusBountiesFrameTab4
  if not btab4 then
    btab4 = CreateFrame("Button", "MythicbusBountiesFrameTab4", bf, "PanelTopTabButtonTemplate")
    btab4:SetPoint("LEFT", btab3, "RIGHT", -14, 0)
    btab4:SetText("Guides")
  end

  btab4:SetScript("OnClick", function() bf:Hide(); if NS.ShowGuides then NS.ShowGuides() end end)
  btab3:SetScript("OnClick", function() bf:Hide(); if NS.ShowTalents then NS.ShowTalents() end end)

  btab1:SetFrameStrata("HIGH"); btab2:SetFrameStrata("HIGH")
  SetTabs(bf, 4)

  btab1:SetScript("OnClick", function()
    bf:Hide()
    local parent = _G.MythicbusFrame
    if parent then
      parent:Show(); parent:Raise()
      if PanelTemplates_SetTab then PanelTemplates_SetTab(parent, 1) end
    end
  end)

  btab2:SetScript("OnClick", function()
    updateBountiesUI()
    EnsureRatingTicker()
    if PanelTemplates_SetTab then PanelTemplates_SetTab(bf, 2) end
  end)
end

function NS.ShowQueue()
  local parent = _G.MythicbusFrame
  EnsureMainTabs(); EnsureRankTabs()
  if parent then parent:Show(); parent:Raise(); if PanelTemplates_SetTab then PanelTemplates_SetTab(parent, 1) end end
  if BFrame then BFrame:Hide() end
  local tf = _G.MythicbusTalentsFrame
  if tf then tf:Hide() end
  local gf = _G.MythicbusGuidesFrame
  if gf then gf:Hide() end
end

function NS.ShowBounties()
  EnsureMainTabs(); EnsureRankTabs()
  local bf = EnsureRankWindow()
  local parent = _G.MythicbusFrame
  if parent then MirrorFromParent(parent, bf); parent:Hide() end
  updateBountiesUI(); EnsureRatingTicker()
  bf:Show(); bf:Raise()
  if PanelTemplates_SetTab then PanelTemplates_SetTab(bf, 2) end
end

NS.ShowRanks = NS.ShowBounties

-- ======================
-- Bootstrap
-- ======================
local function TryWire()
  if not _G.MythicbusFrame then return false end
  EnsureMainTabs()
  EnsureRankTabs()

  if BFrame then
    MirrorFromParent(_G.MythicbusFrame, BFrame)
    EnsureMirrorHooks(_G.MythicbusFrame, BFrame)
  end
  return true
end

if not TryWire() then
  local w = CreateFrame("Frame")
  w:RegisterEvent("PLAYER_LOGIN")
  w:RegisterEvent("PLAYER_ENTERING_WORLD")
  w:RegisterEvent("ADDON_LOADED")
  w:SetScript("OnEvent", function(self)
    if TryWire() then self:UnregisterAllEvents(); self:SetScript("OnEvent", nil) end
  end)
end

-- refresh when score likely changes
local evf = CreateFrame("Frame")
evf:RegisterEvent("PLAYER_LOGIN")
evf:RegisterEvent("PLAYER_ENTERING_WORLD")
evf:RegisterEvent("CHALLENGE_MODE_COMPLETED")
evf:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
evf:SetScript("OnEvent", function()
  if BFrame and BFrame:IsShown() then updateBountiesUI() end
end)

-- slash
SLASH_MBUSBOUNTIES1 = "/mbusbounties"
SLASH_MBUSRANKS1    = "/mbusranks"
SlashCmdList.MBUSBOUNTIES = function() NS.ShowRanks() end
SlashCmdList.MBUSRANKS    = function() NS.ShowRanks() end
