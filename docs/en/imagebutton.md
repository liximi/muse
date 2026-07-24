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

    -- Inherited from Widget
    h_size_flags = number,     -- SIZE_FLAGS combo, default FILL
    v_size_flags = number,     -- SIZE_FLAGS combo, default FILL
    stretch_ratio = number,    -- EXPAND weight, default 1.0
    custom_minimum_size = {w, h},  -- Override content min size
    -- ... and all Widget base params (pivot, anchor, x, y, w, h, padding, etc.)
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

## Size & Container Compatibility

ImageButton reports `getMinimumSize()` from its internal Image widget's texture dimensions, so it works directly inside BoxContainer and other layout containers — no need for `custom_minimum_size`.

If no `texture` is provided in the `normal` style, `getMinimumSize()` returns `(0, 0)` and you must set explicit dimensions when placing it in a container.

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
