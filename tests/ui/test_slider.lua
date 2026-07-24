--------------------------------------------------
-- SliderBar 测试场景 — 使用容器布局
--------------------------------------------------

local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local SliderBar = require "ui.widgets.sliderbar"
local Box = require "ui.widgets.containers.box_container"
local Margin = require "ui.widgets.containers.margin_container"
local Utils = require "ui.utils"

local ORIENT = Utils.ORIENTATION
local SZ = Utils.SIZE_FLAGS
local uc = Utils.UI_COLORS

local test = {}
test.name = "SliderBar"

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

	local root = margin:addChild(Box({ separation = 14 }))

	-- 辅助：创建标签 + 滑块行
	local function slider_row(label_text, slider_datas)
		local box = Box({ separation = 2 })
		local label = box:addChild(Text({
			text = label_text,
			font_size = 12,
			text_color = uc.HINT,
		}))
		local slider = box:addChild(SliderBar(slider_datas))
		return box, label, slider
	end

	-- 辅助：添加行到 root
	local function add_slider_row(label_text, slider_datas)
		local box, label, slider = slider_row(label_text, slider_datas)
		root:addChild(box)
		return label, slider
	end

	--------------------------------------------------
	-- 标题
	--------------------------------------------------
	root:addChild(Text({
		text = "SliderBar — 水平 / 垂直 / 步长模式",
		font_size = 18,
	}))

	--------------------------------------------------
	-- 1. 基础水平滑块
	--------------------------------------------------
	root:addChild(Text({
		text = "基础水平滑块",
		font_size = 12,
		text_color = uc.HINT,
	}))

	local _, s1 = add_slider_row("50%", {
		orientation = "horizontal",
		value = 0.5,
		h = 16,
	})

	local _, s2 = add_slider_row("25%", {
		orientation = "horizontal",
		value = 0.25,
		h = 16,
	})

	--------------------------------------------------
	-- 2. 步长模式
	--------------------------------------------------
	root:addChild(Text({
		text = "步长模式 — 整数 / 半整数 / 5的倍数",
		font_size = 12,
		text_color = uc.HINT,
		padding = {0, 0, 6, 0},
	}))

	local int_label, int_slider = add_slider_row("Integer: 5", {
		orientation = "horizontal",
		max_limit = 10,
		step = 1,
		value = 5,
		h = 16,
		block_min_len = 15,
	})
	int_slider:setOnValueUpdateFn(function(val)
		int_label:setText("Integer: " .. tostring(val))
	end)

	local half_label, half_slider = add_slider_row("Half-integer: 3.5", {
		orientation = "horizontal",
		max_limit = 10,
		step = 0.5,
		value = 3.5,
		h = 16,
		block_min_len = 15,
	})
	half_slider:setOnValueUpdateFn(function(val)
		half_label:setText("Half-integer: " .. tostring(val))
	end)

	local multi_label, multi_slider = add_slider_row("Multiple of 5: 50", {
		orientation = "horizontal",
		max_limit = 100,
		step = 5,
		value = 50,
		h = 16,
		block_min_len = 15,
	})
	multi_slider:setOnValueUpdateFn(function(val)
		multi_label:setText("Multiple of 5: " .. tostring(val))
	end)

	--------------------------------------------------
	-- 3. 垂直滑块
	--------------------------------------------------
	root:addChild(Text({
		text = "垂直滑块",
		font_size = 12,
		text_color = uc.HINT,
		padding = {0, 0, 6, 0},
	}))

	local vrow = Box({ orientation = ORIENT.HORIZONTAL,  separation = 30, h = 120 })
	vrow:addChild(SliderBar({
		orientation = "vertical",
		value = 0.7,
		w = 16,
		h_size_flags = SZ.SHRINK_BEGIN,
	}))

	vrow:addChild(SliderBar({
		orientation = "vertical",
		value = 0.4,
		w = 16,
		h_size_flags = SZ.SHRINK_BEGIN,
	}))

	vrow:addChild(SliderBar({
		orientation = "vertical",
		value = 0.9,
		w = 16,
		h_size_flags = SZ.SHRINK_BEGIN,
	}))

	root:addChild(vrow)
end

return test
