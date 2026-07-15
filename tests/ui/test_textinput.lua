--------------------------------------------------
-- TextInput 测试场景 — 使用容器布局
--------------------------------------------------

local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local TextInput = require "ui.widgets.textinput"
local Box = require "ui.widgets.containers.box_container"
local Margin = require "ui.widgets.containers.margin_container"
local Utils = require "ui.utils"

local uc = Utils.UI_COLORS

local test = {}
test.name = "TextInput"

function test.create(parent)
	parent:removeAllChildren()

	-- 背景
	parent:addChild(Panel({
		anchor = {0, 0, 1, 1},
	}))

	local margin = parent:addChild(Margin({
		anchor = {0, 0, 1, 1},
		margin_left = 20, margin_right = 20,
		margin_top = 16, margin_bottom = 16,
	}))

	local root = margin:addChild(Box({ separation = 16 }))

	--------------------------------------------------
	-- 标题
	--------------------------------------------------
	root:addChild(Text({
		text = "TextInput — 光标、选择、剪贴板、撤销/重做",
		font_size = 18,
	}))

	--------------------------------------------------
	-- 多行输入
	--------------------------------------------------
	root:addChild(Text({
		text = "多行文本输入（高度自适应）",
		font_size = 12,
		text_color = uc.HINT,
	}))

	local ti = root:addChild(TextInput({
		height_adaptive = false,
		wrap_mode = Utils.TEXT_WRAP_MODE.DEFAULT,
		bg = Panel(),
		text_padding = {10, 10, 10, 10},
		text = "Type here...\nCtrl+Z/Y to undo/redo\nCtrl+C/V to copy/paste\nShift+Arrow to select",
	}))

	--------------------------------------------------
	-- 单行输入
	--------------------------------------------------
	root:addChild(Text({
		text = "单行文本输入（Enter 提交）",
		font_size = 12,
		text_color = uc.HINT,
	}))

	root:addChild(TextInput({
		h = 32,
		single_line = true,
		bg = Panel(),
		text_padding = {8, 8, 8, 8},
		text = "Single line input (Enter submits)",
		on_submit = function()
			print("TextInput submitted!")
		end,
	}))
end

return test
