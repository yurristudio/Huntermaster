local _, Addon = ...
local Colors = Addon:GetModule("Colors")
local L = Addon:GetModule("Locale")
local PetFamilies = Addon:GetModule("PetFamilies")
local Theme = Addon:GetModule("Theme")
local Widgets = Addon:GetModule("Widgets")

Addon:RegisterNavModule("PetFamilies", "NAV_PET_FAMILIES", nil, 2)

-- Family tab strip: same wrapping-row layout as the rank tabs on Pet Codex,
-- just with family names instead of rank numbers.
local TAB_MIN_WIDTH = 112
local TAB_MAX_WIDTH = 176
local TAB_ROW_HEIGHT = 26
local TAB_GAP = 6

local FONT_SIZE = 15
local ICON_SIZE = 18

local state = { tabs = {}, selected = nil }

-- ============================================================================
-- Data (built from TameableNPCs / TameableAbilities — nothing extra to edit)
-- ============================================================================
-- A pet family is any `family` used by a creature, plus any family named in an
-- ability's `learned_by` — so a family with no creatures yet still appears
-- (with a 0 count) once something in the data references it.
--
-- This tab intentionally stops at family-level info (type/diet/can-learn).
-- Many individual pets have no recorded ability of their own — only their
-- family's can-learn list applies — so a full per-pet ability listing here
-- would be mostly empty. Pet Codex is still where per-pet detail belongs.

local function BuildFamilies()
  local families = {}

  local function get(name)
    if not families[name] then
      families[name] = { name = name, count = 0, types = {}, diets = {} }
    end
    return families[name]
  end

  for _, npc in pairs(Addon.TameableNPCs) do
    if npc.family then
      local family = get(npc.family)
      family.count = family.count + 1
      if npc.type then family.types[npc.type] = true end
      for food in tostring(npc.diet or ""):gmatch("[^,]+") do
        local trimmed = food:match("^%s*(.-)%s*$")
        if trimmed ~= "" then family.diets[trimmed] = true end
      end
    end
  end

  for _, ability in pairs(Addon.TameableAbilities) do
    for _, family in ipairs(ability.learned_by or {}) do get(family) end
  end

  local list = {}
  for _, family in pairs(families) do
    local function keys(set)
      local out = {}
      for k in pairs(set) do out[#out + 1] = k end
      table.sort(out)
      return out
    end
    family.types = keys(family.types)
    family.diets = keys(family.diets)
    list[#list + 1] = family
  end
  table.sort(list, function(a, b) return a.name < b.name end)
  return list
end

-- Abilities a family can learn. An empty `learned_by` means every family.
local function AbilitiesFor(familyName)
  local result = {}
  for _, ability in pairs(Addon.TameableAbilities) do
    local learnedBy, allowed = ability.learned_by or {}, false
    if #learnedBy == 0 then
      allowed = true
    else
      for _, name in ipairs(learnedBy) do
        if name == familyName then allowed = true; break end
      end
    end
    if allowed then result[#result + 1] = ability end
  end
  table.sort(result, function(a, b) return a.name < b.name end)
  return result
end

-- ============================================================================
-- Food icons
-- ============================================================================
-- Each diet entry gets the icon of a representative food item, looked up from
-- the game by item ID. Falls back to a generic icon if the lookup fails.

local FOOD_ITEMS = {
  ["Meat"] = 117,        -- Tough Jerky
  ["Fish"] = 787,        -- Slitherskin Mackerel
  ["Raw Fish"] = 6303,   -- Raw Slitherskin Mackerel
  ["Cheese"] = 414,      -- Dalaran Sharp
  ["Bread"] = 4540,      -- Tough Hunk of Bread
  ["Fungus"] = 4605,     -- Red-speckled Mushroom
  ["Fruit"] = 4536,      -- Shiny Red Apple
}
local FALLBACK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local foodIcons = {}

local function FoodIcon(food)
  if foodIcons[food] then return foodIcons[food] end
  local icon
  local itemId = FOOD_ITEMS[food]
  if itemId then
    if C_Item and C_Item.GetItemIconByID then
      local ok, value = pcall(C_Item.GetItemIconByID, itemId)
      if ok then icon = value end
    end
    if not icon and GetItemIcon then
      local ok, value = pcall(GetItemIcon, itemId)
      if ok then icon = value end
    end
  end
  foodIcons[food] = icon or FALLBACK_ICON
  return foodIcons[food]
end

-- Larger label font than AceGUI's small default. Flags must be a string
-- ("", not nil) — passing nil throws in this client.
local function Line(parent, text)
  Widgets:Label({
    parent = parent, fullWidth = true, text = text,
    font = Theme.Font.body, fontHeight = FONT_SIZE, fontFlags = "",
  })
end

local function BigTitle(group)
  if group.titletext then group.titletext:SetFont(Theme.Font.body, FONT_SIZE + 1, "") end
end

-- ============================================================================
-- Family tab strip (top)
-- ============================================================================

function PetFamilies:RenderFamilyTabs(tabBar, families, onSelect)
  for _, child in ipairs({ tabBar:GetChildren() }) do
    child:Hide()
    child:SetParent(nil)
  end
  state.tabs = {}

  local barWidth = tabBar:GetWidth()
  if not barWidth or barWidth <= 0 then barWidth = 600 end

  local count = #families
  local perRow = math.max(1, math.floor((barWidth + TAB_GAP) / (TAB_MIN_WIDTH + TAB_GAP)))
  perRow = math.min(perRow, count)
  local rowCount = math.ceil(count / perRow)
  perRow = math.ceil(count / rowCount)

  local tabWidth = math.floor((barWidth - (perRow - 1) * TAB_GAP) / perRow)
  tabWidth = math.max(TAB_MIN_WIDTH, math.min(TAB_MAX_WIDTH, tabWidth))

  for i, family in ipairs(families) do
    local tab = Widgets:NavButton({
      parent = tabBar,
      text = ("%s (%d)"):format(family.name, family.count),
      onClick = function() onSelect(family) end,
    })
    tab.familyName = family.name
    tab:SetHeight(TAB_ROW_HEIGHT)
    tab:SetWidth(tabWidth)
    tab:ClearAllPoints()

    local col = (i - 1) % perRow
    local row = math.floor((i - 1) / perRow)
    tab:SetPoint("TOPLEFT", col * (tabWidth + TAB_GAP), -row * (TAB_ROW_HEIGHT + TAB_GAP))

    state.tabs[#state.tabs + 1] = tab
  end

  tabBar:SetHeight(rowCount * TAB_ROW_HEIGHT + (rowCount - 1) * TAB_GAP)
end

function PetFamilies:UpdateTabSelection(name)
  for _, tab in ipairs(state.tabs) do tab:SetSelected(tab.familyName == name) end
end

-- ============================================================================
-- Detail panel (bottom) — Type, Can Learn, Diet. No per-pet list.
-- ============================================================================

function PetFamilies:RenderFamily(scroll, family)
  scroll:ReleaseChildren()

  local LABEL_S = Colors.Label("%s:") .. " %s"

  Widgets:Label({
    parent = scroll, fullWidth = true,
    text = Colors.Primary(family.name) .. "  " .. Colors.Muted(L.PET_COUNT_S:format(family.count)),
    font = "GameFontNormalHuge",
  })

  if #family.types > 0 then
    Widgets:Label({ parent = scroll, fullWidth = true, text = LABEL_S:format(L.TYPE, table.concat(family.types, ", ")) })
  end

  local learn = Widgets:InlineGroup({ parent = scroll, title = L.CAN_LEARN, relativeWidth = 0.5, layout = "List" })
  BigTitle(learn)
  local abilities = AbilitiesFor(family.name)
  if #abilities == 0 then Line(learn, L.NONE) end
  for _, ability in ipairs(abilities) do
    Line(learn, ("|T%s:%d|t %s"):format(ability.icon or Addon.ICON, ICON_SIZE, Colors.White(ability.name)))
  end

  local diet = Widgets:InlineGroup({ parent = scroll, title = L.DIET, relativeWidth = 0.5, layout = "List" })
  BigTitle(diet)
  if #family.diets == 0 then Line(diet, L.NONE) end
  for _, food in ipairs(family.diets) do
    Line(diet, ("|T%s:%d|t %s"):format(FoodIcon(food), ICON_SIZE, Colors.White(food)))
  end
end

function PetFamilies:SelectFamily(hostFrame, family)
  state.selected = family.name
  self:UpdateTabSelection(family.name)
  hostFrame.placeholder:Hide()
  self:RenderFamily(hostFrame.detailScroll, family)
end

-- ============================================================================
-- Build
-- ============================================================================

function PetFamilies:Build(hostFrame)
  local families = BuildFamilies()
  self.families = families

  local tabBar = CreateFrame("Frame", nil, hostFrame)
  tabBar:SetPoint("TOPLEFT", 8, -8)
  tabBar:SetPoint("TOPRIGHT", -8, -8)
  hostFrame.tabBar = tabBar

  local divider = hostFrame:CreateTexture(nil, "ARTWORK")
  divider:SetColorTexture(unpack(Theme.Color.border))
  divider:SetHeight(1)
  divider:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, -8)
  divider:SetPoint("TOPRIGHT", tabBar, "BOTTOMRIGHT", 0, -8)

  local detailHost = CreateFrame("Frame", nil, hostFrame)
  detailHost:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -8)
  detailHost:SetPoint("BOTTOMRIGHT", hostFrame, "BOTTOMRIGHT", -8, 8)
  hostFrame.detailScroll = Widgets:MountScrollHost(detailHost)

  local placeholder = detailHost:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  placeholder:SetPoint("TOP", 0, -24)
  placeholder:SetText(L.SELECT_A_FAMILY)
  hostFrame.placeholder = placeholder

  self:RenderFamilyTabs(tabBar, families, function(family) self:SelectFamily(hostFrame, family) end)

  self.hostFrame = hostFrame
end
