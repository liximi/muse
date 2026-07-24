# Utils

工具函数和枚举常量模块。

## 枚举常量

### SIZE_FLAGS

子控件在容器中的尺寸行为标志，可位组合：

| 标志 | 值 | 含义 |
|------|-----|------|
| `SHRINK_BEGIN` | 0 | 保持最小尺寸，靠左/上 |
| `FILL` | 1 | 填满容器分配的区域 |
| `EXPAND` | 2 | 参与剩余空间的瓜分 |
| `SHRINK_CENTER` | 4 | 在区域内居中（需关闭 FILL） |
| `SHRINK_END` | 8 | 在区域内靠右/下（需关闭 FILL） |

### ORIENTATION

```lua
Utils.ORIENTATION.VERTICAL    -- "vertical"
Utils.ORIENTATION.HORIZONTAL  -- "horizontal"
```

### ALIGNMENT

BoxContainer 无 EXPAND 子控件时的整体偏移：

```lua
Utils.ALIGNMENT.BEGIN   -- "begin"
Utils.ALIGNMENT.CENTER  -- "center"
Utils.ALIGNMENT.END     -- "end"
```

### H_ALIGN / V_ALIGN

Text / TextInput 对齐方式：

```lua
Utils.H_ALIGN.LEFT / CENTER / RIGHT / JUSTIFY
Utils.V_ALIGN.TOP / CENTER / BOTTOM
```

### BTN_STATES

按钮状态：

```lua
Utils.BTN_STATES.NORMAL / HOVER / PRESSED / DISABLED / SELECTED / SELECTED_HOVER
```

### CHECKBOX_STYLE

```lua
Utils.CHECKBOX_STYLE.CHECKBOX  -- "checkbox"
Utils.CHECKBOX_STYLE.TOGGLE    -- "toggle"
```

### TEXT_WRAP_MODE

```lua
Utils.TEXT_WRAP_MODE.OFF      -- "off"（不换行）
Utils.TEXT_WRAP_MODE.DEFAULT  -- "default"（按宽度换行）
```

### SCROLL_MODE

```lua
Utils.SCROLL_MODE.DISABLED / AUTO / SHOW_ALWAYS / SHOW_NEVER / RESERVE
```

### RENDER_LAYERS

```lua
Utils.RENDER_LAYERS.BASE = 0
Utils.RENDER_LAYERS.OVERLAY = 50
Utils.RENDER_LAYERS.DROPDOWN = 80
Utils.RENDER_LAYERS.TOOLTIP = 100
```

### UI_COLORS

预设颜色表。常用：

```lua
Utils.UI_COLORS.WHITE / BG / SURFACE / LINE
Utils.UI_COLORS.TITLE / PRIMARY_TEXT / SECONDARY_TEXT / HINT
Utils.UI_COLORS.BTN_NORMAL / BTN_HOVER / BTN_DISABLED / BTN_SELECTED
Utils.UI_COLORS.ACCENT / ACCENT_LIGHT / WARNING
```

## 工具函数

| 函数 | 说明 |
|------|------|
| `Utils.RGB(r, g, b, a)` | 将 0~255 的 RGB 值转换为 0~1 的 `{r, g, b, a}` 表 |
| `Utils.clamp(val, min, max)` | 将值限制在 [min, max] 范围内 |
| `Utils.hasFlag(flags, flag)` | 检查位标志组合中是否包含某个标志 |
| `Utils.validateEnum(value, enum, default, label)` | 校验枚举值，非法时返回默认值并打印警告 |
| `Utils.newButtonStateStyle(...)` | 构造按钮状态样式表 |
| `Utils.newImageButtonStateStyle(...)` | 构造图片按钮状态样式表 |

### newButtonStateStyle

```lua
Utils.newButtonStateStyle(text, text_color, font_size, bg_color,
    outline_width, outline_color, offset, scale, rounding_radius)
```

参数按位置传入，不需要的可传 `nil`。返回的样式表可直接传给 Button 的 `normal`/`hover` 等字段。

### newImageButtonStateStyle

```lua
Utils.newImageButtonStateStyle(texture, tint, text, text_color, font_size, offset, scale)
```

## 最佳实践

- **推荐**：使用枚举常量而非硬编码字符串（如 `Utils.ORIENTATION.VERTICAL` 而非 `"vertical"`）。
- **推荐**：使用 `Utils.hasFlag` 而非手动位运算检测 SizeFlags。
- **推荐**：使用 `Utils.newButtonStateStyle(...)` 构造按钮样式，保持一致性。
