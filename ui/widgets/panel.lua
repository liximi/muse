local Widget = require "ui.widgets.widget"
local Utils = require "ui.utils"
local AddSizeComponent = require "ui.components".AddSize


--一个纯色的面板，可设置面板颜色和边框颜色
local Panel = Class(Widget, function(self, w, h)
	Widget.new(self, "Panel")

	AddSizeComponent(self)
	self:SetSize(w, h)
	self.bg_color = Utils.UI_COLORS.PRIMARY
	self.outline_color = Utils.UI_COLORS.DIVIDER
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

function Panel:OnDraw()
	love.graphics.setColor(unpack(self.bg_color))
	local x, y = self:GetGlobalPosition()
	local sx, sy = self:GetGlobalScale()
	love.graphics.rectangle("fill", x, y, self.width * sx, self.height * sy)
	love.graphics.setColor(unpack(self.outline_color))
	love.graphics.rectangle("line", x, y, self.width * sx, self.height * sy)
end


return Panel