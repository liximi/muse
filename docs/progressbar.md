# ProgressBar

进度条组件，支持水平和垂直方向。可开启交互模式让用户拖拽调节进度。

**继承链：** `Widget` → `ProgressBar`

## 构造参数（datas）

```lua
{
    value = number,               -- 当前进度，0~1，默认 0
    orientation = string,         -- 方向："horizontal"（默认）| "vertical"
    fill_color = {r, g, b, a},    -- 填充色，默认来自 theme.progressbar.fill_color
    bg_color = {r, g, b, a},      -- 背景色，默认来自 theme.progressbar.bg_color
    rounding_radius = number,     -- 圆角半径，默认来自 theme（4）

    -- 交互模式
    interactive = boolean,           -- 是否允许用户手动调节，默认 false
    thumb_radius = number,           -- 滑块圆点半径（像素），默认自动计算（薄边一半的 1.2 倍，最小 5px）
    thumb_color = {r, g, b, a},      -- 滑块颜色，默认等于 fill_color
    thumb_outline_color = {r, g, b, a},  -- 滑块描边色，默认 nil（不描边）
    thumb_outline_width = number,    -- 滑块描边宽度，默认 2
    on_value_changed = function(value),  -- 值变化回调（仅在交互模式下生效）
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `setValue(v)` | 设置进度值（0~1，自动 clamp），交互模式下触发 `on_value_changed` |
| `setProgress(v)` | `setValue` 的别名 |
| `getValue()` | 获取当前进度值 |
| `getMinimumSize()` | 水平条返回 `(0, max(h, 8))`，垂直条返回 `(max(w, 10), max(h, 30))` |

## 交互模式

当 `interactive = true` 时：

- **点击/拖拽** — 在 progress bar 区域内按下鼠标即更新进度值，拖拽时实时跟随
- **鼠标悬停滑块** — 光标变为手型（hand）
- **滑块外观** — 在填充条末端显示一个圆形拖拽把手，半径和颜色可自定义
- **回调通知** — 值变化时触发 `on_value_changed(value)`
- **hover 检测** — 自动混入 `Components.addHoverState`，支持 `onHovered` 回调

## 示例

```lua
-- 静态进度条
local static = ProgressBar({
    value = 0.6,
    anchor = {0, 0, 1, 0},
    h = 12,
})

-- 可交互进度条（音乐播放进度）
local vol = ProgressBar({
    value = 0.8,
    interactive = true,
    anchor = {0, 0, 1, 0},
    h = 14,
    fill_color = Utils.RGB(80, 180, 100),
    thumb_color = Utils.RGB(140, 220, 160),
    thumb_outline_color = Utils.RGB(40, 80, 40),
    on_value_changed = function(val)
        setVolume(val)
    end,
})

-- 垂直交互进度条
local v = ProgressBar({
    orientation = "vertical",
    value = 0.5,
    interactive = true,
    anchor = {0, 0, 0, 1},
    w = 20,
    on_value_changed = function(val)
        print("value:", val)
    end,
})

-- 编程更新
static:setValue(0.75)
```
