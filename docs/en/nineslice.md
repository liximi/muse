# NineSlice

A 9-slice texture rendering component. Divides a texture into a 3×3 grid of nine regions: the four corners and four edges keep their original size, while the center region is stretched to fill, enabling arbitrarily-sized border/panel effects.

**Inheritance chain:** `Widget` → `NineSlice`

## Constructor Parameters (datas)

```lua
{
    texture = love.Texture,                        -- 9-slice texture (required)
    center_padding = {left, right, top, bottom},   -- pixel distance from center area to each edge (required)
}
```

`center_padding` defines the 9-slice cut lines:
- Left/right: horizontal cut position measured from the left/right edges of the texture
- Top/bottom: vertical cut position measured from the top/bottom edges of the texture

Automatic assignment of the nine Quads:

```
 1(top-left)  |  2(top-center)  |  3(top-right)
--------------+-----------------+----------------
 4(mid-left)  |  5(mid-center)  |  6(mid-right)
--------------+-----------------+----------------
 7(bot-left)  |  8(bot-center)  |  9(bot-right)
```

The center regions (2, 4, 5, 6, 8) are stretched to fit the target size, while the four corners (1, 3, 7, 9) retain their original size.

## Example

```lua
local border = NineSlice({
    texture = love.graphics.newImage("assets/border.png"),
    center_padding = {8, 8, 8, 8},  -- 8px fixed border on all sides
    anchor = {0, 0, 1, 1},
    padding = {0, 0, 0, 0},
})
```
