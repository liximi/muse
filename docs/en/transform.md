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

## Anchor Modes and Setter Pitfalls

### Behavioral Differences: Point Anchor vs. Stretch Anchor

| Anchor Mode | Primary Data | Derived Data |
|-------------|-------------|--------------|
| Point anchor (`min == max`) | `x`/`y`, `w`/`h` | `left/right/top/bottom` |
| Stretch anchor (`min < max`) | `left/right/top/bottom` | `x`/`y`, `w`/`h` |

### Correct Handling

`_updateWidthAndX` / `_updateHeightAndY` internally check `anchor_w > 0`:
- In stretch anchor mode: derive size + position from padding
- In point anchor mode: only update `x = left + w * pivot_x`, size unchanged

### Datas Processing Order in Widget Construction

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
