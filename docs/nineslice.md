# NineSlice

九宫格切图渲染组件，将贴图分为 3×3 共九个区域，四角和四边保持原始尺寸，中央区域拉伸填充，实现任意尺寸的边框/面板效果。

**继承链：** `Widget` → `NineSlice`

## 构造参数（datas）

```lua
{
    texture = love.Texture,                        -- 九宫格贴图（必填）
    center_padding = {left, right, top, bottom},   -- 中央区域距四边的像素距离（必填）
}
```

`center_padding` 定义了九宫格切割线：
- 左/右：距离贴图左/右边缘的水平切割位置
- 上/下：距离贴图上/下边缘的垂直切割位置

九个 Quad 的自动分配：

```
 1(top-left)  |  2(top-center)  |  3(top-right)
--------------+-----------------+----------------
 4(mid-left)  |  5(mid-center)  |  6(mid-right)
--------------+-----------------+----------------
 7(bot-left)  |  8(bot-center)  |  9(bot-right)
```

中央区域（2, 4, 5, 6, 8）会被拉伸以适配目标尺寸，四角（1, 3, 7, 9）保持原始尺寸。

## 示例

```lua
local border = NineSlice({
    texture = love.graphics.newImage("assets/border.png"),
    center_padding = {8, 8, 8, 8},  -- 四边各 8px 为固定边框
    anchor = {0, 0, 1, 1},
    padding = {0, 0, 0, 0},
})
```
