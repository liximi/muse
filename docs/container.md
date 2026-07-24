# Container（容器基类）

所有容器的基类。子控件进入 Container 后放弃自主定位权，由容器的 `_sortChildren()` 统一管理位置和尺寸。

**继承链：** `Widget` → `Container`

## 核心契约

- `addChild` / `removeChild` 自动调用 `queueSort()`，下一帧 `_preChildrenUpdate` 自动调用 `_sortChildren()`。
- 子类只需覆写 `_sortChildren()`，在其中调用 `fitChildInRect(child, x, y, w, h)` 定位每个子控件。
- Container 覆写的是 `_preChildrenUpdate`（而非 `onUpdate`），确保排序发生在子控件 update 之前，子控件同帧拿到容器分配的尺寸。

## 构造参数（datas）

```lua
{
    auto_size = boolean,     -- 每次排序后自动根据子控件最小尺寸调整自身尺寸，默认 false
}
```

## 工作原理

### fitChildInRect

子控件定位的核心方法。将子控件放入给定的矩形区域，根据其 `h_size_flags` / `v_size_flags` 决定 Fill 还是 Shrink 行为：

- **FILL**：子控件尺寸等于矩形尺寸（填满）。
- **非 FILL**：子控件尺寸在 `[minsize, min(desired, rect_size)]` 之间，并按 `SHRINK_BEGIN`/`SHRINK_CENTER`/`SHRINK_END` 在区域内定位。

设完尺寸后立即调用 `_notifySizeChanged`，让 Text 等控件在父容器继续排其余子控件之前完成重排。

### 变化检测

`_preChildrenUpdate` 每帧检测以下条件，任一变化即触发 `_sortChildren()`：

1. `_dirty` 标记（由 `queueSort()` 设置）
2. 容器自身尺寸 `w` / `h` 变化
3. `_getChildrenMinSize()` 返回值变化

使用 `_getChildrenMinSize()` 而非 `getMinimumSize()` 做变化检测：BoxContainer 的 `getMinimumSize()` 返回 `math.max(children, container_size)`，当容器被 anchor 撑大时，子控件尺寸增长可能被容器自身大尺寸掩盖导致漏检。`_getChildrenMinSize()` 返回纯子控件推导值，不受此影响。

### auto_size

开启后，每次重排自动将自身尺寸调整为 `_getChildrenMinSize()` 的值。`_auto_size_axis`（由子类在构造中设置）决定调整哪个维度：`"h"` 调宽度，`"v"` 调高度。

## 公有方法

| 方法 | 说明 |
|------|------|
| `queueSort()` | 标记脏，下一帧自动重排 |
| `fitChildInRect(child, x, y, w, h)` | 在给定矩形内定位子控件，根据 SizeFlags 决定 Fill/Shrink |
| `_visibleChildren()` | 返回可见子控件列表 |
| `getInnerCombinedMaximumSize()` | 返回内部可用最大尺寸（扣除装饰后） |
| `getDesiredSize()` | 期望尺寸，默认等于 `getMinimumSize()` |

## 需子类覆写的方法

| 方法 | 说明 |
|------|------|
| `_sortChildren()` | 实现具体布局算法 |
| `getMinimumSize()` | 报告容器最小尺寸 |
| `_getChildrenMinSize()` | 返回纯子控件推导的最小尺寸（不含容器 cap），供变化检测用 |
| `_getAllowedSizeFlagsHorizontal()` | 返回允许子控件使用的水平 size_flags |
| `_getAllowedSizeFlagsVertical()` | 返回允许子控件使用的垂直 size_flags |

## 示例：自定义容器

```lua
local Container = require "ui.widgets.containers.container"
local Class = require "dependencies.classic"

local MyContainer = Class(Container, function(self, datas, theme)
    Container.new(self, "MyContainer", datas, theme)
    self._auto_size_axis = "v"  -- auto_size 调整垂直方向
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

## 最佳实践

- **推荐**：在 `_sortChildren` 中遍历 `_visibleChildren()` 而非 `self.children`，自动跳过隐藏控件。
- **推荐**：`fitChildInRect` 后子控件尺寸可能变化（如文本换行），应在变化检测中处理二次排序。
- **不推荐**：直接在 `onUpdate` 中操作子控件位置——使用 `_sortChildren` 让框架在正确的时机调用。
