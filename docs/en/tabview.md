# TabView

A tabbed view with a top Button bar and a content panel below.

**Inheritance chain:** `Widget` → `TabView`

## Constructor Parameters (datas)

```lua
{
    tabs = {                          -- tab list
        {label = string, content = Widget},
        ...
    },
    tab_bar_height = number,          -- tab bar height, default 36
    selected_index = number,          -- initially selected index (1-based), default 1
    on_tab_changed = function(index), -- switch callback
    content_bg = {r, g, b, a},        -- content area background color
    content_rounding_radius = number,  -- content area corner radius
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `setTabs(tab_list, selected_index)` | Set tab list, rebuild tab bar and content |
| `selectTab(index)` | Switch to the specified index |
| `getSelected()` | Get the currently selected index |

## Behavior

- Tab buttons evenly divide the tab bar width horizontally
- Button `selected` state is automatically updated on tab switch
- Content area uses a Panel as the backer

## Example

```lua
local tabview = TabView({
    anchor = {0, 0, 1, 1},
    tabs = {
        {label = "General", content = Panel({bg_color = Utils.RGB(50, 50, 60)})},
        {label = "Advanced", content = Panel({bg_color = Utils.RGB(60, 50, 50)})},
        {label = "About", content = Text({text = "About text"})},
    },
    on_tab_changed = function(index)
        print("switched to tab", index)
    end,
})
```
