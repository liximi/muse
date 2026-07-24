# MarginContainer

在子控件四周附加像素边距的最简容器。

**继承链：** `Widget` → `Container` → `MarginContainer`

## 构造参数（datas）

```lua
{
    margin_left   = number,  -- 左边距（像素），默认 0
    margin_right  = number,  -- 右边距（像素），默认 0
    margin_top    = number,  -- 上边距（像素），默认 0
    margin_bottom = number,  -- 下边距（像素），默认 0
}
```

## 工作原理

`_sortChildren()` 将自身尺寸减去四边 margin 后，把子控件放入剩余区域。`getMinimumSize()` 返回子控件最小尺寸 + 四边 margin。

## 示例

```lua
local MarginContainer = require "ui.widgets.containers.margin_container"

local mc = MarginContainer({
    margin_left = 16,
    margin_right = 16,
    margin_top = 8,
    margin_bottom = 8,
    anchor = {0, 0, 1, 1},
})

mc:addChild(Text({ text = "Content with margins" }))
```

## 最佳实践

- MarginContainer 是无样式容器。如需带背景色的边距区域，用 Panel 包裹并通过 padding 控制。
- 优先用 MarginContainer 而非直接设子控件 padding——边距是容器的职责。
