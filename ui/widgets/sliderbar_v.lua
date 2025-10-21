local Widget = require "ui.widgets.widget"
local Utils = require "ui.utils"



local SliderBar = Class(Widget, function (self, w, h)
	Widget.new(self, "SliderBar Vertical")

	self.bg_color = Utils.UI_COLORS.LINE
	self.outline_width = 0
	self.outline_color = Utils.UI_COLORS.LINE

	self.transform:setSize(w or 8, h or 100)
end)


function SliderBar:onDraw()
	love.graphics.setColor(unpack(self.bg_color))
	local x, y = self:getGlobalPosition()
	local sx, sy = self:getGlobalScale()
	love.graphics.rectangle("fill", x, y, self.width * sx, self.height * sy)
	if self.outline_color and self.outline_width and self.outline_width > 0 then
		love.graphics.setColor(unpack(self.outline_color))
		love.graphics.rectangle("line", x, y, self.width * sx, self.height * sy)
	end
end


return SliderBar