# Utils — Constants, Enums & Utilities

Muse core utility module (`ui/utils.lua`), providing all enum constants, color utilities, and helper functions. The `Components` module (`ui/components.lua`) provides widget mixins and style application.

---

## Contents

- [Enum Constants](#enum-constants)
- [Colors](#colors)
- [Utility Functions](#utility-functions)
- [Components](#components)

---

## Enum Constants

All constants are under the `Utils` table.

### RENDER_LAYERS — Render Layers

```lua
Utils.RENDER_LAYERS = {
    BASE     = 0,   -- default
    OVERLAY  = 50,  -- overlays
    DROPDOWN = 80,  -- dropdown popups
    TOOLTIP  = 100, -- tooltips (topmost)
}
```

Set `widget.render_layer = Utils.RENDER_LAYERS.TOOLTIP` to control draw order. Higher numbers draw later (on top).

### ORIENTATION — Orientation

```lua
Utils.ORIENTATION = {
    VERTICAL   = "vertical",
    HORIZONTAL = "horizontal",
}
```

Used by BoxContainer, ProgressBar, SliderBar.

### SIZE_FLAGS — Container Child Layout Flags

| Flag | Value | Meaning |
|------|-------|---------|
| `SHRINK_BEGIN` | 0 | Keep minimum size, align start (default) |
| `FILL` | 1 | Fill the allocated area |
| `EXPAND` | 2 | Grab remaining space |
| `SHRINK_CENTER` | 4 | Center within area (disable FILL first) |
| `SHRINK_END` | 8 | Align end within area (disable FILL first) |

Combinable: `Utils.SIZE_FLAGS.FILL + Utils.SIZE_FLAGS.EXPAND` = `3`.

```lua
child.h_size_flags = Utils.SIZE_FLAGS.FILL + Utils.SIZE_FLAGS.EXPAND
```

### ALIGNMENT — Container Alignment

```lua
Utils.ALIGNMENT = {
    BEGIN  = "begin",   -- align start
    CENTER = "center",  -- center
    END    = "end",     -- align end
}
```

Only effective when the container has no EXPAND children.

### BTN_STATES — Button States

```lua
Utils.BTN_STATES = {
    NORMAL        = "normal",
    PRESSED       = "pressed",
    DISABLED      = "disabled",
    SELECTED      = "selected",
    HOVER         = "hover",
    SELECTED_HOVER = "selected_hover",
}
```

Used as the `state` parameter in `Button:setStateStyle(state, style)`.

### H_ALIGN — Horizontal Alignment

```lua
Utils.H_ALIGN = {
    LEFT    = "left",
    CENTER  = "center",
    RIGHT   = "right",
    JUSTIFY = "justify",
}
```

Text, TextInput `h_align` parameter.

### V_ALIGN — Vertical Alignment

```lua
Utils.V_ALIGN = {
    TOP    = "top",
    CENTER = "center",
    BOTTOM = "bottom",
}
```

Text, TextInput `v_align` parameter.

### TEXT_WRAP_MODE — Text Wrap Mode

```lua
Utils.TEXT_WRAP_MODE = {
    OFF     = "off",      -- no wrapping
    DEFAULT = "default",  -- wrap at transform.w width
}
```

```lua
text:setWrapMode(Utils.TEXT_WRAP_MODE.OFF)
```

### TEXT_OVERFLOW_MODE — Text Overflow Mode

```lua
Utils.TEXT_OVERFLOW_MODE = {
    NONE = "none",  -- don't trim
    CHAR = "char",  -- trim character by character
}
```

### CHECKBOX_STYLE — Checkbox Styles

```lua
Utils.CHECKBOX_STYLE = {
    CHECKBOX = "checkbox",  -- square + checkmark
    TOGGLE   = "toggle",    -- sliding toggle
}
```

### CROSS_ALIGN — Cross-Axis Alignment (old Box, being deprecated)

```lua
Utils.CROSS_ALIGN = {
    STRETCH = "stretch",
    START   = "start",
    CENTER  = "center",
    END     = "end",
}
```

### ANCHORS_HORI / ANCHORS_VERT — Text Anchors (internal)

```lua
Utils.ANCHORS_HORI = { LEFT = "left", MIDDLE = "middle", RIGHT = "right" }
Utils.ANCHORS_VERT = { TOP = "top", MIDDLE = "middle", BOTTOM = "bottom" }
```

### TWO_PI

```lua
Utils.TWO_PI = math.pi * 2  -- for rotation angle normalization comparison
```

---

## Colors

### UI_COLORS — Preset Palette

```lua
Utils.UI_COLORS.WHITE            -- {1, 1, 1, 1}
Utils.UI_COLORS.BG               -- background (dark)
Utils.UI_COLORS.SURFACE          -- panel/card background
Utils.UI_COLORS.LINE             -- outline/separator

Utils.UI_COLORS.TITLE            -- title text (brightest)
Utils.UI_COLORS.PRIMARY_TEXT     -- body text
Utils.UI_COLORS.SECONDARY_TEXT   -- secondary text
Utils.UI_COLORS.HINT             -- placeholder hint

Utils.UI_COLORS.BTN_NORMAL       -- button default background
Utils.UI_COLORS.BTN_HOVER        -- button hover background
Utils.UI_COLORS.BTN_DISABLED     -- button disabled background
Utils.UI_COLORS.BTN_SELECTED     -- button selected background (semi-transparent blue)
Utils.UI_COLORS.BTN_SELECTED_HOVER  -- button selected+hover background

Utils.UI_COLORS.ACCENT           -- accent (blue)
Utils.UI_COLORS.ACCENT_LIGHT     -- light accent
Utils.UI_COLORS.WARNING          -- warning (yellow)

-- Legacy aliases (same colors)
Utils.UI_COLORS.PINK             -- → ACCENT
Utils.UI_COLORS.LIGHT_PINK       -- → ACCENT_LIGHT
Utils.UI_COLORS.BLUE             -- → ACCENT
Utils.UI_COLORS.LIGHT_BLUE       -- → ACCENT_LIGHT
Utils.UI_COLORS.YELLOW           -- → WARNING
```

Grayscale reference (0–255):

| Name | R | G | B | Usage |
|------|---|---|---|-------|
| light | 240 | 240 | 240 | Titles |
| light_gray1 | 200 | 200 | 200 | Body text |
| light_gray2 | 155 | 155 | 155 | Hints |
| light_gray3 | 100 | 100 | 100 | Secondary text |
| dark_gray1 | 70 | 70 | 70 | Separators/hover |
| dark_gray2 | 50 | 50 | 50 | Panel surfaces |
| dark_gray3 | 38 | 38 | 38 | Button default |
| dark | 26 | 26 | 26 | Background |

### Utils.RGB(r, g, b, a)

Converts 0–255 range colors to 0–1 range `{r, g, b, a}`.

```lua
Utils.RGB(255, 128, 64)        -- → {1, 0.502, 0.251, 1}
Utils.RGB(100, 200, 50, 0.8)   -- → {0.392, 0.784, 0.196, 0.8}
```

---

## Utility Functions

### Utils.clamp(val, min, max)

Clamps a value to the `[min, max]` range.

```lua
Utils.clamp(5, 0, 10)   -- → 5
Utils.clamp(15, 0, 10)  -- → 10
Utils.clamp(-3, 0, 10)  -- → 0
```

### Utils.validateEnum(value, enum, default, label)

Validates an enum value. `nil` silently returns default; illegal values print a warning and fall back.

```lua
local orientation = Utils.validateEnum(
    datas.orientation,           -- user-supplied value
    Utils.ORIENTATION,           -- valid values set
    Utils.ORIENTATION.VERTICAL,  -- default
    "BoxContainer.orientation"   -- label (for error messages)
)
```

### Utils.hasFlag(flags, flag)

Bit detection, LuaJIT-compatible (no `bit` library). Checks whether `flags` contains the `flag` bit.

```lua
local flags = Utils.SIZE_FLAGS.FILL + Utils.SIZE_FLAGS.EXPAND  -- = 3
Utils.hasFlag(flags, Utils.SIZE_FLAGS.FILL)    -- → true
Utils.hasFlag(flags, Utils.SIZE_FLAGS.EXPAND)  -- → true
Utils.hasFlag(flags, Utils.SIZE_FLAGS.SHRINK_END) -- → false
```

### Utils.newButtonStateStyle(text, text_color, font_size, bg_color, outline_width, outline_color, offset, scale, rounding_radius)

Creates a single-state style table for Button. All parameters optional (nil = don't override).

```lua
local normal = Utils.newButtonStateStyle(
    "Click Me",                  -- text
    Utils.UI_COLORS.TITLE,       -- text_color
    16,                          -- font_size
    Utils.UI_COLORS.BTN_NORMAL,  -- bg_color
    nil,                         -- outline_width
    nil,                         -- outline_color
    nil,                         -- offset {x, y}
    nil,                         -- scale {sx, sy}
    4                            -- rounding_radius
)
```

Return fields: `text`, `text_color`, `font_size`, `bg_color`, `outline_width`, `outline_color`, `offset`, `scale`, `rounding_radius`.

### Utils.newImageButtonStateStyle(texture, tint, text, text_color, font_size, offset, scale)

Creates a single-state style table for ImageButton. All parameters optional.

```lua
local normal = Utils.newImageButtonStateStyle(
    icon,                        -- texture
    {1, 1, 1, 1},               -- tint
    "Save",                      -- text
    Utils.UI_COLORS.TITLE,       -- text_color
    14,                          -- font_size
    nil,                         -- offset
    nil                          -- scale
)
```

Return fields: `texture`, `tint`, `text`, `text_color`, `font_size`, `offset`, `scale`.

---

## Components

`ui/components.lua` — reusable widget mixins and style application.

### Components.addHoverState(widget)

Mixes hover detection into any Widget. After calling:

- widget gains a `hovered` property (boolean)
- widget gains an `onHovered(hovered, x, y, dx, dy)` callback
- internally wraps `onMouseMoved`: calls original handler first, then hover detection

```lua
local Components = require "ui.components"

local box = Widget({...})
Components.addHoverState(box)
function box:onHovered(hovered, x, y, dx, dy)
    if hovered then
        print("mouse enter")
    else
        print("mouse leave")
    end
end
```

> **Note**: ProgressBar auto-calls this mixin when `interactive = true`.

### Components.applyButtonTextStyle(button, new_style)

Applies text style changes (color + font size) during button state transitions. Called internally by Button; rarely needed manually.

### Components.applyButtonTransform(button, old_style, new_style)

Applies position offset and scale changes during button state transitions. Called internally by Button.

---

## Common Imports

```lua
local Utils = require "ui.utils"
local Components = require "ui.components"
```
