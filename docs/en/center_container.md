# CenterContainer

A container that centers its children.

**Inheritance:** `Widget` → `Container` → `CenterContainer`

## Constructor Parameters (datas)

```lua
{
    use_top_left = boolean,  -- When true, aligns children top-left (default false)
}
```

## How It Works

`_sortChildren()` computes each child's `getCombinedMinimumSize()` and places the child in the horizontal and vertical center of the container. `getMinimumSize()` returns the maximum of all children's minimum sizes.

## Example

```lua
local CenterContainer = require "ui.widgets.containers.center_container"

local cc = CenterContainer({
    anchor = {0, 0, 1, 1},
})
cc:addChild(Button({ text = "Centered", w = 120, h = 40 }))
```

## Best Practices

- Good for dialog content wrappers.
- Children with default `FILL` will stretch to fill the container, defeating centering. Disable FILL: `child.h_size_flags = 0; child.v_size_flags = 0`.
