# VirtualList

虚拟化列表容器。仅实例化可见范围内的元素，适用于大数据量列表（数百至数千项）。

**继承链：** `Widget` → `Container` → `VirtualList`

## 构造参数（datas）

```lua
{
    itemTemplate = VirtualListItem,  -- 元素模板类（必填）
    itemSize = number,               -- 沿主轴固定尺寸（可选，模板 getItemSize 优先）
    itemDatas = table,               -- 传递给每个 item 构造的 datas（可选）
    orientation = "vertical" | "horizontal",  -- 方向，默认 "vertical"
    separation = number,             -- 间距，默认 0
}
```

## 工作原理

### 核心算法

```
visibleCount  = ceil(viewport / itemStride)    -- itemStride = itemSize + separation
instanceCount = visibleCount + 2               -- 上下各 1 个缓冲

firstIndex    = floor(scrollOffset / itemStride)
visualOffset  = -(scrollOffset % itemStride)
```

- 实例数量在容器尺寸或模板尺寸变化时重建。
- `firstIndex` 变化时全部 item 重绑数据（`bindData`）。
- 滚动通过视觉偏移实现——item 控件位置不变，仅叠加 `visualOffset`。
- 遍历 `_itemWidgets` 而非 `_visibleChildren()` 进行布局，确保隐藏的缓冲 item 保持正确位置。

### 裁剪

`onDraw`/`onPostDraw` 中设置 GPU scissor 裁剪可视区域，`onPostDraw` 中绘制滚动条。

### 最小尺寸

`_getChildrenMinSize()` 返回 `(0, 0)`——VirtualList 不参与 BoxContainer 的自动尺寸计算，需通过 anchor 或显式 setSize 指定尺寸。

## 公有方法

| 方法 | 说明 |
|------|------|
| `setData(count, getData)` | 设置数据源。`getData(index)` 按 0-based 索引返回数据 |
| `scrollTo(offset)` | 设置滚动偏移（自动 clamp） |
| `getScrollOffset()` | 获取当前滚动偏移 |
| `getMaxScroll()` | 获取最大可滚动偏移 |
| `getItems()` | 返回当前 item 控件列表 |

## VirtualListItem 模板

```lua
local VirtualListItem = require "ui.widgets.virtual_list_item"
local Class = require "dependencies.classic"

local MyItem = Class(VirtualListItem, function(self, datas, theme)
    VirtualListItem.new(self, datas, theme)
    -- 创建子控件（模板结构）
end)

-- 必须覆写：返回沿主轴的固定尺寸
function MyItem:getItemSize()
    return 48  -- 垂直列表的高度
end

-- 必须覆写：绑定数据
function MyItem:bindData(data, index)
    -- data 可能为 nil（索引超出数据范围时）
    if data then
        self.label:setText(data.title)
    end
end
```

## 示例

```lua
local list = VirtualList({
    itemTemplate = MyChatBubble,
    orientation = "vertical",
    separation = 4,
    anchor = {0, 0, 1, 1},
})
list:setData(3000, function(i) return messages[i] end)
```

## 最佳实践

- **推荐**：`getItemSize()` 必须返回固定值，不支持动态尺寸 item。
- **推荐**：`bindData` 应处理 `data == nil` 的情况（缓冲项超出数据范围时）。
- **推荐**：通过 anchor 或 `setSize` 显式指定 VirtualList 尺寸。
- **不推荐**：将 VirtualList 放入 BoxContainer 的 auto_size 链中——它的 `_getChildrenMinSize` 返回 (0,0)。
