# Transform 布局系统

Transform 是本 UI 框架的核心布局引擎，每个 widget 持有一个 Transform 实例来处理位置、尺寸、旋转和缩放。其设计类似 Unity 的 anchor-based 布局系统。

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

### Padding

`{left, right, top, bottom}` — 像素偏移，表示元素边缘到锚点范围边缘的距离。

## 构造参数（直接赋值给 `Transform()`）

```lua
{
    x = 0,              -- pivot 相对锚点范围左边缘的偏移（像素）
    y = 0,              -- pivot 相对锚点范围上边缘的偏移（像素）
    w = 0,              -- 宽度（像素）
    h = 0,              -- 高度（像素）
    rotation = 0,       -- 旋转角（弧度）
    scale_x = 1,        -- 水平缩放
    scale_y = 1,        -- 垂直缩放
    anchor_min = {0, 0},-- 锚点左上角（百分比）
    anchor_max = {0, 0},-- 锚点右下角（百分比）
    pivot = {0, 0},     -- 支点（百分比）
    left = 0,           -- 左边缘到锚点左侧距离（像素）
    right = 0,          -- 右边缘到锚点右侧距离（像素）
    top = 0,            -- 上边缘到锚点顶部距离（像素）
    bottom = 0,         -- 下边缘到锚点底部距离（像素）
}
```

## 公有方法

### Setters

| 方法 | 说明 |
|------|------|
| `setPosition(x, y)` | 设置位置，会额外影响 padding |
| `setSize(w, h)` | 设置尺寸，会额外影响 padding |
| `setPadding(left, right, top, bottom)` | 设置 padding，会额外影响坐标和尺寸 |
| `setScale(sx, sy)` | 设置缩放 |
| `setPivot(px, py)` | 设置支点，保持视觉位置不变（会额外影响坐标） |
| `setAnchor(minx, miny, maxx, maxy)` | 设置锚点，会根据模式自动更新位置或尺寸 |
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
| `getRotation()` | 弧度 |
| `getAABB()` | 本地 AABB `x, y, w, h`（考虑旋转） |
| `getBounds()` | 本地包围盒 `x, y, w, h, r` |

### Getters（全局坐标）

| 方法 | 返回值 |
|------|--------|
| `getGlobalPosition()` | 屏幕坐标 `x, y`（递归通过父级计算，考虑旋转） |
| `getGlobalScale()` | 累积缩放 `sx, sy` |
| `getGlobalScaledSize()` | 全局缩放后的尺寸 `w, h` |
| `getGlobalRotation()` | 累积旋转角（弧度） |
| `getGlobalAABB()` | 全局 AABB `x, y, w, h` |
| `getGlobalBounds()` | 全局包围盒 `x, y, w, h, r` |

### 其他

| 方法 | 说明 |
|------|------|
| `screenToLocal(screen_x, screen_y)` | 屏幕坐标转本地坐标（考虑全局旋转和缩放） |
| `onUpdate(force)` | 更新布局计算（内部缓存，参数不变时跳过） |

## 锚点模式与真相源

Transform 的布局系统基于 **padding 作为唯一真相源**（类似 Unity UGUI 的 offsetMin/offsetMax）：

```
字段分层：
  配置层：anchor_min, anchor_max（锚点范围，0~1 父容器百分比）
         pivot（支点，0~1 自身百分比）
  真相源：left, right, top, bottom（像素偏移，所有 setter 最终写入这里）
  缓存层：x, y, w, h（由 _recalcLayout 从真相源派生，只读）
```

核心公式（点锚点和拉伸锚点共用，不再分支）：
```lua
w = parent_w * (anchor_max_x - anchor_min_x) - left - right
h = parent_h * (anchor_max_y - anchor_min_y) - top - bottom
x = left + w * pivot_x
y = top  + h * pivot_y
```

点锚点（`min == max`）时 `anchor_w == 0`，公式自然退化为 `w = -left - right`。
`_recalcLayout` 仅在 `anchor_w > 0` 时才重算尺寸，否则保留 `setSize` 设定的值。

### setter 不变量

每个 setter 对同一轴同时更新两端 padding，保持"改 A 时 B 不变"：
- `setPosition(x)` → 同时更新 `left` 和 `right`，保持 `w` 不变
- `setSize(w)`    → 同时更新 `left` 和 `right`，保持 `x` 不变
- `setPivot(px)`  → 同时更新 `left` 和 `right`，保持 `x` 和 `w` 都不变
- `setPadding(...)` → 直接写真相源
- `setAnchor(...)` → 写配置层，触发重算

### 构造期 `parent_w == 0` 的保护

Widget 构造时父控件尺寸未就绪，`setPadding` 触发 `_recalcLayout` 但 `aw == 0`，
守卫跳过尺寸计算，不会产生负尺寸。依赖 `measure()` 的布局逻辑应放在首帧 `onUpdate` 中。

### Widget 构造中的 datas 处理顺序

```
pivot → anchor → position → padding → size
```

后调用的 setter 覆盖前者的 padding 值，符合"position 定位 + size 定尺寸"的直觉。

> **注意**：Text 的 `transform.w/h` 默认为 0（尺寸存在 `love.graphics.Text` 对象里而非 transform）。
> Text 覆写了 `Widget:getCullAABB()` 保证裁剪正确，但 debug 框（`drawBound`）对 Text 仍显示零面积框。

## 使用示例

```lua
-- 全屏填充的 widget
local fullscreen = Widget({
    anchor = {0, 0, 1, 1},  -- 拉伸锚点填满父容器
    padding = {10, 10, 10, 10}  -- 四边各留 10px 边距
})

-- 居中固定尺寸的 widget
local centered = Widget({
    pivot = {0.5, 0.5},       -- 以自身中心为原点
    anchor = {0.5, 0.5, 0.5, 0.5},  -- 点锚点在父容器中心
    w = 200,
    h = 100
})

-- 顶部水平拉伸、固定高度的 widget
local topbar = Widget({
    anchor = {0, 0, 1, 0},  -- 水平拉伸，顶边固定
    h = 48
})
```
