# ListContainer

线性排列子控件 + key-based diff 复用。继承 `BoxContainer`，完全融入 Godot Container 体系。

**继承链：** `Widget` → `Container` → `BoxContainer` → `ListContainer`

与 `BoxContainer` 的区别：
- 默认 `auto_size = true`、`separation = 8`
- 提供 `updateItems` diff 复用机制（通过 key 做增删改 diff，保留已有控件状态）
- 提供 `insert` / `remove` / `removeAtPos` / `setItems` 便捷方法

## 构造参数（datas）

```lua
{
    orientation = "vertical" | "horizontal",  -- 排列方向，默认 "vertical"
    separation  = number,    -- 子控件间距（像素），默认 8
    auto_size   = boolean,   -- 是否在主轴方向自动调整尺寸，默认 true
    alignment   = "begin" | "center" | "end", -- 整体对齐（同 BoxContainer），默认 "begin"
    items       = {Widget, ...},  -- 初始子控件列表
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `setItems(items)` | 全量替换子控件。先 `removeAllChildren` 再逐个 `addChild` |
| `updateItems(newData, keyFn, createFn, updateFn)` | **diff 复用更新（推荐）**。通过 key 找出新增/移除/保留的项，复用已有控件 |
| `insert(item, pos)` | 在指定位置插入控件。`pos` 为 nil 时追加到末尾 |
| `remove(item)` | 移除指定控件 |
| `removeAtPos(pos)` | 移除指定位置的控件并返回 |

## updateItems — diff 复用更新

```lua
list:updateItems(newData, keyFn, createFn, updateFn)

-- newData:  新的数据列表
-- keyFn:    function(data) -> key，从数据项提取唯一键。nil 时以数据项自身引用为键
-- createFn: function(data) -> Widget，从数据项创建新控件（必填）
-- updateFn: function(widget, data)，用新数据更新已有控件（可选，nil 时不更新）
```

示例：

```lua
list:updateItems(buttons_data,
    function(d) return d.id end,                       -- key: 用 id 标识
    function(d) return Button({ text = d.label }) end, -- 创建新按钮
    function(w, d) w:setText(d.label) end              -- 更新已有按钮文字
)
```

diff 过程：按 key 顺序遍历新数据 → 已存在则复用并调用 `updateFn`，不存在则 `createFn` 创建 → 旧数据中未复用的控件被 `removeChild`。最后重建 `children` 顺序匹配新数据顺序，调用 `queueSort()` 触发重排。

## 布局

布局完全委托给 `BoxContainer._sortChildren()` 三趟分配算法。ListContainer 覆写 `addChild` / `removeChild` 的队列排序行为继承自 `Container`。

## 示例

```lua
local list = ListContainer({
    orientation = "vertical",
    items = {
        Button({ text = "Item 1" }),
        Button({ text = "Item 2" }),
    },
})

-- 追加
list:insert(Button({ text = "Item 3" }))

-- diff 更新
list:updateItems(
    {{id = "a", label = "A"}, {id = "b", label = "B"}, {id = "c", label = "C"}},
    function(d) return d.id end,
    function(d) return Button({ text = d.label }) end,
    function(w, d) w:setText(d.label) end
)
```
