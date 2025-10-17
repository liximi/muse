local Widget = require "ui.widgets.widget"
local Utils = require "ui.utils"


--一个纯色的面板，可设置面板颜色和边框颜色
local Panel = Class(Widget, function(self, datas, theme)
	Widget.new(self, "Panel", datas, theme)
	self.bg_color = datas and datas.bg_color or self.theme.panel.bg_color
	self.outline_color = datas and datas.outline_color or self.theme.panel.outline_color
	self.rounding_radius = datas and datas.rounding_radius or self.theme.panel.rounding_radius
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
	local px, py = self.transform:getGlobalPosition()
	local x, y, w, h, r = self.transform:getGlobalBounds()
	love.graphics.push()
	love.graphics.setLineWidth(2)
	if r ~= 0 and r ~= Utils.TWO_PI then
		love.graphics.translate(px, py)
		love.graphics.rotate(r)
		love.graphics.translate(-px, -py)
	end
	love.graphics.setColor(unpack(self.bg_color))
	love.graphics.rectangle("fill", x, y, w, h, self.rounding_radius, self.rounding_radius, self.rounding_radius * 2)
	love.graphics.setColor(unpack(self.outline_color))
	love.graphics.rectangle("line", x, y, w, h, self.rounding_radius, self.rounding_radius, self.rounding_radius * 2)
	love.graphics.pop()
	love.graphics.setLineWidth(1)
end


return Panel