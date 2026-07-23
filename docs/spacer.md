# Spacer

不可见的弹性占位控件（对标 Godot `BoxContainer::add_spacer`）。射线穿透，两个轴都设为 `EXPAND + FILL`。

**继承链：** `Widget` → `Spacer`

无构造参数。

## 用法

```lua
local hbox = BoxContainer({ orientation = "horizontal" })
hbox:addChild(Button({ text = "Left", w = 80 }))
hbox:addChild(Spacer())  -- 把后续子控件推到右边
hbox:addChild(Button({ text = "Right", w = 80 }))
```

也可直接用 `BoxContainer:addSpacer()` 快捷方法。

## 属性

| 属性 | 值 | 说明 |
|------|-----|------|
| `h_size_flags` | `FILL + EXPAND` (3) | 水平方向参与瓜分 |
| `v_size_flags` | `FILL + EXPAND` (3) | 垂直方向参与瓜分 |
| `stretch_ratio` | `1.0` | 瓜分比例 |
| `raycast_target` | `false` | 鼠标事件穿透 |
