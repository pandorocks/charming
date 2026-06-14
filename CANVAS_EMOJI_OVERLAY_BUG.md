# Canvas overlay misalignment with double-width emoji

## Summary

`Charming::UI::Canvas#overlay` positions overlays based on cell count, but it does not account for glyphs that the terminal renders as two columns wide (e.g. emoji). When the underlying canvas contains double-width characters, the overlay's box-drawing borders and absolute positions become misaligned, producing broken/jagged UI.

## Reproduction

Run the example app `rpg` (in `../rpg`) and display the help overlay (`?`) while the dungeon map is visible. The map uses double-width emoji such as:

- `🧱` wall
- `🧙` player
- `🧪` potion
- `🪜` stairs
- `👺` goblin
- `🐗` orc
- `🧌` troll

The help overlay border is drawn on top of this content. The right and bottom borders shift relative to the overlay's internal text because Charming assumes each tile occupies one cell, while the terminal allocates two columns for each emoji.

## Expected behavior

Overlays should align correctly regardless of whether the underlying canvas contains single-width or double-width glyphs.

## Actual behavior

Border characters appear displaced on rows/columns that contain emoji.

## Root cause

`Canvas` and `Style`/`Theme` treat each `place`/`overlay` call as consuming a single cell. They do not use display-width measurement (e.g. `unicode-display_width` or equivalent) when computing cursor position or overlay coordinates.

## Suggested fix

1. Measure each rendered glyph's display width using a library such as `unicode-display_width`.
2. Track the actual terminal column consumed by each placed string, not just the cell index.
3. Adjust `overlay` positioning so that coordinates refer to terminal columns, not abstract cells, when content beneath may be double-width.

## Workaround used in RPG example

The `rpg` app currently avoids the issue by rendering the help overlay on a fresh, empty canvas when it is open, instead of overlaying it on top of the emoji map.

## Environment

- Charming: local development checkout
- Terminal: macOS Terminal.app / iTerm / similar
- Example app: `../rpg`
