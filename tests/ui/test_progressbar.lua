local Widget = require "ui.widgets.widget"
local Text = require "ui.widgets.text"
local ProgressBar = require "ui.widgets.progressbar"
local Utils = require "ui.utils"

local test = {}
test.name = "ProgressBar"

function test.create(parent)
	parent:removeAllChildren()

	parent:addChild(Text({
		text = "ProgressBar — horizontal and vertical",
		font_size = 14,
		h = 20,
		text_color = Utils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 0},
	}))

	parent:addChild(ProgressBar({
		value = 0.75,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 32, 0},
		h = 14,
	}))

	parent:addChild(ProgressBar({
		value = 0.45,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 54, 0},
		h = 8,
	}))

	parent:addChild(ProgressBar({
		value = 1.0,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 70, 0},
		h = 18,
		rounding_radius = 9,
	}))

	-- Vertical
	local v_container = parent:addChild(Widget({
		anchor = {0, 0, 1, 1},
		padding = {0, 0, 100, 0},
	}))
	v_container:addChild(ProgressBar({
		orientation = "vertical",
		value = 0.6,
		anchor = {0, 0, 0, 1},
		w = 14,
		padding = {0, 0, 0, 0},
	}))
	v_container:addChild(ProgressBar({
		orientation = "vertical",
		value = 0.3,
		anchor = {0, 0, 0, 1},
		w = 14,
		padding = {24, 0, 0, 0},
	}))
end

return test
