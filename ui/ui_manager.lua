local Theme = require "ui.theme"
local Class = require "dependencies.classic"

local Manager = Class(function(self)
	self.hierarchy = {}
	self.default_theme = Theme()
	self.current_focus = nil
	self._render_cache_dirty = true  -- 首帧强制重建渲染层缓存
	self._layers_cache = {}
	self._sorted_layers = {}
	self._widget_count = 0  -- 活动 widget 总数
end)

function Manager:addWidget(widget)
	assert(widget.parent == nil, "Cannot use a Widget with a parent as the root")
	for _, v in ipairs(self.hierarchy) do
		if v == widget then
			return widget
		end
	end
	table.insert(self.hierarchy, widget)
	widget:_setAttached(true)
	self._render_cache_dirty = true
	return widget
end

--- 从 UiManager 移除根 widget 并通知生命周期
function Manager:removeWidget(widget)
	for k, v in ipairs(self.hierarchy) do
		if v == widget then
			table.remove(self.hierarchy, k)
			widget:_setAttached(false)
			self._render_cache_dirty = true
			return true
		end
	end
	return false
end

--- 标记渲染层缓存失效（Widget show/hide/render_layer 变更时调用）
function Manager:invalidateRenderCache()
	self._render_cache_dirty = true
end

--- 内部：widget 创建时计数（由 Widget:new 调用）
function Manager:_onWidgetCreated()
	self._widget_count = self._widget_count + 1
end

--- 内部：widget 销毁时计数（由 Widget:destroy 调用）
function Manager:_onWidgetDestroyed()
	self._widget_count = math.max(0, self._widget_count - 1)
end

--- 活动 widget 总数（用于性能诊断）
function Manager:getWidgetCount()
	return self._widget_count
end

--------------------------------------------------
-- Focus Management
--------------------------------------------------

function Manager:setFocus(widget)
	if self.current_focus == widget then
		return
	end
	if self.current_focus then
		self.current_focus.focus = false
		if self.current_focus.onRemoveFocus then
			self.current_focus:onRemoveFocus()
		end
	end
	self.current_focus = widget
	if widget then
		widget.focus = true
		if widget.onFocus then
			widget:onFocus()
		end
	end
end

function Manager:getFocus()
	return self.current_focus
end

function Manager:clearFocus()
	self:setFocus(nil)
end

function Manager:moveToTop(widget)
	for k, v in ipairs(self.hierarchy) do
		if v == widget then
			table.remove(self.hierarchy, k)
			table.insert(self.hierarchy, widget)
			break
		end
	end
end

function Manager:moveToBottom(widget)
	for k, v in ipairs(self.hierarchy) do
		if v == widget then
			table.remove(self.hierarchy, k)
			table.insert(self.hierarchy, 1, widget)
			break
		end
	end
end

function Manager:getDefaultTheme()
	return self.default_theme
end

function Manager:setDefaultTheme(theme)
	self.default_theme = theme
	return theme
end

--------------------------------------------------
-- Event Handlers
--------------------------------------------------

function Manager:update(dt)
	for _, widget in ipairs(self.hierarchy) do
		widget:update(dt, true)
	end
end

function Manager:_collectByLayer(widget, layers, parent_layer)
	if not widget:shouldDraw() then
		return
	end
	local layer = widget.render_layer
	-- 只在层切换或根节点时加入绘制列表，同层子孙由 Widget:draw() 递归处理
	if parent_layer == nil or layer ~= parent_layer then
		if not layers[layer] then
			layers[layer] = {}
		end
		table.insert(layers[layer], widget)
	end
	for _, child in ipairs(widget.children) do
		self:_collectByLayer(child, layers, layer)
	end
end

function Manager:draw()
	if self._render_cache_dirty then
		self._layers_cache = {}
		for _, widget in ipairs(self.hierarchy) do
			self:_collectByLayer(widget, self._layers_cache)
		end
		-- 重建排序后的 layer key 列表
		self._sorted_layers = {}
		for layer, _ in pairs(self._layers_cache) do
			table.insert(self._sorted_layers, layer)
		end
		table.sort(self._sorted_layers)
		self._render_cache_dirty = false
	end
	for _, layer in ipairs(self._sorted_layers) do
		for _, widget in ipairs(self._layers_cache[layer]) do
			widget:draw()
		end
	end
end

function Manager:KeyPressed(key, isrepeat)
	-- Tab 键焦点切换（在分发给 widget 之前拦截）
	if key == "tab" then
		self:_handleTabFocus(key, isrepeat)
		return true
	end
	for i = #self.hierarchy, 1, -1 do
		local widget = self.hierarchy[i]
		if widget:handleEvent("KeyPressed", key, isrepeat) then
			return true
		end
	end
	return false
end

function Manager:_collectFocusable(widget, list)
	if not widget or not widget:isOperational() then
		return
	end
	if widget.focusable then
		table.insert(list, widget)
	end
	for _, child in ipairs(widget.children) do
		self:_collectFocusable(child, list)
	end
end

function Manager:_handleTabFocus(key, isrepeat)
	local list = {}
	for _, widget in ipairs(self.hierarchy) do
		self:_collectFocusable(widget, list)
	end
	if #list == 0 then
		return
	end
	local current_idx = 0
	if self.current_focus then
		for i, w in ipairs(list) do
			if w == self.current_focus then
				current_idx = i
				break
			end
		end
	end
	local shift = love.keyboard.isDown("lshift", "rshift")
	local next_idx
	if shift then
		next_idx = current_idx > 1 and current_idx - 1 or #list
	else
		next_idx = current_idx < #list and current_idx + 1 or 1
	end
	self:setFocus(list[next_idx])
end

function Manager:KeyReleased(key)
	for i = #self.hierarchy, 1, -1 do
		local widget = self.hierarchy[i]
		if widget:handleEvent("KeyReleased", key) then
			return true
		end
	end
	return false
end

function Manager:TextInput(text)
	for i = #self.hierarchy, 1, -1 do
		local widget = self.hierarchy[i]
		if widget:handleEvent("TextInput", text) then
			return true
		end
	end
	return false
end

function Manager:MouseMoved(x, y, dx, dy)
	for i = #self.hierarchy, 1, -1 do
		local widget = self.hierarchy[i]
		if widget:handleEvent("MouseMoved", x, y, dx, dy) then
			return true
		end
	end
	return false
end

function Manager:MousePressed(x, y, button)
	local handled = false
	for i = #self.hierarchy, 1, -1 do
		local widget = self.hierarchy[i]
		if widget:handleEvent("MousePressed", x, y, button) then
			handled = true
			break
		end
	end
	-- 点击外部区域清除焦点
	if self.current_focus and not self.current_focus:regionDetection(x, y) then
		self:clearFocus()
	end
	return handled
end

function Manager:MouseReleased(x, y, button)
	for i = #self.hierarchy, 1, -1 do
		local widget = self.hierarchy[i]
		if widget:handleEvent("MouseReleased", x, y, button) then
			return true
		end
	end
	return false
end

function Manager:WheelMoved(x, y)
	for i = #self.hierarchy, 1, -1 do
		local widget = self.hierarchy[i]
		if widget:handleEvent("WheelMoved", x, y) then
			return true
		end
	end
	return false
end

return {
	__instance = nil,
	GetInstance = function(self)
		if not self.__instance then
			self.__instance = Manager()
		end
		return self.__instance
	end
}
