# Muse UI 框架使用反馈

> Sphere Colony 项目实践总结 | 2026-07-14

---

## 概述

Muse 是一个保留式 UI 框架，设计理念类似 Unity UGUI：控件创建后持久化，通过属性更新驱动 UI 变化。但在实际使用中，多个 API 设计引导开发者走向**立即模式**用法，导致一系列问题。本文档记录踩坑经验和改进建议。

---

## 1. `List:setItems()` — 最大的陷阱

### 问题

`setItems(items)` 是 List 容器最常用的内容更新方法，但它内部调用 `removeAllChildren()` + `addChild()` + `layout()`：

```lua
function List:setItems(items)
    self:removeAllChildren()  -- 销毁所有旧子控件
    self.items = {}
    for i, v in ipairs(items) do
        table.insert(self.items, v)
        self:addChild(v)       -- 重新添加
    end
    self:layout()
end
```

这导致每次更新列表内容时，所有子控件被**从父节点移除再重新添加**。对于 Button 等有状态的控件，`removeChild` 虽不销毁 Lua 对象，但会清空 `transform.parent`，而重新 `addChild` 后 transform 链恢复。**关键是：如果在 setItems 之前已有 `mousedown` 事件将按钮设为 `pressed`，下一次 setItems 不会丢掉这个状态——真正的问题是跨帧销毁**。

### 实际踩坑

我们的信息面板最初每帧调用 `content:setItems(sections)` 全量重建。LÖVE 的事件循环中 `mousedown` 和 `mouseup` 通常跨帧：

```
Frame N:   update → setItems（创建按钮 A）→ mousedown（A.state = pressed）
Frame N+1: update → setItems（创建按钮 B，A 被 orphan）→ mouseup（B.state = normal → IGNORED）
```

按钮 B 是新对象，`state = normal`，`onClick` 永远不会触发。

### 正确用法

**叶子控件（Button/Text）应创建一次，存入对象池，后续只原地更新属性：**

```lua
-- ❌ 错误：每帧重建
function refresh(data)
    local items = {}
    for _, d in ipairs(data.buttons) do
        table.insert(items, makeBtn(d.label, d.action_id))  -- 新 Button
    end
    list:setItems(items)
end

-- ✅ 正确：对象池复用
local btnPool = {}
function refresh(data)
    local items = {}
    for _, d in ipairs(data.buttons) do
        local btn = btnPool[d.id]
        if not btn then
            btn = makeBtn(d.label, d.id)
            btnPool[d.id] = btn
        else
            btn:setStateStyle("normal", ...)  -- 原地更新
        end
        table.insert(items, btn)
    end
    list:setItems(items)  -- setItems 仅用于重排序，叶子控件复用
end
```

### 建议

- 提供一个 `List:updateItems(items, keyFn)` 方法，自动 diff 新旧列表，复用已有控件
- 或者在文档中明确警告 `setItems` 的破坏性，推荐对象池模式

---

## 2. 缺少"原地更新子控件"的内置模式

### 问题

框架没有提供"我有 5 个 Text 控件，数据变了，请更新文本"的标准方式。开发者要么：

- **每帧 setItems 重建**（立即模式，有状态丢失风险）
- **手动维护控件引用 + 逐个 setText/setStateStyle**（大量样板代码）

我们最终采用了后者，但每个组件都需要自己实现对象池和 diff 逻辑（见 `info_actions.lua` 的 `_getOrUpdateBtn` 和 `info_header.lua` 的 Text 池）。

### 建议

提供轻量级数据绑定或 ItemsControl 模式：

```lua
-- 理想 API
local itemsControl = ItemsControl({
    itemTemplate = function(data) return Text({...}) end,
    updateItem = function(widget, data) widget:setText(data.text) end,
})
itemsControl:setData(newDataList)  -- 自动 diff + 复用
```

---

## 3. Button 必须显式设置 `w`

### 问题

创建 `Button({h = 18})` 而不设 `w` 时，按钮宽为 0，背景矩形不可见。文字能渲染（`love.graphics.print` 不依赖 widget 宽度），但按钮看起来像漂浮文字。AGENTS.md #15。

### 建议

Button 默认 `w` 应至少等于文本宽度 + padding，或文档中明确标注此行为。

---

## 4. `BoxH` 布局延迟 — build 阶段不可用于定位

### 问题

`Box:layout()` 只在 `onUpdate` 中触发，但 `ListV:setItems()` 同步调用子控件 `measure()`。如果用 BoxH 做「左-弹性-右」三列布局并在 build 阶段放入 ListV，`measure()` 返回 `h=0`，导致 ListV 布局错乱。AGENTS.md #22。

### 建议

提供一个同步的 `layout()` 方法，或文档中说明 Box 容器的延迟布局特性。

---

## 5. Text 右对齐需要手动测量宽度

### 问题

`pivot={1,0}` + `anchor={1,0,1,0}` 对 Text 无效，因为 `Text` 的 `transform.w` 默认为 0（文本宽度在 `love.graphics.newText` 对象里，不写入 transform）。

```lua
-- ❌ 无效：w=0 时 pivot 计算无意义
Text({ text = "hello", anchor = {1,0,1,0}, pivot = {1,0} })

-- ✅ 只能手动测量
local w = font:getWidth("hello")
Text({ text = "hello", x = -(w + margin) })
```

AGENTS.md #18。

### 建议

Text 的 `measure()` 应将其实际文本尺寸同步到 `transform.w/h`，使 anchor/pivot 机制对 Text 也正常工作。

---

## 6. 字体创建时机限制

### 问题

`love.graphics.newFont` 必须在 `love.load()` 之后调用（`love.graphics` 未初始化）。但 Muse 的 `fonts.lua` 在模块加载时创建字体，导致如果在 `love.load()` 之前 `require` 会崩溃。AGENTS.md #3, #6。

### 建议

字体系统应支持延迟初始化，或文档中明确说明所有 Muse require 必须放在 `love.load()` 内。

---

## 7. Scroll 内容必须通过 `setItem` 设置

### 问题

如果内容控件作为 Scroll 的**兄弟节点**而非子节点，事件链断裂且无滚动：

```
❌ Panel → [contentListV, scroll]  // 兄弟，事件/滚动都不通
✅ Panel → scroll → contentListV   // 父子，通过 setItem 设置
```

框架没有在运行时检测这种错误配置。

### 建议

Scroll 在 `onUpdate` 时可检测是否有内容直接添加到自身（而非 `scroll_root`），并打印警告。

---

## 8. `removeAllChildren` + `addChild` 循环破坏事件系统

### 问题

每帧 `removeAllChildren` 再 `addChild` 重建控件树会导致新旧控件对象不同。Muse 事件传播依赖全局坐标（`getGlobalPosition`），虽然理论上 `addChild` 后立即计算 transform，但实测存在不一致。AGENTS.md #24。

### 建议

这是 `setItems` 问题的延伸。提供更安全的列表更新 API 可避免此模式。

---

## 9. `getGlobalPosition` 与视觉渲染位置不一致

### 问题

调试按钮点击时发现，`regionDetection` 使用的 `getGlobalPosition()` 返回的 Y 坐标与实际渲染位置差 ~44px。原因可能是 `List:layout()` 中 `setPosition` 与 `addChild` 的调用时机导致 transform 缓存未刷新。AGENTS.md #24。

### 建议

在 `addChild` 和 `setPosition` 后强制刷新 transform 缓存（`onUpdate(true)`），或提供显式的 `recalculateLayout()` 方法。

---

## 10. Panel 不适合做 List 分隔符

### 问题

在 ListV 中用 Panel 做视觉分隔符会产生额外的 w/h 计算问题，Panel 背景矩形需要正确尺寸但与 List layout 冲突。AGENTS.md #16。

### 建议

提供专门的 `Separator` 控件，或文档中推荐用嵌套 ListV 分层（外层 `space` 控制区间距）。

---

## 总结

| 问题 | 严重程度 | 根因 |
|------|:--:|------|
| `setItems` 破坏性 | 🔴 高 | API 设计引导立即模式 |
| 无内置 diff/复用 | 🔴 高 | 缺少 ItemsControl 抽象 |
| Button 默认 w=0 | 🟡 中 | 默认值不合理 |
| BoxH 延迟 layout | 🟡 中 | layout 时机问题 |
| Text 右对齐 | 🟡 中 | transform.w 未同步文本宽度 |
| 字体加载时机 | 🟡 中 | 初始化顺序耦合 |
| Scroll 兄弟节点静默失效 | 🟡 中 | 无运行时检测 |
| removeAllChildren 模式 | 🟡 中 | 与 setItems 同源 |
| getGlobalPosition 偏移 | 🟡 中 | transform 缓存未刷新 |

**核心建议**：为 `List` 容器提供 `updateItems(data, keyFn, createFn, updateFn)` 方法，自动 diff 新旧数据、复用已有控件、原地更新属性。这将消除 80% 的上述问题。
