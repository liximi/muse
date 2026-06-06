# Checkbox

复选框组件，支持方框+对勾和滑动开关两种样式。

**继承链：** `Widget` → `ButtonBase` → `Checkbox`

## 构造参数（datas）

```lua
{
    checked = boolean,            -- 初始选中状态，默认 false
    style = "checkbox" | "toggle", -- 样式，默认 "checkbox"
    box_size = number,            -- 复选框尺寸（像素），默认 20
    box_color = {r, g, b, a},     -- 方框颜色
    check_color = {r, g, b, a},   -- 对勾/轨道颜色
    outline_width = number,       -- 描边宽度，默认 1
    outline_color = {r, g, b, a}, -- 描边色
    rounding_radius = number,     -- 圆角，默认 3

    on_checked = function(checked),  -- 选中状态改变回调
    on_click = function(),           -- 点击回调（继承自 ButtonBase）
    on_pressed = function(x, y),     -- 按下回调

    label = string | table,       -- 可选标签文本（coloredtext）
    label_color = {r, g, b, a},   -- 标签颜色
    label_font_size = number,     -- 标签字号
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `isChecked()` | 返回当前是否选中 |
| `setChecked(checked)` | 编程式设置选中状态 |
| `toggle()` | 切换选中状态 |

## 样式说明

- **checkbox** — 方框 + 选中时显示对勾
- **toggle** — 滑动开关，轨道宽度为 `box_size * 1.8`

## 示例

```lua
-- 方框复选框
local cb = Checkbox({
    label = "Enable feature",
    checked = true,
    on_checked = function(checked)
        print("checked:", checked)
    end,
})

-- 滑动开关
local toggle = Checkbox({
    style = "toggle",
    checked = false,
    on_checked = function(checked)
        print("toggled:", checked)
    end,
})
```
