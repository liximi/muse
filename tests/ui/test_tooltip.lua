local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local TextInput = require "ui.widgets.textinput"
local Button = require "ui.widgets.button"
local Tooltip = require "ui.widgets.tooltip"
local Utils = require "ui.utils"

local test = {}
test.name = "Tooltip"

function test.create(parent)
	parent:removeAllChildren()
	Tooltip.destroyAll()  -- 清理上次测试场景遗留的 Tooltip

	parent:addChild(Text({
		text = "Tooltip — hover over widgets to see tooltips",
		font_size = 14,
		h = 20,
		text_color = Utils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 0},
	}))

	-- 一个带 tooltip 的按钮（Tooltip 自动注册到 UiManager，无需 parent:addChild）
	local btn = parent:addChild(Button({
		anchor = {0, 0, 0, 0},
		x = 20,
		y = 40,
		w = 120,
		h = 32,
		normal = Utils.newButtonStateStyle("Hover me"),
	}))
	Tooltip({
		target = btn,
		text = "This is a button tooltip.\nHover for 0.5s to see it.",
	})

	-- 一个 Panel 带 tooltip（长文本自动换行）
	local info_panel = parent:addChild(Panel({
		anchor = {0, 0, 0, 0},
		x = 20,
		y = 90,
		w = 120,
		h = 60,
		bg_color = {0.15, 0.15, 0.2, 1},
		rounding_radius = 4,
		outline_width = 0,
	}))
	info_panel:addChild(Text({
		text = "Panel",
		text_color = Utils.UI_COLORS.TITLE,
		font_size = 14,
		anchor = {0.5, 0.5, 0.5, 0.5},
		pivot = {0.5, 0.5},
	}))
	Tooltip({
		target = info_panel,
		text = "This tooltip has a very long text that should wrap to multiple lines automatically.",
		max_width = 200,
	})

	-- 一个单行 TextInput 带 tooltip
	local input = parent:addChild(TextInput({
		anchor = {0, 0, 0, 0},
		x = 20,
		y = 170,
		w = 200,
		h = 28,
		single_line = true,
		bg = Panel(),
		text = "Single line input",
		text_padding = {6, 6, 5, 5},
	}))
	Tooltip({
		target = input,
		text = "Type something and press Enter to submit.",
	})

	-- 说明文字
	parent:addChild(Text({
		text = "Tooltips auto-register to UiManager.\nNo parent:addChild() needed.",
		font_size = 12,
		h = 32,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 1, 1, 1},
		padding = {0, 16, 8, 8},
	}))
end

return test
