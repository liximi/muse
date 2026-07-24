# CenterContainer

将所有子控件居中放置的容器。子控件保持最小尺寸，水平和垂直均居中。

**继承链：** `Widget` → `Container` → `CenterContainer`

## 构造参数（datas）

```lua
{
    use_top_left = boolean,  -- 设为 true 时退化为左上对齐（等同于普通容器），默认 false
    -- ... 也继承所有 Container / Widget 基类参数
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `getMinimumSize()` | 所有子控件最小尺寸取 max |

## 示例

```lua
local center = CenterContainer({
    anchor = {0, 0, 1, 1},
})
-- 按钮会在容器内居中，保持其最小尺寸
center:addChild(Button({ text = "Centered Button" }))
```
