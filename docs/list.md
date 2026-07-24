# List

线性列表容器，子元素沿主轴依次排列。通过 diff 算法 (`updateItems`) 支持高效的列表更新（复用已有控件）。

**继承链：** `Widget` → `List`

> **注意**：List 不是 Container 的子类，而是 Widget 的直接子类。它有自己的布局逻辑（`layout()`），不参与 Godot Container 的 SizeFlags 系统。对于新代码，推荐使用 `BoxContainer`；List 主要用于需要 `updateItems` diff 复用的场景（如 `chat_history`）。

## 构造参数（datas）

```lua
{
    orientation = "vertical" | "horizontal",  -- 排列方向，默认 "vertical"
    items = {Widget, ...},   -- 初始子控件列表
    space = number,          -- 元素之间的间隔（像素），默认 8
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `setItems(items)` | 全量替换子控件（不保留旧控件状态）。先 `removeAllChildren` 再逐个 `addChild` |
| `updateItems(newData, keyFn, createFn, updateFn)` | diff 复用更新（推荐）。通过 key 找出新增/移除/保留的项，复用已有控件 |
| `insert(item, pos)` | 插入子控件 |
| `remove(item)` | 移除指定子控件 |
| `removeAtPos(pos)` | 移除指定位置的子控件 |

## updateItems — diff 复用更新

`updateItems` 是 List 的核心方法。它接收新数据列表，通过 key 函数做 diff，复用已有的 widget 实例，避免销毁重建导致的状态丢失（如按钮选中状态、输入焦点等）。

```lua
-- 签名
list:updateItems(newData, keyFn, createFn, updateFn)

-- newData: 新的数据列表
-- keyFn: function(data) -> key，从数据项提取唯一键。nil 时以数据项自身引用为键
-- createFn: function(data) -> Widget，从数据项创建新控件（必填）
-- updateFn: function(widget, data)，用新数据更新已有控件（可选，nil 时不更新）
```

示例：

```lua
list:updateItems(buttons_data,
    function(d) return d.id end,                    -- key: 用 id 标识
    function(d) return Button({ text = d.label }) end,  -- 创建新按钮
    function(w, d) w:setText(d.label) end              -- 更新已有按钮文字
)
```

diff 过程：按 `key_order` 遍历新数据 → 已存在则复用并调用 `updateFn`，不存在则 `createFn` 创建 → 旧数据中未复用的控件被 `removeChild`。

## layout 机制

`layout()` 沿主轴逐个放置子控件，使用 `measure()` 获取每个子控件的自然尺寸来计算位置偏移。`onUpdate` 每帧检测子控件尺寸变化（缓存 `_child_sizes` 做比较），变化时自动触发布局重排。最后将 List 自身尺寸设为子控件总尺寸（主轴方向）。

## 示例

```lua
local list = List({
    orientation = "vertical",
    space = 4,
    items = {
        Button({ text = "Item 1" }),
        Button({ text = "Item 2" }),
    },
})

-- 追加
list:insert(Button({ text = "Item 3" }))

-- diff 更新
list:updateItems(
    {{id = "a", label = "Updated A"}, {id = "b", label = "Updated B"}, {id = "c", label = "New C"}},
    function(d) return d.id end,
    function(d) return Button({ text = d.label }) end,
    function(w, d) w:setText(d.label) end
)
```
