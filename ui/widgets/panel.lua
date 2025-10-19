local Widget = require "ui.widgets.widget"
local Utils = require "ui.utils"


--一个纯色的面板，可设置面板颜色和边框颜色
local Panel = Class(Widget, function(self, datas, theme)
	Widget.new(self, "Panel", datas, theme)
	self.bg_color = datas and datas.bg_color or self.theme.panel.bg_color
	self.outline_color = datas and datas.outline_color or self.theme.panel.outline_color
	self.rounding_radius = datas and datas.rounding_radius or self.theme.panel.rounding_radius
	self.outline_width = datas and datas.outline_width or self.theme.panel.outline_width

	self.enable_shadow = datas and datas.enable_shadow or self.theme.panel.enable_shadow
	if self.enable_shadow then
		self.shadow_offset = datas and datas.shadow_offset or self.theme.panel.shadow_offset or Utils.SHADOW_DEFAULT_PROPS.OFFSET
		self.shadow_color = datas and datas.shadow_color or self.theme.panel.shadow_color or Utils.SHADOW_DEFAULT_PROPS.COLOR
		self.shadow_blur = datas and datas.shadow_blur or self.theme.panel.shadow_blur or Utils.SHADOW_DEFAULT_PROPS.BLUR
	end
end)


--- 设置背景颜色
---@param r number 红色通道的值 0~255
---@param g number 绿色通道的值 0~255
---@param b number 蓝色通道的值 0~255
function Panel:SetBGColor(r, g, b)
	if type(r) == "table" then
		self.bg_color = r
	else
		self.bg_color = Utils.RGB(r, g, b)
	end
end

--- 设置边框颜色
---@param r number 红色通道的值 0~255
---@param g number 绿色通道的值 0~255
---@param b number 蓝色通道的值 0~255
function Panel:SetOutlineColor(r, g, b)
	if type(r) == "table" then
		self.outline_color = r
	else
		self.outline_color = Utils.RGB(r, g, b)
	end
end




function Panel:onDraw()
	local x, y, w, h, r = self.transform:getGlobalBounds()

	if self.enable_shadow then
		Utils.drawRectangleShadow(
			{x+w/2, y+h/2},
			{w/2, h/2},
			self.shadow_blur / 2,
			self.rounding_radius,
			self.shadow_offset,
			self.shadow_color,
			r
		)
	end

	love.graphics.push()
	if r ~= 0 and r ~= Utils.TWO_PI then
		local px, py = self.transform:getGlobalPosition()
		love.graphics.translate(px, py)
		love.graphics.rotate(r)
		love.graphics.translate(-px, -py)
	end
	love.graphics.setColor(unpack(self.bg_color))
	love.graphics.rectangle("fill", x, y, w, h, self.rounding_radius)
	if self.outline_width > 0 then
		love.graphics.setLineWidth(self.outline_width)
		love.graphics.setColor(unpack(self.outline_color))
		love.graphics.rectangle("line", x, y, w, h, self.rounding_radius)
		love.graphics.setLineWidth(1)
	end
	love.graphics.pop()
end


return Panel