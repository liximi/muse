# Widget (Base Class)

Base class for all UI elements. Provides tree structure, Transform layout, event handling, lifecycle management, and size measurement.

**Inheritance:** `Class` → `Widget`

## Constructor Parameters (datas)

```lua
{
    pivot = {x, y},           -- Pivot 0~1 (default {0, 0})
    anchor = {minx, miny, maxx, maxy},  -- Anchor (default {0, 0, 0, 0})
    x = number, y = number,   -- Position (px)
    w = number, h = number,   -- Size (px)
    sx = number, sy = number, -- Scale (default 1)
    padding = {left, right, top, bottom},  -- Padding (px)
    r = number,               -- Rotation (radians)
}
```

Three constructor signatures are supported:

```lua
Widget(datas, theme)
Widget(name, datas, theme)
```

## Child Management

| Method | Description |
|--------|-------------|
| `addChild(child)` | Add child widget (auto-detects circular references, removes from old parent, propagates attached state) |
| `removeChild(child)` | Remove child widget |
| `removeAllChildren()` | Remove all children (preserves widget objects, no destroy) |
| `clearChildren()` | Remove and **recursively destroy** all children (frees GPU resources). Use only when children are no longer needed |

## Lifecycle

| Method | Description |
|--------|-------------|
| `destroy()` | Recursively destroy self and descendants, remove from parent, notify UiManager |
| `isValid()` | Check if widget is valid (not destroyed) |
| `onAttached()` | Called when entering UiManager's active tree |
| `onDetached()` | Called when leaving the active tree |
| `_setAttached(attached)` | Internal: recursively set attached state and trigger lifecycle hooks |

## Update Lifecycle

```lua
function Widget:update(dt, parent_should_update)
    self.transform:onUpdate()         -- 1. Transform dirty check
    -- SizeChanged event detection
    self:_preChildrenUpdate(dt)       -- 2. ★ Hook (Container sorts here)
    for child in children do          -- 3. Children update
        child:update(dt, true)
    end
    self:onUpdate(dt)                 -- 4. Self update
end
```

## Size Measurement

| Method | Description |
|--------|-------------|
| `measure(max_w, max_h)` | Query natural size `{w, h}`. Default: current transform size |
| `getMinimumSize()` | Return content minimum natural size `w, h`. Default: `(0, 0)`. Override for content-based sizing |
| `getCombinedMinimumSize()` | `max(getMinimumSize(), custom_minimum)` — what containers actually use |
| `setCustomMinimumSize(w, h)` | Set custom minimum size override (nil = no constraint) |
| `getDesiredSize()` | Desired natural size, defaults to minimum. Text overrides for full text width |

> **Note**: A plain Widget with `h = 40` but no overridden `getMinimumSize` or `custom_minimum` may get 0 height from a container. Button, Text, Image etc. already override `getMinimumSize`. For custom widgets in containers, call `setCustomMinimumSize(nil, 40)`.

## Event Handling

Events propagate **children-first** (reverse iteration over children). Returning `true` intercepts the event.

| Method | Description |
|--------|-------------|
| `handleEvent(event_type, ...)` | Dispatch entry point; auto-constructs handler name as `"on" .. event_type` |
| `isOperational()` | Check if widget is operational (valid + enabled + shown) |
| `enableSizeChangedEvent(enable)` | Enable/disable SizeChanged event polling |

### Raycast Target (raycast_target)

After recursing children and trying the self handler, `handleEvent` has a fallback: if `raycast_target == true` and the mouse is within `regionDetection`, return `true` to block penetration. **WheelMoved is excluded** — scroll events should pass through to scrollable parents.

Visible widgets default to `raycast_target = true`; layout containers default to `false`.

## Event Handlers

Override these methods (naming: `on` + PascalCase event name):

| Handler | Trigger |
|---------|---------|
| `onUpdate(dt)` | Every frame |
| `onDraw()` | Self-draw (before children) |
| `onPostDraw()` | After children draw |
| `onMousePressed(x, y, button)` | Mouse press |
| `onMouseReleased(x, y, button)` | Mouse release |
| `onMouseMoved(x, y, dx, dy)` | Mouse move |
| `onWheelMoved(x, y)` | Mouse wheel |
| `onKeyPressed(key, isrepeat)` | Key press |
| `onTextInput(text)` | Text input |
| `onFocus()` / `onRemoveFocus()` | Focus gain/loss |
| `onSizeChanged(w, h)` | Size change (requires `enableSizeChangedEvent(true)`) |
| `onHovered(hovered, x, y, dx, dy)` | Mouse enter/leave (requires `Components.addHoverState`) |

## SizeFlags

Each Widget holds layout flags read by parent containers:

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `h_size_flags` | number | `FILL` (1) | Horizontal size flags |
| `v_size_flags` | number | `FILL` (1) | Vertical size flags |
| `stretch_ratio` | number | `1.0` | Distribution weight when EXPAND is set |

Flags are composed via addition: `Utils.SIZE_FLAGS.FILL + Utils.SIZE_FLAGS.EXPAND` = `3`.

## Properties

| Property | Type | Description |
|----------|------|-------------|
| `transform` | Transform | Layout transform instance |
| `theme` | Theme | Current theme |
| `children` | table | Child widget array |
| `parent` | Widget/nil | Parent widget |
| `enabled` / `shown` | boolean | Enable/visibility state |
| `focus` / `focusable` | boolean | Focus state |
| `raycast_target` | boolean | Raycast fallback switch |
| `render_layer` | number | Render layer (0=BASE, 50=OVERLAY, 80=DROPDOWN, 100=TOOLTIP) |
| `always_draw` | boolean | Skip visibility culling |
| `_name` | string | Widget name (debug) |
