# Modal

模态框组件，全屏半透明遮罩 + 居中内容区域。

**继承链：** `Widget` → `Modal`

## 构造参数（datas）

```lua
{
    overlay_color = {r, g, b, a},         -- 遮罩颜色，默认来自 theme.modal.overlay_color
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
| `getContentContainer()` | 获取内容容器（用于外部直接操作） |
| `show()` | 显示模态框（自动 `moveToTop`） |
| `hide()` | 隐藏模态框 |
| `dismiss()` | 关闭（触发 `onDismiss` 回调后隐藏） |
| `isShowing()` | 是否正在显示 |

## 行为

- **默认隐藏** — 构造后需调用 `show()` 显示
- **遮罩拦截** — 所有鼠标事件被遮罩拦截，不会穿透到背景 UI
- **内容居中** — 内容通过 pivot `{0.5, 0.5}` + anchor `{0.5, 0.5}` 自动居中

## 闭包前向引用

当 `on_click` 闭包引用稍后才创建的 widget（如关闭按钮引用 modal 自身），在闭包之前声明 `local modal`：

```lua
local modal
modal = Modal({
    content = Button({
        text = "Close",
        on_click = function()
            modal:dismiss()  -- 闭包捕获 outer `modal` 变量
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
        -- 在这个 Panel 里添加其他子 widget
    }),
})
modal:show()
```
