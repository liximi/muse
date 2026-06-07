# ImageButton

An image button component that adds texture switching on top of ButtonBase, with optional accompanying text.

**Inheritance chain:** `Widget` → `ButtonBase` → `ImageButton`

## Constructor Parameters (datas)

```lua
{
    no_text = boolean,            -- whether to hide text (pure image button)
    font_key = string,            -- font key
    normal = style_table,         -- default state style (Utils.newImageButtonStateStyle)
    hover = style_table,
    pressed = style_table,
    disabled = style_table,
    selected = style_table,
    selected_hover = style_table,

    on_click = function(),        -- click callback (inherited from ButtonBase)
    on_pressed = function(x, y),  -- press callback (inherited from ButtonBase)
}
```

If `datas.w` / `datas.h` are not set, they will be inferred from the size of `normal.texture`.

### State Style Fields (returned by `Utils.newImageButtonStateStyle`)

```lua
{
    texture = love.Texture,       -- texture
    tint = {r, g, b, a},         -- tint color
    text = string | table,        -- text (coloredtext)
    text_color = {r, g, b, a},    -- text color
    font_size = number,           -- font size
    offset = {x, y},              -- positional offset
    scale = {sx, sy},             -- scale
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `setStateStyle(state, style)` | Set the style for a given state |
| `getStateStyle(state)` | Get the merged style |

State transition logic is identical to Button (inherited from ButtonBase).

## Example

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
