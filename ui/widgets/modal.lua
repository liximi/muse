local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Utils = require "ui.utils"


-- 模态框，全屏半透明遮罩 + 居中内容
--[[datas: 此处不包括基类所支持的字段
	overlay_color = {r, g, b, a}  -- 遮罩颜色
	dismiss_on_outside_click = boolean  -- 点击内容区域外是否关闭，默认 true
	dismiss_on_escape = boolean  -- Escape 键是否关闭，默认 true
	content = Widget  -- 初始内容 widget
	on_dismiss = function  -- 关闭回调
]]
local Modal = Class(Widget, function(self, datas, theme)
	Widget.new(self, "Modal", datas, theme)

	self._is_showing = false
	self.dismiss_on_outside_click = datas and datas.dismiss_on_outside_click ~= false
	self.dismiss_on_escape = datas and datas.dismiss_on_escape ~= false
	self.onDismiss = datas and datas.on_dismiss

	-- 全屏遮罩
	local overlay_color = datas and datas.overlay_color or self.theme.modal.overlay_color
	self.overlay = self:addChild(Panel({
		anchor = {0, 0, 1, 1},
		padding = {0, 0, 0, 0},
		bg_color = overlay_color,
	}))

	-- 遮罩拦截所有鼠标事件，防止穿透到背景 UI
	-- 子元素优先处理（内容区域的按钮等），未被处理的才到遮罩
	function self.overlay.onMousePressed(_self, x, y, button)
		print("[Modal] overlay.onMousePressed x=" .. x .. " y=" .. y .. " inside_content=" .. tostring(self.content_container:regionDetection(x, y)))
		if self.dismiss_on_outside_click and not self.content_container:regionDetection(x, y) then
			self:dismiss()
			print("[Modal] dismissed by outside click")
		end
		return true
	end
	function self.overlay.onMouseReleased(_self, x, y, button)
		return true
	end
	function self.overlay.onMouseMoved(_self, x, y, dx, dy)
		return true
	end
	function self.overlay.onWheelMoved(_self, x, y)
		return true
	end

	-- 居中内容容器
	self.content_container = self.overlay:addChild(Widget({
		pivot = {0.5, 0.5},
		anchor = {0.5, 0.5, 0.5, 0.5},
	}))

	if datas and datas.content then
		self:setContent(datas.content)
	end
end)


--- 设置模态框的内容
---@param widget Widget
function Modal:setContent(widget)
	self.content_container:removeAllChildren()
	if widget then
		self.content_container:addChild(widget)
	end
end

--- 获取内容容器（用于外部直接操作）
---@return Widget
function Modal:getContentContainer()
	return self.content_container
end

--- 显示模态框
function Modal:show()
	if self._is_showing then return end
	self._is_showing = true
	self.shown = true
	self:moveToTop()
end

--- 隐藏模态框
function Modal:hide()
	if not self._is_showing then return end
	self._is_showing = false
	self.shown = false
end

--- 关闭（触发 onDismiss 回调后隐藏）
function Modal:dismiss()
	if not self._is_showing then return end
	self:hide()
	if self.onDismiss then
		self:onDismiss()
	end
end

--- 是否正在显示
function Modal:isShowing()
	return self._is_showing
end


-- 点击遮罩空白区域关闭
-- 因为遮罩的 onMousePressed 已拦截所有事件，此 handler 不再需要
function Modal:onKeyPressed(key, isrepeat)
	if not self._is_showing then return end
	if self.dismiss_on_escape and key == "escape" then
		self:dismiss()
		return true
	end
	return true  -- 拦截其他键盘事件
end


return Modal
