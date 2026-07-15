--------------------------------------------------
-- RadioGroup 测试场景 — 使用容器布局
--------------------------------------------------

local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local RadioGroup = require "ui.widgets.radiogroup"
local Box = require "ui.widgets.containers.box_container"
local Margin = require "ui.widgets.containers.margin_container"
local Utils = require "ui.utils"

local uc = Utils.UI_COLORS

local test = {}
test.name = "RadioGroup"

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

	local root = margin:addChild(Box({ separation = 12 }))

	--------------------------------------------------
	-- 标题
	--------------------------------------------------
	root:addChild(Text({
		text = "RadioGroup — 单选按钮组",
		font_size = 18,
	}))

	--------------------------------------------------
	-- 1. 基础单选组
	--------------------------------------------------
	root:addChild(Text({
		text = "互斥选择 — 同时只能选中一项",
		font_size = 12,
		text_color = uc.HINT,
	}))

	root:addChild(RadioGroup({
		h = 90,
		items = {
			{label = "Apple — fresh and crispy"},
			{label = "Banana — rich in potassium"},
			{label = "Cherry — sweet and tart"},
		},
		selected_index = 1,
		on_selection_changed = function(idx)
			print("Selected fruit:", idx)
		end,
	}))
end

return test
