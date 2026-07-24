# CenterContainer

将子控件居中放置的容器。对标 Godot 的 `CenterContainer`。

**继承链：** `Widget` → `Container` → `CenterContainer`

## 构造参数（datas）

```lua
{
    use_top_left = boolean,  -- 设为 true 时左上对齐（退化为普通容器），默认 false
}
```

## 工作原理

`_sortChildren()` 计算子控件最小尺寸，将其居中于容器内，赋给子控件的区域宽度最大化（防止文本换行被过早截断）。`use_top_left = true` 时退化为左上对齐。

## 示例

```lua
local center = CenterContainer({ w = 200, h = 100 })
center:addChild(Text({ text = "Centered" }))
```
