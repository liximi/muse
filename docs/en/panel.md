# Panel

Solid-color panel with background color, outline, and rounded corners.

**Inheritance:** `Widget` → `Panel`

## Constructor Parameters (datas)

```lua
{
    bg_color = {r, g, b, a},      -- Default from theme
    outline_width = number,       -- Default from theme (1)
    outline_color = {r, g, b, a}, -- Default from theme
    rounding_radius = number,     -- Default from theme (4)
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `SetBGColor(r, g, b)` | Set background color (0-255 or `{r,g,b}` table) |
| `SetOutlineColor(r, g, b)` | Set outline color |

## Example

```lua
local panel = Panel({
    anchor = {0, 0, 1, 1},
    bg_color = Utils.RGB(40, 40, 50),
    outline_width = 2,
    rounding_radius = 8,
})
```
