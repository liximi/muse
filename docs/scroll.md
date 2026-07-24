# Scroll（ScrollContainer）

滚动容器，提供带 scissor 裁剪的滚动视图。支持水平/垂直滚动、滚动条、补间动画和内容尺寸自动追踪。

**继承链：** `Widget` → `Scroll`

> Scroll 不是 Container 的子类——它通过内部的 `scroll_root` Widget 来管理内容。内容通过 `setItem()` 设置，`scroll_root` 使用锚点 `{0,0,1,1}` + padding 预留滚动条空间。

## 构造参数（datas）

```lua
{
    item = Widget,                    -- 要滚动的内容 widget
    horizontal_scroll_mode = "disabled" | "auto" | "show_always" | "show_never" | "reserve",  -- 水平滚动模式，默认 "disabled"
    vertical_scroll_mode   = "disabled" | "auto" | "show_always" | "show_never" | "reserve",  -- 垂直滚动模式，默认 "auto"

    sensitivity = number,             -- 鼠标滚轮灵敏度（像素），默认 100
    scrollable_w = number,            -- 水平可滚动宽度（像素），默认等于 transform.w
    scrollable_h = number,            -- 垂直可滚动高度（像素），默认等于 transform.h
    auto_track = boolean,             -- 自动追踪内容尺寸变化，默认 true

    show_slider_bar = boolean,        -- 是否显示滚动条，默认 true
    h_slider_bar_height = number,     -- 水平滚动条高度，默认 8
    v_slider_bar_width = number,      -- 垂直滚动条宽度，默认 8
    scrollbar_gap = number,           -- 滚动条与内容间距，默认 2

    -- 滚动条边距与最小尺寸
    v_bar_pad_top = number,           -- 垂直滚动条顶部边距，默认 0
    v_bar_pad_bottom = number,        -- 垂直滚动条底部边距，默认 0
    h_bar_pad_left = number,          -- 水平滚动条左侧边距，默认 0
    h_bar_pad_right = number,         -- 水平滚动条右侧边距，默认 0
    v_bar_min_h = number,             -- 垂直滚动条最小高度（空间不足时缩减边距），默认 0
    h_bar_min_w = number,             -- 水平滚动条最小宽度，默认 0
    block_min_len = number,           -- 滑块最小长度，默认 0
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `setItem(item)` | 设置要滚动的内容 widget（先清空 scroll_root，再添加） |
| `setXOffset(offset, tween)` | 设置水平滚动偏移（tween=true 启用补间动画） |
| `setYOffset(offset, tween)` | 设置垂直滚动偏移 |
| `setScrollableW(w)` | 设置水平可滚动宽度（自动更新滑块比例） |
| `setScrollableH(h)` | 设置垂直可滚动高度 |
| `updateHBlockLengthPercent()` | 更新水平滑块长度比例 |
| `updateVBlockLengthPercent()` | 更新垂直滑块长度比例 |
| `getMinimumSize()` | 返回自身 transform 尺寸 |

## auto_track（自动追踪内容尺寸）

默认开启。`onUpdate` 每帧检测 `item` 的 `transform.w/h` 变化，自动更新 `scrollable_w/h` + 滑块比例。内容缩小后自动修正越界的 offset。设为 `false` 退回到手动 `setScrollableW/H` 管理。

## 滚动条最小尺寸约束

当 `v_bar_min_h > 0` 或 `h_bar_min_w > 0` 时，若轨道空间不足，系统会按比例缩减滚动条两端边距以确保最小尺寸。

## scissor 裁剪

- scissor 在 `scroll_root` 的 `onDraw`/`onPostDraw` 闭包中管理（而非 Scroll 自身）。
- 嵌套 Scroll 时手动求交集（love.graphics.setScissor 是替换而非求交）。
- CPU 端裁剪同步：`_clip_rect` 向四周扩展 1px 容差，仅当元素与裁剪区完全无交集时才跳过。

## 交互

- 鼠标滚轮在 Scroll 区域内滚动（垂直滚动默认每次 100px）
- 拖拽滚动条滑块可快速定位
- `onWheelMoved` 返回 `true` 拦截冒泡——嵌套 Scroll 各自独立滚动
- 鼠标事件仅在 Scroll 可见区域内时传播给内容

## 示例

```lua
-- 基本用法
local content = Widget({h = 800})
local scroll = Scroll({
    item = content,
    anchor = {0, 0, 1, 1},
    padding = {0, 8, 0, 0},
    hide_slider_when_cannot_scroll = true,
})
scroll:setScrollableH(800)

-- auto_track + VBox 自动布局
local VBoxContainer = require "ui.widgets.containers.box_v_container"
local list = VBoxContainer({ auto_size = true, separation = 4 })

for i = 1, 50 do
    list:addChild(Button({ text = "Item " .. i, h = 32 }))
end

local scroll = Scroll({
    item = list,
    anchor = {0, 0, 1, 1},
    hide_slider_when_cannot_scroll = true,
})
-- 无需手动 setScrollableH，auto_track 自动追踪 VBox 高度
```

## 最佳实践

- **内容必须通过 `setItem()` 设置**：直接 `addChild` 到 Scroll 本体不会进入内部的 `scroll_root`，滚动和裁剪都会失效。
- **Scroll 内 VBox 需要 `anchor = {0,0,1,0}`**：水平方向填满 scroll_root，高度由内容撑开。
- **嵌套 Scroll 的滚轮隔离**：外层和内层各自独立处理滚轮，`onWheelMoved` 返回 `true` 阻止冒泡。
