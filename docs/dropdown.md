# Dropdown

下拉选择组件。点击触发按钮展开选项列表，支持滚动、屏幕边缘自适应和渲染层级管理。

**继承链：** `Widget` → `Dropdown`

## 构造参数（datas）

```lua
{
    options = {string, ...},          -- 选项文本列表
    selected_index = number,          -- 默认选中索引（1-based），默认 1
    on_select = function(index, value),  -- 选中回调
    max_visible_items = number,       -- 同时可见最多选项数，默认 6
    placeholder = string,             -- 未选择时的占位文本（当前未实现）
    scrollbar_edge_pad = number,      -- 滚动条两端距面板边缘的边距（像素），默认 2
    scroll_bottom_pad = number,       -- 滚动内容底部额外空白（像素），默认 4
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `select(index)` | 选择指定索引项（触发 `onSelect` 并关闭弹窗） |
| `getSelectedIndex()` | 获取当前选中索引 |
| `getSelectedValue()` | 获取当前选中文本 |
| `setOptions(options, selected_index)` | 替换选项列表（如在打开状态下调用，会先关闭再重新打开） |
| `getMinimumSize()` | 返回自身 transform 尺寸 |

## 工作原理

- **触发按钮**：Dropdown 内部的 Button，填充整个 Dropdown 区域，点击切换展开/关闭。
- **popup**：作为 UiManager 根 widget（`render_layer = DROPDOWN = 80`），全屏锚点。在 `onAttached` 时注册到 UiManager，`onDetached` 时注销并销毁。
- **panel**：popup 内部的 Panel，绝对定位在触发按钮下方（或上方，空间不足时翻转）。宽度与 Dropdown 一致。
- **选项列表**：选项数 ≤ `max_visible_items` 时直接排列 Button；超出时包裹进 Scroll 容器。
- **关闭**：点击 popup 空白区域、选中选项后自动关闭。popup 拦截 MouseMoved 和 WheelMoved 防止穿透。

## 弹出位置算法

1. 默认 popup 在触发按钮下方，右侧对齐。
2. 若下方空间不足（`pos_y + panel_h > screen_h - 8`），翻转至触发按钮上方。
3. 若右侧空间不足（`pos_x + panel_w > screen_w - 8`），左对齐至触发按钮右边缘。

## 示例

```lua
local dd = Dropdown({
    options = {"Apple", "Banana", "Cherry", "Date", "Elderberry", "Fig", "Grape"},
    selected_index = 1,
    max_visible_items = 4,
    scrollbar_edge_pad = 4,
    on_select = function(index, value)
        print("selected:", index, value)
    end,
    anchor = {0, 0, 0, 0},
    w = 200,
    h = 32,
})

-- 编程操作
dd:select(3)
dd:setOptions({"One", "Two", "Three"}, 1)
```
