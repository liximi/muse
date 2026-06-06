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
| `setItems(items)` | 设置子元素列表（替换所有） |
| `insert(item, pos)` | 在指定位置插入元素（pos 可选，默认末尾） |
| `remove(item)` | 移除指定元素 |
| `removeAtPos(pos)` | 移除指定位置元素并返回 |
| `layout()` | 手动触发布局计算 |

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
