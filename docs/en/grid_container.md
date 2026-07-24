# GridContainer

Fixed-column grid layout container.

**Inheritance:** `Widget` → `Container` → `GridContainer`

## Constructor Parameters (datas)

```lua
{
    columns = number,         -- Column count, default 2
    h_separation = number,    -- Column spacing, default 0
    v_separation = number,    -- Row spacing, default 0
}
```

## How It Works

Uses a three-pass allocation algorithm:

1. **Collect**: Scans children grouped by row/column, collecting per-column max min_w/desired_w and per-row max min_h/desired_h.
2. **Allocate**: Distributes remaining space first by desired ratio, then by EXPAND. Columns/rows that can't fit their minimum are removed from the EXPAND pool; those exceeding max are also removed.
3. **Position**: Calls `fitChildInRect` for each child using final column widths and row heights.

## Public Methods

| Method | Description |
|--------|-------------|
| `setColumns(n)` | Set column count |

## Example

```lua
local grid = GridContainer({
    columns = 3,
    h_separation = 8,
    v_separation = 8,
})
for i = 1, 9 do
    grid:addChild(Button({ text = tostring(i) }))
end
```
