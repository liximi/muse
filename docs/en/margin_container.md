# MarginContainer

Adds pixel margins around child widgets. Equivalent to Godot's `MarginContainer`.

**Inheritance:** `Widget` → `Container` → `MarginContainer`

## Constructor Parameters (datas)

```lua
{
    margin_left   = number,  -- Left margin, default 0
    margin_right  = number,  -- Right margin, default 0
    margin_top    = number,  -- Top margin, default 0
    margin_bottom = number,  -- Bottom margin, default 0
}
```

## How It Works

`_sortChildren()` subtracts the four margins from the container size, then calls `fitChildInRect` to place all children in the remaining area. `getMinimumSize()` = max child minimum size + margins.

## Example

```lua
local margin = MarginContainer({
    margin_left = 16, margin_right = 16,
    margin_top = 8, margin_bottom = 8,
})
margin:addChild(Button({ text = "Padded" }))
```
