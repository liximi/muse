# Utils

Utility functions and enum constants module.

## Enum Constants

### SIZE_FLAGS

Child widget size behavior flags in containers, combinable via bitwise addition:

| Flag | Value | Meaning |
|------|-------|---------|
| `SHRINK_BEGIN` | 0 | Keep minimum size, align start |
| `FILL` | 1 | Fill the allocated area |
| `EXPAND` | 2 | Participate in remaining space distribution |
| `SHRINK_CENTER` | 4 | Center within area (requires FILL off) |
| `SHRINK_END` | 8 | Align end within area (requires FILL off) |

### ORIENTATION

```lua
Utils.ORIENTATION.VERTICAL    -- "vertical"
Utils.ORIENTATION.HORIZONTAL  -- "horizontal"
```

### ALIGNMENT

BoxContainer overall offset when no EXPAND children:

```lua
Utils.ALIGNMENT.BEGIN / CENTER / END
```

### H_ALIGN / V_ALIGN

Text / TextInput alignment:

```lua
Utils.H_ALIGN.LEFT / CENTER / RIGHT / JUSTIFY
Utils.V_ALIGN.TOP / CENTER / BOTTOM
```

### BTN_STATES

Button states:

```lua
Utils.BTN_STATES.NORMAL / HOVER / PRESSED / DISABLED / SELECTED / SELECTED_HOVER
```

### TEXT_WRAP_MODE

```lua
Utils.TEXT_WRAP_MODE.OFF      -- No wrapping
Utils.TEXT_WRAP_MODE.DEFAULT  -- Wrap at width
```

### SCROLL_MODE

```lua
Utils.SCROLL_MODE.DISABLED / AUTO / SHOW_ALWAYS / SHOW_NEVER / RESERVE
```

### RENDER_LAYERS

```lua
Utils.RENDER_LAYERS.BASE = 0
Utils.RENDER_LAYERS.OVERLAY = 50
Utils.RENDER_LAYERS.DROPDOWN = 80
Utils.RENDER_LAYERS.TOOLTIP = 100
```

## Utility Functions

| Function | Description |
|----------|-------------|
| `Utils.RGB(r, g, b, a)` | Convert 0~255 RGB to 0~1 `{r, g, b, a}` table |
| `Utils.clamp(val, min, max)` | Clamp value to [min, max] |
| `Utils.hasFlag(flags, flag)` | Check if a bit flag is set |
| `Utils.validateEnum(value, enum, default, label)` | Validate enum value; prints warning and returns default on invalid |
| `Utils.newButtonStateStyle(...)` | Construct button state style table |
| `Utils.newImageButtonStateStyle(...)` | Construct image button state style table |

### newButtonStateStyle

```lua
Utils.newButtonStateStyle(text, text_color, font_size, bg_color,
    outline_width, outline_color, offset, scale, rounding_radius)
```

Arguments are positional; pass `nil` to skip. The returned style table can be directly used in Button's `normal`/`hover` etc.

### newImageButtonStateStyle

```lua
Utils.newImageButtonStateStyle(texture, tint, text, text_color, font_size, offset, scale)
```

## Best Practices

- **Do**: Use enum constants instead of hardcoded strings (e.g., `Utils.ORIENTATION.VERTICAL` not `"vertical"`).
- **Do**: Use `Utils.hasFlag` instead of manual bitwise operations for SizeFlags.
- **Do**: Use `Utils.newButtonStateStyle(...)` for consistent button style construction.
