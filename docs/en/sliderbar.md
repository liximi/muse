# SliderBar

A slider component supporting horizontal and vertical orientation. Consists of a track background and a draggable thumb (Button).

**Inheritance chain:** `Widget` → `SliderBar`

## Constructor Parameters (datas)

```lua
{
    orientation = "vertical" | "horizontal",  -- orientation, default "vertical"
    max_limit = number,           -- maximum value, default 1
    block_length_percent = number, -- thumb length as proportion of track 0~1, default 0.1
    block_min_len = number,       -- minimum thumb length (pixels), default 0
    step = number,               -- step size, default 0 (continuous). >0 snaps value to step multiples
    sensitivity = number,         -- click track / scroll wheel sensitivity, default 0.8
    on_value_update = function(value, percent),  -- value change callback
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `setValue(val)` | Set current value (0 ~ max_limit), does not trigger callback |
| `setPercent(percent)` | Set value by percentage (0~1) |
| `setMaxLimit(max)` | Set maximum value (auto-clamps current value and triggers callback) |
| `setBlockLengthPercent(percent)` | Set thumb length ratio (auto-clamped to 0~1) |
| `setOnValueUpdateFn(callback_fn)` | Set the value change callback function |

## Interaction

| Action | Behavior |
|--------|----------|
| Drag thumb | Real-time value update |
| Click empty track area | Step toward click position (delta = thumb length × sensitivity) |
| Long-press track | Repeat step every 0.25 seconds |
| Window resize | Thumb size and rounding auto-adapt |

## Step Mode

The `step` parameter controls value granularity:

| step value | Mode | Example (max_limit=100) |
|-----------|------|-------------------------|
| 0 or nil | Continuous float | Can drag to 37.2, 81.5, etc. |
| 1 | Integer step | Values only take 0, 1, 2, ..., 100 |
| 5 | Multiple of 5 | Values only take 0, 5, 10, ..., 100 |
| 0.5 | Half-integer | Values only take 0, 0.5, 1.0, ..., 100 |

Step snapping applies to all interactions (drag, track click, long-press). `setValue`/`setPercent` also auto-snap.

## Thumb Rounding

Both ends of the thumb are semi-circular. The corner radius is calculated from the thin-edge dimension (width for vertical sliders, height for horizontal sliders), and is kept in sync in `onSizeChanged` and `setBlockLengthPercent`.

## Convenience Constructors

```lua
-- Horizontal slider
local SliderBarH = require "ui.widgets.sliderbar_h"
local h = SliderBarH({h = 12, anchor = {0, 0, 1, 0}})

-- Vertical slider
local SliderBarV = require "ui.widgets.sliderbar_v"
local v = SliderBarV({w = 12, anchor = {0, 0, 0, 1}})
```

## Example

```lua
-- Continuous mode (default)
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
int_slider:setValue(90)  -- value is always an integer
```
