local ADDON, NS = ...

-- Load templates safely (no-op if already loaded)
pcall(LoadAddOn, "Blizzard_UIDropDownMenu")
pcall(LoadAddOn, "Blizzard_UIPanelTemplates")
pcall(LoadAddOn, "Blizzard_ChallengesUI")     -- ensure challenge map names
pcall(LoadAddOn, "Blizzard_EncounterJournal") -- harmless fallback

-- ===== Main frame =====
local frame = CreateFrame("Frame", "MythicbusFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(820, 540)
frame:SetPoint("CENTER")
frame.TitleText:SetText("Mythicbus – Interest Queue")
frame:Hide()

-- Movable
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetClampedToScreen(true)
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

-- ========= Utilities =========

-- Safe event register that won't error if an event doesn't exist (Retail vs Classic, etc.)
local function MBUS_SafeRegisterEvent(frame, eventName)
  if C_EventUtils and C_EventUtils.IsEventValid then
    if C_EventUtils.IsEventValid(eventName) then
      frame:RegisterEvent(eventName)
    end
  else
    -- Fallback for very old clients: pcall so invalid events won't throw
    pcall(frame.RegisterEvent, frame, eventName)
  end
end

local function queueEntriesSorted()
  local t = {}
  for name, q in pairs(MythicbusDB.queue or {}) do
    t[#t+1] = { name = name, q = q }
  end
  table.sort(t, function(a,b)
    local ta = a.q.ts or 0
    local tb = b.q.ts or 0
    if ta == tb then return (a.name < b.name) end
    return ta < tb
  end)
  return t
end

local function timeAgoColor(sec)
  if sec < 60 then return ("|cff00ff00%ds|r"):format(sec)
  elseif sec < 300 then return ("|cffffff00%dm|r"):format(math.floor(sec/60))
  else return ("|cffff0000%dm|r"):format(math.floor(sec/60)) end
end

local function wantLetters(str)
  str = (str or "A"):upper()
  if str == "AUTO" or str == "A" then return "A" end
  local set = {}
  if str:find("TANK") then set["T"]=true end
  if str:find("HEAL") then set["H"]=true end
  if str:find("DPS")  then set["D"]=true end
  for ch in str:gmatch("%a") do if ch=="T" or ch=="H" or ch=="D" then set[ch]=true end end
  local out = ""; for _,ch in ipairs({"T","H","D"}) do if set[ch] then out=out..ch end end
  return (out~="" and out) or "A"
end

-- Player full name helper (Name-Realm)
local function MBUS_PlayerFullName()
  local n, r = UnitName("player")
  if not n then return nil end
  if r and r ~= "" then return n.."-"..r end
  return n
end
local PLAYER_NAME = MBUS_PlayerFullName()

-- ===== Cached map name resolver (keeps retrying until names are ready) =====
local MBUS_MapCache, MBUS_Pending = {}, {}
-- Try multiple sources to turn a map id (incl. UiMapIDs like 2441) into a dungeon name
local function _tryGetMapName(id)
  if not id or id == 0 then return nil end
  local n

  -- 1) Challenge Mode name (works when it's a CM/MP map id)
  if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
    n = C_ChallengeMode.GetMapUIInfo(id)
  end

  -- 2) Newer Mythic+ struct
  if (not n or n == "") and C_MythicPlus and C_MythicPlus.GetMapInfo then
    local info = C_MythicPlus.GetMapInfo(id)
    if info and info.name and info.name ~= "" then n = info.name end
  end

  -- 3) Alt Mythic+ name
  if (not n or n == "") and C_MythicPlus and C_MythicPlus.GetMapUIInfo then
    n = C_MythicPlus.GetMapUIInfo(id)
  end

  -- 4) Encounter Journal fallback for UiMapIDs (e.g., 2441 -> instanceID -> name)
  if (not n or n == "") and EJ_GetInstanceForMap and EJ_GetInstanceInfo then
    local instID = EJ_GetInstanceForMap(id)
    if instID and instID > 0 then
      local instName = EJ_GetInstanceInfo(instID)
      if instName and instName ~= "" then n = instName end
    end
  end

  -- 5) World map db last resort
  if (not n or n == "") and C_Map and C_Map.GetMapInfo then
    local mi = C_Map.GetMapInfo(id)
    if mi and mi.name and mi.name ~= "" then n = mi.name end
  end

  return (n and n ~= "") and n or nil
end

local function mapName(id)
  if not id or id == 0 then return "—" end
  if MBUS_MapCache[id] then return MBUS_MapCache[id] end
  local name = _tryGetMapName(id)
  if name then
    MBUS_MapCache[id] = name
    return name
  end
  MBUS_Pending[id] = true -- not ready yet; try again later
  return tostring(id)
end

-- Retry loop to resolve pending IDs & refresh UI when names appear
local MBUS_MapTicker = nil
local function MBUS_RetryPendingMapNames()
  local changed = false
  for id in pairs(MBUS_Pending) do
    local n = _tryGetMapName(id)
    if n then
      MBUS_MapCache[id] = n
      MBUS_Pending[id] = nil
      changed = true
    end
  end
  if changed and NS.RefreshUI then NS.RefreshUI() end
end
local function MBUS_StartMapRetryTicker()
  if MBUS_MapTicker then return end
  local tries = 0
  MBUS_MapTicker = C_Timer.NewTicker(2, function()
    tries = tries + 1
    MBUS_RetryPendingMapNames()
    if tries >= 6 or next(MBUS_Pending) == nil then
      MBUS_MapTicker:Cancel()
      MBUS_MapTicker = nil
    end
  end)
end

-- Owned key / member helpers
local function ownedKeyStr(member)
  if not member or not member.key then return "—" end
  local m, l = member.key.mapID or 0, member.key.level or 0
  if m == 0 or l == 0 then return "—" end
  return ("%s +%d"):format(mapName(m), l)
end
local function memberClassSpec(name)
  local m = (MythicbusDB.members or {})[name]
  if not m then return "—" end
  local spec = m.spec and m.spec ~= "" and m.spec or "—"
  local cls  = m.class or "—"
  return spec .. " " .. cls
end
local function memberILvl(name)
  local m = (MythicbusDB.members or {})[name]
  if m and m.ilvl and m.ilvl > 0 then return tostring(m.ilvl) end
  return "—"
end

-- ========= Guild button (safe) =========
local function MBUS_CreateGuildButton()
  if not CommunitiesFrame or CommunitiesFrame.MBUSButton then return end
  local btn = CreateFrame("Button", nil, CommunitiesFrame, "UIPanelButtonTemplate")
  btn:SetText("Mythicbus")
  btn:SetSize(90, 22)
  btn:SetPoint("TOPLEFT", CommunitiesFrame, "TOPLEFT", 40, 28)
  btn:SetScript("OnClick", function()
    if MythicbusFrame:IsShown() then
      MythicbusFrame:Hide()
    else
      MythicbusFrame:Show()
      if NS.RefreshUI then NS.RefreshUI() end
    end
  end)

  -- minimal fix: clear any "stuck" pushed/highlight state on the next frame
  btn:RegisterForClicks("AnyUp")
  btn:HookScript("OnClick", function(self)
    C_Timer.After(0, function()
      if not self then return end
      if self.SetButtonState then self:SetButtonState("NORMAL") end
      if self.UnlockHighlight then self:UnlockHighlight() end
    end)
  end)

  CommunitiesFrame.MBUSButton = btn
end

local _mbusLoader = CreateFrame("Frame")
_mbusLoader:RegisterEvent("PLAYER_LOGIN")
_mbusLoader:RegisterEvent("ADDON_LOADED")
_mbusLoader:SetScript("OnEvent", function(_, ev, addon)
  if ev == "PLAYER_LOGIN" then
    pcall(LoadAddOn, "Blizzard_Communities")
    C_Timer.After(0, MBUS_CreateGuildButton)
  elseif ev == "ADDON_LOADED" and addon == "Blizzard_Communities" then
    MBUS_CreateGuildButton()
  end
end)

-- ========= Role (multi-select) + Preferred Level/Activity =========
local wantT, wantH, wantD = false, false, false
local function makeRoleCheck(parent, atlas, letter, x)
  local btn = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  btn:SetSize(36, 36)
  btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 16 + (x-1) * 48, -36)
  local tex = btn:CreateTexture(nil, "ARTWORK"); tex:SetAllPoints(); tex:SetAtlas(atlas); btn.icon = tex
  local checked = btn:CreateTexture(nil, "OVERLAY"); checked:SetAllPoints(); checked:SetColorTexture(0,1,0,0.25); btn:SetCheckedTexture(checked)
  btn:SetScript("OnClick", function(self)
    local on = self:GetChecked()
    if letter=="T" then wantT=on elseif letter=="H" then wantH=on else wantD=on end
  end)
  return btn
end
frame.roleButtons = {}
frame.roleButtons[1] = makeRoleCheck(frame, "roleicon-tiny-tank",   "T", 1)
frame.roleButtons[2] = makeRoleCheck(frame, "roleicon-tiny-healer", "H", 2)
frame.roleButtons[3] = makeRoleCheck(frame, "roleicon-tiny-dps",    "D", 3)

-- ====== Delves list (editable) ======
local MBUS_DELVES = {
  "Fungal Folly", "Earthcrawl Mines", "Nightfall Sanctum",
  "The Sinkhole", "Kriegval's Rest", "The Underkeep",
  "Skittering Breach", "The Dread Pit",
}

-- ===== Preferred Level (0, +2..+20 explicitly) =====
local preferredLevel = 0
local levelDD = CreateFrame("Frame", "MBUS_LevelDD", frame, "UIDropDownMenuTemplate")
levelDD:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -86)
UIDropDownMenu_SetWidth(levelDD, 100)
UIDropDownMenu_SetText(levelDD, "0")
local lvlLbl = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
lvlLbl:SetPoint("LEFT", levelDD, "RIGHT", -8, 2)
lvlLbl:SetText("Preferred Level")
UIDropDownMenu_Initialize(levelDD, function(self, level)
  local function choose(val)
    preferredLevel = val
    UIDropDownMenu_SetText(levelDD, (val==0) and "0" or ("+"..val))
    CloseDropDownMenus()
  end
  local info = UIDropDownMenu_CreateInfo(); info.func=function(_,arg1) choose(arg1) end
  info.text,info.arg1,info.checked="0",0,(preferredLevel==0); UIDropDownMenu_AddButton(info, level)
  info=UIDropDownMenu_CreateInfo(); info.func=function(_,arg1) choose(arg1) end
  info.text="+2"; info.arg1=2; info.checked=(preferredLevel==2); UIDropDownMenu_AddButton(info, level)
  for i=3,20 do
    info=UIDropDownMenu_CreateInfo(); info.func=function(_,arg1) choose(arg1) end
    info.text="+"..i; info.arg1=i; info.checked=(preferredLevel==i); UIDropDownMenu_AddButton(info, level)
  end
end)

-- ===== Preferred Activity (Any Dungeon / Any Delve / Dungeons / Delves) =====
local preferredMapID = 0                 -- for DUNGEON choice
local preferredActivityKind = "ANY_DUNGEON" -- "ANY_DUNGEON","ANY_DELVE","DUNGEON","DELVE"
local preferredDelveName = nil

-- seasonal dungeon list
local seasonMaps, mapRetryTicker = {}, nil
local function uniqPush(dst, id, name)
  if not id or id==0 then return end
  for _,v in ipairs(dst) do if v.id==id then return end end
  table.insert(dst, {id=id, name=name or tostring(id)})
end
local function refreshSeasonMaps()
  wipe(seasonMaps)
  local ids = (C_ChallengeMode and C_ChallengeMode.GetMapTable and C_ChallengeMode.GetMapTable()) or {}
  for _,id in ipairs(ids) do uniqPush(seasonMaps, id, C_ChallengeMode.GetMapUIInfo and C_ChallengeMode.GetMapUIInfo(id) or nil) end
  if #seasonMaps==0 and C_MythicPlus and C_MythicPlus.GetMapTable then
    local mids = C_MythicPlus.GetMapTable() or {}
    for _,id in ipairs(mids) do uniqPush(seasonMaps, id, C_MythicPlus.GetMapUIInfo and C_MythicPlus.GetMapUIInfo(id) or nil) end
  end
  if #seasonMaps==0 and C_MythicPlus and C_MythicPlus.GetRunHistory then
    local hist = C_MythicPlus.GetRunHistory(false,true) or {}
    for _, run in ipairs(hist) do
      uniqPush(seasonMaps, run.mapChallengeModeID, C_ChallengeMode.GetMapUIInfo and C_ChallengeMode.GetMapUIInfo(run.mapChallengeModeID) or nil)
    end
  end
  for _,m in ipairs(seasonMaps) do
    if not m.name or m.name=="" then
      local info = C_MythicPlus and C_MythicPlus.GetMapInfo and C_MythicPlus.GetMapInfo(m.id)
      m.name = (info and info.name) or (C_Map and C_Map.GetMapInfo and (C_Map.GetMapInfo(m.id) or {}).name) or tostring(m.id)
    end
  end
  table.sort(seasonMaps, function(a,b) return (a.name or "") < (b.name or "") end)
end
local function ensureMapsSoon()
  if #seasonMaps>0 or mapRetryTicker then return end
  local tries=0
  mapRetryTicker=C_Timer.NewTicker(2, function()
    tries=tries+1; refreshSeasonMaps()
    if #seasonMaps>0 or tries>=6 then
      mapRetryTicker:Cancel(); mapRetryTicker=nil
      if NS.RefreshUI then NS.RefreshUI() end
    end
  end)
end

-- PREDECLARE the dropdown so setActivityDisplay captures the correct local upvalue
local dungeonDD

local function setActivityDisplay()
  if not dungeonDD then return end
  if preferredActivityKind == "ANY_DUNGEON" then
    UIDropDownMenu_SetText(dungeonDD, "Any Dungeon")
  elseif preferredActivityKind == "ANY_DELVE" then
    UIDropDownMenu_SetText(dungeonDD, "Any Delve")
  elseif preferredActivityKind == "DUNGEON" then
    UIDropDownMenu_SetText(dungeonDD, mapName(preferredMapID))
  elseif preferredActivityKind == "DELVE" then
    UIDropDownMenu_SetText(dungeonDD, (preferredDelveName or "Delve"))
  end
end

dungeonDD = CreateFrame("Frame", "MBUS_DungeonDD", frame, "UIDropDownMenuTemplate")
dungeonDD:SetPoint("LEFT", lvlLbl, "RIGHT", 24, 0)
UIDropDownMenu_SetWidth(dungeonDD, 260)
UIDropDownMenu_SetText(dungeonDD, "Any Dungeon")
local dLbl = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
dLbl:SetPoint("LEFT", dungeonDD, "RIGHT", -8, 2)
dLbl:SetText("Preferred Activity")

UIDropDownMenu_Initialize(dungeonDD, function(self, level)
  if #seasonMaps==0 then refreshSeasonMaps() end

  local function chooseAnyDungeon()
    preferredActivityKind = "ANY_DUNGEON"
    preferredMapID = 0
    preferredDelveName = nil
    setActivityDisplay()
    CloseDropDownMenus()
  end
  local function chooseAnyDelve()
    preferredActivityKind = "ANY_DELVE"
    preferredMapID = 0
    preferredDelveName = nil
    setActivityDisplay()
    CloseDropDownMenus()
  end
  local function chooseDungeon(id)
    preferredActivityKind = "DUNGEON"
    preferredMapID = id
    preferredDelveName = nil
    setActivityDisplay()
    CloseDropDownMenus()
  end
  local function chooseDelve(name)
    preferredActivityKind = "DELVE"
    preferredMapID = 0
    preferredDelveName = name
    setActivityDisplay()
    CloseDropDownMenus()
  end

  -- Any Dungeon / Any Delve
  do
    local info = UIDropDownMenu_CreateInfo()
    info.text = "Any Dungeon"
    info.checked = (preferredActivityKind == "ANY_DUNGEON")
    info.func = chooseAnyDungeon
    UIDropDownMenu_AddButton(info, level)

    info = UIDropDownMenu_CreateInfo()
    info.text = "Any Delve"
    info.checked = (preferredActivityKind == "ANY_DELVE")
    info.func = chooseAnyDelve
    UIDropDownMenu_AddButton(info, level)
  end

  -- Spacer
  do
    local info = UIDropDownMenu_CreateInfo()
    info.notClickable = true
    info.isTitle = true
    info.disabled = true
    info.text = " "
    UIDropDownMenu_AddButton(info, level)
  end

  -- Dungeons header
  do
    local info = UIDropDownMenu_CreateInfo()
    info.isTitle = true
    info.notCheckable = true
    info.text = "Dungeons"
    UIDropDownMenu_AddButton(info, level)
  end

  if #seasonMaps==0 then
    local owned = C_MythicPlus.GetOwnedKeystoneMapID and C_MythicPlus.GetOwnedKeystoneMapID() or 0
    if owned and owned>0 then
      local info = UIDropDownMenu_CreateInfo()
      info.text = "Use My Key: "..mapName(owned)
      info.checked = (preferredActivityKind=="DUNGEON" and preferredMapID==owned)
      info.func = function() chooseDungeon(owned) end
      UIDropDownMenu_AddButton(info, level)
    end
  else
    for _,m in ipairs(seasonMaps) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = m.name
      info.checked = (preferredActivityKind=="DUNGEON" and preferredMapID==m.id)
      info.func = function() chooseDungeon(m.id) end
      UIDropDownMenu_AddButton(info, level)
    end
  end

  -- Delves header
  do
    local info = UIDropDownMenu_CreateInfo()
    info.isTitle = true
    info.notCheckable = true
    info.text = "Delves"
    UIDropDownMenu_AddButton(info, level)
  end

  -- Delves list
  for _, name in ipairs(MBUS_DELVES) do
    local info = UIDropDownMenu_CreateInfo()
    info.text = name
    info.checked = (preferredActivityKind=="DELVE" and preferredDelveName==name)
    info.func = function() chooseDelve(name) end
    UIDropDownMenu_AddButton(info, level)
  end
end)

-- ========= Action buttons (created lazily) =========
local function CreateActionButtons()
  if frame.qButton then return end
  local q = CreateFrame("Button", "MBUS_QueueButton", frame, "UIPanelButtonTemplate")
  q:SetText("Queue Me"); q:SetSize(120, 28); q:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -122)
  q:SetScript("OnClick", function()
    local letters = "" ; if wantT then letters=letters.."T" end; if wantH then letters=letters.."H" end; if wantD then letters=letters.."D" end
    if letters == "" then UIErrorsFrame:AddMessage("Select at least one role (Tank/Healer/DPS).", 1, 0.2, 0.2, 1.0); return end
    local minv,maxv = preferredLevel or 0, preferredLevel or 0

    -- Only pass a mapID when a specific *dungeon* is chosen; otherwise leave blank
    local maps = ""
    if preferredActivityKind=="DUNGEON" and preferredMapID and preferredMapID>0 then
      maps = tostring(preferredMapID)
    end

    -- Save your local choice so your row shows proper text in the table
    MythicbusDB.selfPrefs = MythicbusDB.selfPrefs or {}
    MythicbusDB.selfPrefs[PLAYER_NAME or "player"] = {
      kind  = preferredActivityKind,
      mapID = preferredMapID,
      delve = preferredDelveName,
    }

     -- ✅ Send kind/delve through to core.lua
    NS.QueueMe(letters, minv, maxv, maps, preferredActivityKind, preferredDelveName)
  end)
  local l = CreateFrame("Button", "MBUS_LeaveButton", frame, "UIPanelButtonTemplate")
  l:SetText("Leave"); l:SetSize(100, 28); l:SetPoint("LEFT", q, "RIGHT", 10, 0); l:SetScript("OnClick", function() NS.LeaveQueue() end)
  frame.qButton, frame.lButton = q, l
end

-- ===== Context menu for names (Whisper / Invite / Copy) =====
local nameMenuFrame = CreateFrame("Frame", "MBUS_NameMenu", UIParent, "UIDropDownMenuTemplate")
StaticPopupDialogs["MBUS_COPY_NAME"] = {
  text = "Copy player name",
  button1 = OKAY,
  hasEditBox = true,
  editBoxWidth = 220,
  whileDead = true,
  hideOnEscape = true,
  OnShow = function(self) self.editBox:SetText(self.data or ""); self.editBox:HighlightText() end,
  OnAccept = function(self) end,
}
local function MBUS_ShowNameMenu(anchor, name)
  local items = {
    { text = name, isTitle = true, notCheckable = true },
    { text = "Whisper", notCheckable = true, func = function() ChatFrame_OpenChat("/w "..name.." ") end },
    { text = "Invite to Group", notCheckable = true, func = function() InviteUnit(name) end },
    { text = "Copy Name", notCheckable = true, func = function() StaticPopup_Show("MBUS_COPY_NAME", nil, nil, name) end },
    { text = CANCEL, notCheckable = true },
  }
  EasyMenu(items, nameMenuFrame, anchor, 0, 0, "MENU", true)
end

-- ===== Table =====
local tableBuilt, tableFrame, rows = false, nil, {}
local COL_SPACING = 4
local COLS = {
  { key="name",  title="Name",         width=160, align="LEFT"  },
  { key="role",  title="Roles",        width=40,  align="CENTER"},
  { key="wants", title="Wants",        width=50,  align="CENTER"},
  { key="pref",  title="Pref Dungeon", width=160, align="LEFT"  }, -- shows Your activity choice for you
  { key="owned", title="Owned Key",    width=150, align="LEFT"  },
  { key="class", title="Class/Spec",   width=110, align="LEFT"  },
  { key="ilvl",  title="iLvl",         width=36,  align="RIGHT" },
  { key="age",   title="Last Seen",    width=44,  align="RIGHT" },
}
local ROWS, rowHeight = 12, 24

local function BuildTable()
  if tableBuilt then return end
  tableFrame = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
  tableFrame:SetSize(788, 356)
  tableFrame:SetPoint("TOPLEFT", 16, -168)
  frame.tableFrame = tableFrame  

  local hdr = CreateFrame("Frame", nil, tableFrame)
  hdr:SetSize(788, 20); hdr:SetPoint("TOPLEFT", 6, -6)
  local x=0; for _,c in ipairs(COLS) do
    local fs = hdr:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("LEFT", hdr, "LEFT", x, 0); fs:SetWidth(c.width); fs:SetJustifyH(c.align or "LEFT"); fs:SetText(c.title)
    x = x + c.width + COL_SPACING
  end

  rows = {}
  for i=1, ROWS do
    local row = CreateFrame("Frame", nil, tableFrame)
    row:SetSize(788, rowHeight); row:SetPoint("TOPLEFT", 6, -(22 + (i-1)*rowHeight))
    row.cells = {}; local cx=0
    for _,c in ipairs(COLS) do
      local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      fs:SetPoint("LEFT", row, "LEFT", cx, 0); fs:SetWidth(c.width); fs:SetJustifyH(c.align or "LEFT"); fs:SetText("")
      row.cells[c.key] = fs; cx = cx + c.width + COL_SPACING
    end
    -- right-click context menu
    row:SetScript("OnMouseUp", function(self, button)
      if button == "RightButton" and self._name then MBUS_ShowNameMenu(self, self._name) end
    end)
    rows[i] = row
  end

  -- Scrolling
  tableFrame:EnableMouseWheel(true)
  tableFrame:SetScript("OnMouseWheel", function(_, delta)
    local total = #queueEntriesSorted(); local maxOffset = math.max(0, total - ROWS)
    frame._qOffset = math.min(maxOffset, math.max(0, (frame._qOffset or 0) - delta)); if NS.RefreshUI then NS.RefreshUI() end
  end)

  tableBuilt = true
end

-- ===== Populate =====
function NS.RefreshUI()
  if not tableBuilt then return end
  local entries = queueEntriesSorted()
  local nowSec = time()
  local qOffset = frame._qOffset or 0

  -- pull your saved activity (if any) to show delves/any-delves properly for your row
  local selfPrefs = ((MythicbusDB or {}).selfPrefs or {})[PLAYER_NAME or "player"]

  for i=1, ROWS do
    local idx = i + qOffset
    local row = rows[i]
    local item = entries[idx]
    if item then
      local name, q = item.name, item.q
      local m = (MythicbusDB.members or {})[name]

      local wants
      local qmin, qmax = (q.min or 0), (q.max or 0)
      if qmin == 0 and qmax == 0 then wants = "0"
      elseif qmin == qmax then wants = ("+%d"):format(qmin)
      else wants = ("%d–%d"):format(qmin, qmax) end

      -- Preferred activity text
      local prefText = "Any"

      -- If sender included kind/delve, prefer that
      if q.kind == "ANY_DUNGEON" then
        prefText = "Any Dungeon"
      elseif q.kind == "ANY_DELVE" then
        prefText = "Any Delve"
      elseif q.kind == "DUNGEON" and q.targetMaps and #q.targetMaps > 0 then
        prefText = mapName(q.targetMaps[1]) or "Any"
      elseif q.kind == "DELVE" then
        prefText = q.delve or "Delve"
      -- Fallback: numeric map id only (legacy senders)
      elseif q.targetMaps and #q.targetMaps > 0 then
        prefText = mapName(q.targetMaps[1]) or "Any"
      end

      -- (Optional) keep your self-row local override if you like
      if name == (PLAYER_NAME or name) and selfPrefs then
        local k = selfPrefs.kind
        if k == "ANY_DUNGEON" then      prefText = "Any Dungeon"
        elseif k == "ANY_DELVE" then    prefText = "Any Delve"
        elseif k == "DUNGEON" and selfPrefs.mapID and selfPrefs.mapID > 0 then
          prefText = mapName(selfPrefs.mapID)
        elseif k == "DELVE" then        prefText = selfPrefs.delve or "Delve"
        end
      end

      local ageSec = math.max(0, nowSec - (q.updated or q.ts or nowSec))

      row.cells.name:SetText(name)
      row.cells.role:SetText(wantLetters(q.wantRole))
      row.cells.wants:SetText(wants)
      row.cells.pref:SetText(prefText)
      row.cells.owned:SetText(ownedKeyStr(m))
      row.cells.class:SetText(memberClassSpec(name))
      row.cells.ilvl:SetText(memberILvl(name))
      row.cells.age:SetText(timeAgoColor(ageSec))
      row._name = name
      row:Show()
    else
      for k,_ in pairs(row.cells) do row.cells[k]:SetText("") end
      row._name = nil
      row:Hide()
    end
  end
end

-- ===== Lifecycle =====
frame:SetScript("OnShow", function()
  refreshSeasonMaps(); ensureMapsSoon()
  if not frame.qButton then CreateActionButtons() end
  if not tableBuilt then BuildTable() end
  UIDropDownMenu_SetText(levelDD, (preferredLevel == 0) and "0" or ("+"..preferredLevel))
  -- reflect current activity selection
  setActivityDisplay()
  if NS.RefreshUI then NS.RefreshUI() end
  if not frame._ticker then
    frame._ticker = C_Timer.NewTicker(1, function() if frame:IsShown() and NS.RefreshUI then NS.RefreshUI() end end)
  end
  MBUS_StartMapRetryTicker()  -- kick off map-name retries while UI is open
end)
frame:SetScript("OnHide", function()
  if frame._ticker then frame._ticker:Cancel(); frame._ticker=nil end
end)

-- Update when CM maps/affixes publish (also resolves owned-key names quickly)
local _mbusEvt = CreateFrame("Frame")
MBUS_SafeRegisterEvent(_mbusEvt, "PLAYER_ENTERING_WORLD")
MBUS_SafeRegisterEvent(_mbusEvt, "CHALLENGE_MODE_MAPS_UPDATE")
MBUS_SafeRegisterEvent(_mbusEvt, "MYTHIC_PLUS_CURRENT_AFFIXES_UPDATED")
_mbusEvt:SetScript("OnEvent", function()
  refreshSeasonMaps()
  MBUS_RetryPendingMapNames()
  if NS.RefreshUI then NS.RefreshUI() end
end)

-- Slash to open UI
SLASH_MBUSUI1 = "/mbusui"
SlashCmdList.MBUSUI = function()
  if MythicbusFrame:IsShown() then MythicbusFrame:Hide() else MythicbusFrame:Show() end
end

-- =================================================================
-- ============== MINIMAP ICON (with fallback) =====================
-- =================================================================
-- Ensure DB table exists
MythicbusDB = MythicbusDB or {}

-- Preferred (LibDataBroker + LibDBIcon)
local LDB  = LibStub and LibStub("LibDataBroker-1.1", true)
local LDBI = LibStub and LibStub("LibDBIcon-1.0", true)

if LDB and LDBI then
  MythicbusDB.minimap = MythicbusDB.minimap or { hide = false, minimapPos = 220 }

  local dataobj = LDB:NewDataObject("Mythicbus", {
    type  = "launcher",
    text  = "Mythicbus",
    icon  = 134400, -- change to your icon path or fileID
    OnClick = function(_, button)
      if button == "LeftButton" then
        if MythicbusFrame and MythicbusFrame:IsShown() then MythicbusFrame:Hide() else
          if SlashCmdList and SlashCmdList.MBUSUI then SlashCmdList.MBUSUI() end
        end
      else -- Right-click
        if NS and NS.ShowBounties then NS.ShowBounties()
        else
          if MythicbusFrame and MythicbusFrame:IsShown() then MythicbusFrame:Hide() else
            if SlashCmdList and SlashCmdList.MBUSUI then SlashCmdList.MBUSUI() end
          end
        end
      end
    end,
    OnTooltipShow = function(tt)
      tt:AddLine("|cff00ff88Mythicbus|r")
      tt:AddLine("|cffffffffLeft-Click:|r Toggle Queue")
      tt:AddLine("|cffffffffRight-Click:|r Bounties")
      tt:AddLine(" ")
      tt:AddLine("|cffffffff/mbusmini|r to hide/show")
    end
  })

  LDBI:Register("Mythicbus", dataobj, MythicbusDB.minimap)

  function NS.ShowMinimapIcon() MythicbusDB.minimap.hide=false; LDBI:Show("Mythicbus") end
  function NS.HideMinimapIcon() MythicbusDB.minimap.hide=true;  LDBI:Hide("Mythicbus") end
  function NS.ToggleMinimapIcon()
    if MythicbusDB.minimap.hide then NS.ShowMinimapIcon() else NS.HideMinimapIcon() end
  end

  SLASH_MBUSMINI1 = "/mbusmini"
  SlashCmdList.MBUSMINI = function()
    NS.ToggleMinimapIcon()
    print(("Mythicbus minimap icon: %s"):format(MythicbusDB.minimap.hide and "|cffff5555hidden|r" or "|cff55ff55shown|r"))
  end
else
  -- Fallback: simple API minimap button (no libs)
  MythicbusDB.minimapFallback = MythicbusDB.minimapFallback or { hide=false, angle = 210 }

  local function MBUS_CreateSimpleMinimapButton()
    if MBUS_MinimapButton then return end

    local btn = CreateFrame("Button", "MBUS_MinimapButton", Minimap)
    btn:SetSize(32, 32)
    btn:SetFrameStrata("MEDIUM")
    btn:SetHighlightTexture(136477) -- "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
    btn:SetNormalTexture(136430)
    btn:SetPushedTexture(136429)

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(134400)
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 0)
    btn.icon = icon

    local function UpdatePos()
      local ang = math.rad(MythicbusDB.minimapFallback.angle or 210)
      local x = math.cos(ang) * 80
      local y = math.sin(ang) * 80
      btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
      
    end

    btn:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_LEFT")
      GameTooltip:AddLine("|cff00ff88Mythicbus|r")
      GameTooltip:AddLine("|cffffffffLeft-Click:|r Toggle Queue")
      GameTooltip:AddLine("|cffffffffRight-Click:|r Ranks")
      GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    btn:SetScript("OnClick", function(_, button)
      if button == "LeftButton" then
        if MythicbusFrame and MythicbusFrame:IsShown() then MythicbusFrame:Hide() else
          if SlashCmdList and SlashCmdList.MBUSUI then SlashCmdList.MBUSUI() end
        end
      else
        if NS and NS.ShowBounties then NS.ShowBounties()
        elseif SlashCmdList and SlashCmdList.MBUSUI then SlashCmdList.MBUSUI() end
      end
    end)

    btn:RegisterForDrag("LeftButton")
    btn:SetMovable(true)
    btn:SetScript("OnDragStart", function(self) self:StartMoving() end)
    btn:SetScript("OnDragStop", function(self)
      self:StopMovingOrSizing()
      local mx, my = Minimap:GetCenter()
      local bx, by = self:GetCenter()
      local ang = math.deg(math.atan2(by - my, bx - mx))
      MythicbusDB.minimapFallback.angle = ang
      UpdatePos()
    end)

    UpdatePos()
    if MythicbusDB.minimapFallback.hide then btn:Hide() else btn:Show() end

    function NS.ShowMinimapIcon() MythicbusDB.minimapFallback.hide=false; btn:Show() end
    function NS.HideMinimapIcon() MythicbusDB.minimapFallback.hide=true;  btn:Hide() end
    function NS.ToggleMinimapIcon() if btn:IsShown() then NS.HideMinimapIcon() else NS.ShowMinimapIcon() end end

    SLASH_MBUSMINI1 = "/mbusmini"
    SlashCmdList.MBUSMINI = function()
      NS.ToggleMinimapIcon()
      print(("Mythicbus minimap icon (fallback): %s"):format((btn:IsShown() and "|cff55ff55shown|r") or "|cffff5555hidden|r"))
    end
  end

  local mbusMiniLoader = CreateFrame("Frame")
  mbusMiniLoader:RegisterEvent("PLAYER_LOGIN")
  mbusMiniLoader:SetScript("OnEvent", function()
    MBUS_CreateSimpleMinimapButton()
  end)
end
