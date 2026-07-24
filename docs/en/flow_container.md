# FlowContainer

Flow-wrap layout container. Children are arranged along the main axis and wrap to the next line/column when exceeding the container. Equivalent to CSS `flex-wrap`.

**Inheritance:** `Widget` → `Container` → `FlowContainer`

## Constructor Parameters (datas)

```lua
{
    orientation = "horizontal" | "vertical",  -- Main axis, default "horizontal"
    h_separation = number,   -- Column spacing, default 0
    v_separation = number,   -- Row spacing, default 0
    alignment = "begin" | "center" | "end",  -- In-line alignment, default "begin"
    last_wrap_alignment = "inherit" | "begin" | "center" | "end",  -- Last line alignment, default "inherit"
}
```

## How It Works

Uses a two-pass algorithm:
1. **Pass 1 (wrapping)**: Scans children along the main axis, accumulating width (or height); wraps when exceeding the container.
2. **Pass 2 (in-line allocation)**: EXPAND children in each line receive remaining space, then `alignment` offset is applied.

`last_wrap_alignment` controls alignment of the last (potentially unfilled) line:
- `"inherit"`: Follow `alignment`.
- `"begin"` / `"center"` / `"end"`: Independent specification for the last line.

EXPAND is disallowed on the cross axis (to avoid conflicts at wrap points).

## Public Methods

| Method | Description |
|--------|-------------|
| `getLineCount()` | Get current line count |
| `getLineMaxChildCount()` | Get max children per line |

## Example

```lua
local flow = FlowContainer({
    w = 300,
    h_separation = 8,
    v_separation = 8,
})
for i = 1, 10 do
    flow:addChild(Button({ text = "Item " .. i, h_size_flags = 0 }))
end
```
