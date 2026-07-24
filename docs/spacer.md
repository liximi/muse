# Spacer

不可见的弹性占位控件。对标 Godot 的 `Control` 作为 `add_spacer` 使用。

**继承链：** `Widget` → `Spacer`

## 用途

Spacer 是一种"空气"控件——它不可见（无 onDraw），不拦截射线（`raycast_target = false`），两个轴都设为 `FILL + EXPAND`。放入 BoxContainer 后，它会吞掉所有剩余空间，将后续子控件推到主轴末端。

## 属性

| 属性 | 值 | 说明 |
|------|-----|------|
| `h_size_flags` | `FILL + EXPAND` (=3) | 水平方向填满并参与瓜分 |
| `v_size_flags` | `FILL + EXPAND` (=3) | 垂直方向填满并参与瓜分 |
| `stretch_ratio` | `1.0` | 瓜分权重 |
| `raycast_target` | `false` | 鼠标穿透 |

## 示例

```lua
-- VBox 中：将后续控件推到底部
local vbox = VBoxContainer({ anchor = {0, 0, 1, 1} })
vbox:addChild(Button({ text = "Top" }))
vbox:addSpacer()  -- ← 等效于 vbox:addChild(Spacer())
vbox:addChild(Button({ text = "Bottom" }))

-- HBox 中：将后续控件推到右边
local hbox = HBoxContainer({ anchor = {0, 0, 1, 0} })
hbox:addChild(Text({ text = "Left" }))
hbox:addSpacer()
hbox:addChild(Button({ text = "Right" }))

-- 手动创建
local Spacer = require "ui.widgets.spacer"
local sp = Spacer()
sp.stretch_ratio = 2.0  -- 可调整权重
```

## 最佳实践

- 优先使用 `box:addSpacer()` 快捷方法而不是手动 `box:addChild(Spacer())`。
- 多个 Spacer 可以有不同的 `stretch_ratio` 来实现非均等分配（如 1:2:1 的三栏布局）。
