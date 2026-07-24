# Utils — Constants, Enums & Utility Functions

Core utility module (`ui/utils.lua`). Provides all enum constants, color utilities, and helper functions. `Components` module (`ui/components.lua`) provides widget mixins and style application.

## Enum Constants

### RENDER_LAYERS

```lua
BASE = 0, OVERLAY = 50, DROPDOWN = 80, TOOLTIP = 100
```

### ORIENTATION

```lua
VERTICAL = "vertical", HORIZONTAL = "horizontal"
```

### SIZE_FLAGS — Container child layout flags

| Flag | Value | Meaning |
|------|-------|---------|
| `SHRINK_BEGIN` | 0 | Minimum size, align left/top |
| `FILL` | 1 | Fill allocated area |
| `EXPAND` | 2 | Participate in space distribution |
| `SHRINK_CENTER` | 4 | Center within area (disable FILL) |
| `SHRINK_END` | 8 | Align right/bottom (disable FILL) |

Compose: `Utils.SIZE_FLAGS.FILL + Utils.SIZE_FLAGS.EXPAND` = `3`.

### ALIGNMENT

```lua
BEGIN = "begin", CENTER = "center", END = "end"
```

### BTN_STATES — Button states

```lua
NORMAL, PRESSED, DISABLED, SELECTED, HOVER, SELECTED_HOVER
```

### H_ALIGN / V_ALIGN — Text alignment

```lua
H_ALIGN: LEFT, CENTER, RIGHT, JUSTIFY
V_ALIGN: TOP, CENTER, BOTTOM
```

### TEXT_WRAP_MODE / TEXT_OVERFLOW_MODE

```lua
TEXT_WRAP_MODE: OFF, DEFAULT
TEXT_OVERFLOW_MODE: NONE, CHAR
```

### CHECKBOX_STYLE

```lua
CHECKBOX = "checkbox", TOGGLE = "toggle"
```

## Color

### UI_COLORS — Preset palette

```lua
Utils.UI_COLORS.WHITE / BG / SURFACE / LINE
Utils.UI_COLORS.TITLE / PRIMARY_TEXT / SECONDARY_TEXT / HINT
Utils.UI_COLORS.BTN_NORMAL / BTN_HOVER / BTN_DISABLED
Utils.UI_COLORS.BTN_SELECTED / BTN_SELECTED_HOVER
Utils.UI_COLORS.ACCENT / ACCENT_LIGHT / WARNING
```

### Utils.RGB(r, g, b, a)

0–255 → `{r, g, b, a}` (0–1). `a` defaults to 1.

```lua
Utils.RGB(255, 128, 64)  -- → {1, 0.502, 0.251, 1}
```

## Utility Functions

| Function | Description |
|----------|-------------|
| `Utils.clamp(val, min, max)` | Clamp to range |
| `Utils.validateEnum(value, enum, default, label)` | Validate enum; nil → silent default, invalid → warn + fallback |
| `Utils.hasFlag(flags, flag)` | LuaJIT-compatible bit test |
| `Utils.newButtonStateStyle(...)` | Create Button state style table |
| `Utils.newImageButtonStateStyle(...)` | Create ImageButton state style table |

## Components

`ui/components.lua`:

### addHoverState(widget)

Mix hover detection into any Widget. Adds `hovered` property and `onHovered(hovered, x, y, dx, dy)` callback. Preserves original `onMouseMoved`.

### applyButtonTextStyle / applyButtonTransform

Internal helpers used by Button/ImageButton during state transitions.
