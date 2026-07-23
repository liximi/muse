# MarginContainer

在子控件四周附加像素边距的最简容器。自身尺寸减去四边 margin 后，把子控件放入剩余区域。

**继承链：** `Widget` → `Container` → `MarginContainer`

## 构造参数（datas）

```lua
{
    margin_left = number,    -- 左边距（像素），默认 0
    margin_right = number,   -- 右边距（像素），默认 0
    margin_top = number,     -- 上边距（像素），默认 0
    margin_bottom = number,  -- 下边距（像素），默认 0
    -- ... 也继承所有 Container / Widget 基类参数
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `getMinimumSize()` | 子控件最小尺寸 + 四边 margin |

## 示例

```lua
local margin = MarginContainer({
    margin_left = 10,
    margin_right = 10,
    margin_top = 5,
    margin_bottom = 5,
    anchor = {0, 0, 1, 1},
})
margin:addChild(Button({ text = "Wrapped", h = 40 }))
```
