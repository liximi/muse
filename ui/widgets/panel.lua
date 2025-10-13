local Widget = require "ui.widgets.widget"
local Utils = require "ui.utils"
local Fonts = require "ui.fonts"


--一个纯色的面板，可设置面板颜色和边框颜色
local Panel = Class(Widget, function(self, datas)
	Widget.new(self, "Panel", datas)
	self.bg_color = datas.bg_color or Utils.UI_COLORS.PRIMARY
	self.outline_color = datas.outline_color or Utils.UI_COLORS.DIVIDER
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

local two_pi = 2 * math.pi
function Panel:onDraw()
	local px, py = self.transform:getGlobalPosition()
	local x, y, w, h, r = self.transform:getGlobalBounds()
	love.graphics.push()
	if r ~= 0 and r ~= two_pi then
		love.graphics.translate(px, py)
		love.graphics.rotate(r)
		love.graphics.translate(-px, -py)
	end
	love.graphics.setColor(unpack(self.bg_color))
	love.graphics.rectangle("fill", x, y, w, h)
	love.graphics.setColor(unpack(self.outline_color))
	love.graphics.rectangle("line", x, y, w, h)
	love.graphics.pop()
end


return Panel