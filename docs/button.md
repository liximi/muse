# Button

文字按钮，支持 6 种状态样式（normal/pressed/hover/selected/selected_hover/disabled）。

**继承链：** `Widget` → `ButtonBase` → `Button`

## 构造参数（datas）

```lua
{
    text = string,                -- 按钮文字
    font_key = string,            -- 字体 key
    on_click = function(),        -- 点击回调
    on_pressed = function(x, y),  -- 按下回调

    -- 状态样式（每项为 Utils.newButtonStateStyle 的返回值）
    normal = style,
    hover = style,
    pressed = style,
    disabled = style,
    selected = style,
    selected_hover = style,
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `setText(t)` | 设置按钮文字（文字不受状态切换影响） |
| `getText()` | 获取按钮文字 |
| `setStateStyle(state, style)` | 设置某个状态的样式。若 style 含 `text` 字段，自动调用 `setText()`（兼容旧用法） |
| `getStateStyle(state)` | 获取合并后的状态样式（自定义样式 > theme 对应状态 > 自定义 normal > theme normal）。**text 字段不参与合并** |
| `getMinimumSize()` | 返回内部文字最小尺寸 + 内边距（2px × 4） |
| `setSelected(selected)` | 设置选中状态（继承自 ButtonBase） |

## 文字与样式分离（2026-07 重构）

按钮的**文字内容**与**视觉样式**是独立的：

- `setText()` 管理文字内容。
- `setStateStyle()` 管理各状态的视觉属性（颜色、字号、背景、描边等）。
- 状态切换时只改变颜色和字号，不改变文字内容。
- `getStateStyle()` 合并时跳过 `text` 字段。

`setStateStyle(state, style)` 中若 `style.text` 存在，会自动调用 `setText(style.text)`——这是为了兼容旧代码中通过样式传文字的用法。

## 状态样式字段

```lua
{
    text = string,              -- 不参与合并，但通过 setStateStyle 传递时会自动调用 setText
    text_color = {r, g, b, a},  -- 文本颜色
    font_size = number,         -- 字号
    bg_color = {r, g, b, a},    -- 背景色
    outline_width = number,     -- 描边宽度
    outline_color = {r, g, b, a}, -- 描边颜色
    offset = {x, y},            -- 位置偏移（按下时常用 {0, 2}）
    scale = {sx, sy},           -- 缩放
    rounding_radius = number,   -- 圆角半径
}
```

## 示例

```lua
local btn = Button({
    text = "Click Me",
    anchor = {0, 0, 1, 0},
    h = 40,
    normal = Utils.newButtonStateStyle(nil, Utils.UI_COLORS.TITLE, nil, Utils.UI_COLORS.BTN_NORMAL, nil, nil, nil, nil, 4),
    hover = Utils.newButtonStateStyle(nil, nil, nil, Utils.UI_COLORS.BTN_HOVER, 1, Utils.UI_COLORS.LINE),
    pressed = Utils.newButtonStateStyle(nil, nil, nil, nil, nil, nil, {0, 2}),
    on_click = function()
        print("clicked!")
    end,
})

-- 动态修改
btn:setText("Updated")
btn:setStateStyle("normal", Utils.newButtonStateStyle(nil, nil, nil, Utils.RGB(80, 120, 180)))
```
