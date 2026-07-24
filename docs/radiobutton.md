# RadioButton

单选按钮，继承 Checkbox，渲染圆形轮廓+实心圆点。`style` 固定为 `"radio"`。

**继承链：** `Widget` → `ButtonBase` → `Checkbox` → `RadioButton`

## 构造参数（datas）

```lua
{
    -- 继承 Checkbox 的所有参数
    checked = boolean,            -- 初始选中状态
    label = string | table,       -- 标签文本
    on_checked = function(checked), -- 选中状态改变时的回调
    on_click = function(),        -- 点击回调

    -- 额外参数（覆盖 Checkbox 的 box_* 系列）
    circle_size = number,         -- 圆形尺寸，默认来自 theme（20）
    circle_color = {r, g, b, a},  -- 圆形填充色
    dot_color = {r, g, b, a},     -- 选中圆点颜色
    outline_width = number,       -- 描边宽度
    outline_color = {r, g, b, a}, -- 描边颜色
}
```

## 公有方法

继承 Checkbox 的全部方法：`isChecked()`, `setChecked(checked)`, `toggle()`。

## 渲染

- 圆形背景：`box_color`（或主题中的 `circle_color`）
- 圆形描边：`outline_color` + `outline_width`
- 选中时：半径 `× 0.55` 的实心圆点（`check_color` / `dot_color`）

## 示例

```lua
local rb = RadioButton({
    label = "Option A",
    checked = true,
    on_checked = function(checked)
        if checked then
            print("Option A selected")
        end
    end,
})
```

> RadioButton 通常不单独使用，而是通过 RadioGroup 管理互斥行为。
