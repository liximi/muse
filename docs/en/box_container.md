# BoxContainer

A container that arranges children linearly — horizontal (HBoxContainer) or vertical (VBoxContainer). Modeled after Godot's `BoxContainer`.

**Inheritance:** `Widget` → `Container` → `BoxContainer`

## Constructor Parameters (datas)

```lua
{
    orientation = "vertical" | "horizontal",  -- Default "vertical"
    separation  = number,    -- Spacing (px), default 0
    alignment   = "begin" | "center" | "end", -- Default "begin"
    auto_size   = boolean,   -- Auto-resize along main axis, default false
}
```

## How It Works

Children are arranged in three allocation passes:

1. **Pass 1** — Collect `getCombinedMinimumSize()` and `getDesiredSize()`, record EXPAND flags and stretch_ratio.
2. **Pass 2A** — Distribute by desired_size proportionally.
3. **Pass 2B** — Distribute remaining space by stretch_ratio among EXPAND children. Last EXPAND absorbs rounding error.
4. **Pass 3** — `fitChildInRect` each child; apply alignment offset when no EXPAND children.

## Public Methods

| Method | Description |
|--------|-------------|
| `addSpacer()` | Add flexible spacer; pushes subsequent children to main axis end |

## SizeFlags

| Flag | Value | Meaning |
|------|-------|---------|
| `FILL` | 1 | Fill allocated area (default) |
| `EXPAND` | 2 | Participate in remaining space distribution |
| `SHRINK_CENTER` | 4 | Center in area (disable FILL) |
| `SHRINK_END` | 8 | Align right/bottom (disable FILL) |
| `SHRINK_BEGIN` | 0 | Minimum size, align left/top |

## Minimum Size

`getMinimumSize()` returns `math.max(children_sum, container_size)`.

## auto_size

When enabled, auto-resizes along the main axis to `_getChildrenMinSize()` on each resort.

## Convenience Constructors

```lua
local HBoxContainer = require "ui.widgets.containers.box_h_container"
local hbox = HBoxContainer({separation = 8})

local VBoxContainer = require "ui.widgets.containers.box_v_container"
local vbox = VBoxContainer({separation = 4})
```

## Example

```lua
-- VBox with spacer pushing bottom button
local vbox = VBoxContainer({ anchor = {0, 0, 1, 1}, separation = 4 })
vbox:addChild(Button({ text = "First" }))
vbox:addSpacer()
vbox:addChild(Button({ text = "Bottom" }))

-- HBox: fixed label + expanding value
local hbox = HBoxContainer({ anchor = {0, 0, 1, 0}, h = 32, separation = 8 })
hbox:addChild(Text({ text = "Name:", h_size_flags = 0 }))
hbox:addChild(Text({ text = "John Doe", h_size_flags = Utils.SIZE_FLAGS.FILL + Utils.SIZE_FLAGS.EXPAND }))
```
