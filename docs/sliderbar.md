# SliderBar

滑块组件，支持水平和垂直方向。包含轨道背景和可拖拽的滑块（Button）。支持连续模式和整数步长模式。

**继承链：** `Widget` → `SliderBar`

## 构造参数（datas）

```lua
{
    orientation = "vertical" | "horizontal",  -- 方向，默认 "vertical"
    max_limit = number,           -- 最大值，默认 1
    block_length_percent = number, -- 滑块长度占轨道比例 0~1，默认从 theme 读取（0.1）
    block_min_len = number,       -- 滑块最小长度（像素），默认 0
    step = number,               -- 步长，默认 0（连续模式）。>0 时值 snap 到最近步长倍数
    sensitivity = number,         -- 点击轨道/长按时的步进灵敏度，默认来自 theme（0.8）
    on_value_update = function(value, percent),  -- 值变化回调
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `setValue(val)` | 设置当前值（0 ~ max_limit），不触发回调，自动 snap |
| `setPercent(percent)` | 按百分比设置值（0~1） |
| `setMaxLimit(max)` | 设置最大值（自动 clamp 当前值并触发回调） |
| `setBlockLengthPercent(percent)` | 设置滑块长度比例（自动 clamp 0~1） |
| `setOnValueUpdateFn(callback_fn)` | 设置值变化回调函数 |
| `getMinimumSize()` | 返回自身 transform 尺寸 |

## 交互

| 操作 | 行为 |
|------|------|
| 拖拽滑块 | 实时更新值。步长模式下用缓动动画 snap 到最近刻度 |
| 点击轨道空白区域 | 向点击方向步进（delta = 滑块长度 × sensitivity），带缓动动画 |
| 长按轨道 | 每 0.25 秒重复步进，带缓动动画 |
| 窗口 resize | 滑块尺寸和圆角自动适配 |

## 步长模式（step）

`step` 参数控制值的粒度：

| step 值 | 模式 | 示例（max_limit=100）|
|---------|------|----------------------|
| 0 或不传 | 连续浮点 | 可拖到 37.2、81.5 等任意值 |
| 1 | 整数步长 | 值只取 0, 1, 2, ..., 100 |
| 5 | 5 的倍数 | 值只取 0, 5, 10, ..., 100 |
| 0.5 | 半整数 | 值只取 0, 0.5, 1.0, ..., 100 |

步长 snap 在拖拽、点击轨道、长按等所有交互中均生效，`setValue`/`setPercent` 也会自动 snap。拖拽过程中越过吸附边界时用 `outQuad` 缓动（0.15 秒）平滑过渡。

## 滑块圆角

滑块两端为半圆形，圆角半径由薄边尺寸自动计算（垂直滑块取宽度，水平滑块取高度），最小值 1px。尺寸变化或 `setBlockLengthPercent` 时自动更新。

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
-- 连续模式（默认）
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

-- 整数步长模式
local int_slider = SliderBar({
    orientation = "horizontal",
    max_limit = 120,
    step = 1,
    block_length_percent = 0.1,
    block_min_len = 15,
})
int_slider:setValue(90)  -- 值始终为整数，拖拽时带缓动 snap
```
