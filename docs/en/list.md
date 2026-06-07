# List (ListContainer)

A linear list container whose children are arranged sequentially along the main axis.

**Inheritance chain:** `Widget` → `List`

## Constructor Parameters (datas)

```lua
{
    orientation = "vertical" | "horizontal",  -- layout direction, default "vertical"
    items = {Widget, ...},       -- initial list of child elements
    space = number,              -- spacing between elements (pixels), default 8
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `setItems(items)` | Set child element list (replaces all) |
| `insert(item, pos)` | Insert an element at the given position (pos optional, defaults to end) |
| `remove(item)` | Remove the specified element |
| `removeAtPos(pos)` | Remove the element at the given position and return it |
| `layout()` | Manually trigger layout calculation |

## Auto Layout

- Children are arranged sequentially along the main axis with spacing `space`
- Container size automatically equals the sum of all child sizes + spacing
- Auto re-layout when child sizes change (detected via `measure()` each frame)

## Convenience Constructors

```lua
-- Vertical list
local ListV = require "ui.widgets.containers.list_v_container"
local list = ListV({space = 4})

-- Horizontal list
local ListH = require "ui.widgets.containers.list_h_container"
local list = ListH({space = 8})
```

## Example

```lua
local list = List({
    orientation = "vertical",
    space = 4,
    items = {
        Button({text = "Item 1", h = 30}),
        Button({text = "Item 2", h = 30}),
        Button({text = "Item 3", h = 30}),
    },
})

-- Dynamic append
list:insert(Button({text = "Item 4", h = 30}))
```
