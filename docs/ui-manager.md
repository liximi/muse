# UiManager

全局 UI 管理器（单例）。持有所有根 widget，分发 LÖVE 事件，管理渲染层和焦点。

## 获取实例

```lua
local UiManager = require "ui.ui_manager":GetInstance()
```

## 核心职责

### 根 widget 管理

`hierarchy` 数组存储所有顶层 widget。事件从末尾向前遍历（后添加的在最上层）。

### 渲染层系统

widget 按 `render_layer` 分层绘制，确保 Dropdown、Tooltip 等浮层显示在常规 UI 之上：

| 层级 | 值 | 用途 |
|------|-----|------|
| `BASE` | 0 | 常规 UI |
| `OVERLAY` | 50 | 半浮层 |
| `DROPDOWN` | 80 | 下拉菜单 |
| `TOOLTIP` | 100 | 提示框（最顶层） |

### 焦点管理

维护 `current_focus` 引用。`setFocus(widget)` 将焦点转移到指定 widget，`clearFocus()` 清除焦点。

### 生命周期

`addWidget` 时自动调用 `widget:_setAttached(true)`，触发 `onAttached`。`removeWidget` 时调用 `_setAttached(false)`。

## 公有方法

| 方法 | 说明 |
|------|------|
| `addWidget(widget)` | 添加根 widget |
| `removeWidget(widget)` | 移除根 widget |
| `setFocus(widget)` | 设置焦点 |
| `clearFocus()` | 清除焦点 |
| `invalidateRenderCache()` | 失效渲染层缓存（show/hide 时自动调用） |
| `moveToTop(widget)` | 将根 widget 移至最上层 |
| `moveToBottom(widget)` | 将根 widget 移至最下层 |
| `getWidgetCount()` | 获取活动 widget 总数 |
| `getDefaultTheme()` | 获取默认主题 |

## 生命周期钩子

| 钩子 | 触发时机 |
|------|----------|
| `onWidgetCreated` | Widget 构造时调用（计数） |
| `onWidgetDestroyed` | Widget 销毁时调用（计数） |

## 事件分发

`UiManager` 接收 LÖVE 的全局事件（`love.draw`、`love.update`、`love.mousepressed` 等），按渲染层顺序分发给 hierarchy 中的根 widget。

## 最佳实践

- **推荐**：通过 `addWidget` / `removeWidget` 管理浮层（Modal、Tooltip、Dropdown 的 popup）。
- **推荐**：使用 `render_layer` 而非手动 Z 排序来控制绘制层级。
- **不推荐**：直接操作 `hierarchy` 数组——使用 `addWidget`/`removeWidget`。
