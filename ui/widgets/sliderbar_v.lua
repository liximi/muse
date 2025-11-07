local Widget = require "ui.widgets.widget"
local Utils = require "ui.utils"
local Panel = require "ui.widgets.panel"
local Button = require "ui.widgets.button"


local SliderBar = Class(Widget, function (self, datas, theme)
	Widget.new(self, "SliderBar Vertical", datas, theme)

	self.drag = false

	self.bg = self:addChild(Panel({
		anchors = {0, 0, 1, 1},
		padding = {0, 0, 0, 0},
		rounding_radius = 4,
	}))
	self.block = self:addChild(Button({
		anchors = {0, 0, 1, 0},
		padding = {0, 0, 0, nil},
		h = 50,
		on_pressed = function(_self)
			self.drag = true
		end,
		on_click = function (_self)
			self.drag = false
		end
	}))
end)


function SliderBar:onMousePressed(x, y, button)
	if button ~= 1 then
		return
	end
	local is_in_scope = self:regionDetection(x, y)
	if is_in_scope then
		return true
	end
end


function SliderBar:onMouseReleased(x, y, button)
	if button ~= 1 then
		return
	end
end


function SliderBar:onMouseMoved(x, y, dx, dy)
	if self.drag then
		
	end
end


return SliderBar