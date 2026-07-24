# NineSlice

九宫格切图渲染组件。将贴图分为 3×3 格，四角保持原始比例，四边单向拉伸，中心双向拉伸，实现自适应尺寸的边框/面板效果。

**继承链：** `Widget` → `NineSlice`

## 构造参数（datas）

```lua
{
    texture = love.Texture,                -- 贴图（必填）
    center_padding = {left, right, top, bottom},  -- 中心区距四边的像素边界（必填）
}
```

## 工作原理

`center_padding` 定义了贴图上的切割边界：左上角是 `(0, 0)` 到 `(left, top)`，中心区是 `(left, top)` 到 `(tex_w-right, tex_h-bottom)`，以此类推。

渲染时，四角以原始比例绘制，四边沿对应方向拉伸，中心区双向拉伸。这使得 UI 面板无论多大都保持边框的原始粗细和角部圆角。

## 示例

```lua
local tex = love.graphics.newImage("panel_border.png")

local frame = NineSlice({
    texture = tex,
    center_padding = {8, 8, 8, 8},  -- 四边各 8px 不动，中心拉伸
    anchor = {0, 0, 1, 1},
})
```
