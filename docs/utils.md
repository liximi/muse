# Utils — 常量、枚举 & 工具函数

Muse 核心工具模块（`ui/utils.lua`），提供所有枚举常量、颜色工具和辅助函数。`Components` 模块（`ui/components.lua`）提供控件混入和状态应用。

---

## 目录

- [枚举常量](#枚举常量)
- [颜色](#颜色)
- [工具函数](#工具函数)
- [Components](#components)

---

## 枚举常量

所有常量挂在 `Utils` 表下。

### RENDER_LAYERS — 渲染层级

```lua
Utils.RENDER_LAYERS = {
    BASE     = 0,   -- 默认层
    OVERLAY  = 50,  -- 覆盖层
    DROPDOWN = 80,  -- 下拉弹窗
    TOOLTIP  = 100, -- 提示框（最顶层）
}
```

设置 `widget.render_layer = Utils.RENDER_LAYERS.TOOLTIP` 即可改变渲染顺序。数字越大越晚绘制（越靠前）。

### ORIENTATION — 方向

```lua
Utils.ORIENTATION = {
    VERTICAL   = "vertical",
    HORIZONTAL = "horizontal",
}
```

用于 BoxContainer、ProgressBar、SliderBar。

### SIZE_FLAGS — 容器子控件布局标志

| 标志 | 值 | 含义 |
|------|-----|------|
| `SHRINK_BEGIN` | 0 | 保持最小尺寸，靠左/上（默认值） |
| `FILL` | 1 | 填满分到的区域 |
| `EXPAND` | 2 | 参与剩余空间瓜分 |
| `SHRINK_CENTER` | 4 | 分到区域内居中（需关闭 FILL） |
| `SHRINK_END` | 8 | 分到区域内靠右/下（需关闭 FILL） |

可叠加使用：`Utils.SIZE_FLAGS.FILL + Utils.SIZE_FLAGS.EXPAND` = `3`。

```lua
child.h_size_flags = Utils.SIZE_FLAGS.FILL + Utils.SIZE_FLAGS.EXPAND
```

### ALIGNMENT — 容器整体对齐

```lua
Utils.ALIGNMENT = {
    BEGIN  = "begin",   -- 靠左/上
    CENTER = "center",  -- 居中
    END    = "end",     -- 靠右/下
}
```

仅当容器内无 EXPAND 子控件时生效。

### BTN_STATES — 按钮状态

```lua
Utils.BTN_STATES = {
    NORMAL        = "normal",
    PRESSED       = "pressed",
    DISABLED      = "disabled",
    SELECTED      = "selected",
    HOVER         = "hover",
    SELECTED_HOVER = "selected_hover",
}
```

用于 `Button:setStateStyle(state, style)` 的 `state` 参数。

### H_ALIGN — 水平对齐

```lua
Utils.H_ALIGN = {
    LEFT    = "left",
    CENTER  = "center",
    RIGHT   = "right",
    JUSTIFY = "justify",
}
```

Text、TextInput 的 `h_align` 参数。

### V_ALIGN — 垂直对齐

```lua
Utils.V_ALIGN = {
    TOP    = "top",
    CENTER = "center",
    BOTTOM = "bottom",
}
```

Text、TextInput 的 `v_align` 参数。

### TEXT_WRAP_MODE — 文本换行模式

```lua
Utils.TEXT_WRAP_MODE = {
    OFF     = "off",      -- 不换行
    DEFAULT = "default",  -- 以 transform.w 为宽度换行
}
```

```lua
text:setWrapMode(Utils.TEXT_WRAP_MODE.OFF)
```

### TEXT_OVERFLOW_MODE — 文本溢出模式

```lua
Utils.TEXT_OVERFLOW_MODE = {
    NONE = "none",  -- 不修剪
    CHAR = "char",  -- 逐字符修剪
}
```

### CHECKBOX_STYLE — 复选框样式

```lua
Utils.CHECKBOX_STYLE = {
    CHECKBOX = "checkbox",  -- 方框 + 对勾
    TOGGLE   = "toggle",    -- 滑动开关
}
```

### CROSS_ALIGN — 交叉轴对齐（旧 Box，逐步废弃）

```lua
Utils.CROSS_ALIGN = {
    STRETCH = "stretch",
    START   = "start",
    CENTER  = "center",
    END     = "end",
}
```

### ANCHORS_HORI / ANCHORS_VERT — 文本锚点（内部用）

```lua
Utils.ANCHORS_HORI = { LEFT = "left", MIDDLE = "middle", RIGHT = "right" }
Utils.ANCHORS_VERT = { TOP = "top", MIDDLE = "middle", BOTTOM = "bottom" }
```

### TWO_PI

```lua
Utils.TWO_PI = math.pi * 2  -- 用于旋转角归一化比较
```

---

## 颜色

### UI_COLORS — 预设调色板

```lua
Utils.UI_COLORS.WHITE            -- {1, 1, 1, 1}
Utils.UI_COLORS.BG               -- 背景色（深色） {26/255, ...}
Utils.UI_COLORS.SURFACE          -- 面板/卡片底色
Utils.UI_COLORS.LINE             -- 描边/分隔线色

Utils.UI_COLORS.TITLE            -- 标题文本色（最亮）
Utils.UI_COLORS.PRIMARY_TEXT     -- 正文文本色
Utils.UI_COLORS.SECONDARY_TEXT   -- 辅助文本色
Utils.UI_COLORS.HINT             -- 占位提示色

Utils.UI_COLORS.BTN_NORMAL       -- 按钮默认底色
Utils.UI_COLORS.BTN_HOVER        -- 按钮悬停底色
Utils.UI_COLORS.BTN_DISABLED     -- 按钮禁用底色
Utils.UI_COLORS.BTN_SELECTED     -- 按钮选中底色（半透明蓝）
Utils.UI_COLORS.BTN_SELECTED_HOVER  -- 按钮选中+悬停底色

Utils.UI_COLORS.ACCENT           -- 强调色（蓝）
Utils.UI_COLORS.ACCENT_LIGHT     -- 浅强调色
Utils.UI_COLORS.WARNING          -- 警告色（黄）

-- 兼容旧名称（指向同色）
Utils.UI_COLORS.PINK             -- → ACCENT
Utils.UI_COLORS.LIGHT_PINK       -- → ACCENT_LIGHT
Utils.UI_COLORS.BLUE             -- → ACCENT
Utils.UI_COLORS.LIGHT_BLUE       -- → ACCENT_LIGHT
Utils.UI_COLORS.YELLOW           -- → WARNING
```

实际灰度值参考（0~255）：

| 名称 | R | G | B | 用途 |
|------|---|---|---|-----|
| light | 240 | 240 | 240 | 标题 |
| light_gray1 | 200 | 200 | 200 | 正文 |
| light_gray2 | 155 | 155 | 155 | 提示 |
| light_gray3 | 100 | 100 | 100 | 辅助文字 |
| dark_gray1 | 70 | 70 | 70 | 分隔线/悬停 |
| dark_gray2 | 50 | 50 | 50 | 面板表面 |
| dark_gray3 | 38 | 38 | 38 | 按钮默认 |
| dark | 26 | 26 | 26 | 背景 |

### Utils.RGB(r, g, b, a)

0~255 范围颜色转 0~1 范围 `{r, g, b, a}`。

```lua
Utils.RGB(255, 128, 64)        -- → {1, 0.502, 0.251, 1}
Utils.RGB(100, 200, 50, 0.8)   -- → {0.392, 0.784, 0.196, 0.8}
```

---

## 工具函数

### Utils.clamp(val, min, max)

将值钳制到 `[min, max]` 范围内。

```lua
Utils.clamp(5, 0, 10)   -- → 5
Utils.clamp(15, 0, 10)  -- → 10
Utils.clamp(-3, 0, 10)  -- → 0
```

### Utils.validateEnum(value, enum, default, label)

校验枚举值。`nil` 时静默返回 default，非法时打印警告并回退。

```lua
local orientation = Utils.validateEnum(
    datas.orientation,           -- 用户传入的值
    Utils.ORIENTATION,           -- 合法值集合
    Utils.ORIENTATION.VERTICAL,  -- 默认值
    "BoxContainer.orientation"   -- 标签（用于错误信息）
)
```

### Utils.hasFlag(flags, flag)

位检测，LuaJIT 兼容（不用 `bit` 库）。检查 `flags` 中是否包含 `flag` 位。

```lua
local flags = Utils.SIZE_FLAGS.FILL + Utils.SIZE_FLAGS.EXPAND  -- = 3
Utils.hasFlag(flags, Utils.SIZE_FLAGS.FILL)    -- → true
Utils.hasFlag(flags, Utils.SIZE_FLAGS.EXPAND)  -- → true
Utils.hasFlag(flags, Utils.SIZE_FLAGS.SHRINK_END) -- → false
```

### Utils.newButtonStateStyle(text, text_color, font_size, bg_color, outline_width, outline_color, offset, scale, rounding_radius)

为 Button 创建单个状态的样式表。所有参数可选（nil 表示不覆盖）。

```lua
local normal = Utils.newButtonStateStyle(
    "Click Me",                  -- text
    Utils.UI_COLORS.TITLE,       -- text_color
    16,                          -- font_size
    Utils.UI_COLORS.BTN_NORMAL,  -- bg_color
    nil,                         -- outline_width
    nil,                         -- outline_color
    nil,                         -- offset {x, y}
    nil,                         -- scale {sx, sy}
    4                            -- rounding_radius
)
```

返回值字段：`text`, `text_color`, `font_size`, `bg_color`, `outline_width`, `outline_color`, `offset`, `scale`, `rounding_radius`。

### Utils.newImageButtonStateStyle(texture, tint, text, text_color, font_size, offset, scale)

为 ImageButton 创建单个状态的样式表。所有参数可选。

```lua
local normal = Utils.newImageButtonStateStyle(
    icon,                        -- texture
    {1, 1, 1, 1},               -- tint
    "Save",                      -- text
    Utils.UI_COLORS.TITLE,       -- text_color
    14,                          -- font_size
    nil,                         -- offset
    nil                          -- scale
)
```

返回值字段：`texture`, `tint`, `text`, `text_color`, `font_size`, `offset`, `scale`。

---

## Components

`ui/components.lua` — 可复用的控件混入和样式应用。

### Components.addHoverState(widget)

为任意 Widget 混入 hover 检测能力。调用后：

- widget 新增 `hovered` 属性（boolean）
- widget 获得 `onHovered(hovered, x, y, dx, dy)` 回调
- 内部覆写 `onMouseMoved`，先调原 handler 再做 hover 检测

```lua
local Components = require "ui.components"

local box = Widget({...})
Components.addHoverState(box)
function box:onHovered(hovered, x, y, dx, dy)
    if hovered then
        print("鼠标进入")
    else
        print("鼠标离开")
    end
end
```

> **注意**：ProgressBar 在 `interactive = true` 时自动调用此混入，无需手动处理。

### Components.applyButtonTextStyle(button, new_style)

应用按钮状态切换时的文本样式变更（颜色 + 字号）。Button 内部自动调用，通常不需要手动使用。

### Components.applyButtonTransform(button, old_style, new_style)

应用按钮状态切换时的位置偏移和缩放变更。Button 内部自动调用。

---

## 常用引入

```lua
local Utils = require "ui.utils"
local Components = require "ui.components"
```
