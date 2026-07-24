# GridContainer

固定列数网格布局容器。

**继承链：** `Widget` → `Container` → `GridContainer`

## 构造参数（datas）

```lua
{
    columns = number,         -- 列数，默认 2
    h_separation = number,    -- 列间距，默认 0
    v_separation = number,    -- 行间距，默认 0
}
```

## 工作原理

使用三趟分配算法：

1. **收集**：扫描子控件，按行列分组，收集每列最大 min_w/desired_w 和每行最大 min_h/desired_h。
2. **分配**：先按 desired 比例分配剩余空间，再按 EXPAND 分配。装不下最小尺寸的列/行从 EXPAND 池中移除，超出 max 的也被移除。
3. **定位**：按最终列宽/行高逐个 `fitChildInRect`。

## 公有方法

| 方法 | 说明 |
|------|------|
| `setColumns(n)` | 设置列数 |

## 示例

```lua
local grid = GridContainer({
    columns = 3,
    h_separation = 8,
    v_separation = 8,
})
for i = 1, 9 do
    grid:addChild(Button({ text = tostring(i) }))
end
```
