# Fonts (Font Manager)

The Fonts module is Muse's font registry and management system. It provides unified font loading, caching, and lookup — all widgets that render text (Text, Button, TextInput, etc.) obtain `love.graphics.Font` objects through it.

## Core Mechanism

### Lazy Loading & Caching

The Fonts module uses an **on-demand lazy loading** strategy:

- Each font entry is identified by a key (string) and stores the TTF file path (`_file` field) along with `love.graphics.Font` objects cached by size
- The first call to `getFont(key, size)` invokes `love.graphics.newFont(file, size)`, creates the font object, and caches it
- Subsequent requests for the same key + size return the cached object directly, avoiding duplicate creation

```lua
-- First call: loads TTF and caches
local f1 = Fonts:getFont("default", 20)  -- creates love.graphics.Font

-- Subsequent call: cache hit, returned directly
local f2 = Fonts:getFont("default", 20)  -- f1 == f2
```

### Per-Size Caching

The same font at different sizes is cached independently — `"default"` at 12px, 16px, and 20px creates three separate `love.graphics.Font` objects that do not interfere with each other.

## Built-in Fonts

Muse ships with the [Noto Sans SC](https://fonts.google.com/noto/specimen/Noto+Sans+SC) font family (SIL Open Font License 1.1), located in the `ui/fonts/` directory:

| Key | File | Weight | Use Case |
|-----|------|--------|----------|
| `"default"` | `NotoSansSC-Regular.ttf` | Regular (400) | Body text, buttons, input fields, general UI text. **A 16px instance is pre-created at construction time** |
| `"default_thin"` | `NotoSansSC-Thin.ttf` | Thin (250) | Ultra-light weight |
| `"default_light"` | `NotoSansSC-Light.ttf` | Light (300) | Lighter weight |
| `"default_bold"` | `NotoSansSC-Bold.ttf` | Bold (700) | Bold text, heading emphasis |
| `"default_black"` | `NotoSansSC-Black.ttf` | Black (900) | Ultra-bold weight |
| `"debug"` | `NotoSansSC-Light.ttf` | Light (300) | Debug info rendering (debug mode for Button, Image, ScrollContainer) |

> **Note**: `"debug"` and `"default_light"` use the same TTF file but exist as independent keys — their cache spaces do not interfere.

## API

### `Fonts:getFont(key, size)`

Returns the font object for the given key and size. If the font at this size hasn't been created yet, it is automatically loaded and cached.

```lua
---@param key   string  Font registry key
---@param size  number  Font size (pixels)
---@return love.graphics.Font
local font = Fonts:getFont("default", 16)
```

### `Fonts:newFont(key, file, size)`

Registers a new font and optionally pre-creates an instance at a given size.

```lua
---@param key   string  Registry key for the new font (must not duplicate an existing key)
---@param file  string  Path to the .ttf file
---@param size  number  Size to pre-create, defaults to 16
---@return love.graphics.Font  Returns the pre-created font object
Fonts:newFont("my_font", "assets/fonts/MyCustomFont.ttf", 18)
```

> **Note**: If the key already exists, `newFont` will **overwrite** the existing entry.

### `Fonts:hasFont(key)`

Checks whether the given key is registered in Fonts.

```lua
if Fonts:hasFont("my_font") then
    print("my_font is registered")
end
```

## Usage

### Method 1: Via Widget Constructor Parameters

Text and TextInput widgets accept `font_key` and `font_size` at construction time:

```lua
local label = Text({
    text = "Hello, Muse!",
    font_key = "default_bold",
    font_size = 20,
})
```

### Method 2: Via Widget Instance Methods

```lua
-- Set both font and size
label:setFont("default", 18)

-- Change size only
label:setFontSize(24)

-- Get the current font object
local font = label:getFont()

-- Get the current font key
local key = label:getFont(true)

-- Get the current font size
local size = label:getFontSize()
```

### Method 3: Via the Theme System

Set default fonts uniformly in a theme:

```lua
local Theme = require "ui.theme"

local MyTheme = Theme:extend()
function MyTheme:new()
    Theme.new(self)
    self.text.font_key = "default_bold"
    self.text.font_size = 18
    self.textinput.font_key = "default"
    self.textinput.font_size = 16
end
```

### Method 4: Direct Access for Raw LÖVE Drawing

When you need to use the LÖVE API directly outside the widget system:

```lua
local Fonts = require "ui.fonts"

function love.draw()
    local font = Fonts:getFont("default", 14)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("FPS: 60", font, 10, 10)
end
```

## Registering Custom Fonts

```lua
local Fonts = require "ui.fonts"

-- 1. Register the font (place the .ttf in ui/fonts/ or your project's assets folder)
Fonts:newFont("pixel", "ui/fonts/PixelFont.ttf", 12)

-- 2. Use it directly
local font = Fonts:getFont("pixel", 24)

-- 3. Or use it in a widget
local label = Text({
    text = "Pixel Style",
    font_key = "pixel",
    font_size = 24,
})
```

## Font Loading Lifecycle

```
Fonts:newFont("my_font", "path.ttf", 16)
        │
        ├──► self["my_font"] = { _file = "path.ttf" }
        └──► self:getFont("my_font", 16)
                │
                ├──► self["my_font"][16] = love.graphics.newFont("path.ttf", 16)
                └──► return self["my_font"][16]
```

Subsequent requests:

```
Fonts:getFont("my_font", 20)
        │
        ├──► self["my_font"][20] does not exist
        ├──► self["my_font"][20] = love.graphics.newFont("path.ttf", 20)
        └──► return self["my_font"][20]

Fonts:getFont("my_font", 20)  -- called again
        │
        ├──► self["my_font"][20] already cached
        └──► return self["my_font"][20]
```

## Font Flow in Widgets

Taking Button as an example, here's how fonts flow through the widget system:

```
Theme / datas defines font_key + font_size
        │
        ▼
Button constructor
        │
        ├──► datas.font_key / theme.button.normal.font_size
        │
        ▼
Button's internal Text child widget
        │
        ├──► Text:setFont(font_key, font_size)
        │     ├──► validates Fonts[font_key] exists
        │     └──► self.__text:setFont(Fonts:getFont(font_key, font_size))
        │
        ▼
State switch (normal → hover → pressed …)
        │
        └──► Components.applyButtonTextStyle(button, new_style)
              └──► button.text:setFontSize(new_style.font_size)
```

## FAQ

### Q: "Unregistered fonts" error

```
Text:setFont|Unregistered fonts: xxx
```

**Cause**: An unregistered `font_key` was used. All fonts must first be registered via `Fonts:newFont()`, or you must use one of the built-in keys.

**Solution**:
```lua
-- Ensure registration before use
Fonts:newFont("my_font", "path/to/font.ttf", 16)
```

### Q: Text size doesn't update after changing font_size

**Cause**: `Text:setFontSize()` internally calls `updateTextLayout()` to refresh the layout. However, directly manipulating the `love.graphics.Font` object will not be detected by the widget.

**Solution**: Always use the widget's `setFont` / `setFontSize` methods to change fonts.

### Q: Are fonts shared between different widgets?

Yes. `Fonts:getFont("default", 16)` always returns the same `love.graphics.Font` object. Multiple Text widgets referencing the same object will not cause duplicate loading.

### Q: How to dynamically switch fonts without recreating a widget?

```lua
-- Runtime font switching
label:setFont("default_bold", 18)   -- switch to bold
label:setFont("default", 14)        -- switch back to regular
```
