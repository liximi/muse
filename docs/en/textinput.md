# TextInput

A text input field supporting cursor control, text selection, clipboard, undo/redo, adaptive height, and single-line mode.

**Inheritance chain:** `Widget` → `TextInput`

## Constructor Parameters (datas)

```lua
{
    text = string,                -- initial text
    height_adaptive = boolean,    -- whether to auto-adjust height to fit text, default false
    min_height = number,          -- minimum height when height_adaptive is enabled, default 75
    single_line = boolean,        -- single-line mode (Enter does not break line; pasted newlines are filtered), default false
    on_submit = function(),       -- callback triggered on Enter in single-line mode

    bg = Widget,                  -- background Widget (auto-tracked to match size)

    hint = string,                -- placeholder hint text
    hint_color = {r, g, b, a},    -- placeholder hint color, defaults to theme

    font_key = string,            -- font key
    font_size = number,           -- font size
    text_color = {r, g, b, a},    -- text color
    h_align = string,             -- horizontal alignment: "left" | "right" | "center" | "justify"
    v_align = string,             -- vertical alignment: "top" | "bottom" | "center"
    text_padding = {l, r, t, b},  -- text padding, default {8, 8, 8, 8}
}
```

## Public Methods

### Text Operations

| Method | Description |
|--------|-------------|
| `setText(text)` | Set text content |
| `getText()` | Get text |
| `setTextColor(color)` | Set text color |
| `getTextColor()` | Get text color |
| `setFont(font_key, size)` | Set font |
| `getFont(return_key)` | Get font |
| `setFontSize(size)` | Set font size |
| `getFontSize()` | Get font size |
| `setHAlign(align)` | Set horizontal alignment |
| `setVAlign(align)` | Set vertical alignment |
| `measure(max_w, max_h)` | Query natural size (includes padding and min_height) |

### Cursor Operations

| Method | Description |
|--------|-------------|
| `showCursor(show)` | Show/hide cursor |
| `setCursorIndex(index)` | Set cursor UTF-8 character index within the paragraph |
| `setCursorPosByScreenPos(screen_x, screen_y)` | Set cursor position from screen coordinates |
| `moveCursorLeft()` | Move cursor left |
| `moveCursorRight()` | Move cursor right |
| `moveCursorUp()` | Move cursor up |
| `moveCursorDown()` | Move cursor down |
| `moveCursorToHead()` | Move cursor to line start |
| `moveCursorToEnd()` | Move cursor to line end |

### Selection Operations

| Method | Description |
|--------|-------------|
| `selectText(start_sec, start_idx, end_sec, end_idx)` | Set selection range |
| `selectAll()` | Select all |
| `copy()` | Copy selection to clipboard |
| `paste()` | Paste from clipboard |
| `lineBreak()` | Insert line break |
| `backspace()` | Backspace delete |
| `delete()` | Forward delete |

### Undo/Redo

| Method | Description |
|--------|-------------|
| `undo()` | Undo |
| `redo()` | Redo |

The undo stack has a maximum capacity of 100. Consecutive operations of the same type (e.g., consecutive character input) are merged into one group. A pause exceeding 0.3 seconds automatically commits the current group.

### Paragraph Operations

| Method | Description |
|--------|-------------|
| `appendNewSection()` | Append a new paragraph |
| `insertNewSection(pos, section)` | Insert a paragraph at the given position |
| `removeSection(pos)` | Remove a paragraph |
| `flushText()` | Sync sections to the internal Text component |
| `refreshHint()` | Refresh hint visibility |
| `refreshHeight()` | Refresh adaptive height |

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+A` | Select all |
| `Ctrl+C` | Copy |
| `Ctrl+V` | Paste |
| `Ctrl+X` | Cut |
| `Ctrl+Z` | Undo |
| `Ctrl+Y` / `Ctrl+Shift+Z` | Redo |
| `Shift+Arrow` | Extend selection |
| `Home/End` | Line start / line end |
| `Enter` | Line break (multi-line mode) or trigger `on_submit` (single-line mode) |

## Example

```lua
local input = TextInput({
    anchor = {0, 0, 1, 0},
    h = 40,
    hint = "Type something...",
    single_line = true,
    on_submit = function()
        print("submitted:", input:getText())
    end,
})
```
