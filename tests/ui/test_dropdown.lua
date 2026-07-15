--------------------------------------------------
-- Dropdown 测试场景 — 使用 Godot 风格容器布局
--------------------------------------------------

local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local Dropdown = require "ui.widgets.dropdown"
local Box = require "ui.widgets.containers.box_container"
local Margin = require "ui.widgets.containers.margin_container"
local Spacer = require "ui.widgets.spacer"
local Utils = require "ui.utils"

local uc = Utils.UI_COLORS

local test = {}
test.name = "Dropdown"

function test.create(parent)
	parent:removeAllChildren()

	-- 背景
	parent:addChild(Panel({
		anchor = {0, 0, 1, 1},
	}))

	-- 根布局：Margin → VBox
	local margin = parent:addChild(Margin({
		anchor = {0, 0, 1, 1},
		margin_left = 20, margin_right = 20,
		margin_top = 16, margin_bottom = 16,
	}))

	local root = margin:addChild(Box({ separation = 12 }))

	-- 辅助：创建带标签的 section（标签 + 控件）
	local function section(label_text)
		local box = Box({ separation = 4 })
		box:addChild(Text({
			text = label_text,
			font_size = 12,
			text_color = uc.HINT,
		}))
		return box
	end

	--------------------------------------------------
	-- 标题
	--------------------------------------------------
	root:addChild(Text({
		text = "Dropdown — 下拉选择组件",
		font_size = 18,
	}))

	--------------------------------------------------
	-- 1. 基础用法：少量选项（无滚动）
	--------------------------------------------------
	local sec1 = section("基础用法 — 少量选项（无滚动条）")
	sec1:addChild(Dropdown({
		h = 28,
		options = {"Option Alpha", "Option Beta", "Option Gamma", "Option Delta"},
		selected_index = 1,
		on_select = function(index, value)
			print("[Dropdown] Selected:", index, value)
		end,
	}))
	root:addChild(sec1)

	--------------------------------------------------
	-- 2. 多选项：带滚动条
	--------------------------------------------------
	local sec2 = section("多选项 — 超出 max_visible_items 时出现滚动条")
	sec2:addChild(Dropdown({
		h = 28,
		options = {
			"Apple", "Banana", "Cherry", "Date", "Elderberry",
			"Fig", "Grape", "Honeydew", "Kiwi", "Lemon",
			"Mango", "Nectarine", "Orange", "Peach",
		},
		selected_index = 3,
		max_visible_items = 5,
		on_select = function(index, value)
			print("[Dropdown] Fruit:", value)
		end,
	}))
	root:addChild(sec2)

	--------------------------------------------------
	-- 弹性占位 — 把 Section 3 推到底部
	--------------------------------------------------
	root:addChild(Spacer())

	--------------------------------------------------
	-- 3. 底部触发：自动向上翻转
	--------------------------------------------------
	local sec3 = section("底部触发 — 下方空间不足时自动向上翻转")
	sec3:addChild(Dropdown({
		h = 28,
		options = {"Upward Alpha", "Upward Beta", "Upward Gamma"},
		selected_index = 1,
		on_select = function(index, value)
			print("[Dropdown] Upward:", value)
		end,
	}))
	root:addChild(sec3)
end

return test
