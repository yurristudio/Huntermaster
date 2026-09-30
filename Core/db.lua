local _, Addon = ...
local DB = Addon:GetModule("DB")

local defaults = {
  global = {
    minimapIcon = { hide = false },
    npc_tooltips = true,
    deadZone = {
      enabled = true,
      onlyInCombat = false,
      locked = false,
      scale = 1.0,
      showText = true,
      textSize = 16,
      meleeSpell = "Wing Clip",
      rangedSpell = "Auto Shot",
      point = { "CENTER", "UIParent", "CENTER", 0, -180 },
    },
  }
}

function DB:Initialize()
  local db = LibStub("AceDB-3.0"):New("__HUNTMASTER_DB__", defaults)
  setmetatable(self, { __index = db })
  self.Initialize = nil
end
