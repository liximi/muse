# Dropdown

下拉选择框。点击触发按钮弹出选项列表，选中后自动关闭。

**继承链：** `Widget` → `Dropdown`

## 构造参数（datas）

```lua
{
    options = {string, ...},      -- 选项文本列表
    selected_index = number,      -- 默认选中索引（1-based），默认 1
    on_select = function(index, value),  -- 选中回调
    max_visible_items = number,   -- 同时可见最多选项数，默认 6
    placeholder = string,         -- 未选择时的占位文本
    scrollbar_edge_pad = number,  -- 滚动条边距，默认 2
    scroll_bottom_pad = number,   -- 滚动底部额外边距，默认 4
}
```

## 工作原理

Dropdown 内部维护一个 `trigger`（触发按钮）和一个 `popup`（弹出层）。`popup` 作为独立的 UiManager 根 widget 注册，使用 `DROPDOWN` 渲染层（80），确保在所有常规 UI 之上绘制。

选项列表超过 `max_visible_items` 时自动出现滚动。弹出面板根据触发按钮的屏幕位置计算打开方向——优先向下打开，空间不足时向上打开。点击 popup 空白区域关闭下拉。

## 生命周期

`onAttached` 时将 popup 注册到 UiManager，`onDetached` 时注销。这确保 Dropdown 只在活动场景中显示。

## 示例

```lua
local dropdown = Dropdown({
    options = {"Option A", "Option B", "Option C"},
    selected_index = 1,
    w = 200,
    on_select = function(index, value)
        print("Selected:", index, value)
    end,
})
```
