# BoxContainer

Linear container that arranges children along a single axis, supporting horizontal and vertical orientations. Equivalent to Godot's `BoxContainer`.

**Inheritance:** `Widget` → `Container` → `BoxContainer`

## Constructor Parameters (datas)

```lua
{
    orientation = "vertical" | "horizontal",  -- Layout direction, default "vertical"
    separation  = number,    -- Spacing between children (px), default 0
    alignment   = "begin" | "center" | "end", -- Overall alignment when no EXPAND children, default "begin"
    auto_size   = boolean,   -- Auto-adjust size on main axis, default false
}
```

## How It Works

BoxContainer arranges children along the main axis using a three-pass allocation algorithm:

1. **Pass 1** — Collect `getCombinedMinimumSize()` and `getDesiredSize()` for each visible child, noting EXPAND flags and `stretch_ratio`.
2. **Pass 2A** — Distribute initial space proportionally by desired_size, prioritizing each child's desired size. Increases for non-stretch children are deducted from the stretch pool.
3. **Pass 2B** — Distribute remaining space proportionally by `stretch_ratio` among EXPAND children. The last EXPAND child absorbs floating-point rounding error.
4. **Pass 3** — Call `fitChildInRect` for each child. Cross-axis stretches to container size. When no children have EXPAND, the `alignment` offset is applied.

### Minimum Size

`getMinimumSize()` returns `math.max(children_sum, container_size)` — the greater of the children's total along the main axis and the container's explicit size.

### auto_size

When enabled, automatically adjusts own size on the main axis to match the total children size (including separation).

## Convenience Constructors

```lua
local HBoxContainer = require "ui.widgets.containers.box_h_container"
local hbox = HBoxContainer({ separation = 8 })

local VBoxContainer = require "ui.widgets.containers.box_v_container"
local vbox = VBoxContainer({ separation = 4 })
```

## Public Methods

| Method | Description |
|--------|-------------|
| `addSpacer()` | Add an elastic placeholder (EXPAND + FILL) that pushes subsequent children to the end of the main axis |

## Example

```lua
local Utils = require "ui.utils"
local SZ = Utils.SIZE_FLAGS

-- VBox with Spacer pushing bottom
local vbox = VBoxContainer({ anchor = {0, 0, 1, 1}, separation = 4 })
vbox:addChild(Button({ text = "Header" }))
vbox:addSpacer()
vbox:addChild(Button({ text = "Footer" }))

-- HBox: fixed label on left, filling+expanding text on right
local hbox = HBoxContainer({ anchor = {0, 0, 1, 0}, h = 32, separation = 8 })
hbox:addChild(Text({ text = "Name:", h_size_flags = 0 }))
hbox:addChild(Text({
    text = "John Doe",
    h_size_flags = SZ.FILL + SZ.EXPAND,
}))
```

## Best Practices

- **Do**: Use `anchor = {0, 0, 1, 0}` for a VBox inside a Scroll to fill the scroll_root horizontally.
- **Do**: Combine `auto_size = true` with Scroll's `auto_track` for content-adaptive scrolling.
- **Do**: Use `addSpacer()` instead of manually inserting a Spacer widget.
- **Don't**: Place plain Widgets with dynamic sizes into a BoxContainer without setting `custom_minimum_size` — they may receive 0 size.
