# Widget（基类）

所有 UI 元素的基类。提供了树形结构、Transform 布局、事件处理、生命周期管理、尺寸测量等核心机制。

**继承链：** `Class` → `Widget`

## 构造参数（datas）

```lua
{
    pivot = {x, y},           -- 支点，0~1 百分比（默认 {0, 0}）
    anchor = {minx, miny, maxx, maxy},  -- 锚点（默认 {0, 0, 0, 0}）
    x = number,               -- 位置 X（像素）
    y = number,               -- 位置 Y（像素）
    w = number,               -- 宽度（像素）
    h = number,               -- 高度（像素）
    sx = number,              -- 水平缩放（默认 1）
    sy = number,              -- 垂直缩放（默认 1）
    padding = {left, right, top, bottom},  -- 内边距（像素）
    r = number,               -- 旋转角（弧度）
}
```

构造时也可传入可选的 `theme` 参数；签名支持三种形式：

```lua
Widget(datas, theme)
Widget(name, datas, theme)
```

## Transform 代理方法

Widget 将 Transform 的核心操作暴露为自身的便捷方法：

| 方法 | 说明 |
|------|------|
| `setPosition(x, y)` | 设置位置 |
| `getPosition()` | 获取位置 `x, y` |
| `getGlobalPosition()` | 获取全局（屏幕）坐标 |
| `getGlobalScale()` | 获取全局累积缩放 |
| `getGlobalScaledSize()` | 获取全局缩放后尺寸 |
| `regionDetection(px, py)` | 检测屏幕坐标是否在包围盒内（考虑旋转） |

## 子节点管理

| 方法 | 说明 |
|------|------|
| `addChild(child)` | 添加子 widget。自动检测循环引用，自动从旧父节点移除。若父节点已在活动树中，子节点自动获得 attached 状态 |
| `removeChild(child)` | 移除子 widget |
| `removeAllChildren()` | 移除所有子 widget（保留 widget 对象，不销毁） |
| `clearChildren()` | 移除并**递归销毁**所有子节点（释放 GPU 资源）。仅用于不再需要子节点的场景，如测试切换、面板重建。TabView/List 等需要复用内容的场景请用 `removeAllChildren` |

## 生命周期

| 方法 | 说明 |
|------|------|
| `destroy()` | 递归销毁自身及所有子孙，从父节点移除，通知 UiManager |
| `isValid()` | 检查 widget 是否有效（未被销毁） |
| `onAttached()` | 加入 UiManager 活动树时调用（子类可覆写注册全局资源，如 Dropdown 在此注册 popup） |
| `onDetached()` | 从活动树移除时调用（子类可覆写释放全局资源） |
| `_setAttached(attached)` | 内部方法：递归设置 attached 状态并触发生命周期钩子 |

## 更新生命周期

```lua
function Widget:update(dt, parent_should_update)
    self.transform:onUpdate()         -- 1. Transform 脏检测
    -- SizeChanged 事件检测
    self:_preChildrenUpdate(dt)       -- 2. ★ 钩子（Container 在此排序）
    for child in children do          -- 3. 子控件 update
        child:update(dt, true)
    end
    self:onUpdate(dt)                 -- 4. 自身 update
end
```

## 尺寸测量

| 方法 | 说明 |
|------|------|
| `measure(max_w, max_h)` | 查询自然（内容）尺寸 `{w, h}`。默认返回当前 transform 尺寸。子类覆写以提供基于内容的尺寸报告 |
| `getMinimumSize()` | 返回自身内容的最小自然尺寸 `w, h`。默认返回 `(0, 0)`。子类覆写以报告基于实际内容的最小尺寸（如 Text 返回文本尺寸、Button 返回文字+边距） |
| `getCombinedMinimumSize()` | `max(getMinimumSize(), custom_minimum)`，容器实际使用的值 |
| `setCustomMinimumSize(w, h)` | 设置自定义最小尺寸覆盖（nil 表示不限制） |
| `getDesiredSize()` | 期望的自然尺寸，默认等于最小尺寸。Text 覆写为完整文本宽度（换行时返回当前整形后尺寸） |

> **注意**：普通 Widget 设了 `h = 40` 但不覆写 `getMinimumSize` 也不设 `custom_minimum`，容器分配时可能给 0 高度。Button、Text、Image 等已内置覆写 `getMinimumSize`，不需要额外处理。对于自定义 Widget 放入容器，推荐调用 `setCustomMinimumSize(nil, 40)` 或覆写 `getMinimumSize`。

## 显示控制

| 方法 | 说明 |
|------|------|
| `show()` | 显示（使 `shown = true`，失效渲染缓存） |
| `hide()` | 隐藏（使 `shown = false`，失效渲染缓存） |
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

## 事件处理

事件传播机制：**子节点优先**（倒序遍历 children），子节点返回 `true` 则拦截事件不再继续。

| 方法 | 说明 |
|------|------|
| `handleEvent(event_type, ...)` | 事件分发入口，自动拼接 `"on" .. event_type` 查找 handler。先递归子节点（倒序），再调用自身 handler |
| `isOperational()` | 检查 widget 是否可操作（valid + enabled + shown） |
| `enableSizeChangedEvent(enable)` | 开启/关闭 SizeChanged 事件检测。开启后每帧对比 `transform.w/h` 变化，触发 `onSizeChanged` |

### 射线检测（raycast_target）

`handleEvent` 在子节点递归和自身 handler 之后，有一个 fallback：
`raycast_target == true` 且鼠标在 `regionDetection` 区域内 → 返回 `true` 阻断穿透。

有子节点的容器同样生效——子节点已在前一步优先检查过，不会冲突。

**注意**：`WheelMoved` 不在此 fallback 之列——滚轮应穿透到可滚动的父容器。

> **组合控件注意**：Button/TextInput/SliderBar 等内部子 Text/Panel 已在构造中设为 `raycast_target = false`，避免子节点抢走父控件的事件。自定义组合控件同样处理。

各控件默认值：

| 控件 | 默认值 | 说明 |
|------|--------|------|
| Panel / Text / Image / NineSlice / ProgressBar | `true` | 有视觉实体 |
| Button / ImageButton / Checkbox / RadioButton | `true` | 交互控件（继承 ButtonBase） |
| TextInput / SliderBar / Scroll | `true` | 交互控件 |
| Modal / TabView / Dropdown / Tooltip | `true` | 容器但有交互/视觉 |
| Widget（基类） / Container / BoxContainer / List / RadioGroup / Spacer | `false` | 纯布局容器，不阻挡 |

## 事件处理器约定

子类覆写以下方法以响应事件（命名规则：`on` + PascalCase 事件名）：

| 处理器 | 触发时机 |
|--------|----------|
| `onUpdate(dt)` | 每帧更新 |
| `onDraw()` | 自身绘制（在子节点绘制之前） |
| `onPostDraw()` | 子节点绘制完毕后 |
| `onKeyPressed(key, isrepeat)` | 键盘按下 |
| `onKeyReleased(key)` | 键盘释放 |
| `onTextInput(text)` | 文本输入 |
| `onMousePressed(x, y, button)` | 鼠标按下 |
| `onMouseReleased(x, y, button)` | 鼠标释放 |
| `onMouseMoved(x, y, dx, dy)` | 鼠标移动 |
| `onWheelMoved(x, y)` | 滚轮 |
| `onFocus()` | 获得焦点 |
| `onRemoveFocus()` | 失去焦点 |
| `onEnabled()` | 被启用 |
| `onDisabled()` | 被禁用 |
| `onSizeChanged(w, h)` | 尺寸变化（需先调用 `enableSizeChangedEvent(true)`） |
| `onHovered(hovered, x, y, dx, dy)` | 鼠标进入/离开（需先通过 `Components.addHoverState` 混入） |

## 调试

| 方法 | 说明 |
|------|------|
| `enableDebug(enable)` | 开启/关闭调试绘制（包围盒 + AABB + pivot 点），返回 self，支持链式调用 |

> **注意**：Text 的 `transform.w/h = 0`，debug 框对 Text 可能显示零面积框。这是正常的——Text 的尺寸存在 `love.graphics.Text` 对象里，不影响碰撞检测和裁剪。

## 可见性裁剪

| 方法 | 说明 |
|------|------|
| `getCullAABB()` | 供可见性裁剪使用的包围盒。子类可覆写以提供比 transform 更精确的尺寸 |

Text 覆写了此方法使用 `getGlobalScaledSize()`（文本实际尺寸），避免在 Scroll 中被过早裁剪。
裁剪使用 1px 容差，仅当元素与裁剪区**完全无交集**时才跳过整棵子树。

## SizeFlags — 在容器中的布局行为

每个 Widget 持有以下布局属性，由父容器读取：

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

标志通过加法组合：`Utils.SIZE_FLAGS.FILL + Utils.SIZE_FLAGS.EXPAND` = `3`。

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
| `raycast_target` | boolean | 射线检测开关。开启后，即使没有显式事件 handler，鼠标落在区域内也会阻断事件穿透 |
| `render_layer` | number | 渲染层级（0=BASE, 50=OVERLAY, 80=DROPDOWN, 100=TOOLTIP） |
| `always_draw` | boolean | 是否跳过可见性裁剪 |
| `_clip_rect` | table/nil | 裁剪矩形（内部属性，由 Scroll 等设置），传给子节点用于 AABB 裁剪 |
| `_name` | string | widget 名称（调试用） |
