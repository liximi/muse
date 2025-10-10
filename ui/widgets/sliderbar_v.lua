local Widget = require "ui.widgets.widget"
local Utils = require "ui.utils"
local AddSizeComponent = require "ui.components".AddSize



local SliderBar = Class(Widget, function (self, w, h)
	Widget.new(self, "SliderBar Vertical")

	self.bg_color = Utils.UI_COLORS.TEXT
	self.outline_color = Utils.UI_COLORS.SECONDARY_TEXT

	AddSizeComponent(self)
	self.transform:setSize(w or 10, h or 100)
end)


function SliderBar:onDraw()
	love.graphics.setColor(unpack(self.bg_color))
	local x, y = self:getGlobalPosition()
	local sx, sy = self:getGlobalScale()
	love.graphics.rectangle("fill", x, y, self.width * sx, self.height * sy)
	love.graphics.setColor(unpack(self.outline_color))
	love.graphics.rectangle("line", x, y, self.width * sx, self.height * sy)
end


return SliderBar