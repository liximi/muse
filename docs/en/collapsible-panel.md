# CollapsiblePanel (Advanced Component)

A horizontally screen-edge-docked collapsible panel that expands/collapses with an `outQuint` easing animation when the fold button is clicked.

**Inheritance chain:** `Widget` → `Panel` → `CollapsiblePanel`

## Constructor Parameters (datas)

```lua
{
    right = boolean,  -- whether docked to the right screen edge, default false (left side)
    -- ... also inherits all Panel parameters
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `toggleOpen()` | Toggle expand/collapse state (with easing animation) |
| `setMode(right)` | Set dock mode: `false`=left, `true`=right |

## Behavior

- When expanded, the panel edge is flush with the screen edge
- When collapsed, the panel slides off-screen (only the fold button remains visible)
- Fold button icon auto-adapts to direction (left/right arrows)
- Animation duration: 0.3 seconds, using `outQuint` easing

## Properties

| Property | Description |
|----------|-------------|
| `open` | Whether currently expanded |
| `right` | Current dock mode |

## Example

```lua
local panel = CollapsiblePanel({
    right = true,  -- right-side dock
    w = 300,
    bg_color = Utils.RGB(40, 40, 50),
    rounding_radius = 8,
})

-- Click fold button to toggle expand/collapse
panel.collapse_btn.onClick = function()
    panel:toggleOpen()
end
```
