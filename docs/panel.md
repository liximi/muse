# Panel

纯色面板组件，可设置背景颜色、描边和圆角。

**继承链：** `Widget` → `Panel`

## 构造参数（datas）

```lua
{
    bg_color = {r, g, b, a},      -- 背景色，默认来自 theme.panel.bg_color
    outline_width = number,        -- 描边宽度（像素），默认 1
    outline_color = {r, g, b, a},  -- 描边色，默认来自 theme.panel.outline_color
    rounding_radius = number,      -- 圆角半径（像素），默认 4
}
```

以上字段均可被 `Widget` 基类的 datas 字段覆盖（如 `anchor`、`padding` 等）。

## 公有方法

| 方法 | 说明 |
|------|------|
| `SetBGColor(r, g, b)` 或 `SetBGColor({r, g, b, a})` | 设置背景色，接受 0~255 整数或 {0~1} 表 |
| `SetOutlineColor(r, g, b)` 或 `SetOutlineColor({r, g, b, a})` | 设置描边色 |

## 示例

```lua
local panel = Panel({
    anchor = {0, 0, 1, 1},
    padding = {10, 10, 10, 10},
    bg_color = Utils.RGB(40, 40, 50),
    rounding_radius = 8,
    outline_width = 2,
    outline_color = Utils.RGB(100, 100, 120),
})
```
