# Spacer

Invisible elastic spacer (mirrors Godot `BoxContainer::add_spacer`). Mouse events pass through. Both axes set to `EXPAND + FILL`.

**Inheritance chain:** `Widget` → `Spacer`

No constructor parameters.

## Usage

```lua
local hbox = BoxContainer({ orientation = "horizontal" })
hbox:addChild(Button({ text = "Left", w = 80 }))
hbox:addChild(Spacer())  -- pushes subsequent children to the right
hbox:addChild(Button({ text = "Right", w = 80 }))
```

Or use the `BoxContainer:addSpacer()` convenience method.

## Properties

| Property | Value | Description |
|----------|-------|-------------|
| `h_size_flags` | `FILL + EXPAND` (3) | Grabs horizontal space |
| `v_size_flags` | `FILL + EXPAND` (3) | Grabs vertical space |
| `stretch_ratio` | `1.0` | Division ratio |
| `raycast_target` | `false` | Mouse events pass through |
