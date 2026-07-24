# Tooltip

鼠标悬停提示。在目标控件上悬停指定延迟后显示，跟随鼠标移动。

**继承链：** `Widget` → `Tooltip`

## 构造参数（datas）

```lua
{
    target = Widget,      -- 目标控件（必填）
    text = string,        -- 提示文本
    delay = number,       -- 悬停延迟（秒），默认 0.5
    max_width = number,   -- 文本最大宽度（像素），默认 250
    offset = {x, y},      -- 相对鼠标的偏移（像素），默认 {12, 18}
}
```

## 工作原理

Tooltip 构造时自动注册到 UiManager（无需手动 addWidget），使用 `TOOLTIP` 渲染层（100）确保在最顶层绘制。每帧检查鼠标是否在 target 区域内——悬停超过 `delay` 秒后显示，鼠标移出后隐藏。

面板位置跟随鼠标并自动避开屏幕边缘。文本在 `max_width` 内自动换行。

## 公有方法

| 方法 | 说明 |
|------|------|
| `setText(text)` | 设置提示文本 |
| `setTarget(target)` | 设置目标控件 |
| `Tooltip.destroyAll()` | 销毁所有活跃的 Tooltip（测试场景切换用） |

## 示例

```lua
local btn = Button({ text = "Hover Me" })
local tip = Tooltip({
    target = btn,
    text = "Click to perform this action.",
    delay = 0.3,
})
```
