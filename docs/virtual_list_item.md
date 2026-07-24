# VirtualListItem

VirtualList 的元素基类。子类必须覆写 `getItemSize()` 和 `bindData()`。

**继承链：** `Widget` → `VirtualListItem`

## 必须覆写的方法

| 方法 | 说明 |
|------|------|
| `getItemSize()` | 返回沿主轴方向的固定尺寸（像素）。垂直列表返回高度，水平列表返回宽度 |
| `bindData(data, index)` | 用指定索引的数据填充控件。`data` 可能为 `nil`（索引超出数据范围时） |

## 示例

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

## 最佳实践

- **推荐**：`bindData` 中 data 为 nil 时调用 `self:hide()`，data 有效时调用 `self:show()`。
- **推荐**：`getItemSize()` 返回常量，不要依赖 transform 或子控件尺寸。
