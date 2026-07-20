# Muse Tooltip 修复报告

## 问题

Tooltip 在目标 widget 被禁用（`enabled = false`）时不显示。

## 根因

`muse/ui/widgets/tooltip.lua` 的 `onUpdate` 方法中对目标调用了 `isOperational()`：

```lua
function Tooltip:onUpdate(dt)
    if not self.target or not self.target:isOperational() then  -- ← 这里
        if self._active then
            self._active = false
            self:hide()
        end
        return
    end

    local mx, my = love.mouse.getPosition()
    local is_over = self.target:regionDetection(mx, my)  -- ← 永远走不到
    ...
```

`Widget:isOperational()`（`muse/ui/widgets/widget.lua:524`）的定义是：

```lua
function Widget:isOperational()
    return self._valid and self.enabled and self.shown
end
```

当按钮被 `disable()` 后，`self.enabled = false` → `isOperational()` 返回 `false` → Tooltip 直接退出，连 `regionDetection` 都没执行。而 `regionDetection` 本身是纯几何检测，跟 enabled 无关。

## 修复方案

将 Tooltip 的守卫条件从 `isOperational()` 改为只检查 widget 是否存活且可见，不检查 `enabled`：

**文件**：`muse/ui/widgets/tooltip.lua`

**位置**：`Tooltip:onUpdate(dt)` 方法，约第 104-109 行

**改前**：
```lua
function Tooltip:onUpdate(dt)
    if not self.target or not self.target:isOperational() then
        if self._active then
            self._active = false
            self:hide()
        end
        return
    end
```

**改后**：
```lua
function Tooltip:onUpdate(dt)
    -- 只检查 target 是否存活+可见，不检查 enabled
    -- 禁用的按钮仍然应该在 hover 时显示 Tooltip
    if not self.target or not self.target._valid or not self.target.shown then
        if self._active then
            self._active = false
            self:hide()
        end
        return
    end
```

## 影响范围

- **仅影响 Tooltip 行为**：禁用的 widget 从"Tooltip 不显示"变为"Tooltip 正常显示"
- **不影响事件系统**：`Widget:handleEvent()` 中的 `isOperational()` 不受影响，禁用的按钮仍然不响应点击
- **不影响其他组件**：`isOperational()` 本身不修改，只在 Tooltip 中不再用它

## 使用场景

本项目 Sphere Colony 中大量使用此模式：建造按钮材料不足时灰掉，但玩家 hover 上去需要 Tooltip 说明"缺少: 钢材×50"。
