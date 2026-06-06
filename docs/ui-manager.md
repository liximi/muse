# UiManager

UiManager 是全局单例，管理顶层 widget 层级和事件分发。

## 获取实例

```lua
local UiManager = require "ui.ui_manager":GetInstance()
```

## 公有方法

### Widget 管理

| 方法 | 说明 |
|------|------|
| `addWidget(widget)` | 将 widget 添加为根节点（widget 必须没有 parent） |
| `moveToTop(widget)` | 将根 widget 移到渲染顺序最上层（最后绘制） |
| `moveToBottom(widget)` | 将根 widget 移到渲染顺序最下层（最先绘制） |

### 焦点管理

| 方法 | 说明 |
|------|------|
| `setFocus(widget)` | 设置当前焦点 widget（自动调用旧焦点的 `onRemoveFocus` 和新焦点的 `onFocus`） |
| `getFocus()` | 返回当前焦点 widget |
| `clearFocus()` | 清除焦点 |

Tab 键可循环切换 focusable 的 widget（按住 Shift 反向切换）。

### 主题

| 方法 | 说明 |
|------|------|
| `getDefaultTheme()` | 返回当前默认主题实例 |
| `setDefaultTheme(theme)` | 设置默认主题（所有未指定 theme 的 widget 将使用此主题） |

### 事件分发

UiManager 将 LÖVE 事件分发给 widget 树，从 hierarchy 末尾向前遍历（后添加的先收到事件）：

| 方法 | 对应 LÖVE 事件 |
|------|---------------|
| `update(dt)` | `love.update` |
| `draw()` | `love.draw`（按 render_layer 分层绘制） |
| `KeyPressed(key, isrepeat)` | `love.keypressed` |
| `KeyReleased(key)` | `love.keyreleased` |
| `TextInput(text)` | `love.textinput` |
| `MouseMoved(x, y, dx, dy)` | `love.mousemoved` |
| `MousePressed(x, y, button)` | `love.mousepressed` |
| `MouseReleased(x, y, button)` | `love.mousereleased` |
| `WheelMoved(x, y)` | `love.wheelmoved` |

点击 widget 外部区域会自动清除焦点。

### 渲染层

`draw()` 按 `render_layer` 数值升序分层绘制。预定义层级：

```lua
Utils.RENDER_LAYERS = {
    BASE = 0,       -- 默认层
    OVERLAY = 50,   -- 覆盖层
    DROPDOWN = 80,  -- 下拉菜单
    TOOLTIP = 100   -- 工具提示
}
```
