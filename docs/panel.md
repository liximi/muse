# Panel

纯色面板，可设置背景色、描边和圆角。

**继承链：** `Widget` → `Panel`

## 构造参数（datas）

```lua
{
    bg_color = {r, g, b, a},      -- 背景色，默认来自 theme.panel.bg_color
    outline_width = number,       -- 描边宽度（像素），默认来自 theme（1）
    outline_color = {r, g, b, a}, -- 描边颜色，默认来自 theme.panel.outline_color
    rounding_radius = number,     -- 圆角半径（像素），默认来自 theme（4）
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `SetBGColor(r, g, b)` | 设置背景色。支持 `SetBGColor(255, 128, 64)` 或 `SetBGColor({1, 0.5, 0.25})` |
| `SetOutlineColor(r, g, b)` | 设置描边色，同上支持两种格式 |

## 示例

```lua
-- 圆角面板
local panel = Panel({
    anchor = {0, 0, 1, 1},
    bg_color = Utils.RGB(40, 40, 50),
    outline_width = 2,
    outline_color = Utils.RGB(80, 80, 100),
    rounding_radius = 8,
})

-- 动态修改颜色
panel:SetBGColor(60, 30, 30)
panel:SetOutlineColor(120, 60, 60)
```
