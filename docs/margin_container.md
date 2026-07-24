# MarginContainer

在子控件四周附加像素边距的容器。对标 Godot 的 `MarginContainer`。

**继承链：** `Widget` → `Container` → `MarginContainer`

## 构造参数（datas）

```lua
{
    margin_left   = number,  -- 左边距，默认 0
    margin_right  = number,  -- 右边距，默认 0
    margin_top    = number,  -- 上边距，默认 0
    margin_bottom = number,  -- 下边距，默认 0
}
```

## 工作原理

`_sortChildren()` 将容器尺寸减去四边 margin 后，调用 `fitChildInRect` 将所有子控件放入剩余区域。`getMinimumSize()` = 子控件最大最小尺寸 + 四边 margin。

## 示例

```lua
local margin = MarginContainer({
    margin_left = 16, margin_right = 16,
    margin_top = 8, margin_bottom = 8,
})
margin:addChild(Button({ text = "Padded" }))
```
