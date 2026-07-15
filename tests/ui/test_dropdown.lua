local Widget = require "ui.widgets.widget"
local Text = require "ui.widgets.text"
local Dropdown = require "ui.widgets.dropdown"
local Utils = require "ui.utils"

local test = {}
test.name = "Dropdown"

function test.create(parent)
	parent:removeAllChildren()

	parent:addChild(Text({
		text = "Dropdown — click to open, select an option",
		font_size = 14,
		h = 20,
		text_color = Utils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 0},
	}))

	-- 基础下拉框（少量选项）
	parent:addChild(Text({
		text = "Few options (no scroll):",
		font_size = 12,
		h = 16,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 36, 0},
	}))
	parent:addChild(Dropdown({
		anchor = {0, 0, 0, 0},
		x = 20,
		y = 56,
		w = 200,
		h = 28,
		options = {"Option Alpha", "Option Beta", "Option Gamma", "Option Delta"},
		selected_index = 1,
		on_select = function(index, value)
			print("Selected:", index, value)
		end,
	}))

	-- 多选项（带滚动条）
	parent:addChild(Text({
		text = "Many options (with scroll):",
		font_size = 12,
		h = 16,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 102, 0},
	}))
	parent:addChild(Dropdown({
		anchor = {0, 0, 0, 0},
		x = 20,
		y = 122,
		w = 200,
		h = 28,
		options = {
			"Apple", "Banana", "Cherry", "Date", "Elderberry",
			"Fig", "Grape", "Honeydew", "Kiwi", "Lemon",
			"Mango", "Nectarine",
		},
		selected_index = 3,
		max_visible_items = 5,
			scrollbar_edge_pad = 6,
		on_select = function(index, value)
			print("Fruit:", value)
		end,
	}))

	-- 底部触发（测试向上翻转）
	parent:addChild(Text({
		text = "Near bottom edge (flips up):",
		font_size = 12,
		h = 16,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 1, 1, 1},
		padding = {0, 0, 60, 0},
	}))
	parent:addChild(Dropdown({
		anchor = {0, 1, 0, 1},
		padding = {20, nil, nil, 36},
		w = 200,
		h = 28,
		options = {"Upward 1", "Upward 2", "Upward 3"},
		selected_index = 1,
	}))
end

return test
