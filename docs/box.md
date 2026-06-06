# Box（BoxContainer）

Flexbox 式布局容器，子元素按主轴方向排列，支持 flex-grow/flex-shrink 伸缩分配。

**继承链：** `Widget` → `Box`

## 构造参数（datas）

```lua
{
    orientation = "vertical" | "horizontal",  -- 排列方向，默认 "vertical"
    space = number,               -- 子元素间隔（像素），默认 0
    cross_align = "stretch" | "start" | "center" | "end",  -- 交叉轴对齐，默认 "stretch"
}
```

## 子元素属性

在每个子 widget 上设置以下字段来控制布局行为：

| 字段 | 默认值 | 说明 |
|------|--------|------|
| `flex_grow` | `0` | 剩余空间分配权重 |
| `flex_shrink` | `1` | 空间不足时压缩权重 |
| `flex_min_size` | `0` | 最小主轴尺寸（像素） |

## 公有方法

| 方法 | 说明 |
|------|------|
| `layout()` | 手动触发布局计算 |
| `addChild(child)` | 添加子元素（自动标记脏布局） |
| `removeChild(child)` | 移除子元素 |

布局在 `onUpdate` 中自动触发（脏标记），或在 `onSizeChanged` 时触发。

## 布局算法

1. 收集所有可见子元素，用 `measure()` 获取首选尺寸
2. 计算主轴总首选尺寸 = sum(main_sizes) + space × (n - 1)
3. **有剩余空间** → 按 `flex_grow` 权重分配
4. **空间不足** → 按 `flex_shrink` 权重压缩（不低于 `flex_min_size`）
5. 交叉轴：`stretch` 填充容器、`start`/`center`/`end` 对齐

## 快捷构造

```lua
local BoxV = require "ui.widgets.containers.box_v_container"
local BoxH = require "ui.widgets.containers.box_h_container"
```

## 示例

```lua
local box = Box({
    orientation = "vertical",
    space = 4,
    cross_align = "stretch",
    anchor = {0, 0, 1, 1},
})

-- 固定高度元素
box:addChild(Button({text = "Header", h = 40}))

-- flex_grow 填充剩余空间
local content = Panel({bg_color = Utils.RGB(40, 40, 50)})
content.flex_grow = 1
content.flex_shrink = 1
content.flex_min_size = 100
box:addChild(content)

-- 固定高度元素
box:addChild(Button({text = "Footer", h = 30}))
```
