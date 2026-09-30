# Changelog

## [Unreleased]

- New ability **Dust Cloud** (rank 1, spell 1265899, pet level 12) learnable by the Tallstrider family; known by Fleeting Plainstrider and Foreststrider. Tallstrider family is now **Defense** type and its diet includes Bread (Bread, Cheese, Fungus, Fruit).
- New Tallstrider pets: Foreststrider (id 2322, Darkshore, lvl 14-16), Galestrider (id 251661, Zephras Isle, lvl 5-6), Ornery Galestrider (id 251707, Zephras Isle, lvl 8-9), all with coordinates. Fleeting Plainstrider (Barrens) is now level 13 with a new coordinate list.
- NEW tag added to Dust Cloud, Trickster's Dance, Demoralizing Screech and Swipe, and to the new/updated Tallstrider pets.

- New zone **Zephras Isle** (zone/map ID 16593, Skyborn start zone): added Scrawny Ursera, Urs'anah, Ursera Scavenger (Claw 1), Highlands Ursera, Windsong Crawler (Claw 2), Shadowgale Ursera (Claw 3) with all coordinates. Elmpaw (Elwynn Forest, Elite) added to Claw 3. Diet/type copied from existing Bear/Crab entries; Shadowgale Ursera's level is unknown and shows "??".
- Strigid Owl coordinates replaced with the new list. The **Owl** family is now **Birds of Prey** everywhere (creatures and every ability's "learned by").
- New ability **Dismember** (rank 1, spell 1264758, pet level 12) learnable by the Crocolisk family; Deviate Crocolisk knows it (no map available for it).
- New yellow **NEW** tag (plain text, no glow) on new creatures and on Dismember: Pet Codex cards and ability list, world tooltips and map-pin tooltips. Set with `is_new = true` in the data files; it stays until removed there. Applied to all Zephras Isle pets (including the earlier Vuldren foxes), Strigid Owl, Elmpaw and Deviate Crocolisk.

- Pet Families rebuilt: families are now a horizontal, wrapping row of boxes across the top (same layout as the rank tabs on Pet Codex), and selecting one shows only Type, Can Learn and Diet underneath. Removed the per-pet list (name/level/location/abilities for every individual pet), since most pets carry no ability of their own beyond what their family can learn, so that list was mostly empty repeated entries. Per-pet detail (including Show on Map) is still available on Pet Codex.

- Fixed Pet Families showing an empty Can Learn box and nothing else after the font-size change: sized labels passed a nil font-flags argument to SetFont, which throws in this client and aborted the whole render. Flags now default to an empty string.

- Pet Families: each diet entry now has a food icon (Meat, Fish, Raw Fish, Cheese, Bread, Fungus, Fruit), looked up from the game by item ID with a generic fallback. Can Learn, Diet and the pet cards use a larger font.

- Fixed long panels not scrolling (Pet Families, and the same container in Pet Codex, Dead Zone and Settings): scrolling now uses a native scroll frame with a scroll bar instead of AceGUI's ScrollFrame, which never detected that its content was taller than the view.
- Pet Families layout simplified: header (name + pet count), pet type, then two columns - Can Learn (ability names) and Diet (one food per line) - then the Pets list with Show on Map.

- New **Pet Families** tab: a list of every pet family; selecting one shows what it can learn (abilities with ranks and required pet level) and every tameable pet in that family with level, location, abilities/ranks and a Show on Map button. Built from the existing data files, so new pets/abilities/families appear automatically once added there.

- Fixed the Pet Codex detail panel not scrolling when an ability lists several tameable NPCs: nested AceGUI groups were filled after being added to their parent, so the ScrollFrame never got the real content height. Layout is now re-run bottom-up after building, and scroll resets to the top on ability/rank change.

- Dead Zone HUD is now a distance ladder: one TGA per band (OutOfRange, MaxRange, Range35..Range10, DeadZone, Melee), stepping down as the target closes in. Detection adapted from Rangefinder3000 (item-range ladder + Raptor Strike / Auto Shot). Removed the melee/ranged spell-name settings, which are no longer used.

- Dead Zone HUD now shows only the TGA for each state: removed the colored plate/border behind the icon and the icon desaturation.

- Dead Zone HUD made bigger and clearer:
  - Icon doubled in size (36px -> 72px) so it's actually noticeable in the
    corner of the screen during combat, not just up close.
  - Added a solid colored plate behind the icon (with a thin border) so it
    reads clearly against any background — grass, snow, bright sky — instead
    of floating directly on the world. Colored per state (dim green/red/
    blue/grey) so the state is legible at a glance, not just from the icon.
  - Status text enlarged (11px -> 16px).
  - Back to loading from `Textures/*.tga` (rather than Blizzard icons), now
    with clean, correctly-formatted placeholder art — proper alpha, single
    flat layer, 256x256 (~256KB each instead of the old set's up to 16MB) —
    a grey broken-ring for Out of Range, a green reticle for In Range, a red
    warning triangle for Dead Zone, and crossed blue swords for Melee. Drop
    in your own art using the same four filenames any time; no code changes
    needed.

- Fixed the Dead Zone HUD's icon/glow rendering:
  - The melee icon (`Ability_Hunter_MeleeSpecialist`) doesn't exist in this
    client's data files and was rendering blank — swapped to a universal
    vanilla-era icon (`INV_Sword_04`) guaranteed to exist on any client.
  - The glow (`SpellActivationOverlay\IconAlert`, a Cataclysm-era file) was
    rendering as a flat tinted box instead of a glow, for the same reason —
    replaced with a flat white texture (`Buttons\WHITE8x8`, the same
    universal texture the rest of the UI already relies on) additively
    blended and colored per state, which reads as a proper soft glow.
  - Stopped tinting the ranged icon's own art with the state color (its
    baked-in scope/reticle art muddied badly under red/green tints) — the
    icon now only desaturates for "Too Far"; the ring, glow, and text carry
    the actual state color.

- Dead Zone HUD overhaul:
  - Added a genuine 4th state, **Too Far** (grey, desaturated icon), separated
    from the actual dead zone using a new long-range "probe" spell
    (default: Hunter's Mark) that has no minimum range — this is what lets
    the HUD tell "beyond max range" apart from "stuck in the gap", which a
    simple melee/ranged check alone can't do.
  - **In Range** now glows green with a slow "breathing" pulse.
  - **Dead Zone** now flashes fast (glow + status text) in red for a genuine
    alarm feel, on top of a red-tinted icon.
  - **Melee** now swaps to an actual melee-ability icon (rather than just
    recoloring the ranged icon) with blue "Melee" text.
  - Added a "Max-Range Probe Spell" field to the Dead Zone settings tab.
  - Preview HUD now cycles through all four states.

## [1.0.0] - 2026-09-26

- Rebuilt from Tamed (WoW Forever port) as **Huntmaster**, a modular hunter
  companion toolkit.
- New fully custom-skinned UI: dark hunter-themed window with header bar and
  a sidebar of feature-module tabs, replacing the stock AceGUI tree/frame
  look.
- First module: **Pet Codex** — searchable ability list, rank tabs, and NPC
  detail cards with "Show on Map" pins (all inherited functionality from
  Tamed, rebuilt on the new shell).
- Second module: **Settings** — minimap icon toggle, NPC tooltip toggle.
- Added `/hm` as a shorthand slash command alongside `/huntmaster`.
- Architecture is now modules-first: new hunter features register a sidebar
  tab and a `Build(hostFrame)` function, with no changes needed to the shell.
