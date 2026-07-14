# List（ListContainer）

线性列表容器，子元素按主轴方向依次排列。

**继承链：** `Widget` → `List`

## 构造参数（datas）

```lua
{
    orientation = "vertical" | "horizontal",  -- 排列方向，默认 "vertical"
    items = {Widget, ...},       -- 初始子元素列表
    space = number,              -- 元素间隔（像素），默认 8
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `setItems(items)` | 设置子元素列表（**会销毁旧控件**，状态如按钮 pressed、焦点/选区会丢失） |
| `updateItems(data, keyFn, createFn, updateFn)` | **推荐**：diff 复用已有控件，保持旧控件状态。见下方 |
| `insert(item, pos)` | 在指定位置插入元素（pos 可选，默认末尾） |
| `remove(item)` | 移除指定元素 |
| `removeAtPos(pos)` | 移除指定位置元素并返回 |
| `layout()` | 手动触发布局计算 |

### updateItems —— 推荐的内容更新方式

```lua
list:updateItems(
    newData,                          -- 新的数据列表
    function(item) return item.id end,  -- keyFn：从数据提取唯一键（可选，默认按引用）
    function(item) return Button({ text = item.label }) end,  -- createFn：创建新控件
    function(widget, item) widget:setText(item.label) end     -- updateFn：更新已有控件（可选）
)
```

流程：通过 key 匹配已有控件 → 复用并调 `updateFn` 原地更新 → 无匹配的调 `createFn` 创建 → 多余的旧控件移除。不销毁复用控件，按钮状态/焦点/选区保留。

> **不要每帧调用 `setItems`**：每帧 `removeAllChildren + addChild` 会重建所有控件，
> 按钮 `pressed` 状态、TextInput 焦点/光标/选区都会丢失。数据变化时用 `updateItems` 替代。

## 自动布局

- 子元素按主轴方向依次排列，间距为 `space`
- 容器尺寸自动等于所有子元素尺寸之和 + 间距
- 子元素尺寸变化时自动重新布局（通过每帧 `measure()` 检测变化）

## 快捷构造

```lua
-- 垂直列表
local ListV = require "ui.widgets.containers.list_v_container"
local list = ListV({space = 4})

-- 水平列表
local ListH = require "ui.widgets.containers.list_h_container"
local list = ListH({space = 8})
```

## 示例

```lua
local list = List({
    orientation = "vertical",
    space = 4,
    items = {
        Button({text = "Item 1", h = 30}),
        Button({text = "Item 2", h = 30}),
        Button({text = "Item 3", h = 30}),
    },
})

-- 动态追加
list:insert(Button({text = "Item 4", h = 30}))
```
