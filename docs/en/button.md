# Button

Text button with 6 state styles (normal/pressed/hover/selected/selected_hover/disabled).

**Inheritance:** `Widget` → `ButtonBase` → `Button`

## Constructor Parameters (datas)

```lua
{
    text = string,                -- Button text
    font_key = string,            -- Font key
    on_click = function(),        -- Click callback
    on_pressed = function(x, y),  -- Press callback

    -- State styles (each is a Utils.newButtonStateStyle return value)
    normal / hover / pressed / disabled / selected / selected_hover = style,
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `setText(t)` | Set button text (text is independent of state changes) |
| `getText()` | Get button text |
| `setStateStyle(state, style)` | Set a state's style. If style contains `text`, auto-calls `setText()` (legacy compatibility) |
| `getStateStyle(state)` | Get merged state style (custom > theme state > custom normal > theme normal). **text field is excluded from merge** |
| `getMinimumSize()` | Internal text min size + padding (2px × 4) |

## Text / Style Separation (2026-07 refactor)

Button text content and visual style are independent:

- `setText()` manages text content
- `setStateStyle()` manages visual properties (color, size, background, outline)
- State transitions only change color and font size, never text
- `getStateStyle()` merge skips the `text` field

## State Style Fields

```lua
{
    text_color = {r, g, b, a},  -- Text color
    font_size = number,         -- Font size
    bg_color = {r, g, b, a},    -- Background color
    outline_width = number,     -- Outline width
    outline_color = {r, g, b, a}, -- Outline color
    offset = {x, y},            -- Position offset (e.g. {0, 2} for press)
    scale = {sx, sy},           -- Scale
    rounding_radius = number,   -- Corner radius
}
```

## Example

```lua
local btn = Button({
    text = "Click Me",
    anchor = {0, 0, 1, 0},
    h = 40,
    normal = Utils.newButtonStateStyle(nil, Utils.UI_COLORS.TITLE, nil, Utils.UI_COLORS.BTN_NORMAL, nil, nil, nil, nil, 4),
    hover = Utils.newButtonStateStyle(nil, nil, nil, Utils.UI_COLORS.BTN_HOVER, 1, Utils.UI_COLORS.LINE),
    pressed = Utils.newButtonStateStyle(nil, nil, nil, nil, nil, nil, {0, 2}),
    on_click = function() print("clicked!") end,
})
```
