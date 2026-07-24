# RadioGroup

Manages mutual exclusion among a group of RadioButtons.

**Inheritance:** `Widget` → `RadioGroup`

## Constructor Parameters (datas)

```lua
{
    items = {{label = string, ...}, ...},  -- Option datas passed to RadioButton
    selected_index = number,
    on_selection_changed = function(index),
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `setItems(items, selected_index)` | Rebuild RadioButtons |
| `getSelected()` | Get selected index |
| `setSelected(index)` | Programmatically select |
| `getMinimumSize()` | Returns own transform size |

## Mutual Exclusion

Each RadioButton's `on_checked` callback fires `_onButtonChecked(i)`, which deselects all other buttons and updates `_selected_index`. A `_handling` guard prevents cascading toggles.

## Example

```lua
local group = RadioGroup({
    items = {
        {label = "Option A"},
        {label = "Option B"},
        {label = "Option C"},
    },
    selected_index = 1,
    on_selection_changed = function(index) print("selected:", index) end,
})
```
