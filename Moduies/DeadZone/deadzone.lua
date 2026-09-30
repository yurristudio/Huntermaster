local _, Addon = ...
local DB = Addon:GetModule("DB")
local DeadZone = Addon:GetModule("DeadZone")
local L = Addon:GetModule("Locale")
local Theme = Addon:GetModule("Theme")
local Widgets = Addon:GetModule("Widgets")

Addon:RegisterNavModule("DeadZone", "NAV_DEADZONE", nil, 50)

-- ============================================================================
-- State
-- ============================================================================

-- Every band the HUD can show, ordered far -> near. Each one has its own
-- TGA in the Textures folder (file name = the "file" field below, no
-- extension, no spaces). As the target closes in, the HUD steps down this
-- list: OutOfRange -> MaxRange -> Range35 ... Range10 -> DeadZone -> Melee.
local TEXTURE_PATH = "Interface\\AddOns\\Huntmaster\\Textures\\"

local ZONE = {
  FAR = "FAR", MAX = "MAX",
  Y35 = "Y35", Y30 = "Y30", Y25 = "Y25", Y20 = "Y20", Y15 = "Y15", Y10 = "Y10",
  DEADZONE = "DEADZONE", MELEE = "MELEE",
}

local GREEN  = { 0.25, 1.00, 0.25 }
local LIME   = { 0.60, 1.00, 0.20 }
local YELLOW = { 1.00, 0.90, 0.20 }
local ORANGE = { 1.00, 0.60, 0.15 }

local ZoneInfo = {
  [ZONE.FAR]      = { label = L.DEADZONE_STATE_FAR,      file = "OutOfRange", textColor = { 0.60, 0.60, 0.60 } },
  [ZONE.MAX]      = { label = L.DEADZONE_STATE_MAX,      file = "MaxRange",   textColor = { 0.30, 0.85, 1.00 } },
  [ZONE.Y35]      = { label = "35 yd",                   file = "Range35",    textColor = GREEN },
  [ZONE.Y30]      = { label = "30 yd",                   file = "Range30",    textColor = GREEN },
  [ZONE.Y25]      = { label = "25 yd",                   file = "Range25",    textColor = LIME },
  [ZONE.Y20]      = { label = "20 yd",                   file = "Range20",    textColor = YELLOW },
  [ZONE.Y15]      = { label = "15 yd",                   file = "Range15",    textColor = YELLOW },
  [ZONE.Y10]      = { label = "10 yd",                   file = "Range10",    textColor = ORANGE },
  [ZONE.DEADZONE] = { label = L.DEADZONE_STATE_DEADZONE, file = "DeadZone",   textColor = { 1.00, 0.15, 0.10 } },
  [ZONE.MELEE]    = { label = L.DEADZONE_STATE_MELEE,    file = "Melee",      textColor = { 0.30, 0.55, 1.00 } },
}
for _, info in pairs(ZoneInfo) do info.icon = TEXTURE_PATH .. info.file end

-- Preview order (far -> near).
local ZONE_ORDER = { ZONE.FAR, ZONE.MAX, ZONE.Y35, ZONE.Y30, ZONE.Y25, ZONE.Y20,
  ZONE.Y15, ZONE.Y10, ZONE.DEADZONE, ZONE.MELEE }

local hud
local elapsedSinceCheck = 0
local CHECK_INTERVAL = 0.15
local testTicker

-- ============================================================================
-- Range detection
-- ============================================================================
-- Distance ladder adapted from Rangefinder3000 (same client, known to work):
-- each rung is a set of items whose use-range is a known distance, checked
-- with C_Item.IsItemInRange. The first rung that says "in range" is how far
-- away the target is (at most). Melee and dead zone come from Raptor Strike /
-- Auto Shot, since Auto Shot is what enforces the minimum shooting range.

local LADDER = {
  { ZONE.Y10, 17626, 10699, 17689 },
  { ZONE.Y15, 4559 },
  { ZONE.Y20, 10645, 1191, 4388 },
  { ZONE.Y25, 13289 },
  { ZONE.Y30, 7734, 17202, 835, 2091 },
  { ZONE.Y35, 18904 },
}
local MELEE_SPELL_ID = 2974 -- Raptor Strike
local AUTO_SHOT_ID = 75

local function Normalize(value)
  if value == true or value == 1 then return true end
  if value == false or value == 0 then return false end
  return nil
end

local spellNames = {}
local function SpellName(id)
  if spellNames[id] ~= nil then return spellNames[id] or nil end
  local name
  if C_Spell and C_Spell.GetSpellInfo then
    local ok, info = pcall(C_Spell.GetSpellInfo, id)
    if ok and type(info) == "table" then name = info.name end
    if ok and type(info) == "string" then name = info end
  end
  if not name and GetSpellInfo then
    local ok, info = pcall(GetSpellInfo, id)
    if ok then name = info end
  end
  spellNames[id] = name or false
  return name
end

local function SpellInRange(id)
  local name = SpellName(id)
  if name and IsSpellInRange then
    local ok, value = pcall(IsSpellInRange, name, "target")
    if ok and Normalize(value) ~= nil then return Normalize(value) end
  end
  if C_Spell and C_Spell.IsSpellInRange then
    local ok, value = pcall(C_Spell.IsSpellInRange, id, "target")
    if ok then
      if type(value) == "table" then value = value.inRange end
      return Normalize(value)
    end
  end
  return nil
end

local function ItemInRange(id)
  if not (C_Item and C_Item.IsItemInRange) then return nil end
  local ok, value = pcall(C_Item.IsItemInRange, id, "target")
  if ok then return Normalize(value) end
  return nil
end

local function RungInRange(rung)
  local sawFalse = false
  for i = 2, #rung do
    local value = ItemInRange(rung[i])
    if value == true then return true end
    if value == false then sawFalse = true end
  end
  if sawFalse then return false end
  return nil
end

local function GetZone()
  if not UnitExists("target") or UnitIsDeadOrGhost("target") or not UnitCanAttack("player", "target") then
    return nil
  end

  local melee = SpellInRange(MELEE_SPELL_ID)
  local auto
  if melee == nil then
    -- Raptor Strike not usable (not learned yet): fall back to native checks.
    melee = ItemInRange(16114)
    if melee == nil and CheckInteractDistance then
      local ok, value = pcall(CheckInteractDistance, "target", 2)
      if ok then melee = Normalize(value) end
    end
  elseif melee == true then
    -- In melee reach; Auto Shot still working means we're not really "melee".
    auto = SpellInRange(AUTO_SHOT_ID)
    if auto ~= nil then melee = (auto == false) end
  end
  if melee == true then return ZONE.MELEE end

  if auto == nil then auto = SpellInRange(AUTO_SHOT_ID) end

  local thirtyFive
  for i = 1, #LADDER do
    local result = RungInRange(LADDER[i])
    if i == #LADDER then thirtyFive = result end
    if result == true then
      -- Inside 20 yd but Auto Shot refuses to fire: that's the dead zone.
      if auto == false and i <= 3 then return ZONE.DEADZONE end
      return LADDER[i][1]
    end
  end

  -- Auto Shot alone can't prove we're past 35 yd; the 35 yd probe must
  -- explicitly say no before we show the "max range" band.
  if auto == true and thirtyFive == false then return ZONE.MAX end
  if auto == true then return ZONE.Y35 end
  return ZONE.FAR
end

-- ============================================================================
-- HUD frame
-- ============================================================================

local ICON_SIZE = 72 -- was 36 — small enough in the corner of the screen
                      -- during combat to be easy to miss entirely
local FRAME_WIDTH, FRAME_HEIGHT = ICON_SIZE + 12, ICON_SIZE + 34

local function CreateHUD()
  local f = CreateFrame("Frame", "HuntmasterDeadZoneHUD", UIParent, "BackdropTemplate")
  f:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
  f:SetFrameStrata("MEDIUM")
  f:SetClampedToScreen(true)
  f:SetMovable(true)

  f.icon = f:CreateTexture(nil, "ARTWORK")
  f.icon:SetSize(ICON_SIZE, ICON_SIZE)
  f.icon:SetPoint("TOP", 0, 0)
  f.icon:SetTexture(ZoneInfo[ZONE.Y35].icon)

  -- Status label — noticeably larger than before so it's readable at a
  -- glance, not just up close.
  f.status = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  f.status:SetPoint("TOP", f.icon, "BOTTOM", 0, -4)
  f.status:SetFont(Theme.Font.title, DB.global.deadZone.textSize, "OUTLINE")
  f.status:SetShown(DB.global.deadZone.showText)

  -- Dragging.
  f:EnableMouse(true)
  f:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not DB.global.deadZone.locked then
      self:StartMoving()
    end
  end)
  f:SetScript("OnMouseUp", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    DB.global.deadZone.point = { point, "UIParent", relPoint, x, y }
  end)
  f:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(L.NAV_DEADZONE, 1.0, 0.82, 0)
    GameTooltip:AddLine(L.DEADZONE_ENABLE_TOOLTIP, 1, 1, 1, true)
    GameTooltip:Show()
  end)
  f:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  local p = DB.global.deadZone.point
  f:SetPoint(p[1], UIParent, p[3], p[4], p[5])
  f:SetScale(DB.global.deadZone.scale)
  f:Hide()

  return f
end

-- Swaps the icon/text to match the given zone.
local function ApplyZone(zone)
  local info = ZoneInfo[zone]

  hud.status:SetText(info.label)
  hud.status:SetTextColor(unpack(info.textColor))

  hud.icon:SetTexture(info.icon)
end

local function RefreshVisibility()
  if not hud then return end
  local settings = DB.global.deadZone

  if not settings.enabled then
    hud:Hide()
    return
  end

  if settings.onlyInCombat and not UnitAffectingCombat("player") then
    hud:Hide()
    return
  end

  local zone = GetZone()
  if not zone then
    hud:Hide()
    return
  end

  ApplyZone(zone)
  hud:Show()
end

-- ============================================================================
-- Driver frame — polls at CHECK_INTERVAL since range state has no event.
-- ============================================================================

local driver = CreateFrame("Frame")
driver:Hide()
driver:SetScript("OnUpdate", function(_, elapsed)
  elapsedSinceCheck = elapsedSinceCheck + elapsed
  if elapsedSinceCheck < CHECK_INTERVAL then return end
  elapsedSinceCheck = 0
  RefreshVisibility()
end)

driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:RegisterEvent("PLAYER_TARGET_CHANGED")
driver:RegisterEvent("PLAYER_REGEN_DISABLED")
driver:RegisterEvent("PLAYER_REGEN_ENABLED")
driver:SetScript("OnEvent", RefreshVisibility)

function DeadZone:Initialize()
  hud = CreateHUD()
  if DB.global.deadZone.enabled then
    driver:Show()
  end
  self.Initialize = nil
end

-- Cycles the HUD through all three states on a timer so it can be previewed
-- without needing a target.
local function ToggleTestMode(enable)
  if not hud then return end

  if testTicker then
    testTicker:Cancel()
    testTicker = nil
  end

  if not enable then
    RefreshVisibility()
    return
  end

  local order = ZONE_ORDER
  local i = 0
  local function Step()
    i = (i % #order) + 1
    ApplyZone(order[i])
    hud:Show()
  end
  Step()
  testTicker = C_Timer.NewTicker(1.4, Step)
end

-- ============================================================================
-- Settings tab
-- ============================================================================

function DeadZone:Build(hostFrame)
  local settings = DB.global.deadZone
  local scroll = Widgets:MountScrollHost(hostFrame)

  Widgets:Heading(scroll, L.NAV_DEADZONE)

  local general = Widgets:InlineGroup({ parent = scroll, title = L.GENERAL, fullWidth = true })

  Widgets:CheckBox({
    parent = general,
    label = L.DEADZONE_ENABLE,
    tooltip = L.DEADZONE_ENABLE_TOOLTIP,
    get = function() return settings.enabled end,
    set = function(value)
      settings.enabled = value
      if value then driver:Show() else driver:Hide() end
      RefreshVisibility()
    end,
  })

  Widgets:CheckBox({
    parent = general,
    label = L.DEADZONE_COMBAT_ONLY,
    tooltip = L.DEADZONE_COMBAT_ONLY_TOOLTIP,
    get = function() return settings.onlyInCombat end,
    set = function(value)
      settings.onlyInCombat = value
      RefreshVisibility()
    end,
  })

  Widgets:CheckBox({
    parent = general,
    label = L.DEADZONE_LOCK,
    tooltip = L.DEADZONE_LOCK_TOOLTIP,
    get = function() return settings.locked end,
    set = function(value) settings.locked = value end,
  })

  Widgets:Slider({
    parent = general,
    label = L.DEADZONE_SCALE,
    fullWidth = true,
    min = 0.6, max = 2.0, step = 0.05,
    get = function() return settings.scale end,
    set = function(value)
      settings.scale = value
      if hud then hud:SetScale(value) end
    end,
  })

  Widgets:CheckBox({
    parent = general,
    label = L.DEADZONE_SHOW_TEXT,
    tooltip = L.DEADZONE_SHOW_TEXT_TOOLTIP,
    get = function() return settings.showText end,
    set = function(value)
      settings.showText = value
      if hud then hud.status:SetShown(value) end
    end,
  })

  Widgets:Slider({
    parent = general,
    label = L.DEADZONE_TEXT_SIZE,
    fullWidth = true,
    min = 8, max = 40, step = 1,
    get = function() return settings.textSize end,
    set = function(value)
      settings.textSize = value
      if hud then hud.status:SetFont(Theme.Font.title, value, "OUTLINE") end
    end,
  })

  local advanced = Widgets:InlineGroup({ parent = scroll, title = L.OPTIONS, fullWidth = true })

  Widgets:Spacer(advanced)

  local testEnabled = false
  Widgets:Button({
    parent = advanced,
    text = L.DEADZONE_TEST_MODE,
    fullWidth = true,
    onClick = function()
      testEnabled = not testEnabled
      ToggleTestMode(testEnabled)
    end,
  })

  Widgets:Button({
    parent = advanced,
    text = L.DEADZONE_RESET_POSITION,
    fullWidth = true,
    onClick = function()
      settings.point = { "CENTER", "UIParent", "CENTER", 0, -180 }
      if hud then
        hud:ClearAllPoints()
        hud:SetPoint("CENTER", UIParent, "CENTER", 0, -180)
      end
    end,
  })
end
