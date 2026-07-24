# Checkbox / RadioButton

复选框（方框+对勾样式）和单选按钮（圆形+圆点样式）。

**继承链：** `Widget` → `ButtonBase` → `Checkbox` → `RadioButton`

## 构造参数（datas）

```lua
{
    checked = boolean,            -- 初始选中状态，默认 false
    style = "checkbox" | "toggle", -- 样式：方框对勾或滑动开关，默认 "checkbox"
    box_size = number,            -- 复选框尺寸（像素）
    box_color = {r, g, b, a},     -- 背景色
    check_color = {r, g, b, a},   -- 对勾/圆点颜色
    outline_width = number,       -- 边框宽度
    outline_color = {r, g, b, a}, -- 边框颜色
    rounding_radius = number,     -- 圆角半径
    on_checked = function(checked), -- 状态变化回调
    label = string | table,       -- 标签文本（coloredtext 支持）
    label_color = {r, g, b, a},   -- 标签颜色
    label_font_size = number,     -- 标签字号
}
```

RadioButton 额外支持：

```lua
{
    circle_size = number,   -- 圆形尺寸
    circle_color = {r, g, b, a},  -- 圆形背景色
    dot_color = {r, g, b, a},     -- 选中圆点色
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `isChecked()` | 获取选中状态 |
| `setChecked(boolean)` | 设置选中状态 |
| `toggle()` | 切换选中状态 |

## 示例

```lua
-- 复选框
local cb = Checkbox({
    label = "Enable feature",
    checked = true,
    on_checked = function(checked) print("Feature:", checked) end,
})

-- 滑动开关
local toggle = Checkbox({
    style = "toggle",
    checked = false,
})

-- 单选按钮
local radio = RadioButton({
    label = "Option A",
})
```
