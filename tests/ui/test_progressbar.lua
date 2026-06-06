local Widget = require "ui.widgets.widget"
local Text = require "ui.widgets.text"
local ProgressBar = require "ui.widgets.progressbar"
local Utils = require "ui.utils"

local test = {}
test.name = "ProgressBar"

function test.create(parent)
	parent:removeAllChildren()

	--------------------------------------------------
	-- 静态演示
	--------------------------------------------------
	parent:addChild(Text({
		text = "Static ProgressBar",
		font_size = 14,
		h = 20,
		text_color = Utils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 0, 0},
	}))

	parent:addChild(ProgressBar({
		value = 0.75,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 26, 0},
		h = 14,
	}))

	parent:addChild(ProgressBar({
		value = 0.45,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 48, 0},
		h = 8,
	}))

	parent:addChild(ProgressBar({
		value = 1.0,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 64, 0},
		h = 18,
		rounding_radius = 9,
	}))

	-- Vertical static
	local v_container = parent:addChild(Widget({
		anchor = {0, 0, 1, 0},
		h = 120,
		padding = {0, 0, 74, 0},
	}))
	v_container:addChild(ProgressBar({
		orientation = "vertical",
		value = 0.6,
		anchor = {0, 0, 0, 1},
		w = 14,
	}))
	v_container:addChild(ProgressBar({
		orientation = "vertical",
		value = 0.3,
		anchor = {0, 0, 0, 1},
		w = 14,
		padding = {24, 0, 0, 0},
	}))

	--------------------------------------------------
	-- 交互式演示
	--------------------------------------------------
	parent:addChild(Text({
		text = "Interactive ProgressBar (drag thumb or click track)",
		font_size = 14,
		h = 20,
		text_color = Utils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 210, 0},
	}))

	-- 水平交互进度条
	local h_label = parent:addChild(Text({
		text = "HP: 75%",
		font_size = 12,
		h = 16,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 234, 0},
	}))

	local hp_bar = parent:addChild(ProgressBar({
		value = 0.75,
		interactive = true,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 254, 0},
		h = 20,
		fill_color = Utils.RGB(80, 180, 100),
		bg_color = Utils.RGB(40, 50, 40),
		thumb_color = Utils.RGB(120, 220, 140),
		thumb_outline_color = Utils.RGB(40, 60, 40),
		on_value_changed = function(val)
			h_label:setText(string.format("HP: %.0f%%", val * 100))
		end,
	}))

	-- 音量调节
	local v_label = parent:addChild(Text({
		text = "Volume: 80%",
		font_size = 12,
		h = 16,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 280, 0},
	}))

	local vol_bar = parent:addChild(ProgressBar({
		value = 0.8,
		interactive = true,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 300, 0},
		h = 12,
		fill_color = Utils.RGB(180, 140, 80),
		bg_color = Utils.RGB(50, 45, 40),
		thumb_color = Utils.RGB(220, 180, 120),
		on_value_changed = function(val)
			v_label:setText(string.format("Volume: %.0f%%", val * 100))
		end,
	}))

	-- 自定义滑块大小
	parent:addChild(ProgressBar({
		value = 0.35,
		interactive = true,
		thumb_radius = 12,
		thumb_color = Utils.RGB(255, 200, 100),
		thumb_outline_color = Utils.RGB(200, 150, 50),
		thumb_outline_width = 3,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 320, 0},
		h = 10,
		fill_color = Utils.RGB(100, 140, 200),
	}))

	-- 垂直交互进度条
	local vi_container = parent:addChild(Widget({
		anchor = {1, 0, 1, 0},
		x = -60,
		w = 0,
		h = 160,
		padding = {0, 0, 210, 0},
	}))

	local vi_label = vi_container:addChild(Text({
		text = "50%",
		font_size = 11,
		h = 14,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 1, 0, 1},
		y = -6,
	}))

	local vi_bar = vi_container:addChild(ProgressBar({
		orientation = "vertical",
		value = 0.5,
		interactive = true,
		anchor = {0.5, 0, 0.5, 1},
		w = 20,
		padding = {0, 0, 0, 18},
		thumb_outline_color = Utils.RGB(80, 80, 100),
		on_value_changed = function(val)
			vi_label:setText(string.format("%.0f%%", val * 100))
		end,
	}))
end

return test
