local Widget = require "ui.widgets.widget"
local Utils = require "ui.utils"
local Fonts = require "ui.fonts"
local AddSizeComponent = require "ui.components".AddSize


--一个纯色的面板，可设置面板颜色和边框颜色
local Panel = Class(Widget, function(self, datas)
	Widget.new(self, "Panel", datas)

	AddSizeComponent(self)
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

function Panel:onDraw()
	love.graphics.setColor(unpack(self.bg_color))
	local x, y = self.transform:getGlobalPosition()
	local w, h = self.transform:getGlobalScaledSize()
	love.graphics.rectangle("fill", x, y, w, h)
	love.graphics.setColor(unpack(self.outline_color))
	love.graphics.rectangle("line", x, y, w, h)
	if self._debug then
		love.graphics.setColor(unpack(Utils.debug_color1))
		-- love.graphics.rectangle("line", x-1, y-1, w+2, h+2)
		love.graphics.printf(self.transform:__tostring(), Fonts:getFont("default", 16), love.graphics.getWidth()-300, 0, 300)

		local g_aabb = self:getGlobalAABB()
		local aabb = self:getAABB()
		love.graphics.rectangle("line", g_aabb.x + 10, g_aabb.y + 10, g_aabb.w - 20, g_aabb.h - 20)
		love.graphics.setColor(unpack(Utils.debug_color2))
		love.graphics.rectangle("line", aabb.x + 20, aabb.y + 20, aabb.w - 40, aabb.h - 40)
	end
end


return Panel