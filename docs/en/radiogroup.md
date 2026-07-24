# RadioGroup

Radio button group. Manages mutual exclusion among a set of RadioButtons — selecting one automatically deselects the others.

**Inheritance:** `Widget` → `RadioGroup`

## Constructor Parameters (datas)

```lua
{
    items = {{label = string, ...}, ...},  -- Per-option datas tables, passed to RadioButton constructor
    selected_index = number,    -- Initial selected index
    on_selection_changed = function(index),  -- Selection change callback
}
```

## How It Works

`setItems()` creates a set of RadioButtons from the provided datas, auto-arranging them vertically and injecting an `on_checked` callback into each. When any button is checked, `_onButtonChecked` deselects all other buttons, implementing mutual exclusion. A `_handling` guard prevents cascading deselection.

## Public Methods

| Method | Description |
|--------|-------------|
| `setItems(items, selected_index)` | Set option list |
| `getSelected()` | Get current selected index |
| `setSelected(index)` | Programmatically select an item |

## Example

```lua
local group = RadioGroup({
    items = {
        {label = "Option A"},
        {label = "Option B"},
        {label = "Option C"},
    },
    selected_index = 1,
    on_selection_changed = function(index)
        print("Selected:", index)
    end,
})
```
