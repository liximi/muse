# Modal

A modal dialog component with a fullscreen semi-transparent overlay and centered content area.

**Inheritance chain:** `Widget` → `Modal`

## Constructor Parameters (datas)

```lua
{
    overlay_color = {r, g, b, a},         -- overlay color, defaults to theme.modal.overlay_color
    dismiss_on_outside_click = boolean,   -- whether clicking outside the content area dismisses the modal, default true
    dismiss_on_escape = boolean,          -- whether the Escape key dismisses the modal, default true
    content = Widget,                     -- initial content widget
    on_dismiss = function(),              -- dismiss callback
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `setContent(widget)` | Set modal content (replaces old content) |
| `getContentContainer()` | Get the content container (for direct external manipulation) |
| `show()` | Show the modal (auto `moveToTop`) |
| `hide()` | Hide the modal |
| `dismiss()` | Dismiss (triggers `onDismiss` callback then hides) |
| `isShowing()` | Whether the modal is currently showing |

## Behavior

- **Hidden by default** — must call `show()` after construction to display
- **Overlay interception** — all mouse events are intercepted by the overlay and will not pass through to background UI
- **Content centered** — content is auto-centered via pivot `{0.5, 0.5}` + anchor `{0.5, 0.5}`

## Closure Forward Reference

When an `on_click` closure references a widget created later (e.g., a close button referencing the modal itself), declare `local modal` before the closure:

```lua
local modal
modal = Modal({
    content = Button({
        text = "Close",
        on_click = function()
            modal:dismiss()  -- closure captures the outer `modal` variable
        end,
    }),
})
modal:show()
```

## Example

```lua
local modal = Modal({
    dismiss_on_outside_click = true,
    dismiss_on_escape = true,
    on_dismiss = function()
        print("modal dismissed")
    end,
    content = Panel({
        w = 300,
        h = 200,
        bg_color = Utils.RGB(50, 50, 60),
        -- add other child widgets inside this Panel
    }),
})
modal:show()
```
