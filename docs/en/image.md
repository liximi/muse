# Image

Image display widget. Supports texture stretching, tint coloring, and `use_texture_size` auto-sizing.

**Inheritance:** `Widget` → `Image`

## Constructor Parameters (datas)

```lua
{
    texture = love.Texture,    -- Texture object
    use_texture_size = boolean, -- Auto-set widget size to texture's original dimensions
    tint = {r, g, b, a},       -- Tint color (multiplied with texture)
}
```

## How It Works

`getMinimumSize()` returns the texture's original dimensions. If the texture's WrapMode is `"clamp"`, drawing adjusts the scale to stretch-fill the widget area (rather than repeating/tiling).

## Public Methods

| Method | Description |
|--------|-------------|
| `setTexture(texture, resize)` | Set texture; `resize=true` auto-sizes widget to texture dimensions |
| `getTexture()` | Get current texture |
| `setTint({r, g, b, a})` | Set tint color |
| `reSize()` | Reset widget size to texture original dimensions |
| `getTextureRowSize()` | Get texture original width/height |

## Example

```lua
-- Display image and auto-size to texture dimensions
local img = Image({
    texture = my_texture,
    use_texture_size = true,
})

-- Fixed-size icon with tint
local icon = Image({
    texture = icon_texture,
    w = 32, h = 32,
    tint = {1, 1, 1, 0.8},
})
```
