# Fonts — Font Manager

Provides per-key + per-size lazy loading and caching.

## Registered Fonts

Defined in `ui/fonts.lua` (all Noto Sans SC):

| Key | Weight |
|-----|--------|
| `default` | Regular (400) |
| `default_thin` | Thin (250) |
| `default_light` | Light (300) |
| `default_bold` | Bold (700) |
| `default_black` | Black (900) |
| `debug` | Light (300) |

## Public Methods

| Method | Description |
|--------|-------------|
| `Fonts:getFont(key, size)` | Get/create cached font object |
| `Fonts:newFont(key, file, size)` | Register a new font at runtime |
| `Fonts:hasFont(key)` | Check if key is registered |

## Lazy-loading Cache

```lua
-- First call: load from file, cache at Fonts[key][size]
local f16 = Fonts:getFont("default", 16)
-- Second call: returns cached object
local f16_again = Fonts:getFont("default", 16)  -- same object
-- Different size: creates new font
local f24 = Fonts:getFont("default", 24)
```

## Register Custom Font

```lua
local Fonts = require "ui.fonts"
local muse = require("init")
Fonts:newFont("my_font", muse.resolve("assets/my_font.ttf"), 16)
local my_font = Fonts:getFont("my_font", 20)
```
