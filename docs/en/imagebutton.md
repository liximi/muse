# ImageButton

Image button with texture/tint switching and optional attached text.

**Inheritance:** `Widget` → `ButtonBase` → `ImageButton`

## Constructor Parameters (datas)

```lua
{
    no_text = boolean,            -- Pure image button (no text), default false
    font_key = string,            -- Font key
    on_click = function(),
    on_pressed = function(x, y),

    -- State styles (each is a Utils.newImageButtonStateStyle return value)
    normal / hover / pressed / disabled / selected / selected_hover = style,
}
```

If `normal` style contains a `texture`, the button defaults to that texture's dimensions (when `w`/`h` not explicitly set).

## Public Methods

| Method | Description |
|--------|-------------|
| `setText(t)` | Set text (silently ignored in `no_text` mode) |
| `setStateStyle(state, style)` | Set state style; auto-updates texture and tint on state change |
| `getStateStyle(state)` | Get merged state style |

## State Style Fields

```lua
{
    texture = love.Texture,     -- Texture
    tint = {r, g, b, a},        -- Color tint
    text = string,              -- Text
    text_color = {r, g, b, a},  -- Text color
    font_size = number,         -- Font size
    offset = {x, y},            -- Offset
    scale = {sx, sy},           -- Scale
}
```

## Example

```lua
local icon = love.graphics.newImage("icon.png")
local ibtn = ImageButton({
    normal = Utils.newImageButtonStateStyle(icon, {1,1,1,1}, "Save", Utils.UI_COLORS.TITLE, 14),
    hover = Utils.newImageButtonStateStyle(icon_hover, nil, nil, nil, nil, {0, -1}),
    disabled = Utils.newImageButtonStateStyle(nil, {0.4,0.4,0.4,1}, nil, Utils.UI_COLORS.SECONDARY_TEXT),
    on_click = function() print("clicked") end,
})
```
