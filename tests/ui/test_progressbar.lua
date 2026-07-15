--------------------------------------------------
-- ProgressBar 测试场景 — 使用 Godot 风格容器布局
--------------------------------------------------

local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local ProgressBar = require "ui.widgets.progressbar"
local HBox = require "ui.widgets.containers.hbox_container"
local VBox = require "ui.widgets.containers.vbox_container"
local Margin = require "ui.widgets.containers.margin_container"
local Utils = require "ui.utils"

local uc = Utils.UI_COLORS
local ORIENT = Utils.ORIENTATION
local SZ = Utils.SIZE_FLAGS

local test = {}
test.name = "ProgressBar"

function test.create(parent)
	parent:removeAllChildren()

	-- 背景
	parent:addChild(Panel({
		anchor = {0, 0, 1, 1},
		bg_color = Utils.RGB(35, 38, 42),
	}))

	-- 根布局
	local margin = parent:addChild(Margin({
		anchor = {0, 0, 1, 1},
		margin_left = 16, margin_right = 16,
		margin_top = 16, margin_bottom = 16,
	}))

	local root = margin:addChild(VBox({ separation = 20 }))

	-- 辅助：建一个带标签的 section
	local function section(title)
		local box = VBox({ separation = 6 })
		box:addChild(Text({
			text = title,
			font_size = 13,
			text_color = uc.SECONDARY_TEXT,
		}))
		return box
	end

	--------------------------------------------------
	-- 1. 静态水平进度条
	--------------------------------------------------
	local sec1 = section("Static Horizontal")
	sec1:addChild(ProgressBar({ value = 0.75, h = 14 }))
	sec1:addChild(ProgressBar({ value = 0.45, h = 8 }))
	sec1:addChild(ProgressBar({ value = 1.0, h = 18, rounding_radius = 9 }))
	root:addChild(sec1)

	--------------------------------------------------
	-- 2. 静态垂直进度条
	--------------------------------------------------
	local sec2 = section("Static Vertical")
	local vhbox = sec2:addChild(HBox({ separation = 16, h = 100 }))
	local vb1 = vhbox:addChild(ProgressBar({ orientation = ORIENT.VERTICAL, value = 0.6, w = 14 }))
	vb1.h_size_flags = SZ.SHRINK_BEGIN  -- 保持14px宽度
	local vb2 = vhbox:addChild(ProgressBar({ orientation = ORIENT.VERTICAL, value = 0.3, w = 14 }))
	vb2.h_size_flags = SZ.SHRINK_BEGIN
	root:addChild(sec2)

	--------------------------------------------------
	-- 3. 交互式水平进度条
	--------------------------------------------------
	local sec3 = section("Interactive Horizontal")

	-- HP 条
	local hp_row = sec3:addChild(VBox({ separation = 2 }))
	local hp_label = hp_row:addChild(Text({
		text = "HP: 75%",
		font_size = 12,
		text_color = uc.SECONDARY_TEXT,
	}))
	hp_row:addChild(ProgressBar({
		value = 0.75,
		interactive = true,
		h = 20,
		fill_color = Utils.RGB(80, 180, 100),
		bg_color = Utils.RGB(40, 50, 40),
		thumb_color = Utils.RGB(120, 220, 140),
		thumb_outline_color = Utils.RGB(40, 60, 40),
		on_value_changed = function(val)
			hp_label:setText(string.format("HP: %.0f%%", val * 100))
		end,
	}))

	-- Volume 条
	local vol_row = sec3:addChild(VBox({ separation = 2 }))
	local vol_label = vol_row:addChild(Text({
		text = "Volume: 80%",
		font_size = 12,
		text_color = uc.SECONDARY_TEXT,
	}))
	vol_row:addChild(ProgressBar({
		value = 0.8,
		interactive = true,
		h = 12,
		fill_color = Utils.RGB(180, 140, 80),
		bg_color = Utils.RGB(50, 45, 40),
		thumb_color = Utils.RGB(220, 180, 120),
		on_value_changed = function(val)
			vol_label:setText(string.format("Volume: %.0f%%", val * 100))
		end,
	}))

	-- 自定义滑块
	local custom_row = sec3:addChild(VBox({ separation = 2 }))
	custom_row:addChild(Text({
		text = "Custom Thumb",
		font_size = 12,
		text_color = uc.SECONDARY_TEXT,
	}))
	custom_row:addChild(ProgressBar({
		value = 0.35,
		interactive = true,
		thumb_radius = 12,
		thumb_color = Utils.RGB(255, 200, 100),
		thumb_outline_color = Utils.RGB(200, 150, 50),
		thumb_outline_width = 3,
		h = 10,
		fill_color = Utils.RGB(100, 140, 200),
	}))

	root:addChild(sec3)

	--------------------------------------------------
	-- 4. 交互式垂直进度条
	--------------------------------------------------
	local sec4 = section("Interactive Vertical")
	local vi_hbox = sec4:addChild(HBox({ separation = 20, h = 160 }))

	local vi_box = vi_hbox:addChild(VBox({ separation = 2 }))
	local vi_label = vi_box:addChild(Text({
		text = "50%",
		font_size = 11,
		text_color = uc.SECONDARY_TEXT,
	}))
	local vi_bar = vi_box:addChild(ProgressBar({
		orientation = ORIENT.VERTICAL,
		value = 0.5,
		interactive = true,
		w = 20,
		thumb_outline_color = Utils.RGB(80, 80, 100),
		on_value_changed = function(val)
			vi_label:setText(string.format("%.0f%%", val * 100))
		end,
	}))
	vi_bar.v_size_flags = SZ.FILL + SZ.EXPAND  -- 占满 VBox 剩余高度

	root:addChild(sec4)
end

return test
