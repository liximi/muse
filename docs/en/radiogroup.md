# RadioGroup

A radio button group that manages mutual exclusion among a set of RadioButtons.

**Inheritance chain:** `Widget` → `RadioGroup`

## Constructor Parameters (datas)

```lua
{
    items = {                      -- list of options
        {label = string, ...},     -- each item's datas is passed to the RadioButton constructor
        ...
    },
    selected_index = number,       -- initially selected item index (1-based)
    on_selection_changed = function(index),  -- selection change callback
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `setItems(items, selected_index)` | Set option list, rebuilding all RadioButtons |
| `getSelected()` | Return the currently selected index |
| `setSelected(index)` | Programmatically set the selected item |

## Auto Layout

RadioGroup automatically arranges RadioButtons vertically:
- Each button height: 28px
- Button spacing: 4px

## Mutual Exclusion Mechanism

When any button is selected, all other buttons are automatically deselected. A `_handling` guard prevents cascading deselection.

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
        print("selected:", index)
    end,
    anchor = {0, 0, 1, 0},
    h = 100,
})
```
