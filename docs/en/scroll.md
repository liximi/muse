# Scroll

Scroll container with scissor clipping. Supports horizontal/vertical scrolling, scrollbars, tween animations, and auto content size tracking.

**Inheritance:** `Widget` → `Scroll`

> Scroll is not a Container subclass — it manages content through an internal `scroll_root` Widget. Content is set via `setItem()`.

## Constructor Parameters (datas)

```lua
{
    item = Widget,                    -- Content widget
    enable_scroll_h = boolean,        -- Enable horizontal scroll, default false
    enable_scroll_v = boolean,        -- Enable vertical scroll, default true

    sensitivity = number,             -- Wheel sensitivity (px), default 100
    scrollable_w = number,            -- Horizontal scrollable width
    scrollable_h = number,            -- Vertical scrollable height
    auto_track = boolean,             -- Auto-track content size changes, default true

    show_slider_bar = boolean,        -- Show scrollbar, default true
    hide_slider_when_cannot_scroll = boolean,  -- Hide when not scrollable, default false
    h_slider_bar_height = number,     -- Horizontal scrollbar height, default 8
    v_slider_bar_width = number,      -- Vertical scrollbar width, default 8
    scrollbar_gap = number,           -- Scrollbar gap from content, default 2

    v_bar_pad_top = number,           -- Vertical scrollbar top padding
    v_bar_pad_bottom = number,        -- Vertical scrollbar bottom padding
    h_bar_pad_left = number,          -- Horizontal scrollbar left padding
    h_bar_pad_right = number,         -- Horizontal scrollbar right padding
    v_bar_min_h = number,             -- Vertical scrollbar minimum height
    h_bar_min_w = number,             -- Horizontal scrollbar minimum width
    block_min_len = number,           -- Minimum slider length
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `setItem(item)` | Set scrollable content |
| `setXOffset(offset, tween)` / `setYOffset(offset, tween)` | Set scroll offset |
| `setScrollableW(w)` / `setScrollableH(h)` | Set scrollable range |
| `updateHBlockLengthPercent()` / `updateVBlockLengthPercent()` | Update slider ratio |
| `getMinimumSize()` | Returns own transform size |

## auto_track

Enabled by default. Each frame in `onUpdate`, polls `item`'s `transform.w/h` and updates scrollable range + slider ratio automatically. Clamps overshooting offsets when content shrinks.

## Scissor Clipping

- Managed in `scroll_root`'s `onDraw`/`onPostDraw` closures (not on Scroll itself).
- Nested Scrolls compute intersection manually since `love.graphics.setScissor` replaces rather than intersects.
- CPU-side culling: `_clip_rect` expanded by 1px tolerance, only skips elements fully outside.

## Interaction

- Mouse wheel scrolls vertically (100px per tick by default)
- Drag scrollbar slider for fast positioning
- `onWheelMoved` returns `true` — nested Scrolls scroll independently
- Mouse events only pass to content when within the visible area

## Example

```lua
-- Basic
local content = Widget({h = 800})
local scroll = Scroll({
    item = content,
    anchor = {0, 0, 1, 1},
    padding = {0, 8, 0, 0},
})
scroll:setScrollableH(800)

-- auto_track + VBox
local VBoxContainer = require "ui.widgets.containers.box_v_container"
local list = VBoxContainer({ auto_size = true, separation = 4 })
for i = 1, 50 do
    list:addChild(Button({ text = "Item " .. i, h = 32 }))
end
local scroll = Scroll({
    item = list,
    anchor = {0, 0, 1, 1},
})
-- No manual setScrollableH needed; auto_track follows VBox height
```

## Best Practices

- **Content must be set via `setItem()`**: direct `addChild` to Scroll bypasses `scroll_root`; scrolling and clipping break.
- **VBox in Scroll needs `anchor = {0, 0, 1, 0}`**: fill scroll_root horizontally, height determined by content.
- **Nested Scroll wheel isolation**: inner and outer Scrolls handle wheel independently.
