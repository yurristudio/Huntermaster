local ADDON_NAME, Addon = ...

-- ============================================================================
-- Consts
-- ============================================================================

Addon.VERSION = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")
Addon.ICON = "Interface\\ICONS\\Ability_Hunter_BeastTaming" -- fallback icon for abilities
Addon.LOGO = "Interface\\AddOns\\Huntmaster\\Textures\\logo" -- addon logo (minimap + addon list)

-- Ordered list of modules that appear as tabs in the main window sidebar.
-- Each entry: { key, label locale key, icon, module getter key }
-- Populated by each module file via Addon:RegisterNavModule().
Addon.NavModules = {}

function Addon:RegisterNavModule(key, labelKey, icon, order)
  self.NavModules[#self.NavModules + 1] = {
    key = key,
    labelKey = labelKey,
    icon = icon,
    order = order or (#self.NavModules + 1)
  }
  table.sort(self.NavModules, function(a, b) return a.order < b.order end)
end

-- ============================================================================
-- Functions
-- ============================================================================

do -- Addon:GetModule()
  local modules = {}

  function Addon:GetModule(key)
    key = key:upper()
    if type(modules[key]) ~= "table" then modules[key] = {} end
    return modules[key]
  end
end

do -- Addon:GetLibrary()
  local libraries = {
    AceAddon = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0"),
    AceGUI = LibStub("AceGUI-3.0"),
    HBD = LibStub("HereBeDragons-2.0"),
    HBDPins = LibStub("HereBeDragons-Pins-2.0"),
    LDB = LibStub("LibDataBroker-1.1"),
    LDBIcon = LibStub("LibDBIcon-1.0")
  }

  function Addon:GetLibrary(key)
    return libraries[key] or error("Invalid library: " .. key)
  end
end

do -- AceAddon:OnInitialize().
  local AceAddon = Addon:GetLibrary("AceAddon")

  function AceAddon:OnInitialize()
    Addon:GetModule("DB"):Initialize()
    Addon:GetModule("MinimapIcon"):Initialize()
    Addon:GetModule("Commands"):Initialize()

    -- Guarded: a problem in a newer/optional module (like DeadZone) should
    -- never be able to take the rest of the addon's init down with it.
    local ok, err = pcall(function() Addon:GetModule("DeadZone"):Initialize() end)
    if not ok then
      geterrorhandler()(err)
    end
  end
end
