local Text = require "ui.widgets.text"
local Button = require "ui.widgets.button"
local CollapsiblePanel = require "ui.widgets.advanced.collapsible_h_screen_edge_panel"
local Utils = require "ui.utils"

local test = {}
test.name = "CollapsiblePanel"

function test.create(parent)
	parent:removeAllChildren()

	parent:addChild(Text({
		text = "CollapsiblePanel — 屏幕边缘停靠可收起面板",
		font_size = 14, h = 20,
		text_color = Utils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0}, padding = {0, 0, 0},
	}))

	parent:addChild(Text({
		text = "点击 ←/→ 箭头按钮收起/展开面板，带 300ms outQuint 动画。实际使用时 dock 到屏幕边缘。",
		font_size = 11, h = 14,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 0, 1, 0}, padding = {0, 0, 24, 0},
	}))

	--------------------------------------------------
	-- 左侧可收起面板
	--------------------------------------------------
	local left_panel = parent:addChild(CollapsiblePanel({
		w = 200,
		bg_color = {0.10, 0.10, 0.13, 0.97},
		outline_width = 1,
		outline_color = Utils.UI_COLORS.LINE,
		rounding_radius = {0, 6, 6, 0},  -- 仅右侧圆角
		padding = {0, 0, 44, 0},
	}))

	left_panel:addChild(Text({
		text = "左侧面板",
		font_size = 16,
		text_color = Utils.UI_COLORS.TITLE,
		anchor = {0, 0, 1, 0},
		padding = {12, 40, 12, 0},
	}))

	left_panel:addChild(Text({
		text = "这是一个从左侧边缘\n滑出的可收起面板。\n\n点击右上角箭头按钮\n可以将面板收起。",
		font_size = 13,
		text_color = Utils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0},
		padding = {12, 12, 48, 0},
	}))

	left_panel:addChild(Button({
		normal = Utils.newButtonStateStyle("内部按钮", nil, nil, nil, nil, nil, nil, nil, 4),
		anchor = {0, 1, 1, 1},
		padding = {12, 12, nil, 12},
		h = 32,
		on_click = function()
			print("Left panel button clicked")
		end,
	}))

	--------------------------------------------------
	-- 右侧可收起面板
	--------------------------------------------------
	local right_panel = parent:addChild(CollapsiblePanel({
		right = true,
		w = 180,
		bg_color = {0.12, 0.12, 0.18, 0.97},
		outline_width = 1,
		outline_color = Utils.UI_COLORS.LINE,
		rounding_radius = {6, 0, 0, 6},  -- 仅左侧圆角
		padding = {0, 0, 44, 0},
	}))

	right_panel:addChild(Text({
		text = "右侧面板",
		font_size = 16,
		text_color = Utils.UI_COLORS.TITLE,
		anchor = {0, 0, 1, 0},
		padding = {12, 40, 12, 0},
	}))

	right_panel:addChild(Text({
		text = "这是从屏幕右侧\n停靠的面板。\n\nsetMode(true) 会让\n面板锚定到右侧。",
		font_size = 13,
		text_color = Utils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0},
		padding = {12, 12, 48, 0},
	}))

	-- 右侧面板底部提示
	right_panel:addChild(Text({
		text = "点击左下角箭头收起",
		font_size = 11,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 1, 1, 1},
		padding = {12, 12, nil, 12},
		h = 20,
	}))
end

return test
