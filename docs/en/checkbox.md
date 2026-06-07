# Checkbox

A checkbox component supporting two visual styles: square + checkmark and sliding toggle.

**Inheritance chain:** `Widget` → `ButtonBase` → `Checkbox`

## Constructor Parameters (datas)

```lua
{
    checked = boolean,            -- initial checked state, default false
    style = "checkbox" | "toggle", -- visual style, default "checkbox"
    box_size = number,            -- box size (pixels), default 20
    box_color = {r, g, b, a},     -- box color
    check_color = {r, g, b, a},   -- checkmark / track color
    outline_width = number,       -- outline width, default 1
    outline_color = {r, g, b, a}, -- outline color
    rounding_radius = number,     -- corner radius, default 3

    on_checked = function(checked),  -- checked-state change callback
    on_click = function(),           -- click callback (inherited from ButtonBase)
    on_pressed = function(x, y),     -- press callback

    label = string | table,       -- optional label text (coloredtext)
    label_color = {r, g, b, a},   -- label color
    label_font_size = number,     -- label font size
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `isChecked()` | Return whether currently checked |
| `setChecked(checked)` | Programmatically set checked state |
| `toggle()` | Toggle the checked state |

## Style Descriptions

- **checkbox** — square box + checkmark shown when checked
- **toggle** — sliding switch, track width is `box_size * 1.8`

## Examples

```lua
-- Square checkbox
local cb = Checkbox({
    label = "Enable feature",
    checked = true,
    on_checked = function(checked)
        print("checked:", checked)
    end,
})

-- Sliding toggle
local toggle = Checkbox({
    style = "toggle",
    checked = false,
    on_checked = function(checked)
        print("toggled:", checked)
    end,
})
```
