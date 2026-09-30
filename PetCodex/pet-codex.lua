local ADDON_NAME, Addon = ...
local Colors = Addon:GetModule("Colors")
local HBDPins = Addon:GetLibrary("HBDPins")
local L = Addon:GetModule("Locale")
local PetCodex = Addon:GetModule("PetCodex")
local PinHelper = Addon:GetModule("PinHelper")
local Theme = Addon:GetModule("Theme")
local Widgets = Addon:GetModule("Widgets")

Addon:RegisterNavModule("PetCodex", "NAV_PET_CODEX", nil, 1)

local LIST_WIDTH = 224
local ROW_HEIGHT = 28

local state = {
  rows = {},          -- native list rows, reused/pooled
  filterText = "",
  selectedId = nil,
  selectedRank = nil,
}

-- ============================================================================
-- Data helpers
-- ============================================================================

local function GetSortedAbilities()
  local list = {}
  for id, ability in pairs(Addon.TameableAbilities) do
    list[#list + 1] = { id = id, ability = ability }
  end
  table.sort(list, function(a, b) return a.ability.name < b.ability.name end)
  return list
end

local function MatchesFilter(ability, filterText)
  if filterText == "" then return true end
  return ability.name:lower():find(filterText, 1, true) ~= nil
end

-- ============================================================================
-- Detail panel (right pane)
-- ============================================================================

-- compact = true skips Family/Diet/Type (used by the Pet Families tab, where
-- those are already shown once for the whole family).
function PetCodex:RenderNPC(parent, npc, compact)
  if not npc then return end

  local LABEL_S = Colors.Label("%s:") .. " %s"
  -- Compact cards (Pet Families tab) use a larger font than AceGUI's tiny
  -- default so the list is comfortable to read.
  local size = compact and 14 or nil

  parent = Widgets:InlineGroup({
    parent = parent,
    title = Colors.Primary(npc.name) .. (npc.is_new and ("  " .. Colors.NewTag(L.NEW)) or ""),
    fullWidth = true
  })
  if size and parent.titletext then parent.titletext:SetFont(Theme.Font.body, size + 1, "") end

  local function line(text)
    Widgets:Label({
      parent = parent, fullWidth = true, text = text,
      font = size and Theme.Font.body or nil, fontHeight = size,
    })
  end

  line(LABEL_S:format(L.LEVEL, npc.level_range or L.NONE))
  line(LABEL_S:format(L.ABILITIES, (npc.abilities and #npc.abilities > 0) and table.concat(npc.abilities, ", ") or L.NONE))
  if not compact then
    line(LABEL_S:format(L.FAMILY, npc.family or L.NONE))
    line(LABEL_S:format(L.DIET, npc.diet or L.NONE))
    line(LABEL_S:format(L.TYPE, npc.type or L.NONE))
  end
  line(LABEL_S:format(L.LOCATION, npc.location or L.NONE))

  local b = Widgets:Button({
    parent = parent,
    text = L.SHOW_ON_MAP,
    onClick = function()
      local ok, err = pcall(function()
        if OpenWorldMap then
          OpenWorldMap(npc.ui_map_id)
        else
          WorldMapFrame:Show()
          WorldMapFrame:SetMapID(npc.ui_map_id)
        end
      end)

      if not ok then
        print(("|cffff0000%s error:|r %s"):format(ADDON_NAME, tostring(err)))
        return
      end

      -- Adding pins right after opening/switching the map can hit the map
      -- canvas before it's finished laying out (same class of timing issue
      -- as maximizing too early), throwing deep inside Blizzard's own
      -- MapCanvas code ("attempt to index local 'layers'") and leaving no
      -- pin placed. Waiting one frame lets the canvas finish first.
      C_Timer.After(0, function()
        local pinOk, pinErr = pcall(function()
          PinHelper:Clear()

          for _, coords in pairs(npc.coords) do
            HBDPins:AddWorldMapIconMap(
              Addon,
              PinHelper:Get(npc),
              npc.ui_map_id,
              coords.x * 0.01,
              coords.y * 0.01,
              HBD_PINS_WORLDMAP_SHOW_WORLD
            )
          end
        end)

        if not pinOk then
          print(("|cffff0000%s error:|r %s"):format(ADDON_NAME, tostring(pinErr)))
        end
      end)
    end,
  })

  if not npc.ui_map_id or #npc.coords == 0 then
    b:SetText(L.MAP_UNAVAILABLE)
    b:SetDisabled(true)
  end

  return parent
end

function PetCodex:RenderAbilityDetail(scrollWidget, ability, rankIndex)
  scrollWidget:ReleaseChildren()

  -- Back to the top whenever a different ability/rank is shown.
  if scrollWidget.scrollbar then scrollWidget.scrollbar:SetValue(0) end
  scrollWidget:SetScroll(0)

  -- Invalidates any pending deferred relayout from a previous render.
  local token = (scrollWidget.renderToken or 0) + 1
  scrollWidget.renderToken = token
  local npcGroups = {}

  local rank = ability.ranks[rankIndex]

  Widgets:Button({
    parent = scrollWidget,
    fullWidth = true,
    text = "|cFFFFFFFF" .. ability.name .. " (" .. L.RANK .. " " .. rankIndex .. ")|r",
    height = 34,
    onEnter = function()
      GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
      GameTooltip:SetHyperlink("spell:" .. rank.spell_id)
      GameTooltip:Show()
    end,
    onLeave = function() GameTooltip:Hide() end,
  })

  local petLevel = Widgets:InlineGroup({ parent = scrollWidget, title = L.PET_LEVEL, fullWidth = true })
  Widgets:Label({ parent = petLevel, fullWidth = true, text = rank.pet_level or 1 })

  local trainingCost = Widgets:InlineGroup({ parent = scrollWidget, title = L.TRAINING_COST, fullWidth = true })
  Widgets:Label({ parent = trainingCost, fullWidth = true, text = rank.training_cost or 0 })

  local learnedBy = Widgets:InlineGroup({ parent = scrollWidget, title = L.LEARNABLE_BY, fullWidth = true })
  Widgets:Label({
    parent = learnedBy,
    fullWidth = true,
    text = (#ability.learned_by > 0 and table.concat(ability.learned_by, ", ") or L.ALL_PET_FAMILIES)
  })

  local npcGroup = Widgets:InlineGroup({ parent = scrollWidget, title = L.TAMEABLE_NPCS, fullWidth = true })
  if #rank.npc_ids > 0 then
    for _, npcId in ipairs(rank.npc_ids) do
      local g = self:RenderNPC(npcGroup, Addon.TameableNPCs[tostring(npcId)])
      if g then npcGroups[#npcGroups + 1] = g end
    end
  else
    Widgets:Label({ parent = npcGroup, fullWidth = true, text = L.NONE })
  end

  -- AceGUI only lays a container out when a child is ADDED to it. Groups here
  -- are added to their parent first and filled afterwards, so the parents never
  -- learn about their children's final height -> the ScrollFrame thinks the
  -- content is short and never shows a scrollbar. Re-run layout bottom-up
  -- (NPC groups -> NPC list -> scroll frame) so heights propagate.
  local function relayout()
    if scrollWidget.renderToken ~= token then return end
    for _, g in ipairs(npcGroups) do g:DoLayout() end
    npcGroup:DoLayout()
    scrollWidget:DoLayout()
  end

  relayout()
  -- Text wrapping settles once widths are applied; do it again next frame.
  if C_Timer and C_Timer.After then C_Timer.After(0, relayout) end
end

-- Builds/rebuilds the small rank-tab strip shown above the detail scroll
-- area. Hidden entirely for single-rank abilities (most of them).
--
-- Tabs used to be laid out at a fixed 72px each with no wrapping, so any
-- ability with more ranks than fit in the bar (Claw, Bite, Cower, etc. all
-- go past 4-5 ranks) spilled its later tabs outside the frame. This now
-- sizes tabs to fit the available width and wraps onto extra rows instead,
-- growing tabBar's height as needed -- detailHost is anchored to its
-- BOTTOMLEFT so it repositions itself automatically.
local RANK_TAB_GAP = 4
local RANK_TAB_MAX_WIDTH = 70
local RANK_TAB_MIN_WIDTH = 44
local RANK_TAB_ROW_HEIGHT = 24

function PetCodex:RenderRankTabs(tabBar, ability, onSelect)
  for _, child in ipairs({ tabBar:GetChildren() }) do
    child:Hide()
    child:SetParent(nil)
  end

  local rankCount = #ability.ranks
  if rankCount <= 1 then
    tabBar:Hide()
    tabBar:SetHeight(RANK_TAB_ROW_HEIGHT)
    return
  end

  tabBar:Show()
  tabBar.tabs = {}

  local barWidth = tabBar:GetWidth()
  if not barWidth or barWidth <= 0 then barWidth = 300 end

  -- How many tabs fit per row at the minimum width, then balance the
  -- actual tab count evenly across that many rows.
  local perRow = math.max(1, math.floor((barWidth + RANK_TAB_GAP) / (RANK_TAB_MIN_WIDTH + RANK_TAB_GAP)))
  perRow = math.min(perRow, rankCount)
  local rowCount = math.ceil(rankCount / perRow)
  perRow = math.ceil(rankCount / rowCount)

  local tabWidth = math.floor((barWidth - (perRow - 1) * RANK_TAB_GAP) / perRow)
  tabWidth = math.max(RANK_TAB_MIN_WIDTH, math.min(RANK_TAB_MAX_WIDTH, tabWidth))

  for i in ipairs(ability.ranks) do
    local tab = Widgets:NavButton({
      parent = tabBar,
      text = ("%s %d"):format(L.RANK, i),
      onClick = function() onSelect(i) end,
    })
    tab.rankIndex = i
    tab:SetHeight(RANK_TAB_ROW_HEIGHT)
    tab:SetWidth(tabWidth)
    tab:ClearAllPoints()

    local col = (i - 1) % perRow
    local row = math.floor((i - 1) / perRow)
    tab:SetPoint("TOPLEFT", col * (tabWidth + RANK_TAB_GAP), -row * (RANK_TAB_ROW_HEIGHT + RANK_TAB_GAP))

    tabBar.tabs[#tabBar.tabs + 1] = tab
  end

  tabBar:SetHeight(rowCount * RANK_TAB_ROW_HEIGHT + (rowCount - 1) * RANK_TAB_GAP)
end

-- Applies the current rank selection state to an already-built tab strip.
function PetCodex:UpdateRankTabSelection(tabBar, rankIndex)
  if not tabBar.tabs then return end
  for _, tab in ipairs(tabBar.tabs) do
    tab:SetSelected(tab.rankIndex == rankIndex)
  end
end

-- ============================================================================
-- List panel (left pane)
-- ============================================================================

function PetCodex:SelectAbility(hostFrame, id)
  local ability = Addon.TameableAbilities[id]
  if not ability then return end

  state.selectedId = id
  state.selectedRank = #ability.ranks

  for _, row in ipairs(state.rows) do
    row:SetSelected(row.abilityId == id)
  end

  local function selectRank(rankIndex)
    state.selectedRank = rankIndex
    self:RenderAbilityDetail(hostFrame.detailScroll, ability, rankIndex)
    self:UpdateRankTabSelection(hostFrame.rankTabBar, rankIndex)
  end

  self:RenderRankTabs(hostFrame.rankTabBar, ability, selectRank)
  selectRank(state.selectedRank)
  hostFrame.placeholder:Hide()
end

function PetCodex:RefreshList(hostFrame)
  local abilities = GetSortedAbilities()
  local filterText = state.filterText:lower()

  -- Reset row pool visibility.
  for _, row in ipairs(state.rows) do row:Hide() end

  local shown = 0
  for _, entry in ipairs(abilities) do
    if MatchesFilter(entry.ability, filterText) then
      shown = shown + 1
      local row = state.rows[shown]

      if not row then
        row = Widgets:ListRow({
          parent = hostFrame.scrollChild,
          text = "",
          icon = nil,
          onClick = function(self) PetCodex:SelectAbility(hostFrame, self.abilityId) end,
        })
        row:SetPoint("TOPLEFT", 0, -(shown - 1) * ROW_HEIGHT)
        row:SetPoint("TOPRIGHT", 0, -(shown - 1) * ROW_HEIGHT)
        state.rows[shown] = row
      end

      row.abilityId = entry.id
      row.label:SetText(entry.ability.name .. (entry.ability.is_new and ("  " .. Colors.NewTag(L.NEW)) or ""))
      row:SetSelected(entry.id == state.selectedId)
      row:Show()
    end
  end

  hostFrame.scrollChild:SetHeight(math.max(shown * ROW_HEIGHT, 1))
end

-- ============================================================================
-- Build
-- ============================================================================

function PetCodex:Build(hostFrame)
  local searchBox = Widgets:SearchBox({
    parent = hostFrame,
    placeholder = L.SEARCH_ABILITIES,
    onTextChanged = function(text)
      state.filterText = text
      self:RefreshList(hostFrame)
    end,
  })
  searchBox:SetPoint("TOPLEFT", 8, -8)
  searchBox:SetPoint("TOPRIGHT", hostFrame, "TOPLEFT", LIST_WIDTH - 8, -8)

  -- Left: scrollable ability list.
  local scrollFrame = CreateFrame("ScrollFrame", nil, hostFrame, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", -8, -8)
  scrollFrame:SetPoint("BOTTOMLEFT", hostFrame, "BOTTOMLEFT", 8, 8)
  scrollFrame:SetWidth(LIST_WIDTH - 22)

  local scrollChild = CreateFrame("Frame", nil, scrollFrame)
  scrollChild:SetWidth(LIST_WIDTH - 22)
  scrollChild:SetHeight(1)
  scrollFrame:SetScrollChild(scrollChild)
  hostFrame.scrollChild = scrollChild

  -- Vertical divider between list and detail panel.
  local divider = hostFrame:CreateTexture(nil, "ARTWORK")
  divider:SetColorTexture(unpack(Theme.Color.border))
  divider:SetWidth(1)
  divider:SetPoint("TOP", hostFrame, "TOPLEFT", LIST_WIDTH, 0)
  divider:SetPoint("BOTTOM", hostFrame, "BOTTOMLEFT", LIST_WIDTH, 0)

  -- Right: rank tabs + detail scroll area.
  local rankTabBar = CreateFrame("Frame", nil, hostFrame)
  rankTabBar:SetHeight(24)
  rankTabBar:SetPoint("TOPLEFT", hostFrame, "TOPLEFT", LIST_WIDTH + 12, -8)
  rankTabBar:SetPoint("TOPRIGHT", -8, -8)
  hostFrame.rankTabBar = rankTabBar

  local detailHost = CreateFrame("Frame", nil, hostFrame)
  detailHost:SetPoint("TOPLEFT", rankTabBar, "BOTTOMLEFT", 0, -6)
  detailHost:SetPoint("BOTTOMRIGHT", hostFrame, "BOTTOMRIGHT", -8, 8)
  hostFrame.detailScroll = Widgets:MountScrollHost(detailHost)

  local placeholder = detailHost:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  placeholder:SetPoint("TOP", 0, -24)
  placeholder:SetText(L.SELECT_AN_ABILITY)
  hostFrame.placeholder = placeholder

  self:RefreshList(hostFrame)
end
