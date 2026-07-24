# Modal

Modal dialog. Full-screen semi-transparent overlay with centered content, blocking all background interaction.

**Inheritance:** `Widget` → `Modal`

## Constructor Parameters (datas)

```lua
{
    overlay_color = {r, g, b, a},     -- Overlay color
    dismiss_on_outside_click = boolean, -- Close on outside click, default true
    dismiss_on_escape = boolean,      -- Close on Escape key, default true
    content = Widget,                 -- Initial content
    on_dismiss = function,            -- Dismiss callback
}
```

## How It Works

Modal is hidden by default; call `show()` to display. The overlay intercepts all mouse events (MousePressed/Released/Moved/WheelMoved), preventing penetration to background UI. Children process events first (buttons inside the content area); only unhandled events fall through to the overlay.

Content is auto-centered via `content_container` with centered anchor `{0.5, 0.5, 0.5, 0.5}`.

## Public Methods

| Method | Description |
|--------|-------------|
| `show()` | Show the modal |
| `hide()` | Hide the modal |
| `dismiss()` | Dismiss (triggers `on_dismiss` then hides) |
| `isShowing()` | Whether currently showing |
| `setContent(widget)` | Set content |
| `getContentContainer()` | Get content container |

## Example

```lua
local modal = Modal({
    dismiss_on_outside_click = true,
    dismiss_on_escape = true,
    content = Panel({
        w = 300, h = 200,
        bg_color = {0.15, 0.15, 0.2, 1},
        rounding_radius = 8,
    }),
    on_dismiss = function() print("modal closed") end,
})

modal:show()  -- Add as root widget and display
```

## Best Practices

- **Do**: Add Modal as a UiManager root widget and use `show()`/`hide()` to control visibility.
- **Do**: Use fixed `w`/`h` on the content; `content_container` auto-centers it.
- **Don't**: Create multiple Modal instances in the same scene without reuse — repeated creation/destruction is costly.
