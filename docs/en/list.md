# List

Linear list container arranging children sequentially along an axis. Supports efficient diff-based updates via `updateItems`.

**Inheritance:** `Widget` → `List`

> List is a direct Widget subclass (not a Container). For simple linear layouts, prefer `BoxContainer`. List's unique value is `updateItems` diff reuse — key-based add/remove/update that preserves widget state (focus, selection, etc.). `chat_history` depends on this capability.

## Constructor Parameters (datas)

```lua
{
    orientation = "vertical" | "horizontal",  -- Default "vertical"
    items = {Widget, ...},   -- Initial children
    space = number,          -- Spacing (px), default 8
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `setItems(items)` | Full replacement (destroys old state) |
| `updateItems(newData, keyFn, createFn, updateFn)` | Diff reuse update (preserves widget state) |
| `insert(item, pos)` | Insert child |
| `remove(item)` / `removeAtPos(pos)` | Remove child |

## updateItems — Diff Reuse

```lua
list:updateItems(newData, keyFn, createFn, updateFn)
-- keyFn: function(data) -> key  (nil = use data reference as key)
-- createFn: function(data) -> Widget  (required)
-- updateFn: function(widget, data)  (optional, nil = no update)
```

Example:
```lua
list:updateItems(buttons_data,
    function(d) return d.id end,
    function(d) return Button({ text = d.label }) end,
    function(w, d) w:setText(d.label) end
)
```

## layout Mechanism

`layout()` positions children along the main axis using `measure()` for natural sizes. `onUpdate` polls child size changes and re-layouts on change. List's own size is set to the total children size.

## Example

```lua
local list = List({
    orientation = "vertical",
    space = 4,
    items = { Button({ text = "A" }), Button({ text = "B" }) },
})
list:insert(Button({ text = "C" }))
```
