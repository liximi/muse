# Container（容器基类）

所有容器的基类。子控件进入 Container 后放弃自主定位权，由容器统一管理位置和尺寸。

**继承链：** `Widget` → `Container`

## 核心契约

- `addChild` / `removeChild` 自动触发 `queueSort()`，下一帧 `_preChildrenUpdate` 自动调用 `_sortChildren()`。
- 子类只需覆写 `_sortChildren()`，在其中调用 `fitChildInRect(child, x, y, w, h)` 定位每个子控件。
- 容器覆写的是 `_preChildrenUpdate`（而非 `onUpdate`），确保排序发生在子控件 update 之前。

## 构造参数（datas）

```lua
{
    auto_size = boolean,     -- 开启后每次排序自动根据子控件最小尺寸调整自身尺寸，默认 false
    -- ... 继承所有 Widget 基类参数
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `queueSort()` | 标记脏，下一帧 `_preChildrenUpdate` 自动调用 `_sortChildren()` |
| `fitChildInRect(child, x, y, w, h)` | 将子控件放入给定矩形区域内，根据其 `h_size_flags` / `v_size_flags` 决定 Fill 或 Shrink 行为。非 FILL 时尺寸在 `[minsize, min(desired, rect_size)]` 之间。设完尺寸后立即触发 `_notifySizeChanged` 让子控件同步重排 |
| `_visibleChildren()` | 返回可见（`isShown() == true`）的子控件列表 |
| `getDesiredSize()` | 返回容器期望尺寸。默认等于 `getMinimumSize()`，子类覆写以报告基于子控件 desired_size 的尺寸 |
| `getInnerCombinedMaximumSize()` | 返回容器内部可用最大尺寸（扣除装饰后的空间）。默认返回自身尺寸 |
| `_getAllowedSizeFlagsHorizontal()` | 子类覆写，返回允许子控件使用的水平 size_flags 列表 |
| `_getAllowedSizeFlagsVertical()` | 子类覆写，返回允许子控件使用的垂直 size_flags 列表 |

### 需子类覆写的方法

| 方法 | 说明 |
|------|------|
| `_sortChildren()` | 实现具体布局算法 |
| `getMinimumSize()` | 报告容器最小尺寸。默认返回自身 transform 尺寸 |
| `_getChildrenMinSize()` | 返回纯子控件推导的最小尺寸（不含容器自身 cap），供变化检测用。默认调用 `getMinimumSize()` |

## fitChildInRect 行为

```
FILL：子控件填满分到的矩形区域（默认）
非 FILL：子控件保持最小尺寸，在区域内按 SHRINK_BEGIN/CENTER/END 定位
```

所有 Widget 默认 `h_size_flags = FILL`、`v_size_flags = FILL`。

## 变化检测

`_preChildrenUpdate` 每帧检测以下条件，任一变化即触发重排：

1. `_dirty` 标记（`queueSort()` 设置）
2. 容器自身尺寸 `w` / `h` 变化
3. `_getChildrenMinSize()` 返回值变化

使用 `_getChildrenMinSize()` 而非 `getMinimumSize()` 做检测，是因为 BoxContainer 的 `getMinimumSize()` 返回 `math.max(children, container_size)`——当容器被 anchor 撑大时，子控件尺寸增长可能被容器自身尺寸"盖住"导致漏检。

## auto_size

开启后，在主轴方向自动调整尺寸为 `_getChildrenMinSize()` 的值。子控件尺寸变化触发的重排会自动更新容器尺寸。注意 `auto_size` 的生效依赖于子类设置 `_auto_size_axis`（如 BoxContainer 在构造中设 `"h"` 或 `"v"`）。

## 示例：自定义容器

```lua
local Container = require "ui.widgets.containers.container"
local Class = require "dependencies.classic"

local MyContainer = Class(Container, function(self, datas, theme)
    Container.new(self, "MyContainer", datas, theme)
    self._auto_size_axis = "v"  -- 让 auto_size 在垂直方向生效
end)

function MyContainer:getMinimumSize()
    local mw, mh = 0, 0
    for _, c in ipairs(self.children) do
        if c:isShown() then
            local cw, ch = c:getCombinedMinimumSize()
            mw, mh = math.max(mw, cw), math.max(mh, ch)
        end
    end
    return mw, mh
end

function MyContainer:_sortChildren()
    for _, c in ipairs(self:_visibleChildren()) do
        self:fitChildInRect(c, 0, 0, self.transform.w, self.transform.h)
    end
end
```
