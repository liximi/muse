# Container (Base Class)

Base class for all containers. Children entering a Container surrender positioning control — the container manages their positions and sizes via `_sortChildren()`.

**Inheritance chain:** `Widget` → `Container`

`addChild` / `removeChild` automatically trigger re-sort. Subclasses only need to override `_sortChildren()`, calling `fitChildInRect(child, x, y, w, h)` to position each child.

## Constructor Parameters (datas)

```lua
{
    auto_size = boolean,     -- auto-adjust size along main axis after each sort, default false
    -- ... also inherits all Widget base class parameters
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `queueSort()` | Mark dirty, auto-calls `_sortChildren()` next frame in `_preChildrenUpdate` |
| `fitChildInRect(child, x, y, w, h)` | Place child in the given rectangle, following its `h_size_flags` / `v_size_flags` for Fill/Shrink behavior |
| `_sortChildren()` | Override in subclass to implement layout algorithm |
| `getMinimumSize()` | Override in subclass to report minimum container size. Default returns own transform size |
| `_getChildrenMinSize()` | Returns pure child-derived minimum size (without container cap), for change detection |
| `auto_size` | Property; when enabled, auto-resizes along main axis after each sort |

## SizeFlags — Child Layout Intent

Each Widget holds `h_size_flags`, `v_size_flags` (default `FILL`), and `stretch_ratio` (default 1.0):

| Flag | Value | Meaning |
|------|-------|---------|
| `SHRINK_BEGIN` | 0 | Keep minimum size, align to start (default) |
| `FILL` | 1 | Fill the allocated area |
| `EXPAND` | 2 | Grab remaining space |
| `SHRINK_CENTER` | 4 | Center within allocated area (disable FILL first) |
| `SHRINK_END` | 8 | Align end within allocated area (disable FILL first) |

Bit check: `Utils.hasFlag(flags, flag)`.

### Example: Set child behavior in containers

```lua
-- Let child grab remaining space
child.h_size_flags = Utils.SIZE_FLAGS.FILL + Utils.SIZE_FLAGS.EXPAND
child.stretch_ratio = 2.0  -- takes 2 shares when dividing

-- Keep minimum size, center in area
child.h_size_flags = Utils.SIZE_FLAGS.SHRINK_CENTER  -- note: this disables FILL
child:setCustomMinimumSize(100, nil)
```

## fitChildInRect Behavior

```
FILL: child fills the allocated rectangle (default)
Non-FILL: child keeps minimum size, positioned by SHRINK_BEGIN/CENTER/END within the area
```

All Widgets default to `h_size_flags = FILL`, `v_size_flags = FILL`.

## Change Detection

`_preChildrenUpdate` polls `_getChildrenMinSize()` each frame. Re-sorts when the container size or child minimum sizes change.

## Example: Custom Container

```lua
local Container = require "ui.widgets.containers.container"
local MyContainer = Class(Container, function(self, datas, theme)
    Container.new(self, "MyContainer", datas, theme)
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
