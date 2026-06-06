# RadioButton

单选按钮，继承 Checkbox，渲染为圆形轮廓+实心圆点。

**继承链：** `Widget` → `ButtonBase` → `Checkbox` → `RadioButton`

## 构造参数（datas）

除 Checkbox 的所有参数外，额外支持：

```lua
{
    circle_size = number,         -- 圆形尺寸（像素），默认来自主题
    circle_color = {r, g, b, a},  -- 圆形颜色
    dot_color = {r, g, b, a},     -- 选中圆点颜色
    outline_width = number,       -- 描边宽度
    outline_color = {r, g, b, a}, -- 描边色

    -- 也继承以下 Checkbox 参数：
    checked = boolean,
    label = string | table,
    label_color = {r, g, b, a},
    on_checked = function(checked),
    on_click = function(),
}
```

## 公有方法

与 Checkbox 相同：

| 方法 | 说明 |
|------|------|
| `isChecked()` | 返回当前是否选中 |
| `setChecked(checked)` | 编程式设置选中状态 |
| `toggle()` | 切换选中状态 |

## 说明

- `style` 固定为 `"radio"`，不可切换
- 选中时渲染一个半径为外圆 55% 的实心圆点
- 通常配合 RadioGroup 使用以实现互斥行为

## 示例

```lua
local rb = RadioButton({
    label = "Option A",
    checked = true,
    on_checked = function(checked)
        print("selected:", checked)
    end,
})
```
