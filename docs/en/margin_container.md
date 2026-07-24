# MarginContainer

The simplest container — adds pixel margins around its children.

**Inheritance:** `Widget` → `Container` → `MarginContainer`

## Constructor Parameters (datas)

```lua
{
    margin_left   = number,  -- Default 0
    margin_right  = number,  -- Default 0
    margin_top    = number,  -- Default 0
    margin_bottom = number,  -- Default 0
}
```

## How It Works

`_sortChildren()` subtracts the four margins from the container's own size and places children into the remaining area. `getMinimumSize()` returns child minimum size + margins.

## Example

```lua
local MarginContainer = require "ui.widgets.containers.margin_container"

local mc = MarginContainer({
    margin_left = 16, margin_right = 16,
    margin_top = 8, margin_bottom = 8,
    anchor = {0, 0, 1, 1},
})
mc:addChild(Text({ text = "Content with margins" }))
```

## Best Practices

- MarginContainer has no visual style. For colored margin areas, use Panel with padding.
- Prefer MarginContainer over setting child padding directly.
