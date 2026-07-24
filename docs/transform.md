# Transform

布局 Transform 系统。管理 UI 元素的位置、尺寸、锚点、支点、缩放和旋转。

## 设计原则

**padding 是唯一真相源**。所有 setter（setPosition、setSize、setAnchor、setPivot）最终写入 `left`/`right`/`top`/`bottom` 字段。`_recalcLayout` 从这四个值 + 锚点 + 支点派生出 `x`/`y`/`w`/`h` 缓存值。

## 核心字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `x`, `y` | number | 缓存：位置（支点坐标） |
| `w`, `h` | number | 缓存：尺寸 |
| `left`, `right`, `top`, `bottom` | number | 真相源：四边边距 |
| `anchor_min` | {number, number} | 锚点最小比例（0~1） |
| `anchor_max` | {number, number} | 锚点最大比例（0~1） |
| `pivot` | {number, number} | 支点（自身尺寸比例 0~1） |
| `rotation` | number | 旋转角（弧度） |
| `scale_x`, `scale_y` | number | 缩放比例 |
| `parent` | Transform/nil | 父 Transform 引用 |

## 锚点机制

锚点范围 `(anchor_min, anchor_max)` 定义了子控件相对父控件的定位参考。两者相等时退化为点锚点（子控件不随父控件尺寸变化而拉伸）；两者不等时为拉伸锚点（子控件随父控件自适应）。

```
子控件 x = left + w × pivot[1]
子控件 y = top + h × pivot[2]
子控件 w = parent_w × (anchor_max[1] - anchor_min[1]) - left - right
子控件 h = parent_h × (anchor_max[2] - anchor_min[2]) - top - bottom
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `setPosition(x, y)` | 设置位置（nil = 不修改） |
| `setSize(w, h)` | 设置尺寸（nil = 不修改） |
| `setPadding(left, right, top, bottom)` | 设置边距（nil = 不修改） |
| `setAnchor(minx, miny, maxx, maxy)` | 设置锚点 |
| `setPivot(px, py)` | 设置支点 |
| `setScale(sx, sy)` | 设置缩放 |
| `setRotation(rad)` | 设置旋转（自动规范化到 0~2π） |
| `setParent(parent)` | 设置父 Transform |
| `getPosition()` | 获取位置 `x, y` |
| `getSize()` | 获取尺寸 `w, h` |
| `getGlobalPosition()` | 获取全局（屏幕）坐标（考虑所有父节点的变换） |
| `getGlobalScale()` | 获取全局累积缩放 |
| `getGlobalScaledSize()` | 获取全局缩放后尺寸 |
| `getGlobalRotation()` | 获取全局旋转 |
| `getAABB()` | 获取轴对齐包围盒（本地坐标） |
| `getGlobalAABB()` | 获取轴对齐包围盒（屏幕坐标） |
| `screenToLocal(sx, sy)` | 屏幕坐标 → 本地坐标 |
| `onUpdate(force)` | 每帧调用：检测脏，必要时重算缓存 |

## 最佳实践

- **推荐**：使用锚点范围（如 `{0, 0, 1, 1}`）实现子控件跟随父控件尺寸自适应。
- **推荐**：使用中心支点 `{0.5, 0.5}` + 中心锚点 `{0.5, 0.5, 0.5, 0.5}` 实现居中定位。
- **注意**：构造期 parent_w == 0，依赖 measure 的布局逻辑应放在首帧 update 中。
