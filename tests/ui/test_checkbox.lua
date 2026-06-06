local Widget = require "ui.widgets.widget"
local Text = require "ui.widgets.text"
local Checkbox = require "ui.widgets.checkbox"
local Utils = require "ui.utils"

local test = {}
test.name = "Checkbox"

function test.create(parent)
	parent:removeAllChildren()

	parent:addChild(Text({
		text = "Checkbox — toggle selection with click or Space key",
		font_size = 14,
		h = 20,
		text_color = Utils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 0},
	}))

	local chk1 = parent:addChild(Checkbox({
		label = "Unchecked box",
		anchor = {0, 0, 0, 0}, w = 300,
		padding = {0, 0, 32, 0},
		h = 28,
		on_checked = function(c) print("Checkbox 1:", c) end,
	}))

	local chk2 = parent:addChild(Checkbox({
		checked = true,
		label = "Checked box",
		anchor = {0, 0, 0, 0}, w = 300,
		padding = {0, 0, 68, 0},
		h = 28,
		on_checked = function(c) print("Checkbox 2:", c) end,
	}))

	local chk3 = parent:addChild(Checkbox({
		style = "toggle",
		checked = true,
		label = "Toggle switch style",
		anchor = {0, 0, 0, 0}, w = 300,
		padding = {0, 0, 104, 0},
		h = 28,
		on_checked = function(c) print("Toggle:", c) end,
	}))
end

return test
