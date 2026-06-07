# Image

A texture rendering component with support for tint coloring and clamp-mode stretch-to-fill.

**Inheritance chain:** `Widget` → `Image`

## Constructor Parameters (datas)

```lua
{
    texture = love.Texture,       -- LÖVE texture object
    use_texture_size = boolean,   -- whether to auto-set widget size to the texture's original size
    tint = {r, g, b, a},         -- tint color, default {1, 1, 1, 1}
}
```

> **Note:** `use_texture_size` conflicts with the anchor "range positioning" (stretch anchor) mechanism and will also override `datas.w` and `datas.h`.

## Public Methods

| Method | Description |
|--------|-------------|
| `setTexture(texture, resize)` | Set texture; `resize=true` auto-sets size to the texture's original dimensions |
| `getTexture()` | Get the texture object |
| `setTint(r, g, b, a)` or `setTint({r, g, b, a})` | Set tint color |
| `getTint()` | Get the tint color |
| `getTextureRowSize()` | Get the texture's original size `w, h` |
| `reSize()` | Reset widget size to the texture's original size |
| `measure(max_w, max_h)` | Query natural size: returns current size if explicitly set, otherwise falls back to texture original size |

## Clamp Mode Behavior

When the texture's WrapMode is `"clamp"`, Image stretches the texture to fill the entire widget rectangle (non-clamp mode uses Quad clipping instead).

## Example

```lua
local img = Image({
    texture = love.graphics.newImage("assets/icon.png"),
    use_texture_size = true,
    tint = {1, 1, 1, 0.8},
    pivot = {0.5, 0.5},
    anchor = {0.5, 0.5, 0.5, 0.5},
})
```
