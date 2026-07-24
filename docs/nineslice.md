# NineSlice

九宫格缩放图片。将纹理分成 3×3 的九宫格区域，四角和四边保持原始尺寸，中央区域拉伸填充。

**继承链：** `Widget` → `NineSlice`

## 构造参数（datas）

```lua
{
    texture = love.Texture,       -- 贴图对象（必填）
    center_padding = {left, right, top, bottom},  -- 中央区域边距（像素），定义四角尺寸
}
```

## 工作原理

将纹理按 `center_padding` 划分为九个区域。四角以原始比例绘制，四边单向拉伸，中央区域双向拉伸。适用于需要在不同尺寸下保持边框和圆角不变的 UI 背景。

## 示例

```lua
local bg = NineSlice({
    texture = panel_texture,
    center_padding = {12, 12, 12, 12},  -- 四角 12px
    anchor = {0, 0, 1, 1},
})
```
