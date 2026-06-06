# 主题系统

主题系统为所有 widget 提供统一的默认样式。每个 widget 类型在主题中有自己的配置区块，可以通过继承默认 Theme 类来创建自定义主题。

## 优先级

样式值的优先级（从高到低）：

1. **datas 参数** — widget 构造时直接传入的字段，最高优先级
2. **自定义 theme** — widget 构造时传入的 `theme` 参数
3. **默认 theme** — UiManager 持有的默认主题实例

## 默认主题

默认主题定义在 `ui/theme.lua`，包含以下区块：

```lua
local Theme = Class(function(self)
    self.panel = { ... }        -- Panel 默认样式
    self.text = { ... }         -- Text 默认样式
    self.textinput = { ... }    -- TextInput 默认样式
    self.image = { ... }        -- Image 默认样式
    self.button = { ... }       -- Button 默认样式
    self.sliderbar = { ... }    -- SliderBar 默认样式
    self.progressbar = { ... }  -- ProgressBar 默认样式
    self.checkbox = { ... }     -- Checkbox 默认样式
    self.radiobutton = { ... }  -- RadioButton 默认样式
    self.modal = { ... }        -- Modal 默认样式
    self.tabview = { ... }      -- TabView 默认样式
    self.imagebutton = { ... }  -- ImageButton 默认样式
end)
```

## 各区块的默认字段

### panel

| 字段 | 默认值 | 说明 |
|------|--------|------|
| `bg_color` | `UI_COLORS.SURFACE` | 背景色 `{r, g, b, a}` |
| `outline_color` | `UI_COLORS.LINE` | 描边色 |
| `rounding_radius` | `4` | 圆角半径（像素） |
| `outline_width` | `1` | 描边宽度（像素） |

### text

| 字段 | 默认值 | 说明 |
|------|--------|------|
| `font_key` | `"default"` | 字体注册 key |
| `font_size` | `16` | 字号 |
| `text_color` | `UI_COLORS.PRIMARY_TEXT` | 文本颜色 |

### textinput

| 字段 | 默认值 | 说明 |
|------|--------|------|
| `font_key` | `"default"` | 字体 key |
| `font_size` | `16` | 字号 |
| `text_color` | `UI_COLORS.PRIMARY_TEXT` | 文本颜色 |
| `text_padding` | `{8, 8, 8, 8}` | 文本内边距 |
| `hint_color` | `UI_COLORS.SECONDARY_TEXT` | 占位提示颜色 |

### image

| 字段 | 默认值 | 说明 |
|------|--------|------|
| `tint` | `{1, 1, 1, 1}` | 着色 `{r, g, b, a}` |

### button & imagebutton

按钮主题通过 `Utils.newButtonStateStyle()` / `Utils.newImageButtonStateStyle()` 定义 6 种状态样式：

| 状态 | 说明 |
|------|------|
| `normal` | 默认 |
| `pressed` | 按下 |
| `hover` | 悬停 |
| `selected` | 选中 |
| `selected_hover` | 选中+悬停 |
| `disabled` | 禁用 |

Button 状态样式字段：`text`, `text_color`, `font_size`, `bg_color`, `outline_width`, `outline_color`, `offset`, `scale`, `rounding_radius`

ImageButton 状态样式字段：`texture`, `tint`, `text`, `text_color`, `font_size`, `offset`, `scale`

### sliderbar

| 字段 | 默认值 | 说明 |
|------|--------|------|
| `track_color` | `UI_COLORS.BG` | 轨道背景色 |
| `block_color` | `UI_COLORS.BTN_NORMAL` | 滑块颜色 |
| `block_hover_color` | `UI_COLORS.BTN_HOVER` | 滑块悬停色 |
| `outline_color` | `UI_COLORS.LINE` | 描边色 |
| `block_length_percent` | `0.1` | 滑块长度占轨道比例 |
| `sensitivity` | `0.8` | 点击轨道时的步进灵敏度 |

### progressbar

| 字段 | 默认值 | 说明 |
|------|--------|------|
| `bg_color` | `UI_COLORS.BG` | 背景色 |
| `fill_color` | `UI_COLORS.ACCENT` | 填充色 |
| `rounding_radius` | `4` | 圆角半径 |

### checkbox

| 字段 | 默认值 | 说明 |
|------|--------|------|
| `box_color` | `UI_COLORS.BTN_NORMAL` | 方框颜色 |
| `check_color` | `UI_COLORS.ACCENT` | 对勾颜色 |
| `box_size` | `20` | 方框尺寸 |
| `outline_width` | `1` | 描边宽度 |
| `outline_color` | `UI_COLORS.LINE` | 描边色 |
| `rounding_radius` | `3` | 圆角 |
| `label_color` | `UI_COLORS.PRIMARY_TEXT` | 标签颜色 |
| `knob_color` | `UI_COLORS.TITLE` | 滑动开关滑块颜色 |

### radiobutton

| 字段 | 默认值 | 说明 |
|------|--------|------|
| `circle_color` | `UI_COLORS.BTN_NORMAL` | 圆形颜色 |
| `dot_color` | `UI_COLORS.ACCENT` | 选中圆点颜色 |
| `circle_size` | `20` | 圆形尺寸 |
| `outline_width` | `1` | 描边宽度 |
| `outline_color` | `UI_COLORS.LINE` | 描边色 |
| `label_color` | `UI_COLORS.PRIMARY_TEXT` | 标签颜色 |

### modal

| 字段 | 默认值 | 说明 |
|------|--------|------|
| `overlay_color` | `{0, 0, 0, 0.5}` | 遮罩颜色 |

### tabview

| 字段 | 默认值 | 说明 |
|------|--------|------|
| `tab_height` | `36` | Tab 栏高度 |
| `tab_bg_normal` | `UI_COLORS.BTN_NORMAL` | 未选中 Tab 背景 |
| `tab_bg_selected` | `UI_COLORS.SURFACE` | 选中 Tab 背景 |
| `tab_text_normal` | `UI_COLORS.SECONDARY_TEXT` | 未选中文字颜色 |
| `tab_text_selected` | `UI_COLORS.TITLE` | 选中文字颜色 |
| `tab_font_size` | `14` | Tab 字号 |
| `tab_outline_color` | `UI_COLORS.LINE` | Tab 描边色 |
| `content_bg` | `UI_COLORS.SURFACE` | 内容区背景 |
| `content_rounding_radius` | `4` | 内容区圆角 |

## 创建自定义主题

```lua
local Theme = require "ui.theme"
local Utils = require "ui.utils"

local MyTheme = Theme:extend()
function MyTheme:new()
    Theme.new(self)  -- 继承默认值
    -- 覆盖需要的字段
    self.panel.bg_color = Utils.RGB(30, 30, 40)
    self.button.normal.text_color = Utils.RGB(255, 200, 100)
end

-- 方式一：设为全局默认主题
local UiManager = require "ui.ui_manager":GetInstance()
UiManager:setDefaultTheme(MyTheme())

-- 方式二：传递给单个 widget
local btn = Button({text = "Hello"}, MyTheme())
```

## 颜色工具

`ui/utils.lua` 提供颜色相关工具：

```lua
-- RGB(0-255) → {0-1, 0-1, 0-1, a}
Utils.RGB(r, g, b, a)  -- a 可选，默认 1

-- 预设 UI 颜色
Utils.UI_COLORS = {
    WHITE, BG, SURFACE, LINE,
    TITLE, PRIMARY_TEXT, SECONDARY_TEXT, HINT,
    BTN_NORMAL, BTN_HOVER, BTN_DISABLED,
    BTN_SELECTED, BTN_SELECTED_HOVER,
    ACCENT, ACCENT_LIGHT, WARNING
}
```
