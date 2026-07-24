# Checkbox / RadioButton

Checkbox (box+checkmark style) and radio button (circle+dot style).

**Inheritance:** `Widget` → `ButtonBase` → `Checkbox` → `RadioButton`

## Constructor Parameters (datas)

```lua
{
    checked = boolean,            -- Initial checked state, default false
    style = "checkbox" | "toggle", -- Style: check box or toggle switch, default "checkbox"
    box_size = number,            -- Box size (px)
    box_color = {r, g, b, a},     -- Background color
    check_color = {r, g, b, a},   -- Checkmark/dot color
    outline_width = number,       -- Outline width
    outline_color = {r, g, b, a}, -- Outline color
    rounding_radius = number,     -- Corner radius
    on_checked = function(checked), -- State change callback
    label = string | table,       -- Label text (coloredtext supported)
    label_color = {r, g, b, a},   -- Label color
    label_font_size = number,     -- Label font size
}
```

RadioButton additionally supports:

```lua
{
    circle_size = number,   -- Circle size
    circle_color = {r, g, b, a},  -- Circle background
    dot_color = {r, g, b, a},     -- Selected dot color
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `isChecked()` | Get checked state |
| `setChecked(boolean)` | Set checked state |
| `toggle()` | Toggle checked state |

## Example

```lua
-- Checkbox
local cb = Checkbox({
    label = "Enable feature",
    checked = true,
    on_checked = function(checked) print("Feature:", checked) end,
})

-- Toggle switch
local toggle = Checkbox({
    style = "toggle",
    checked = false,
})

-- Radio button
local radio = RadioButton({
    label = "Option A",
})
```
