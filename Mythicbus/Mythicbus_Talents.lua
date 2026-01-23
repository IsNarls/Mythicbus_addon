-- Mythicbus_Talents.lua
-- Shows Wowhead talent import strings from Talents.lua (Mythicbus_WowheadResults)
-- Ignores BuildGroup entirely; only uses ButtonLabel + TalentString (+ URL for attribution).
-- UI: Two dropdowns (Class + Spec) instead of one combined dropdown.

local ADDON, NS = ...
pcall(LoadAddOn, "Blizzard_PanelTemplates")
pcall(LoadAddOn, "Blizzard_UIDropDownMenu")

-- ======================
-- Mirror helpers (same pattern as your scaffold)
-- ======================
local function CopyAllPoints(dst, src)
  dst:ClearAllPoints()
  for i = 1, src:GetNumPoints() do
    local p, rel, rp, x, y = src:GetPoint(i)
    dst:SetPoint(p, rel, rp, x, y)
  end
end

local function MirrorFromParent(parent, tf)
  if not parent or not tf then return end
  local w, h = parent:GetSize()
  if w and h and w > 0 and h > 0 then tf:SetSize(w, h) end
  tf:SetScale(parent:GetScale() or 1)
  CopyAllPoints(tf, parent)
end

local function EnsureMirrorHooks(parent, tf)
  if not parent or not tf or tf.__mirrorHooks then return end
  tf.__mirrorHooks = true

  hooksecurefunc(parent, "SetSize",  function() MirrorFromParent(parent, tf) end)
  hooksecurefunc(parent, "SetScale", function() MirrorFromParent(parent, tf) end)
  hooksecurefunc(parent, "SetPoint", function() MirrorFromParent(parent, tf) end)

  parent:HookScript("OnDragStop", function()
    parent:StopMovingOrSizing()
    MirrorFromParent(parent, tf)
  end)

  parent:HookScript("OnSizeChanged", function()
    MirrorFromParent(parent, tf)
  end)

  parent:HookScript("OnShow", function()
    MirrorFromParent(parent, tf)
  end)

  tf:HookScript("OnShow", function()
    local p = _G.MythicbusFrame
    if p then MirrorFromParent(p, tf) end
  end)
end

-- ======================
-- Data access (Talents.lua defines Mythicbus_WowheadResults)
-- ======================
local function GetData()
  return _G.Mythicbus_WowheadResults or {}
end

local function GetImageSize(path)
  local sizes = _G.Mythicbus_ImageSizes
  if not sizes or not path then return nil end
  local name = tostring(path):gsub("\\", "/"):match("([^/]+)$")
  if not name then return nil end
  local info = sizes[name]
  if not info then return nil end
  return tonumber(info.width), tonumber(info.height)
end

-- ======================
-- Class mapping (classFile -> English class name used in your CSV/Lua)
-- ======================
local CLASSFILE_TO_EN = {
  WARRIOR      = "Warrior",
  PALADIN      = "Paladin",
  HUNTER       = "Hunter",
  ROGUE        = "Rogue",
  PRIEST       = "Priest",
  DEATHKNIGHT  = "Death Knight",
  SHAMAN       = "Shaman",
  MAGE         = "Mage",
  WARLOCK      = "Warlock",
  MONK         = "Monk",
  DRUID        = "Druid",
  DEMONHUNTER  = "Demon Hunter",
  EVOKER       = "Evoker",
}

local function GetPlayerClassSpec_EN()
  local _, classFile = UnitClass("player")
  local classEN = classFile and CLASSFILE_TO_EN[classFile] or nil

  local specName = nil
  if GetSpecialization and GetSpecializationInfo then
    local specIndex = GetSpecialization()
    if specIndex then
      local _, name = GetSpecializationInfo(specIndex)
      specName = name
    end
  end
  return classEN, specName
end

local function Key(className, specName)
  return tostring(className or "") .. "||" .. tostring(specName or "")
end

-- ======================
-- Index: class list + specs per class + builds per class/spec
-- ======================
local INDEX
local function BuildIndex()
  if INDEX then return INDEX end

  INDEX = {
    classes = {},               -- ordered list of class names
    specsByClass = {},          -- className -> ordered list of spec names
    byKey = {},                 -- "class||spec" -> build rows
  }

  local classSeen = {}
  local specSeenByClass = {}

  for _, r in ipairs(GetData()) do
    local c = r.Class
    local s = r.Spec
    if c and s then
      local k = Key(c, s)
      if not INDEX.byKey[k] then INDEX.byKey[k] = {} end
      table.insert(INDEX.byKey[k], r)

      if not classSeen[c] then
        classSeen[c] = true
        table.insert(INDEX.classes, c)
      end

      specSeenByClass[c] = specSeenByClass[c] or {}
      if not specSeenByClass[c][s] then
        specSeenByClass[c][s] = true
        INDEX.specsByClass[c] = INDEX.specsByClass[c] or {}
        table.insert(INDEX.specsByClass[c], s)
      end
    end
  end

  table.sort(INDEX.classes)

  for _, c in ipairs(INDEX.classes) do
    if INDEX.specsByClass[c] then
      table.sort(INDEX.specsByClass[c])
    end
  end

  return INDEX
end

-- ======================
-- UI state
-- ======================
local TFrame
local UI = {
  selectedClass = nil,
  selectedSpec = nil,
  rows = {},

  classDropdown = nil,
  specDropdown = nil,
}

local ROW_HEIGHT = 40
local ROW_GAP = 4

local function SafeTrim(s)
  if not s then return "" end
  return (tostring(s):gsub("^%s+",""):gsub("%s+$",""))
end

local function BuildImagePath(p)
  if not p or p == "" then return nil end
  p = tostring(p):gsub("\\", "/")
  p = p:gsub("%.png$", ".tga")
  if p:match("^Interface/") then
    return p:gsub("/", "\\")
  end
  return ("Interface\\AddOns\\Mythicbus\\%s"):format(p:gsub("/", "\\"))
end

local function SetCopyBox(text, title)
  if not UI.copyTitle or not UI.copyBox then return end
  UI.copyTitle:SetText(title or "Copy")
  UI.copyBox:SetText(text or "")
  UI.copyBox:HighlightText(0)
  UI.copyBox:SetFocus()
end

local function GetBuildsForSelected()
  if not UI.selectedClass or not UI.selectedSpec then return {} end
  local idx = BuildIndex()
  return idx.byKey[Key(UI.selectedClass, UI.selectedSpec)] or {}
end

-- ======================
-- Window
-- ======================
local function EnsureTalentsWindow()
  if TFrame then return TFrame end

  TFrame = CreateFrame("Frame", "MythicbusTalentsFrame", UIParent, "BasicFrameTemplateWithInset")
  TFrame:SetMovable(true)
  TFrame:EnableMouse(true)
  TFrame:RegisterForDrag("LeftButton")
  TFrame:SetClampedToScreen(true)
  TFrame:SetScript("OnDragStart", TFrame.StartMoving)
  TFrame:SetScript("OnDragStop",  TFrame.StopMovingOrSizing)
  TFrame.TitleText:SetText("Mythicbus - Talents")

  local parent = _G.MythicbusFrame
  if parent and parent:GetWidth() then
    MirrorFromParent(parent, TFrame)
    EnsureMirrorHooks(parent, TFrame)
  else
    TFrame:SetSize(820, 540)
    TFrame:SetPoint("CENTER")
  end

  -- Detected class/spec line
  local detected = TFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  detected:SetPoint("TOPLEFT", 16, -38)
  detected:SetText("Detected: (unknown)")
  UI.detectedText = detected

  -- Class dropdown
  local cLabel = TFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  cLabel:SetPoint("TOPLEFT", detected, "BOTTOMLEFT", 0, -10)
  cLabel:SetText("Class:")

  local cdd = CreateFrame("Frame", "MythicbusTalentsClassDropdown", TFrame, "UIDropDownMenuTemplate")
  cdd:SetPoint("LEFT", cLabel, "RIGHT", -8, -2)
  UI.classDropdown = cdd

  -- Spec dropdown (next to class)
  local sLabel = TFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  sLabel:SetPoint("LEFT", cdd, "RIGHT", -8, 2)
  sLabel:SetText("Spec:")

  local sdd = CreateFrame("Frame", "MythicbusTalentsSpecDropdown", TFrame, "UIDropDownMenuTemplate")
  sdd:SetPoint("LEFT", sLabel, "RIGHT", -8, -2)
  UI.specDropdown = sdd

  -- Scroll list of builds
  local scroll = CreateFrame("ScrollFrame", nil, TFrame, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 16, -110)
  scroll:SetPoint("BOTTOMRIGHT", -36, 120)

  local content = CreateFrame("Frame", nil, scroll)
  content:SetSize(1, 1)
  scroll:SetScrollChild(content)
  UI.scroll = scroll
  UI.content = content

  -- keep content width synced (prevents collapsed rows/buttons)
  local function SyncContentWidth()
    local w = scroll:GetWidth()
    if w and w > 50 then
      content:SetWidth(w - 28) -- scrollbar + padding
    end
  end
  scroll:HookScript("OnShow", SyncContentWidth)
  scroll:HookScript("OnSizeChanged", SyncContentWidth)
  SyncContentWidth()

  -- Copy box title + hint
  local copyTitle = TFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  copyTitle:SetPoint("BOTTOMLEFT", 16, 92)
  copyTitle:SetText("Copy")
  UI.copyTitle = copyTitle

  local hint = TFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  hint:SetPoint("BOTTOMLEFT", copyTitle, "TOPLEFT", 0, 2)
  hint:SetText("Pick a class/spec, then click a build to load its talent string below (Ctrl+C). Wowhead loads the source URL.")
  UI.hintText = hint

  -- Copy box (multiline) in a scroll frame
  local copyScroll = CreateFrame("ScrollFrame", nil, TFrame, "UIPanelScrollFrameTemplate")
  copyScroll:SetPoint("BOTTOMLEFT", 16, 16)
  copyScroll:SetPoint("BOTTOMRIGHT", -36, 16)
  copyScroll:SetHeight(70)

  local eb = CreateFrame("EditBox", nil, copyScroll)
  eb:SetMultiLine(true)
  eb:SetAutoFocus(false)
  eb:SetFontObject("ChatFontNormal")
  eb:SetWidth(1)
  eb:SetHeight(1)
  eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  eb:SetScript("OnEditFocusGained", function(self) self:HighlightText(0) end)

  copyScroll:SetScrollChild(eb)
  UI.copyBox = eb

  copyScroll:HookScript("OnSizeChanged", function(self)
    local w = self:GetWidth()
    if w and w > 40 then eb:SetWidth(w - 26) end
  end)

  TFrame:Hide()
  if TFrame.CloseButton then
    TFrame.CloseButton:SetScript("OnClick", function() TFrame:Hide() end)
  end

  return TFrame
end

-- ======================
-- Build rows (one row per ButtonLabel)
-- ======================
local function EnsureRow(i)
  if UI.rows[i] then return UI.rows[i] end
  local content = UI.content
  if not content then return nil end

  local row = CreateFrame("Frame", nil, content)
  row:SetHeight(ROW_HEIGHT)
  row:SetPoint("TOPLEFT", 0, 0)
  row:SetPoint("TOPRIGHT", 0, 0)

  row.bg = row:CreateTexture(nil, "BACKGROUND")
  row.bg:SetAllPoints(true)
  row.bg:SetColorTexture(0.1, 0.1, 0.1, 0.25)

  -- Wowhead button pinned to the right
  row.wowheadBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
  row.wowheadBtn:SetSize(90, 22)
  row.wowheadBtn:SetPoint("RIGHT", -8, 0)
  row.wowheadBtn:SetText("Wowhead")

  -- "Source:" label just to the left of Wowhead button
  row.sourceText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  row.sourceText:SetPoint("RIGHT", row.wowheadBtn, "LEFT", -10, 0)
  row.sourceText:SetText("|cffaaaaaaSource:|r")

  -- Main build button fills remaining space
  row.buildBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
  row.buildBtn:SetPoint("LEFT", 8, 0)
  row.buildBtn:SetPoint("RIGHT", row.sourceText, "LEFT", -10, 0)
  row.buildBtn:SetHeight(ROW_HEIGHT - 8)
  row.buildBtn:SetText("Copy Build")
  if row.buildBtn.Left then row.buildBtn.Left:Hide() end
  if row.buildBtn.Middle then row.buildBtn.Middle:Hide() end
  if row.buildBtn.Right then row.buildBtn.Right:Hide() end
  local normal = row.buildBtn:GetNormalTexture()
  if normal then normal:SetTexture(nil); normal:Hide() end
  local pushed = row.buildBtn:GetPushedTexture()
  if pushed then pushed:SetTexture(nil); pushed:Hide() end
  local highlight = row.buildBtn:GetHighlightTexture()
  if highlight then highlight:SetTexture(nil); highlight:Hide() end
  row.buildTex = row.buildBtn:CreateTexture(nil, "BACKGROUND")
  row.buildTex:Hide()

  UI.rows[i] = row
  return row
end

local function RefreshList()
  if not UI.content then return end

  -- keep content width synced in case frame was resized
  if UI.scroll and UI.content then
    local w = UI.scroll:GetWidth()
    if w and w > 50 then UI.content:SetWidth(w - 28) end
  end

  local builds = GetBuildsForSelected()

  local totalHeight = 0
  for i = 1, #UI.rows do UI.rows[i]:Hide() end

  if #builds == 0 then
    SetCopyBox("", "No builds found for this Class/Spec")
    return
  end

  for i, b in ipairs(builds) do
    local row = EnsureRow(i)
    row:Show()
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", 0, -totalHeight)
    row:SetPoint("TOPRIGHT", 0, -totalHeight)
    local label = SafeTrim(b.ButtonLabel)
    if label == "" then label = "Copy Build" end

    local imgW = tonumber(b.ImageWidth)
    local imgH = tonumber(b.ImageHeight)
    if (not imgW or not imgH) and b.ImagePath then
      local sw, sh = GetImageSize(b.ImagePath)
      imgW = imgW or sw
      imgH = imgH or sh
    end
    local rowHeight = ROW_HEIGHT
    if imgH and imgH > 0 and not (imgW == 618 and imgH == 37) then
      rowHeight = math.max(ROW_HEIGHT, imgH + 8)
    end
    row:SetHeight(rowHeight)
    row.buildBtn:SetHeight(rowHeight - 8)

    local img = BuildImagePath(b.ImagePath)
    if img then
      row.buildTex:ClearAllPoints()
      row.buildTex:SetTexture(img)
      row.buildTex:Show()
      row.buildBtn:SetText("")
      if row.buildBtn.Left then row.buildBtn.Left:Hide() end
      if row.buildBtn.Middle then row.buildBtn.Middle:Hide() end
      if row.buildBtn.Right then row.buildBtn.Right:Hide() end

      if imgW and imgH and imgW > 0 and imgH > 0 then
        local btnW, btnH = row.buildBtn:GetSize()
        if btnW and btnH and btnW > 0 and btnH > 0 then
          if imgW == 618 and imgH == 37 then
            row.buildTex:SetAllPoints(true)
          else
            local scale = math.min(1, btnW / imgW, btnH / imgH)
            local targetW = math.floor((imgW * scale) + 0.5)
            local targetH = math.floor((imgH * scale) + 0.5)
            row.buildTex:SetPoint("LEFT", row.buildBtn, "LEFT", 4, 0)
            row.buildTex:SetSize(targetW, targetH)
          end
        else
          row.buildTex:SetAllPoints(true)
        end
      else
        row.buildTex:SetAllPoints(true)
      end

      if not row.buildTex:GetTexture() then
        row.buildTex:SetTexture(nil)
        row.buildTex:Hide()
        row.buildBtn:SetText(label)
        if row.buildBtn.Left then row.buildBtn.Left:Show() end
        if row.buildBtn.Middle then row.buildBtn.Middle:Show() end
        if row.buildBtn.Right then row.buildBtn.Right:Show() end
      end
    else
      row.buildTex:SetTexture(nil)
      row.buildTex:Hide()
      row.buildBtn:SetText(label)
      if row.buildBtn.Left then row.buildBtn.Left:Show() end
      if row.buildBtn.Middle then row.buildBtn.Middle:Show() end
      if row.buildBtn.Right then row.buildBtn.Right:Show() end
    end

    row.buildBtn:SetScript("OnClick", function()
      SetCopyBox(b.TalentString or "", label)
    end)

    row.wowheadBtn:SetScript("OnClick", function()
      SetCopyBox(b.URL or "", "Wowhead Source URL")
    end)

    totalHeight = totalHeight + rowHeight + ROW_GAP
  end

  UI.content:SetHeight(math.max(1, totalHeight - ROW_GAP))
end

-- ======================
-- Dropdowns: Class then Spec
-- ======================
local function InitSpecDropdown()
  local sdd = UI.specDropdown
  if not sdd or not UIDropDownMenu_Initialize then return end

  local idx = BuildIndex()
  local className = UI.selectedClass
  local specs = (className and idx.specsByClass[className]) or {}

  UIDropDownMenu_Initialize(sdd, function(self, level)
    local info = UIDropDownMenu_CreateInfo()

    if not className or #specs == 0 then
      info.text = "(no specs)"
      info.disabled = true
      info.func = nil
      UIDropDownMenu_AddButton(info, level)
      return
    end

    for _, specName in ipairs(specs) do
      info.text = specName
      info.checked = (UI.selectedSpec == specName)
      info.disabled = false
      info.func = function()
        UI.selectedSpec = specName
        UIDropDownMenu_SetText(sdd, specName)
        RefreshList()
      end
      UIDropDownMenu_AddButton(info, level)
    end
  end)

  UIDropDownMenu_SetWidth(sdd, 170)
  UIDropDownMenu_JustifyText(sdd, "LEFT")

  -- set display text (or placeholder)
  if UI.selectedSpec then
    UIDropDownMenu_SetText(sdd, UI.selectedSpec)
  else
    UIDropDownMenu_SetText(sdd, "(pick spec)")
  end
end

local function InitClassDropdown()
  local cdd = UI.classDropdown
  if not cdd or not UIDropDownMenu_Initialize then return end

  local idx = BuildIndex()

  UIDropDownMenu_Initialize(cdd, function(self, level)
    local info = UIDropDownMenu_CreateInfo()
    for _, className in ipairs(idx.classes) do
      info.text = className
      info.checked = (UI.selectedClass == className)
      info.func = function()
        UI.selectedClass = className

        -- When changing class, auto-pick the first available spec for that class
        local specs = idx.specsByClass[className] or {}
        UI.selectedSpec = specs[1]

        UIDropDownMenu_SetText(cdd, className)
        InitSpecDropdown() -- rebuild spec menu for this class
        if UI.selectedSpec then
          UIDropDownMenu_SetText(UI.specDropdown, UI.selectedSpec)
        else
          UIDropDownMenu_SetText(UI.specDropdown, "(pick spec)")
        end

        RefreshList()
      end
      UIDropDownMenu_AddButton(info, level)
    end
  end)

  UIDropDownMenu_SetWidth(cdd, 170)
  UIDropDownMenu_JustifyText(cdd, "LEFT")

  if UI.selectedClass then
    UIDropDownMenu_SetText(cdd, UI.selectedClass)
  else
    UIDropDownMenu_SetText(cdd, "(pick class)")
  end
end

local function SetDetectedAndDefaultSelection()
  local classEN, specName = GetPlayerClassSpec_EN()

  if UI.detectedText then
    if classEN and specName then
      UI.detectedText:SetText(("Detected: |cffffffff%s|r - |cffffffff%s|r"):format(classEN, specName))
    elseif classEN then
      UI.detectedText:SetText(("Detected: |cffffffff%s|r - |cffff6666(no spec detected)|r"):format(classEN))
    else
      UI.detectedText:SetText("Detected: |cffff6666(unknown)|r")
    end
  end

  local idx = BuildIndex()

  -- Default: detected class/spec if present in dataset
  local defaultClass, defaultSpec = nil, nil
  if classEN and idx.specsByClass[classEN] then
    defaultClass = classEN
    if specName and idx.byKey[Key(classEN, specName)] then
      defaultSpec = specName
    else
      defaultSpec = idx.specsByClass[classEN][1]
    end
  end

  -- Fallback: first class/spec in dataset
  if not defaultClass then
    defaultClass = idx.classes[1]
    defaultSpec = defaultClass and idx.specsByClass[defaultClass] and idx.specsByClass[defaultClass][1] or nil
  end

  UI.selectedClass = defaultClass
  UI.selectedSpec  = defaultSpec
end

-- ======================
-- Tabs (same 4-tab navigation you already use)
-- ======================
local function SetTabs(frame, num)
  if PanelTemplates_SetNumTabs then PanelTemplates_SetNumTabs(frame, num) end
end

local function EnsureTalentsTabs()
  local tf = EnsureTalentsWindow()

  local ttab1 = _G.MythicbusTalentsFrameTab1
  if not ttab1 then
    ttab1 = CreateFrame("Button", "MythicbusTalentsFrameTab1", tf, "PanelTopTabButtonTemplate")
    ttab1:SetPoint("TOPLEFT", tf, "TOPLEFT", 0, 30)
    ttab1:SetText("Queue")
  end

  local ttab2 = _G.MythicbusTalentsFrameTab2
  if not ttab2 then
    ttab2 = CreateFrame("Button", "MythicbusTalentsFrameTab2", tf, "PanelTopTabButtonTemplate")
    ttab2:SetPoint("LEFT", ttab1, "RIGHT", -14, 0)
    ttab2:SetText("Ranks")
  end

  local ttab3 = _G.MythicbusTalentsFrameTab3
  if not ttab3 then
    ttab3 = CreateFrame("Button", "MythicbusTalentsFrameTab3", tf, "PanelTopTabButtonTemplate")
    ttab3:SetPoint("LEFT", ttab2, "RIGHT", -14, 0)
    ttab3:SetText("Talents")
  end

  local ttab4 = _G.MythicbusTalentsFrameTab4
  if not ttab4 then
    ttab4 = CreateFrame("Button", "MythicbusTalentsFrameTab4", tf, "PanelTopTabButtonTemplate")
    ttab4:SetPoint("LEFT", ttab3, "RIGHT", -14, 0)
    ttab4:SetText("Guides")
  end

  SetTabs(tf, 4)

  ttab1:SetScript("OnClick", function()
    tf:Hide()
    if NS.ShowQueue then
      NS.ShowQueue()
    else
      local parent = _G.MythicbusFrame
      if parent then parent:Show(); parent:Raise() end
    end
  end)

  ttab2:SetScript("OnClick", function()
    tf:Hide()
    if NS.ShowBounties then NS.ShowBounties() end
  end)

  ttab3:SetScript("OnClick", function()
    if PanelTemplates_SetTab then PanelTemplates_SetTab(tf, 3) end
  end)

  ttab4:SetScript("OnClick", function()
    tf:Hide()
    if NS.ShowGuides then NS.ShowGuides() end
  end)
end

-- ======================
-- Public API
-- ======================
function NS.ShowTalents()
  local tf = EnsureTalentsWindow()
  EnsureTalentsTabs()

  local parent = _G.MythicbusFrame
  if parent then parent:Hide() end

  local bf = _G.MythicbusBountiesFrame
  if bf then bf:Hide() end

  local gf = _G.MythicbusGuidesFrame
  if gf then gf:Hide() end

  if parent then MirrorFromParent(parent, tf) end

  -- Rebuild index in case Talents.lua changed
  INDEX = nil

  SetDetectedAndDefaultSelection()
  InitClassDropdown()
  InitSpecDropdown()

  -- set dropdown texts
  if UI.selectedClass then UIDropDownMenu_SetText(UI.classDropdown, UI.selectedClass) end
  if UI.selectedSpec then UIDropDownMenu_SetText(UI.specDropdown, UI.selectedSpec) end

  RefreshList()

  tf:Show()
  tf:Raise()
  if PanelTemplates_SetTab then PanelTemplates_SetTab(tf, 3) end
end

-- Optional: slash command for quick testing
SLASH_MBUS_TALENTS1 = "/mbtalents"
SlashCmdList.MBUS_TALENTS = function()
  if NS and NS.ShowTalents then NS.ShowTalents() end
end

-- ======================
-- Bootstrap (wait for MythicbusFrame)
-- ======================
local function TryWire()
  if not _G.MythicbusFrame then return false end
  EnsureTalentsWindow()
  EnsureTalentsTabs()
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
