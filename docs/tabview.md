# TabView

标签页视图，顶部 Button 栏 + 下方内容面板。Button 用 `selected` 状态标记当前激活的 Tab。

**继承链：** `Widget` → `TabView`

## 构造参数（datas）

```lua
{
    tabs = {                          -- 标签页列表
        {label = string, content = Widget},
        ...
    },
    tab_bar_height = number,          -- Tab 栏高度，默认来自 theme（36）
    selected_index = number,          -- 初始选中索引（1-based），默认 1
    on_tab_changed = function(index), -- 切换回调
    content_bg = {r, g, b, a},        -- 内容区背景色，默认来自 theme
    content_rounding_radius = number,  -- 内容区圆角，默认来自 theme
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `setTabs(tab_list, selected_index)` | 设置标签页列表，重建 Tab 栏和内容 |
| `selectTab(index)` | 切换到指定索引（1-based） |
| `getSelected()` | 获取当前选中索引 |
| `getMinimumSize()` | 返回自身 transform 尺寸 |

## 工作原理

- **tab_bar**：高度 `tab_bar_height`，使用 `anchor={0,0,1,0}` 固定在顶部。
- **content_area**：Panel，`padding = {0, 0, tab_bar_height, 0}` 为 Tab 栏留出空间。
- **Tab 按钮**：水平等分 tab_bar 宽度（锚点 `{(i-1)/n, 0, i/n, 1}`），使用 `normal` 和 `selected` 两种状态样式。
- **切换**：点击按钮 → `selectTab(i)` → 取消旧按钮的 `setSelected(false)` → 设置新按钮的 `setSelected(true)` → 替换 `content_area` 的子控件。

## 示例

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
