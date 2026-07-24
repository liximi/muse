# Container (Base Class)

Base class for all containers. Children surrender autonomous positioning to the container, which manages their positions and sizes via `_sortChildren()`.

**Inheritance:** `Widget` → `Container`

## Core Contract

- `addChild` / `removeChild` automatically call `queueSort()`. The next frame's `_preChildrenUpdate` invokes `_sortChildren()`.
- Subclasses only need to override `_sortChildren()`, calling `fitChildInRect(child, x, y, w, h)` for each child.
- Container overrides `_preChildrenUpdate` (not `onUpdate`), ensuring sorting occurs before children update so they receive correct sizes that same frame.

## Constructor Parameters (datas)

```lua
{
    auto_size = boolean,     -- Auto-adjust own size to children's minimum size after each sort, default false
}
```

## How It Works

### fitChildInRect

The core child placement method. Places a child into a given rectangle, deciding Fill vs Shrink behavior based on `h_size_flags` / `v_size_flags`:

- **FILL**: Child size equals the rectangle size (fills the area).
- **Non-FILL**: Child size is clamped to `[minsize, min(desired, rect_size)]` and positioned within the rectangle according to `SHRINK_BEGIN`/`SHRINK_CENTER`/`SHRINK_END`.

After setting the size, immediately calls `_notifySizeChanged` so widgets like Text can reflow before the container continues positioning remaining children.

### Change Detection

`_preChildrenUpdate` checks the following each frame; any change triggers `_sortChildren()`:

1. `_dirty` flag (set by `queueSort()`)
2. Container size `w` / `h` changed
3. `_getChildrenMinSize()` return value changed

`_getChildrenMinSize()` is used instead of `getMinimumSize()` for detection because BoxContainer's `getMinimumSize()` returns `math.max(children, container_size)` — when the container is stretched by anchors, child size growth can be masked by the container's large size. `_getChildrenMinSize()` returns the raw child-derived value.

### auto_size

When enabled, automatically adjusts own size to `_getChildrenMinSize()` after each sort. `_auto_size_axis` (set by subclasses in the constructor) determines which axis: `"h"` adjusts width, `"v"` adjusts height.

## Public Methods

| Method | Description |
|--------|-------------|
| `queueSort()` | Mark dirty, auto-sort next frame |
| `fitChildInRect(child, x, y, w, h)` | Place child in a rectangle, applying SizeFlags Fill/Shrink |
| `_visibleChildren()` | Return visible children list |
| `getInnerCombinedMaximumSize()` | Return max available inner size (after subtracting decoration) |
| `getDesiredSize()` | Desired size, defaults to `getMinimumSize()` |

## Methods to Override

| Method | Description |
|--------|-------------|
| `_sortChildren()` | Implement layout algorithm |
| `getMinimumSize()` | Report container minimum size |
| `_getChildrenMinSize()` | Return raw child-derived minimum size (without container cap) |
| `_getAllowedSizeFlagsHorizontal()` | Return allowed horizontal size_flags for children |
| `_getAllowedSizeFlagsVertical()` | Return allowed vertical size_flags for children |

## Example: Custom Container

```lua
local Container = require "ui.widgets.containers.container"
local Class = require "dependencies.classic"

local MyContainer = Class(Container, function(self, datas, theme)
    Container.new(self, "MyContainer", datas, theme)
    self._auto_size_axis = "v"
end)

function MyContainer:getMinimumSize()
    local mw, mh = 0, 0
    for _, c in ipairs(self.children) do
        if c:isShown() then
            local cw, ch = c:getCombinedMinimumSize()
            mw, mh = math.max(mw, cw), math.max(mh, ch)
        end
    end
    return mw, mh
end

function MyContainer:_sortChildren()
    for _, c in ipairs(self:_visibleChildren()) do
        self:fitChildInRect(c, 0, 0, self.transform.w, self.transform.h)
    end
end
```

## Best Practices

- **Do**: Iterate `_visibleChildren()` instead of `self.children` in `_sortChildren` to automatically skip hidden widgets.
- **Do**: Handle two-pass sorting — child sizes may change after `fitChildInRect` (e.g., text wrapping triggers reflow).
- **Don't**: Manipulate child positions directly in `onUpdate` — use `_sortChildren` to let the framework call it at the right time.
