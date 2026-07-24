# Tooltip

Hover tooltip. Appears after a specified delay when hovering over a target widget, following the mouse.

**Inheritance:** `Widget` → `Tooltip`

## Constructor Parameters (datas)

```lua
{
    target = Widget,      -- Target widget (required)
    text = string,        -- Tooltip text
    delay = number,       -- Hover delay (seconds), default 0.5
    max_width = number,   -- Max text width (px), default 250
    offset = {x, y},      -- Offset from mouse (px), default {12, 18}
}
```

## How It Works

Tooltip auto-registers with UiManager at construction (no manual addWidget needed) at the `TOOLTIP` render layer (100), ensuring topmost drawing. Each frame checks whether the mouse is within the target area — displays after `delay` seconds of continuous hover, hides when the mouse leaves.

The panel follows the mouse position and auto-avoids screen edges. Text wraps within `max_width`.

## Public Methods

| Method | Description |
|--------|-------------|
| `setText(text)` | Set tooltip text |
| `setTarget(target)` | Set target widget |
| `Tooltip.destroyAll()` | Destroy all active Tooltips (for test scene switching) |

## Example

```lua
local btn = Button({ text = "Hover Me" })
local tip = Tooltip({
    target = btn,
    text = "Click to perform this action.",
    delay = 0.3,
})
```
