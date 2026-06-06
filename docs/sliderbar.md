# SliderBar

滑块组件，支持水平和垂直方向。包含轨道背景和可拖拽的滑块（Button）。

**继承链：** `Widget` → `SliderBar`

## 构造参数（datas）

```lua
{
    orientation = "vertical" | "horizontal",  -- 方向，默认 "vertical"
    max_limit = number,           -- 最大值，默认 1
    block_length_percent = number, -- 滑块长度占轨道比例 0~1，默认 0.1
    block_min_len = number,       -- 滑块最小长度（像素），默认 0
    sensitivity = number,         -- 点击轨道/滚轮灵敏度，默认 0.8
    on_value_update = function(value, percent),  -- 值变化回调
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `setValue(val)` | 设置当前值（0 ~ max_limit），不触发回调 |
| `setPercent(percent)` | 按百分比设置值（0~1） |
| `setMaxLimit(max)` | 设置最大值（自动 clamp 当前值并触发回调） |
| `setBlockLengthPercent(percent)` | 设置滑块长度比例（自动 clamp 0~1） |
| `setOnValueUpdateFn(callback_fn)` | 设置值变化回调函数 |

## 交互

| 操作 | 行为 |
|------|------|
| 拖拽滑块 | 实时更新值 |
| 点击轨道空白区域 | 向点击方向步进（delta = 滑块长度 × sensitivity） |
| 长按轨道 | 每 0.25 秒重复步进 |
| 窗口 resize | 滑块尺寸和圆角自动适配 |

## 滑块圆角

滑块两端为半圆形，圆角半径由薄边尺寸计算（垂直滑块取宽度，水平滑块取高度），在 `onSizeChanged` 和 `setBlockLengthPercent` 时同步更新。

## 快捷构造

```lua
-- 水平滑块
local SliderBarH = require "ui.widgets.sliderbar_h"
local h = SliderBarH({h = 12, anchor = {0, 0, 1, 0}})

-- 垂直滑块
local SliderBarV = require "ui.widgets.sliderbar_v"
local v = SliderBarV({w = 12, anchor = {0, 0, 0, 1}})
```

## 示例

```lua
local slider = SliderBar({
    orientation = "horizontal",
    anchor = {0, 0, 1, 0},
    h = 16,
    max_limit = 100,
    block_length_percent = 0.15,
    on_value_update = function(value, percent)
        print(string.format("value: %.0f (%.0f%%)", value, percent * 100))
    end,
})
slider:setValue(50)
```
