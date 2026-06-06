# Image

贴图渲染组件，支持 tint 着色和 clamp 模式拉伸填充。

**继承链：** `Widget` → `Image`

## 构造参数（datas）

```lua
{
    texture = love.Texture,       -- LÖVE 贴图对象
    use_texture_size = boolean,   -- 是否自动将 widget 尺寸设为贴图原始尺寸
    tint = {r, g, b, a},         -- 着色，默认 {1, 1, 1, 1}
}
```

> **注意：** `use_texture_size` 与锚点「范围定位」（拉伸锚点）机制冲突，也会覆盖 `datas.w` 和 `datas.h`。

## 公有方法

| 方法 | 说明 |
|------|------|
| `setTexture(texture, resize)` | 设置贴图，`resize=true` 时自动将尺寸设为贴图原始尺寸 |
| `getTexture()` | 获取贴图对象 |
| `setTint(r, g, b, a)` 或 `setTint({r, g, b, a})` | 设置着色 |
| `getTint()` | 获取着色 |
| `getTextureRowSize()` | 获取贴图原始尺寸 `w, h` |
| `reSize()` | 将 widget 尺寸重置为贴图原始尺寸 |
| `measure(max_w, max_h)` | 查询自然尺寸：已有显式尺寸时返回当前尺寸，否则 fallback 到纹理原始尺寸 |

## clamp 模式行为

当贴图的 WrapMode 为 `"clamp"` 时，Image 会拉伸贴图来填满整个 widget 矩形范围（非 clamp 模式下使用 Quad 裁剪）。

## 示例

```lua
local img = Image({
    texture = love.graphics.newImage("assets/icon.png"),
    use_texture_size = true,
    tint = {1, 1, 1, 0.8},
    pivot = {0.5, 0.5},
    anchor = {0.5, 0.5, 0.5, 0.5},
})
```
