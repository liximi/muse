# Spacer

不可见的弹性占位控件。对标 Godot 的 `Spacer`。

**继承链：** `Widget` → `Spacer`

## 工作原理

默认 `h_size_flags = FILL + EXPAND`、`v_size_flags = FILL + EXPAND`，`stretch_ratio = 1.0`。放入 BoxContainer 后吸收所有剩余空间，将后续子控件推到主轴末端。

`raycast_target = false`——鼠标事件穿透，不参与交互。

## 示例

```lua
-- 将 "Footer" 按钮推到底部
local vbox = VBoxContainer({ anchor = {0, 0, 1, 1} })
vbox:addChild(Button({ text = "Header" }))
vbox:addChild(Spacer())
vbox:addChild(Button({ text = "Footer" }))

-- 推荐使用 addSpacer() 简写
vbox:addSpacer()  -- 等价于 vbox:addChild(Spacer())
```
