# BoxContainer

线性排列子控件的容器，支持水平和垂直方向。对标 Godot 的 `BoxContainer`。

**继承链：** `Widget` → `Container` → `BoxContainer`

## 构造参数（datas）

```lua
{
    orientation = "vertical" | "horizontal",  -- 排列方向，默认 "vertical"
    separation  = number,    -- 子控件间距（像素），默认 0
    alignment   = "begin" | "center" | "end", -- 无 EXPAND 时的整体对齐，默认 "begin"
    auto_size   = boolean,   -- 主轴自动尺寸，默认 false
}
```

## 工作原理

BoxContainer 沿主轴线性排列子控件，使用三趟分配算法：

1. **第一趟** — 收集每个可见子控件的 `getCombinedMinimumSize()` 和 `getDesiredSize()`，统计 EXPAND 标记和 `stretch_ratio`。
2. **第二趟 A** — 按 desired_size 比例分配初始空间，优先满足子控件的期望尺寸。非 stretch 子控件增加的尺寸从 stretch 池中扣除。
3. **第二趟 B** — 按 `stretch_ratio` 比例将剩余空间分配给 EXPAND 子控件。最后一个 EXPAND 子控件吸收浮点舍入误差。
4. **第三趟** — 调用 `fitChildInRect` 逐个定位，辅轴拉伸到容器交叉轴尺寸。无 EXPAND 子控件时应用 `alignment` 整体偏移。

### 最小尺寸

`getMinimumSize()` 返回 `math.max(children_sum, container_size)`——子控件沿主轴的总尺寸与容器显式尺寸取较大值。

### auto_size

开启后在主轴方向自动将自身尺寸调整为子控件总尺寸（含间距）。

## 便捷构造

```lua
local HBoxContainer = require "ui.widgets.containers.box_h_container"
local hbox = HBoxContainer({ separation = 8 })

local VBoxContainer = require "ui.widgets.containers.box_v_container"
local vbox = VBoxContainer({ separation = 4 })
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `addSpacer()` | 添加弹性占位符（EXPAND + FILL），后续子控件被推到主轴末端 |

## 示例

```lua
local Utils = require "ui.utils"
local SZ = Utils.SIZE_FLAGS

-- VBox + Spacer 推底
local vbox = VBoxContainer({ anchor = {0, 0, 1, 1}, separation = 4 })
vbox:addChild(Button({ text = "Header" }))
vbox:addSpacer()
vbox:addChild(Button({ text = "Footer" }))

-- HBox：左侧固定标签 + 右侧填满+扩展
local hbox = HBoxContainer({ anchor = {0, 0, 1, 0}, h = 32, separation = 8 })
hbox:addChild(Text({ text = "Name:", h_size_flags = 0 }))
hbox:addChild(Text({
    text = "John Doe",
    h_size_flags = SZ.FILL + SZ.EXPAND,
}))
```

## 最佳实践

- **推荐**：VBox 在 Scroll 内部时使用 `anchor = {0, 0, 1, 0}` 水平填满 scroll_root。
- **推荐**：配合 `auto_size = true` 和 Scroll 的 `auto_track` 实现内容自适应滚动。
- **推荐**：使用 `addSpacer()` 而非手动插入 Spacer Widget。
- **不推荐**：将需要动态尺寸的普通 Widget 直接放入 BoxContainer 而不设置 `custom_minimum_size`——可能获得 0 尺寸。
