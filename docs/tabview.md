# TabView

标签页视图，顶部 Button 栏 + 下方内容面板。

**继承链：** `Widget` → `TabView`

## 构造参数（datas）

```lua
{
    tabs = {                          -- 标签页列表
        {label = string, content = Widget},
        ...
    },
    tab_bar_height = number,          -- Tab 栏高度，默认 36
    selected_index = number,          -- 初始选中索引（1-based），默认 1
    on_tab_changed = function(index), -- 切换回调
    content_bg = {r, g, b, a},        -- 内容区背景色
    content_rounding_radius = number,  -- 内容区圆角
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `setTabs(tab_list, selected_index)` | 设置标签页列表，重建 Tab 栏和内容 |
| `selectTab(index)` | 切换到指定索引 |
| `getSelected()` | 获取当前选中索引 |

## 行为

- Tab 按钮水平等分 tab_bar 宽度
- 切换时自动更新按钮 `selected` 状态
- 内容区域使用 Panel 作为底衬

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
