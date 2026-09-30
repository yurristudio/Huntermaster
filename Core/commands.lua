local ADDON_NAME, Addon = ...
local AceAddon = Addon:GetLibrary("AceAddon")
local Commands = Addon:GetModule("Commands")
local PinHelper = Addon:GetModule("PinHelper")
local UI = Addon:GetModule("UI")

function Commands:Initialize()
  AceAddon:RegisterChatCommand(ADDON_NAME, function(...) self:Handle(...) end)
  AceAddon:RegisterChatCommand("hm", function(...) self:Handle(...) end)
  self.Initialize = nil
end

function Commands:Handle(...)
  local s = ...

  if type(s) == "string" then
    local cmd = AceAddon:GetArgs(s)
    if cmd == "clear" then
      return PinHelper:Clear()
    end

    if cmd == "mapid" then
      -- Prints the UiMapID of wherever you're currently standing. New
      -- zones sometimes ship without one recorded in the pet data (or
      -- outside the ID range this addon scans to find one by name), which
      -- is what makes "Show on Map" fail for their creatures. Stand in the
      -- zone and run this to get the exact number to add.
      local uiMapId = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
      if uiMapId then
        local info = C_Map.GetMapInfo(uiMapId)
        print(("|cff33ff99%s|r: you're in |cffffffff%s|r, UiMapID |cffffffff%d|r"):format(
          ADDON_NAME, (info and info.name) or "?", uiMapId
        ))
      else
        print(("|cffff0000%s|r: couldn't determine your current map."):format(ADDON_NAME))
      end
      return
    end
  end

  UI:Toggle()
end
