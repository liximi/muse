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

### Raycast Target

`handleEvent` has a fallback blocking mechanism for mouse events, **only active for leaf nodes (`#children == 0`)**:
if `raycast_target == true` and the cursor is within bounds, the event is blocked even without an explicit handler.

Containers with children do not block via fallback — they rely on children or explicit handlers.

> **Note:** Interactive widgets like Button/Checkbox/TextInput set `raycast_target = false`
> on their child Text/Image during construction, preventing children from intercepting clicks
> meant for the parent. If you build custom composite widgets, do the same.

Default values per widget type:

| Widget | Default | Reason |
|--------|---------|--------|
| Panel / Text / Image / NineSlice / ProgressBar | `true` | Visual entity |
| Button / ImageButton / Checkbox / RadioButton | `true` | Interactive (inherits ButtonBase) |
| TextInput / SliderBar / Scroll | `true` | Interactive |
| Modal / TabView / Dropdown / Tooltip | `true` | Container with interaction/visuals |
| Widget (base) / Box / List / RadioGroup | `false` | Pure layout container, no blocking |

Toggle at runtime: `widget.raycast_target = false`.

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
| `enableDebug(enable)` | Toggle debug drawing (bounding boxes + AABB + pivot point). Returns self, supports chaining |

> **Note**: Text's `transform.w/h = 0`; debug boxes may show zero-area for Text.
> This is normal — Text dimensions are in `love.graphics.Text`, not transform. Hit detection and culling work correctly.

## Visibility Culling

| Method | Description |
|--------|-------------|
| `getCullAABB()` | Returns AABB for visibility culling. Subclasses may override for more accurate bounds than transform |

Text overrides this method using `getGlobalScaledSize()` (actual text dimensions) to avoid premature culling in Scroll.
Culling uses a 1px tolerance; subtrees are skipped only when they have **zero overlap** with the clip region.

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
| `raycast_target` | boolean | Raycast toggle. When `true`, mouse events are blocked even without an explicit handler if the cursor falls within the widget's bounds. Visual controls default to `true`, containers to `false` |
| `render_layer` | number | Render layer (0=BASE, 50=OVERLAY, 80=DROPDOWN, 100=TOOLTIP) |
| `always_draw` | boolean | Whether to skip visibility culling |
| `_name` | string | Widget name (for debugging) |
