# TabView

Tabbed view with top button bar and content panel below.

**Inheritance:** `Widget` → `TabView`

## Constructor Parameters (datas)

```lua
{
    tabs = {{label = string, content = Widget}, ...},
    tab_bar_height = number,          -- Default from theme (36)
    selected_index = number,          -- Default 1
    on_tab_changed = function(index),
    content_bg = {r, g, b, a},
    content_rounding_radius = number,
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `setTabs(tab_list, selected_index)` | Rebuild tabs and content |
| `selectTab(index)` | Switch to tab (1-based) |
| `getSelected()` | Get current tab index |
| `getMinimumSize()` | Returns own transform size |

## How It Works

- **tab_bar**: fixed height at top (`anchor={0,0,1,0}`).
- **content_area**: Panel with `padding = {0, 0, tab_bar_height, 0}`.
- **Tab buttons**: equally divided horizontally with `normal` and `selected` state styles.
- **Switching**: deselects old button, selects new, replaces content.

## Example

```lua
local tabview = TabView({
    anchor = {0, 0, 1, 1},
    tabs = {
        {label = "General", content = Panel({bg_color = Utils.RGB(50, 50, 60)})},
        {label = "Advanced", content = Panel({bg_color = Utils.RGB(60, 50, 50)})},
    },
    on_tab_changed = function(index) print("tab:", index) end,
})
```
