# TabView

Tabbed view. Top tab button bar + content panel below.

**Inheritance:** `Widget` → `TabView`

## Constructor Parameters (datas)

```lua
{
    tabs = {{label = string, content = Widget}, ...},  -- Tab list
    tab_bar_height = number,    -- Tab bar height, default 36
    selected_index = number,    -- Initial selected index
    on_tab_changed = function(index),  -- Switch callback
}
```

## How It Works

`setTabs()` distributes button anchors proportionally by tab count (e.g., 3 tabs each get 1/3 width). Selecting a tab updates the button visuals via `setSelected` and replaces the content area's child widget.

## Public Methods

| Method | Description |
|--------|-------------|
| `setTabs(tab_list, selected_index)` | Set tab list |
| `selectTab(index)` | Switch to the specified index |
| `getSelected()` | Get current selected index |

## Example

```lua
local tabs = TabView({
    anchor = {0, 0, 1, 1},
    tabs = {
        {label = "General", content = Panel({ bg_color = {0.1, 0.1, 0.15, 1} })},
        {label = "Audio",   content = Panel({ bg_color = {0.1, 0.12, 0.1, 1} })},
    },
    on_tab_changed = function(i) print("Tab:", i) end,
})
```

## Best Practices

- **Do**: Use `TabContainer` (the Container-system version) for complex content areas — it automatically manages child visibility.
- **Do**: Use `removeAllChildren` + `addChild` for content switching to avoid repeated creation.
