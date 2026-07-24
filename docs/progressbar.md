# ProgressBar

进度条控件。支持水平和垂直方向，可切换为交互模式让用户拖拽滑块调节。

**继承链：** `Widget` → `ProgressBar`

## 构造参数（datas）

```lua
{
    value = number,               -- 当前进度 0~1，默认 0
    orientation = "horizontal" | "vertical",  -- 方向，默认 "horizontal"
    fill_color = {r, g, b, a},    -- 填充颜色
    bg_color = {r, g, b, a},      -- 背景颜色
    rounding_radius = number,     -- 圆角半径

    -- 交互模式
    interactive = boolean,        -- 允许用户拖拽调节，默认 false
    thumb_radius = number,        -- 滑块半径（像素），默认自动计算
    thumb_color = {r, g, b, a},   -- 滑块颜色，默认 fill_color
    thumb_outline_color = {r, g, b, a},  -- 滑块描边颜色
    thumb_outline_width = number, -- 滑块描边宽度，默认 2
    on_value_changed = function(value),  -- 值变化回调
}
```

## 工作原理

- **静态模式**（`interactive = false`）：仅显示进度，不响应鼠标。
- **交互模式**（`interactive = true`）：点击或拖拽改变进度值，滑块随鼠标位置更新。

水平条从左侧填充，垂直条从底部填充。交互模式下的滑块半径自动计算为薄边的一半 × 1.2，最小 5px。

## 公有方法

| 方法 | 说明 |
|------|------|
| `setValue(v)` | 设置进度值（0~1） |
| `setProgress(v)` | `setValue` 的别名 |
| `getValue()` | 获取当前值 |

## 示例

```lua
-- 静态进度条
local bar = ProgressBar({
    w = 200, h = 8,
    value = 0.6,
    fill_color = {0.3, 0.6, 1, 1},
    bg_color = {0.1, 0.1, 0.15, 1},
})

-- 可交互的音量滑块
local volume = ProgressBar({
    w = 200, h = 12,
    value = 0.8,
    interactive = true,
    on_value_changed = function(v) print("Volume:", v) end,
})
```
