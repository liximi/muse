# Transform 布局系统

Transform 是本 UI 框架的核心布局引擎，每个 widget 持有一个 Transform 实例来处理位置、尺寸、旋转和缩放。其设计模仿了 Unity 的 anchor-based 布局系统。

## 核心概念

### 锚点（Anchor）

锚点定义了元素在父容器中的定位基准，由 `{minx, miny, maxx, maxy}` 四个 0~1 的百分比值表示一个范围：

| 锚点模式 | 条件 | 含义 |
|----------|------|------|
| **点锚点** | `min == max` | 尺寸固定（`w`/`h`），位置由 `x`/`y` 偏移决定 |
| **拉伸锚点** | `min < max` | 尺寸自适应（由锚点范围减 padding 决定），`x`/`y` 为派生值 |

### 支点（Pivot）

`{x, y}` — 0~1 百分比，表示元素自身坐标的原点，同时也是旋转和缩放的中心。

- `{0, 0}` = 左上角
- `{0.5, 0.5}` = 中心
- `{1, 1}` = 右下角

### Padding — 唯一真相源

`{left, right, top, bottom}` — 像素偏移。所有的 setter（`setPosition`、`setSize`、`setPivot`、`setPadding`）最终都写入这四个字段。`x`/`y`/`w`/`h` 是从 padding + anchor + pivot 推导出的缓存值（只读）。

```
配置层：anchor_min, anchor_max（0~1 父容器百分比）
        pivot（0~1 自身百分比）
真相源：left, right, top, bottom（像素偏移）
缓存层：x, y, w, h（由 _recalcLayout 派生）
```

核心公式：
```lua
w = parent_w * (anchor_max_x - anchor_min_x) - left - right
h = parent_h * (anchor_max_y - anchor_min_y) - top - bottom
x = left + w * pivot_x
y = top  + h * pivot_y
```

点锚点（`min == max`）时 `anchor_w == 0`，`_recalcLayout` 仅在 `anchor_w > 0` 时才重算尺寸，否则保留 `setSize` 设定的值。构造期 `parent_w == 0` 时同样跳过尺寸计算，避免产生负尺寸。

### Setter 不变量

每个 setter 对同一轴同时更新两端 padding，保持"改 A 时 B 不变"：
- `setPosition(x)` → 同时更新 `left` 和 `right`，保持 `w` 不变
- `setSize(w)`    → 同时更新 `left` 和 `right`，保持 `x` 不变
- `setPivot(px)`  → 同时更新 `left` 和 `right`，保持 `x` 和 `w` 都不变
- `setPadding(...)` → 直接写真相源

## Widget 构造中的 datas 处理顺序

```
pivot → anchor → position → padding → size
```

后调用的 setter 覆盖前者的 padding 值。

## 公有方法

### Setters

| 方法 | 说明 |
|------|------|
| `setPosition(x, y)` | 设置位置（像素），nil 表示不修改 |
| `setSize(w, h)` | 设置尺寸（像素），nil 表示不修改 |
| `setPadding(left, right, top, bottom)` | 设置 padding（像素），nil 表示不修改 |
| `setScale(sx, sy)` | 设置缩放 |
| `setPivot(px, py)` | 设置支点（0~1），保持视觉位置不变 |
| `setAnchor(minx, miny, maxx, maxy)` | 设置锚点范围（0~1） |
| `setRotation(rot)` | 设置旋转角（弧度） |
| `setParent(parent_transform)` | 设置父 Transform（通常由 widget 树自动管理） |

### Getters（本地坐标）

| 方法 | 返回值 |
|------|--------|
| `getPosition()` | `x, y` |
| `getSize()` | `w, h` |
| `getScale()` | `scale_x, scale_y` |
| `getScaledSize()` | `w * scale_x, h * scale_y` |
| `getAnchor()` | `minx, miny, maxx, maxy` |
| `getPivot()` | `px, py` |
| `getPadding()` | `{left, right, top, bottom}` |
| `getRotation()` | 弧度（归一化到 [0, 2π)） |
| `getAABB()` | 本地轴对齐包围盒 `x, y, w, h`（考虑旋转） |
| `getBounds()` | 本地包围盒 `x, y, w, h, r` |

### Getters（全局坐标）

| 方法 | 返回值 |
|------|--------|
| `getGlobalPosition()` | 屏幕坐标 `x, y`（递归计算，考虑父级旋转和缩放） |
| `getGlobalScale()` | 累积缩放 `sx, sy` |
| `getGlobalScaledSize()` | 全局缩放后尺寸 `w, h` |
| `getGlobalRotation(no_normalize)` | 累积旋转角（弧度） |
| `getGlobalAABB()` | 全局轴对齐包围盒 `x, y, w, h` |
| `getGlobalBounds()` | 全局包围盒 `x, y, w, h, r` |

### 其他

| 方法 | 说明 |
|------|------|
| `screenToLocal(screen_x, screen_y)` | 屏幕坐标转本地坐标（考虑全局旋转和缩放） |
| `onUpdate(force)` | 更新布局计算。内部缓存上次参数，不变时跳过。`force=true` 强制重算 |

## 脏检测与缓存

`onUpdate` 内部缓存了 `left`/`right`/`top`/`bottom`、`anchor`、`pivot` 和 `parent_w`/`parent_h`。仅当任一值变化时才调用 `_recalcLayout`。每帧由 `Widget:update(dt)` 自动调用。

## 使用示例

```lua
-- 全屏填充
local fullscreen = Widget({
    anchor = {0, 0, 1, 1},
    padding = {10, 10, 10, 10}  -- 四边各留 10px
})

-- 居中固定尺寸
local centered = Widget({
    pivot = {0.5, 0.5},
    anchor = {0.5, 0.5, 0.5, 0.5},
    w = 200, h = 100,
})

-- 顶部水平拉伸、固定高度
local topbar = Widget({
    anchor = {0, 0, 1, 0},
    h = 48,
})
```

> **注意**：Text 的 `transform.w/h` 默认为 0（尺寸存在 `love.graphics.Text` 对象里）。Text 覆写了 `getCullAABB()` 保证裁剪正确，但 debug 框对 Text 可能显示零面积框。
