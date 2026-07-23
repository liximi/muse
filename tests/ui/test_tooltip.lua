--------------------------------------------------
-- Tooltip 测试场景 — 使用容器布局
--------------------------------------------------

local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local TextInput = require "ui.widgets.textinput"
local Button = require "ui.widgets.button"
local Tooltip = require "ui.widgets.tooltip"
local Box = require "ui.widgets.containers.box_container"
local Margin = require "ui.widgets.containers.margin_container"
local Utils = require "ui.utils"

local ORIENT = Utils.ORIENTATION
local uc = Utils.UI_COLORS

local test = {}
test.name = "Tooltip"

function test.create(parent)
	parent:removeAllChildren()
	Tooltip.destroyAll()

	-- 背景
	parent:addChild(Panel({
		anchor = {0, 0, 1, 1},
	}))

	local margin = parent:addChild(Margin({
		anchor = {0, 0, 1, 1},
		margin_left = 20, margin_right = 20,
		margin_top = 16, margin_bottom = 16,
	}))

	local root = margin:addChild(Box({ separation = 14 }))

	--------------------------------------------------
	-- 标题
	--------------------------------------------------
	root:addChild(Text({
		text = "Tooltip — 悬停提示",
		font_size = 18,
	}))

	root:addChild(Text({
		text = "将鼠标悬停在下方控件上 0.5 秒查看 tooltip",
		font_size = 12,
		text_color = uc.HINT,
	}))

	--------------------------------------------------
	-- 按钮 Tooltip
	--------------------------------------------------
	local row1 = root:addChild(Box({ orientation = ORIENT.HORIZONTAL, h = 36, separation = 12 }))

	local btn = row1:addChild(Button({
		text = "Hover me",
	}))
	Tooltip({
		target = btn,
		text = "This is a button tooltip.\nHover for 0.5s to see it.",
	})

	-- Panel Tooltip（长文本自动换行）
	local info_panel = row1:addChild(Panel({
		w = 120,
		h = 36,
		bg_color = {0.15, 0.15, 0.2, 1},
		rounding_radius = 4,
		outline_width = 0,
	}))
	info_panel:setCustomMinimumSize(120, 36)
	local panel_text = info_panel:addChild(Text({
		text = "Panel",
		text_color = uc.TITLE,
		font_size = 14,
		anchor = {0, 0, 1, 1},
		h_align = "center",
		v_align = "center",
	}))
	Tooltip({
		target = info_panel,
		text = "This tooltip has a very long text that should wrap to multiple lines automatically.",
		max_width = 200,
	})

	--------------------------------------------------
	-- TextInput Tooltip
	--------------------------------------------------
	local input = root:addChild(TextInput({
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

	--------------------------------------------------
	-- 底部说明
	--------------------------------------------------
	root:addChild(Text({
		text = "Tooltip 自动注册到 UiManager，无需 parent:addChild()。",
		font_size = 12,
		text_color = uc.HINT,
	}))
end

return test
