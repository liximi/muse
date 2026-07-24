# CenterContainer

Centers child widgets within the container. Equivalent to Godot's `CenterContainer`.

**Inheritance:** `Widget` → `Container` → `CenterContainer`

## Constructor Parameters (datas)

```lua
{
    use_top_left = boolean,  -- When true, aligns top-left instead of center, default false
}
```

## How It Works

`_sortChildren()` computes the child's minimum size and centers it within the container, maximizing the allocated area width to prevent premature text wrapping. `use_top_left = true` disables centering for top-left alignment.

## Example

```lua
local center = CenterContainer({ w = 200, h = 100 })
center:addChild(Text({ text = "Centered" }))
```
