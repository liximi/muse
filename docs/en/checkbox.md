# Checkbox

Checkbox component supporting square+checkmark and sliding toggle styles.

**Inheritance:** `Widget` → `ButtonBase` → `Checkbox`

## Constructor Parameters (datas)

```lua
{
    checked = boolean,            -- Initial state, default false
    style = "checkbox" | "toggle", -- Default "checkbox"
    box_size = number,            -- Box size, default from theme (20)
    box_color = {r, g, b, a},     -- Box fill color
    check_color = {r, g, b, a},   -- Checkmark / active track color
    outline_width = number,       -- Default 1
    outline_color = {r, g, b, a},
    rounding_radius = number,     -- Default 3
    on_checked = function(checked),
    label = string | table,       -- Label text (supports coloredtext)
    label_color = {r, g, b, a},
    label_font_size = number,
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `isChecked()` | Get logical checked state |
| `setChecked(checked)` | Programmatically set state (triggers `onChecked`) |
| `toggle()` | Toggle state |
| `getMinimumSize()` | Returns own transform size |

## Styles

### checkbox (default)

Square box with checkmark (polyline) when checked.

### toggle

Capsule-shaped track with circular knob. Track turns `check_color` when active. Knob color from `theme.checkbox.knob_color`.

## Example

```lua
local cb = Checkbox({
    label = "Enable feature",
    checked = true,
    on_checked = function(checked) print("enabled:", checked) end,
})

local toggle = Checkbox({
    style = "toggle",
    label = "Dark mode",
    on_checked = function(checked) setDarkMode(checked) end,
})
```
