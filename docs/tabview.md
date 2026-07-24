# TabContainer

标签页容器，顶部/底部 TabBar + 内容区域。继承 Container，添加的子控件自动成为标签页。

**继承链：** `Container` → `TabContainer`

## 构造参数（datas）

```lua
{
    tabs_position          = "top" | "bottom",  -- Tab 栏位置，默认 "top"
    tabs_visible           = boolean,            -- 是否显示 Tab 栏，默认 true
    tab_bar_height         = number,             -- Tab 栏高度，默认来自 theme（36）
    selected_index         = number,             -- 初始选中索引（1-based）
    use_hidden_for_min_size = boolean,           -- 计算 min size 时是否包含隐藏 tab，默认 false
    content_bg             = {r, g, b, a},       -- 内容区背景色，默认来自 theme
    content_rounding_radius = number,             -- 内容区圆角，默认来自 theme
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `addChild(widget)` | 添加标签页。widget 的 `name` 自动成为 tab 标题 |
| `removeChild(widget)` | 移除标签页 |
| `getTabCount()` | 返回标签页数量 |
| `getCurrentTab()` | 返回当前选中索引 |
| `setCurrentTab(idx)` | 切换到指定索引（1-based） |
| `getTabControl(idx)` | 返回第 idx 个标签页的控件 |
| `setTabTitle(idx, title)` | 覆盖第 idx 个标签页的标题 |
| `getTabTitle(idx)` | 获取标签页标题 |
| `setTabsPosition(pos)` | 设置 Tab 栏位置（"top"/"bottom"） |
| `getTabsPosition()` | 获取 Tab 栏位置 |
| `setTabsVisible(visible)` | 设置 Tab 栏可见性 |
| `areTabsVisible()` | 查询 Tab 栏是否可见 |
| `getMinimumSize()` | 返回容器最小尺寸 |
| `getDesiredSize()` | 返回容器期望尺寸 |

## 工作原理

- **TabBar**：内部 HBox，放置等宽 Tab 按钮，选中态用 `selected` 样式。
- **内容区域**：选中子控件填满内容区，其余子控件 `hide()`。子控件始终保持在 TabContainer 内，不移入移出。
- **Tab 标题**：默认取自子控件的 `name` 属性，可通过 `setTabTitle` 覆盖。
- **按钮状态**：`_rebuildTabBar` 在每次 `addChild`/`removeChild` 后重建所有按钮并恢复选中状态。

## 示例

```lua
local tc = TabContainer({
    anchor = {0, 0, 1, 1},
})

local page1 = Widget({ name = "General" })
page1:addChild(Text({ text = "General settings" }))
tc:addChild(page1)

local page2 = Widget({ name = "Advanced" })
page2:addChild(Text({ text = "Advanced settings" }))
tc:addChild(page2)
```
