# Tooltip

鼠标悬停提示组件，在目标 widget 上悬停指定时延后显示。

**继承链：** `Widget` → `Tooltip`

## 构造参数（datas）

```lua
{
    target = Widget,              -- 目标 widget（必填）
    text = string,                -- 提示文本
    delay = number,               -- 悬停延迟（秒），默认 0.5
    max_width = number,           -- 文本最大宽度（像素），默认 250
    offset = {x, y},              -- 相对鼠标的偏移（像素），默认 {12, 18}
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `setText(text)` | 设置提示文本 |
| `setTarget(target)` | 更换目标 widget |
| `destroy()` | 销毁 tooltip 并从 UiManager 移除 |

## 静态方法

| 方法 | 说明 |
|------|------|
| `Tooltip.destroyAll()` | 销毁所有活跃的 Tooltip（测试场景切换时使用） |

## 行为

- 渲染在最顶层（`render_layer = TOOLTIP = 100`）
- 直接注册到 UiManager 作为根 widget（避免父容器偏移干扰）
- 自动避开屏幕边缘（右/下方空间不足时翻转到左/上方）
- 目标 widget 不可操作时自动隐藏

## 示例

```lua
local btn = Button({text = "Hover me", w = 100, h = 30})
local tip = Tooltip({
    target = btn,
    text = "This is a tooltip message",
    delay = 0.3,
    offset = {10, 20},
})
```
