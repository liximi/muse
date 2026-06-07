# Tooltip

A mouse hover tooltip component that appears after hovering over a target widget for a specified delay.

**Inheritance chain:** `Widget` → `Tooltip`

## Constructor Parameters (datas)

```lua
{
    target = Widget,              -- target widget (required)
    text = string,                -- tooltip text
    delay = number,               -- hover delay (seconds), default 0.5
    max_width = number,           -- maximum text width (pixels), default 250
    offset = {x, y},              -- offset relative to mouse cursor (pixels), default {12, 18}
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `setText(text)` | Set tooltip text |
| `setTarget(target)` | Replace target widget |
| `destroy()` | Destroy the tooltip and remove from UiManager |

## Static Methods

| Method | Description |
|--------|-------------|
| `Tooltip.destroyAll()` | Destroy all active Tooltips (used when switching test scenes) |

## Behavior

- Renders on the topmost layer (`render_layer = TOOLTIP = 100`)
- Registered directly with UiManager as a root widget (avoids parent container offset interference)
- Auto-flips to avoid screen edges (flips to left/top when right/bottom space is insufficient)
- Auto-hides when target widget is not operational

## Example

```lua
local btn = Button({text = "Hover me", w = 100, h = 30})
local tip = Tooltip({
    target = btn,
    text = "This is a tooltip message",
    delay = 0.3,
    offset = {10, 20},
})
```
