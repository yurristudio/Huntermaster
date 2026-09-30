local _, Addon = ...
local Theme = Addon:GetModule("Theme")

-- ============================================================================
-- Palette
-- ============================================================================
-- A dark leather-and-forest palette, evoking a hunter's field journal rather
-- than a stock Blizzard/Ace3 panel.

Theme.Color = {
  background      = { 0.06, 0.07, 0.06, 0.96 }, -- near-black, faint green tint
  panel           = { 0.10, 0.11, 0.10, 0.96 },
  panelLight      = { 0.13, 0.14, 0.13, 1.00 },
  border          = { 0.24, 0.30, 0.20, 1.00 }, -- muted forest border
  accent          = { 0.67, 0.83, 0.45, 1.00 }, -- hunter green (matches Colors.Primary)
  accentDim       = { 0.67, 0.83, 0.45, 0.35 },
  gold            = { 1.00, 0.82, 0.00, 1.00 },
  text            = { 0.92, 0.92, 0.90, 1.00 },
  textMuted       = { 0.62, 0.62, 0.60, 1.00 },
  navIdle         = { 0.00, 0.00, 0.00, 0.00 },
  navHover        = { 1.00, 1.00, 1.00, 0.06 },
  navSelected     = { 0.67, 0.83, 0.45, 0.16 },
}

-- ============================================================================
-- Backdrops
-- ============================================================================

Theme.Backdrop = {
  main = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  },
  panel = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  },
}

-- ============================================================================
-- Fonts
-- ============================================================================

Theme.Font = {
  title = "Fonts\\FRIZQT__.TTF",
  body = "Fonts\\FRIZQT__.TTF",
}

-- ============================================================================
-- Helpers
-- ============================================================================

-- Applies a flat-color backdrop (bg + 1px border) to `frame` using `backdrop`
-- (one of Theme.Backdrop.*), `bgColor`, and `borderColor`.
function Theme:Skin(frame, backdrop, bgColor, borderColor)
  frame:SetBackdrop(backdrop)
  frame:SetBackdropColor(unpack(bgColor))
  frame:SetBackdropBorderColor(unpack(borderColor))
end

-- Creates a flat-colored texture that fills `parent` — used for row
-- highlights, dividers, and header bars instead of Blizzard art.
function Theme:Fill(parent, color, layer)
  local tex = parent:CreateTexture(nil, layer or "BACKGROUND")
  tex:SetAllPoints(parent)
  tex:SetColorTexture(unpack(color))
  return tex
end

-- Creates a 1px-tall/wide divider line.
function Theme:Divider(parent, color)
  local tex = parent:CreateTexture(nil, "ARTWORK")
  tex:SetColorTexture(unpack(color or Theme.Color.border))
  tex:SetHeight(1)
  return tex
end
