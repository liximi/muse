--------------------------------------------------
-- Checkbox 测试场景 — 使用容器布局
--------------------------------------------------

local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local Checkbox = require "ui.widgets.checkbox"
local Box = require "ui.widgets.containers.box_container"
local Margin = require "ui.widgets.containers.margin_container"
local Utils = require "ui.utils"

local uc = Utils.UI_COLORS

local test = {}
test.name = "Checkbox"

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

	local root = margin:addChild(Box({ separation = 10 }))

	-- 辅助：创建带标签的 checkbox 行
	local function checkbox_row(label, checked, on_checked)
		local cb = Checkbox({
			label = label,
			checked = checked,
			h = 28,
			on_checked = on_checked,
		})
		return cb
	end

	--------------------------------------------------
	-- 标题
	--------------------------------------------------
	root:addChild(Text({
		text = "Checkbox — 复选框与 Toggle 开关",
		font_size = 18,
	}))

	--------------------------------------------------
	-- 1. 基础复选框
	--------------------------------------------------
	root:addChild(Text({
		text = "Checkbox 样式",
		font_size = 12,
		text_color = uc.HINT,
	}))

	root:addChild(checkbox_row("未选中", false,
		function(c) print("Checkbox 1:", c) end))

	root:addChild(checkbox_row("已选中", true,
		function(c) print("Checkbox 2:", c) end))

	root:addChild(checkbox_row("禁用状态", false,
		function(c) print("Checkbox 3:", c) end)):disable()

	--------------------------------------------------
	-- 2. Toggle 开关
	--------------------------------------------------
	root:addChild(Text({
		text = "Toggle 样式",
		font_size = 12,
		text_color = uc.HINT,
		padding = {0, 0, 10, 0},
	}))

	root:addChild(Checkbox({
		style = "toggle",
		label = "关闭",
		h = 28,
		on_checked = function(c) print("Toggle:", c) end,
	}))

	root:addChild(Checkbox({
		style = "toggle",
		label = "开启",
		checked = true,
		h = 28,
		on_checked = function(c) print("Toggle:", c) end,
	}))
end

return test
