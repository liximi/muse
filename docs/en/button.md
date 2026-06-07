# Button

A text button component supporting 6 state styles (normal / pressed / hover / selected / selected_hover / disabled).

**Inheritance chain:** `Widget` → `ButtonBase` → `Button`

## Constructor Parameters (datas)

```lua
{
    font_key = string,            -- font key
    normal = style_table,         -- default state style (Utils.newButtonStateStyle)
    hover = style_table,          -- hover state style
    pressed = style_table,        -- pressed state style
    disabled = style_table,       -- disabled state style
    selected = style_table,       -- selected state style
    selected_hover = style_table, -- selected + hover state style

    on_click = function(),        -- click callback (inherited from ButtonBase)
    on_pressed = function(x, y),  -- press callback (inherited from ButtonBase)
}
```

### State Style Fields (returned by `Utils.newButtonStateStyle`)

```lua
{
    text = string | table,        -- button text (supports coloredtext)
    text_color = {r, g, b, a},    -- text color
    font_size = number,           -- font size
    bg_color = {r, g, b, a},      -- background color
    outline_width = number,       -- outline width
    outline_color = {r, g, b, a}, -- outline color
    offset = {x, y},              -- positional offset (pixels)
    scale = {sx, sy},             -- scale
    rounding_radius = number,     -- corner radius
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `setStateStyle(state, style)` | Set the style for a given state; state is `"normal"` / `"pressed"` / `"disabled"` / `"selected"` / `"hover"` / `"selected_hover"` |
| `getStateStyle(state)` | Get the merged style for a state (auto-merges custom style, normal style, and theme style) |

## Methods Inherited from ButtonBase

| Method | Description |
|--------|-------------|
| `setState(new_state)` | Switch button state (triggers `onSetState`) |
| `setSelected(selected)` | Set selected state (triggers `onSelected` / `onUnselected`) |

## State Transitions

```
NORMAL ⇄ HOVER
  ↓        ↓
PRESSED  SELECTED_HOVER
           ⇅
         SELECTED
```

- Mouse enter → `HOVER` (or `SELECTED_HOVER`)
- Mouse leave → `NORMAL` (or `SELECTED`)
- Press → `PRESSED`
- Release (inside bounds) → `HOVER` or `SELECTED_HOVER`
- Release (outside bounds) → `NORMAL` or `SELECTED`
- Disable → `DISABLED`
- Enable → `NORMAL`

## Style Merge Priority

`state_styles[target]` > `state_styles["normal"]` > `theme.button[target]` > `theme.button["normal"]`

## Example

```lua
local btn = Button({
    w = 120,
    h = 36,
    normal = Utils.newButtonStateStyle("Click Me", Utils.UI_COLORS.TITLE, 16,
                Utils.UI_COLORS.BTN_NORMAL, nil, nil, nil, nil, 4),
    hover = Utils.newButtonStateStyle(nil, nil, nil,
                Utils.UI_COLORS.BTN_HOVER, 1, Utils.UI_COLORS.LINE, {0, -1}),
    pressed = Utils.newButtonStateStyle(nil, nil, nil, nil, nil, nil, {0, 2}),
    on_click = function()
        print("clicked!")
    end,
})
```
