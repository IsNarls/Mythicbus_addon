-- Mythicbus_Bounties.lua
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

local function Clamp(n, a, b)
  if n < a then return a end
  if n > b then return b end
  return n
end

local function FormatGold(g) return ("%dg repairs"):format(tonumber(g) or 0) end

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
  slot:SetSize(size, size)
  slot:SetBackdrop({
    bgFile   = "Interface/Buttons/UI-Quickslot2",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = false, edgeSize = 12, insets = { left=2, right=2, top=2, bottom=2 }
  })
  slot:SetBackdropColor(0,0,0,0.25)
  slot:SetBackdropBorderColor(0.7,0.6,0.2,0.8)

  slot.tex = slot:CreateTexture(nil, "ARTWORK")
  slot.tex:SetAllPoints()
  slot.tex:Hide()
  return slot
end

local function MakeRankPip(parent, i)
  local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
  b:SetSize(26, 26)
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

  b.check = b:CreateTexture(nil, "OVERLAY")
  b.check:SetTexture("Interface/Buttons/UI-CheckBox-Check")
  b.check:SetSize(18, 18)
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

  c.iconSlot = MakeIconSlot(c, 44)
  c.iconSlot:SetPoint("TOPLEFT", 14, -36)

  c.rankName = c:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  c.rankName:SetPoint("TOPLEFT", c.iconSlot, "TOPRIGHT", 12, -2)
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
    BFrame:SetSize(560, 460)
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

  BFrame.ringIconSlot = MakeIconSlot(BFrame.rankRing, 32)
  BFrame.ringIconSlot:SetPoint("LEFT", 14, 0)

  BFrame.rankNum = BFrame.rankRing:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
  BFrame.rankNum:SetPoint("CENTER", 12, -6)
  BFrame.rankNum:SetText("1")

  BFrame.rankFrac = BFrame.rankRing:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  BFrame.rankFrac:SetPoint("CENTER", 70, -10)
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

local function FillCurrentCard(card, r, rating)
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
