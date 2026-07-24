# Dropdown

Dropdown selector with trigger button and popup option list. Supports scrolling, screen edge avoidance, and render layer management.

**Inheritance:** `Widget` → `Dropdown`

## Constructor Parameters (datas)

```lua
{
    options = {string, ...},          -- Option texts
    selected_index = number,          -- Default selection (1-based), default 1
    on_select = function(index, value),
    max_visible_items = number,       -- Max visible at once, default 6
    scrollbar_edge_pad = number,      -- Scrollbar edge padding (px), default 2
    scroll_bottom_pad = number,       -- Bottom extra padding (px), default 4
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `select(index)` | Select option (triggers `onSelect`, closes popup) |
| `getSelectedIndex()` / `getSelectedValue()` | Get current selection |
| `setOptions(options, selected_index)` | Replace options list |
| `getMinimumSize()` | Returns own transform size |

## How It Works

- **Trigger button**: fills Dropdown area, toggles open/close on click.
- **Popup**: root widget at `render_layer = DROPDOWN = 80`, full-screen anchor. Registered to UiManager on `onAttached`, destroyed on `onDetached`.
- **Panel**: absolute-positioned Panel inside popup, positioned below (or above) the trigger with edge avoidance.
- **Options**: direct Button array when ≤ `max_visible_items`; wrapped in Scroll when more.
- **Close**: clicking popup background or selecting an option. Popup intercepts MouseMoved and WheelMoved.

## Example

```lua
local dd = Dropdown({
    options = {"Apple", "Banana", "Cherry", "Date", "Elderberry", "Fig", "Grape"},
    selected_index = 1,
    max_visible_items = 4,
    on_select = function(index, value) print("selected:", index, value) end,
    anchor = {0, 0, 0, 0},
    w = 200, h = 32,
})
```
