--------------------------------------------------
-- Canvas — 设计画布
-- 职责：承载目标 UI、拦截鼠标事件实现选中、绘制选中覆盖层
--------------------------------------------------

local Fonts = require "ui.fonts"
local Widget = require "ui.widgets.widget"
local Selection = require "ui_editor.editor.selection"
local UiManager = require "ui.ui_manager":GetInstance()
local Utils = require "ui.utils"

local Canvas = Class(Widget, function(self, datas)
    Widget.new(self, "Canvas", datas)
    self.raycast_target = true

    self.selection = Selection()
    self._edited_root = nil    -- 被编辑的 UI 根节点
    self._design_mode = true   -- 设计模式（true=选中, false=交互）
    self.onSelectionChanged = nil -- 回调：选中变化时通知外部（如 Inspector）
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
-- 事件拦截（设计模式下优先于子节点）
--------------------------------------------------

function Canvas:handleEvent(event_type, ...)
    if not self:isOperational() then return end

    -- 设计模式：Canvas 自己的 handler 优先于子节点
    if self._design_mode then
        local handler_name = "on" .. event_type
        local handler = self[handler_name]
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

    -- 交互模式：正常流程（子节点优先，Canvas handler 兜底）
    if not self._design_mode then
        local handler_name = "on" .. event_type
        local handler = self[handler_name]
        if handler then
            return handler(self, ...)
        end
    end

    return false
end

--------------------------------------------------
-- 命中检测
--------------------------------------------------

-- 递归查找屏幕坐标下最深的 widget（子优先）
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
-- 判断 widget 是否是 ancestor 的后代
function Canvas:_isDescendantOf(widget, ancestor)
	local current = widget
	while current do
		if current == ancestor then return true end
		current = current.parent
	end
	return false
end
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
        -- 切换到父节点（替代 Tab，因 UiManager 拦截了 Tab）
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
        -- 切换设计/交互模式
        self._design_mode = not self._design_mode
        if not self._design_mode then
            self.selection:deselect()
        end
        return true
    end
    return false
end

--------------------------------------------------
-- 鼠标事件
--------------------------------------------------

function Canvas:onTextInput(text)
	-- 设计模式下：仅当焦点在被编辑 UI 内部时才拦截文本输入
	-- 否则放行（Inspector 等编辑器面板需要接收）
	if self._design_mode then
		local focus = UiManager:getFocus()
		if focus and self._edited_root and self:_isDescendantOf(focus, self._edited_root) then
			return true
		end
	end
	return false
end

function Canvas:onMousePressed(x, y, button)
    if button ~= 1 then return end
    if not self:regionDetection(x, y) then return end

    -- 检测是否命中拖拽手柄
    if self.selection:hasSelection() then
        local handle = self.selection:hitHandle(x, y)
        if handle then
            -- TODO: 开始拖拽手柄
            return true
        end
    end

    -- 命中检测 → 选中
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
	-- 选中覆盖层
	if self._design_mode and self.selection:hasSelection() then
		self.selection:draw()
	end

	-- 模式提示
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
