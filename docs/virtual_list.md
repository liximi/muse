# VirtualList

虚拟化列表容器。仅实例化可见区域内的元素（+ 上下各 1 个缓冲），适用于数百至数千项的大数据量列表。

**继承链：** `Widget` → `Container` → `VirtualList`

**核心思想**：每个 item 固定尺寸 → 计算可见区域能容纳多少个 → 实例化 `ceil(visible) + 2` 个控件 → 滚动时只替换数据绑定 + 视觉偏移，不创建/销毁控件。

## 构造参数（datas）

```lua
{
    itemTemplate = VirtualListItemSubclass,  -- VirtualListItem 子类（必填）
    itemSize     = number,   -- 沿主轴的固定尺寸（可选，模板 getItemSize 优先）
    itemDatas    = table,    -- 传递给每个 item 构造函数的 datas（可选）
    orientation  = "vertical" | "horizontal",  -- 默认 "vertical"
    separation   = number,   -- 子控件间距（像素），默认 0
}
```

## 公开方法

| 方法 | 说明 |
|------|------|
| `setData(count, getData)` | 设置数据源。`count` 总数，`getData(index)` 按 0-based 索引返回数据 |
| `scrollTo(offset)` | 设置滚动偏移（像素），自动 clamp 到 `[0, maxScroll]` |
| `getScrollOffset()` | 返回当前滚动偏移 |
| `getMaxScroll()` | 返回最大可滚动偏移 |
| `getItems()` | 返回当前所有 item 控件列表（用于调试/外部遍历） |

## 核心算法

```
itemStride   = itemSize + separation
visibleCount = ceil(viewport / itemStride)
instanceCount = visibleCount + 2              -- 上下各 1 个缓冲

firstIndex   = floor(scrollOffset / itemStride)
visualOffset = -(scrollOffset % itemStride)

每个 item widget 的固定布局位置 = i * itemStride
实际位置 = 固定位置 + visualOffset            ← 模拟滚动
显示数据 = getData(firstIndex + i)
```

### 实例数量何时重建

仅在以下情况触发 `_recalculate()` 重建所有实例：
- 容器尺寸变化（`_preChildrenUpdate` 检测 `transform.w/h` 变化）
- 模板尺寸变化（`_itemSize` 变化）

其余时间实例数量不变，仅通过 `bindData` 替换内容。

## 内置滚动

- **Wheel 事件**：`onWheelMoved`，40px/tick，仅当鼠标在容器区域内响应，返回 `true` 防冒泡
- **滚动条**：6px 宽，`onPostDraw` 绘制，支持拖拽滑块和点击轨道跳转
- **Scissor 裁剪**：`onDraw` / `onPostDraw` 设置 `love.graphics.setScissor`，溢出内容不可见

## 示例

```lua
-- 1. 定义模板
local RowItem = Class(VirtualListItem, function(self, datas, theme)
    VirtualListItem.new(self, datas, theme)
    self.label = self:addChild(Text({ font_size = 14, anchor = {0,0,1,1} }))
end)
function RowItem:getItemSize() return 32 end
function RowItem:bindData(data, idx)
    self.label:setText(data and data.text or "")
end

-- 2. 创建 VirtualList
local vlist = VirtualList({
    itemTemplate = RowItem,
    itemSize = 32,
    separation = 2,
    anchor = {0, 0, 1, 1},
})

-- 3. 设置数据
vlist:setData(5000, function(i)
    return { text = string.format("Item #%d", i) }
end)

-- 4. 程序化滚动
vlist:scrollTo(300)
```

## 陷阱

- **getItemSize 必须为常量**：VirtualList 不支持动态尺寸 item。所有 item 等高等宽
- **尺寸指定**：VirtualList 覆写 `_getChildrenMinSize()` 返回 (0,0)，不参与 BoxContainer 的自动尺寸计算。需通过 anchor 或显式 `setSize` 指定容器尺寸
- **隐藏 item 仍参与布局**：`_sortChildren` 遍历 `_itemWidgets` 而非 `_visibleChildren()`，确保隐藏的缓冲 item 保持正确位置
- **数据绑定时机**：`bindData` 仅在 `firstIndex` 变化时调用（非每帧）。不要在 `bindData` 中做每帧状态更新
