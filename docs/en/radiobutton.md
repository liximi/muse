# RadioButton

Radio button inheriting Checkbox. Renders circular outline + filled dot. `style` is fixed to `"radio"`.

**Inheritance:** `Widget` → `ButtonBase` → `Checkbox` → `RadioButton`

## Constructor Parameters (datas)

```lua
{
    -- Inherits all Checkbox params
    circle_size = number,         -- Circle size, default from theme (20)
    circle_color = {r, g, b, a},  -- Circle fill
    dot_color = {r, g, b, a},     -- Dot color when checked
    outline_width = number,
    outline_color = {r, g, b, a},
}
```

## Public Methods

Inherits all from Checkbox: `isChecked()`, `setChecked(checked)`, `toggle()`.

## Rendering

- Circle background: `box_color` / `circle_color`
- Outline: `outline_color` + `outline_width`
- Checked: filled dot at `radius × 0.55` (`check_color` / `dot_color`)

## Example

```lua
local rb = RadioButton({
    label = "Option A",
    checked = true,
    on_checked = function(checked)
        if checked then print("Option A selected") end
    end,
})
```

> Typically used within RadioGroup for mutual exclusion.
