# Huntmaster

A hunter companion toolkit for WoW Forever. Built as a modular shell so new
hunter-focused features can be dropped in one at a time without touching
what already works.

Ported from, and MIT-licensed like, the original **Tamed** addon by Justin
Moody (see `LICENSE.md`) — Huntmaster carries the pet-ability/NPC database
forward as its first module (**Pet Codex**) under a new name, a rebuilt
modular structure, and a fully custom-skinned UI.

## Structure

```
Huntmaster.toc          Load order / metadata
libs/                   Ace3 + HereBeDragons + LibDataBroker (unchanged)
Data/                   Raw ability/NPC tables (unchanged from Tamed)
Core/                   Addon bootstrap, DB, locale, colors, slash commands,
                         tooltip hook, and the data-init pass that merges the
                         raw tables with live game data (spell names/icons,
                         zone names)
UI/                     The shell: theme.lua (palette/backdrop helpers),
                         widgets.lua (native + AceGUI-backed widgets),
                         main.lua (window, header, sidebar nav, content host),
                         minimap-icon.lua, pin-helper.lua (world map pins)
Modules/                One folder per feature module. Each module:
                         1. calls Addon:RegisterNavModule(key, labelKey, icon, order)
                            at file load time to appear in the sidebar
                         2. implements Module:Build(hostFrame), called once,
                            lazily, the first time its tab is selected
  PetCodex/              The pet-ability browser (search + rank tabs + NPC
                         locations/map pins) — today's only real feature
  Settings/              General options (minimap icon, NPC tooltips)
```

## Adding a new feature module

1. Create `Modules/<Name>/<name>.lua`.
2. Add its path to `Huntmaster.toc` under `# Modules`.
3. At the top of the file: `Addon:RegisterNavModule("<Name>", "NAV_<NAME>", nil, <order>)`.
4. Add `L["NAV_<NAME>"] = "Display Name"` to `Core/locale.lua`.
5. Implement `function <Module>:Build(hostFrame) ... end` — `hostFrame` is a
   plain, already-sized/positioned native Frame; build whatever you want
   inside it (native frames, or `Widgets:MountScrollHost(hostFrame)` if you'd
   rather lay it out with the AceGUI-backed `Widgets:Label/Button/InlineGroup/
   CheckBox/Heading` helpers already used by Pet Codex and Settings).

No changes to `UI/main.lua` are needed — it builds the sidebar from
`Addon.NavModules` automatically.
