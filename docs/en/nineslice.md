# NineSlice

9-slice scaled image. Divides a texture into a 3×3 grid; corners and edges keep their original size while the center stretches to fill.

**Inheritance:** `Widget` → `NineSlice`

## Constructor Parameters (datas)

```lua
{
    texture = love.Texture,       -- Texture object (required)
    center_padding = {left, right, top, bottom},  -- Center area margins (px), defining corner sizes
}
```

## How It Works

The texture is divided into nine regions by `center_padding`. Corners draw at original scale, edges stretch in one axis, and the center stretches in both axes. Ideal for UI backgrounds that need to preserve border and corner appearance at varying sizes.

## Example

```lua
local bg = NineSlice({
    texture = panel_texture,
    center_padding = {12, 12, 12, 12},  -- 12px corners
    anchor = {0, 0, 1, 1},
})
```
