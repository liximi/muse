# VirtualListItem

VirtualList 的元素模板基类。所有放入 VirtualList 的 item 必须继承此类并覆写两个方法。

**继承链：** `Widget` → `VirtualListItem`

## 必须覆写的方法

### getItemSize() → along_size

返回沿主轴方向的固定尺寸（像素）。对于 vertical 列表返回高度，horizontal 列表返回宽度。

VirtualList 使用此值计算可见区域内能容纳多少个元素。返回值必须为常量——VirtualList **不支持**动态尺寸 item。

```lua
function MyItem:getItemSize()
    return 32  -- 固定 32px 高度
end
```

### bindData(data, index)

用指定索引的数据填充控件。VirtualList 滚动时调用此方法替换 item 显示的内容。

- `data` — 数据项，由 `getData(index)` 回调返回。可能为 `nil`（索引越界时）
- `index` — 数据索引（0-based）

```lua
function MyItem:bindData(data, index)
    if data then
        self.label:setText(data.title)
    else
        self.label:setText("")
    end
end
```

## 构造参数（datas）

无额外 datas 字段。VirtualList 通过 `itemDatas` 统一传递给所有 item 实例。

## 示例

```lua
local MyRow = Class(VirtualListItem, function(self, datas, theme)
    VirtualListItem.new(self, datas, theme)
    self.label = self:addChild(Text({
        font_size = 14,
        anchor = {0, 0, 1, 1},
    }))
end)

function MyRow:getItemSize()
    return 36
end

function MyRow:bindData(data, index)
    self.label:setText(data and data.text or "")
end
```
