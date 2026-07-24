# PanelContainer

带样式面板背景的容器。在子控件周围绘制可配置的背景面板。

**继承链：** `Widget` → `Container` → `PanelContainer`

## 构造参数（datas）

```lua
{
    bg_color = {r, g, b, a},       -- 背景色
    outline_width = number,         -- 边框宽度
    outline_color = {r, g, b, a},   -- 边框颜色
    rounding_radius = number,       -- 圆角半径
}
```

## 工作原理

PanelContainer 在 `onDraw` 中绘制面板背景和边框。`_sortChildren()` 将子控件放置在内边距（outline_width）以内的区域。禁止子控件使用 `EXPAND`——Panel 自身不参与弹性分配。

## 示例

```lua
local pc = PanelContainer({
    bg_color = {0.12, 0.12, 0.18, 1},
    outline_width = 1,
    outline_color = {0.3, 0.3, 0.4, 1},
    rounding_radius = 6,
})
pc:addChild(Text({ text = "Content" }))
```
