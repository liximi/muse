# ProgressBar

Progress bar widget. Supports horizontal and vertical orientations, and can be switched to interactive mode for user dragging.

**Inheritance:** `Widget` → `ProgressBar`

## Constructor Parameters (datas)

```lua
{
    value = number,               -- Current progress 0~1, default 0
    orientation = "horizontal" | "vertical",  -- Direction, default "horizontal"
    fill_color = {r, g, b, a},    -- Fill color
    bg_color = {r, g, b, a},      -- Background color
    rounding_radius = number,     -- Corner radius

    -- Interactive mode
    interactive = boolean,        -- Allow user dragging, default false
    thumb_radius = number,        -- Thumb radius (px), auto-calculated by default
    thumb_color = {r, g, b, a},   -- Thumb color, defaults to fill_color
    thumb_outline_color = {r, g, b, a},  -- Thumb outline color
    thumb_outline_width = number, -- Thumb outline width, default 2
    on_value_changed = function(value),  -- Value change callback
}
```

## How It Works

- **Static mode** (`interactive = false`): Displays progress only, no mouse response.
- **Interactive mode** (`interactive = true`): Click or drag to change progress; the thumb follows the mouse.

Horizontal bars fill from the left; vertical bars fill from the bottom. In interactive mode, the thumb radius is auto-calculated as half the thin edge × 1.2, minimum 5px.

## Public Methods

| Method | Description |
|--------|-------------|
| `setValue(v)` | Set progress value (0~1) |
| `setProgress(v)` | Alias for `setValue` |
| `getValue()` | Get current value |

## Example

```lua
-- Static progress bar
local bar = ProgressBar({
    w = 200, h = 8,
    value = 0.6,
    fill_color = {0.3, 0.6, 1, 1},
    bg_color = {0.1, 0.1, 0.15, 1},
})

-- Interactive volume slider
local volume = ProgressBar({
    w = 200, h = 12,
    value = 0.8,
    interactive = true,
    on_value_changed = function(v) print("Volume:", v) end,
})
```
