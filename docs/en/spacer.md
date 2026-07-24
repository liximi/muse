# Spacer

Invisible elastic placeholder widget. Equivalent to Godot's `Spacer`.

**Inheritance:** `Widget` → `Spacer`

## How It Works

Defaults to `h_size_flags = FILL + EXPAND`, `v_size_flags = FILL + EXPAND`, `stretch_ratio = 1.0`. When placed in a BoxContainer, it absorbs all remaining space and pushes subsequent children to the end of the main axis.

`raycast_target = false` — mouse events pass through.

## Example

```lua
-- Push "Footer" button to the bottom
local vbox = VBoxContainer({ anchor = {0, 0, 1, 1} })
vbox:addChild(Button({ text = "Header" }))
vbox:addChild(Spacer())
vbox:addChild(Button({ text = "Footer" }))

-- Recommended shorthand
vbox:addSpacer()  -- Equivalent to vbox:addChild(Spacer())
```
