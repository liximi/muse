--------------------------------------------------
-- Canvas — 设计画布
-- 职责：承载目标 UI、拦截鼠标/键盘事件实现选中、绘制选中覆盖层
--------------------------------------------------

local Widget = require "ui.widgets.widget"
local Selection = require "ui_editor.editor.selection"
local Utils = require "ui.utils"
local Fonts = require "ui.fonts"
local UiManager = require "ui.ui_manager":GetInstance()

--------------------------------------------------
-- 设计模式下需要 Canvas 优先拦截的事件（其余事件走正常子节点优先传播）
--------------------------------------------------
local INTERCEPT_FIRST = {
    KeyPressed     = true,
    MousePressed   = true,
    MouseReleased  = true,
    MouseMoved     = true,
}

local Canvas = Class(Widget, function(self, datas)
    Widget.new(self, "Canvas", datas)
    self.raycast_target = true

    self.selection = Selection()
    self._edited_root = nil
    self._design_mode = true
    self.onSelectionChanged = nil
end)

--------------------------------------------------
-- 被编辑 UI 的管理
--------------------------------------------------

function Canvas:setEditedRoot(root_widget)
    if self._edited_root then
        self:removeChild(self._edited_root)
    end
    self._edited_root = root_widget
    self:addChild(root_widget)
    self.selection:deselect()
end

function Canvas:getEditedRoot()
    return self._edited_root
end

--------------------------------------------------
-- 事件拦截
--
-- 设计模式：
--   KeyPressed / Mouse* → Canvas 优先处理（选中/导航），未消耗才传给子节点
--   TextInput / WheelMoved 等 → 正常子节点优先，Canvas 无 handler 则不拦截
--   进入设计模式时清除焦点，确保被编辑 UI 不会收到文本输入
-- 交互模式：
--   完全正常传播，子节点优先
--------------------------------------------------

function Canvas:handleEvent(event_type, ...)
    if not self:isOperational() then return end

    if self._design_mode and INTERCEPT_FIRST[event_type] then
        local handler = self["on" .. event_type]
        if handler and handler(self, ...) then
            return true
        end
    end

    -- 传播给子节点
    for i = #self.children, 1, -1 do
        if self.children[i]:handleEvent(event_type, ...) then
            return true
        end
    end

    -- 未被优先拦截的事件 / 交互模式：Canvas handler 兜底
    if not self._design_mode or not INTERCEPT_FIRST[event_type] then
        local handler = self["on" .. event_type]
        if handler and handler(self, ...) then
            return true
        end
    end

    return false
end

--------------------------------------------------
-- 命中检测
--------------------------------------------------

function Canvas:_hitTest(widget, screen_x, screen_y)
    if not widget or not widget:isOperational() then
        return nil
    end
    for i = #widget.children, 1, -1 do
        local hit = self:_hitTest(widget.children[i], screen_x, screen_y)
        if hit then return hit end
    end
    if widget ~= self and widget.regionDetection
        and widget:regionDetection(screen_x, screen_y) then
        return widget
    end
    return nil
end

function Canvas:_findWidgetAt(screen_x, screen_y)
    if not self._edited_root then return nil end
    return self:_hitTest(self._edited_root, screen_x, screen_y)
end

function Canvas:_getParentInTree(widget)
    if not widget or widget == self._edited_root then return nil end
    local parent = widget.parent
    if parent == self or parent == nil then return nil end
    return parent
end

--------------------------------------------------
-- 键盘事件
--------------------------------------------------

function Canvas:onKeyPressed(key, isrepeat)
    if key == "escape" then
        if self.selection:hasSelection() then
            self.selection:deselect()
            self:_notifySelection()
            return true
        end
    elseif key == "p" then
        local current = self.selection.widget
        if current then
            local parent = self:_getParentInTree(current)
            if parent then
                self.selection:select(parent)
                self:_notifySelection()
            end
        end
        return true
    elseif key == "delete" or key == "backspace" then
        -- TODO: 删除选中 widget
        return true
    elseif key == "e" then
        self._design_mode = not self._design_mode
        if self._design_mode then
            -- 进入设计模式时清除焦点，确保被编辑 UI 不会收到文本输入
            UiManager:clearFocus()
        else
            self.selection:deselect()
            self:_notifySelection()
        end
        return true
    end
    return false
end

--------------------------------------------------
-- 鼠标事件
--------------------------------------------------

function Canvas:onMousePressed(x, y, button)
    if button ~= 1 then return end
    if not self:regionDetection(x, y) then return end

    if self.selection:hasSelection() then
        local handle = self.selection:hitHandle(x, y)
        if handle then
            return true  -- 拖拽手柄（后续实现）
        end
    end

    local hit = self:_findWidgetAt(x, y)
    if hit then
        self.selection:select(hit)
    else
        self.selection:deselect()
    end
    self:_notifySelection()
    return true
end

--------------------------------------------------
-- 内部
--------------------------------------------------

function Canvas:_notifySelection()
    if self.onSelectionChanged then
        self.onSelectionChanged(self.selection.widget)
    end
end

--------------------------------------------------
-- 绘制
--------------------------------------------------

function Canvas:onPostDraw()
    if self._design_mode and self.selection:hasSelection() then
        self.selection:draw()
    end

    local prev_font = love.graphics.getFont()
    local x, y = self.transform:getGlobalPosition()
    local gh = love.graphics.getHeight()
    local label = self._design_mode
        and "[设计模式]  E=交互  P=父节点  Esc=取消选中"
        or  "[交互模式]  E=返回设计"
    local font = Fonts:getFont("default", 12)
    love.graphics.setFont(font)
    love.graphics.setColor(0.3, 0.6, 1.0, 0.55)
    love.graphics.print(label, x + 4, gh - 20)
    love.graphics.setFont(prev_font)
end

return Canvas
