# RadioGroup

单选按钮组，管理一组 RadioButton 的互斥行为。

**继承链：** `Widget` → `RadioGroup`

## 构造参数（datas）

```lua
{
    items = {                          -- 各选项的 datas 表，会被传给 RadioButton 构造
        {label = string, ...},
        ...
    },
    selected_index = number,           -- 初始选中项索引（1-based）
    on_selection_changed = function(index),  -- 选中变化回调
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `setItems(items, selected_index)` | 设置选项列表，重建所有 RadioButton |
| `getSelected()` | 获取当前选中索引 |
| `setSelected(index)` | 编程式设置选中项 |
| `getMinimumSize()` | 返回自身 transform 尺寸 |

## 互斥机制

每个 RadioButton 的 `on_checked` 回调被注入为 `_onButtonChecked(i)`，该方法：

1. 用 `_handling` 守卫防止级联反选。
2. 将其他所有按钮设为 `setChecked(false)`。
3. 更新 `_selected_index`。
4. 触发 `onSelectionChanged` 回调。

## 自动布局

`setItems()` 中每个 RadioButton 默认垂直排列（`item_h = 28`，`spacing = 4`），也可通过 `datas.anchor` / `datas.padding` 手动覆盖。

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
})

-- 编程设置
group:setSelected(2)
```
