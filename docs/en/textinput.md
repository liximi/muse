# TextInput

Text input widget. Supports multi-line editing, single-line mode, text selection, clipboard operations, undo/redo, cursor blinking, and scrollbars.

**Inheritance:** `Widget` → `TextInput`

## Constructor Parameters (datas)

```lua
{
    text = string,              -- Initial text
    single_line = boolean,      -- Single-line mode: Enter triggers on_submit instead of newline, default false
    height_adaptive = boolean,  -- Auto-expand height to fit content, default false
    min_height = number,        -- Minimum height when height_adaptive, default 75
    hint = string,              -- Placeholder text (shown when empty)
    hint_color = {r, g, b, a},  -- Hint text color
    on_submit = function,       -- Callback when Enter pressed in single-line mode
    bg = Widget,                -- Background widget (e.g., Panel), auto-sized to match
    text_padding = {left, right, top, bottom},  -- Text padding
    font_key = string,          -- Font key
    font_size = number,         -- Font size
    text_color = {r, g, b, a},  -- Text color
    h_align = "left" | "center" | "right" | "justify",
    v_align = "top" | "center" | "bottom",
}
```

## How It Works

### Multi-Line Mode (default)

Text is internally managed as sections split by `\n`. Text wraps at `transform.w` width. Internal vertical scrolling is achieved by adjusting the inner Text child's `padding.top/bottom` to offset text content, combined with scissor clipping in `onDraw`.

### Single-Line Mode

When `single_line = true`: Enter triggers `on_submit`, pasted newlines are replaced with spaces, and horizontal scrolling replaces vertical scrolling.

### Height Adaptive

When `height_adaptive = true`, `refreshHeight()` adjusts the input height each frame based on actual text height, never below `min_height`.

### Cursor and Selection

The cursor uses UTF-8 character indices (not byte indices). Dragging the mouse creates a selection. `_sel_start`/`_sel_end` store selection bounds as `{section, index}`.

### Undo/Redo

Snapshot-based undo stack (max 100). Consecutive operations of the same type (input/backspace/delete) are merged into a single undo record after a brief pause. Ctrl+Z undo, Ctrl+Y or Ctrl+Shift+Z redo.

### Scrollbar

In multi-line mode, a native scrollbar (6px track + proportional thumb) appears on the right when content overflows, supporting thumb dragging and track click-to-jump.

## Public Methods

| Method | Description |
|--------|-------------|
| `setText(text)` | Set text, overwriting current content |
| `getText()` | Get text content |
| `setTextColor({r, g, b, a})` | Set text color |
| `setFont(font_key, size)` | Set font |
| `setFontSize(size)` | Set font size |
| `setHAlign(align)` | Set horizontal alignment |
| `setVAlign(align)` | Set vertical alignment |
| `selectAll()` | Select all text |
| `copy()` | Copy selection to clipboard |
| `paste()` | Paste from clipboard |
| `undo()` / `redo()` | Undo/redo |
| `getMinimumSize()` | Min size: height = line height + padding, width = 0 |

## Example

```lua
-- Multi-line text input
local input = TextInput({
    w = 300,
    h = 120,
    hint = "Type something...",
    bg = Panel({ bg_color = {0.1, 0.1, 0.12, 1}, rounding_radius = 4 }),
})

-- Single-line search box
local search = TextInput({
    w = 200,
    h = 32,
    single_line = true,
    hint = "Search...",
    on_submit = function()
        print("Search:", search:getText())
    end,
})
```

## Best Practices

- **Do**: Use `single_line = true` + `on_submit` for search/input scenarios.
- **Do**: Set background via the `bg` parameter; the framework handles focus outline toggling automatically.
- **Don't**: Set `v_size_flags = FILL` together with `height_adaptive = true` — they conflict.
