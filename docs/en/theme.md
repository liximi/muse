# Theme System

The theme system provides uniform default styles for all widgets. Each widget type has its own configuration block in the theme. Custom themes can be created by extending the default Theme class.

## Priority

Style value priority (highest to lowest):

1. **datas parameters** — fields passed directly to widget constructor, highest priority
2. **Custom theme** — the `theme` parameter passed to widget constructor
3. **Default theme** — the default theme instance held by UiManager

## Default Theme

The default theme is defined in `ui/theme.lua` and contains the following blocks:

```lua
local Theme = Class(function(self)
    self.panel = { ... }        -- Panel default style
    self.text = { ... }         -- Text default style
    self.textinput = { ... }    -- TextInput default style
    self.image = { ... }        -- Image default style
    self.button = { ... }       -- Button default style
    self.sliderbar = { ... }    -- SliderBar default style
    self.progressbar = { ... }  -- ProgressBar default style
    self.checkbox = { ... }     -- Checkbox default style
    self.radiobutton = { ... }  -- RadioButton default style
    self.modal = { ... }        -- Modal default style
    self.tabview = { ... }      -- TabView default style
    self.imagebutton = { ... }  -- ImageButton default style
end)
```

## Default Fields by Block

### panel

| Field | Default | Description |
|-------|---------|-------------|
| `bg_color` | `UI_COLORS.SURFACE` | Background color `{r, g, b, a}` |
| `outline_color` | `UI_COLORS.LINE` | Outline color |
| `rounding_radius` | `4` | Corner radius (pixels) |
| `outline_width` | `1` | Outline width (pixels) |

### text

| Field | Default | Description |
|-------|---------|-------------|
| `font_key` | `"default"` | Font registry key |
| `font_size` | `16` | Font size |
| `text_color` | `UI_COLORS.PRIMARY_TEXT` | Text color |

### textinput

| Field | Default | Description |
|-------|---------|-------------|
| `font_key` | `"default"` | Font key |
| `font_size` | `16` | Font size |
| `text_color` | `UI_COLORS.PRIMARY_TEXT` | Text color |
| `text_padding` | `{8, 8, 8, 8}` | Text padding |
| `hint_color` | `UI_COLORS.SECONDARY_TEXT` | Placeholder hint color |

### image

| Field | Default | Description |
|-------|---------|-------------|
| `tint` | `{1, 1, 1, 1}` | Tint color `{r, g, b, a}` |

### button & imagebutton

Button themes define 6 state styles via `Utils.newButtonStateStyle()` / `Utils.newImageButtonStateStyle()`:

| State | Description |
|-------|-------------|
| `normal` | Default |
| `pressed` | Pressed |
| `hover` | Hover |
| `selected` | Selected |
| `selected_hover` | Selected + hover |
| `disabled` | Disabled |

Button state style fields: `text`, `text_color`, `font_size`, `bg_color`, `outline_width`, `outline_color`, `offset`, `scale`, `rounding_radius`

ImageButton state style fields: `texture`, `tint`, `text`, `text_color`, `font_size`, `offset`, `scale`

### sliderbar

| Field | Default | Description |
|-------|---------|-------------|
| `track_color` | `UI_COLORS.BG` | Track background color |
| `block_color` | `UI_COLORS.BTN_NORMAL` | Thumb color |
| `block_hover_color` | `UI_COLORS.BTN_HOVER` | Thumb hover color |
| `outline_color` | `UI_COLORS.LINE` | Outline color |
| `block_length_percent` | `0.1` | Thumb length as proportion of track |
| `sensitivity` | `0.8` | Step sensitivity when clicking track |

### progressbar

| Field | Default | Description |
|-------|---------|-------------|
| `bg_color` | `UI_COLORS.BG` | Background color |
| `fill_color` | `UI_COLORS.ACCENT` | Fill color |
| `rounding_radius` | `4` | Corner radius |

### checkbox

| Field | Default | Description |
|-------|---------|-------------|
| `box_color` | `UI_COLORS.BTN_NORMAL` | Box color |
| `check_color` | `UI_COLORS.ACCENT` | Checkmark color |
| `box_size` | `20` | Box size |
| `outline_width` | `1` | Outline width |
| `outline_color` | `UI_COLORS.LINE` | Outline color |
| `rounding_radius` | `3` | Corner radius |
| `label_color` | `UI_COLORS.PRIMARY_TEXT` | Label color |
| `knob_color` | `UI_COLORS.TITLE` | Sliding toggle knob color |

### radiobutton

| Field | Default | Description |
|-------|---------|-------------|
| `circle_color` | `UI_COLORS.BTN_NORMAL` | Circle color |
| `dot_color` | `UI_COLORS.ACCENT` | Selected dot color |
| `circle_size` | `20` | Circle size |
| `outline_width` | `1` | Outline width |
| `outline_color` | `UI_COLORS.LINE` | Outline color |
| `label_color` | `UI_COLORS.PRIMARY_TEXT` | Label color |

### modal

| Field | Default | Description |
|-------|---------|-------------|
| `overlay_color` | `{0, 0, 0, 0.5}` | Overlay color |

### tabview

| Field | Default | Description |
|-------|---------|-------------|
| `tab_height` | `36` | Tab bar height |
| `tab_bg_normal` | `UI_COLORS.BTN_NORMAL` | Unselected tab background |
| `tab_bg_selected` | `UI_COLORS.SURFACE` | Selected tab background |
| `tab_text_normal` | `UI_COLORS.SECONDARY_TEXT` | Unselected text color |
| `tab_text_selected` | `UI_COLORS.TITLE` | Selected text color |
| `tab_font_size` | `14` | Tab font size |
| `tab_outline_color` | `UI_COLORS.LINE` | Tab outline color |
| `content_bg` | `UI_COLORS.SURFACE` | Content area background |
| `content_rounding_radius` | `4` | Content area corner radius |

## Creating a Custom Theme

```lua
local Theme = require "ui.theme"
local Utils = require "ui.utils"

local MyTheme = Theme:extend()
function MyTheme:new()
    Theme.new(self)  -- inherit defaults
    -- Override desired fields
    self.panel.bg_color = Utils.RGB(30, 30, 40)
    self.button.normal.text_color = Utils.RGB(255, 200, 100)
end

-- Option 1: set as global default theme
local UiManager = require "ui.ui_manager":GetInstance()
UiManager:setDefaultTheme(MyTheme())

-- Option 2: pass to a single widget
local btn = Button({text = "Hello"}, MyTheme())
```

## Color Utilities

`ui/utils.lua` provides color-related utilities:

```lua
-- RGB(0-255) → {0-1, 0-1, 0-1, a}
Utils.RGB(r, g, b, a)  -- a optional, defaults to 1

-- Predefined UI colors
Utils.UI_COLORS = {
    WHITE, BG, SURFACE, LINE,
    TITLE, PRIMARY_TEXT, SECONDARY_TEXT, HINT,
    BTN_NORMAL, BTN_HOVER, BTN_DISABLED,
    BTN_SELECTED, BTN_SELECTED_HOVER,
    ACCENT, ACCENT_LIGHT, WARNING
}
```
