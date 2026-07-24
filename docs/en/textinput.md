# TextInput

Text input field with cursor control, text selection, clipboard, undo/redo, adaptive height, single-line mode, native scrollbar, and smooth scrolling.

**Inheritance:** `Widget` → `TextInput`

## Constructor Parameters (datas)

```lua
{
    text = string,                -- Initial text
    height_adaptive = boolean,    -- Auto-adjust height to fit content, default false
    min_height = number,          -- Minimum height when adaptive, default 75 or datas.h
    single_line = boolean,        -- Single-line mode (Enter submits, paste filters newlines), default false
    on_submit = function(),       -- Enter callback (single-line mode)

    bg = Widget,                  -- Background Widget (Panel), auto-sized, outline turns blue on focus
    hint = string,                -- Placeholder text (hidden when content exists)
    hint_color = {r, g, b, a},    -- Placeholder color
    font_key = string,            -- Font key
    font_size = number,           -- Font size
    text_color = {r, g, b, a},    -- Text color
    h_align = string,             -- "left" | "right" | "center" | "justify"
    v_align = string,             -- "top" | "bottom" | "center"
    text_padding = {l, r, t, b},  -- Text padding, default {8, 8, 8, 8}
}
```

## Public Methods

### Text

| Method | Description |
|--------|-------------|
| `setText(text)` / `getText()` | Set/get text content |
| `setTextColor(color)` / `getTextColor()` | Set/get text color |
| `setFont(font_key, size)` / `getFont()` | Set/get font |
| `setFontSize(size)` / `getFontSize()` | Set/get font size |
| `setHAlign(align)` / `setVAlign(align)` | Set alignment |
| `measure(max_w, max_h)` | Query natural size |
| `getMinimumSize()` | Adaptive mode: current size; otherwise `(0, min(line_h, min_height) + padding)` |

### Cursor

| Method | Description |
|--------|-------------|
| `setCursorIndex(index)` | Set UTF-8 char index within section |
| `setCursorPosByScreenPos(screen_x, screen_y)` | Set cursor from screen coords |
| `moveCursorLeft/Right/Up/Down()` | Move cursor (supports cross-section and wrapped lines) |
| `moveCursorToHead/End()` | Move to line start/end |

### Selection & Clipboard

| Method | Description |
|--------|-------------|
| `selectAll()` / `copy()` / `paste()` | Selection and clipboard operations |
| `lineBreak()` / `backspace()` / `delete()` | Editing operations |
| `undo()` / `redo()` | Undo/redo (100-entry stack, groups consecutive same-type operations) |

## Scroll Mechanics

### Multi-line (default)

- Internal `_scroll_y` with smooth target approaching (max 5 lines/sec)
- Native scrollbar: 6px wide, drawn in `onPostDraw` (track + proportional thumb)
- Supports scrollbar drag and track click-to-jump
- Mouse wheel: 3 lines per notch, only when mouse is inside and focused

### Single-line

- `_scroll_x` horizontal offset
- Tracks cursor on focus, resets to start on blur

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+A` | Select all |
| `Ctrl+C/V/X` | Copy/Paste/Cut |
| `Ctrl+Z` / `Ctrl+Y` | Undo/Redo |
| `Shift+Arrows` | Extend selection |
| `Home/End` | Line start/end |

## Height Adaptive

When `height_adaptive = true`, height follows content: `max(min_height, text_h) + padding_top + padding_bottom`. Notifies parent container via `parent:queueSort()` on height change.

## Example

```lua
-- Single-line input
local input = TextInput({
    anchor = {0, 0, 1, 0},
    h = 40,
    hint = "Type something...",
    single_line = true,
    on_submit = function() print("submitted:", input:getText()) end,
})

-- Multi-line adaptive
local textarea = TextInput({
    anchor = {0, 0, 1, 0},
    height_adaptive = true,
    min_height = 100,
    text_padding = {12, 12, 8, 8},
})

-- With custom background
local styled = TextInput({
    bg = Panel({
        bg_color = Utils.RGB(40, 40, 50),
        rounding_radius = 6,
        outline_width = 1,
        outline_color = Utils.RGB(70, 70, 80),
    }),
    anchor = {0, 0, 1, 0},
    h = 120,
})
```
