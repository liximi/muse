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
	h_size_flags = number     -- SIZE_FLAGS 组合值，默认 FILL
	v_size_flags = number     -- SIZE_FLAGS 组合值，默认 FILL
	stretch_ratio = number    -- EXPAND 时的分配比例，默认 1.0
	custom_minimum_size = {w, h}  -- 覆盖内容最小尺寸
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
	self._attached = false  -- 生命周期：是否已加入 UiManager 活动树
	self._debug = false

	UiManager:_onWidgetCreated()

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
		if datas.w or datas.h then
			self.transform:setSize(datas.w, datas.h)
		end
		if datas.padding then
			self.transform:setPadding(unpack(datas.padding))
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

	-- 射线检测开关。开启后，即使没有显式事件 handler，鼠标落在区域内也会阻断事件穿透
	self.raycast_target = false

	-- 容器布局标志（参考 Godot SizeFlags，默认 FILL）
	self.h_size_flags = datas and datas.h_size_flags or Utils.SIZE_FLAGS.FILL
	self.v_size_flags = datas and datas.v_size_flags or Utils.SIZE_FLAGS.FILL
	self.stretch_ratio = (datas and datas.stretch_ratio) or 1.0
	if datas and datas.custom_minimum_size then
		self:setCustomMinimumSize(datas.custom_minimum_size[1], datas.custom_minimum_size[2])
	else
		self._custom_min_w = nil
		self._custom_min_h = nil
	end

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
	-- 如果父节点已在活动树中，子节点自动获得 attached 状态
	if self._attached then
		child:_setAttached(true)
	end
	return child
end

function Widget:removeChild(child)
	for i, _child in ipairs(self.children) do
		if _child == child then
			-- 如果子节点在活动树中，先触发 detach
			if child._attached then
				child:_setAttached(false)
			end
			child.parent = nil
			table.remove(self.children, i)
			child.transform:setParent()
			return
		end
	end
end

function Widget:removeAllChildren()
	for _, child in ipairs(self.children) do
		if child._attached then
			child:_setAttached(false)
		end
		child.parent = nil
		child.transform:setParent()
	end
	self.children = {}
end

--- 移除并销毁所有子节点（释放 GPU 资源）。
--- 与 removeAllChildren 不同，此方法会递归调用 destroy()，彻底清理。
--- 仅用于不再需要子节点的场景（如测试切换、面板重建）。
--- TabView/ListContainer 等需要复用内容的场景请用 removeAllChildren。
function Widget:clearChildren()
	local copy = {}
	for _, child in ipairs(self.children) do
		table.insert(copy, child)
	end
	for _, child in ipairs(copy) do
		child:destroy()
	end
end

--- 递归设置 attached 状态并触发生命周期钩子
function Widget:_setAttached(attached)
	if attached == self._attached then
		return
	end
	self._attached = attached
	if attached then
		self:onAttached()
	else
		self:onDetached()
	end
	for _, child in ipairs(self.children) do
		child:_setAttached(attached)
	end
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

--- 返回控件自身内容的最小自然尺寸（像素）。
--- 子类覆写此方法报告基于实际内容（文字、贴图等）的最小尺寸。
--- 容器通过 getCombinedMinimumSize() 聚合子控件的最小尺寸来决定布局。
---@return number w
---@return number h
function Widget:getMinimumSize()
	return 0, 0
end

--- 返回控件的最小有效尺寸 = max(内容最小尺寸, 用户设置的 custom_minimum_size)。
--- 这是容器实际使用的值。
---@return number w
---@return number h
function Widget:getCombinedMinimumSize()
	local mw, mh = self:getMinimumSize()
	return math.max(mw, self._custom_min_w or 0), math.max(mh, self._custom_min_h or 0)
end

--- 设置自定义最小尺寸（覆盖内容最小尺寸）。nil 表示不限制。
function Widget:setCustomMinimumSize(w, h)
	self._custom_min_w = w
	self._custom_min_h = h
end

--- 返回控件期望的自然尺寸（用于两趟分配的第一趟：先满足 desired，再瓜分剩余）。
--- 默认等于最小尺寸。子类覆写以报告更大的自然尺寸（如 Text 返回完整文本宽度）。
---@return number w
---@return number h
function Widget:getDesiredSize()
	return self:getCombinedMinimumSize()
end

--------------------------------------------------
-- Lifecycle Hooks (called by UiManager when widget enters/leaves the active tree)
--------------------------------------------------

--- 当 Widget（或其祖先）被添加到 UiManager 的活动树时调用。子类可覆写以注册全局资源。
function Widget:onAttached()
end

--- 当 Widget（或其祖先）从 UiManager 的活动树移除时调用。子类可覆写以释放全局资源。
function Widget:onDetached()
end

--------------------------------------------------
-- Destroy
--------------------------------------------------

function Widget:destroy()
	if not self._valid then return end  -- 防止重复销毁
	-- 先从活动树中分离（触发生命周期清理）
	if self._attached then
		self:_setAttached(false)
	end
	local temp_children = {}
	for _, child in ipairs(self.children) do
		table.insert(temp_children, child)
	end
	for _, child in ipairs(temp_children) do
		child:destroy()
	end
	if self.parent then
		self.parent:removeChild(self)
		-- removeChild 不调用 destroy，但我们已在上方递归销毁了子树
	end
	self._valid = false
	UiManager:_onWidgetDestroyed()
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
	-- 父节点指示不更新 → 跳过整棵子树（祖先已隐藏/禁用）
	if not parent_should_update then
		return
	end
	if not self:shouldUpdate() then
		-- 自身禁用但子节点可能活跃，继续传播
		for _, child in ipairs(self.children) do
			child:update(dt, true)
		end
		return
	end
	-- ★ 钩子：子类（Container）在此对子控件排序，确保子控件 update 时拿到正确尺寸
	self:_preChildrenUpdate(dt)
	for _, child in ipairs(self.children) do
		child:update(dt, true)
	end
	if self.onUpdate then
		self:onUpdate(dt)
	end
end

--- 在子控件 update 之前调用的钩子。默认空实现。
--- Container 覆写此方法以在子控件拿到尺寸前完成布局。
function Widget:_preChildrenUpdate(dt)
end

--- 供可见性裁剪使用的包围盒。子类可覆写以提供比 transform 更精确的尺寸（如 Text 的内部纹理尺寸）
---@return number ax, number ay, number aw, number ah 轴对齐包围盒（屏幕坐标）
function Widget:getCullAABB()
	return self.transform:getGlobalAABB()
end

function Widget:draw()
	if not self:shouldDraw() then
		return
	end
	-- 可见性裁剪：仅在元素完全不可见时跳过该子树
	if not self.always_draw and self._clip_rect then
		local ax, ay, aw, ah = self:getCullAABB()
		local cx, cy, cw, ch = unpack(self._clip_rect)
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
	if not self.shown then
		self.shown = true
		UiManager:invalidateRenderCache()
	end
end

function Widget:hide()
	if self.shown then
		self.shown = false
		UiManager:invalidateRenderCache()
	end
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

	-- 射线检测 fallback：如果开了 raycast_target 且鼠标在区域内，就阻断事件
	-- 有子节点也不影响——子节点和自身 handler 已在前面优先检查过了
	-- 注意：WheelMoved 不在此列——滚轮应穿透到可滚动的父容器
	if self.raycast_target then
		local mouse_event_types = {MousePressed = true, MouseReleased = true, MouseMoved = true}
		if mouse_event_types[event_type] then
			local mx, my = ...
			if mx and self:regionDetection(mx, my) then
				return true
			end
		end
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

--- 容器在 fitChildInRect 后立即调用，让子控件同步完成重排（如文本换行）。
--- 仅在 __enable_size_changed_event 启用时生效。
function Widget:_notifySizeChanged(w, h)
	if self.__enable_size_changed_event then
		self.__oldw = w
		self.__oldh = h
		self:handleEvent("SizeChanged", w, h)
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
	return self
end

return Widget
