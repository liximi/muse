# ProgressBar

Progress bar component, supporting horizontal and vertical orientation. Optionally interactive for user dragging.

**Inheritance:** `Widget` → `ProgressBar`

## Constructor Parameters (datas)

```lua
{
    value = number,               -- Current progress 0~1, default 0
    orientation = string,         -- "horizontal" (default) | "vertical"
    fill_color = {r, g, b, a},    -- Fill color
    bg_color = {r, g, b, a},      -- Background color
    rounding_radius = number,     -- Corner radius, default from theme (4)

    -- Interactive mode
    interactive = boolean,           -- Allow user dragging, default false
    thumb_radius = number,           -- Thumb radius (px), auto-calculated if nil
    thumb_color = {r, g, b, a},      -- Thumb color, default = fill_color
    thumb_outline_color = {r, g, b, a},  -- Thumb outline, default nil
    thumb_outline_width = number,    -- Thumb outline width, default 2
    on_value_changed = function(value),  -- Value change callback (interactive only)
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `setValue(v)` | Set progress (0~1, auto-clamped). Triggers `on_value_changed` in interactive mode |
| `setProgress(v)` | Alias for `setValue` |
| `getValue()` | Get current progress |
| `getMinimumSize()` | Horizontal: `(0, max(h, 8))`, Vertical: `(max(w, 10), max(h, 30))` |

## Interactive Mode

When `interactive = true`:

- **Click/drag** — pressing anywhere on the bar updates progress; dragging follows mouse
- **Cursor** — changes to hand when hovering over the thumb
- **Thumb** — circular handle at the fill bar end with configurable radius and colors
- **Callback** — `on_value_changed(value)` fires on each change

## Example

```lua
-- Static
local static = ProgressBar({
    value = 0.6,
    anchor = {0, 0, 1, 0},
    h = 12,
})

-- Interactive (volume slider)
local vol = ProgressBar({
    value = 0.8,
    interactive = true,
    anchor = {0, 0, 1, 0},
    h = 14,
    fill_color = Utils.RGB(80, 180, 100),
    on_value_changed = function(val) setVolume(val) end,
})

-- Vertical interactive
local v = ProgressBar({
    orientation = "vertical",
    value = 0.5,
    interactive = true,
    anchor = {0, 0, 0, 1},
    w = 20,
})
```
