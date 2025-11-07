local Widget = require "ui.widgets.widget"
local SliderBarH = require "ui.widgets.sliderbar_h"
local SliderBarV = require "ui.widgets.sliderbar_v"
local Fonts = require "ui.fonts"
local Utils = require "ui.utils"
local Tween = require "dependencies.tween"


--[[datas: 此处不包括当前Widget继承的基类所支持的字段
	item = Widget,
	show_slider_bar = bool 默认为true
	enable_scroll_h = bool 默认为false
	enable_scroll_v = bool 默认为true
	max_offset_x = number
	max_offset_y = number
	sensitivity = number
]]
local Scroll = Class(Widget, function(self, datas, theme)
	Widget.new(self, "Scroll", datas, theme)

	self.offset_x = 0
	self.offset_y = 0
	self.max_offset_x = datas and datas.max_offset_x or self.transform.w
	self.max_offset_y = datas and datas.max_offset_y or self.transform.h

	self.sensitivity = datas and datas.sensitivity or 30

	self.show_slider_bar = true
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

	self.scroll_root = self:addChild(Widget("ScrollRoot"))
	self.scroll_root:enableDebug(true)
	self.item = nil
	if datas and datas.item then
		self:setItem(datas.item)
	end

	if self.enable_scroll_h then
		self.slider_bar_h = self:addChild(SliderBarH({
			--TODO
		}))
	end
	if self.enable_scroll_v then
		self.slider_bar_v = self:addChild(SliderBarV({
			pivot = {1, 0},
			anchors = {1, 0, 1, 1},
			padding = {-8, 0, 0, 0},
		}))
	end
end)


--- 设置要显示的内容
---@param item Widget 要显示的UI
function Scroll:setItem(item)
	self.scroll_root:removeAllChildren()
	if item then
		self.item = self.scroll_root:addChild(item)
	end
end


function Scroll:setXOffset(offset)
	self.offset_x = Utils.clamp(offset, 0, self.max_offset_x)
	self.scroll_root:setPosition(-self.offset_x)
end

function Scroll:setYOffset(offset)
	self.offset_y = Utils.clamp(offset, 0, self.max_offset_y)
	self.scroll_root:setPosition(nil, -self.offset_y)
end

function Scroll:setMaxXOffset(max)
	self.max_offset_x = max
end

function Scroll:setMaxYOffset(max)
	self.max_offset_y = max
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
		self:setYOffset(self.offset_y - self.sensitivity)
	elseif y < 0 then
		self:setYOffset(self.offset_y + self.sensitivity)
	end
end


function Scroll:onUpdate(dt)
    -- if self.tween then
    --     if self.tween:update(dt) then
    --         self.tween = nil
    --     end
	-- 	self.scroll_root:setPosition(self.offset_x, -self.offset)
    -- end
end

function Scroll:onDraw()
	local x, y, w, h, r = self.transform:getGlobalBounds()
	love.graphics.push()
	if r ~= 0 and r ~= Utils.TWO_PI then
		local px, py = self.transform:getGlobalPosition()
		love.graphics.translate(px, py)
		love.graphics.rotate(r)
		love.graphics.translate(-px, -py)
	end
	love.graphics.setScissor(x, y, w, h)
end

function Scroll:onPostDraw()
	love.graphics.setScissor()
	love.graphics.pop()
	if self._debug then
		local x, y, w, h, r = self.transform:getGlobalBounds()
		love.graphics.setColor(unpack(Utils.UI_COLORS.PINK))
		love.graphics.printf(string.format("Offset Y: %.1f", self.offset_y), Fonts:getFont("default", 16), x, y+h, w)
	end
end


return Scroll
