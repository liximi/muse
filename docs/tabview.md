# TabView

标签页视图。顶部 Tab 按钮栏 + 下方内容面板。

**继承链：** `Widget` → `TabView`

## 构造参数（datas）

```lua
{
    tabs = {{label = string, content = Widget}, ...},  -- 标签页列表
    tab_bar_height = number,    -- Tab 栏高度，默认 36
    selected_index = number,    -- 初始选中索引
    on_tab_changed = function(index),  -- 切换回调
}
```

## 工作原理

`setTabs()` 根据标签数量按比例分配按钮锚点（如 3 个 Tab 各占 1/3 宽），选中状态切换时通过 `setSelected` 更新按钮视觉，并替换内容区域的子控件。

## 公有方法

| 方法 | 说明 |
|------|------|
| `setTabs(tab_list, selected_index)` | 设置标签页列表 |
| `selectTab(index)` | 切换到指定索引 |
| `getSelected()` | 获取当前选中索引 |

## 示例

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

## 最佳实践

- **推荐**：内容区域较复杂时使用 `TabContainer`（Container 体系内的版本，自动管理子控件可见性）。
- **推荐**：Tab 内容使用 `removeAllChildren` + `addChild` 切换，避免重复创建。
