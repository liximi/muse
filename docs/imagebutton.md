# ImageButton

基于贴图的按钮。与 Button 同样有六种状态，每种状态可配置不同的贴图、tint、文字样式。

**继承链：** `Widget` → `ButtonBase` → `ImageButton`

## 构造参数（datas）

```lua
{
    no_text = boolean,        -- 无文字模式（不创建 Text 子控件）
    font_key = string,        -- 字体键

    -- 状态样式（见 Utils.newImageButtonStateStyle）
    normal = Utils.newImageButtonStateStyle,
    hover = Utils.newImageButtonStateStyle,
    pressed = Utils.newImageButtonStateStyle,
    disabled = Utils.newImageButtonStateStyle,
    selected = Utils.newImageButtonStateStyle,
    selected_hover = Utils.newImageButtonStateStyle,
}
```

`Utils.newImageButtonStateStyle(texture, tint, text, text_color, font_size, offset, scale)` 构造状态样式。

## 工作原理

如果构造时未指定 `w`/`h`，自动从 `normal.texture` 的尺寸推导。`getMinimumSize()` 委托给内部 Image 子控件。文字（除非 `no_text = true`）以居中锚点叠加在图片上方。

状态切换时自动切换贴图、tint 和文字样式。

## 示例

```lua
local Utils = require "ui.utils"

local icon_btn = ImageButton({
    normal = Utils.newImageButtonStateStyle(icon_tex, nil, "Play", {1, 1, 1, 1}, 14),
    hover  = Utils.newImageButtonStateStyle(icon_hover_tex, {1, 0.9, 0.8, 1}),
    on_click = function() print("play") end,
})
```

## 最佳实践

- **推荐**：构造时通过 `normal.texture` 的尺寸自动推导按钮尺寸；手动指定 `w`/`h` 覆盖。
- **推荐**：使用 `Utils.newImageButtonStateStyle(...)` 构造样式。
- **不推荐**：在 `no_text = true` 的按钮上调用 `setText()`——会被静默忽略。
