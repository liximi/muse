# RadioButton

Radio button. Inherits Checkbox, renders as a circular outline with a solid dot. See [Checkbox](checkbox.md).

**Inheritance:** `Widget` → `ButtonBase` → `Checkbox` → `RadioButton`

## Additional Constructor Parameters

```lua
{
    circle_size = number,         -- Circle size
    circle_color = {r, g, b, a},  -- Circle background
    dot_color = {r, g, b, a},     -- Selected dot color
    outline_width = number,       -- Outline width
    outline_color = {r, g, b, a}, -- Outline color
}
```

RadioButton is fixed to `style = "radio"` (circle + dot); switching to checkbox or toggle style is not supported. All other behavior matches Checkbox, including `label`, `on_checked` callback, etc.

## Example

```lua
local radio = RadioButton({
    label = "Option A",
    checked = true,
    on_checked = function(checked) print("Selected:", checked) end,
})
```

## Best Practices

- **Do**: Place a group of RadioButtons in a RadioGroup for mutual exclusion.
- **Don't**: Manually manage mutual exclusion across multiple RadioButtons — use RadioGroup.
