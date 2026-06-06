local Widget = require "ui.widgets.widget"
local SliderBar = require "ui.widgets.sliderbar"
local Fonts = require "ui.fonts"
local Utils = require "ui.utils"
local Tween = require "dependencies.tween"
local Class = require "dependencies.classic"

--[[datas: 此处不包括当前Widget继承的基类所支持的字段
	item = Widget,
	enable_scroll_h = bool 默认为false
	enable_scroll_v = bool 默认为true

	sensitivity = number 鼠标滚轮控制滚动的灵敏度(像素)
	scrollable_w = number 水平方向可滚动的宽度(像素)
	scrollable_h = number 垂直方向可滚动的宽度(像素)

	show_slider_bar = bool 默认为true
	hide_slider_when_cannot_scroll = bool 默认为false
	h_slider_bar_height = number 水平滚动条的高度 默认为8 (滑块会各自向上下超出1像素)
	v_slider_bar_width = number 垂直滚动条的宽度(像素) 默认为8 (滑块会各自向左右超出1像素)
]]
local Scroll = Class(Widget, function(self, datas, theme)
	Widget.new(self, "Scroll", datas, theme)

	self.offset_x = 0
	self.offset_y = 0
	self.scrollable_w = datas and datas.scrollable_w or self.transform.w
	self.scrollable_h = datas and datas.scrollable_h or self.transform.h

	self.sensitivity = datas and datas.sensitivity or 100 -- 鼠标滚轮控制滚动的灵敏度(像素)

	self.show_slider_bar = true
	self.hide_slider_when_cannot_scroll = datas and datas.hide_slider_when_cannot_scroll or false
	self.enable_scroll_h = datas and datas.enable_scroll_h == true or false
	self.enable_scroll_v = true
	if datas then
		if datas.show_slider_bar == false then
			self.show_slider_bar = false
		end
		if datas.enable_scroll_v == false then
			self.enable_scroll_v = false
		end
	end

	self.scroll_root = self:addChild(Widget("ScrollRoot", {
		anchor = {0, 0, self.enable_scroll_h and 0 or 1, self.enable_scroll_v and 0 or 1},
		padding = {0, 0, 0, 0}
	}))
	function self.scroll_root.onDraw(_self)
		local x, y, w, h, r = self.transform:getGlobalBounds()
		love.graphics.push()
		if r ~= 0 and r ~= Utils.TWO_PI then
			local px, py = self.transform:getGlobalPosition()
			love.graphics.translate(px, py)
			love.graphics.rotate(r)
			love.graphics.translate(-px, -py)
		end
		love.graphics.setScissor(x, y, w, h)
		_self._clip_rect = {x, y, w, h}
	end
	function self.scroll_root.onPostDraw(_self)
		love.graphics.setScissor()
		_self._clip_rect = nil
		love.graphics.pop()
	end

	self.item = nil
	if datas and datas.item then
		self:setItem(datas.item)
	end

	local h_slider_bar_height = datas and datas.h_slider_bar_height or 8
	local v_slider_bar_width = datas and datas.v_slider_bar_width or 8
	if self.enable_scroll_h then
		local percent = Utils.clamp(self.transform.w / self.scrollable_w, 0, 1)
		local padding_right = self.enable_scroll_v and v_slider_bar_width or 0
		self.slider_bar_h = self:addChild(SliderBar({
			orientation = "horizontal",
			pivot = {0, 1},
			anchor = {0, 1, 1, 1},
			padding = {0, padding_right, -h_slider_bar_height, 0},
			max_limit = math.max(self.scrollable_w - self.transform.w, 0),
			block_length_percent = percent,
			on_value_update = function(val, percent)
				self:setXOffset(val, false)
			end
		}))
		if not self.show_slider_bar then
			self.slider_bar_h:hide()
		end
	end
	if self.enable_scroll_v then
		local percent = Utils.clamp(self.transform.h / self.scrollable_h, 0, 1)
		local padding_bottom = self.enable_scroll_h and h_slider_bar_height or 0
		self.slider_bar_v = self:addChild(SliderBar({
			orientation = "vertical",
			pivot = {1, 0},
			anchor = {1, 0, 1, 1},
			padding = {-v_slider_bar_width, 0, 0, padding_bottom},
			max_limit = math.max(self.scrollable_h - self.transform.h, 0),
			block_length_percent = percent,
			on_value_update = function(val, percent)
				self:setYOffset(val, false)
			end
		}))
		if not self.show_slider_bar then
			self.slider_bar_v:hide()
		end
	end

	self:enableSizeChangedEvent(true)
	self:onSizeChanged(self.transform.w, self.transform.h)
end)

--- 设置要显示的内容
---@param item Widget 要显示的UI
function Scroll:setItem(item)
	self.scroll_root:removeAllChildren()
	if item then
		self.item = self.scroll_root:addChild(item)
	end
end

function Scroll:setXOffset(offset, tween)
	local new_offset = Utils.clamp(offset, 0, math.max(self.scrollable_w - self.transform.w, 0))
	if new_offset == self.offset_x then
		return
	end
	if not tween then
		self.offset_x = new_offset
		self.scroll_root:setPosition(-new_offset)
		self.slider_bar_h:setValue(new_offset)
		if self.tweenx then
			self.tweenx = nil
		end
		return
	end

	local duration = 0.1 * math.min(1, math.abs(new_offset - self.offset_x) / self.sensitivity)
	if not self.tweenx then
		self.tweenx = Tween.newFunctionalTween(duration, {
			offset_x = {self.offset_x, new_offset, function(val)
				self.offset_x = Utils.clamp(val, 0, math.max(self.scrollable_w - self.transform.w, 0))
				self.scroll_root:setPosition(-self.offset_x)
				self.slider_bar_h:setValue(self.offset_x)
			end}
		}, "linear")
	else
		self.tweenx:setInitialValue("offset_x", self.offset_x)
		self.tweenx:setTargetValue("offset_x", new_offset)
		self.tweenx.duration = duration
		self.tweenx:reset()
	end
end

function Scroll:setYOffset(offset, tween)
	local new_offset = Utils.clamp(offset, 0, math.max(self.scrollable_h - self.transform.h, 0))
	if new_offset == self.offset_y then
		return
	end
	if not tween then
		self.offset_y = new_offset
		self.scroll_root:setPosition(nil, -new_offset)
		self.slider_bar_v:setValue(new_offset)
		if self.tweeny then
			self.tweeny = nil
		end
		return
	end

	local duration = 0.1 * math.min(1, math.abs(new_offset - self.offset_y) / self.sensitivity)
	if not self.tweeny then
		self.tweeny = Tween.newFunctionalTween(duration, {
			offset_y = {self.offset_y, new_offset, function(val)
				self.offset_y = Utils.clamp(val, 0, math.max(self.scrollable_h - self.transform.h, 0))
				self.scroll_root:setPosition(nil, -self.offset_y)
				self.slider_bar_v:setValue(self.offset_y)
			end}
		}, "linear")
	else
		self.tweeny:setInitialValue("offset_y", self.offset_y)
		self.tweeny:setTargetValue("offset_y", new_offset)
		self.tweeny.duration = duration
		self.tweeny:reset()
	end
end

function Scroll:setScrollableW(w)
	self.scrollable_w = w
	self.slider_bar_h:setMaxLimit(math.max(w - self.transform.w, 0))
	self:updateHBlockLengthPercent()
end

function Scroll:setScrollableH(h)
	self.scrollable_h = h
	self.slider_bar_v:setMaxLimit(math.max(h - self.transform.h, 0))
	self:updateVBlockLengthPercent()
end

function Scroll:updateHBlockLengthPercent()
	if self.enable_scroll_h then
		local percent = Utils.clamp(self.transform.w / self.scrollable_w, 0, 1)
		self.slider_bar_h:setBlockLengthtPercent(percent)
		if self.hide_slider_when_cannot_scroll then
			if percent >= 1 and self.slider_bar_h:isShown() then
				self.slider_bar_h:hide()
				if self.slider_bar_v then
					self.slider_bar_v.transform:setPadding(nil, nil, nil, 0)
				end
			elseif percent < 1 and not self.slider_bar_h:isShown() then
				self.slider_bar_h:show()
				if self.slider_bar_v then
					self.slider_bar_v.transform:setPadding(nil, nil, nil, self.slider_bar_h.transform.h)
				end
			end
		end
	end
end

function Scroll:updateVBlockLengthPercent()
	if self.enable_scroll_v then
		local percent = Utils.clamp(self.transform.h / self.scrollable_h, 0, 1)
		self.slider_bar_v:setBlockLengthtPercent(percent)
		if self.hide_slider_when_cannot_scroll then
			if percent >= 1 and self.slider_bar_v:isShown() then
				self.slider_bar_v:hide()
				if self.slider_bar_h then
					self.slider_bar_h.transform:setPadding(nil, 0)
				end
			elseif percent < 1 and not self.slider_bar_v:isShown() then
				self.slider_bar_v:show()
				if self.slider_bar_h then
					self.slider_bar_h.transform:setPadding(nil, self.slider_bar_v.transform.w)
				end
			end
		end
	end
end

--------------------------------------------------
---@region Event Handlers
--------------------------------------------------

function Scroll:onWheelMoved(x, y)
	local mousex, mousey = love.mouse.getPosition()
	if not self:regionDetection(mousex, mousey) then
		return
	end
	if y > 0 then
		self:setYOffset(self.offset_y - self.sensitivity, true)
	elseif y < 0 then
		self:setYOffset(self.offset_y + self.sensitivity, true)
	end
end

function Scroll:onSizeChanged(w, h)
	self:updateHBlockLengthPercent()
	self:updateVBlockLengthPercent()
	if self.slider_bar_h then
		self.slider_bar_h:setMaxLimit(math.max(self.scrollable_w - self.transform.w, 0))
	end
	if self.slider_bar_v then
		self.slider_bar_v:setMaxLimit(math.max(self.scrollable_h - self.transform.h, 0))
	end
end

function Scroll:onUpdate(dt)
	if self.tweenx then
		local finish = self.tweenx:update(dt)
		if finish then
			self.tweenx = nil
		end
	end
	if self.tweeny then
		local finish = self.tweeny:update(dt)
		if finish then
			self.tweeny = nil
		end
	end
end

function Scroll:onDebugDraw()
	local x, y, w, h, r = self.transform:getGlobalBounds()
	love.graphics.push()
	if r ~= 0 and r ~= Utils.TWO_PI then
		local px, py = self.transform:getGlobalPosition()
		love.graphics.translate(px, py)
		love.graphics.rotate(r)
		love.graphics.translate(-px, -py)
	end
	love.graphics.setColor(unpack(Utils.UI_COLORS.PINK))
	local font = Fonts:getFont("default", 16)
	love.graphics.printf(string.format("Height: %.1f | Scrollable H: %.1f", self.transform.h, self.scrollable_h), font,
		x, y + h, w)
	love.graphics.printf(string.format("Offset X: %.1f | Offset Y: %.1f", self.offset_x, self.offset_y), font, x,
		y + h + 14, w)
	love.graphics.pop()
end

return Scroll
