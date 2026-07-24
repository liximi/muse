# Checkbox

复选框组件，支持方框+对勾（checkbox）和滑动开关（toggle）两种样式。

**继承链：** `Widget` → `ButtonBase` → `Checkbox`

## 构造参数（datas）

```lua
{
    checked = boolean,            -- 初始选中状态，默认 false
    style = "checkbox" | "toggle", -- 样式，默认 "checkbox"
    box_size = number,            -- 复选框尺寸，默认来自 theme（20）
    box_color = {r, g, b, a},     -- 方框颜色
    check_color = {r, g, b, a},   -- 对勾/轨道激活颜色
    outline_width = number,       -- 描边宽度，默认 1
    outline_color = {r, g, b, a}, -- 描边颜色
    rounding_radius = number,     -- 圆角，默认 3
    on_checked = function(checked), -- 选中状态改变时的回调
    label = string | table,       -- 可选标签文本（支持 coloredtext）
    label_color = {r, g, b, a},   -- 标签颜色
    label_font_size = number,     -- 标签字号
    on_click = function(),        -- 点击回调（继承自 ButtonBase）
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `isChecked()` | 是否处于选中状态（逻辑状态，不依赖视觉 cur_state） |
| `setChecked(checked)` | 编程式设置选中状态（触发 `onChecked` 回调） |
| `toggle()` | 切换选中状态 |
| `getMinimumSize()` | 返回自身 transform 尺寸 |
| `setSelected(selected)` | 覆写 ButtonBase，同步 `_checked` 并触发 `onChecked` |

## 区域检测

Checkbox 覆写了 `regionDetection`，将点击有效范围限定在视觉区域（box + label），而非整个 widget 宽度。toggle 样式的轨道宽度为 `box_size × 1.8`。

## 两种样式

### checkbox（默认）

- 方框 + 选中时绘制对勾（折线）
- 方框圆角可配置
- 描边和填充色独立

### toggle

- 胶囊形轨道 + 圆形滑块
- 选中时轨道变为 `check_color`，滑块滑到右侧
- 滑块颜色取自 `theme.checkbox.knob_color`

## 示例

```lua
-- 方框样式
local cb = Checkbox({
    label = "Enable feature",
    checked = true,
    on_checked = function(checked)
        print("feature enabled:", checked)
    end,
})

-- 滑动开关样式
local toggle = Checkbox({
    style = "toggle",
    label = "Dark mode",
    checked = false,
    on_checked = function(checked)
        setDarkMode(checked)
    end,
})
```
