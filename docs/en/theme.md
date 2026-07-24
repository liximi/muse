# Theme System

The theme system provides default styles for all widgets. Each widget type has its own configuration block in the theme. Create custom themes by extending the default Theme class.

## Priority

Style value priority (highest to lowest):

1. **datas parameters** — passed directly to widget constructor
2. **Custom theme** — passed as `theme` argument
3. **Default theme** — UiManager's default theme instance

## Default Theme Blocks

Defined in `ui/theme.lua`: `panel`, `text`, `textinput`, `image`, `button`, `sliderbar`, `progressbar`, `checkbox`, `radiobutton`, `modal`, `tabview`, `imagebutton`.

### Key Defaults

| Block | Key Fields |
|-------|-----------|
| panel | `bg_color`, `outline_color`, `rounding_radius`=4, `outline_width`=1 |
| text | `font_key`="default", `font_size`=16, `text_color` |
| textinput | `font_key`, `font_size`, `text_color`, `text_padding`={8,8,8,8}, `hint_color` |
| button | 6 state styles via `newButtonStateStyle()` |
| sliderbar | `track_color`, `block_color`, `block_length_percent`=0.1, `sensitivity`=0.8 |
| progressbar | `bg_color`, `fill_color`, `rounding_radius`=4 |
| checkbox | `box_size`=20, `outline_width`=1, `rounding_radius`=3 |
| modal | `overlay_color`={0,0,0,0.5} |
| tabview | `tab_height`=36, `tab_font_size`=14 |

> **Note**: Button text (`text` field) is now managed independently by `setText()` / constructor params. `getStateStyle()` merge skips the `text` field.

## Creating a Custom Theme

```lua
local Theme = require "ui.theme"
local Utils = require "ui.utils"

local MyTheme = Theme:extend()
function MyTheme:new()
    Theme.new(self)  -- inherit defaults
    self.panel.bg_color = Utils.RGB(30, 30, 40)
end

-- Option 1: Set as global default
local UiManager = require "ui.ui_manager":GetInstance()
UiManager:setDefaultTheme(MyTheme())

-- Option 2: Pass to individual widget
local btn = Button({text = "Hello"}, MyTheme())
```
