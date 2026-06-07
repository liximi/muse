# RadioButton

A radio button that inherits from Checkbox, rendered as a circular outline with a filled dot.

**Inheritance chain:** `Widget` → `ButtonBase` → `Checkbox` → `RadioButton`

## Constructor Parameters (datas)

In addition to all of Checkbox's parameters, the following are supported:

```lua
{
    circle_size = number,         -- circle size (pixels), defaults to theme
    circle_color = {r, g, b, a},  -- circle color
    dot_color = {r, g, b, a},     -- selected dot color
    outline_width = number,       -- outline width
    outline_color = {r, g, b, a}, -- outline color

    -- Also inherits these Checkbox parameters:
    checked = boolean,
    label = string | table,
    label_color = {r, g, b, a},
    on_checked = function(checked),
    on_click = function(),
}
```

## Public Methods

Same as Checkbox:

| Method | Description |
|--------|-------------|
| `isChecked()` | Return whether currently selected |
| `setChecked(checked)` | Programmatically set selected state |
| `toggle()` | Toggle the selected state |

## Notes

- `style` is fixed to `"radio"` and cannot be changed
- When selected, renders a filled dot with a radius of 55% of the outer circle
- Typically used with RadioGroup to achieve mutual exclusion

## Example

```lua
local rb = RadioButton({
    label = "Option A",
    checked = true,
    on_checked = function(checked)
        print("selected:", checked)
    end,
})
```
