# Image

图片显示控件。支持纹理拉伸、tint 着色和 `use_texture_size` 自动尺寸。

**继承链：** `Widget` → `Image`

## 构造参数（datas）

```lua
{
    texture = love.Texture,    -- 贴图对象
    use_texture_size = boolean, -- 是否将控件尺寸设为纹理原始尺寸
    tint = {r, g, b, a},       -- 着色（将乘以纹理颜色）
}
```

## 工作原理

`getMinimumSize()` 返回纹理原始尺寸。若纹理的 WrapMode 为 `"clamp"`，绘制时通过调整 scale 来拉伸填充控件区域（而非重复平铺）。

## 公有方法

| 方法 | 说明 |
|------|------|
| `setTexture(texture, resize)` | 设置贴图，`resize=true` 时自动将控件尺寸设为纹理原始尺寸 |
| `getTexture()` | 获取当前贴图 |
| `setTint({r, g, b, a})` | 设置着色 |
| `reSize()` | 将控件尺寸重置为纹理原始尺寸 |
| `getTextureRowSize()` | 获取纹理原始宽高 |

## 示例

```lua
-- 显示图片并自动使用纹理尺寸
local img = Image({
    texture = my_texture,
    use_texture_size = true,
})

-- 指定尺寸的图标
local icon = Image({
    texture = icon_texture,
    w = 32, h = 32,
    tint = {1, 1, 1, 0.8},
})
```
