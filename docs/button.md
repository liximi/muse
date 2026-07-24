# Button

标准按钮控件。支持六种视觉状态（normal/hover/pressed/disabled/selected/selected_hover），每种状态可独立配置背景色、文字颜色、字号、边框等样式。

**继承链：** `Widget` → `ButtonBase` → `Button`

## 构造参数（datas）

```lua
{
    text = string | table,    -- 按钮文字（也支持 coloredtext）
    font_key = string,        -- 字体键
    on_click = function,      -- 点击回调
    on_pressed = function,    -- 按下回调

    -- 各状态样式（见 Utils.newButtonStateStyle）
    normal = Utils.newButtonStateStyle,
    hover = Utils.newButtonStateStyle,
    pressed = Utils.newButtonStateStyle,
    disabled = Utils.newButtonStateStyle,
    selected = Utils.newButtonStateStyle,
    selected_hover = Utils.newButtonStateStyle,
}
```

## 工作原理

### 状态机

Button 继承自 `ButtonBase`，维护六种状态。鼠标移入/移出、按下/释放时自动切换状态。`setSelected(true/false)` 用于编程式切换选中态（Checkbox、Tab 按钮等场景）。

### 文字与样式分离

按钮文字通过 `setText()` / 构造参数 `text` 独立管理。状态切换只改变颜色和字号，不改变文字内容。与旧版不同，`getStateStyle` 合并样式时跳过 `text` 字段。

> `setStateStyle(state, style)` 若 `style.text` 存在，仍会自动调用 `setText(style.text)`——这是兼容旧用法的行为，不推荐新代码依赖。

### 最小尺寸

`getMinimumSize()` 返回内部 Text 的最小尺寸 + 2px 内边距。

## 公有方法

| 方法 | 说明 |
|------|------|
| `setText(text)` | 设置按钮文字 |
| `getText()` | 获取按钮文字 |
| `setStateStyle(state, style)` | 设置某状态的样式 |
| `getStateStyle(state)` | 获取合并后的状态样式（自定义样式 + 主题样式） |
| `setSelected(selected)` | 设置选中状态 |
| `setState(new_state)` | 直接切换状态（继承自 ButtonBase） |

## 示例

```lua
local Utils = require "ui.utils"

-- 基础按钮
local btn = Button({
    text = "Click Me",
    normal = Utils.newButtonStateStyle("Click Me", nil, 14,
        Utils.UI_COLORS.BTN_NORMAL, 1, Utils.UI_COLORS.LINE),
    hover = Utils.newButtonStateStyle(nil, nil, 14,
        Utils.UI_COLORS.BTN_HOVER, 1, Utils.UI_COLORS.ACCENT_LIGHT),
    on_click = function()
        print("clicked!")
    end,
})

-- 带选中状态的切换按钮
local toggle_btn = Button({
    text = "Toggle",
    normal = Utils.newButtonStateStyle("Toggle", nil, 14,
        Utils.UI_COLORS.BTN_NORMAL),
    selected = Utils.newButtonStateStyle(nil, {1, 1, 1, 1}, 14,
        Utils.UI_COLORS.ACCENT),
    on_click = function(self)
        -- 通过 ButtonBase.setSelected 切换状态需额外处理
    end,
})
```

## 最佳实践

- **推荐**：通过构造参数 `text` 或 `setText()` 设置按钮文字，而不是依赖 `setStateStyle` 的 side effect。
- **推荐**：使用 `Utils.newButtonStateStyle(...)` 构造样式表，参数按位置传入。
- **不推荐**：在 `on_click` 回调中长时间阻塞——事件处理应快速返回。
- **不推荐**：在按钮文字中使用未注册的字体 key——会导致运行时错误。
