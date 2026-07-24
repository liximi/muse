# Scroll

Scroll container. Inner content can scroll horizontally and vertically, with optional slider bars and easing animations.

**Inheritance:** `Widget` → `Scroll`

## Constructor Parameters (datas)

```lua
{
    item = Widget,            -- Initial content
    horizontal_scroll_mode = "disabled" | "auto" | "show_always" | "show_never" | "reserve",  -- Default "disabled"
    vertical_scroll_mode   = "disabled" | "auto" | "show_always" | "show_never" | "reserve",  -- Default "auto"
    sensitivity = number,     -- Wheel sensitivity (px), default 100
    scrollable_w = number,    -- Horizontal scrollable range (px)
    scrollable_h = number,    -- Vertical scrollable range (px)
    show_slider_bar = boolean, -- Show slider bars, default true
    auto_track = boolean,     -- Auto-track content size changes, default true
    h_slider_bar_height = number,  -- Horizontal bar height, default 8
    v_slider_bar_width = number,   -- Vertical bar width, default 8
    scrollbar_gap = number,   -- Bar-to-content gap, default 2
    v_bar_pad_top = number,   -- Vertical bar top padding
    v_bar_pad_bottom = number,
    h_bar_pad_left = number,
    h_bar_pad_right = number,
    block_min_len = number,   -- Thumb minimum length
}
```

## How It Works

### Internal Structure

Scroll internally maintains `scroll_root` (content container) and two `SliderBar` instances (horizontal/vertical). `scroll_root` offsets its position to achieve content scrolling.

### Clipping

Scissor clipping is managed in `scroll_root`'s `onDraw`/`onPostDraw` closures (not on Scroll itself). Reason: `Widget:draw` order is onDraw → children → onPostDraw; setting scissor inside scroll_root's children loop precisely covers the content drawing phase.

Nested Scrolls correctly intersect scissor regions — `love.graphics.setScissor()` replaces rather than intersects, so the code explicitly computes the intersection.

### Auto-Track

When `auto_track = true` (default), `onUpdate` polls `item.transform.w/h` each frame and automatically updates `scrollable_w`/`scrollable_h`.

### Scroll Modes

- `"disabled"`: Axis is not scrollable, content fills the area.
- `"auto"`: Show bar when content overflows.
- `"show_always"`: Always show bar.
- `"show_never"`: Never show bar (still scrollable via code).
- `"reserve"`: Reserve bar space.

### Wheel Events

`onWheelMoved` returns `true` to block bubbling, preventing nested Scroll interference. Uses `love.mouse.getPosition()` for hit testing (not event parameters), so wheel events that pass through the raycast_target fallback are still captured by outer Scrolls.

### Easing Animation

Pass `true` as the second argument to `setXOffset`/`setYOffset` for eased animation using `tween.lua` linear interpolation.

## Public Methods

| Method | Description |
|--------|-------------|
| `setItem(item)` | Set content widget |
| `setXOffset(offset, tween)` | Set horizontal scroll offset |
| `setYOffset(offset, tween)` | Set vertical scroll offset |
| `setScrollableW(w)` | Set horizontal scrollable range |
| `setScrollableH(h)` | Set vertical scrollable range |
| `getMinimumSize()` | Returns own transform size |

## Example

```lua
-- Vertical scrolling list
local scroll = Scroll({
    anchor = {0, 0, 1, 1},
    vertical_scroll_mode = "auto",
})
local vbox = VBoxContainer({ anchor = {0, 0, 1, 0}, auto_size = true, separation = 4 })
vbox:addChild(Button({ text = "Item 1" }))
vbox:addChild(Button({ text = "Item 2" }))
scroll:setItem(vbox)
```

## Best Practices

- **Do**: Use `anchor = {0, 0, 1, 0}` for VBox inside Scroll to fill horizontally.
- **Do**: Enable `auto_size = true` on the inner VBox and `auto_track = true` on Scroll.
- **Do**: Return `true` from `onWheelMoved` to prevent nested Scroll conflicts.
- **Don't**: Manipulate scissor outside of scroll_root — clipping is managed by closures.
