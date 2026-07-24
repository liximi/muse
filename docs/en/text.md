# Text

A widget for displaying text. Supports automatic wrapping, alignment, and colored text (multi-color segments).

**Inheritance:** `Widget` → `Text`

## Constructor Parameters (datas)

```lua
{
    text = string | table,    -- Text content, also supports coloredtext: {color1, string1, color2, string2, ...}
    font_key = string,        -- Font key (must be registered in ui/fonts.lua)
    font_size = number,       -- Font size
    text_color = {r, g, b, a}, -- Text color (multiplied with segment colors for coloredtext)
    h_align = "left" | "center" | "right" | "justify",  -- Horizontal alignment, default "left"
    v_align = "top" | "center" | "bottom",              -- Vertical alignment, default "top"
}
```

## How It Works

Text creates a `love.graphics.Text` object at construction. `transform.w/h` defaults to 0 — the actual text dimensions are stored inside the `love.graphics.Text` object, accessible via `getDimensions()`.

### Wrap Mode

Controlled by `wrap_mode`, defaulting to off (`TEXT_WRAP_MODE.OFF`). When set to `TEXT_WRAP_MODE.DEFAULT`, text wraps at `transform.w` width.

### Minimum Size

`getMinimumSize()` behavior depends on wrap mode:
- **Wrap off**: width = full text width (incompressible), height = single line height.
- **Wrap on**: width = 1 (can shrink to almost any width), height = current shaped line height. Containers use this to know the text can compress, triggering wrapping in constrained space.

### Desired Size

`getDesiredSize()` also depends on wrap mode:
- **Wrap off**: equals minimum size.
- **Wrap on**: returns the current shaped dimensions. Containers use this in "pass 2A" to allocate width close to what the text actually needs.

### Culling AABB

Text overrides `getCullAABB()` to use actual text dimensions instead of `transform.w/h`, preventing premature culling inside Scroll containers.

## Public Methods

| Method | Description |
|--------|-------------|
| `setText(text)` | Set text content |
| `getText(only_string)` | Get text (coloredtext returns plain concatenation when only_string=true) |
| `setTextColor({r, g, b, a})` | Set text color |
| `setFont(font_key, size)` | Set font |
| `setFontSize(size)` | Set font size |
| `setHAlign(align)` | Set horizontal alignment |
| `setVAlign(align)` | Set vertical alignment |
| `setWrapMode(mode)` | Set wrap mode |
| `getDimensions()` | Get actual text dimensions (px) |
| `measure(max_w, max_h)` | Query natural size `{w, h}` under a width constraint |

## Example

```lua
-- Basic text
local label = Text({ text = "Hello World", font_size = 16 })

-- Auto-wrapping text
local desc = Text({
    text = "A long description that wraps automatically.",
    w = 200,
    wrap_mode = "default",
    h_align = "left",
})

-- Colored text
local colored = Text({
    text = {
        {1, 0.3, 0.3}, "Red ",
        {0.3, 1, 0.3}, "Green ",
        {0.3, 0.3, 1}, "Blue",
    },
    font_size = 14,
})
```

## Best Practices

- **Do**: Set `w` or obtain width through container layout for wrapping text, otherwise it won't wrap.
- **Do**: Use `getDimensions()` for actual text size, not `transform.w/h`.
- **Don't**: Rely on `transform.w/h` for layout calculations when it's 0 — Text dimensions live in the `love.graphics.Text` object.
