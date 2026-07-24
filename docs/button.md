# Button

文字按钮组件，支持 6 种状态样式（normal / pressed / hover / selected / selected_hover / disabled）。

**继承链：** `Widget` → `ButtonBase` → `Button`

## 构造参数（datas）

```lua
{
    text = string | table,        -- 按钮文字（coloredtext 也支持）。text 独立管理，不是样式的一部分
    font_key = string,            -- 字体 key
    normal = style_table,         -- 默认状态样式（Utils.newButtonStateStyle）
    hover = style_table,          -- 悬停状态样式
    pressed = style_table,        -- 按下状态样式
    disabled = style_table,       -- 禁用状态样式
    selected = style_table,       -- 选中状态样式
    selected_hover = style_table, -- 选中+悬停状态样式

    on_click = function(),        -- 点击回调（继承自 ButtonBase）
    on_pressed = function(x, y),  -- 按下回调（继承自 ButtonBase）
}
```

> **text 与样式分离**：`text` 不再是样式的一部分。状态切换只改颜色、字号等视觉属性，不改变文字。
> `setStateStyle` 中如果包含 `text` 字段，会自动调用 `setText()`（兼容旧用法），但推荐做法是
> 直接在构造参数或 `setText()` 中管理文字。

### 状态样式字段（`Utils.newButtonStateStyle` 返回）

```lua
{
    text = string | table,        -- 按钮文本（支持 coloredtext）
    text_color = {r, g, b, a},    -- 文本颜色
    font_size = number,           -- 字号
    bg_color = {r, g, b, a},      -- 背景色
    outline_width = number,       -- 描边宽度
    outline_color = {r, g, b, a}, -- 描边色
    offset = {x, y},              -- 位置偏移（像素）
    scale = {sx, sy},             -- 缩放
    rounding_radius = number,     -- 圆角半径
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `setText(text)` | 设置按钮文字（不受状态切换影响） |
| `getText()` | 获取按钮文字 |
| `setStateStyle(state, style)` | 设置某个状态的样式，state 为 `"normal"` / `"pressed"` / `"disabled"` / `"selected"` / `"hover"` / `"selected_hover"` |
| `getStateStyle(state)` | 获取某个状态的合并后样式（自动合并自定义样式、normal 样式和主题样式） |
| `getMinimumSize()` | 返回内部文字最小尺寸 + 文本内边距 `(2px × 2)` |

## 从 ButtonBase 继承的方法

| 方法 | 说明 |
|------|------|
| `setState(new_state)` | 切换按钮状态（触发 `onSetState`） |
| `setSelected(selected)` | 设置选中状态（触发 `onSelected` / `onUnselected`） |

## 状态转换

```
NORMAL ⇄ HOVER
  ↓        ↓
PRESSED  SELECTED_HOVER
           ⇅
         SELECTED
```

- 鼠标进入 → `HOVER`（或 `SELECTED_HOVER`）
- 鼠标离开 → `NORMAL`（或 `SELECTED`）
- 按下 → `PRESSED`
- 释放（在范围内）→ `HOVER` 或 `SELECTED_HOVER`
- 释放（在范围外）→ `NORMAL` 或 `SELECTED`
- 禁用 → `DISABLED`
- 启用 → `NORMAL`

## 样式合并优先级

`state_styles[目标状态]` > `state_styles["normal"]` > `theme.button[目标状态]` > `theme.button["normal"]`

## 示例

```lua
local btn = Button({
    w = 120,
    h = 36,
    normal = Utils.newButtonStateStyle("Click Me", Utils.UI_COLORS.TITLE, 16,
                Utils.UI_COLORS.BTN_NORMAL, nil, nil, nil, nil, 4),
    hover = Utils.newButtonStateStyle(nil, nil, nil,
                Utils.UI_COLORS.BTN_HOVER, 1, Utils.UI_COLORS.LINE, {0, -1}),
    pressed = Utils.newButtonStateStyle(nil, nil, nil, nil, nil, nil, {0, 2}),
    on_click = function()
        print("clicked!")
    end,
})
```
