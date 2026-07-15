--------------------------------------------------
-- Modal 测试场景 — 使用容器布局
--------------------------------------------------

local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local Button = require "ui.widgets.button"
local Modal = require "ui.widgets.modal"
local Box = require "ui.widgets.containers.box_container"
local Margin = require "ui.widgets.containers.margin_container"
local Utils = require "ui.utils"
local UiManager = require "ui.ui_manager":GetInstance()

local uc = Utils.UI_COLORS

local test = {}
test.name = "Modal"

-- Modal 只创建一次，避免切换标签页时重复添加到 UiManager
local modal

local function buildModal()
	local modal_content = Widget({ pivot = {0.5, 0.5}, w = 320, h = 180 })
	local modal_bg = modal_content:addChild(Panel({
		anchor = {0, 0, 1, 1},
		padding = {0, 0, 0, 0},
		bg_color = uc.SURFACE,
		rounding_radius = 8,
		outline_width = 1,
		outline_color = uc.LINE,
	}))
	modal_bg:addChild(Text({
		text = "Modal Dialog",
		font_size = 18,
		font_key = "default_bold",
		text_color = uc.TITLE,
		anchor = {0, 0, 1, 0},
		padding = {20, 20, 16, 0},
		h = 24,
	}))
	modal_bg:addChild(Text({
		text = "Click the overlay background or press Escape\nto dismiss this modal.",
		font_size = 14,
		text_color = uc.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0},
		padding = {20, 20, 56, 0},
		h = 36,
	}))
	modal_bg:addChild(Button({
		text = "Close",
		anchor = {1, 1, 1, 1},
		padding = {-80, 20, -40, 20},
		w = 60,
		h = 28,
		on_click = function()
			modal:dismiss()
		end,
	}))

	modal = UiManager:addWidget(Modal({
		content = modal_content,
		dismiss_on_outside_click = true,
		dismiss_on_escape = true,
	}))
	modal:hide()
end

function test.create(parent)
	parent:removeAllChildren()

	if not modal then
		buildModal()
	end

	-- 背景
	parent:addChild(Panel({
		anchor = {0, 0, 1, 1},
	}))

	local margin = parent:addChild(Margin({
		anchor = {0, 0, 1, 1},
		margin_left = 20, margin_right = 20,
		margin_top = 16, margin_bottom = 16,
	}))

	local root = margin:addChild(Box({ separation = 12 }))

	--------------------------------------------------
	-- 标题
	--------------------------------------------------
	root:addChild(Text({
		text = "Modal — 模态弹窗",
		font_size = 18,
	}))

	root:addChild(Text({
		text = "点击按钮打开模态弹窗，点击遮罩或按 Esc 关闭",
		font_size = 12,
		text_color = uc.HINT,
	}))

	--------------------------------------------------
	-- 触发按钮
	--------------------------------------------------
	root:addChild(Button({
		text = "Open Modal",
		h = 32,
		on_click = function()
			modal:show()
		end,
	}))
end

return test
