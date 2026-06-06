# ProgressBar

进度条组件，支持水平和垂直方向。

**继承链：** `Widget` → `ProgressBar`

## 构造参数（datas）

```lua
{
    value = number,               -- 当前进度，0~1，默认 0
    fill_color = {r, g, b, a},    -- 填充色，默认来自 theme.progressbar.fill_color
    bg_color = {r, g, b, a},      -- 背景色，默认来自 theme.progressbar.bg_color
    rounding_radius = number,     -- 圆角半径，默认 4
    orientation = string,         -- 方向："horizontal"（默认）| "vertical"
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `setValue(v)` | 设置进度值（0~1，自动 clamp） |
| `setProgress(v)` | `setValue` 的别名 |
| `getValue()` | 获取当前进度值 |

## 示例

```lua
-- 水平进度条
local hp = ProgressBar({
    anchor = {0, 0, 1, 0},
    h = 12,
    value = 0.6,
    rounding_radius = 6,
})

-- 更新进度
hp:setValue(0.75)

-- 垂直进度条
local vp = ProgressBar({
    orientation = "vertical",
    anchor = {0, 0, 0, 1},
    w = 12,
    value = 0.3,
})
```
