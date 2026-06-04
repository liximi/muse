local Widget = require "ui.widgets.widget"
local Text = require "ui.widgets.text"
local RadioGroup = require "ui.widgets.radiogroup"
local Utils = require "ui.utils"

local test = {}
test.name = "RadioGroup"

function test.create(parent)
	parent:removeAllChildren()

	parent:addChild(Text({
		text = "RadioGroup — mutually exclusive selection",
		font_size = 14,
		h = 20,
		text_color = Utils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 0},
	}))

	parent:addChild(RadioGroup({
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 32, 0},
		h = 90,
		items = {
			{label = "Apple — fresh and crispy"},
			{label = "Banana — rich in potassium"},
			{label = "Cherry — sweet and tart"},
		},
		selected_index = 1,
		on_selection_changed = function(idx)
			print("Selected fruit:", idx)
		end,
	}))

	parent:addChild(Text({
		text = "Another group with different options:",
		font_size = 14,
		h = 20,
		text_color = Utils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 140, 0},
	}))

	parent:addChild(RadioGroup({
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 168, 0},
		h = 60,
		items = {
			{label = "Red pill"},
			{label = "Blue pill"},
		},
		selected_index = 2,
		on_selection_changed = function(idx)
			print("Pill choice:", idx)
		end,
	}))
end

return test
