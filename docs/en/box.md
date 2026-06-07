# Box (BoxContainer)

A Flexbox-style layout container. Children are arranged along the main axis with support for flex-grow/flex-shrink distribution.

**Inheritance chain:** `Widget` → `Box`

## Constructor Parameters (datas)

```lua
{
    orientation = "vertical" | "horizontal",  -- layout direction, default "vertical"
    space = number,               -- spacing between children (pixels), default 0
    cross_align = "stretch" | "start" | "center" | "end",  -- cross-axis alignment, default "stretch"
}
```

## Child Element Properties

Set the following fields on each child widget to control layout behavior:

| Field | Default | Description |
|-------|---------|-------------|
| `flex_grow` | `0` | Remaining space allocation weight |
| `flex_shrink` | `1` | Shrink weight when space is insufficient |
| `flex_min_size` | `0` | Minimum main-axis size (pixels) |

## Public Methods

| Method | Description |
|--------|-------------|
| `layout()` | Manually trigger layout calculation |
| `addChild(child)` | Add a child element (auto-marks dirty layout) |
| `removeChild(child)` | Remove a child element |

Layout is automatically triggered in `onUpdate` (dirty flag), or on `onSizeChanged`.

## Layout Algorithm

1. Collect all visible children, query preferred sizes via `measure()`
2. Calculate total preferred main-axis size = sum(main_sizes) + space × (n - 1)
3. **Surplus space** → distribute by `flex_grow` weights
4. **Insufficient space** → shrink by `flex_shrink` weights (not below `flex_min_size`)
5. Cross-axis: `stretch` fills container; `start`/`center`/`end` aligns

## Convenience Constructors

```lua
local BoxV = require "ui.widgets.containers.box_v_container"
local BoxH = require "ui.widgets.containers.box_h_container"
```

## Example

```lua
local box = Box({
    orientation = "vertical",
    space = 4,
    cross_align = "stretch",
    anchor = {0, 0, 1, 1},
})

-- Fixed-height element
box:addChild(Button({text = "Header", h = 40}))

-- flex_grow fills remaining space
local content = Panel({bg_color = Utils.RGB(40, 40, 50)})
content.flex_grow = 1
content.flex_shrink = 1
content.flex_min_size = 100
box:addChild(content)

-- Fixed-height element
box:addChild(Button({text = "Footer", h = 30}))
```
