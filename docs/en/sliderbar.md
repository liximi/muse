# SliderBar

Slider widget. Supports horizontal and vertical orientations, configurable thumb size, step snapping, and easing animations.

**Inheritance:** `Widget` → `SliderBar`

## Constructor Parameters (datas)

```lua
{
    orientation = "vertical" | "horizontal",  -- Direction, default "vertical"
    max_limit = number,           -- Maximum value, default 1
    block_length_percent = number, -- Thumb length as percentage of track
    block_min_len = number,       -- Thumb minimum length (px), default 0
    step = number,                -- Step size (0 = continuous, >0 = snap to multiples), default 0
    sensitivity = number,         -- Movement sensitivity when clicking track
    on_value_update = function(value, percent),  -- Value change callback
}
```

## How It Works

### Interaction

- **Drag thumb**: Drag the block directly.
- **Click track**: Clicking the track on either side of the thumb moves it with easing animation.
- **Long press track**: Holding for more than 0.25 seconds triggers continuous movement.

### Step Snapping

When `step > 0`, both drag and click snap to the nearest step multiple. During drag, the position is driven by an easing animation (`outQuad`, 0.15s) while the value updates immediately.

### Rounding

The thumb's corner radius is auto-calculated as half the thin-edge size plus 1px, producing semicircular ends.

## Example

```lua
-- Vertical slider (Scroll uses SliderBar internally)
local bar = SliderBar({
    orientation = "vertical",
    max_limit = 500,
    block_length_percent = 0.2,
    on_value_update = function(val, percent)
        print("Value:", val)
    end,
})

-- Stepped slider (snaps to multiples of 10)
local stepped = SliderBar({
    orientation = "horizontal",
    max_limit = 100,
    step = 10,
    block_length_percent = 0.1,
})
```
