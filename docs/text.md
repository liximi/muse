# Text

文本渲染组件，支持 coloredtext、自动换行和对齐。

**继承链：** `Widget` → `Text`

## 构造参数（datas）

```lua
{
    text = string | table,        -- 文本内容，也支持 coloredtext 格式：{color1, str1, color2, str2, ...}
    font_key = string,            -- 字体注册 key，默认 "default"
    font_size = number,           -- 字号，默认 16
    text_color = {r, g, b, a},    -- 文本颜色，默认来自 theme.text.text_color
    h_align = string,             -- 水平对齐："left" | "right" | "center" | "justify"，默认 "left"
    v_align = string,             -- 垂直对齐："top" | "bottom" | "center"，默认 "top"
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `setText(text)` | 设置文本内容（支持 coloredtext） |
| `getText(only_string)` | 获取文本，`only_string=true` 时从 coloredtext 提取纯字符串 |
| `setTextColor(color)` | 设置文本颜色 `{r, g, b, a}` |
| `getTextColor()` | 获取文本颜色 |
| `setFont(font_key, size)` | 设置字体（需在 `ui/fonts.lua` 中注册） |
| `getFont(return_key)` | 获取字体对象，`return_key=true` 时返回 key 字符串 |
| `setFontSize(size)` | 设置字号 |
| `getFontSize()` | 获取字号 |
| `setHAlign(align)` | 设置水平对齐方式 |
| `setVAlign(align)` | 设置垂直对齐方式 |
| `setWrapMode(mode)` | 设置换行模式：`"off"` 或 `"default"` |
| `getDimensions()` | 获取渲染后的文本尺寸 `w, h` |
| `getScaledDimensions()` | 获取本地缩放后的尺寸 |
| `getGlobalScaledDimensions()` | 获取全局缩放后的尺寸 |
| `getSize()` | 同 `getDimensions()` |
| `getScaledSize()` | 同 `getScaledDimensions()` |
| `getGlobalScaledSize()` | 同 `getGlobalScaledDimensions()` |
| `measure(max_w, max_h)` | 查询自然尺寸 `{w, h}`，给定宽度约束时返回换行后尺寸 |
| `updateTextLayout()` | 强制刷新文本布局 |

## 换行模式

| 模式 | 常量 | 行为 |
|------|------|------|
| 默认换行 | `Utils.TEXT_WRAP_MODE.DEFAULT` | 以 transform.w 为宽度自动换行 |
| 关闭换行 | `Utils.TEXT_WRAP_MODE.OFF` | 不换行，以文本实际宽度渲染 |

## 示例

```lua
local label = Text({
    text = "Hello, World!",
    font_size = 18,
    text_color = Utils.UI_COLORS.TITLE,
    h_align = "center",
    v_align = "center",
    anchor = {0, 0, 1, 1},
})

-- coloredtext 格式
local colored = Text({
    text = {
        {1, 0.5, 0.5, 1}, "Red text ",
        {0.5, 0.5, 1, 1}, "Blue text",
    },
})
```
