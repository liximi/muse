# CenterContainer

Centers all children within the container. Children keep their minimum size and are centered both horizontally and vertically.

**Inheritance chain:** `Widget` → `Container` → `CenterContainer`

## Constructor Parameters (datas)

```lua
{
    use_top_left = boolean,  -- when true, aligns children to top-left (plain container), default false
    -- ... also inherits all Container / Widget base parameters
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `getMinimumSize()` | Max of all child minimum sizes |

## Example

```lua
local center = CenterContainer({
    anchor = {0, 0, 1, 1},
})
-- Button will be centered, keeping its minimum size
center:addChild(Button({ text = "Centered Button" }))
```
