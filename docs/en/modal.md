# Modal

Modal dialog with full-screen semi-transparent overlay + centered content. Overlay blocks all mouse events.

**Inheritance:** `Widget` → `Modal`

## Constructor Parameters (datas)

```lua
{
    overlay_color = {r, g, b, a},         -- Default from theme ({0,0,0,0.5})
    dismiss_on_outside_click = boolean,   -- Default true
    dismiss_on_escape = boolean,          -- Default true
    content = Widget,                     -- Initial content
    on_dismiss = function(),              -- Dismiss callback
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `setContent(widget)` | Replace content |
| `getContentContainer()` | Get content container for direct manipulation |
| `show()` / `hide()` | Show/hide modal |
| `dismiss()` | Close (fires `onDismiss`, then hides) |
| `isShowing()` | Check if visible |

## How It Works

- **Hidden by default**: `shown = false` after construction; must call `show()`.
- **Full-screen overlay**: Panel with `{0,0,1,1}` anchor. Overrides all mouse handlers to block event penetration.
- **Centered content**: `content_container` uses `pivot={0.5,0.5}` + `anchor={0.5,0.5,0.5,0.5}`.
- **Dismiss**: Escape key or outside-content click triggers `dismiss()`.

## Example

```lua
local modal
modal = Modal({
    dismiss_on_outside_click = true,
    dismiss_on_escape = true,
    on_dismiss = function() print("dismissed") end,
    content = Panel({ w = 300, h = 200, bg_color = Utils.RGB(50, 50, 60) }),
})
modal:show()
```
