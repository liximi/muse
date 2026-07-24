# Image

Texture rendering component with tint coloring and clamp-mode stretch-to-fill.

**Inheritance:** `Widget` → `Image`

## Constructor Parameters (datas)

```lua
{
    texture = love.Texture,       -- Required
    use_texture_size = boolean,   -- Reset size to texture's native dimensions
    tint = {r, g, b, a},          -- Default from theme ({1,1,1,1})
}
```

> `use_texture_size` conflicts with stretch anchors.

## Public Methods

| Method | Description |
|--------|-------------|
| `setTexture(texture, resize)` | Set texture; `resize=true` resets size |
| `setTint(r, g, b, a)` | Set tint (supports table or separate args) |
| `getTextureRowSize()` | Get native texture size |
| `getMinimumSize()` | Returns native texture size |
| `reSize()` | Reset size to native texture size |
| `measure(max_w, max_h)` | Returns current or native size |

## Clamp Mode

When texture `WrapMode` is `"clamp"`, the quad is set to full texture size and scaled to fill the UI rectangle.

## Example

```lua
local img = Image({
    texture = love.graphics.newImage("sprite.png"),
    use_texture_size = true,
    tint = {1, 0.8, 0.6, 1},
})
```
