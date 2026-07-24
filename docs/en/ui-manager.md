# UiManager

Global UI manager (singleton). Holds all root widgets, dispatches LÖVE events, manages render layers and focus.

## Getting the Instance

```lua
local UiManager = require "ui.ui_manager":GetInstance()
```

## Core Responsibilities

### Root Widget Management

The `hierarchy` array stores all top-level widgets. Events traverse from last to first (later-added widgets are on top).

### Render Layer System

Widgets are drawn grouped by `render_layer`, ensuring overlays like Dropdown and Tooltip appear above regular UI:

| Layer | Value | Use |
|-------|-------|-----|
| `BASE` | 0 | Regular UI |
| `OVERLAY` | 50 | Semi-overlay |
| `DROPDOWN` | 80 | Dropdown menus |
| `TOOLTIP` | 100 | Tooltips (topmost) |

### Focus Management

Maintains a `current_focus` reference. `setFocus(widget)` transfers focus; `clearFocus()` removes it.

### Lifecycle

`addWidget` automatically calls `widget:_setAttached(true)`, triggering `onAttached`. `removeWidget` calls `_setAttached(false)`.

## Public Methods

| Method | Description |
|--------|-------------|
| `addWidget(widget)` | Add root widget |
| `removeWidget(widget)` | Remove root widget |
| `setFocus(widget)` | Set focus |
| `clearFocus()` | Clear focus |
| `invalidateRenderCache()` | Invalidate render layer cache (auto-called on show/hide) |
| `moveToTop(widget)` | Move root widget to top |
| `moveToBottom(widget)` | Move root widget to bottom |
| `getWidgetCount()` | Get active widget count |
| `getDefaultTheme()` | Get default theme |

## Lifecycle Hooks

| Hook | Trigger |
|------|---------|
| `onWidgetCreated` | Called when a Widget is constructed (counts) |
| `onWidgetDestroyed` | Called when a Widget is destroyed (counts) |

## Event Dispatch

`UiManager` receives LÖVE global events (`love.draw`, `love.update`, `love.mousepressed`, etc.) and dispatches them to hierarchy root widgets grouped by render layer.

## Best Practices

- **Do**: Use `addWidget` / `removeWidget` to manage overlays (Modal, Tooltip, Dropdown popup).
- **Do**: Use `render_layer` instead of manual Z-ordering to control draw order.
- **Don't**: Manipulate the `hierarchy` array directly — use `addWidget`/`removeWidget`.
