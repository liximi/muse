# Button

Standard button widget. Supports six visual states (normal/hover/pressed/disabled/selected/selected_hover), each independently configurable for background color, text color, font size, outline, etc.

**Inheritance:** `Widget` → `ButtonBase` → `Button`

## Constructor Parameters (datas)

```lua
{
    text = string | table,    -- Button text (also supports coloredtext)
    font_key = string,        -- Font key
    on_click = function,      -- Click callback
    on_pressed = function,    -- Press callback

    -- State styles (see Utils.newButtonStateStyle)
    normal = Utils.newButtonStateStyle,
    hover = Utils.newButtonStateStyle,
    pressed = Utils.newButtonStateStyle,
    disabled = Utils.newButtonStateStyle,
    selected = Utils.newButtonStateStyle,
    selected_hover = Utils.newButtonStateStyle,
}
```

## How It Works

### State Machine

Button inherits from `ButtonBase` and maintains six states. States transition automatically on mouse enter/leave and press/release. `setSelected(true/false)` is used for programmatic selection toggling (e.g., Checkbox, Tab buttons).

### Text-Style Separation

Button text is managed independently via `setText()` / the `text` constructor parameter. State transitions only change color and font size, not the text content. Unlike older versions, `getStateStyle` skips the `text` field when merging styles.

> `setStateStyle(state, style)` still auto-calls `setText(style.text)` if `style.text` exists — this is backward compatibility behavior; new code should not rely on it.

### Minimum Size

`getMinimumSize()` returns the inner Text's minimum size plus 2px padding on each side.

## Public Methods

| Method | Description |
|--------|-------------|
| `setText(text)` | Set button text |
| `getText()` | Get button text |
| `setStateStyle(state, style)` | Set style for a state |
| `getStateStyle(state)` | Get merged state style (custom + theme) |
| `setSelected(selected)` | Set selected state |
| `setState(new_state)` | Direct state switch (inherited from ButtonBase) |

## Example

```lua
local Utils = require "ui.utils"

-- Basic button
local btn = Button({
    text = "Click Me",
    normal = Utils.newButtonStateStyle("Click Me", nil, 14,
        Utils.UI_COLORS.BTN_NORMAL, 1, Utils.UI_COLORS.LINE),
    hover = Utils.newButtonStateStyle(nil, nil, 14,
        Utils.UI_COLORS.BTN_HOVER, 1, Utils.UI_COLORS.ACCENT_LIGHT),
    on_click = function()
        print("clicked!")
    end,
})

-- Toggle-style button with selected state
local toggle_btn = Button({
    text = "Toggle",
    normal = Utils.newButtonStateStyle("Toggle", nil, 14,
        Utils.UI_COLORS.BTN_NORMAL),
    selected = Utils.newButtonStateStyle(nil, {1, 1, 1, 1}, 14,
        Utils.UI_COLORS.ACCENT),
})
```

## Best Practices

- **Do**: Set button text via the constructor `text` parameter or `setText()`, not via `setStateStyle` side effects.
- **Do**: Use `Utils.newButtonStateStyle(...)` to construct style tables with positional arguments.
- **Don't**: Block for long periods in `on_click` callbacks — event handlers should return quickly.
- **Don't**: Use unregistered font keys in button text — this causes runtime errors.
