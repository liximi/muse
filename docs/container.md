# Container（容器基类）

所有容器的基类。子控件进入 Container 后放弃自主定位权，由容器统一管理位置和尺寸。

**继承链：** `Widget` → `Container`

`addChild` / `removeChild` 自动触发重排。子类只需覆写 `_sortChildren()`，在其中调用 `fitChildInRect(child, x, y, w, h)` 定位每个子控件。

## 构造参数（datas）

```lua
{
    auto_size = boolean,     -- 开启后每次排序自动根据子控件最小尺寸调整自身尺寸，默认 false
    -- ... 也继承所有 Widget 基类参数
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `queueSort()` | 标记脏，下一帧 `_preChildrenUpdate` 自动调用 `_sortChildren()` |
| `fitChildInRect(child, x, y, w, h)` | 将子控件放入给定矩形区域内，根据其 `h_size_flags` / `v_size_flags` 决定 Fill 或 Shrink 行为 |
| `_sortChildren()` | 子类覆写，实现具体布局算法 |
| `getMinimumSize()` | 子类覆写，报告容器最小尺寸。默认返回自身 transform 尺寸 |
| `_getChildrenMinSize()` | 返回纯子控件推导的最小尺寸（不含容器自身 cap），供变化检测用 |
| `auto_size` | 属性，开启后在主轴方向自动调整尺寸 |

## SizeFlags（子控件布局意图）

每个 Widget 持有 `h_size_flags`、`v_size_flags`（默认 `FILL`）和 `stretch_ratio`（默认 1.0）：

| 标志 | 值 | 含义 |
|------|-----|------|
| `SHRINK_BEGIN` | 0 | 保持最小尺寸，靠左/上（默认值） |
| `FILL` | 1 | 填满分到的区域 |
| `EXPAND` | 2 | 参与剩余空间瓜分 |
| `SHRINK_CENTER` | 4 | 分到区域内居中（需关闭 FILL） |
| `SHRINK_END` | 8 | 分到区域内靠右/下（需关闭 FILL） |

位检测：`Utils.hasFlag(flags, flag)`。

### 示例：在容器中设置子控件行为

```lua
-- 让子控件参与剩余空间瓜分
child.h_size_flags = Utils.SIZE_FLAGS.FILL + Utils.SIZE_FLAGS.EXPAND
child.stretch_ratio = 2.0  -- 瓜分时占 2 份

-- 让子控件保持最小尺寸并居中
child.h_size_flags = Utils.SIZE_FLAGS.SHRINK_CENTER  -- 注意：这会关闭 FILL
child:setCustomMinimumSize(100, nil)
```

## fitChildInRect 行为

```
FILL：子控件填满分到的矩形区域（默认）
非 FILL：子控件保持最小尺寸，按 SHRINK_BEGIN/CENTER/END 在区域内定位
```

所有 Widget 默认 `h_size_flags = FILL`、`v_size_flags = FILL`。

## 变化检测

`_preChildrenUpdate` 用 `_getChildrenMinSize()` 每帧 poll 子控件变化。检测到容器尺寸或子控件最小尺寸变化时自动重排。

## 示例：自定义容器

```lua
local Container = require "ui.widgets.containers.container"
local MyContainer = Class(Container, function(self, datas, theme)
    Container.new(self, "MyContainer", datas, theme)
end)

function MyContainer:getMinimumSize()
    -- 返回最大子控件尺寸
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
