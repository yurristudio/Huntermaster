local ADDON_NAME, Addon = ...
local Colors = Addon:GetModule("Colors")
local DB = Addon:GetModule("DB")
local L = Addon:GetModule("Locale")
local TameableNPCs = Addon.TameableNPCs

-- Retail (Dragonflight+) rebuilds tooltip content through an async pipeline
-- (TooltipDataProcessor) instead of synchronously inside SetUnit/
-- OnTooltipSetUnit, so lines added the old-fashioned way can run too early
-- and get silently dropped once the tooltip finishes building.
-- TooltipDataProcessor.AddTooltipPostCall is the officially supported way to
-- append lines after that pipeline runs, so it's used whenever available.
-- On Classic-Era-style clients (no TooltipDataProcessor), OnTooltipSetUnit
-- is still a real script fired by GameTooltip, so that's hooked directly.
local function OnTooltipSetUnit(tooltip)
  if not DB.global.npc_tooltips then return end

  -- Get unit.
  local _, unit = tooltip:GetUnit()
  if not unit then return end

  -- Get unit type and id.
  local guid = UnitGUID(unit) or ""
  local unitType, _, _, _, _, id = strsplit("-", guid)
  if not (id and unitType == "Creature") then return end

  -- Get npc.
  local npc = TameableNPCs[id]
  if not npc then return end

  -- Header.
  tooltip:AddLine(" ")
  tooltip:AddLine(Colors.Primary(ADDON_NAME) .. (npc.is_new and ("  " .. Colors.NewTag(L.NEW)) or ""))

  -- Diet.
  if npc.diet then
    tooltip:AddDoubleLine(L.DIET, npc.diet, nil, nil, nil, 1, 1, 1)
  end

  -- Abilities already known at taming.
  if npc.abilities and #npc.abilities > 0 then
    tooltip:AddLine(Colors.Label(L.ABILITIES .. ":"))
    for _, ability in ipairs(npc.abilities) do
      tooltip:AddLine("  " .. ability, 1, 1, 1)
    end
  end

  -- Other family abilities this pet can still be trained in once tamed.
  if npc.learnable and #npc.learnable > 0 then
    tooltip:AddLine(Colors.Label(L.CAN_LEARN .. ":"))
    for _, ability in ipairs(npc.learnable) do
      tooltip:AddLine("  " .. ability, 1, 1, 1)
    end
  end

  tooltip:Show()
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
  TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnTooltipSetUnit)
else
  -- Classic-Era-style clients still fire OnTooltipSetUnit as a real script
  -- on GameTooltip — hook that directly rather than hooksecurefunc'ing
  -- SetUnit, since some clients build tooltips through a path that doesn't
  -- call SetUnit the same way (which would make that hook silently miss).
  GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnit)
end
