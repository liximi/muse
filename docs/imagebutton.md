# ImageButton

图片按钮，在 ButtonBase 基础上增加纹理/tint 切换和可选附属文本。

**继承链：** `Widget` → `ButtonBase` → `ImageButton`

## 构造参数（datas）

```lua
{
    no_text = boolean,            -- 是否不显示文本（纯图片按钮），默认 false
    font_key = string,            -- 字体 key
    on_click = function(),        -- 点击回调
    on_pressed = function(x, y),  -- 按下回调

    -- 状态样式（每项为 Utils.newImageButtonStateStyle 的返回值）
    normal = style,
    hover = style,
    pressed = style,
    disabled = style,
    selected = style,
    selected_hover = style,
}
```

若 `normal` 样式中包含 `texture`，构造时会用该纹理的尺寸作为按钮默认尺寸（如果未显式指定 `w`/`h`）。

## 公有方法

| 方法 | 说明 |
|------|------|
| `setText(t)` | 设置按钮文字（`no_text` 模式下静默忽略） |
| `setStateStyle(state, style)` | 设置某个状态的样式。状态切换时自动更新纹理和 tint |
| `getStateStyle(state)` | 获取合并后的状态样式 |

## 状态样式字段

```lua
{
    texture = love.Texture,     -- 贴图
    tint = {r, g, b, a},        -- 着色
    text = string,              -- 文字（通过 setStateStyle 传递时自动调 setText）
    text_color = {r, g, b, a},  -- 文字颜色
    font_size = number,         -- 字号
    offset = {x, y},            -- 偏移
    scale = {sx, sy},           -- 缩放
}
```

## 示例

```lua
local icon = love.graphics.newImage("icon.png")
local icon_hover = love.graphics.newImage("icon_hover.png")

local ibtn = ImageButton({
    anchor = {0, 0, 0, 0},
    normal = Utils.newImageButtonStateStyle(icon, {1,1,1,1}, "Save", Utils.UI_COLORS.TITLE, 14),
    hover = Utils.newImageButtonStateStyle(icon_hover, nil, nil, nil, nil, {0, -1}),
    disabled = Utils.newImageButtonStateStyle(nil, {0.4,0.4,0.4,1}, nil, Utils.UI_COLORS.SECONDARY_TEXT),
    on_click = function()
        print("icon clicked")
    end,
})

-- 纯图片按钮
local icon_only = ImageButton({
    no_text = true,
    normal = Utils.newImageButtonStateStyle(icon, {1,1,1,1}),
})
```
