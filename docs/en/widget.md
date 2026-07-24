# Widget (Base Class)

Base class for all UI elements. Provides tree structure, Transform layout, event handling, lifecycle management, and size measurement.

**Inheritance:** `Class` → `Widget`

## Constructor Parameters (datas)

```lua
{
    -- Layout
    pivot = {x, y},           -- Pivot 0~1 ratio, default {0, 0}
    anchor = {minx, miny, maxx, maxy},  -- Anchor, default {0, 0, 0, 0}
    x = number,               -- X position (px)
    y = number,               -- Y position (px)
    w = number,               -- Width (px)
    h = number,               -- Height (px)
    sx = number,              -- Horizontal scale, default 1
    sy = number,              -- Vertical scale, default 1
    padding = {left, right, top, bottom},  -- Padding (px)
    r = number,               -- Rotation (radians)

    -- SizeFlags (used by containers)
    h_size_flags = number,    -- Horizontal SizeFlags, default FILL(1)
    v_size_flags = number,    -- Vertical SizeFlags, default FILL(1)
    stretch_ratio = number,   -- EXPAND distribution weight, default 1.0
    custom_minimum_size = {w, h},  -- Override content minimum size
}
```

Two constructor signatures are supported:

```lua
Widget(datas, theme)
Widget(name, datas, theme)  -- When the first argument is a string, treated as name
```

## How It Works

### Transform Layout

Each Widget holds a `Transform` instance. Transform treats `padding` (left/right/top/bottom) as the single source of truth. All setters (setPosition, setSize, setAnchor, setPivot) ultimately write to padding fields, from which `_recalcLayout` derives the cached `x`/`y`/`w`/`h` values.

### Update Lifecycle

```lua
function Widget:update(dt, parent_should_update)
    self.transform:onUpdate()         -- 1. Transform dirty check (recompute x/y/w/h)
    -- SizeChanged detection           -- 2. If enabled, compare old vs new w/h
    self:_preChildrenUpdate(dt)       -- 3. Hook (Container sorts here)
    for child in children do          -- 4. Children update
        child:update(dt, true)
    end
    self:onUpdate(dt)                 -- 5. Self update
end
```

### Event Propagation

Events traverse children from last to first (reverse order). If a child returns `true`, the event is consumed and does not propagate to earlier siblings. The widget's own handler runs only after all children have been given a chance.

### Raycast Target Fallback

After recursing children and trying the self handler, `handleEvent` has a fallback: if `raycast_target == true` and the mouse is within `regionDetection`, return `true` to block penetration.

**Note**: `WheelMoved` is excluded from this fallback — scroll events should pass through to scrollable parents.

## Child Management

| Method | Description |
|--------|-------------|
| `addChild(child)` | Add child (auto-detects circular references, removes from old parent, propagates attached state) |
| `removeChild(child)` | Remove child |
| `removeAllChildren()` | Remove all children (preserves widget objects, no destroy) |
| `clearChildren()` | Remove and recursively destroy all children (frees GPU resources). Use for panel rebuilds |

> **Best Practice**: Use `removeAllChildren` for content switching (TabView, ListContainer). Use `clearChildren` for complete teardown (test scene switching).

## Size Measurement

| Method | Description |
|--------|-------------|
| `getMinimumSize()` | Return content minimum natural size. Default `(0, 0)`. Override for content-based sizing |
| `getCombinedMinimumSize()` | `max(getMinimumSize(), custom_minimum)` — what containers use |
| `setCustomMinimumSize(w, h)` | Set custom minimum size override (`nil` = no constraint) |
| `getDesiredSize()` | Desired natural size, defaults to `getCombinedMinimumSize()`. Text overrides for full text width |
| `measure(max_w, max_h)` | Query natural size, returns `{w, h}`. Default: current transform size |

> **Important**: A plain Widget with `h = 40` but no `getMinimumSize` override or `custom_minimum_size` may receive 0 height from a container. Button, Text, Image already override `getMinimumSize`. For custom widgets in containers, pass `custom_minimum_size` in datas or call `setCustomMinimumSize`.

## Show/Hide

| Method | Description |
|--------|-------------|
| `show()` | Show (invalidates render cache) |
| `hide()` | Hide (invalidates render cache) |
| `isShown()` | Whether visible |

## Enable/Disable

| Method | Description |
|--------|-------------|
| `enable()` | Enable (triggers `onEnabled`) |
| `disable()` | Disable (triggers `onDisabled`) |
| `isEnabled()` | Whether enabled |

## Focus

| Method | Description |
|--------|-------------|
| `setFocus()` | Request focus |
| `removeFocus()` | Remove focus |
| `isFocus()` | Whether focused |

## Z-Order

| Method | Description |
|--------|-------------|
| `moveToTop()` | Move to top of sibling list (drawn last) |
| `moveToBottom()` | Move to bottom of sibling list (drawn first) |

## Event Handlers

Override these methods (naming: `on` + PascalCase event name):

| Handler | Trigger |
|---------|---------|
| `onUpdate(dt)` | Every frame (after children) |
| `onDraw()` | Self-draw (before children) |
| `onPostDraw()` | After children draw |
| `onMousePressed(x, y, button)` | Mouse press |
| `onMouseReleased(x, y, button)` | Mouse release |
| `onMouseMoved(x, y, dx, dy)` | Mouse move |
| `onWheelMoved(x, y)` | Mouse wheel |
| `onKeyPressed(key, isrepeat)` | Key press |
| `onKeyReleased(key)` | Key release |
| `onTextInput(text)` | Text input |
| `onFocus()` | Focus gained |
| `onRemoveFocus()` | Focus lost |
| `onEnabled()` | Enabled |
| `onDisabled()` | Disabled |
| `onSizeChanged(w, h)` | Size changed (requires `enableSizeChangedEvent(true)`) |
| `onHovered(hovered, x, y, dx, dy)` | Mouse enter/leave (requires `Components.addHoverState`) |

## SizeFlags

Each Widget holds layout flags read by parent containers:

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `h_size_flags` | number | `FILL` (1) | Horizontal size flags |
| `v_size_flags` | number | `FILL` (1) | Vertical size flags |
| `stretch_ratio` | number | `1.0` | Distribution weight when EXPAND is set |

Flags are combined via addition and tested with `Utils.hasFlag(flags, flag)`.

## Lifecycle

| Method/Hook | Description |
|-------------|-------------|
| `onAttached()` | Called when entering UiManager's active tree |
| `onDetached()` | Called when leaving the active tree |
| `destroy()` | Recursively destroy self and descendants, remove from parent |
| `isValid()` | Check if valid (not destroyed) |

## Culling

| Method | Description |
|--------|-------------|
| `getCullAABB()` | Returns AABB for visibility culling. Text overrides for actual text size |
| `_clip_rect` | Internal, set by Scroll etc., passed to children for AABB culling |
| `always_draw` | Set `true` to skip visibility culling |

## Debug

```lua
widget:enableDebug(true)  -- Enable debug drawing (bounds + pivot), returns self for chaining
```

## Properties

| Property | Type | Description |
|----------|------|-------------|
| `transform` | Transform | Layout transform instance |
| `theme` | Theme | Current theme |
| `children` | table | Child widget array |
| `parent` | Widget/nil | Parent widget |
| `enabled` | boolean | Enabled state |
| `shown` | boolean | Visibility state |
| `focus` | boolean | Focus state |
| `focusable` | boolean | Can receive focus via Tab |
| `raycast_target` | boolean | Raycast fallback switch |
| `render_layer` | number | Render layer (0=BASE, 50=OVERLAY, 80=DROPDOWN, 100=TOOLTIP) |

## Example

```lua
local Utils = require "ui.utils"

-- Custom widget in a container with explicit minimum height
local spacer = Widget({
    h = 40,
    custom_minimum_size = {nil, 40},
    v_size_flags = 0,  -- SHRINK_BEGIN: don't fill
})
```

## Best Practices

- **Do**: Always set `custom_minimum_size` or override `getMinimumSize` for custom widgets placed in containers.
- **Do**: Use `removeAllChildren` for content switching, `clearChildren` for teardown.
- **Do**: Set `raycast_target = false` on internal Text/Panel children of composite widgets to avoid stealing events from the parent.
- **Don't**: Perform layout logic in `onUpdate` — containers should use `_preChildrenUpdate`.
- **Don't**: Rely on `transform.w/h` for Text's actual dimensions — use `getDimensions()`.
