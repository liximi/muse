# Widget（基类）

所有 UI 元素的基类。提供了树形结构、Transform 布局、事件处理、生命周期管理等核心机制。

**继承链：** `Object` → `Widget`

## 构造参数（datas）

```lua
{
    pivot = {x, y},           -- 支点，0~1 百分比
    anchor = {minx, miny, maxx, maxy},  -- 锚点
    x = number,               -- 位置 X（像素）
    y = number,               -- 位置 Y（像素）
    w = number,               -- 宽度（像素）
    h = number,               -- 高度（像素）
    sx = number,              -- 水平缩放
    sy = number,              -- 垂直缩放
    padding = {left, right, top, bottom},  -- 内边距（像素）
    r = number,               -- 旋转角（弧度）
}
```

构造时也接受可选的 `theme` 参数：`Widget(datas, theme)` 或 `Widget(name, datas, theme)`。

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
| `addChild(child)` | 添加子 widget（自动检测循环引用，自动从旧父节点移除） |
| `removeChild(child)` | 移除子 widget |
| `removeAllChildren()` | 移除所有子 widget |

## 生命周期

| 方法 | 说明 |
|------|------|
| `destroy()` | 递归销毁自身及所有子孙，从父节点移除 |
| `isValid()` | 检查 widget 是否有效（未被销毁） |

## 尺寸测量

| 方法 | 说明 |
|------|------|
| `measure(max_w, max_h)` | 查询自然（内容）尺寸，返回值 `{w, h}`。默认返回当前 transform 尺寸 |

## 显示控制

| 方法 | 说明 |
|------|------|
| `show()` | 显示 |
| `hide()` | 隐藏 |
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
| `handleEvent(event_type, ...)` | 事件分发入口，自动拼接 `"on" .. event_type` 查找 handler |
| `isOperational()` | 检查 widget 是否可操作（valid + enabled + shown） |

## 事件处理器约定

子类覆写以下方法以响应事件（命名规则：`on` + PascalCase 事件名）：

| 处理器 | 触发时机 |
|--------|----------|
| `onUpdate(dt)` | 每帧更新 |
| `onDraw()` | 自身绘制 |
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

> **注意**：Text 的 `transform.w/h = 0`，debug 框对 Text 可能显示零面积框。
> 这是正常的——Text 的尺寸存在 `love.graphics.Text` 对象里，不影响碰撞检测和裁剪。

## 可见性裁剪

| 方法 | 说明 |
|------|------|
| `getCullAABB()` | 供可见性裁剪使用的包围盒。子类可覆写以提供比 transform 更精确的尺寸 |

Text 覆写了此方法使用 `getGlobalScaledSize()`（文本实际尺寸），避免在 Scroll 中被过早裁剪。
裁剪使用 1px 容差，仅当元素与裁剪区**完全无交集**时才跳过整棵子树。

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
| `render_layer` | number | 渲染层级（0=BASE, 50=OVERLAY, 80=DROPDOWN, 100=TOOLTIP） |
| `always_draw` | boolean | 是否跳过可见性裁剪 |
| `_name` | string | widget 名称（调试用） |
