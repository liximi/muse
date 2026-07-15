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

	-- 浅色背景便于观察按钮和容器边界
	parent:addChild(Panel({
		anchor = {0, 0, 1, 1},
		bg_color = Utils.RGB(32, 34, 38),
	}))

	--------------------------------------------------
	-- 总体布局：Margin(边距) → VBox(垂直排列)
	--------------------------------------------------
	local root_vbox = VBox({
		separation = 12,
	})
	local margin = parent:addChild(Margin({
		anchor = {0, 0, 1, 1},
		margin_left = 12, margin_right = 12,
		margin_top = 12, margin_bottom = 12,
	}))
	margin:addChild(root_vbox)
	-- 调试：给 margin 和 root_vbox 画边界框
	margin:enableDebug(true)
	root_vbox:enableDebug(true)

	-- 标题
	root_vbox:addChild(Text({
		text = "Godot 风格容器系统测试",
		font_size = 18,
		text_color = uc.PRIMARY_TEXT,
	}))

	-- 说明
	root_vbox:addChild(Text({
		text = "HBox / VBox / Margin / Center — 子控件最小尺寸驱动 + Fill/Expand 标志",
		font_size = 12,
		text_color = uc.SECONDARY_TEXT,
	}))

	--------------------------------------------------
	-- 1. HBox + 按钮（Fill 默认，等分空间）
	--------------------------------------------------
	root_vbox:addChild(Text({
		text = "1. HBoxContainer — 三个按钮默认 FILL（等分）",
		font_size = 14,
		text_color = uc.PRIMARY_TEXT,
	}))

	local hbox1 = root_vbox:addChild(HBox({
		h = 40,
		separation = 8,
	}))
	hbox1:enableDebug(true)

	hbox1:addChild(Button({ text = "按钮 A" }))
	hbox1:addChild(Button({ text = "按钮 B" }))
	hbox1:addChild(Button({ text = "按钮 C" }))

	--------------------------------------------------
	-- 2. HBox + EXPAND + stretch_ratio
	--------------------------------------------------
	root_vbox:addChild(Text({
		text = "2. HBoxContainer — 右侧 EXPAND(ratio=2) 左侧固定",
		font_size = 14,
		text_color = uc.PRIMARY_TEXT,
	}))

	local hbox2 = root_vbox:addChild(HBox({
		h = 40,
		separation = 8,
	}))
	hbox2:enableDebug(true)

	local left_btn = hbox2:addChild(Button({ text = "固定" }))
	left_btn.h_size_flags = 0 -- SHRINK_BEGIN，不 Fill，不 Expand

	local right_btn = hbox2:addChild(Button({ text = "占2/3" }))
	right_btn.h_size_flags = SZ.FILL + SZ.EXPAND
	right_btn.stretch_ratio = 2

	local right_btn2 = hbox2:addChild(Button({ text = "占1/3" }))
	right_btn2.h_size_flags = SZ.FILL + SZ.EXPAND
	right_btn2.stretch_ratio = 1

	--------------------------------------------------
	-- 3. VBox + SHRINK_CENTER
	--------------------------------------------------
	root_vbox:addChild(Text({
		text = "3. VBoxContainer — 按钮 SHRINK_CENTER（保持最小尺寸居中）",
		font_size = 14,
		text_color = uc.PRIMARY_TEXT,
	}))

	local vbox1 = root_vbox:addChild(VBox({
		h = 120,
		separation = 4,
		alignment = "center",
	}))
	vbox1:enableDebug(true)

	for i = 1, 3 do
		local btn = vbox1:addChild(Button({ text = "居中按钮 " .. i }))
		btn.h_size_flags = SZ.SHRINK_CENTER -- 不 Fill，水平居中
		btn.v_size_flags = 0 -- SHRINK_BEGIN
	end

	--------------------------------------------------
	-- 4. Margin + Center 嵌套
	--------------------------------------------------
	root_vbox:addChild(Text({
		text = "4. MarginContainer → CenterContainer → Button（边距+居中）",
		font_size = 14,
		text_color = uc.PRIMARY_TEXT,
	}))

	local margin = root_vbox:addChild(Margin({
		margin_top = 8,
		margin_bottom = 8,
		margin_left = 24,
		margin_right = 24,
		h = 60,
	}))
	margin:enableDebug(true)

	local center = margin:addChild(Center({}))
	center:enableDebug(true)
	center:addChild(Button({ text = "居中 + 边距" }))

	--------------------------------------------------
	-- 5. HBox alignment 测试
	--------------------------------------------------
	root_vbox:addChild(Text({
		text = "5. HBoxContainer alignment = end（无 EXPAND，整体靠右）",
		font_size = 14,
		text_color = uc.PRIMARY_TEXT,
	}))

	local hbox3 = root_vbox:addChild(HBox({
		h = 40,
		separation = 8,
		alignment = "end",
	}))
	hbox3:enableDebug(true)

	local b1 = hbox3:addChild(Button({ text = "靠" }))
	b1.h_size_flags = 0
	local b2 = hbox3:addChild(Button({ text = "右" }))
	b2.h_size_flags = 0
	local b3 = hbox3:addChild(Button({ text = "!" }))
	b3.h_size_flags = 0
end

return test
