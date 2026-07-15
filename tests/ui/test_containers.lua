--------------------------------------------------
-- Godot 风格容器系统测试场景
-- 演示 HBoxContainer / VBoxContainer / MarginContainer / CenterContainer
--------------------------------------------------

local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local Button = require "ui.widgets.button"
local HBox = require "ui.widgets.containers.hbox_container"
local VBox = require "ui.widgets.containers.vbox_container"
local Margin = require "ui.widgets.containers.margin_container"
local Center = require "ui.widgets.containers.center_container"
local Utils = require "ui.utils"

local SZ = Utils.SIZE_FLAGS
local uc = Utils.UI_COLORS

local test = {}
test.name = "Godot Containers"

function test.create(parent)
	parent:removeAllChildren()

	-- 调试辅助
	local function dbg(w) w:enableDebug(true); return w end

	-- 测试用按钮样式
	local BTN = { bg_color = Utils.RGB(65, 70, 80), text_color = uc.PRIMARY_TEXT }

	-- 背景
	parent:addChild(Panel({
		anchor = {0, 0, 1, 1},
		bg_color = Utils.RGB(55, 58, 64),
	}))

	-- 总体布局
	local root_vbox = VBox({ separation = 12 })
	local margin = parent:addChild(Margin({
		anchor = {0, 0, 1, 1},
		margin_left = 12, margin_right = 12,
		margin_top = 12, margin_bottom = 12,
	}))
	margin:addChild(root_vbox)
	margin:enableDebug(true)
	root_vbox:enableDebug(true)

	root_vbox:addChild(dbg(Text({
		text = "Godot 风格容器系统测试  |  粉框 = Widget 边界",
		font_size = 18,
		text_color = uc.PRIMARY_TEXT,
	})))

	--------------------------------------------------
	-- 1. HBox 等分
	--------------------------------------------------
	root_vbox:addChild(dbg(Text({
		text = "1. HBox — 三个按钮默认 FILL（等分）",
		font_size = 14, text_color = uc.PRIMARY_TEXT,
	})))

	do
		local hbox = root_vbox:addChild(HBox({ h = 40, separation = 8 }))
		hbox:enableDebug(true)
		hbox:addChild(dbg(Button({ normal = BTN, text = "Button A" })))
		hbox:addChild(dbg(Button({ normal = BTN, text = "Button B" })))
		hbox:addChild(dbg(Button({ normal = BTN, text = "Button C" })))
	end

	--------------------------------------------------
	-- 2. HBox + stretch_ratio
	--------------------------------------------------
	root_vbox:addChild(dbg(Text({
		text = "2. HBox — SHRINK(固定) + EXPAND ratio=2 + EXPAND ratio=1",
		font_size = 14, text_color = uc.PRIMARY_TEXT,
	})))

	do
		local hbox = root_vbox:addChild(HBox({ h = 40, separation = 8 }))
		hbox:enableDebug(true)

		local b1 = hbox:addChild(dbg(Button({ normal = BTN, text = "固定" })))
		b1.h_size_flags = 0

		local b2 = hbox:addChild(dbg(Button({ normal = BTN, text = "占2/3" })))
		b2.h_size_flags = SZ.FILL + SZ.EXPAND
		b2.stretch_ratio = 2

		local b3 = hbox:addChild(dbg(Button({ normal = BTN, text = "占1/3" })))
		b3.h_size_flags = SZ.FILL + SZ.EXPAND
		b3.stretch_ratio = 1
	end

	--------------------------------------------------
	-- 3. VBox + SHRINK_CENTER
	--------------------------------------------------
	root_vbox:addChild(dbg(Text({
		text = "3. VBox — SHRINK_CENTER（保持最小尺寸，水平居中）",
		font_size = 14, text_color = uc.PRIMARY_TEXT,
	})))

	do
		local vbox = root_vbox:addChild(VBox({ h = 120, separation = 4, alignment = "center" }))
		vbox:enableDebug(true)
		for i = 1, 3 do
			local btn = vbox:addChild(dbg(Button({ normal = BTN, text = "居中 " .. i })))
			btn.h_size_flags = SZ.SHRINK_CENTER
			btn.v_size_flags = 0
		end
	end

	--------------------------------------------------
	-- 4. Margin + Center 嵌套
	--------------------------------------------------
	root_vbox:addChild(dbg(Text({
		text = "4. Margin → Center → Button（边距 + 居中嵌套）",
		font_size = 14, text_color = uc.PRIMARY_TEXT,
	})))

	do
		local m = root_vbox:addChild(Margin({
			margin_top = 8, margin_bottom = 8,
			margin_left = 24, margin_right = 24,
			h = 60,
		}))
		m:enableDebug(true)
		local c = m:addChild(Center({}))
		c:enableDebug(true)
		c:addChild(dbg(Button({ normal = BTN, text = "居中+边距" })))
	end

	--------------------------------------------------
	-- 5. HBox alignment
	--------------------------------------------------
	root_vbox:addChild(dbg(Text({
		text = "5. HBox alignment=end（无 EXPAND 时整体靠右）",
		font_size = 14, text_color = uc.PRIMARY_TEXT,
	})))

	do
		local hbox = root_vbox:addChild(HBox({ h = 40, separation = 8, alignment = "end" }))
		hbox:enableDebug(true)

		local b1 = hbox:addChild(dbg(Button({ normal = BTN, text = "靠" })))
		b1.h_size_flags = 0
		local b2 = hbox:addChild(dbg(Button({ normal = BTN, text = "右" })))
		b2.h_size_flags = 0
		local b3 = hbox:addChild(dbg(Button({ normal = BTN, text = "!" })))
		b3.h_size_flags = 0
	end

	--------------------------------------------------
	-- 6. auto_size — 容器自动根据子控件调整自身尺寸
	--------------------------------------------------
	root_vbox:addChild(dbg(Text({
		text = "6. VBox auto_size=true — 高度自动跟随子控件（粉色框 = 容器边界）",
		font_size = 14, text_color = uc.PRIMARY_TEXT,
	})))

	do
		local vbox = root_vbox:addChild(VBox({ auto_size = true, separation = 4 }))
		vbox:enableDebug(true)
		vbox:addChild(dbg(Button({ normal = BTN, text = "第一行" })))
		vbox:addChild(dbg(Button({ normal = BTN, text = "第二行" })))
		vbox:addChild(dbg(Button({ normal = BTN, text = "第三行 —— VBox 高度自动收缩" })))
	end
end

return test
