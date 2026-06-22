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

	-- Step mode
	parent:addChild(Text({
		text = "Step mode — integer / half-integer / multiple-of-5",
		font_size = 14,
		h = 20,
		text_color = Utils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 90, 0},
	}))

	-- Integer step (step = 1)
	local int_label = parent:addChild(Text({
		text = "Integer: 5",
		font_size = 12,
		h = 16,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 118, 0},
	}))
	parent:addChild(SliderBar({
		orientation = "horizontal",
		max_limit = 10,
		step = 1,
		value = 5,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 138, 0},
		h = 16,
		block_min_len = 15,
		on_value_update = function(val)
			int_label:setText("Integer: " .. tostring(val))
		end,
	}))

	-- Half-integer step (step = 0.5)
	local half_label = parent:addChild(Text({
		text = "Half-integer: 3.5",
		font_size = 12,
		h = 16,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 168, 0},
	}))
	parent:addChild(SliderBar({
		orientation = "horizontal",
		max_limit = 10,
		step = 0.5,
		value = 3.5,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 188, 0},
		h = 16,
		block_min_len = 15,
		on_value_update = function(val)
			half_label:setText("Half-integer: " .. tostring(val))
		end,
	}))

	-- Multiple-of-5 step (step = 5)
	local multi_label = parent:addChild(Text({
		text = "Multiple of 5: 50",
		font_size = 12,
		h = 16,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 218, 0},
	}))
	parent:addChild(SliderBar({
		orientation = "horizontal",
		max_limit = 100,
		step = 5,
		value = 50,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 238, 0},
		h = 16,
		block_min_len = 15,
		on_value_update = function(val)
			multi_label:setText("Multiple of 5: " .. tostring(val))
		end,
	}))

	-- Vertical
	local v_row = parent:addChild(Widget({
		anchor = {0, 0, 1, 1},
		padding = {0, 0, 275, 0},
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
