# Text

Text rendering component. Supports coloredtext, word wrap, multi-directional alignment, and overflow clipping.

**Inheritance:** `Widget` → `Text`

## Constructor Parameters (datas)

```lua
{
    text = string | table,        -- Text content; also supports coloredtext: {color1, str1, color2, str2, ...}
    font_key = string,            -- Font key, default from theme
    font_size = number,           -- Font size, default from theme (16)
    text_color = {r, g, b, a},    -- Text color, default from theme
    h_align = string,             -- "left" | "right" | "center" | "justify", default "left"
    v_align = string,             -- "top" | "bottom" | "center", default "top"
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `setText(text)` | Set text content (triggers `updateTextLayout()`) |
| `getText(only_string)` | Get text; `only_string=true` extracts plain string from coloredtext |
| `setTextColor(color)` | Set text color `{r, g, b, a}` |
| `setFont(font_key, size)` | Set font (must be registered in `ui/fonts.lua`) |
| `setFontSize(size)` | Set font size |
| `setHAlign(align)` / `setVAlign(align)` | Set alignment |
| `setWrapMode(mode)` | Set wrap mode: `"off"` or `"default"` |
| `getDimensions()` | Get rendered texture dimensions `w, h` |
| `measure(max_w, max_h)` | Query natural size with width constraint |
| `updateTextLayout()` | Force rebuild layout |

## Minimum & Desired Size

Text overrides `getMinimumSize()` and `getDesiredSize()`:

| Method | Wrap Off | Wrap On |
|--------|----------|---------|
| `getMinimumSize()` | Full text width × line height | Width=1 (compressible), height=current shaped height |
| `getDesiredSize()` | Same as minimum | Current actual shaped `w, h` |

This matches Godot Label behavior: with wrap on, the text tells containers "I can shrink very narrow" while desired reflects actual needed size.

## Wrap Modes

| Mode | Constant | Behavior |
|------|----------|----------|
| Word wrap | `Utils.TEXT_WRAP_MODE.DEFAULT` | Wrap at `transform.w` width |
| No wrap | `Utils.TEXT_WRAP_MODE.OFF` | Render at actual text width |

## Overflow Mode

```lua
Utils.TEXT_OVERFLOW_MODE.NONE  -- Don't clip (default)
Utils.TEXT_OVERFLOW_MODE.CHAR  -- Clip per-character, append ellipsis
```

## Key Edge Cases

- **`transform.w/h` defaults to 0**: Text stores size in the `love.graphics.Text` object, not in transform. `getCullAABB()` is overridden to use actual text dimensions, so clipping and collision work correctly. Debug bounding boxes may show zero area.
- **Wrap width fallback**: When `transform.w <= 0`, `updateTextLayout()` fallbacks to full text width.

## Example

```lua
local label = Text({
    text = "Hello, World!",
    font_size = 18,
    text_color = Utils.UI_COLORS.TITLE,
    h_align = "center",
    v_align = "center",
    anchor = {0, 0, 1, 1},
})

-- Colored text
local colored = Text({
    text = {
        {1, 0.5, 0.5, 1}, "Red ",
        {0.5, 0.5, 1, 1}, "Blue",
    },
})

-- Wrapped
local wrapped = Text({
    text = "A very long text that wraps",
    wrap_mode = Utils.TEXT_WRAP_MODE.DEFAULT,
    anchor = {0, 0, 1, 0},
    h = 60,
})
```
