# Spacer

An invisible, flexible spacer widget. Modeled after Godot's `Control` used as `add_spacer`.

**Inheritance:** `Widget` → `Spacer`

## Purpose

Spacer is an "air" widget — invisible (no `onDraw`), transparent to mouse events (`raycast_target = false`), with both axes set to `FILL + EXPAND`. In a BoxContainer, it consumes all remaining space, pushing subsequent children to the end of the main axis.

## Properties

| Property | Value | Description |
|----------|-------|-------------|
| `h_size_flags` | `FILL + EXPAND` (=3) | Fill and expand horizontally |
| `v_size_flags` | `FILL + EXPAND` (=3) | Fill and expand vertically |
| `stretch_ratio` | `1.0` | Distribution weight |
| `raycast_target` | `false` | Mouse events pass through |

## Example

```lua
-- VBox: push bottom button
local vbox = VBoxContainer({ anchor = {0, 0, 1, 1} })
vbox:addChild(Button({ text = "Top" }))
vbox:addSpacer()  -- equivalent to vbox:addChild(Spacer())
vbox:addChild(Button({ text = "Bottom" }))

-- Multiple spacers with different ratios
local sp1 = Spacer({ stretch_ratio = 1.0 })
local sp2 = Spacer({ stretch_ratio = 2.0 })  -- takes twice as much space
```

## Best Practices

- Prefer `box:addSpacer()` over `box:addChild(Spacer())`.
- Multiple Spacers with different `stretch_ratio` values enable non-uniform distribution (e.g. 1:2:1 three-column layout).
