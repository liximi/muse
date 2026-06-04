local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local TextInput = require "ui.widgets.textinput"
local Utils = require "ui.utils"

local test = {}
test.name = "TextInput"

function test.create(parent)
	parent:removeAllChildren()

	parent:addChild(Text({
		text = "TextInput — cursor, selection, clipboard, undo/redo",
		font_size = 14,
		h = 20,
		text_color = Utils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 0},
	}))

	parent:addChild(TextInput({
		height_adaptive = true,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 28, 0},
		bg = Panel(),
		text_padding = {10, 10, 10, 10},
		text = "Type here...\nCtrl+Z/Y to undo/redo\nCtrl+C/V to copy/paste\nShift+Arrow to select",
	}))

	parent:addChild(Text({
		text = "Single-line TextInput",
		font_size = 14,
		h = 20,
		text_color = Utils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 140, 0},
	}))

	parent:addChild(TextInput({
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 168, 0},
		h = 32,
		bg = Panel(),
		text_padding = {8, 8, 8, 8},
		text = "Single line input",
	}))
end

return test
