# Tooltip

鼠标悬停提示组件。在目标 widget 上方悬停指定延迟后显示浮层文本。

**继承链：** `Widget` → `Tooltip`

> Tooltip 是无父节点的独立 UiManager 根 widget（`render_layer = TOOLTIP = 100`），在构造函数中自动注册到 UiManager。

## 构造参数（datas）

```lua
{
    target = Widget,       -- 目标 widget（必填）
    text = string,         -- 提示文本
    delay = number,        -- 悬停延迟秒数，默认 0.5
    max_width = number,    -- 文本最大宽度像素（超出则换行），默认 250
    offset = {x, y},       -- 相对鼠标的偏移像素，默认 {12, 18}
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `setText(text)` | 设置提示文本 |
| `setTarget(target)` | 更换目标 widget |

## 静态方法

| 方法 | 说明 |
|------|------|
| `Tooltip.destroyAll()` | 销毁所有活跃的 Tooltip 实例（测试场景切换用） |

## 工作原理

- `onUpdate` 每帧检测鼠标是否在 target 区域内。
- 区域内：累计悬停计时器，超过 `delay` 后显示。
- 区域外：计时器清零，已显示时隐藏。
- 显示时跟随鼠标移动更新位置（仅在坐标变化时重计算）。
- 屏幕边界约束：面板超出右/下边缘时翻转到鼠标左/上方。

## 示例

```lua
local Tooltip = require "ui.widgets.tooltip"

local btn = Button({ text = "Hover me", w = 120, h = 32 })

local tip = Tooltip({
    target = btn,
    text = "This button does something useful",
    delay = 0.3,
    max_width = 200,
})

-- 动态修改
tip:setText("Updated tip text")
```
