# Transform

Layout Transform system. Manages UI element position, size, anchors, pivot, scale, and rotation.

## Design Principle

**Padding is the single source of truth**. All setters (setPosition, setSize, setAnchor, setPivot) ultimately write to `left`/`right`/`top`/`bottom` fields. `_recalcLayout` derives cached `x`/`y`/`w`/`h` values from these four fields plus anchor and pivot.

## Core Fields

| Field | Type | Description |
|-------|------|-------------|
| `x`, `y` | number | Cache: position (pivot coordinates) |
| `w`, `h` | number | Cache: size |
| `left`, `right`, `top`, `bottom` | number | Truth source: edge margins |
| `anchor_min` | {number, number} | Anchor min ratio (0~1) |
| `anchor_max` | {number, number} | Anchor max ratio (0~1) |
| `pivot` | {number, number} | Pivot (own-size ratio 0~1) |
| `rotation` | number | Rotation (radians) |
| `scale_x`, `scale_y` | number | Scale factors |
| `parent` | Transform/nil | Parent Transform reference |

## Anchor Mechanism

The anchor range `(anchor_min, anchor_max)` defines the child's positioning reference relative to its parent. When both are equal, it's a point anchor (child does not stretch with parent). When they differ, it's a stretch anchor (child auto-adapts to parent).

```
child x = left + w × pivot[1]
child y = top + h × pivot[2]
child w = parent_w × (anchor_max[1] - anchor_min[1]) - left - right
child h = parent_h × (anchor_max[2] - anchor_min[2]) - top - bottom
```

## Public Methods

| Method | Description |
|--------|-------------|
| `setPosition(x, y)` | Set position (nil = no change) |
| `setSize(w, h)` | Set size (nil = no change) |
| `setPadding(left, right, top, bottom)` | Set margins (nil = no change) |
| `setAnchor(minx, miny, maxx, maxy)` | Set anchor |
| `setPivot(px, py)` | Set pivot |
| `setScale(sx, sy)` | Set scale |
| `setRotation(rad)` | Set rotation (auto-normalized to 0~2π) |
| `setParent(parent)` | Set parent Transform |
| `getPosition()` | Get position `x, y` |
| `getSize()` | Get size `w, h` |
| `getGlobalPosition()` | Get global (screen) coordinates |
| `getGlobalScale()` | Get accumulated global scale |
| `getGlobalScaledSize()` | Get globally scaled size |
| `getGlobalRotation()` | Get global rotation |
| `getAABB()` | Get axis-aligned bounding box (local) |
| `getGlobalAABB()` | Get axis-aligned bounding box (screen) |
| `screenToLocal(sx, sy)` | Screen coords → local coords |
| `onUpdate(force)` | Called each frame: checks dirty, recomputes cache if needed |

## Best Practices

- **Do**: Use stretch anchors (e.g., `{0, 0, 1, 1}`) for children to auto-adapt to parent size.
- **Do**: Use center pivot `{0.5, 0.5}` + center anchor `{0.5, 0.5, 0.5, 0.5}` for centered positioning.
- **Note**: During construction `parent_w == 0`; layout logic that depends on measure should go in the first frame's `onUpdate`.
