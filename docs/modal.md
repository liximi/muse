# Modal

模态框。全屏半透明遮罩 + 居中内容区域，拦截所有背景交互。

**继承链：** `Widget` → `Modal`

## 构造参数（datas）

```lua
{
    overlay_color = {r, g, b, a},     -- 遮罩颜色
    dismiss_on_outside_click = boolean, -- 点击内容外是否关闭，默认 true
    dismiss_on_escape = boolean,      -- Escape 键是否关闭，默认 true
    content = Widget,                 -- 初始内容
    on_dismiss = function,            -- 关闭回调
}
```

## 工作原理

Modal 默认隐藏，需调用 `show()` 显示。遮罩 overlay 拦截所有鼠标事件（MousePressed/Released/Moved/WheelMoved），防止穿透到背景 UI。子元素优先处理事件（内容区域内的按钮等），未被处理的才被遮罩拦截。

内容通过 `content_container`（居中锚点 `{0.5, 0.5, 0.5, 0.5}`）自动居中。

## 公有方法

| 方法 | 说明 |
|------|------|
| `show()` | 显示模态框 |
| `hide()` | 隐藏模态框 |
| `dismiss()` | 关闭（触发 `on_dismiss` 后隐藏） |
| `isShowing()` | 是否正在显示 |
| `setContent(widget)` | 设置内容 |
| `getContentContainer()` | 获取内容容器 |

## 示例

```lua
local modal = Modal({
    dismiss_on_outside_click = true,
    dismiss_on_escape = true,
    content = Panel({
        w = 300, h = 200,
        bg_color = {0.15, 0.15, 0.2, 1},
        rounding_radius = 8,
    }),
    on_dismiss = function() print("modal closed") end,
})

modal:show()  -- 添加到根 widget 并显示
```

## 最佳实践

- **推荐**：Modal 构造后作为 UiManager 根 widget 添加，`show()`/`hide()` 控制可见性。
- **推荐**：内容区域使用 `w`/`h` 设置固定尺寸，`content_container` 会自动居中。
- **不推荐**：在同一个场景中创建多个 Modal 实例而不复用——反复创建销毁成本高。
