local ADDON_NAME, Addon = ...
local L = Addon:GetModule("Locale")
local Theme = Addon:GetModule("Theme")
local UI = Addon:GetModule("UI")
local Widgets = Addon:GetModule("Widgets")

local SIDEBAR_WIDTH = 168
local HEADER_HEIGHT = 46
local FRAME_WIDTH = 780
local FRAME_HEIGHT = 540

-- ============================================================================
-- Show / Hide
-- ============================================================================

function UI:IsShown()
  return self.frame and self.frame:IsShown()
end

function UI:Toggle()
  if self:IsShown() then
    self:Hide()
  else
    self:Show()
  end
end

function UI:Show()
  if not self.frame then self:Create() end
  self.frame:Show()
end

function UI:Hide()
  if not self.frame then return end
  self.frame:Hide()
end

-- ============================================================================
-- Module navigation
-- ============================================================================

-- Switches the content host to the module registered under `key`, building
-- it lazily the first time it's selected.
function UI:SelectModule(key)
  if self.selectedKey == key then return end
  self.selectedKey = key

  for k, button in pairs(self.navButtons) do
    button:SetSelected(k == key)
  end

  for k, hostFrame in pairs(self.moduleHosts) do
    hostFrame:SetShown(k == key)
  end

  local hostFrame = self.moduleHosts[key]
  if not hostFrame then
    hostFrame = CreateFrame("Frame", nil, self.contentHost)
    hostFrame:SetAllPoints(self.contentHost)
    self.moduleHosts[key] = hostFrame

    local module = Addon:GetModule(key)
    if type(module.Build) == "function" then
      module:Build(hostFrame)
    else
      -- Placeholder for modules that haven't shipped yet.
      local label = hostFrame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
      label:SetPoint("CENTER")
      label:SetText(L.COMING_SOON)
    end

    hostFrame:Show()
  end
end

-- ============================================================================
-- Frame construction
-- ============================================================================

function UI:Create()
  self.navButtons = {}
  self.moduleHosts = {}

  local frame = CreateFrame("Frame", "HuntmasterMainFrame", UIParent, "BackdropTemplate")
  frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
  frame:SetPoint("CENTER")
  frame:SetFrameStrata("HIGH")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:SetClampedToScreen(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  Theme:Skin(frame, Theme.Backdrop.main, Theme.Color.background, Theme.Color.border)
  self.frame = frame

  -- Header bar.
  local header = Widgets:Panel(frame, Theme.Color.panel)
  header:SetPoint("TOPLEFT", 1, -1)
  header:SetPoint("TOPRIGHT", -1, -1)
  header:SetHeight(HEADER_HEIGHT)

  local icon = header:CreateTexture(nil, "ARTWORK")
  icon:SetSize(30, 30)
  icon:SetPoint("LEFT", 14, 0)
  icon:SetTexture(Addon.LOGO)

  local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("LEFT", icon, "RIGHT", 10, 2)
  title:SetText(ADDON_NAME)
  title:SetTextColor(unpack(Theme.Color.accent))

  local version = header:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  version:SetPoint("LEFT", title, "RIGHT", 8, 0)
  version:SetText("v" .. tostring(Addon.VERSION or "?"))

  local close = CreateFrame("Button", nil, header, "UIPanelCloseButton")
  close:SetPoint("RIGHT", -2, 0)
  close:SetScript("OnClick", function() UI:Hide() end)

  local headerDivider = Theme:Divider(frame)
  headerDivider:SetPoint("TOPLEFT", header, "BOTTOMLEFT")
  headerDivider:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT")

  -- Sidebar.
  local sidebar = Widgets:Panel(frame, Theme.Color.panel)
  sidebar:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
  sidebar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1)
  sidebar:SetWidth(SIDEBAR_WIDTH)

  local sidebarDivider = frame:CreateTexture(nil, "ARTWORK")
  sidebarDivider:SetColorTexture(unpack(Theme.Color.border))
  sidebarDivider:SetWidth(1)
  sidebarDivider:SetPoint("TOP", sidebar, "TOPRIGHT")
  sidebarDivider:SetPoint("BOTTOM", sidebar, "BOTTOMRIGHT")

  -- Content host (the currently selected module renders into here).
  local content = CreateFrame("Frame", nil, frame)
  content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 1, 0)
  content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
  self.contentHost = content

  -- Sidebar nav buttons, driven by Addon.NavModules (each module registers
  -- itself — see Modules/*/*.lua). New modules just show up here.
  local y = -8
  for _, entry in ipairs(Addon.NavModules) do
    local button = Widgets:NavButton({
      parent = sidebar,
      text = L[entry.labelKey] or entry.key,
      onClick = function() UI:SelectModule(entry.key) end,
    })
    button:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 0, y)
    button:SetPoint("TOPRIGHT", sidebar, "TOPRIGHT", 0, y)
    self.navButtons[entry.key] = button
    y = y - button:GetHeight()
  end

  if Addon.NavModules[1] then
    self:SelectModule(Addon.NavModules[1].key)
  end

  self.Create = nil
end

-- ============================================================================
-- `CloseSpecialWindows` Hook
-- ============================================================================

-- `CloseSpecialWindows` is called when the "Esc" key is pressed.
local closeSpecialWindows = _G.CloseSpecialWindows
_G.CloseSpecialWindows = function()
  local found = closeSpecialWindows()

  if UI:IsShown() then
    UI:Hide()
    return true
  end

  return found
end
