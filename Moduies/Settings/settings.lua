local _, Addon = ...
local DB = Addon:GetModule("DB")
local L = Addon:GetModule("Locale")
local MinimapIcon = Addon:GetModule("MinimapIcon")
local Settings = Addon:GetModule("Settings")
local Widgets = Addon:GetModule("Widgets")

Addon:RegisterNavModule("Settings", "NAV_SETTINGS", nil, 99)

function Settings:Build(hostFrame)
  local scroll = Widgets:MountScrollHost(hostFrame)

  Widgets:Heading(scroll, L.GENERAL)

  local general = Widgets:InlineGroup({ parent = scroll, title = L.GENERAL, fullWidth = true })

  Widgets:CheckBox({
    parent = general,
    label = L.MINIMAP_ICON,
    tooltip = L.MINIMAP_ICON_TOOLTIP,
    get = function() return not DB.global.minimapIcon.hide end,
    set = function() MinimapIcon:Toggle() end,
  })

  Widgets:CheckBox({
    parent = general,
    label = L.NPC_TOOLTIPS,
    tooltip = L.NPC_TOOLTIPS_TOOLTIP,
    get = function() return DB.global.npc_tooltips end,
    set = function(value) DB.global.npc_tooltips = value end,
  })
end
