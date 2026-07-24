# Utils — 常量、枚举 & 工具函数

Muse 核心工具模块（`ui/utils.lua`），提供所有枚举常量、颜色工具和辅助函数。`Components` 模块（`ui/components.lua`）提供控件混入和样式应用。

---

## 目录

- [枚举常量](#枚举常量)
- [颜色](#颜色)
- [工具函数](#工具函数)
- [Components](#components)

---

## 枚举常量

### RENDER_LAYERS — 渲染层级

```lua
Utils.RENDER_LAYERS = {
    BASE     = 0,   -- 默认层
    OVERLAY  = 50,  -- 覆盖层
    DROPDOWN = 80,  -- 下拉弹窗
    TOOLTIP  = 100, -- 提示框（最顶层）
}
```

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
| `SHRINK_CENTER` | 4 | 在分配区域内居中（需关闭 FILL） |
| `SHRINK_END` | 8 | 在分配区域内靠右/下（需关闭 FILL） |

可叠加使用：`Utils.SIZE_FLAGS.FILL + Utils.SIZE_FLAGS.EXPAND` = `3`。

```lua
child.h_size_flags = Utils.SIZE_FLAGS.FILL + Utils.SIZE_FLAGS.EXPAND
child.stretch_ratio = 2.0
```

### ALIGNMENT — 容器整体对齐

```lua
Utils.ALIGNMENT = {
    BEGIN  = "begin",
    CENTER = "center",
    END    = "end",
}
```

仅当容器内无 EXPAND 子控件时生效。用于 BoxContainer 的 `alignment` 参数。

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

### H_ALIGN — 水平对齐

```lua
Utils.H_ALIGN = {
    LEFT    = "left",
    CENTER  = "center",
    RIGHT   = "right",
    JUSTIFY = "justify",
}
```

### V_ALIGN — 垂直对齐

```lua
Utils.V_ALIGN = {
    TOP    = "top",
    CENTER = "center",
    BOTTOM = "bottom",
}
```

### TEXT_WRAP_MODE — 文本换行

```lua
Utils.TEXT_WRAP_MODE = {
    OFF     = "off",
    DEFAULT = "default",
}
```

### TEXT_OVERFLOW_MODE — 文本溢出

```lua
Utils.TEXT_OVERFLOW_MODE = {
    NONE = "none",  -- 不修剪
    CHAR = "char",  -- 逐字符修剪，末尾加省略号
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
Utils.UI_COLORS.BG               -- 背景色（深色）
Utils.UI_COLORS.SURFACE          -- 面板/卡片底色
Utils.UI_COLORS.LINE             -- 描边/分隔线色

Utils.UI_COLORS.TITLE            -- 标题文本色
Utils.UI_COLORS.PRIMARY_TEXT     -- 正文文本色
Utils.UI_COLORS.SECONDARY_TEXT   -- 辅助文本色
Utils.UI_COLORS.HINT             -- 占位提示色

Utils.UI_COLORS.BTN_NORMAL       -- 按钮默认底色
Utils.UI_COLORS.BTN_HOVER        -- 按钮悬停底色
Utils.UI_COLORS.BTN_DISABLED     -- 按钮禁用底色
Utils.UI_COLORS.BTN_SELECTED     -- 按钮选中底色
Utils.UI_COLORS.BTN_SELECTED_HOVER  -- 按钮选中+悬停底色

Utils.UI_COLORS.ACCENT           -- 强调色（蓝）
Utils.UI_COLORS.ACCENT_LIGHT     -- 浅强调色
Utils.UI_COLORS.WARNING          -- 警告色（黄）

-- 兼容旧名称
Utils.UI_COLORS.PINK / LIGHT_PINK / BLUE / LIGHT_BLUE / YELLOW
```

### Utils.RGB(r, g, b, a)

0~255 范围颜色转 0~1 的 `{r, g, b, a}`。

```lua
Utils.RGB(255, 128, 64)        -- → {1, 0.502, 0.251, 1}
Utils.RGB(100, 200, 50, 0.8)   -- → {0.392, 0.784, 0.196, 0.8}
```

---

## 工具函数

### Utils.clamp(val, min, max)

```lua
Utils.clamp(5, 0, 10)   -- → 5
Utils.clamp(15, 0, 10)  -- → 10
```

### Utils.validateEnum(value, enum, default, label)

校验枚举值。`nil` 时静默返回 default，非法时打印警告并回退。

```lua
local orientation = Utils.validateEnum(
    datas.orientation,
    Utils.ORIENTATION,
    Utils.ORIENTATION.VERTICAL,
    "BoxContainer.orientation"
)
```

### Utils.hasFlag(flags, flag)

LuaJIT 兼容的位检测（不用 `bit` 库）。

```lua
local flags = Utils.SIZE_FLAGS.FILL + Utils.SIZE_FLAGS.EXPAND  -- = 3
Utils.hasFlag(flags, Utils.SIZE_FLAGS.FILL)     -- → true
Utils.hasFlag(flags, Utils.SIZE_FLAGS.EXPAND)   -- → true
Utils.hasFlag(flags, Utils.SIZE_FLAGS.SHRINK_END) -- → false
```

### Utils.newButtonStateStyle(...)

为 Button 创建单个状态样式表。所有参数可选。

```lua
Utils.newButtonStateStyle(text, text_color, font_size, bg_color,
    outline_width, outline_color, offset, scale, rounding_radius)
```

### Utils.newImageButtonStateStyle(...)

为 ImageButton 创建单个状态样式表。所有参数可选。

```lua
Utils.newImageButtonStateStyle(texture, tint, text, text_color,
    font_size, offset, scale)
```

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
Components.addHoverState(widget)
function widget:onHovered(hovered, x, y, dx, dy)
    if hovered then print("鼠标进入") end
end
```

### Components.applyButtonTextStyle(button, new_style)

应用按钮状态切换时的文本样式变更（颜色 + 字号）。Button/ImageButton 内部自动调用。

### Components.applyButtonTransform(button, old_style, new_style)

应用按钮状态切换时的位置偏移和缩放变更。Button/ImageButton 内部自动调用。
