local UiManager = require "ui.ui_manager":GetInstance()
local Utils = require "ui.utils"
local Transform = require "ui.transform"


local Widget = Class(function(self, name, datas, theme)
	self._name = name or "widget"
	self._valid = true
	self._debug = false

	self.transform = Transform()
	if datas then
		if datas.pivot then
			self.transform:setPivot(unpack(datas.pivot))
		end
		if datas.x or datas.y then
			self.transform:setPosition(datas.x, datas.y)
		end
		if datas.w or datas.h then
			self.transform:setSize(datas.w, datas.h)
		end
		if datas.sx or datas.sy then
			self.transform:setScale(datas.sx, datas.sy)
		end
		if datas.anchors then
			self.transform:setAnchors(unpack(datas.anchors))
		end
		if datas.padding then
			self.transform:setPadding(unpack(datas.padding))
		end
		if datas.r then
			self.transform:setRotation(datas.r)
		end
	end

	self.theme = theme or UiManager:getDefaultTheme()
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

function Widget:getGlobalScaledSize()
	return self.transform:getGlobalScaledSize()
end

---检测一个屏幕坐标是否位于当前 UI 的包围框内（考虑了旋转，但是不考虑图像的透明部分）
function Widget:regionDetection(px, py)
	local x, y, w, h, r = self.transform:getGlobalBounds()
	w, h = self:getGlobalScaledSize()
	if r == 0 or r == Utils.TWO_PI then
		return px >= x and px <= x + w and py >= y and py <= y + h
	end

end

--------------------------------------------------
-- Children
--------------------------------------------------

function Widget:addChild(child)
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
		child.parent:removeChild(child)
	end
	child.parent = self
	table.insert(self.children, child)
	child.transform:setParent(self.transform)
	return child
end

function Widget:removeChild(child)
	for i, _child in ipairs(self.children) do
		if _child == child then
			child.parent = nil
			table.remove(self.children, i)
			child.transform:setParent()
			return
		end
	end
end

function Widget:removeAllChildren()
	for _, child in ipairs(self.children) do
		child.parent = nil
		child.transform:setParent()
	end
	self.children = {}
end

--------------------------------------------------
-- Destroy
--------------------------------------------------

function Widget:destroy()
	local temp_children = self.children
	self:removeAllChildren()
	for _, child in ipairs(temp_children) do
		child:destroy()
	end
	if self.parent then
		self.parent:removeChild(self)
	end
	self._valid = false
end

function Widget:isValid()
	return self._valid == true
end

--------------------------------------------------
-- Update & Draw
--------------------------------------------------

function Widget:shouldDraw()
	return self._valid and self.shown
end

function Widget:shouldUpdate()
	return self._valid and self.enabled
end

function Widget:update(dt)
	self.transform:onUpdate()
	if self.__enable_size_changed_event then
		if self.__oldw ~= self.transform.w or self.__oldh ~= self.transform.h then
			self:handleEvent("SizeChanged", self.transform.w, self.transform.h)
			self.__oldw = self.transform.w
			self.__oldh = self.transform.h
		end
	end
	if not self:shouldUpdate() then
		return
	end
	if self.onUpdate then
		self:onUpdate(dt)
	end
	for _, child in ipairs(self.children) do
		child:update(dt)
	end
end

function Widget:draw()
	if not self:shouldDraw() then
		return
	end
	if self.onDraw then
		self:onDraw()
	end
	if self._debug then
		love.graphics.setLineWidth(1)
		self:drawBound()
		self:drawAABB()
	end
	for _, child in ipairs(self.children) do
		child:draw()
	end
end

function Widget:drawAABB()
	love.graphics.setColor(unpack(Utils.UI_COLORS.PINK))
	local x, y, w, h = self.transform:getGlobalAABB()
	love.graphics.rectangle("line", x-1, y-1, w+2, h+2)
end

function Widget:drawBound()
	local x, y, w, h, r = self.transform:getGlobalBounds()
	if r == 0 or r == Utils.TWO_PI then
		return
	end
	local px, py = self.transform:getGlobalPosition()
	love.graphics.push()
	love.graphics.translate(px, py)
	love.graphics.rotate(r)
	love.graphics.translate(-px, -py)
	love.graphics.setColor(unpack(Utils.UI_COLORS.YELLOW))
	love.graphics.rectangle("line", x-1, y-1, w+2, h+2)
	love.graphics.pop()
end

--------------------------------------------------
-- Show & Hide
--------------------------------------------------

function Widget:isShown()
	return self.shown
end

function Widget:show()
	self.shown = true
end

function Widget:hide()
	self.shown = false
end

--------------------------------------------------
-- Enable & Disable
--------------------------------------------------

function Widget:enable()
	self.enabled = true
end

function Widget:disable()
	self.enabled = false
end

function Widget:isEnabled()
	return self.enabled
end

--------------------------------------------------
-- Focus
--------------------------------------------------

function Widget:setFocus()
	self.focus = true
	if self.onFocus then
		self:onFocus()
	end
end

function Widget:removeFocus()
	self.focus = false
	if self.onRemoveFocus then
		self:onRemoveFocus()
	end
end

function Widget:isFocus()
	return self.focus
end

--------------------------------------------------
-- Z-axis Movement
--------------------------------------------------

function Widget:moveToTop()
	if self.parent then
		for k, v in ipairs(self.parent.children) do
			if v == self then
				table.remove(self.parent.children, k)
				table.insert(self.parent.children, self)
				break
			end
		end
	else
		UiManager:moveToTop(self)
	end
end

function Widget:moveToBottom()
	if self.parent then
		for k, v in ipairs(self.parent.children) do
			if v == self then
				table.remove(self.parent.children, k)
				table.insert(self.parent.children, 1, self)
				break
			end
		end
	else
		UiManager:moveToBottom(self)
	end
end


--------------------------------------------------
-- Event Handler
--------------------------------------------------

function Widget:isOperational()
	return self._valid and self.enabled and self.shown
end

function Widget:handleEvent(event_type, ...)
	if not self:isOperational() then
		return
	end

	for i = #self.children, 1, -1 do
		if self.children[i]:handleEvent(event_type, ...) then
			return true -- 事件被拦截
		end
	end

	local handler_name = "on" .. event_type
	local handler = self[handler_name]
	if handler then
		return handler(self, ...)
	end
end

function Widget:enableSizeChangedEvent(enable)
	if enable then
		self.__enable_size_changed_event = true
		self.__oldw = self.transform.w
		self.__oldh = self.transform.h
	else
		self.__enable_size_changed_event = nil
		self.__oldw = nil
		self.__oldh = nil
	end
end


--------------------------------------------------
-- Debug
--------------------------------------------------

function Widget:__tostring()
	return self._name
end

function Widget:enableDebug(enable)
	self._debug = enable == true
end


return Widget
