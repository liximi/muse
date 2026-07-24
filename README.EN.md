# Muse

[中文](README.md) | [English](README.EN.md)

**Muse** — a desktop-grade UI framework for the [LÖVE](https://love2d.org/) game engine, written in Lua. Its layout system is modeled after the [Godot](https://godotengine.org/) engine's Container architecture, providing BoxContainer, MarginContainer, CenterContainer and SizeFlags child layout flags. It also implements a complete widget system including a theme system, text input, scrollable lists, and more.

> This library makes extensive use of LLM-generated code. Please evaluate the risks before using it in production.

![runtime](assets/runtime_overview_1.gif)

## Installation

### Prerequisites

- [LÖVE](https://love2d.org/) 11.5 (uses LuaJIT, based on Lua 5.1 + extensions)

### As a Git Submodule (Recommended)

```bash
git submodule add https://github.com/liximi/muse.git lib/muse
```

Then load Muse in your `main.lua`:

```lua
Class = require "lib.muse.dependencies.classic"
local UiManager = require "lib.muse.ui.ui_manager":GetInstance()
```

### Copy Into Your Project

Copy the following directories and files into your project (e.g. `lib/muse/`):

**Required**:
```
ui/                      # All UI framework source code
dependencies/classic.lua  # OOP class system (required)
dependencies/tween.lua    # Tween animation library (required by Scroll, etc.)
```

**Optional**:
```
dependencies/lovebird/    # Remote debug console (development only)
dependencies/i18n/        # Localization framework + localization/ directory (for i18n support)
assets/                   # Font files and images (copy if using the built-in fonts)
```

**Not needed**:
```
tests/            # Test scenes
docs/             # Documentation
main.lua          # Demo app entry point
conf.lua          # Demo LÖVE config
CLAUDE.md         # AI assistant prompts
```

### Run the Demo

```bash
love .
```

Press `Escape` to exit. After launching, open `http://127.0.0.1:8000` in a browser to access the Lovebird remote debugging console.

## Quick Start

> The following code assumes you are running `love .` from the Muse repository root. If you've installed Muse as `lib/muse` in your project, change the require path prefix to `lib.muse.`.

```lua
-- 1. Import dependencies
Class = require "dependencies.classic"
local UiManager = require "ui.ui_manager":GetInstance()
local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Button = require "ui.widgets.button"
local Utils = require "ui.utils"

function love.load()
    -- 2. Create a root container
    local root = UiManager:addWidget(Widget({
        anchor = {0, 0, 1, 1},   -- fill the entire window
        padding = {0, 0, 0, 0},
    }))

    -- 3. Add a child widget
    local btn = root:addChild(Button({
        pivot = {0.5, 0.5},
        anchor = {0.5, 0.5, 0.5, 0.5},  -- centered
        w = 160,
        h = 40,
        normal = Utils.newButtonStateStyle("Click Me", Utils.UI_COLORS.TITLE, 16,
                    Utils.UI_COLORS.BTN_NORMAL, nil, nil, nil, nil, 4),
        on_click = function()
            print("Hello, World!")
        end,
    }))
end

-- 4. Forward events in LÖVE callbacks
function love.update(dt)
    UiManager:update(dt)
end

function love.draw()
    UiManager:draw()
end

function love.keypressed(key, scancode, isrepeat)
    UiManager:KeyPressed(key, isrepeat)
end

function love.textinput(text)
    UiManager:TextInput(text)
end

function love.mousepressed(x, y, button)
    UiManager:MousePressed(x, y, button)
end

function love.mousereleased(x, y, button)
    UiManager:MouseReleased(x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    UiManager:MouseMoved(x, y, dx, dy)
end

function love.wheelmoved(x, y)
    UiManager:WheelMoved(x, y)
end
```

## Dependencies

| Dependency | Path | Source | Purpose |
|------------|------|--------|---------|
| **classic** | `dependencies/classic.lua` | [rxi/classic](https://github.com/rxi/classic/) | OOP class system, provides simplified class inheritance (interface slightly modified) |
| **tween** | `dependencies/tween.lua` | [kikito/tween.lua](https://github.com/kikito/tween.lua) | Tweening library, used by Scroll container and CollapsiblePanel for smooth animations |
| **Lovebird** | `dependencies/lovebird/` | [rxi/lovebird](https://github.com/rxi/lovebird) | Remote debugging console (HTTP `:8000`), development use only |
| **i18n** | `dependencies/i18n/` | [excessive/i18n](https://github.com/excessive/i18n) | Localization framework (currently zh-cn only), for multi-language UI text support |

The only core dependencies are **classic** and **tween**. Lovebird and i18n are optional dev/auxiliary dependencies.

## Core Systems

| System | Documentation | Description |
|--------|---------------|-------------|
| **Widget (base class)** | [docs/en/widget.md](docs/en/widget.md) | Base class for all UI elements; provides tree structure, Transform layout, event dispatch, and lifecycle |
| **Transform** | [docs/en/transform.md](docs/en/transform.md) | Anchor-based layout engine; supports anchors, pivots, rotation, scaling, and recursive global coordinate calculation |
| **Theme** | [docs/en/theme.md](docs/en/theme.md) | Theme/style system; supports per-widget-type default styles and custom theme overrides |
| **Fonts** | [docs/en/fonts.md](docs/en/fonts.md) | Font manager providing unified font registration, lazy-loading cache, and lookup |
| **UiManager** | [docs/en/ui-manager.md](docs/en/ui-manager.md) | Global singleton; manages root widget hierarchy, focus, themes, and event dispatch |

## Component List

### Basic Components

| Component | Description | Documentation |
|-----------|-------------|---------------|
| **Panel** | Solid-color panel with background color, outline, and rounded corners | [docs/en/panel.md](docs/en/panel.md) |
| **Text** | Text rendering with coloredtext, word wrap, and multi-directional alignment | [docs/en/text.md](docs/en/text.md) |
| **Image** | Texture rendering with tint coloring and clamp-mode stretch-to-fill | [docs/en/image.md](docs/en/image.md) |
| **NineSlice** | 9-slice texture rendering for adaptive-size borders/panels | [docs/en/nineslice.md](docs/en/nineslice.md) |

### Button Components

| Component | Description | Documentation |
|-----------|-------------|---------------|
| **Button** | Text button with 6 state styles (normal/pressed/hover/selected/selected_hover/disabled) | [docs/en/button.md](docs/en/button.md) |
| **ImageButton** | Image button with texture/tint switching, optional attached text | [docs/en/imagebutton.md](docs/en/imagebutton.md) |
| **Checkbox** | Checkbox supporting square+checkmark and sliding toggle styles | [docs/en/checkbox.md](docs/en/checkbox.md) |
| **RadioButton** | Radio button with circular outline + filled dot, inherits from Checkbox | [docs/en/radiobutton.md](docs/en/radiobutton.md) |
| **RadioGroup** | Radio button group managing mutual exclusion among RadioButtons | [docs/en/radiogroup.md](docs/en/radiogroup.md) |

### Input Components

| Component | Description | Documentation |
|-----------|-------------|---------------|
| **TextInput** | Text input field with cursor control, selection, clipboard, and undo/redo | [docs/en/textinput.md](docs/en/textinput.md) |
| **SliderBar** | Slider bar supporting horizontal/vertical orientation, drag, long-press stepping, and integer step mode | [docs/en/sliderbar.md](docs/en/sliderbar.md) |
| **ProgressBar** | Progress bar supporting horizontal and vertical orientation | [docs/en/progressbar.md](docs/en/progressbar.md) |

### Container Components

| Component | Description | Documentation |
|-----------|-------------|---------------|
| **Modal** | Modal dialog with fullscreen semi-transparent overlay + centered content, closes on Escape / outside click | [docs/en/modal.md](docs/en/modal.md) |
| **TabView** | Tabbed view with top Button bar + content panel below | [docs/en/tabview.md](docs/en/tabview.md) |
| **Scroll** | Scroll container with scissor clipping + optional scrollbar + tween animations + auto content tracking | [docs/en/scroll.md](docs/en/scroll.md) |
| **BoxContainer** | Godot-style linear layout container (HBox/VBox), three-pass allocation + SizeFlags | [docs/en/box_container.md](docs/en/box_container.md) |
| **MarginContainer** | Margin container with configurable per-edge margins | [docs/en/margin_container.md](docs/en/margin_container.md) |
| **CenterContainer** | Center container for centering children | [docs/en/center_container.md](docs/en/center_container.md) |
| **Spacer** | Invisible flexible spacer widget | [docs/en/spacer.md](docs/en/spacer.md) |
| **List** | Linear list container (legacy), sequential arrangement + diff reuse | [docs/en/list.md](docs/en/list.md) |
| **Box** | Flexbox-style layout container (legacy, being phased out) | [docs/en/box.md](docs/en/box.md) |

### Overlay Components

| Component | Description | Documentation |
|-----------|-------------|---------------|
| **Tooltip** | Mouse hover tooltip with configurable delay, max width, and positional offset | [docs/en/tooltip.md](docs/en/tooltip.md) |
| **Dropdown** | Dropdown selector with trigger button + popup option list (supports scrolling) | [docs/en/dropdown.md](docs/en/dropdown.md) |

### Advanced Components

| Component | Description | Documentation |
|-----------|-------------|---------------|
| **ChatBubble** | Chat bubble with left/right alignment + custom styling | [docs/en/chat-history.md](docs/en/chat-history.md) |
| **ChatHistory** | Chat history list managing bubble display, appending, and style updates | [docs/en/chat-history.md](docs/en/chat-history.md) |
| **CollapsiblePanel** | Collapsible screen-edge-docked panel with outQuint easing animation | [docs/en/collapsible-panel.md](docs/en/collapsible-panel.md) |

## Architecture Overview

### Class Inheritance Hierarchy

```
Widget (base class)
├── Panel
├── Text
├── Image
├── NineSlice
├── ProgressBar
├── Modal
├── TabView
├── RadioGroup
├── ButtonBase
│   ├── Button
│   ├── ImageButton
│   └── Checkbox
│       └── RadioButton
├── TextInput
├── SliderBar
├── Container
│   ├── BoxContainer
│   ├── MarginContainer
│   └── CenterContainer
├── Scroll
├── Spacer
├── List
├── Box
├── Tooltip
├── Dropdown
└── ChatHistory (contains ChatBubble)
```

### Transform Layout Model

Transform implements a Unity-like anchor-based layout system:

- **Point anchor** (`min == max`): fixed size, position determined by `x`/`y` offset
- **Stretch anchor** (`min < max`): adaptive size, determined by anchor range minus padding

See [Transform Documentation](docs/en/transform.md) for details.

### Event Propagation

Events are dispatched from `UiManager` to the hierarchy (most recently added widgets receive events first), recursively entering child nodes via `handleEvent`:

- **Children first** — reverse-order traversal of children
- **Interception** — when a child handler returns `true`, the event stops propagating
- **Lifecycle** — `update` → `draw` (layered), focus management, keyboard/mouse events

### Theme Priority

```
datas direct parameters > custom theme > UiManager default theme
```

See [Theme Documentation](docs/en/theme.md) for details.

## Widget Common Parameters

All widgets accept the following `datas` fields at construction time (processed via Transform):

```lua
{
    pivot = {x, y},           -- pivot 0~1 (default {0, 0})
    anchor = {minx, miny, maxx, maxy},  -- anchor (default {0, 0, 0, 0})
    x = number, y = number,   -- position (pixels)
    w = number, h = number,   -- size (pixels)
    sx = number, sy = number, -- scale (default 1)
    padding = {left, right, top, bottom},  -- padding (pixels)
    r = number,               -- rotation (radians)
}
```

## Coding Conventions

The codebase follows these conventions (which should be followed when writing new widgets):

- **Indentation**: Tab
- **Naming**: local variables/fields `snake_case`, methods `camelCase`, class names `PascalCase`, constants `UPPER_CASE`
- **Class system**: `Class(BaseClass, function(self, datas, theme) ... end)`
- **Event handlers**: `on` + PascalCase event name, e.g. `onMousePressed`, `onSizeChanged`
- **Widget file structure**: require → private functions → class definition → public methods → event handlers → return
- **Widget file header** should include a structural comment describing the `datas` fields it accepts

## Font

This library uses the [Noto Sans SC](https://fonts.google.com/noto/specimen/Noto+Sans+SC) font family, licensed under the [SIL Open Font License 1.1](https://openfontlicense.org/).

Muse includes a built-in **Font Manager (Fonts)** with per-key + per-size lazy loading, caching, and custom font registration. See the [Fonts documentation](docs/en/fonts.md) for details.

## License

[MIT](LICENSE)
