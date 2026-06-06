# RadioGroup

单选按钮组，管理一组 RadioButton 的互斥行为。

**继承链：** `Widget` → `RadioGroup`

## 构造参数（datas）

```lua
{
    items = {                      -- 选项列表
        {label = string, ...},     -- 每个 item 的 datas 会传给 RadioButton 构造
        ...
    },
    selected_index = number,       -- 初始选中项索引（1-based）
    on_selection_changed = function(index),  -- 选中变更回调
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `setItems(items, selected_index)` | 设置选项列表，重建所有 RadioButton |
| `getSelected()` | 返回当前选中索引 |
| `setSelected(index)` | 编程式设置选中项 |

## 自动布局

RadioGroup 自动垂直排列 RadioButton：
- 每个按钮高度：28px
- 按钮间距：4px

## 互斥机制

当任一按钮被选中时，自动取消其他按钮的选中状态。通过 `_handling` 守卫防止级联反选。

## 示例

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
