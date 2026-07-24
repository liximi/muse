# Widget（基类）

所有 UI 元素的基类，提供树形结构、Transform 布局、事件处理、生命周期管理和尺寸测量等核心机制。

**继承链：** `Class` → `Widget`

## 构造参数（datas）

```lua
{
    -- 布局
    pivot = {x, y},           -- 支点，0~1 比例，默认 {0, 0}
    anchor = {minx, miny, maxx, maxy},  -- 锚点，默认 {0, 0, 0, 0}
    x = number,               -- 位置 X（像素）
    y = number,               -- 位置 Y（像素）
    w = number,               -- 宽度（像素）
    h = number,               -- 高度（像素）
    sx = number,              -- 水平缩放，默认 1
    sy = number,              -- 垂直缩放，默认 1
    padding = {left, right, top, bottom},  -- 内边距（像素）
    r = number,               -- 旋转角（弧度）

    -- SizeFlags（容器布局中使用）
    h_size_flags = number,    -- 水平 SizeFlags，默认 FILL(1)
    v_size_flags = number,    -- 垂直 SizeFlags，默认 FILL(1)
    stretch_ratio = number,   -- EXPAND 时瓜分权重，默认 1.0
    custom_minimum_size = {w, h},  -- 覆盖内容最小尺寸
}
```

构造时支持两种签名：

```lua
Widget(datas, theme)
Widget(name, datas, theme)  -- 当第一个参数为字符串时作为名称
```

## 工作原理

### Transform 布局

每个 Widget 持有一个 `Transform` 实例。Transform 以 `padding`（left/right/top/bottom）为唯一真相源，所有 setter（setPosition、setSize、setAnchor、setPivot）最终写入 padding 字段，再由 `_recalcLayout` 派生出 `x`/`y`/`w`/`h` 缓存值。

### 更新生命周期

```lua
function Widget:update(dt, parent_should_update)
    self.transform:onUpdate()         -- 1. Transform 脏检测（重算 x/y/w/h）
    -- SizeChanged 事件检测           -- 2. 若开启，对比新旧 w/h
    self:_preChildrenUpdate(dt)       -- 3. 钩子（Container 在此排序）
    for child in children do          -- 4. 子控件 update
        child:update(dt, true)
    end
    self:onUpdate(dt)                 -- 5. 自身 update
end
```

### 事件传播

事件从末尾子节点向开头遍历（倒序），子节点返回 `true` 即拦截事件，不再向同级更早的节点传播。子节点全部处理完毕后才调用自身 handler。

### 射线检测（raycast_target）

子节点递归和自身 handler 之后有一个 fallback：若 `raycast_target = true` 且鼠标在 `regionDetection` 区域内，返回 `true` 阻断穿透。

**注意**：`WheelMoved` 事件不受此 fallback 影响——滚轮事件应穿透到可滚动的父容器。

## 子节点管理

| 方法 | 说明 |
|------|------|
| `addChild(child)` | 添加子节点。自动检测循环引用，从旧父节点移除；若新父节点已在活动树中则自动传播 attached 状态 |
| `removeChild(child)` | 移除子节点 |
| `removeAllChildren()` | 移除所有子节点（保留 widget 对象，不销毁） |
| `clearChildren()` | 移除并递归销毁所有子节点（释放 GPU 资源），适用于面板重建等不再需要内容的场景 |

> **最佳实践**：切换内容（如 TabView、ListContainer）使用 `removeAllChildren`；彻底清理（如测试切换）使用 `clearChildren`。

## 尺寸测量

| 方法 | 说明 |
|------|------|
| `getMinimumSize()` | 返回内容最小自然尺寸。默认返回 `(0, 0)`，子类覆写以报告基于实际内容的尺寸 |
| `getCombinedMinimumSize()` | `max(getMinimumSize(), custom_minimum)`，容器实际使用的值 |
| `setCustomMinimumSize(w, h)` | 设置自定义最小尺寸，`nil` 表示不限制该维度 |
| `getDesiredSize()` | 期望的自然尺寸，默认等于 `getCombinedMinimumSize()`。Text 覆写为完整文本宽度 |
| `measure(max_w, max_h)` | 查询自然尺寸，返回 `{w, h}`。默认返回当前 transform 尺寸 |

> **重要**：普通 Widget 设置 `h = 40` 但不覆写 `getMinimumSize` 也不设 `custom_minimum_size` 时，容器可能分配 0 高度。Button、Text、Image 等已内置覆写。自定义控件放入容器时，推荐在 datas 中传 `custom_minimum_size` 或调用 `setCustomMinimumSize`。

## 显示控制

| 方法 | 说明 |
|------|------|
| `show()` | 显示（失效渲染缓存） |
| `hide()` | 隐藏（失效渲染缓存） |
| `isShown()` | 是否可见 |

## 启用/禁用

| 方法 | 说明 |
|------|------|
| `enable()` | 启用（触发 `onEnabled`） |
| `disable()` | 禁用（触发 `onDisabled`） |
| `isEnabled()` | 是否启用 |

## 焦点

| 方法 | 说明 |
|------|------|
| `setFocus()` | 请求焦点 |
| `removeFocus()` | 移除焦点 |
| `isFocus()` | 是否有焦点 |

## Z 轴排序

| 方法 | 说明 |
|------|------|
| `moveToTop()` | 移到同级最上层（最后绘制） |
| `moveToBottom()` | 移到同级最下层（最先绘制） |

## 事件处理器

子类覆写以下方法以响应事件（命名规则：`on` + PascalCase 事件名）：

| 处理器 | 触发时机 |
|--------|----------|
| `onUpdate(dt)` | 每帧更新（在子节点之后） |
| `onDraw()` | 自身绘制（在子节点之前） |
| `onPostDraw()` | 子节点绘制完毕后 |
| `onMousePressed(x, y, button)` | 鼠标按下 |
| `onMouseReleased(x, y, button)` | 鼠标释放 |
| `onMouseMoved(x, y, dx, dy)` | 鼠标移动 |
| `onWheelMoved(x, y)` | 滚轮 |
| `onKeyPressed(key, isrepeat)` | 键盘按下 |
| `onKeyReleased(key)` | 键盘释放 |
| `onTextInput(text)` | 文本输入 |
| `onFocus()` | 获得焦点 |
| `onRemoveFocus()` | 失去焦点 |
| `onEnabled()` | 被启用 |
| `onDisabled()` | 被禁用 |
| `onSizeChanged(w, h)` | 尺寸变化（需先调用 `enableSizeChangedEvent(true)`） |
| `onHovered(hovered, x, y, dx, dy)` | 鼠标进入/离开（需通过 `Components.addHoverState` 混入） |

## SizeFlags

每个 Widget 持有以下布局属性，由父容器在布局时读取：

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `h_size_flags` | number | `FILL` (1) | 水平 SizeFlags 位标志 |
| `v_size_flags` | number | `FILL` (1) | 垂直 SizeFlags 位标志 |
| `stretch_ratio` | number | `1.0` | 开启 EXPAND 时瓜分空间的权重 |

SizeFlags 位标志（`Utils.SIZE_FLAGS`）：

| 标志 | 值 | 含义 |
|------|-----|------|
| `SHRINK_BEGIN` | 0 | 保持最小尺寸，靠左/上 |
| `FILL` | 1 | 填满分到的区域 |
| `EXPAND` | 2 | 参与剩余空间瓜分 |
| `SHRINK_CENTER` | 4 | 在区域内居中（需关闭 FILL） |
| `SHRINK_END` | 8 | 在区域内靠右/下（需关闭 FILL） |

标志通过加法组合，使用 `Utils.hasFlag(flags, flag)` 检测。

## 生命周期

| 方法/钩子 | 说明 |
|-----------|------|
| `onAttached()` | 加入 UiManager 活动树时调用（子类可覆写注册全局资源） |
| `onDetached()` | 从活动树移除时调用（子类可覆写释放全局资源） |
| `destroy()` | 递归销毁自身及所有子孙，从父节点移除 |
| `isValid()` | 检查是否有效（未被销毁） |

## 裁剪与可见性

| 方法 | 说明 |
|------|------|
| `getCullAABB()` | 返回用于可见性裁剪的包围盒。Text 覆写以返回实际文本尺寸 |
| `_clip_rect` | 内部属性，由 Scroll 等设置，传给子节点用于 AABB 裁剪 |
| `always_draw` | 设为 `true` 跳过可见性裁剪 |

## 调试

```lua
widget:enableDebug(true)  -- 开启调试绘制（包围盒 + pivot 点），返回 self 支持链式调用
```

## 属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `transform` | Transform | 布局 Transform 实例 |
| `theme` | Theme | 当前使用的主题 |
| `children` | table | 子 widget 数组 |
| `parent` | Widget/nil | 父 widget |
| `enabled` | boolean | 是否启用 |
| `shown` | boolean | 是否可见 |
| `focus` | boolean | 是否有焦点 |
| `focusable` | boolean | 是否可通过 Tab 键获取焦点 |
| `raycast_target` | boolean | 射线检测 fallback 开关 |
| `render_layer` | number | 渲染层级（0=BASE, 50=OVERLAY, 80=DROPDOWN, 100=TOOLTIP） |

## 示例

```lua
local Utils = require "ui.utils"

-- 带自定义最小尺寸的容器子节点
local spacer = Widget({
    h = 40,
    custom_minimum_size = {nil, 40},
    v_size_flags = 0,  -- SHRINK_BEGIN：不填充
})
```

## 最佳实践

- **推荐**：放入容器中的自定义 Widget 应始终设置 `custom_minimum_size` 或覆写 `getMinimumSize`。
- **推荐**：使用 `removeAllChildren` 切换内容，使用 `clearChildren` 彻底清理。
- **推荐**：组合控件内部的子 Text/Panel 应设 `raycast_target = false`，避免抢走父控件的事件。
- **不推荐**：在 `onUpdate` 中执行布局逻辑——Container 应使用 `_preChildrenUpdate`。
- **不推荐**：依赖 `transform.w/h` 来判断 Text 的实际尺寸——使用 `getDimensions()`。
