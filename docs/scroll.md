# Scroll（ScrollContainer）

滚动容器，提供带裁剪区域的滚动视图，支持水平/垂直滚动、滚动条和补间动画。

**继承链：** `Widget` → `Scroll`

## 构造参数（datas）

```lua
{
    item = Widget,                    -- 要滚动的子 widget（必填）
    enable_scroll_h = boolean,        -- 启用水平滚动，默认 false
    enable_scroll_v = boolean,        -- 启用垂直滚动，默认 true

    sensitivity = number,             -- 鼠标滚轮灵敏度（像素），默认 100
    scrollable_w = number,            -- 水平可滚动宽度（像素）
    scrollable_h = number,            -- 垂直可滚动高度（像素）
    auto_track = boolean,             -- 自动追踪内容尺寸变化并更新可滚动范围，默认 true

    show_slider_bar = boolean,        -- 是否显示滚动条，默认 true
    hide_slider_when_cannot_scroll = boolean,  -- 不可滚动时隐藏滚动条，默认 false
    h_slider_bar_height = number,     -- 水平滚动条高度，默认 8
    v_slider_bar_width = number,      -- 垂直滚动条宽度，默认 8
    scrollbar_gap = number,           -- 滚动条与内容间距，默认 2
    v_bar_pad_top = number,           -- 垂直滚动条顶部边距，默认 0
    v_bar_pad_bottom = number,        -- 垂直滚动条底部边距，默认 0
    h_bar_pad_left = number,          -- 水平滚动条左侧边距，默认 0
    h_bar_pad_right = number,         -- 水平滚动条右侧边距，默认 0
    v_bar_min_h = number,             -- 垂直滚动条最小高度，默认 0 不限制
    h_bar_min_w = number,             -- 水平滚动条最小宽度，默认 0 不限制
    block_min_len = number,           -- 滑块最小长度，默认 0 不限制
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `setItem(item)` | 设置要滚动的内容 widget |
| `setXOffset(offset, tween)` | 设置水平滚动偏移（tween=true 启用补间动画） |
| `setYOffset(offset, tween)` | 设置垂直滚动偏移 |
| `setScrollableW(w)` | 设置水平可滚动宽度（自动更新滑块比例） |
| `setScrollableH(h)` | 设置垂直可滚动高度 |
| `updateHBlockLengthPercent()` | 更新水平滑块长度比例 |
| `updateVBlockLengthPercent()` | 更新垂直滑块长度比例 |
| `getMinimumSize()` | 返回自身 transform 尺寸 |

## auto_track（自动追踪内容尺寸）

默认开启。`onUpdate` 每帧检测 `item` 的 `transform.w/h` 变化，自动更新 `scrollable_w/h` + 滑块比例。
内容缩小后自动修正越界的 offset。设为 `false` 退回到手动 `setScrollableW/H`。

## 滚动条最小尺寸约束

当 `v_bar_min_h > 0` 或 `h_bar_min_w > 0` 时，若轨道空间不足，系统会按比例缩减滚动条两端边距以确保最小尺寸。

## 交互

- 鼠标滚轮在 Scroll 区域内上下滚动
- 鼠标滚轮灵敏度：100px（可通过 `sensitivity` 自定义）
- 拖拽滚动条滑块可快速定位

## 边界行为

- **内容必须通过 `setItem()` 设置**：直接 `addChild` 到 Scroll 本体不会进入内部的 `scroll_root`，
  滚动和裁剪都失效。正确用法是 `scroll:setItem(content)`，content 会成为 `scroll_root` 的子节点
- **部分可见元素不会被整棵子树裁剪**：`_clip_rect` 向四周各扩展 1px 容差，
  AABB 裁剪仅在元素与裁剪区**完全无交集**时才跳过，浮点精度导致的边缘误裁不再发生
- 滚动条滑块有 `block_min_len` 约束，空间不足时按比例缩减两端边距（见 `_enforceBarMinSize`）

## 示例

```lua
local content = Widget({h = 800})  -- 超出容器高度的内容
local scroll = Scroll({
    item = content,
    anchor = {0, 0, 1, 1},
    padding = {0, 8, 0, 0},  -- 为滚动条预留右侧空间
    hide_slider_when_cannot_scroll = true,
})
scroll:setScrollableH(800)
```
