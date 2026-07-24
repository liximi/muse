# Panel

Solid-color rectangular panel with background, outline, and rounded corners. Commonly used as backgrounds or decorative elements for other widgets.

**Inheritance:** `Widget` → `Panel`

## Constructor Parameters (datas)

```lua
{
    bg_color = {r, g, b, a},       -- Background color
    outline_width = number,         -- Outline width (px)
    outline_color = {r, g, b, a},   -- Outline color
    rounding_radius = number,       -- Corner rounding radius (px)
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `SetBGColor(r, g, b)` | Set background color (0~255 or `{r, g, b, a}` table) |
| `SetOutlineColor(r, g, b)` | Set outline color (same format) |

## Example

```lua
-- Basic panel
local panel = Panel({
    w = 200, h = 100,
    bg_color = {0.1, 0.12, 0.16, 1},
    outline_width = 1,
    outline_color = {0.3, 0.3, 0.4, 1},
    rounding_radius = 8,
})

-- As TextInput background
local bg = Panel({
    bg_color = {0.08, 0.08, 0.1, 1},
    rounding_radius = 4,
})
local input = TextInput({ w = 200, h = 32, bg = bg })
```
