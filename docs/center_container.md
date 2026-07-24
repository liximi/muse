# CenterContainer

将子控件居中放置的容器。

**继承链：** `Widget` → `Container` → `CenterContainer`

## 构造参数（datas）

```lua
{
    use_top_left = boolean,  -- 设为 true 时退化为左上对齐，默认 false
}
```

## 工作原理

`_sortChildren()` 计算子控件的 `getCombinedMinimumSize()`，将子控件放在容器内水平和垂直居中的位置。`getMinimumSize()` 返回所有子控件最小尺寸的最大值。

`use_top_left = true` 时，子控件定位在容器左上角，相当于一个普通容器。

## 示例

```lua
local CenterContainer = require "ui.widgets.containers.center_container"

local cc = CenterContainer({
    anchor = {0, 0, 1, 1},
})

-- 按钮在容器中水平垂直居中
cc:addChild(Button({
    text = "Centered",
    w = 120,
    h = 40,
}))
```

## 最佳实践

- CenterContainer 适合做弹出框、对话框的内容容器。
- 子控件默认 `FILL` 时会填满整个区域（失去居中效果）。如需居中，关闭子控件的 FILL：`Button({ text = "居中", h_size_flags = 0, v_size_flags = 0 })`。
