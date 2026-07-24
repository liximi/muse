# ListContainer

线性排列 + key-based diff 复用的列表容器。继承 BoxContainer，融入 Godot Container 体系。

**继承链：** `Widget` → `Container` → `BoxContainer` → `ListContainer`

## 与 BoxContainer 的区别

- 默认 `auto_size = true`、`separation = 8`。
- 提供 `updateItems()` —— 基于 key 的 diff 复用：保留已有控件、创建新控件、移除多余的旧控件。

## 构造参数（datas）

```lua
{
    items = {Widget, ...},    -- 初始子控件
    separation = number,      -- 间距，默认 8
    auto_size = boolean,      -- 自动调整主轴尺寸，默认 true
    -- 其他参数同 BoxContainer
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `setItems(items)` | 全量替换子控件 |
| `updateItems(newData, keyFn, createFn, updateFn)` | 基于 key 的 diff 更新 |
| `insert(item, pos)` | 在指定位置插入（nil = 末尾） |
| `remove(item)` | 移除指定控件 |
| `removeAtPos(pos)` | 移除指定位置控件并返回 |

### updateItems 签名

```lua
list:updateItems(newData, keyFn, createFn, updateFn)
-- keyFn:    function(data) -> key  提取唯一键
-- createFn: function(data) -> Widget  创建新控件（必填）
-- updateFn: function(widget, data)    更新已有控件（可选）
```

## 示例

```lua
local list = ListContainer({
    orientation = "vertical",
    separation = 4,
})

-- diff 更新（保留 widget 状态）
list:updateItems(
    {{id = 1, label = "A"}, {id = 2, label = "B"}},
    function(d) return d.id end,
    function(d) return Button({ text = d.label }) end,
    function(w, d) w:setText(d.label) end
)
```

## 最佳实践

- **推荐**：动态列表（如聊天历史）使用 `updateItems` 保留控件状态（焦点、选中等）。
- **推荐**：`keyFn` 应返回稳定的唯一标识，避免使用数据引用作为 key。
- **不推荐**：频繁全量重建——`setItems` 会销毁所有旧控件。
