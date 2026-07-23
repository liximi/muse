# Text

A text rendering component with support for coloredtext, automatic word wrap, and alignment.

**Inheritance chain:** `Widget` → `Text`

## Constructor Parameters (datas)

```lua
{
    text = string | table,        -- text content; also supports coloredtext format: {color1, str1, color2, str2, ...}
    font_key = string,            -- font registry key, default "default"
    font_size = number,           -- font size, default 16
    text_color = {r, g, b, a},    -- text color, defaults to theme.text.text_color
    h_align = string,             -- horizontal alignment: "left" | "right" | "center" | "justify", default "left"
    v_align = string,             -- vertical alignment: "top" | "bottom" | "center", default "top"
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `setText(text)` | Set text content (supports coloredtext) |
| `getText(only_string)` | Get text; `only_string=true` extracts a plain string from coloredtext |
| `setTextColor(color)` | Set text color `{r, g, b, a}` |
| `getTextColor()` | Get text color |
| `setFont(font_key, size)` | Set font (must be registered in `ui/fonts.lua`) |
| `getFont(return_key)` | Get font object; `return_key=true` returns the key string |
| `setFontSize(size)` | Set font size |
| `getFontSize()` | Get font size |
| `setHAlign(align)` | Set horizontal alignment |
| `setVAlign(align)` | Set vertical alignment |
| `setWrapMode(mode)` | Set wrap mode: `"off"` or `"default"` |
| `getDimensions()` | Get rendered text dimensions `w, h` |
| `getMinimumSize()` | Returns the minimum natural text size (unwrapped full width × one line height) |
| `getDesiredSize()` | Same as `getMinimumSize()` (desired natural width = unwrapped full width) |
| `getScaledDimensions()` | Get locally scaled dimensions |
| `getGlobalScaledDimensions()` | Get globally scaled dimensions |
| `getSize()` | Same as `getDimensions()` |
| `getScaledSize()` | Same as `getScaledDimensions()` |
| `getGlobalScaledSize()` | Same as `getGlobalScaledDimensions()` |
| `measure(max_w, max_h)` | Query natural size `{w, h}`; returns wrapped size when a width constraint is given |
| `updateTextLayout()` | Force-refresh text layout |

## Wrap Modes

| Mode | Constant | Behavior |
|------|----------|----------|
| Default wrap | `Utils.TEXT_WRAP_MODE.DEFAULT` | Auto-wraps using `transform.w` as the width |
| No wrap | `Utils.TEXT_WRAP_MODE.OFF` | No wrapping; renders at the text's actual width |

> **Note**: When wrapping is OFF, `measure()` may still use a different width constraint.
> In single-line inputs, both `wrap_mode=OFF` and correct width constraint in `measure()` are needed.

## Important Edge Cases

- **`transform.w/h` defaults to 0**: Text stores dimensions in `love.graphics.Text`, not in transform.
  `getGlobalAABB()` reads `self.w/h` (=0), but Text overrides `Widget:getCullAABB()` using
  `getGlobalScaledSize()` (virtual, returns actual text size), so culling and hit detection work correctly.
  However, debug boxes (`drawBound`) still show zero-area for Text
- **Right-alignment with `pivot`+`anchor` requires manual width**: `transform.w=0` breaks `pivot={1,0}` etc.
  Use `font:getWidth(text)` to measure first, then set `x` offset

## Examples

```lua
local label = Text({
    text = "Hello, World!",
    font_size = 18,
    text_color = Utils.UI_COLORS.TITLE,
    h_align = "center",
    v_align = "center",
    anchor = {0, 0, 1, 1},
})

-- coloredtext format
local colored = Text({
    text = {
        {1, 0.5, 0.5, 1}, "Red text ",
        {0.5, 0.5, 1, 1}, "Blue text",
    },
})
```
