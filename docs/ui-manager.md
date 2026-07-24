# UiManager

UiManager 是全局单例，管理顶层 widget 层级、焦点、主题、渲染层缓存和事件分发。

## 获取实例

```lua
local UiManager = require "ui.ui_manager":GetInstance()
```

## 公有方法

### Widget 管理

| 方法 | 说明 |
|------|------|
| `addWidget(widget)` | 将 widget 添加为根节点。自动调用 `_setAttached(true)` |
| `removeWidget(widget)` | 从根节点移除 widget。返回是否成功 |
| `moveToTop(widget)` / `moveToBottom(widget)` | 移动根 widget 的渲染/事件顺序 |
| `invalidateRenderCache()` | 标记渲染层缓存失效 |
| `getWidgetCount()` | 获取活动 widget 总数 |

### 焦点管理

| 方法 | 说明 |
|------|------|
| `setFocus(widget)` | 设置焦点 |
| `getFocus()` | 返回当前焦点 |
| `clearFocus()` | 清除焦点 |

`Tab` 键循环切换 `focusable = true` 的 widget（`Shift+Tab` 反向）。点击 widget 外部自动清除焦点。

### 主题

| 方法 | 说明 |
|------|------|
| `getDefaultTheme()` / `setDefaultTheme(theme)` | 获取/设置默认主题 |

### 事件分发

从 hierarchy **末尾向前**遍历（后添加的先收到事件）。除 `update`/`draw` 外均返回 `boolean`（`true` = UI 消费）。

| 方法 | 对应 LÖVE 事件 |
|------|---------------|
| `update(dt)` | `love.update` |
| `draw()` | `love.draw` — 按 render_layer 升序分层绘制 |
| `KeyPressed(key, isrepeat)` | `love.keypressed` — Tab 由 Manager 拦截 |
| `KeyReleased(key)` | `love.keyreleased` |
| `TextInput(text)` | `love.textinput` |
| `MouseMoved/MousePressed/MouseReleased/WheelMoved` | 对应鼠标事件 |

### 事件消费判断

```lua
function love.mousepressed(x, y, button)
    local ui_handled = UiManager:MousePressed(x, y, button)
    if not ui_handled then
        gameWorld:handleClick(x, y)
    end
end
```

### 渲染层

```lua
Utils.RENDER_LAYERS = {
    BASE = 0, OVERLAY = 50, DROPDOWN = 80, TOOLTIP = 100
}
```

`draw()` 按层级缓存渲染列表，仅在 `_render_cache_dirty` 时重建。
