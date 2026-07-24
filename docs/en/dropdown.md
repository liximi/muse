# Dropdown

A dropdown selection component. Clicking the trigger button expands a popup option list.

**Inheritance chain:** `Widget` → `Dropdown`

## Constructor Parameters (datas)

```lua
{
    options = {string, ...},          -- option text list
    selected_index = number,          -- default selected index (1-based), default 1
    on_select = function(index, value),  -- selection callback
    max_visible_items = number,       -- maximum simultaneously visible options, default 6
    placeholder = string,             -- placeholder text when nothing is selected
    scrollbar_edge_pad = number,      -- scrollbar end padding (pixels), default 2
    scroll_bottom_pad = number,       -- scroll content bottom padding (pixels), default 4
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `select(index)` | Select the item at the given index (triggers `onSelect` and closes popup) |
| `getSelectedIndex()` | Get the currently selected index |
| `getSelectedValue()` | Get the currently selected text |
| `setOptions(options, selected_index)` | Replace the options list |

## Static Methods

| Method | Description |
|--------|-------------|
| `Dropdown.destroyAll()` | Destroy popups of all active Dropdowns (used when switching test scenes) |

## Behavior

- Popup is a UiManager root widget with fullscreen anchor
- Render layer: `DROPDOWN = 80`
- Options displayed directly when count ≤ `max_visible_items`
- Wrapped in a Scroll container when count > `max_visible_items`
- Popup position auto-flips to avoid screen edges (top/bottom flip, left/right alignment)
- Clicking empty area of the popup layer dismisses it
- Popup layer intercepts MouseMoved to prevent penetration

## Example

```lua
local dd = Dropdown({
    options = {"Apple", "Banana", "Cherry", "Date", "Elderberry"},
    selected_index = 1,
    max_visible_items = 4,
    on_select = function(index, value)
        print("selected:", index, value)
    end,
    anchor = {0, 0, 0, 0},
    w = 200,
    h = 32,
})
```
