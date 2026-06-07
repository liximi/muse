# Widget (base class)

The base class for all UI elements. Provides core mechanisms including tree structure, Transform layout, event handling, and lifecycle management.

**Inheritance chain:** `Object` → `Widget`

## Constructor Parameters (datas)

```lua
{
    pivot = {x, y},           -- pivot, 0~1 percentage
    anchor = {minx, miny, maxx, maxy},  -- anchor
    x = number,               -- position X (pixels)
    y = number,               -- position Y (pixels)
    w = number,               -- width (pixels)
    h = number,               -- height (pixels)
    sx = number,              -- horizontal scale
    sy = number,              -- vertical scale
    padding = {left, right, top, bottom},  -- padding (pixels)
    r = number,               -- rotation angle (radians)
}
```

An optional `theme` parameter is also accepted at construction: `Widget(datas, theme)` or `Widget(name, datas, theme)`.

## Transform Proxy Methods

Widget exposes Transform's core operations as convenience methods:

| Method | Description |
|--------|-------------|
| `setPosition(x, y)` | Set position |
| `getPosition()` | Get position `x, y` |
| `getGlobalPosition()` | Get global (screen) coordinates |
| `getGlobalScale()` | Get global cumulative scale |
| `getGlobalScaledSize()` | Get globally scaled size |
| `regionDetection(px, py)` | Test whether a screen coordinate falls inside the bounding box (accounts for rotation) |

## Child Management

| Method | Description |
|--------|-------------|
| `addChild(child)` | Add a child widget (auto-detects cycles, auto-removes from old parent) |
| `removeChild(child)` | Remove a child widget |
| `removeAllChildren()` | Remove all child widgets |

## Lifecycle

| Method | Description |
|--------|-------------|
| `destroy()` | Recursively destroy self and all descendants, remove from parent |
| `isValid()` | Check whether the widget is valid (not destroyed) |

## Size Measurement

| Method | Description |
|--------|-------------|
| `measure(max_w, max_h)` | Query natural (content) size, returns `{w, h}`. Defaults to current transform size |

## Visibility Control

| Method | Description |
|--------|-------------|
| `show()` | Show |
| `hide()` | Hide |
| `isShown()` | Whether currently shown |

## Enable/Disable

| Method | Description |
|--------|-------------|
| `enable()` | Enable (triggers `onEnabled`) |
| `disable()` | Disable (triggers `onDisabled`) |
| `isEnabled()` | Whether currently enabled |

## Focus

| Method | Description |
|--------|-------------|
| `setFocus()` | Request focus |
| `removeFocus()` | Remove focus |
| `isFocus()` | Whether currently focused |

## Z-Ordering

| Method | Description |
|--------|-------------|
| `moveToTop()` | Move to top of siblings (drawn last) |
| `moveToBottom()` | Move to bottom of siblings (drawn first) |

## Event Handling

Event propagation: **children first** (reverse-order traversal of children). If a child returns `true`, the event is intercepted and stops propagating.

| Method | Description |
|--------|-------------|
| `handleEvent(event_type, ...)` | Event dispatch entry point; auto-concatenates `"on" .. event_type` to look up the handler |
| `isOperational()` | Check whether the widget is operational (valid + enabled + shown) |

## Event Handler Conventions

Subclasses override the following methods to respond to events (naming rule: `on` + PascalCase event name):

| Handler | When triggered |
|---------|----------------|
| `onUpdate(dt)` | Every frame update |
| `onDraw()` | Self-drawing |
| `onPostDraw()` | After children have finished drawing |
| `onKeyPressed(key, isrepeat)` | Key press |
| `onKeyReleased(key)` | Key release |
| `onTextInput(text)` | Text input |
| `onMousePressed(x, y, button)` | Mouse press |
| `onMouseReleased(x, y, button)` | Mouse release |
| `onMouseMoved(x, y, dx, dy)` | Mouse move |
| `onWheelMoved(x, y)` | Mouse wheel |
| `onFocus()` | Gained focus |
| `onRemoveFocus()` | Lost focus |
| `onEnabled()` | Became enabled |
| `onDisabled()` | Became disabled |
| `onSizeChanged(w, h)` | Size changed (must first call `enableSizeChangedEvent(true)`) |
| `onHovered(hovered, x, y, dx, dy)` | Mouse enter/leave (requires `Components.addHoverState` mixin) |

## Debugging

| Method | Description |
|--------|-------------|
| `enableDebug(enable)` | Toggle debug drawing (bounding boxes + AABB + pivot point) |

## Properties

| Property | Type | Description |
|----------|------|-------------|
| `transform` | Transform | Layout Transform instance |
| `theme` | Theme | Currently active theme |
| `children` | table | Array of child widgets |
| `parent` | Widget/nil | Parent widget |
| `enabled` | boolean | Whether enabled |
| `shown` | boolean | Whether shown |
| `focus` | boolean | Whether focused |
| `focusable` | boolean | Whether focusable via Tab key |
| `render_layer` | number | Render layer (0=BASE, 50=OVERLAY, 80=DROPDOWN, 100=TOOLTIP) |
| `always_draw` | boolean | Whether to skip visibility culling |
| `_name` | string | Widget name (for debugging) |
