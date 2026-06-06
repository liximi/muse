# ImageButton

图片按钮组件，在 ButtonBase 基础上附加贴图切换，可选附带文本。

**继承链：** `Widget` → `ButtonBase` → `ImageButton`

## 构造参数（datas）

```lua
{
    no_text = boolean,            -- 是否不显示文本（纯图片按钮）
    font_key = string,            -- 字体 key
    normal = style_table,         -- 默认状态样式（Utils.newImageButtonStateStyle）
    hover = style_table,
    pressed = style_table,
    disabled = style_table,
    selected = style_table,
    selected_hover = style_table,

    on_click = function(),        -- 点击回调（继承自 ButtonBase）
    on_pressed = function(x, y),  -- 按下回调（继承自 ButtonBase）
}
```

如果不设 `datas.w` / `datas.h`，会自动从 `normal.texture` 的尺寸获取。

### 状态样式字段（`Utils.newImageButtonStateStyle` 返回）

```lua
{
    texture = love.Texture,       -- 贴图
    tint = {r, g, b, a},         -- 着色
    text = string | table,        -- 文本（coloredtext）
    text_color = {r, g, b, a},    -- 文本颜色
    font_size = number,           -- 字号
    offset = {x, y},              -- 位置偏移
    scale = {sx, sy},             -- 缩放
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `setStateStyle(state, style)` | 设置某个状态的样式 |
| `getStateStyle(state)` | 获取合并后样式 |

状态转换逻辑与 Button 相同（继承自 ButtonBase）。

## 示例

```lua
local icon = love.graphics.newImage("assets/icon.png")

local ibtn = ImageButton({
    normal = Utils.newImageButtonStateStyle(icon, {1, 1, 1, 1}, "Save"),
    hover = Utils.newImageButtonStateStyle(nil, nil, nil, nil, nil, {0, -1}),
    pressed = Utils.newImageButtonStateStyle(nil, nil, nil, nil, nil, {0, 2}),
    disabled = Utils.newImageButtonStateStyle(nil, {0.4, 0.4, 0.4, 1}),
    on_click = function()
        print("image button clicked!")
    end,
})
```
