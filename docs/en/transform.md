# Transform Layout System

Transform is the core layout engine of this UI framework. Each widget holds a Transform instance to handle position, size, rotation, and scaling. Its design is similar to Unity's anchor-based layout system.

## Core Concepts

### Anchor

Anchors define an element's positioning reference within its parent container, expressed as a range of four 0~1 percentage values `{minx, miny, maxx, maxy}`:

| Anchor Mode | Condition | Meaning |
|-------------|-----------|---------|
| **Point anchor** | `min == max` | Fixed size (`w`/`h`); position determined by `x`/`y` offset |
| **Stretch anchor** | `min < max` | Adaptive size (determined by anchor range minus padding); `x`/`y` are derived values |

### Pivot

`{x, y}` — 0~1 percentage, representing the origin of the element's own coordinate space, and also the center for rotation and scaling.

- `{0, 0}` = top-left corner
- `{0.5, 0.5}` = center
- `{1, 1}` = bottom-right corner

### Padding

`{left, right, top, bottom}` — pixel offsets representing the distance from the element's edges to the anchor range edges.

## Constructor Parameters (passed directly to `Transform()`)

```lua
{
    x = 0,              -- pivot offset from left edge of anchor range (pixels)
    y = 0,              -- pivot offset from top edge of anchor range (pixels)
    w = 0,              -- width (pixels)
    h = 0,              -- height (pixels)
    rotation = 0,       -- rotation angle (radians)
    scale_x = 1,        -- horizontal scale
    scale_y = 1,        -- vertical scale
    anchor_min = {0, 0},-- anchor top-left corner (percentage)
    anchor_max = {0, 0},-- anchor bottom-right corner (percentage)
    pivot = {0, 0},     -- pivot (percentage)
    left = 0,           -- left edge to anchor left side distance (pixels)
    right = 0,          -- right edge to anchor right side distance (pixels)
    top = 0,            -- top edge to anchor top side distance (pixels)
    bottom = 0,         -- bottom edge to anchor bottom side distance (pixels)
    r = 0,              -- rotation angle (radians)
}
```

## Public Methods

### Setters

| Method | Description |
|--------|-------------|
| `setPosition(x, y)` | Set position; also affects padding |
| `setSize(w, h)` | Set size; also affects padding |
| `setPadding(left, right, top, bottom)` | Set padding; also affects position and size |
| `setScale(sx, sy)` | Set scale |
| `setPivot(px, py)` | Set pivot while keeping the visual position unchanged (affects position) |
| `setAnchor(minx, miny, maxx, maxy)` | Set anchor; auto-updates position or size based on mode |
| `setRotation(rot)` | Set rotation angle (radians) |
| `setParent(parent_transform)` | Set parent Transform (normally managed automatically by the widget tree) |

### Getters (local coordinates)

| Method | Returns |
|--------|---------|
| `getPosition()` | `x, y` |
| `getSize()` | `w, h` |
| `getScale()` | `scale_x, scale_y` |
| `getScaledSize()` | `w * scale_x, h * scale_y` |
| `getAnchor()` | `minx, miny, maxx, maxy` |
| `getPivot()` | `px, py` |
| `getPadding()` | `{left, right, top, bottom}` |
| `getRotation()` | radians |
| `getAABB()` | local AABB `x, y, w, h` (accounts for rotation) |
| `getBounds()` | local bounding box `x, y, w, h, r` |

### Getters (global coordinates)

| Method | Returns |
|--------|---------|
| `getGlobalPosition()` | screen coordinates `x, y` (recursively computed through parents, accounts for rotation) |
| `getGlobalScale()` | cumulative scale `sx, sy` |
| `getGlobalScaledSize()` | globally scaled size `w, h` |
| `getGlobalRotation()` | cumulative rotation angle (radians) |
| `getGlobalAABB()` | global AABB `x, y, w, h` |
| `getGlobalBounds()` | global bounding box `x, y, w, h, r` |

### Other

| Method | Description |
|--------|-------------|
| `screenToLocal(screen_x, screen_y)` | Convert screen coordinates to local coordinates (accounts for global rotation and scale) |
| `onUpdate(force)` | Update layout calculation (internally cached; skipped when parameters are unchanged) |

## Anchor Modes and the Unified Truth Source

Transform's layout system is based on **padding as the single source of truth** (similar to Unity UGUI's offsetMin/offsetMax):

```
Field layers:
  Config:  anchor_min, anchor_max (anchor range, 0~1 parent percentage)
           pivot (pivot point, 0~1 self percentage)
  Truth:   left, right, top, bottom (pixel offsets — all setters ultimately write here)
  Cache:   x, y, w, h (derived from truth by _recalcLayout, read-only)
```

Core formula (shared by both point and stretch anchors, no branching):
```lua
w = parent_w * (anchor_max_x - anchor_min_x) - left - right
h = parent_h * (anchor_max_y - anchor_min_y) - top - bottom
x = left + w * pivot_x
y = top  + h * pivot_y
```

For point anchors (`min == max`), `anchor_w == 0` and the formula naturally degrades to `w = -left - right`.
`_recalcLayout` only recalculates size when `anchor_w > 0`; otherwise it preserves the value set by `setSize`.

### Setter Invariants

Each setter updates both padding values on the same axis to preserve "when changing A, keep B unchanged":
- `setPosition(x)` → updates both `left` and `right`, preserving `w`
- `setSize(w)`    → updates both `left` and `right`, preserving `x`
- `setPivot(px)`  → updates both `left` and `right`, preserving both `x` and `w`
- `setPadding(...)` → writes directly to truth source
- `setAnchor(...)` → writes config layer, triggers recalculation

### Protection During Construction (`parent_w == 0`)

During widget construction the parent size is not yet available. `setPadding` triggers `_recalcLayout` but `aw == 0`,
so the guard skips size calculation, preventing negative sizes. Layout logic that depends on `measure()` should be deferred to the first frame's `onUpdate`.

### Datas Processing Order in Widget Construction

```
pivot → anchor → position → padding → size
```

Later setters override earlier padding values, matching the intuition of "position for placement, size for dimensions".

> **Note**: Text's `transform.w/h` defaults to 0 (dimensions stored in `love.graphics.Text`, not transform).
> Text overrides `Widget:getCullAABB()` for correct culling, but debug boxes (`drawBound`) still show zero-area for Text.

```
anchor → position → size → padding
```

`setPadding` is called last; in point anchor mode it will not overwrite the size values set by `setSize`.

## Usage Examples

```lua
-- Fullscreen-filling widget
local fullscreen = Widget({
    anchor = {0, 0, 1, 1},  -- stretch anchor fills parent container
    padding = {10, 10, 10, 10}  -- 10px margin on all sides
})

-- Centered fixed-size widget
local centered = Widget({
    pivot = {0.5, 0.5},       -- use own center as origin
    anchor = {0.5, 0.5, 0.5, 0.5},  -- point anchor at parent center
    w = 200,
    h = 100
})

-- Top bar: horizontally stretched, fixed height
local topbar = Widget({
    anchor = {0, 0, 1, 0},  -- horizontal stretch, top edge fixed
    h = 48
})
```
