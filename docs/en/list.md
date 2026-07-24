# ListContainer

Linear list container with key-based diff reuse. Inherits BoxContainer, integrated into the Godot container system.

**Inheritance:** `Widget` → `Container` → `BoxContainer` → `ListContainer`

## Differences from BoxContainer

- Defaults to `auto_size = true`, `separation = 8`.
- Provides `updateItems()` — key-based diff reuse: preserves existing widgets, creates new ones, removes stale ones.

## Constructor Parameters (datas)

```lua
{
    items = {Widget, ...},    -- Initial children
    separation = number,      -- Spacing, default 8
    auto_size = boolean,      -- Auto-adjust main-axis size, default true
    -- Other parameters same as BoxContainer
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `setItems(items)` | Full replacement of children |
| `updateItems(newData, keyFn, createFn, updateFn)` | Key-based diff update |
| `insert(item, pos)` | Insert at position (nil = append) |
| `remove(item)` | Remove specified widget |
| `removeAtPos(pos)` | Remove at position and return it |

### updateItems Signature

```lua
list:updateItems(newData, keyFn, createFn, updateFn)
-- keyFn:    function(data) -> key  Extract unique key
-- createFn: function(data) -> Widget  Create new widget (required)
-- updateFn: function(widget, data)    Update existing widget (optional)
```

## Example

```lua
local list = ListContainer({
    orientation = "vertical",
    separation = 4,
})

-- Diff update (preserves widget state)
list:updateItems(
    {{id = 1, label = "A"}, {id = 2, label = "B"}},
    function(d) return d.id end,
    function(d) return Button({ text = d.label }) end,
    function(w, d) w:setText(d.label) end
)
```

## Best Practices

- **Do**: Use `updateItems` for dynamic lists (e.g., chat history) to preserve widget state (focus, selection, etc.).
- **Do**: Use stable unique identifiers for `keyFn`; avoid using data references as keys.
- **Don't**: Rebuild the entire list frequently — `setItems` destroys all old widgets.
