# Modal

模态框组件，全屏半透明遮罩 + 居中内容区域。遮罩拦截所有鼠标事件防止穿透。

**继承链：** `Widget` → `Modal`

## 构造参数（datas）

```lua
{
    overlay_color = {r, g, b, a},         -- 遮罩颜色，默认来自 theme.modal.overlay_color ({0,0,0,0.5})
    dismiss_on_outside_click = boolean,   -- 点击内容区域外是否关闭，默认 true
    dismiss_on_escape = boolean,          -- Escape 键是否关闭，默认 true
    content = Widget,                     -- 初始内容 widget
    on_dismiss = function(),              -- 关闭回调
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `setContent(widget)` | 设置模态框内容（替换旧内容） |
| `getContentContainer()` | 获取内容容器 Widget，用于外部直接添加子控件 |
| `show()` | 显示模态框（自动 `moveToTop`） |
| `hide()` | 隐藏模态框 |
| `dismiss()` | 关闭（触发 `onDismiss` 回调后隐藏） |
| `isShowing()` | 是否正在显示 |

## 工作原理

- **默认隐藏**：构造后 `shown = false`，必须调用 `show()` 显示。
- **全屏遮罩**：`overlay` 是 Panel，锚点 `{0,0,1,1}` 填满窗口。遮罩覆写 `onMousePressed`/`onMouseReleased`/`onMouseMoved`/`onWheelMoved` 全部返回 `true`，彻底阻断事件穿透。
- **内容居中**：`content_container` 使用 `pivot={0.5,0.5}` + `anchor={0.5,0.5,0.5,0.5}` 自动居中。内容区域外的点击触发 `dismiss()`。
- **关闭**：Escape 键或点击内容外区域触发 `dismiss()`，先 `hide()` 再调用 `onDismiss` 回调。

## 闭包前向引用

当 `on_click` 闭包引用稍后才创建的 modal 自身时，需在闭包之前声明 `local modal`：

```lua
local modal
modal = Modal({
    content = Button({
        text = "Close",
        on_click = function()
            modal:dismiss()  -- 闭包捕获 outer modal 变量
        end,
    }),
})
modal:show()
```

## 示例

```lua
local modal = Modal({
    dismiss_on_outside_click = true,
    dismiss_on_escape = true,
    on_dismiss = function()
        print("modal dismissed")
    end,
    content = Panel({
        w = 300,
        h = 200,
        bg_color = Utils.RGB(50, 50, 60),
    }),
})
modal:show()
```
