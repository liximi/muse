# Text

显示文本的控件。支持自动换行、对齐、colored text（多彩文本）等特性。

**继承链：** `Widget` → `Text`

## 构造参数（datas）

```lua
{
    text = string | table,    -- 文本内容，也支持 coloredtext 格式：{color1, string1, color2, string2, ...}
    font_key = string,        -- 字体键（需在 ui/fonts.lua 中注册）
    font_size = number,       -- 字号
    text_color = {r, g, b, a}, -- 文本颜色（coloredtext 时会与各段颜色相乘）
    h_align = "left" | "center" | "right" | "justify",  -- 水平对齐，默认 "left"
    v_align = "top" | "center" | "bottom",              -- 垂直对齐，默认 "top"
}
```

## 工作原理

Text 在构造时创建一个 `love.graphics.Text` 对象。`transform.w/h` 默认为 0——文本的实际尺寸存储在 `love.graphics.Text` 对象内部，通过 `getDimensions()` 获取。

### 换行模式

通过 `wrap_mode` 控制，默认关闭（`TEXT_WRAP_MODE.OFF`）。设为 `TEXT_WRAP_MODE.DEFAULT` 后，文本按 `transform.w` 宽度自动换行。

### 最小尺寸

`getMinimumSize()` 的行为因换行模式而异：
- **关闭换行**：宽度 = 完整文本宽度（不可压缩），高度 = 单行高。
- **开启换行**：宽度 = 1（可缩到几乎任意宽度），高度 = 当前整形后的实际行高。容器据此知道该文本可以压缩，从而在有限空间内触发换行。

### 期望尺寸

`getDesiredSize()` 同样依赖换行模式：
- **关闭换行**：等于最小尺寸。
- **开启换行**：返回当前整形后的实际尺寸，容器在“第二趟分配”中据此为文本争取接近所需的宽度。

### 裁剪 AABB

Text 覆写了 `getCullAABB()`，使用文本实际尺寸而非 `transform.w/h`，避免在 Scroll 容器中被过早裁剪。

## 公有方法

| 方法 | 说明 |
|------|------|
| `setText(text)` | 设置文本内容 |
| `getText(only_string)` | 获取文本（only_string=true 时 coloredtext 返回纯文本拼接） |
| `setTextColor({r, g, b, a})` | 设置文本颜色 |
| `setFont(font_key, size)` | 设置字体 |
| `setFontSize(size)` | 设置字号 |
| `setHAlign(align)` | 设置水平对齐 |
| `setVAlign(align)` | 设置垂直对齐 |
| `setWrapMode(mode)` | 设置换行模式 |
| `getDimensions()` | 获取文本实际尺寸（像素） |
| `measure(max_w, max_h)` | 查询在给定宽度约束下的自然尺寸 `{w, h}` |

## 示例

```lua
-- 基础文本
local label = Text({ text = "Hello World", font_size = 16 })

-- 自动换行文本
local desc = Text({
    text = "A long description that wraps automatically.",
    w = 200,
    wrap_mode = "default",
    h_align = "left",
})

-- 多彩文本（colored text）
local colored = Text({
    text = {
        {1, 0.3, 0.3}, "Red ",
        {0.3, 1, 0.3}, "Green ",
        {0.3, 0.3, 1}, "Blue",
    },
    font_size = 14,
})
```

## 最佳实践

- **推荐**：换行文本应设置 `w` 或在容器中通过布局获得宽度，否则不会换行。
- **推荐**：使用 `getDimensions()` 获取文本实际尺寸，而非 `transform.w/h`。
- **不推荐**：在 `transform.w/h` 为 0 时依赖其值做布局计算——Text 的尺寸在 `love.graphics.Text` 对象中。
