local Widget = require "ui.widgets.widget"
local SliderBar = require "ui.widgets.sliderbar"
local Fonts = require "ui.fonts"
local Utils = require "ui.utils"
local Tween = require "dependencies.tween"
local Class = require "dependencies.classic"

-- 伪常量
local DEFAULT_BAR_HEIGHT = 8      -- 水平滚动条默认高度（像素）
local DEFAULT_BAR_WIDTH = 8       -- 垂直滚动条默认宽度（像素）
local DEFAULT_SCROLLBAR_GAP = 2   -- 滚动条与内容默认间距（像素）
local DEFAULT_SENSITIVITY = 100   -- 鼠标滚轮默认灵敏度（像素）
local TWEEN_DURATION_FACTOR = 0.1 -- 滚动动画时长系数
local DEBUG_LINE_HEIGHT = 14      -- 调试文字行高（像素）
local DEBUG_FONT_SIZE = 16        -- 调试文字字号
local CLIP_RECT_EPSILON = 1       -- 裁剪矩形容差（像素），防止 GPU scissor 与 CPU 裁剪范围不一致导致边缘元素误裁

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
	scrollbar_gap = number 滚动条与内容间距(像素) 默认为2
	v_bar_pad_top = number    垂直滚动条顶部边距（像素，默认 0）
	v_bar_pad_bottom = number 垂直滚动条底部边距（像素，默认 0）
	h_bar_pad_left = number   水平滚动条左侧边距（像素，默认 0）
	h_bar_pad_right = number  水平滚动条右侧边距（像素，默认 0）
	v_bar_min_h = number      垂直滚动条最小高度（像素，默认 0 不限制），空间不足时缩减边距以确保最小高度
	h_bar_min_w = number      水平滚动条最小宽度（像素，默认 0 不限制）
	block_min_len = number    滑块最小长度（像素，默认 0 不限制）
]]
local Scroll = Class(Widget, function(self, datas, theme)
	Widget.new(self, "Scroll", datas, theme)
	self.raycast_target = true

	self.offset_x = 0
	self.offset_y = 0
	self.scrollable_w = datas and datas.scrollable_w or self.transform.w
	self.scrollable_h = datas and datas.scrollable_h or self.transform.h

	self.sensitivity = datas and datas.sensitivity or DEFAULT_SENSITIVITY -- 鼠标滚轮控制滚动的灵敏度(像素)

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

	-- 滚动条边距与最小尺寸
	self._v_bar_pad_top = (datas and datas.v_bar_pad_top) or 0
	self._v_bar_pad_bottom = (datas and datas.v_bar_pad_bottom) or 0
	self._h_bar_pad_left = (datas and datas.h_bar_pad_left) or 0
	self._h_bar_pad_right = (datas and datas.h_bar_pad_right) or 0
	self._v_bar_min_h = (datas and datas.v_bar_min_h) or 0
	self._h_bar_min_w = (datas and datas.h_bar_min_w) or 0
	self._block_min_len = (datas and datas.block_min_len) or 0

	-- 自动追踪内容尺寸。设为 false 可退回到手动 setScrollableW/H
	self._auto_track = (datas and datas.auto_track) ~= false
	self._last_content_w = -1
	self._last_content_h = -1

		local h_bar_h = datas and datas.h_slider_bar_height or DEFAULT_BAR_HEIGHT
		local v_bar_w = datas and datas.v_slider_bar_width or DEFAULT_BAR_WIDTH
		self._h_bar_h = h_bar_h
		self._v_bar_w = v_bar_w
		local bar_gap = (datas and datas.scrollbar_gap) or DEFAULT_SCROLLBAR_GAP
		local right_pad = self.enable_scroll_v and (v_bar_w + bar_gap) or 0
		local bottom_pad = self.enable_scroll_h and (h_bar_h + bar_gap) or 0
		self.scroll_root = self:addChild(Widget("ScrollRoot", {
			anchor = {0, 0, 1, 1},
			padding = {0, right_pad, 0, bottom_pad}
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
		-- _clip_rect 向四周各扩展 CLIP_RECT_EPSILON 像素，确保 CPU 端裁剪
		-- 不会比 GPU scissor 更激进，避免部分可见的元素被整棵子树跳过
		_self._clip_rect = {
			x - CLIP_RECT_EPSILON,
			y - CLIP_RECT_EPSILON,
			w + CLIP_RECT_EPSILON * 2,
			h + CLIP_RECT_EPSILON * 2
		}
	end
	function self.scroll_root.onPostDraw(_self)
		love.graphics.setScissor()
		_self._clip_rect = nil
		love.graphics.pop()
	end

	-- 事件裁剪：鼠标事件仅当在 Scroll 可见区域内时才传播给内容子节点
	-- 防止溢出容器边界的内容仍然响应鼠标事件
	local _widget_handleEvent = Widget.handleEvent
	function self.scroll_root.handleEvent(_self, event_type, ...)
		if event_type == "MousePressed" or event_type == "MouseMoved"
			or event_type == "MouseReleased" or event_type == "WheelMoved" then
			local arg = {...}
			if arg[1] and arg[2] then
				if not self:regionDetection(arg[1], arg[2]) then
					return false
				end
			end
		end
		return _widget_handleEvent(_self, event_type, ...)
	end

	self.item = nil
	if datas and datas.item then
		self:setItem(datas.item)
	end

	if self.enable_scroll_h then
		local percent = Utils.clamp(self.transform.w / self.scrollable_w, 0, 1)
		local padding_right = (self.enable_scroll_v and v_bar_w or 0) + self._h_bar_pad_right
		self.slider_bar_h = self:addChild(SliderBar({
			orientation = "horizontal",
			pivot = {0, 1},
			anchor = {0, 1, 1, 1},
			h = h_bar_h,
			padding = {self._h_bar_pad_left, padding_right, -h_bar_h, 0},
			max_limit = math.max(self.scrollable_w - self.transform.w, 0),
			block_length_percent = percent,
			block_min_len = self._block_min_len,
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
		local padding_bottom = (self.enable_scroll_h and h_bar_h or 0) + self._v_bar_pad_bottom
		self.slider_bar_v = self:addChild(SliderBar({
			orientation = "vertical",
			pivot = {1, 0},
			anchor = {1, 0, 1, 1},
			w = v_bar_w,
			padding = {-v_bar_w, 0, self._v_bar_pad_top, padding_bottom},
			max_limit = math.max(self.scrollable_h - self.transform.h, 0),
			block_length_percent = percent,
			block_min_len = self._block_min_len,
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

--- 最小尺寸 = 自身显式尺寸（如果构造时设了 w/h）
function Scroll:getMinimumSize()
	local w, h = self.transform:getSize()
	return w, h
end

--- 设置要显示的内容
---@param item Widget 要显示的UI
function Scroll:setItem(item)
	self.scroll_root:removeAllChildren()
	if item then
		self.item = self.scroll_root:addChild(item)
		-- 重置内容尺寸跟踪，下一帧 onUpdate 自动捕获新尺寸
		self._last_content_w = -1
		self._last_content_h = -1
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

	local duration = TWEEN_DURATION_FACTOR * math.min(1, math.abs(new_offset - self.offset_x) / self.sensitivity)
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

	local duration = TWEEN_DURATION_FACTOR * math.min(1, math.abs(new_offset - self.offset_y) / self.sensitivity)
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
		self.slider_bar_h:setBlockLengthPercent(percent)
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
		self.slider_bar_v:setBlockLengthPercent(percent)
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
	return true  -- 已处理，阻止冒泡到外层 Scroll
end

function Scroll:onSizeChanged(w, h)
	self:_enforceBarMinSize(w, h)
	self:updateHBlockLengthPercent()
	self:updateVBlockLengthPercent()
	if self.slider_bar_h then
		self.slider_bar_h:setMaxLimit(math.max(self.scrollable_w - self.transform.w, 0))
	end
	if self.slider_bar_v then
		self.slider_bar_v:setMaxLimit(math.max(self.scrollable_h - self.transform.h, 0))
	end
end

-- 确保滚动条 track 满足最小高度/宽度约束（空间不足时按比例缩减边距）
function Scroll:_enforceBarMinSize(cont_w, cont_h)
	if self.slider_bar_v and self._v_bar_min_h > 0 then
		local t = self.slider_bar_v.transform
		local desired_top = self._v_bar_pad_top
		local desired_bot = self._v_bar_pad_bottom + ((self.enable_scroll_h and self._h_bar_h or 0) or 0)
		local track_h = cont_h - desired_top - desired_bot
		if track_h < self._v_bar_min_h then
			local shortage = self._v_bar_min_h - track_h
			local total_pad = desired_top + desired_bot
			if total_pad > 0 then
				desired_top = math.max(0, desired_top - desired_top / total_pad * shortage)
				desired_bot = math.max(0, desired_bot - desired_bot / total_pad * shortage)
			end
		end
		t:setPadding(t.left, t.right, desired_top, desired_bot)
	end
	if self.slider_bar_h and self._h_bar_min_w > 0 then
		local t = self.slider_bar_h.transform
		local desired_left = self._h_bar_pad_left
		local desired_right = self._h_bar_pad_right + ((self.enable_scroll_v and self._v_bar_w or 0) or 0)
		local track_w = cont_w - desired_left - desired_right
		if track_w < self._h_bar_min_w then
			local shortage = self._h_bar_min_w - track_w
			local total_pad = desired_left + desired_right
			if total_pad > 0 then
				desired_left = math.max(0, desired_left - desired_left / total_pad * shortage)
				desired_right = math.max(0, desired_right - desired_right / total_pad * shortage)
			end
		end
		t:setPadding(desired_left, desired_right, t.top, t.bottom)
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

	-- 自动追踪内容尺寸（参考评估报告 #6）：内容大小变了自动更新可滚动范围
	if self._auto_track and self.item then
		local cw, ch = self.item.transform:getSize()
		if self.enable_scroll_h and cw > 0 and cw ~= self._last_content_w then
			self:setScrollableW(cw)
			self._last_content_w = cw
		end
		if self.enable_scroll_v and ch > 0 and ch ~= self._last_content_h then
			self:setScrollableH(ch)
			self._last_content_h = ch
		end
		-- 内容缩小后，修正越界的 offset
		local max_x = math.max(self.scrollable_w - self.transform.w, 0)
		local max_y = math.max(self.scrollable_h - self.transform.h, 0)
		if self.offset_x > max_x then self:setXOffset(max_x, false) end
		if self.offset_y > max_y then self:setYOffset(max_y, false) end
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
	local font = Fonts:getFont("default", DEBUG_FONT_SIZE)
	love.graphics.printf(string.format("Height: %.1f | Scrollable H: %.1f", self.transform.h, self.scrollable_h), font,
		x, y + h, w)
	love.graphics.printf(string.format("Offset X: %.1f | Offset Y: %.1f", self.offset_x, self.offset_y), font, x,
		y + h + DEBUG_LINE_HEIGHT, w)
	love.graphics.pop()
end

return Scroll
