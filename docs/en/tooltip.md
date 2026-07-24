# Tooltip

Mouse hover tooltip. Shows a floating text label after hovering over a target widget for a configurable delay.

**Inheritance:** `Widget` → `Tooltip`

> Tooltip is a parentless UiManager root widget (`render_layer = TOOLTIP = 100`), auto-registered in the constructor.

## Constructor Parameters (datas)

```lua
{
    target = Widget,       -- Target widget (required)
    text = string,         -- Tooltip text
    delay = number,        -- Hover delay in seconds, default 0.5
    max_width = number,    -- Max text width (wraps if exceeded), default 250
    offset = {x, y},       -- Offset from mouse (px), default {12, 18}
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `setText(text)` | Set tooltip text |
| `setTarget(target)` | Change target widget |

## Static Methods

| Method | Description |
|--------|-------------|
| `Tooltip.destroyAll()` | Destroy all active Tooltips |

## How It Works

- `onUpdate` polls mouse position against target's `regionDetection`.
- Accumulates hover timer; shows after `delay`.
- Hides immediately when mouse leaves target.
- Follows mouse on move; auto-flips when near screen edges.

## Example

```lua
local Tooltip = require "ui.widgets.tooltip"
local btn = Button({ text = "Hover me", w = 120, h = 32 })

local tip = Tooltip({
    target = btn,
    text = "This button does something useful",
    delay = 0.3,
    max_width = 200,
})
```
