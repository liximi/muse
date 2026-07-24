# VirtualListItem

Base class for VirtualList items. Subclasses must override `getItemSize()` and `bindData()`.

**Inheritance:** `Widget` → `VirtualListItem`

## Required Overrides

| Method | Description |
|--------|-------------|
| `getItemSize()` | Return fixed size along the main axis (px). Height for vertical lists, width for horizontal |
| `bindData(data, index)` | Populate the widget with data at the given index. `data` may be `nil` (when index exceeds data range) |

## Example

```lua
local VirtualListItem = require "ui.widgets.virtual_list_item"
local Class = require "dependencies.classic"

local MyItem = Class(VirtualListItem, function(self, datas, theme)
    VirtualListItem.new(self, datas, theme)
    self.label = self:addChild(Text({ font_size = 14 }))
end)

function MyItem:getItemSize()
    return 48
end

function MyItem:bindData(data, index)
    if data then
        self.label:setText(data.title)
        self:show()
    else
        self:hide()
    end
end
```

## Best Practices

- **Do**: Call `self:hide()` when data is nil in `bindData`, and `self:show()` when data is valid.
- **Do**: Return a constant from `getItemSize()` — don't depend on transform or child dimensions.
