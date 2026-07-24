# Container (Base Class)

Base class for all containers. Children inside a Container surrender their own positioning rights — the container manages their positions and sizes uniformly.

**Inheritance:** `Widget` → `Container`

## Core Contract

- `addChild` / `removeChild` auto-trigger `queueSort()`. The next frame's `_preChildrenUpdate` calls `_sortChildren()`.
- Subclasses override `_sortChildren()` and call `fitChildInRect(child, x, y, w, h)` to position each child.
- Containers override `_preChildrenUpdate` (not `onUpdate`), ensuring sorting happens before children update.

## Constructor Parameters (datas)

```lua
{
    auto_size = boolean,     -- Auto-resize to children's min size after each sort, default false
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `queueSort()` | Mark dirty; next frame's `_preChildrenUpdate` calls `_sortChildren()` |
| `fitChildInRect(child, x, y, w, h)` | Place child in a rectangle, honoring its `h_size_flags` / `v_size_flags` |
| `_visibleChildren()` | Return visible (`isShown() == true`) children |

### Methods to Override

| Method | Description |
|--------|-------------|
| `_sortChildren()` | Implement the layout algorithm |
| `getMinimumSize()` | Report container minimum size. Default: own transform size |
| `_getChildrenMinSize()` | Pure child-derived minimum size (no container cap), used for change detection |

## fitChildInRect Behavior

```
FILL: child fills the allocated rectangle (default)
Non-FILL: child keeps minimum size, positioned per SHRINK_BEGIN/CENTER/END
```

## Change Detection

`_preChildrenUpdate` polls each frame. Triggers resort on:
1. `_dirty` flag (set by `queueSort()`)
2. Container size change
3. `_getChildrenMinSize()` change

Uses `_getChildrenMinSize()` instead of `getMinimumSize()` to avoid BoxContainer's `math.max(children, container_size)` masking child growth when the container itself is large.

## auto_size

When enabled, the container adjusts its own size along the main axis to match `_getChildrenMinSize()` after each resort. Requires subclasses to set `_auto_size_axis`.

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
