# BoxContainer

Linear layout container (mirrors Godot `HBoxContainer` / `VBoxContainer`). Children are arranged sequentially along the main axis, expressing layout intent through SizeFlags.

**Inheritance chain:** `Widget` → `Container` → `BoxContainer`

## Constructor Parameters (datas)

```lua
{
    orientation = "horizontal" | "vertical",  -- layout direction, default "vertical"
    separation = number,    -- spacing between children (pixels), default 0
    alignment = "begin" | "center" | "end",   -- overall offset when no EXPAND children, default "begin"
    auto_size = boolean,    -- auto-size on main axis, default false (inherited from Container)
    -- ... also inherits all Widget / Container base parameters
}
```

## Child Properties

Set on each child to control layout:

| Field | Default | Description |
|-------|---------|-------------|
| `h_size_flags` | `FILL` (1) | Horizontal size flags (`EXPAND`=2 to grab remaining space) |
| `v_size_flags` | `FILL` (1) | Vertical size flags |
| `stretch_ratio` | `1.0` | Weight when dividing remaining space (with EXPAND) |

## Public Methods

| Method | Description |
|--------|-------------|
| `addSpacer()` | Add an elastic spacer (`Spacer`), pushing subsequent children to the end |
| `getMinimumSize()` | Child min sizes summed on main axis + spacing, max on cross axis (capped by container's own size) |
| `_getChildrenMinSize()` | Pure child-derived minimum size (without container cap), for change detection |

## Layout Algorithm (Three Pass)

```
Pass 1: collect each child's min_size / desired_size / EXPAND flag
Pass 2A: distribute by desired_size ratio ("I need this much")
    - EXPAND children → sync min upward to prevent being shrunk back
    - Non-EXPAND children → deduct desired increment from stretch pool
Pass 2B: distribute remaining by stretch_ratio ("I'm greedy")
    - Insufficient space → remove from pool, redistribute
    - Last EXPAND child absorbs floating-point rounding
Pass 3: fitChildInRect each child + alignment offset
```

## Convenience Constructors

```lua
local BoxV = require "ui.widgets.containers.box_v_container"
local BoxH = require "ui.widgets.containers.box_h_container"
```

## Examples

```lua
-- Vertical layout, children fill width
local vbox = BoxContainer({
    orientation = "vertical",
    separation = 4,
    anchor = {0, 0, 1, 1},
})

-- Fixed-height button
vbox:addChild(Button({ text = "Header", h = 40 }))

-- Elastic middle area
local content = Panel({ bg_color = Utils.RGB(40, 40, 50) })
content.v_size_flags = Utils.SIZE_FLAGS.FILL + Utils.SIZE_FLAGS.EXPAND
content.stretch_ratio = 1.0
content:setCustomMinimumSize(nil, 100)
vbox:addChild(content)

-- Spacer pushes to bottom
vbox:addSpacer()

-- Fixed-height button
vbox:addChild(Button({ text = "Footer", h = 30 }))
```

```lua
-- Horizontal layout + center alignment
local hbox = BoxContainer({
    orientation = "horizontal",
    separation = 8,
    alignment = "center",
    anchor = {0, 0, 1, 0},
    h = 48,
})
hbox:addChild(Button({ text = "Cancel", w = 80 }))
hbox:addChild(Button({ text = "OK", w = 80 }))
```

> **Note**: A plain Widget with `h = 40` placed in a container gets a height of 0 — because
> the base `getMinimumSize()` returns `(0, 0)`. Call `setCustomMinimumSize(nil, 40)` or override `getMinimumSize`.
> Button, Text, Image etc. already override this — no extra handling needed.
