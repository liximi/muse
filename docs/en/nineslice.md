# NineSlice

9-slice texture rendering. Divides a texture into 3×3 cells: corners keep original proportions, edges stretch unidirectionally, center stretches bidirectionally.

**Inheritance:** `Widget` → `NineSlice`

## Constructor Parameters (datas)

```lua
{
    texture = love.Texture,                -- Required
    center_padding = {left, right, top, bottom},  -- Required: cut boundaries (px)
}
```

## How It Works

`center_padding` defines the cut boundaries on the texture. Corners render at original scale, edges stretch along their respective axes, and the center stretches both ways.

## Example

```lua
local frame = NineSlice({
    texture = love.graphics.newImage("panel_border.png"),
    center_padding = {8, 8, 8, 8},
    anchor = {0, 0, 1, 1},
})
```
