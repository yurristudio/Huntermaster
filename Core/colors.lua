local _, Addon = ...
local Colors = Addon:GetModule("Colors")

local colorMap = {
  Primary = "FFAAD372",   -- hunter green (survival/beast mastery accent)
  Highlight = "FFE3E34F", -- amber highlight
  Label = "FFFFD100",     -- gold label
  Muted = "FFA0A0A0",     -- muted grey for secondary text
  Danger = "FFFF4040",    -- error / warning red
  White = "FFFFFFFF",
  NewTag = "FFFFFF00",    -- plain yellow, used for the NEW label (no glow/border)
}

for name, hex in pairs(colorMap) do
  local color = CreateColorFromHexString(hex)
  Colors[name] = setmetatable({}, {
    __call = function(self, text, alpha)
      alpha = (alpha or 1) * 255
      local colorHexString = ("%.2x%.2x%.2x%.2x"):format(alpha, color:GetRGBAsBytes())
      return WrapTextInColorCode(text or "", colorHexString)
    end
  })
end
