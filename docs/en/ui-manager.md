# UiManager

Global singleton managing top-level widget hierarchy, focus, themes, render layer caching, and event dispatch.

## Getting the Instance

```lua
local UiManager = require "ui.ui_manager":GetInstance()
```

## Public Methods

### Widget Management

| Method | Description |
|--------|-------------|
| `addWidget(widget)` | Add widget as root node. Calls `_setAttached(true)` |
| `removeWidget(widget)` | Remove root widget. Returns success |
| `moveToTop(widget)` / `moveToBottom(widget)` | Move root in render/event order |
| `invalidateRenderCache()` | Mark render layer cache dirty |
| `getWidgetCount()` | Get active widget count |

### Focus Management

| Method | Description |
|--------|-------------|
| `setFocus(widget)` / `getFocus()` / `clearFocus()` | Focus management |

`Tab` cycles through `focusable = true` widgets (`Shift+Tab` reverses). Clicking outside clears focus.

### Theme

| Method | Description |
|--------|-------------|
| `getDefaultTheme()` / `setDefaultTheme(theme)` | Get/set default theme |

### Event Dispatch

Events traverse hierarchy from last to first. All event methods (except `update`/`draw`) return `boolean` (`true` = consumed).

| Method | LÖVE Event |
|--------|-----------|
| `update(dt)` | `love.update` |
| `draw()` | `love.draw` — layered by `render_layer` ascending |
| `KeyPressed(key, isrepeat)` | `love.keypressed` — Tab intercepted |
| `KeyReleased/TextInput/MouseMoved/MousePressed/MouseReleased/WheelMoved` | Corresponding events |

### Event Consumption

```lua
function love.mousepressed(x, y, button)
    local ui_handled = UiManager:MousePressed(x, y, button)
    if not ui_handled then
        gameWorld:handleClick(x, y)
    end
end
```

### Render Layers

```lua
Utils.RENDER_LAYERS = {
    BASE = 0, OVERLAY = 50, DROPDOWN = 80, TOOLTIP = 100
}
```
