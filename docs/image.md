# Image

贴图渲染组件，支持 tint 着色和 clamp 模式拉伸填充。

**继承链：** `Widget` → `Image`

## 构造参数（datas）

```lua
{
    texture = love.Texture,       -- 贴图对象
    use_texture_size = boolean,   -- 是否将 Image 尺寸重置为贴图原始尺寸
    tint = {r, g, b, a},          -- 着色，默认来自 theme.image.tint ({1,1,1,1})
}
```

> `use_texture_size` 与拉伸锚点冲突——它会覆盖 `datas.w` / `datas.h`。

## 公有方法

| 方法 | 说明 |
|------|------|
| `setTexture(texture, resize)` | 设置贴图。`resize=true` 时将尺寸重置为贴图原始尺寸 |
| `getTexture()` | 获取贴图对象 |
| `setTint(r, g, b, a)` | 设置着色。支持 `setTint({r,g,b,a})` 和 `setTint(r,g,b,a)` 两种形式 |
| `getTint()` | 获取着色 |
| `getTextureRowSize()` | 获取贴图原始尺寸 `w, h` |
| `getMinimumSize()` | 返回贴图原始尺寸 |
| `reSize()` | 将 UI 尺寸还原为贴图原始尺寸 |
| `measure(max_w, max_h)` | 已设尺寸时返回当前尺寸；未设时 fallback 到贴图原始尺寸 |

## Clamp 模式

若贴图 `WrapMode` 为 `"clamp"`，Image 会将 quad 设为贴图完整尺寸，通过缩放拉伸填满 UI 矩形区域。

## 示例

```lua
local img = love.graphics.newImage("sprite.png")

local ui_img = Image({
    texture = img,
    use_texture_size = true,
    tint = {1, 0.8, 0.6, 1},
})

-- 动态换图
local new_img = love.graphics.newImage("other.png")
ui_img:setTexture(new_img, true)
```
