--------------------------------------------------
-- TabView 测试场景 — 使用容器布局
--------------------------------------------------

local Widget = require "ui.widgets.widget"
local Text = require "ui.widgets.text"
local Panel = require "ui.widgets.panel"
local ProgressBar = require "ui.widgets.progressbar"
local Checkbox = require "ui.widgets.checkbox"
local TabView = require "ui.widgets.tabview"
local Box = require "ui.widgets.containers.box_container"
local Margin = require "ui.widgets.containers.margin_container"
local Utils = require "ui.utils"

local uc = Utils.UI_COLORS

local test = {}
test.name = "TabView"

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

	--------------------------------------------------
	-- 标题
	--------------------------------------------------
	root:addChild(Text({
		text = "TabView — 标签页切换",
		font_size = 18,
	}))

	--------------------------------------------------
	-- Tab 1: Info
	--------------------------------------------------
	local tab1 = Widget({ anchor = {0, 0, 1, 1} })
	tab1:addChild(Text({
		text = "Welcome to the TabView component.\n\nClick the tabs above to switch between panels.\nThe selected tab is visually highlighted.",
		text_color = uc.PRIMARY_TEXT,
		font_size = 14,
		anchor = {0, 0, 1, 1},
		padding = {12, 12, 12, 12},
	}))

	-- Tab 2: Controls
	local tab2 = Widget({ anchor = {0, 0, 1, 1} })
	tab2:addChild(ProgressBar({
		value = 0.7,
		anchor = {0, 0, 1, 0},
		padding = {12, 12, 12},
		h = 12,
	}))
	tab2:addChild(Checkbox({
		checked = true,
		label = "Enable feature A",
		anchor = {0, 0, 1, 0},
		padding = {12, 12, 36, 0},
		h = 24,
	}))
	tab2:addChild(Checkbox({
		label = "Enable feature B",
		anchor = {0, 0, 1, 0},
		padding = {12, 12, 64, 0},
		h = 24,
	}))

	-- Tab 3: Empty state
	local tab3 = Widget({ anchor = {0, 0, 1, 1} })
	tab3:addChild(Text({
		text = "No settings available.",
		text_color = uc.HINT,
		font_size = 14,
		anchor = {0, 0, 1, 1},
		padding = {12, 12, 12, 12},
	}))

	--------------------------------------------------
	-- TabView
	--------------------------------------------------
	local tv = root:addChild(TabView({
		tabs = {
			{label = "Info", content = tab1},
			{label = "Controls", content = tab2},
			{label = "Advanced", content = tab3},
		},
		on_tab_changed = function(idx)
			print("[TabView] Switched to:", idx)
		end,
		v_size_flags = Utils.SIZE_FLAGS.FILL + Utils.SIZE_FLAGS.EXPAND,
	}))
end

return test
