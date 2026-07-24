# SliderBar

滑块控件。支持水平和垂直方向，可配置滑块尺寸、步长吸附和缓动动画。

**继承链：** `Widget` → `SliderBar`

## 构造参数（datas）

```lua
{
    orientation = "vertical" | "horizontal",  -- 方向，默认 "vertical"
    max_limit = number,           -- 最大值，默认 1
    block_length_percent = number, -- 滑块长度占轨道百分比
    block_min_len = number,       -- 滑块最小长度（像素），默认 0
    step = number,                -- 步长（0 = 连续模式，>0 = 吸附到步长倍数），默认 0
    sensitivity = number,         -- 点击轨道时的移动灵敏度
    on_value_update = function(value, percent),  -- 值变化回调
}
```

## 工作原理

### 交互方式

- **拖拽滑块**：直接拖动滑块 block。
- **点击轨道**：在滑块两侧的轨道区域点击，滑块以缓动动画移动到该位置。
- **长按轨道**：按住超过 0.25 秒后连续移动。

### 步长吸附

`step > 0` 时，拖拽和点击都会吸附到最近的步长倍数。拖拽时位置由缓动动画（`outQuad`，0.15 秒）驱动，值立即更新。

### 圆角

滑块的圆角半径自动计算为薄边尺寸的一半加 1px，确保两端呈半圆形。

## 示例

```lua
-- 垂直滑块（Scroll 使用的就是 SliderBar）
local bar = SliderBar({
    orientation = "vertical",
    max_limit = 500,
    block_length_percent = 0.2,
    on_value_update = function(val, percent)
        print("Value:", val)
    end,
})

-- 步长滑块（每次吸附到 10 的倍数）
local stepped = SliderBar({
    orientation = "horizontal",
    max_limit = 100,
    step = 10,
    block_length_percent = 0.1,
})
```
