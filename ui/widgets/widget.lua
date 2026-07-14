local UiManager = require "ui.ui_manager":GetInstance()
local Utils = require "ui.utils"
local Transform = require "ui.transform"
local Class = require "dependencies.classic"

-- 伪常量
local DEFAULT_RENDER_LAYER = 0  -- 默认渲染层
local DEBUG_LINE_WIDTH = 1      -- 调试绘制线宽
local DEBUG_PIVOT_RADIUS = 3    -- 调试 pivot 点半径
local DEBUG_BOUND_INSET = 1     -- 调试包围盒视觉缩进
local DEBUG_BOUND_EXPAND = 2    -- 调试包围盒视觉扩大（inset * 2）
local CULL_EPSILON = 1          -- AABB 裁剪容差（像素），防止浮点精度导致边缘元素被误判为完全不可见

--[[datas:
	pivot = {x, y}
	anchor = {minx, miny, maxx, maxy}
	x = number
	y = number
	w = number
	h = number
	sx = number
	sy = number
	padding = {left, right, top, bottom}
	r = number
]]
local Widget = Class(function(self, name, datas, theme)
	-- 支持 Widget(datas, theme) 的无 name 调用方式
	if type(name) == "table" then
		theme = datas
		datas = name
		name = nil
	elseif type(name) ~= "string" then
		theme = datas
		datas = nil
		name = nil
	end
	self._name = name or "widget"
	self._valid = true
	self._debug = false

	self.transform = Transform()
	if datas then
		if datas.pivot then
			self.transform:setPivot(unpack(datas.pivot))
		end
		if datas.anchor then
			self.transform:setAnchor(unpack(datas.anchor))
		end
		if datas.x or datas.y then
			self.transform:setPosition(datas.x, datas.y)
		end
		if datas.padding then
			self.transform:setPadding(unpack(datas.padding))
		end
		if datas.w or datas.h then
			self.transform:setSize(datas.w, datas.h)
		end
		if datas.sx or datas.sy then
			self.transform:setScale(datas.sx, datas.sy)
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
	self.focusable = false
	self.render_layer = DEFAULT_RENDER_LAYER
	self.always_draw = false
	self._clip_rect = nil
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
	local pvx, pvy = self.transform:getGlobalPosition()
	local sw, sh = self:getGlobalScaledSize()
	local r = self.transform:getGlobalRotation()
	local px_pivot = self.transform.pivot[1]
	local py_pivot = self.transform.pivot[2]
	if r == 0 or r == Utils.TWO_PI then
		local x = pvx - sw * px_pivot
		local y = pvy - sh * py_pivot
		return px >= x and px <= x + sw and py >= y and py <= y + sh
	end
	-- 绕 pivot 逆旋转，而非绕左上角
	local dx = px - pvx
	local dy = py - pvy
	local cosr = math.cos(r)
	local sinr = math.sin(r)
	local localX = dx * cosr + dy * sinr + sw * px_pivot
	local localY = -dx * sinr + dy * cosr + sh * py_pivot
	return localX >= 0 and localX <= sw and localY >= 0 and localY <= sh
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
-- Measure
--------------------------------------------------

--- 查询 widget 的自然（内容）尺寸，给定可用空间约束
---@param max_w number|nil 可用宽度（nil = 无约束）
---@param max_h number|nil 可用高度（nil = 无约束）
---@return table {w = number, h = number}
function Widget:measure(max_w, max_h)
	local w, h = self.transform:getSize()
	return {w = w, h = h}
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

function Widget:update(dt, parent_should_update)
	self.transform:onUpdate()
	if self.__enable_size_changed_event then
		if self.__oldw ~= self.transform.w or self.__oldh ~= self.transform.h then
			self:handleEvent("SizeChanged", self.transform.w, self.transform.h)
			self.__oldw = self.transform.w
			self.__oldh = self.transform.h
		end
	end
	if not self:shouldUpdate() or not parent_should_update then
		for _, child in ipairs(self.children) do
			child:update(dt, false)
		end
		return
	end
	for _, child in ipairs(self.children) do
		child:update(dt, true)
	end
	if self.onUpdate then
		self:onUpdate(dt)
	end
end

function Widget:draw()
	if not self:shouldDraw() then
		return
	end
	-- 可见性裁剪：仅在元素完全不可见时跳过该子树
	-- 判断条件：元素的 AABB 与裁剪区域的交集面积为 0（考虑了坐标偏移和自身尺寸）
	-- 使用 CULL_EPSILON 容差避免浮点精度导致边界重合的元素被误裁
	if not self.always_draw and self._clip_rect then
		local ax, ay, aw, ah = self.transform:getGlobalAABB()
		local cx, cy, cw, ch = unpack(self._clip_rect)
		-- 完全在左侧：元素右边缘 + 容差 < 裁剪左边缘
		-- 完全在右侧：元素左边缘 - 容差 > 裁剪右边缘
		-- 完全在上方：元素下边缘 + 容差 < 裁剪上边缘
		-- 完全在下方：元素上边缘 - 容差 > 裁剪下边缘
		if ax + aw + CULL_EPSILON < cx or ax - CULL_EPSILON > cx + cw
			or ay + ah + CULL_EPSILON < cy or ay - CULL_EPSILON > cy + ch then
			return
		end
	end
	if self.onDraw then
		self:onDraw()
	end
	-- 将裁剪矩形传播给子元素
	for _, child in ipairs(self.children) do
		if child.render_layer == self.render_layer then
		local prev_clip = child._clip_rect
		child._clip_rect = self._clip_rect or child._clip_rect
		child:draw()
		child._clip_rect = prev_clip
		end
	end
	if self.onPostDraw then
		self:onPostDraw()
	end
	if self._debug then
		if self.onDebugDraw then
			self:onDebugDraw()
		end
		love.graphics.setLineWidth(DEBUG_LINE_WIDTH)
		self:drawBound()
		self:drawAABB()
	end
end

function Widget:drawAABB()
	local r = self.transform:getGlobalRotation()
	if r == 0 or r == Utils.TWO_PI then
		return
	end
	love.graphics.setColor(unpack(Utils.UI_COLORS.PINK))
	local x, y, w, h = self.transform:getGlobalAABB()
	love.graphics.rectangle("line", x - DEBUG_BOUND_INSET, y - DEBUG_BOUND_INSET, w + DEBUG_BOUND_EXPAND, h + DEBUG_BOUND_EXPAND)
end

function Widget:drawBound()
	love.graphics.setColor(unpack(Utils.UI_COLORS.YELLOW))
	local px, py = self.transform:getGlobalPosition()
	love.graphics.circle("line", px, py, DEBUG_PIVOT_RADIUS)
	local x, y, w, h, r = self.transform:getGlobalBounds()
	love.graphics.push()
	love.graphics.translate(px, py)
	love.graphics.rotate(r)
	love.graphics.translate(-px, -py)
	love.graphics.rectangle("line", x - DEBUG_BOUND_INSET, y - DEBUG_BOUND_INSET, w + DEBUG_BOUND_EXPAND, h + DEBUG_BOUND_EXPAND)
	if w < 0 or h < 0 then
		love.graphics.line(x, y, x + w, y + h)
		love.graphics.line(x + w, y, x, y + h)
	end
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
	if self.onEnabled then
		self:onEnabled()
	end
end

function Widget:disable()
	self.enabled = false
	if self.onDisabled then
		self:onDisabled()
	end
end

function Widget:isEnabled()
	return self.enabled
end

--------------------------------------------------
-- Focus
--------------------------------------------------

function Widget:setFocus()
	UiManager:setFocus(self)
end

function Widget:removeFocus()
	UiManager:clearFocus()
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

	-- SizeChanged 是自身尺寸变化事件，不应传播给子节点
	-- 否则祖先的尺寸变化会带着祖先的 w/h 值传给子孙，造成误判
	if event_type ~= "SizeChanged" then
		for i = #self.children, 1, -1 do
			if self.children[i]:handleEvent(event_type, ...) then
				return true -- 事件被拦截
			end
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
