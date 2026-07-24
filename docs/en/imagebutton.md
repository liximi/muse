# ImageButton

Texture-based button. Like Button, has six states, each configurable with different textures, tints, and text styles.

**Inheritance:** `Widget` → `ButtonBase` → `ImageButton`

## Constructor Parameters (datas)

```lua
{
    no_text = boolean,        -- Textless mode (no Text child created)
    font_key = string,        -- Font key

    -- State styles (see Utils.newImageButtonStateStyle)
    normal = Utils.newImageButtonStateStyle,
    hover = Utils.newImageButtonStateStyle,
    pressed = Utils.newImageButtonStateStyle,
    disabled = Utils.newImageButtonStateStyle,
    selected = Utils.newImageButtonStateStyle,
    selected_hover = Utils.newImageButtonStateStyle,
}
```

`Utils.newImageButtonStateStyle(texture, tint, text, text_color, font_size, offset, scale)` constructs a state style.

## How It Works

If `w`/`h` are not specified at construction, they are inferred from `normal.texture` dimensions. `getMinimumSize()` delegates to the inner Image child. Text (unless `no_text = true`) is overlaid on the image with centered anchors.

State transitions automatically switch texture, tint, and text style.

## Example

```lua
local Utils = require "ui.utils"

local icon_btn = ImageButton({
    normal = Utils.newImageButtonStateStyle(icon_tex, nil, "Play", {1, 1, 1, 1}, 14),
    hover  = Utils.newImageButtonStateStyle(icon_hover_tex, {1, 0.9, 0.8, 1}),
    on_click = function() print("play") end,
})
```

## Best Practices

- **Do**: Let button size be inferred from `normal.texture` dimensions; override with explicit `w`/`h` when needed.
- **Do**: Use `Utils.newImageButtonStateStyle(...)` for style construction.
- **Don't**: Call `setText()` on a `no_text = true` button — it's silently ignored.
