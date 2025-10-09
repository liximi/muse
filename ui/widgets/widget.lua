local UiManager = require "ui.ui_manager":GetInstance()
local Transform = require "ui.transform"
---@class Widget
local Widget = Class(function(self, name)
	self._name = name or "widget"
	self._valid = true
	self._debug = false

	self.transform = Transform()

	self.children = {}
	self.parent = nil

	self.enabled = true
	self.shown = true
	self.focus = false
end)


--------------------------------------------------
-- Transform
--------------------------------------------------

function Widget:setPosition(x, y)
	self.transform:setPosition(x, y)
end

function Widget:getPosition()
	return self.transform:getPosition()
end

function Widget:getGlobalPosition()
	return self.transform:getGlobalPosition()
end

function Widget:getGlobalScale()
	return self.transform:getGlobalScale()
end

--------------------------------------------------
-- Children
--------------------------------------------------

function Widget:AddChild(child)
	assert(child ~= nil, "Child cannot be nil")
	assert(child ~= self, "Cannot add widget as its own child")
	-- 检查是否会导致循环引用
	local current = self.parent
	while current do
		assert(current ~= child, "Circular reference detected: cannot add parent as child")
		current = current.parent
	end

	if child.parent == self then
		return child
	end
	if child.parent ~= nil and child.parent ~= self then
		child.parent:RemoveChild(child)
	end
	child.parent = self
	table.insert(self.children, child)
	child.transform:setParent(self.transform)
	return child
end

function Widget:RemoveChild(child)
	for i, _child in ipairs(self.children) do
		if _child == child then
			child.parent = nil
			table.remove(self.children, i)
			child.transform:setParent()
			return
		end
	end
end

function Widget:RemoveAllChildren()
	for _, child in ipairs(self.children) do
		child.parent = nil
		child.transform:setParent()
	end
	self.children = {}
end

--------------------------------------------------
-- Destroy
--------------------------------------------------

function Widget:Destroy()
	local temp_children = self.children
	self:RemoveAllChildren()
	for _, child in ipairs(temp_children) do
		child:Destroy()
	end
	if self.parent then
		self.parent:RemoveChild(self)
	end
	self._valid = false
end

function Widget:IsValid()
	return self._valid == true
end

--------------------------------------------------
-- Update & Draw
--------------------------------------------------

function Widget:ShouldDraw()
	return self._valid and self.shown
end

function Widget:ShouldUpdate()
	return self._valid and self.enabled
end

function Widget:Update(dt)
	if not self:ShouldUpdate() then
		return
	end
	if self.OnUpdate then
		self:OnUpdate(dt)
	end
	for _, child in ipairs(self.children) do
		child:Update(dt)
	end
end

function Widget:Draw()
	if not self:ShouldDraw() then
		return
	end
	if self.OnDraw then
		self:OnDraw()
	end
	for _, child in ipairs(self.children) do
		child:Draw()
	end
end

--------------------------------------------------
-- Show & Hide
--------------------------------------------------

function Widget:IsShown()
	return self.shown
end

function Widget:Show()
	self.shown = true
end

function Widget:Hide()
	self.shown = false
end

--------------------------------------------------
-- Enable & Disable
--------------------------------------------------

function Widget:Enable()
	self.enabled = true
end

function Widget:Disable()
	self.enabled = false
end

function Widget:IsEnabled()
	return self.enabled
end

--------------------------------------------------
-- Focus
--------------------------------------------------

function Widget:SetFocus()
	self.focus = true
	if self.OnFocus then
		self:OnFocus()
	end
end

function Widget:RemoveFocus()
	self.focus = false
	if self.OnRemoveFocus then
		self:OnRemoveFocus()
	end
end

function Widget:IsFocus()
	return self.focus
end

--------------------------------------------------
-- Z-axis Movement
--------------------------------------------------

function Widget:MoveToTop()
	if self.parent then
		for k, v in ipairs(self.parent.children) do
			if v == self then
				table.remove(self.parent.children, k)
				table.insert(self.parent.children, self)
				break
			end
		end
	else
		UiManager:MoveToTop(self)
	end
end

function Widget:MoveToBottom()
	if self.parent then
		for k, v in ipairs(self.parent.children) do
			if v == self then
				table.remove(self.parent.children, k)
				table.insert(self.parent.children, 1, self)
				break
			end
		end
	else
		UiManager:MoveToBottom(self)
	end
end


--------------------------------------------------
-- Event Handler
--------------------------------------------------

function Widget:IsOperational()
	return self._valid and self.enabled and self.shown
end

function Widget:HandleEvent(event_type, ...)
	if not self:IsOperational() then
		return
	end

	for i = #self.children, 1, -1 do
		if self.children[i]:HandleEvent(event_type, ...) then
			return true -- 事件被拦截
		end
	end

	local handler_name = "On" .. event_type
	local handler = self[handler_name]
	if handler then
		return handler(self, ...)
	end
end


--------------------------------------------------
-- Debug
--------------------------------------------------

function Widget:__tostring()
	return self._name
end

function Widget:EnableDebug(enable)
	self._debug = enable == true
end


return Widget
