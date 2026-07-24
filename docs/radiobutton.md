# RadioButton

单选按钮。继承 Checkbox，渲染为圆形轮廓 + 实心圆点。详见 [Checkbox](checkbox.md)。

**继承链：** `Widget` → `ButtonBase` → `Checkbox` → `RadioButton`

## 额外构造参数

```lua
{
    circle_size = number,         -- 圆形尺寸
    circle_color = {r, g, b, a},  -- 圆形背景色
    dot_color = {r, g, b, a},     -- 选中圆点颜色
    outline_width = number,       -- 边框宽度
    outline_color = {r, g, b, a}, -- 边框颜色
}
```

RadioButton 固定使用 `style = "radio"`（圆形 + 圆点），不支持切换为 checkbox 或 toggle 样式。其他行为与 Checkbox 一致，包括 `label`、`on_checked` 回调等。

## 示例

```lua
local radio = RadioButton({
    label = "Option A",
    checked = true,
    on_checked = function(checked) print("Selected:", checked) end,
})
```

## 最佳实践

- **推荐**：将一组 RadioButton 放入 RadioGroup 实现互斥。
- **不推荐**：手动管理多个 RadioButton 的互斥逻辑——使用 RadioGroup。
