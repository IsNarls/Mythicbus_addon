-- Guides/Mythicbus_Guides.lua
-- Guides window scaffold (mirrors Queue frame) + 4-tab nav + dungeon/boss/role viewer
-- + SOURCE CREDIT (via NS.MBUS_GuideSources) + "Full Guide URL" copy button.

local ADDON, NS = ...
pcall(LoadAddOn, "Blizzard_PanelTemplates")
pcall(LoadAddOn, "Blizzard_UIDropDownMenu")

-- ======================
-- Mirror helpers (same pattern as Bounties)
-- ======================
local function CopyAllPoints(dst, src)
  dst:ClearAllPoints()
  for i = 1, src:GetNumPoints() do
    local p, rel, rp, x, y = src:GetPoint(i)
    dst:SetPoint(p, rel, rp, x, y)
  end
end

local function MirrorFromParent(parent, gf)
  if not parent or not gf then return end
  local w, h = parent:GetSize()
  if w and h and w > 0 and h > 0 then gf:SetSize(w, h) end
  gf:SetScale(parent:GetScale() or 1)
  CopyAllPoints(gf, parent)
end

local function EnsureMirrorHooks(parent, gf)
  if not parent or not gf or gf.__mirrorHooks then return end
  gf.__mirrorHooks = true

  hooksecurefunc(parent, "SetSize",  function() MirrorFromParent(parent, gf) end)
  hooksecurefunc(parent, "SetScale", function() MirrorFromParent(parent, gf) end)
  hooksecurefunc(parent, "SetPoint", function() MirrorFromParent(parent, gf) end)

  parent:HookScript("OnDragStop", function()
    parent:StopMovingOrSizing()
    MirrorFromParent(parent, gf)
  end)

  parent:HookScript("OnSizeChanged", function()
    MirrorFromParent(parent, gf)
  end)

  parent:HookScript("OnShow", function()
    MirrorFromParent(parent, gf)
  end)

  gf:HookScript("OnShow", function()
    local p = _G.MythicbusFrame
    if p then MirrorFromParent(p, gf) end
  end)
end

-- ======================
-- Simple UI helpers
-- ======================
local function MakeLabel(parent, text, x, y)
  local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  fs:SetText(text or "")
  return fs
end

local function MakeDropdown(parent, width, x, y)
  local dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
  dd:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  UIDropDownMenu_SetWidth(dd, width or 220)
  UIDropDownMenu_SetText(dd, "Select...")
  return dd
end

local function MakeScrollText(parent, x, y, w, h)
  local sf = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  sf:SetSize(w, h)

  local eb = CreateFrame("EditBox", nil, sf)
  eb:SetMultiLine(true)
  eb:SetFontObject("GameFontHighlight")
  eb:SetWidth(w - 30)
  eb:SetAutoFocus(false)
  eb:EnableMouse(false)
  eb:SetText("Select a dungeon and boss to view mechanics.")
  eb:SetScript("OnEscapePressed", function() eb:ClearFocus() end)

  sf:SetScrollChild(eb)
  return sf, eb
end

-- ======================
-- Copy-to-clipboard popup (safe way to "open" URLs in WoW)
-- ======================
local function MBUS_ShowCopyBox(title, text)
  StaticPopupDialogs["MBUS_COPY_GUIDE_URL"] = StaticPopupDialogs["MBUS_COPY_GUIDE_URL"] or {
    text = "%s",
    button1 = OKAY,
    hasEditBox = true,
    editBoxWidth = 380,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnShow = function(self, data)
      self.text:SetText(data.title or "Copy")
      self.editBox:SetText(data.text or "")
      self.editBox:HighlightText()
      self.editBox:SetFocus()
    end,
  }
  StaticPopup_Show("MBUS_COPY_GUIDE_URL", nil, nil, { title = title, text = text })
end

-- ======================
-- Source lookup (from Guides/Mythicbus_GuidesSources.lua)
-- ======================
local function GetGuideSourceForDungeon(dungeonKey)
  local map = NS.MBUS_GuideSources
  if not map or not dungeonKey then return nil, nil end
  local s = map[dungeonKey]
  if not s then return nil, nil end
  return s.name or "Source", s.url or nil
end

-- ======================
-- Guides window
-- ======================
local GFrame

local function BuildGuidesViewerUI(gf)
  if not gf or gf.__guidesViewerBuilt then return end
  gf.__guidesViewerBuilt = true

  -- Container inside inset
  local inset = gf.Inset or gf
  local container = CreateFrame("Frame", nil, inset)
  container:SetPoint("TOPLEFT", inset, "TOPLEFT", 6, -6)
  container:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -6, 6)
  gf.__guidesContainer = container

  -- Header controls (leave room for top tabs)
  MakeLabel(container, "Dungeon", 12, -18)
  local dungeonDD = MakeDropdown(container, 250, -2, -34)

  MakeLabel(container, "Boss", 300, -18)
  local bossDD = MakeDropdown(container, 250, 286, -34)

  MakeLabel(container, "Role", 580, -18)
  local roleDD = MakeDropdown(container, 140, 566, -34)

  -- SOURCE CREDIT LINE + BUTTON (NEW)
  local credit = container:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  credit:SetPoint("TOPLEFT", container, "TOPLEFT", 12, -68)
  credit:SetText("|cffaaaaaaSource:|r (none)")

  local openBtn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
  openBtn:SetSize(140, 22)
  openBtn:SetPoint("TOPRIGHT", container, "TOPRIGHT", -12, -62)
  openBtn:SetText("Full Guide URL")
  openBtn:Disable()

  openBtn:SetScript("OnClick", function()
    local url = openBtn.__mbusUrl
    if not url or url == "" then return end
    print("|cff33ff99Mythicbus|r Full guide URL: " .. url)
    MBUS_ShowCopyBox("Copy full guide URL", url)
  end)

  -- Text area
  local scroll, textBox = MakeScrollText(container, 12, -88, 740, 340)

  -- Status msg (shows if DB missing)
  local status = container:CreateFontString(nil, "ARTWORK", "GameFontRed")
  status:SetPoint("TOPLEFT", container, "TOPLEFT", 12, -84)
  status:SetText("")
  gf.__guidesStatus = status

  local state = {
    dungeonKey = nil,
    bossIndex  = nil,
    roleMode   = "AUTO", -- AUTO | ALL | TANK | HEALER | DAMAGER
  }

  local function DB()
    return NS.MBUS_GuidesDB
  end

  local function effectiveRole()
    if state.roleMode == "AUTO" then
      local db = DB()
      return (db and db.GetRoleAuto) and db:GetRoleAuto() or "ALL"
    end
    return state.roleMode
  end

  local function updateSourceUI()
    local srcName, srcUrl = GetGuideSourceForDungeon(state.dungeonKey)
    if srcName and srcUrl and srcUrl ~= "" then
      credit:SetText(("|cffaaaaaaSource:|r %s"):format(srcName))
      openBtn.__mbusUrl = srcUrl
      openBtn:Enable()
    else
      credit:SetText("|cffaaaaaaSource:|r (none)")
      openBtn.__mbusUrl = nil
      openBtn:Disable()
    end
  end

  local function refreshText()
    local db = DB()
    if not db or not db.FormatBossText then
      status:SetText("Guides DB not loaded (TOC: GuidesDB -> GuidesData_* -> GuidesSources -> Guides UI).")
      textBox:SetText("No guides loaded yet.")
      updateSourceUI()
      return
    end

    status:SetText("")
    updateSourceUI()

    if not state.dungeonKey or not state.bossIndex then
      textBox:SetText("Select a dungeon and boss to view mechanics.")
      return
    end

    local txt = db:FormatBossText(state.dungeonKey, state.bossIndex, effectiveRole())
    textBox:SetText((txt and txt ~= "") and txt or "No guide text found for that selection.")
    scroll:SetVerticalScroll(0)
  end

  local function rebuildBossDropdown()
    local db = DB()
    UIDropDownMenu_Initialize(bossDD, function(self, level)
      if not db or not db.GetBossList then return end
      local list = db:GetBossList(state.dungeonKey)
      for _, entry in ipairs(list) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = entry.name
        info.checked = (state.bossIndex == entry.index)
        info.func = function()
          state.bossIndex = entry.index
          UIDropDownMenu_SetText(bossDD, entry.name)
          refreshText()
        end
        UIDropDownMenu_AddButton(info, level)
      end
    end)

    if db and db.GetBossList then
      local list = db:GetBossList(state.dungeonKey)
      if list[1] then
        state.bossIndex = list[1].index
        UIDropDownMenu_SetText(bossDD, list[1].name)
      else
        state.bossIndex = nil
        UIDropDownMenu_SetText(bossDD, "Select...")
      end
    else
      state.bossIndex = nil
      UIDropDownMenu_SetText(bossDD, "Select...")
    end
  end

  UIDropDownMenu_Initialize(dungeonDD, function(self, level)
    local db = DB()
    if not db or not db.GetDungeonList then return end
    local list = db:GetDungeonList()
    for _, entry in ipairs(list) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = entry.name
      info.checked = (state.dungeonKey == entry.key)
      info.func = function()
        state.dungeonKey = entry.key
        UIDropDownMenu_SetText(dungeonDD, entry.name)
        rebuildBossDropdown()
        refreshText()
      end
      UIDropDownMenu_AddButton(info, level)
    end
  end)

  UIDropDownMenu_Initialize(roleDD, function(self, level)
    local function add(text, val)
      local info = UIDropDownMenu_CreateInfo()
      info.text = text
      info.checked = (state.roleMode == val)
      info.func = function()
        state.roleMode = val
        UIDropDownMenu_SetText(roleDD, text)
        refreshText()
      end
      UIDropDownMenu_AddButton(info, level)
    end
    add("Auto", "AUTO")
    add("All", "ALL")
    add("Tank", "TANK")
    add("Healer", "HEALER")
    add("DPS", "DAMAGER")
  end)
  UIDropDownMenu_SetText(roleDD, "Auto")

  -- Auto-select first dungeon if available
  local db = DB()
  if db and db.GetDungeonList then
    local list = db:GetDungeonList()
    if list[1] then
      state.dungeonKey = list[1].key
      UIDropDownMenu_SetText(dungeonDD, list[1].name)
      rebuildBossDropdown()
    end
  end
  refreshText()

  -- Refresh when role changes (AUTO mode)
  local ev = CreateFrame("Frame", nil, container)
  ev:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
  ev:RegisterEvent("GROUP_ROSTER_UPDATE")
  ev:RegisterEvent("PLAYER_ENTERING_WORLD")
  ev:SetScript("OnEvent", function()
    if state.roleMode == "AUTO" then refreshText() end
  end)

  -- Expose a small refresh hook if you ever need it
  gf.__RefreshGuidesText = refreshText
end

local function EnsureGuidesWindow()
  if GFrame then return GFrame end

  -- Avoid duplicate-frame crash if a stale file was loaded before
  if _G.MythicbusGuidesFrame then
    GFrame = _G.MythicbusGuidesFrame
  else
    GFrame = CreateFrame("Frame", "MythicbusGuidesFrame", UIParent, "BasicFrameTemplateWithInset")
  end

  GFrame:SetMovable(true)
  GFrame:EnableMouse(true)
  GFrame:RegisterForDrag("LeftButton")
  GFrame:SetClampedToScreen(true)
  GFrame:SetScript("OnDragStart", GFrame.StartMoving)
  GFrame:SetScript("OnDragStop",  GFrame.StopMovingOrSizing)

  if GFrame.TitleText then
    GFrame.TitleText:SetText("Mythicbus – Guides")
  end

  local parent = _G.MythicbusFrame
  if parent and parent:GetWidth() then
    MirrorFromParent(parent, GFrame)
    EnsureMirrorHooks(parent, GFrame)
  else
    GFrame:SetSize(560, 460)
    GFrame:SetPoint("CENTER")
  end

  -- Build the actual viewer UI (dropdowns + scroll text + source UI)
  BuildGuidesViewerUI(GFrame)

  -- If DB/data load later, refresh when shown
  if not GFrame.__mbusShowHooked then
    GFrame.__mbusShowHooked = true
    GFrame:HookScript("OnShow", function()
      if GFrame.__RefreshGuidesText then
        GFrame.__RefreshGuidesText()
      end
    end)
  end

  GFrame:Hide()

  if GFrame.CloseButton then
    GFrame.CloseButton:SetScript("OnClick", function() GFrame:Hide() end)
  end

  return GFrame
end

-- ======================
-- Tabs (Guides frame only)
-- ======================
local function SetTabs(frame, num)
  if PanelTemplates_SetNumTabs then PanelTemplates_SetNumTabs(frame, num) end
end

local function EnsureGuidesTabs()
  local gf = EnsureGuidesWindow()

  local gtab1 = _G.MythicbusGuidesFrameTab1
  if not gtab1 then
    gtab1 = CreateFrame("Button", "MythicbusGuidesFrameTab1", gf, "PanelTopTabButtonTemplate")
    gtab1:SetPoint("TOPLEFT", gf, "TOPLEFT", 0, 30)
    gtab1:SetText("Queue")
  end

  local gtab2 = _G.MythicbusGuidesFrameTab2
  if not gtab2 then
    gtab2 = CreateFrame("Button", "MythicbusGuidesFrameTab2", gf, "PanelTopTabButtonTemplate")
    gtab2:SetPoint("LEFT", gtab1, "RIGHT", -14, 0)
    gtab2:SetText("Ranks")
  end

  local gtab3 = _G.MythicbusGuidesFrameTab3
  if not gtab3 then
    gtab3 = CreateFrame("Button", "MythicbusGuidesFrameTab3", gf, "PanelTopTabButtonTemplate")
    gtab3:SetPoint("LEFT", gtab2, "RIGHT", -14, 0)
    gtab3:SetText("Talents")
  end

  local gtab4 = _G.MythicbusGuidesFrameTab4
  if not gtab4 then
    gtab4 = CreateFrame("Button", "MythicbusGuidesFrameTab4", gf, "PanelTopTabButtonTemplate")
    gtab4:SetPoint("LEFT", gtab3, "RIGHT", -14, 0)
    gtab4:SetText("Guides")
  end

  SetTabs(gf, 4)

  gtab1:SetScript("OnClick", function()
    gf:Hide()
    if NS.ShowQueue then
      NS.ShowQueue()
    else
      local parent = _G.MythicbusFrame
      if parent then parent:Show(); parent:Raise() end
    end
  end)

  gtab2:SetScript("OnClick", function()
    gf:Hide()
    if NS.ShowBounties then NS.ShowBounties() end
  end)

  gtab3:SetScript("OnClick", function()
    gf:Hide()
    if NS.ShowTalents then NS.ShowTalents() end
  end)

  gtab4:SetScript("OnClick", function()
    if PanelTemplates_SetTab then PanelTemplates_SetTab(gf, 4) end
    if gf.__RefreshGuidesText then gf.__RefreshGuidesText() end
  end)
end

-- ======================
-- Public API
-- ======================
function NS.ShowGuides()
  local gf = EnsureGuidesWindow()
  EnsureGuidesTabs()

  local parent = _G.MythicbusFrame
  if parent then parent:Hide() end

  local bf = _G.MythicbusBountiesFrame
  if bf then bf:Hide() end

  local tf = _G.MythicbusTalentsFrame
  if tf then tf:Hide() end

  if parent then MirrorFromParent(parent, gf) end

  gf:Show()
  gf:Raise()
  if PanelTemplates_SetTab then PanelTemplates_SetTab(gf, 4) end
  if gf.__RefreshGuidesText then gf.__RefreshGuidesText() end
end

-- ======================
-- Bootstrap (wait for MythicbusFrame)
-- ======================
local function TryWire()
  if not _G.MythicbusFrame then return false end
  EnsureGuidesWindow()
  EnsureGuidesTabs()
  return true
end

if not TryWire() then
  local w = CreateFrame("Frame")
  w:RegisterEvent("PLAYER_LOGIN")
  w:RegisterEvent("PLAYER_ENTERING_WORLD")
  w:RegisterEvent("ADDON_LOADED")
  w:SetScript("OnEvent", function(self)
    if TryWire() then
      self:UnregisterAllEvents()
      self:SetScript("OnEvent", nil)
    end
  end)
end
