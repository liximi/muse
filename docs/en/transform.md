# Transform Layout System

Transform is the core layout engine. Each widget holds a Transform instance handling position, size, rotation, and scale. The design is modeled after Unity's anchor-based layout.

## Core Concepts

### Anchor

Defines the element's positioning reference within its parent. Four 0~1 percentage values `{minx, miny, maxx, maxy}`:

| Mode | Condition | Meaning |
|------|-----------|---------|
| **Point anchor** | `min == max` | Fixed size (`w`/`h`), position from `x`/`y` offset |
| **Stretch anchor** | `min < max` | Adaptive size (anchor range minus padding), `x`/`y` derived |

### Pivot

`{x, y}` — 0~1 percentage, origin of the element's own coordinate system. Also the center of rotation and scaling.

### Padding — Single Source of Truth

`{left, right, top, bottom}` — pixel offsets. All setters (`setPosition`, `setSize`, `setPivot`, `setPadding`) ultimately write to these four fields. `x`/`y`/`w`/`h` are derived cache values.

```
Config layer: anchor_min, anchor_max (0~1 parent percentage)
              pivot (0~1 self percentage)
Truth source: left, right, top, bottom (pixel offsets)
Cache layer: x, y, w, h (derived by _recalcLayout)
```

Core formula:
```lua
w = parent_w * (anchor_max_x - anchor_min_x) - left - right
h = parent_h * (anchor_max_y - anchor_min_y) - top - bottom
x = left + w * pivot_x
y = top  + h * pivot_y
```

Point anchors (`min == max`) give `anchor_w == 0`. `_recalcLayout` only recalculates size when `anchor_w > 0`, preserving `setSize` values otherwise. During construction when `parent_w == 0`, size calculation is also skipped to avoid negative sizes.

### Setter Invariants

Each setter updates both padding edges on the same axis simultaneously, keeping "change A, B stays unchanged":
- `setPosition(x)` → updates both `left` and `right`, keeps `w`
- `setSize(w)` → updates both `left` and `right`, keeps `x`
- `setPivot(px)` → updates both `left` and `right`, keeps both `x` and `w`

### Widget datas Processing Order

```
pivot → anchor → position → padding → size
```

Later setters overwrite earlier padding values.

## Usage Examples

```lua
-- Full-screen fill
local fullscreen = Widget({
    anchor = {0, 0, 1, 1},
    padding = {10, 10, 10, 10},
})

-- Centered, fixed size
local centered = Widget({
    pivot = {0.5, 0.5},
    anchor = {0.5, 0.5, 0.5, 0.5},
    w = 200, h = 100,
})

-- Top bar, horizontal stretch, fixed height
local topbar = Widget({
    anchor = {0, 0, 1, 0},
    h = 48,
})
```

> **Note**: Text's `transform.w/h` defaults to 0 (size stored in `love.graphics.Text` object). Text overrides `getCullAABB()` for correct clipping, but debug bounds may show zero area.
