# CollapsiblePanel（高级组件）

水平屏幕边缘停靠可收起面板，点击折叠按钮以 `outQuint` 缓动动画展开/收起。

**继承链：** `Widget` → `Panel` → `CollapsiblePanel`

## 构造参数（datas）

```lua
{
    right = boolean,  -- 是否停靠在右侧屏幕边缘，默认 false（左侧）
    -- ... 同时继承 Panel 的所有参数
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `toggleOpen()` | 切换展开/收起状态（带缓动动画） |
| `setMode(right)` | 设置停靠模式：`false`=左侧，`true`=右侧 |

## 行为

- 展开时面板边缘对齐屏幕边缘
- 收起时面板滑出屏幕（仅露出折叠按钮）
- 折叠按钮图标自动适配方向（左右箭头）
- 动画时长 0.3 秒，使用 `outQuint` 缓动

## 属性

| 属性 | 说明 |
|------|------|
| `open` | 当前是否展开 |
| `right` | 当前停靠模式 |

## 示例

```lua
local panel = CollapsiblePanel({
    right = true,  -- 右侧停靠
    w = 300,
    bg_color = Utils.RGB(40, 40, 50),
    rounding_radius = 8,
})

-- 点击折叠按钮触发展开/收起
panel.collapse_btn.onClick = function()
    panel:toggleOpen()
end
```
