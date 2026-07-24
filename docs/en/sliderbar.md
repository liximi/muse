# SliderBar

Slider component supporting horizontal and vertical orientation, with continuous and integer step modes.

**Inheritance:** `Widget` → `SliderBar`

## Constructor Parameters (datas)

```lua
{
    orientation = "vertical" | "horizontal",  -- Default "vertical"
    max_limit = number,           -- Maximum value, default 1
    block_length_percent = number, -- Slider length as ratio of track, default from theme (0.1)
    block_min_len = number,       -- Minimum slider length (px), default 0
    step = number,               -- Step size, default 0 (continuous). >0 snaps to nearest multiple
    sensitivity = number,         -- Track click step sensitivity, default from theme (0.8)
    on_value_update = function(value, percent),
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `setValue(val)` | Set current value (0 ~ max_limit), no callback trigger, auto-snaps |
| `setPercent(percent)` | Set value by percentage (0~1) |
| `setMaxLimit(max)` | Set maximum value (auto-clamps and triggers callback) |
| `setBlockLengthPercent(percent)` | Set slider length ratio |
| `setOnValueUpdateFn(callback)` | Set value change callback |
| `getMinimumSize()` | Returns own transform size |

## Interaction

| Action | Behavior |
|--------|----------|
| Drag slider | Real-time value update. Step mode uses `outQuad` easing (0.15s) to snap |
| Click empty track | Step towards click direction (delta = slider size × sensitivity), with easing |
| Long press track | Repeat step every 0.25s, with easing |
| Window resize | Slider size and corner radius auto-adapt |

## Step Mode

| step Value | Mode | Example (max_limit=100) |
|-----------|------|------------------------|
| 0 or unset | Continuous float | Can drag to 37.2, 81.5, etc. |
| 1 | Integer steps | Values only: 0, 1, 2, ..., 100 |
| 5 | Multiples of 5 | Values only: 0, 5, 10, ..., 100 |
| 0.5 | Half-integers | Values only: 0, 0.5, 1.0, ..., 100 |

Step snapping applies to all interactions including `setValue`/`setPercent`.

## Convenience Constructors

```lua
local SliderBarH = require "ui.widgets.sliderbar_h"
local h = SliderBarH({h = 12, anchor = {0, 0, 1, 0}})

local SliderBarV = require "ui.widgets.sliderbar_v"
local v = SliderBarV({w = 12, anchor = {0, 0, 0, 1}})
```

## Example

```lua
-- Continuous mode
local slider = SliderBar({
    orientation = "horizontal",
    anchor = {0, 0, 1, 0},
    h = 16,
    max_limit = 100,
    block_length_percent = 0.15,
    on_value_update = function(value, percent)
        print(string.format("value: %.0f (%.0f%%)", value, percent * 100))
    end,
})
slider:setValue(50)

-- Integer step mode
local int_slider = SliderBar({
    orientation = "horizontal",
    max_limit = 120,
    step = 1,
    block_length_percent = 0.1,
    block_min_len = 15,
})
```
