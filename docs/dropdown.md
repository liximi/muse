# Dropdown

下拉选择组件，点击触发按钮展开选项列表。

**继承链：** `Widget` → `Dropdown`

## 构造参数（datas）

```lua
{
    options = {string, ...},          -- 选项文本列表
    selected_index = number,          -- 默认选中索引（1-based），默认 1
    on_select = function(index, value),  -- 选中回调
    max_visible_items = number,       -- 同时可见最多选项数，默认 6
    placeholder = string,             -- 未选择时的占位文本
    scrollbar_edge_pad = number,      -- 滚动条两端边距（像素），默认 2
    scroll_bottom_pad = number,       -- 滚动内容底部空白（像素），默认 4
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `select(index)` | 选择指定索引项（触发 `onSelect` 并关闭弹窗） |
| `getSelectedIndex()` | 获取当前选中索引 |
| `getSelectedValue()` | 获取当前选中文本 |
| `setOptions(options, selected_index)` | 替换选项列表 |

## 静态方法

| 方法 | 说明 |
|------|------|
| `Dropdown.destroyAll()` | 销毁所有活跃 Dropdown 的 popup（测试场景切换时使用） |

## 行为

- 弹出层作为 UiManager 根 widget，全屏锚点
- 渲染层级：`DROPDOWN = 80`
- 选项数 ≤ `max_visible_items` 时直接排列
- 选项数 > `max_visible_items` 时包裹进 Scroll 容器
- 弹出位置自动避开屏幕边缘（上下翻转、左右对齐）
- 点击弹出层空白区域关闭
- 弹出层拦截 MouseMoved 防止穿透

## 示例

```lua
local dd = Dropdown({
    options = {"Apple", "Banana", "Cherry", "Date", "Elderberry"},
    selected_index = 1,
    max_visible_items = 4,
    on_select = function(index, value)
        print("selected:", index, value)
    end,
    anchor = {0, 0, 0, 0},
    w = 200,
    h = 32,
})
```
