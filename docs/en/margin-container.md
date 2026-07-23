# MarginContainer

Adds pixel margins around children. The simplest container: subtracts four margin values from its own size, placing children in the remaining area.

**Inheritance chain:** `Widget` → `Container` → `MarginContainer`

## Constructor Parameters (datas)

```lua
{
    margin_left = number,    -- left margin (pixels), default 0
    margin_right = number,   -- right margin (pixels), default 0
    margin_top = number,     -- top margin (pixels), default 0
    margin_bottom = number,  -- bottom margin (pixels), default 0
    -- ... also inherits all Container / Widget base parameters
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `getMinimumSize()` | Child minimum size + four margins |

## Example

```lua
local margin = MarginContainer({
    margin_left = 10,
    margin_right = 10,
    margin_top = 5,
    margin_bottom = 5,
    anchor = {0, 0, 1, 1},
})
margin:addChild(Button({ text = "Wrapped", h = 40 }))
```
