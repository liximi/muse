# Panel

A solid-color panel component with configurable background color, outline, and rounded corners.

**Inheritance chain:** `Widget` → `Panel`

## Constructor Parameters (datas)

```lua
{
    bg_color = {r, g, b, a},      -- background color, defaults to theme.panel.bg_color
    outline_width = number,        -- outline width (pixels), default 1
    outline_color = {r, g, b, a},  -- outline color, defaults to theme.panel.outline_color
    rounding_radius = number,      -- corner radius (pixels), default 4
}
```

All fields above can be combined with `Widget` base class datas fields (such as `anchor`, `padding`, etc.).

## Public Methods

| Method | Description |
|--------|-------------|
| `SetBGColor(r, g, b)` or `SetBGColor({r, g, b, a})` | Set background color; accepts 0~255 integers or {0~1} table |
| `SetOutlineColor(r, g, b)` or `SetOutlineColor({r, g, b, a})` | Set outline color |

## Example

```lua
local panel = Panel({
    anchor = {0, 0, 1, 1},
    padding = {10, 10, 10, 10},
    bg_color = Utils.RGB(40, 40, 50),
    rounding_radius = 8,
    outline_width = 2,
    outline_color = Utils.RGB(100, 100, 120),
})
```
