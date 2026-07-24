# RadioGroup

单选按钮组。管理一组 RadioButton 的互斥行为——选中一个自动取消其余。

**继承链：** `Widget` → `RadioGroup`

## 构造参数（datas）

```lua
{
    items = {{label = string, ...}, ...},  -- 各选项的 datas 表，传给 RadioButton 构造
    selected_index = number,    -- 初始选中索引
    on_selection_changed = function(index),  -- 选中变化回调
}
```

## 工作原理

`setItems()` 根据传入的 datas 列表创建一组 RadioButton，自动垂直排列并为每个注入 `on_checked` 回调。当任一按钮被选中时，`_onButtonChecked` 取消其余按钮的选中状态，实现互斥逻辑。使用 `_handling` 守卫防止级联反选。

## 公有方法

| 方法 | 说明 |
|------|------|
| `setItems(items, selected_index)` | 设置选项列表 |
| `getSelected()` | 获取当前选中索引 |
| `setSelected(index)` | 编程式设置选中项 |

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
        print("Selected:", index)
    end,
})
```
