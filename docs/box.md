# BoxContainer

线性排列子控件的容器（对标 Godot `HBoxContainer` / `VBoxContainer`）。子控件沿主轴依次排列，通过 SizeFlags 表达布局意图。

**继承链：** `Widget` → `Container` → `BoxContainer`

## 构造参数（datas）

```lua
{
    orientation = "horizontal" | "vertical",  -- 排列方向，默认 "vertical"
    separation = number,    -- 子控件间距（像素），默认 0
    alignment = "begin" | "center" | "end",   -- 无 EXPAND 子控件时的整体偏移，默认 "begin"
    auto_size = boolean,    -- 主轴自动尺寸，默认 false（继承自 Container）
    -- ... 也继承所有 Widget / Container 基类参数
}
```

## 子控件属性

在每个子 widget 上设置以下字段控制布局行为：

| 字段 | 默认值 | 说明 |
|------|--------|------|
| `h_size_flags` | `FILL` (1) | 水平布局标志（`EXPAND`=2 参与瓜分剩余空间） |
| `v_size_flags` | `FILL` (1) | 垂直布局标志 |
| `stretch_ratio` | `1.0` | 当开启 EXPAND 时，瓜分剩余空间的权重比例 |

## 公有方法

| 方法 | 说明 |
|------|------|
| `addSpacer()` | 添加弹性占位符（`Spacer`），后续子控件被推到主轴末端 |
| `getMinimumSize()` | 子控件最小尺寸沿主轴累加 + 间距，交叉轴取最大（与容器自身尺寸取 max） |
| `_getChildrenMinSize()` | 纯子控件推导的最小尺寸（不含容器自身 cap），供变化检测 |

## 布局算法（三趟式）

```
第一趟：收集每个孩子的 min_size / desired_size / EXPAND 标记
第二趟 A：按 desired_size 比例分配（"我需要这么多"）
    - EXPAND 孩子 → 同步提高 min，防止被后续 stretch 缩回去
    - 非 EXPAND 孩子 → 从 stretch 池中扣除其 desired 增量
第二趟 B：按 stretch_ratio 比例分配剩余空间（"我贪婪"）
    - 装不下的从池中移除 → 重新分配
    - 最后一个 EXPAND 孩子吸收浮点舍入误差
第三趟：fitChildInRect 逐个定位 + alignment 偏移
```

## 快捷构造

```lua
local BoxV = require "ui.widgets.containers.box_v_container"
local BoxH = require "ui.widgets.containers.box_h_container"
```

## 示例

```lua
-- 垂直排列，子控件填满宽度
local vbox = BoxContainer({
    orientation = "vertical",
    separation = 4,
    anchor = {0, 0, 1, 1},
})

-- 固定高度的按钮
vbox:addChild(Button({ text = "Header", h = 40 }))

-- 弹性填充中间区域
local content = Panel({ bg_color = Utils.RGB(40, 40, 50) })
content.v_size_flags = Utils.SIZE_FLAGS.FILL + Utils.SIZE_FLAGS.EXPAND
content.stretch_ratio = 1.0
content:setCustomMinimumSize(nil, 100)
vbox:addChild(content)

-- Spacer 推到底部
vbox:addSpacer()

-- 固定高度的按钮
vbox:addChild(Button({ text = "Footer", h = 30 }))
```

```lua
-- 水平排列 + 居中
local hbox = BoxContainer({
    orientation = "horizontal",
    separation = 8,
    alignment = "center",
    anchor = {0, 0, 1, 0},
    h = 48,
})
hbox:addChild(Button({ text = "Cancel", w = 80 }))
hbox:addChild(Button({ text = "OK", w = 80 }))
```

> **注意**：普通 Widget（如 Panel）放在容器里但只设了 `h = 40`，容器会给 0 高度——因为 Widget 基类的
> `getMinimumSize()` 返回 `(0, 0)`。需调用 `setCustomMinimumSize(nil, 40)` 或覆写 `getMinimumSize`。
> Button、Text 等已内置覆写，不需要额外处理。
