# Scroll (ScrollContainer)

A scroll container providing a clipped scrollable view with support for horizontal/vertical scrolling, scrollbars, and tween animations.

**Inheritance chain:** `Widget` → `Scroll`

## Constructor Parameters (datas)

```lua
{
    item = Widget,                    -- child widget to scroll (required)
    enable_scroll_h = boolean,        -- enable horizontal scrolling, default false
    enable_scroll_v = boolean,        -- enable vertical scrolling, default true

    sensitivity = number,             -- mouse wheel sensitivity (pixels), default 100
    scrollable_w = number,            -- horizontal scrollable width (pixels)
    scrollable_h = number,            -- vertical scrollable height (pixels)

    show_slider_bar = boolean,        -- whether to show scrollbars, default true
    hide_slider_when_cannot_scroll = boolean,  -- hide scrollbars when not scrollable, default false
    h_slider_bar_height = number,     -- horizontal scrollbar height, default 8
    v_slider_bar_width = number,      -- vertical scrollbar width, default 8
    scrollbar_gap = number,           -- gap between scrollbar and content, default 2
    v_bar_pad_top = number,           -- vertical scrollbar top padding, default 0
    v_bar_pad_bottom = number,        -- vertical scrollbar bottom padding, default 0
    h_bar_pad_left = number,          -- horizontal scrollbar left padding, default 0
    h_bar_pad_right = number,         -- horizontal scrollbar right padding, default 0
    v_bar_min_h = number,             -- vertical scrollbar minimum height, default 0 (no limit)
    h_bar_min_w = number,             -- horizontal scrollbar minimum width, default 0 (no limit)
    block_min_len = number,           -- thumb minimum length, default 0 (no limit)
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `setItem(item)` | Set the content widget to scroll |
| `setXOffset(offset, tween)` | Set horizontal scroll offset (tween=true enables easing animation) |
| `setYOffset(offset, tween)` | Set vertical scroll offset |
| `setScrollableW(w)` | Set horizontal scrollable width (auto-updates thumb ratio) |
| `setScrollableH(h)` | Set vertical scrollable height |
| `updateHBlockLengthPercent()` | Update horizontal thumb length ratio |
| `updateVBlockLengthPercent()` | Update vertical thumb length ratio |

## Scrollbar Minimum Size Constraint

When `v_bar_min_h > 0` or `h_bar_min_w > 0`, if the track space is insufficient, the system proportionally reduces scrollbar end margins to ensure the minimum size is met.

## Interaction

- Mouse wheel scrolls up/down within the Scroll area
- Mouse wheel sensitivity: 100px (customizable via `sensitivity`)
- Dragging the scrollbar thumb enables fast positioning

## Edge Cases

- **Content MUST be set via `setItem()`**: Direct `addChild` to Scroll does NOT enter the internal `scroll_root`,
  so scrolling and clipping will not work. Correct usage: `scroll:setItem(content)`
- **Partially visible elements are not culled**: `_clip_rect` is expanded by 1px on each side.
  AABB culling only skips subtrees that have **zero overlap** with the clip region
- Scrollbar thumbs have `block_min_len` constraints; insufficient track space scales edge padding proportionally

## Example

```lua
local content = Widget({h = 800})  -- content taller than the container
local scroll = Scroll({
    item = content,
    anchor = {0, 0, 1, 1},
    padding = {0, 8, 0, 0},  -- reserve right-side space for the scrollbar
    hide_slider_when_cannot_scroll = true,
})
scroll:setScrollableH(800)
```
