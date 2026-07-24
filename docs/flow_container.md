# FlowContainer

流式换行布局容器。子控件沿主轴排列，超出容器时自动换行/换列。对标 CSS 的 `flex-wrap`。

**继承链：** `Widget` → `Container` → `FlowContainer`

## 构造参数（datas）

```lua
{
    orientation = "horizontal" | "vertical",  -- 主轴方向，默认 "horizontal"
    h_separation = number,   -- 列间距，默认 0
    v_separation = number,   -- 行间距，默认 0
    alignment = "begin" | "center" | "end",  -- 行内对齐，默认 "begin"
    last_wrap_alignment = "inherit" | "begin" | "center" | "end",  -- 末行对齐策略，默认 "inherit"
}
```

## 工作原理

使用两趟算法：
1. **第一趟（换行）**：沿主轴扫描子控件，累计宽度（或高度），超出容器时换行。
2. **第二趟（行内分配）**：行内 EXPAND 子控件分配剩余空间，然后应用 `alignment` 偏移。

`last_wrap_alignment` 控制最后一行（可能未填满）的对齐方式：
- `"inherit"`：跟随 `alignment`。
- `"begin"` / `"center"` / `"end"`：独立指定末行对齐。

交叉轴方向禁止 EXPAND（避免换行节点处冲突）。

## 公有方法

| 方法 | 说明 |
|------|------|
| `getLineCount()` | 获取当前行数 |
| `getLineMaxChildCount()` | 获取最大行子控件数 |

## 示例

```lua
local flow = FlowContainer({
    w = 300,
    h_separation = 8,
    v_separation = 8,
})
for i = 1, 10 do
    flow:addChild(Button({ text = "Item " .. i, h_size_flags = 0 }))
end
```
