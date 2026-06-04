local Widget = require "ui.widgets.widget"
local Text = require "ui.widgets.text"
local SliderBar = require "ui.widgets.sliderbar"
local Utils = require "ui.utils"

local test = {}
test.name = "SliderBar"

function test.create(parent)
	parent:removeAllChildren()

	parent:addChild(Text({
		text = "SliderBar — horizontal and vertical",
		font_size = 14,
		h = 20,
		text_color = Utils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 0},
	}))

	-- Horizontal
	parent:addChild(SliderBar({
		orientation = "horizontal",
		value = 0.5,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 32, 0},
		h = 16,
	}))
	parent:addChild(SliderBar({
		orientation = "horizontal",
		value = 0.25,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 58, 0},
		h = 16,
	}))

	-- Vertical
	local v_row = parent:addChild(Widget({
		anchor = {0, 0, 1, 1},
		padding = {0, 0, 90, 0},
	}))
	v_row:addChild(SliderBar({
		orientation = "vertical",
		value = 0.7,
		anchor = {0, 0, 0, 1},
		w = 16,
	}))
	v_row:addChild(SliderBar({
		orientation = "vertical",
		value = 0.4,
		anchor = {0, 0, 0, 1},
		w = 16,
		padding = {30, 0, 0, 0},
	}))
	v_row:addChild(SliderBar({
		orientation = "vertical",
		value = 0.9,
		anchor = {0, 0, 0, 1},
		w = 16,
		padding = {60, 0, 0, 0},
	}))
end

return test
