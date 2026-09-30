local _, Addon = ...
local Colors = Addon:GetModule("Colors")
local L = Addon:GetModule("Locale")
local TameableAbilities = Addon.TameableAbilities
local TameableNPCs = Addon.TameableNPCs

-- ============================================================================
-- Spell resolution
-- ============================================================================
-- Some clients (including this one) have removed the classic `GetSpellInfo`
-- global in favor of `C_Spell.GetSpellInfo`, which returns a table instead of
-- several values. Support both, and if neither exists, leave the raw data
-- (already shipped with a name for every ability) alone instead of crashing
-- or wiping the whole pet list.

local function ResolveSpell(spellId)
  if C_Spell and type(C_Spell.GetSpellInfo) == "function" then
    local info = C_Spell.GetSpellInfo(spellId)
    if info then return info.name, info.iconID end
    return nil, nil
  end

  if type(_G.GetSpellInfo) == "function" then
    local name, _, icon = _G.GetSpellInfo(spellId)
    return name, icon
  end

  return nil, nil
end

local hasSpellAPI = (C_Spell and type(C_Spell.GetSpellInfo) == "function")
    or type(_G.GetSpellInfo) == "function"

-- Update TameableAbilities with in-game data.
if hasSpellAPI then
  for key, ability in pairs(TameableAbilities) do
    -- Remove unavailable ranks.
    for i = #ability.ranks, 1, -1 do
      local rank = ability.ranks[i]
      if ResolveSpell(rank.spell_id) == nil then
        table.remove(ability.ranks, i)
      end
    end

    -- If ability exists, update its name and icon.
    if #ability.ranks > 0 then
      local name, icon = ResolveSpell(ability.ranks[1].spell_id)
      if type(name) == "string" then
        ability.name = name
        ability.icon = type(icon) == "number" and icon or ability.icon
      end
    else
      TameableAbilities[key] = nil
    end

    if TameableAbilities[key] and not TameableAbilities[key].icon then
      TameableAbilities[key].icon = Addon.ICON
    end
  end
else
  -- No known spell API available — keep the raw ability data as shipped
  -- (it already includes a name for every ability) and just fall back to
  -- the addon icon where one isn't provided.
  for _, ability in pairs(TameableAbilities) do
    ability.icon = ability.icon or Addon.ICON
  end
end

-- Some creatures (e.g. new WoW Forever zones) ship without a `ui_map_id`.
-- Find the map by name instead, scanning the client's maps once and caching.
local mapIdsByName
local function ResolveMapByName(name)
  if not name or not (C_Map and C_Map.GetMapInfo) then return nil end
  if not mapIdsByName then
    mapIdsByName = {}
    for id = 1, 4000 do
      local ok, info = pcall(C_Map.GetMapInfo, id)
      if ok and info and info.name then
        -- Prefer a Zone map (type 3) over any other map with the same name.
        if not mapIdsByName[info.name] or info.mapType == 3 then
          mapIdsByName[info.name] = id
        end
      end
    end
  end
  return mapIdsByName[name]
end

-- Update TameableNPCs with in-game data.
for npc_id, npc in pairs(TameableNPCs) do
  npc.location = C_Map.GetAreaInfo(npc.zone_id)

  if npc.location then
    npc.ui_map_id = npc.ui_map_id or ResolveMapByName(npc.location)
    -- Add `classification` to `level_range`.
    if npc.classification then
      npc.level_range = ("%s (%s)"):format(
        npc.level_range,
        Colors.Highlight(npc.classification)
      )
    end

    -- Add `abilities` (already known at taming) and `learnable` (other
    -- family-specific abilities this pet's family can still be trained in
    -- once tamed) tables. `learnable` deliberately only ever pulls from
    -- TameableAbilities, which already excludes generic pet skills like
    -- Growl/Cower/Stamina/Armor -- it only ever contains a family's
    -- particular attack/buff abilities.
    local abilities = {}
    local knownNames = {}
    for _, ability in pairs(TameableAbilities) do
      for rankIndex, rank in ipairs(ability.ranks) do
        for _, id in ipairs(rank.npc_ids) do
          if npc_id == tostring(id) then
            knownNames[ability.name] = true
            abilities[#abilities + 1] = {
              ability.name,
              ("|T%s:0|t %s |cFF9D9D9D(%s %s)|r"):format(
                ability.icon,
                ability.name,
                L.RANK,
                rankIndex
              )
            }
          end
        end
      end
    end
    table.sort(abilities, function(a, b) return a[1] < b[1] end)
    npc.abilities = {}
    for _, v in ipairs(abilities) do npc.abilities[#npc.abilities + 1] = v[2] end

    local learnable = {}
    for _, ability in pairs(TameableAbilities) do
      if not knownNames[ability.name] then
        for _, family in ipairs(ability.learned_by) do
          if family == npc.family then
            learnable[#learnable + 1] = {
              ability.name,
              ("|T%s:0|t %s"):format(ability.icon, ability.name)
            }
            break
          end
        end
      end
    end
    table.sort(learnable, function(a, b) return a[1] < b[1] end)
    npc.learnable = {}
    for _, v in ipairs(learnable) do npc.learnable[#npc.learnable + 1] = v[2] end
  else
    TameableNPCs[npc_id] = nil
  end
end

