# TabContainer

标签页容器（Container 体系内版本）。与 `TabView` 类似，但继承 Container 并自动管理子控件的可见性切换。

**继承链：** `Widget` → `Container` → `TabContainer`

## 构造参数（datas）

```lua
{
    tabs_position = "top" | "bottom",  -- Tab 栏位置，默认 "top"
    tabs_visible = boolean,            -- 是否可见，默认 true
    tab_bar_height = number,           -- Tab 栏高度，默认 36
    selected_index = number,           -- 初始选中索引
    use_hidden_for_min_size = boolean, -- 隐藏的 Tab 内容是否计入最小尺寸，默认 false
}
```

## 工作原理

子控件通过 `addChild` 添加后自动成为标签页，内部 `_rebuildTabBar()` 重建按钮栏。`_sortChildren()` 定位 Tab 栏和当前选中的内容控件，切换时通过 `show()`/`hide()` 控制可见性。

## 公有方法

| 方法 | 说明 |
|------|------|
| `addChild(child)` | 添加标签页（自动重建 Tab 栏） |
| `removeChild(child)` | 移除标签页 |
| `setCurrentTab(idx)` | 切换标签页 |
| `getCurrentTab()` | 获取当前选中索引 |
| `getTabControl(idx)` | 获取指定索引的内容控件 |
| `setTabTitle(idx, title)` | 设置 Tab 标题 |
| `setTabsPosition(pos)` | 设置 Tab 栏位置 |
| `setTabsVisible(visible)` | 设置 Tab 栏可见性 |

## 示例

```lua
local tabs = TabContainer({
    anchor = {0, 0, 1, 1},
    tab_bar_height = 40,
})
tabs:addChild(Panel({ bg_color = {0.1, 0.1, 0.15, 1} }))  -- Tab 1
tabs:addChild(Panel({ bg_color = {0.1, 0.15, 0.1, 1} }))  -- Tab 2
tabs:setTabTitle(1, "General")
tabs:setTabTitle(2, "Audio")
```
