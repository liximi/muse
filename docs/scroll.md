# Scroll

滚动容器。内部内容可在水平和垂直方向滚动，带可选滑块和缓动动画。

**继承链：** `Widget` → `Scroll`

## 构造参数（datas）

```lua
{
    item = Widget,            -- 初始内容
    horizontal_scroll_mode = "disabled" | "auto" | "show_always" | "show_never" | "reserve",  -- 默认 "disabled"
    vertical_scroll_mode   = "disabled" | "auto" | "show_always" | "show_never" | "reserve",  -- 默认 "auto"
    sensitivity = number,     -- 滚轮灵敏度（像素），默认 100
    scrollable_w = number,    -- 水平可滚动范围（像素）
    scrollable_h = number,    -- 垂直可滚动范围（像素）
    show_slider_bar = boolean, -- 是否显示滑块，默认 true
    auto_track = boolean,     -- 自动追踪内容尺寸变化，默认 true
    h_slider_bar_height = number,  -- 水平滚动条高度，默认 8
    v_slider_bar_width = number,   -- 垂直滚动条宽度，默认 8
    scrollbar_gap = number,   -- 滚动条与内容间距，默认 2
    v_bar_pad_top = number,   -- 垂直滚动条顶部边距
    v_bar_pad_bottom = number,
    h_bar_pad_left = number,
    h_bar_pad_right = number,
    block_min_len = number,   -- 滑块最小长度
}
```

## 工作原理

### 内部结构

Scroll 内部维护 `scroll_root`（内容容器）和两个 `SliderBar`（水平/垂直滑块）。`scroll_root` 通过调整自身 position 实现内容偏移。

### 裁剪机制

scissor 裁剪在 `scroll_root` 的 `onDraw`/`onPostDraw` 闭包中管理（不在 Scroll 自身）。原因：`Widget:draw` 顺序为 onDraw → children → onPostDraw，在 scroll_root 的 children 循环内设 scissor 可精确覆盖内容绘制阶段。

嵌套 Scroll 通过手动取交集正确处理——`love.graphics.setScissor()` 是替换而非求交，代码显式计算交集后设置。

### 自动追踪（auto_track）

`auto_track = true`（默认）时，每帧 `onUpdate` 检测 `item.transform.w/h` 变化，自动更新 `scrollable_w`/`scrollable_h`。

### 滚动模式

- `"disabled"`：该轴不可滚动，控件填满区域。
- `"auto"`：内容溢出时显示滚动条。
- `"show_always"`：始终显示滚动条。
- `"show_never"`：始终隐藏（仍可通过代码滚动）。
- `"reserve"`：预留滚动条空间。

### Wheel 事件

`onWheelMoved` 返回 `true` 拦截冒泡，防止嵌套 Scroll 互相干扰。使用 `love.mouse.getPosition()` 检测区域（非事件参数），确保滚轮穿透 raycast_target fallback 后仍能被外层 Scroll 捕获。

### 缓动动画

`setXOffset`/`setYOffset` 第二个参数传 `true` 启用缓动动画，使用 `tween.lua` 线性插值。

## 公有方法

| 方法 | 说明 |
|------|------|
| `setItem(item)` | 设置内容 widget |
| `setXOffset(offset, tween)` | 设置水平滚动偏移 |
| `setYOffset(offset, tween)` | 设置垂直滚动偏移 |
| `setScrollableW(w)` | 设置水平可滚动范围 |
| `setScrollableH(h)` | 设置垂直可滚动范围 |
| `getMinimumSize()` | 返回自身 transform 尺寸 |

## 示例

```lua
-- 垂直滚动列表
local scroll = Scroll({
    anchor = {0, 0, 1, 1},
    vertical_scroll_mode = "auto",
})
local vbox = VBoxContainer({ anchor = {0, 0, 1, 0}, auto_size = true, separation = 4 })
vbox:addChild(Button({ text = "Item 1" }))
vbox:addChild(Button({ text = "Item 2" }))
scroll:setItem(vbox)
```

## 最佳实践

- **推荐**：Scroll 内使用 VBox 时设置 `anchor = {0, 0, 1, 0}` 让它水平填满。
- **推荐**：VBox 开启 `auto_size = true` 配合 Scroll 的 `auto_track = true`。
- **推荐**：`onWheelMoved` 返回 `true` 防止嵌套 Scroll 冲突。
- **不推荐**：在 `scroll_root` 外部直接操作 scissor——裁剪逻辑由闭包管理。
