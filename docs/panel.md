# Panel

纯色矩形面板，可设置背景色、边框和圆角。常用作其他控件的背景或装饰。

**继承链：** `Widget` → `Panel`

## 构造参数（datas）

```lua
{
    bg_color = {r, g, b, a},       -- 背景色
    outline_width = number,         -- 边框宽度（像素）
    outline_color = {r, g, b, a},   -- 边框颜色
    rounding_radius = number,       -- 圆角半径（像素）
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `SetBGColor(r, g, b)` | 设置背景色（0~255 或传 `{r, g, b, a}` 表） |
| `SetOutlineColor(r, g, b)` | 设置边框色（格式同上） |

## 示例

```lua
-- 基础面板
local panel = Panel({
    w = 200, h = 100,
    bg_color = {0.1, 0.12, 0.16, 1},
    outline_width = 1,
    outline_color = {0.3, 0.3, 0.4, 1},
    rounding_radius = 8,
})

-- 作为 TextInput 的背景
local bg = Panel({
    bg_color = {0.08, 0.08, 0.1, 1},
    rounding_radius = 4,
})
local input = TextInput({ w = 200, h = 32, bg = bg })
```
