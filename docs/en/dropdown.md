# Dropdown

Dropdown selector. Clicking the trigger button opens a popup option list; selecting an option auto-closes the popup.

**Inheritance:** `Widget` → `Dropdown`

## Constructor Parameters (datas)

```lua
{
    options = {string, ...},      -- Option text list
    selected_index = number,      -- Default selected index (1-based), default 1
    on_select = function(index, value),  -- Selection callback
    max_visible_items = number,   -- Max visible items at once, default 6
    placeholder = string,         -- Placeholder text when nothing selected
    scrollbar_edge_pad = number,  -- Scrollbar edge padding, default 2
    scroll_bottom_pad = number,   -- Scroll bottom extra padding, default 4
}
```

## How It Works

Dropdown internally maintains a `trigger` (the trigger button) and a `popup` (the popup layer). The `popup` is registered as an independent UiManager root widget at the `DROPDOWN` render layer (80), ensuring it draws above all regular UI.

When options exceed `max_visible_items`, scrolling appears automatically. The popup panel calculates its open direction based on the trigger button's screen position — preferring downward, falling back to upward when space is insufficient. Clicking the popup background area closes the dropdown.

## Lifecycle

The popup is registered with UiManager on `onAttached` and unregistered on `onDetached`. This ensures the dropdown only displays in active scenes.

## Example

```lua
local dropdown = Dropdown({
    options = {"Option A", "Option B", "Option C"},
    selected_index = 1,
    w = 200,
    on_select = function(index, value)
        print("Selected:", index, value)
    end,
})
```
