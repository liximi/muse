local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local Button = require "ui.widgets.button"
local Modal = require "ui.widgets.modal"
local Utils = require "ui.utils"
local UiManager = require "ui.ui_manager":GetInstance()

local test = {}
test.name = "Modal"

function test.create(parent)
	parent:removeAllChildren()

	parent:addChild(Text({
		text = "Modal — overlay dialog with click-outside dismiss",
		font_size = 14,
		h = 20,
		text_color = Utils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 0},
	}))

	-- Modal 内容容器 — 给显式尺寸让子树的全局坐标计算正确
	local modal_content = Widget({ w = 320, h = 180 })
	local modal_bg = modal_content:addChild(Panel({
		anchor = {0, 0, 1, 1},
		padding = {0, 0, 0, 0},
		bg_color = Utils.UI_COLORS.SURFACE,
		rounding_radius = 8,
		outline_width = 1,
		outline_color = Utils.UI_COLORS.LINE,
	}))
	modal_bg:addChild(Text({
		text = "Modal Dialog",
		font_size = 18,
		font_key = "default_bold",
		text_color = Utils.UI_COLORS.TITLE,
		anchor = {0, 0, 1, 0},
		padding = {20, 20, 16, 0},
		h = 24,
	}))
	modal_bg:addChild(Text({
		text = "Click the overlay background or press Escape\nto dismiss this modal.",
		font_size = 14,
		text_color = Utils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0},
		padding = {20, 20, 56, 0},
		h = 36,
	}))

	local modal  -- 前置声明
	modal_bg:addChild(Button({
		normal = Utils.newButtonStateStyle("Close"),
		anchor = {1, 1, 1, 1},
		padding = {-80, 20, -40, 20},
		w = 60,
		h = 28,
		on_pressed = function()
			print("[Modal] Close button pressed")
		end,
		on_click = function()
			print("[Modal] Close button onClick fired")
			modal:dismiss()
			print("[Modal] dismiss() returned")
		end,
	}))

	modal = UiManager:addWidget(Modal({
		content = modal_content,
		dismiss_on_outside_click = true,
		dismiss_on_escape = true,
	}))
	modal:hide()

	parent:addChild(Button({
		normal = Utils.newButtonStateStyle("Open Modal"),
		anchor = {0, 0, 0.5, 0},
		padding = {0, 4, 32, 0},
		h = 32,
		on_click = function()
			modal:show()
		end,
	}))
end

return test
