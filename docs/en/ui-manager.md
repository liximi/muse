# UiManager

UiManager is a global singleton that manages the top-level widget hierarchy and event dispatch.

## Getting the Instance

```lua
local UiManager = require "ui.ui_manager":GetInstance()
```

## Public Methods

### Widget Management

| Method | Description |
|--------|-------------|
| `addWidget(widget)` | Add a widget as a root node (the widget must not have a parent) |
| `moveToTop(widget)` | Move the root widget to the top of render order (drawn last) |
| `moveToBottom(widget)` | Move the root widget to the bottom of render order (drawn first) |

### Focus Management

| Method | Description |
|--------|-------------|
| `setFocus(widget)` | Set the currently focused widget (automatically calls `onRemoveFocus` on the old focus and `onFocus` on the new one) |
| `getFocus()` | Return the currently focused widget |
| `clearFocus()` | Clear focus |

The Tab key cycles through focusable widgets (hold Shift for reverse order).

### Theme

| Method | Description |
|--------|-------------|
| `getDefaultTheme()` | Return the current default theme instance |
| `setDefaultTheme(theme)` | Set the default theme (all widgets without an explicit theme will use this) |

### Event Dispatch

UiManager dispatches LÖVE events to the widget tree, traversing the hierarchy from end to beginning (most recently added widgets receive events first):

| Method | Corresponding LÖVE Event |
|--------|--------------------------|
| `update(dt)` | `love.update` |
| `draw()` | `love.draw` (drawn in layers by `render_layer`) |
| `KeyPressed(key, isrepeat)` | `love.keypressed` |
| `KeyReleased(key)` | `love.keyreleased` |
| `TextInput(text)` | `love.textinput` |
| `MouseMoved(x, y, dx, dy)` | `love.mousemoved` |
| `MousePressed(x, y, button)` | `love.mousepressed` |
| `MouseReleased(x, y, button)` | `love.mousereleased` |
| `WheelMoved(x, y)` | `love.wheelmoved` |

Clicking outside any widget automatically clears focus.

### Render Layers

`draw()` renders in ascending `render_layer` order. Predefined layers:

```lua
Utils.RENDER_LAYERS = {
    BASE = 0,       -- default layer
    OVERLAY = 50,   -- overlay layer
    DROPDOWN = 80,  -- dropdown menus
    TOOLTIP = 100   -- tooltips
}
```
