# BoxContainer

线性排列子控件的容器，支持水平（HBoxContainer）和垂直（VBoxContainer）两个方向。对标 Godot 的 `BoxContainer`。

**继承链：** `Widget` → `Container` → `BoxContainer`

## 构造参数（datas）

```lua
{
    orientation = "vertical" | "horizontal",  -- 排列方向，默认 "vertical"
    separation  = number,    -- 子控件间距（像素），默认 0
    alignment   = "begin" | "center" | "end", -- 整体对齐，默认 "begin"
    auto_size   = boolean,   -- 是否在主轴方向自动调整尺寸，默认 false
}
```

## 工作原理

BoxContainer 将子控件沿主轴线性排列。每个子控件的尺寸由三步分配算法决定：

1. **第一趟** — 收集每个子控件的 `getCombinedMinimumSize()` 和 `getDesiredSize()`，统计 EXPAND 标记和 stretch_ratio。
2. **第二趟 A** — 按 desired_size 比例分配初始可用空间，优先满足子控件的期望尺寸。
3. **第二趟 B** — 按 stretch_ratio 比例将剩余空间瓜分给 EXPAND 子控件。最后一个 EXPAND 子控件吸收舍入误差。
4. **第三趟** — 调用 `fitChildInRect` 逐个定位，无 EXPAND 时应用 alignment 偏移。

## 公有方法

| 方法 | 说明 |
|------|------|
| `addSpacer()` | 添加弹性占位符，后续子控件被推到主轴末端 |

## SizeFlags — 子控件布局意图

每个子控件持有 `h_size_flags`、`v_size_flags`（默认 `FILL`）和 `stretch_ratio`（默认 1.0）：

| 标志 | 值 | 含义 |
|------|-----|------|
| `FILL` | 1 | 填满分到的区域（默认） |
| `EXPAND` | 2 | 参与剩余空间瓜分 |
| `SHRINK_CENTER` | 4 | 在区域内居中（需关闭 FILL） |
| `SHRINK_END` | 8 | 在区域内靠右/下（需关闭 FILL） |
| `SHRINK_BEGIN` | 0 | 保持最小尺寸，靠左/上 |

## 最小尺寸

`getMinimumSize()` 返回 `math.max(children_sum, container_size)`。

## auto_size

开启后每次重排自动在主轴方向将自身尺寸调整为子控件总尺寸。

## 便捷构造

```lua
local HBoxContainer = require "ui.widgets.containers.box_h_container"
local hbox = HBoxContainer({separation = 8})

local VBoxContainer = require "ui.widgets.containers.box_v_container"
local vbox = VBoxContainer({separation = 4})
```

## 示例

```lua
-- VBox + Spacer 推底
local vbox = VBoxContainer({ anchor = {0, 0, 1, 1}, separation = 4 })
vbox:addChild(Button({ text = "First" }))
vbox:addSpacer()
vbox:addChild(Button({ text = "Bottom" }))

-- HBox：左边固定标签 + 右边填满
local hbox = HBoxContainer({ anchor = {0, 0, 1, 0}, h = 32, separation = 8 })
hbox:addChild(Text({ text = "Name:", h_size_flags = 0 }))
hbox:addChild(Text({ text = "John Doe", h_size_flags = Utils.SIZE_FLAGS.FILL + Utils.SIZE_FLAGS.EXPAND }))
```

## 最佳实践

- **VBox 在 Scroll 内**：用 `anchor = {0, 0, 1, 0}` 水平填满 scroll_root。
- **auto_size + Scroll**：VBox 开启 `auto_size = true` 配合 Scroll 的 `auto_track`。
- **普通 Widget 需 min size**：非 Button/Text 控件放入 BoxContainer 时调用 `setCustomMinimumSize` 或设置 `h` 属性。
