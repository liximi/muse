# VirtualList

Virtualized list container. Only instantiates widgets within the visible range, suitable for large datasets (hundreds to thousands of items).

**Inheritance:** `Widget` → `Container` → `VirtualList`

## Constructor Parameters (datas)

```lua
{
    itemTemplate = VirtualListItem,  -- Item template class (required)
    itemSize = number,               -- Fixed size along main axis (optional; template's getItemSize takes priority)
    itemDatas = table,               -- Datas passed to each item's constructor (optional)
    orientation = "vertical" | "horizontal",  -- Direction, default "vertical"
    separation = number,             -- Spacing, default 0
}
```

## How It Works

### Core Algorithm

```
visibleCount  = ceil(viewport / itemStride)    -- itemStride = itemSize + separation
instanceCount = visibleCount + 2               -- 1 buffer above and below

firstIndex    = floor(scrollOffset / itemStride)
visualOffset  = -(scrollOffset % itemStride)
```

- Instance count is rebuilt only when container or template size changes.
- When `firstIndex` changes, all items are rebound via `bindData`.
- Scrolling is achieved via visual offset — item widget positions are fixed, with `visualOffset` overlaid.
- Layout iterates `_itemWidgets` instead of `_visibleChildren()` to keep hidden buffer items in correct positions.

### Clipping

GPU scissor is set in `onDraw`/`onPostDraw` to clip the visible area; scrollbar is drawn in `onPostDraw`.

### Minimum Size

`_getChildrenMinSize()` returns `(0, 0)` — VirtualList does not participate in BoxContainer's auto-size calculation. Size must be specified via anchor or explicit `setSize`.

## Public Methods

| Method | Description |
|--------|-------------|
| `setData(count, getData)` | Set data source. `getData(index)` returns data by 0-based index |
| `scrollTo(offset)` | Set scroll offset (auto-clamped) |
| `getScrollOffset()` | Get current scroll offset |
| `getMaxScroll()` | Get maximum scrollable offset |
| `getItems()` | Return current item widget list |

## VirtualListItem Template

```lua
local VirtualListItem = require "ui.widgets.virtual_list_item"
local Class = require "dependencies.classic"

local MyItem = Class(VirtualListItem, function(self, datas, theme)
    VirtualListItem.new(self, datas, theme)
    -- Create child widgets (template structure)
end)

-- Must override: return fixed size along main axis
function MyItem:getItemSize()
    return 48  -- height for vertical lists
end

-- Must override: bind data
function MyItem:bindData(data, index)
    -- data may be nil (when index is out of data range)
    if data then
        self.label:setText(data.title)
    end
end
```

## Example

```lua
local list = VirtualList({
    itemTemplate = MyChatBubble,
    orientation = "vertical",
    separation = 4,
    anchor = {0, 0, 1, 1},
})
list:setData(3000, function(i) return messages[i] end)
```

## Best Practices

- **Do**: `getItemSize()` must return a fixed value; dynamic-size items are not supported.
- **Do**: Handle `data == nil` in `bindData` (buffer items beyond data range).
- **Do**: Specify VirtualList size via anchor or `setSize`.
- **Don't**: Place VirtualList in a BoxContainer's auto_size chain — its `_getChildrenMinSize` returns (0,0).
