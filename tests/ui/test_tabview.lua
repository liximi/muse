local Widget = require "ui.widgets.widget"
local Text = require "ui.widgets.text"
local Panel = require "ui.widgets.panel"
local ProgressBar = require "ui.widgets.progressbar"
local Checkbox = require "ui.widgets.checkbox"
local TabView = require "ui.widgets.tabview"
local Utils = require "ui.utils"

local test = {}
test.name = "TabView"

function test.create(parent)
	parent:removeAllChildren()

	parent:addChild(Text({
		text = "TabView — tabbed content panels",
		font_size = 14,
		h = 20,
		text_color = Utils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 0},
	}))

	-- Tab 1: Info
	local tab1 = Widget()
	tab1:addChild(Text({
		text = "Welcome to the TabView component.\n\nClick the tabs above to switch between panels.\nThe selected tab is visually highlighted.",
		text_color = Utils.UI_COLORS.PRIMARY_TEXT,
		font_size = 14,
		anchor = {0, 0, 1, 1},
		padding = {12, 12, 12, 12},
	}))

	-- Tab 2: Controls
	local tab2 = Widget()
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

	-- Tab 3: Empty state demo
	local tab3 = Widget()
	tab3:addChild(Text({
		text = "No settings available.",
		text_color = Utils.UI_COLORS.HINT,
		font_size = 14,
		anchor = {0, 0, 1, 1},
		padding = {12, 12, 12, 12},
	}))

	parent:addChild(TabView({
		anchor = {0, 0, 1, 1},
		padding = {0, 0, 28, 0},
		tabs = {
			{label = "Info", content = tab1},
			{label = "Controls", content = tab2},
			{label = "Advanced", content = tab3},
		},
		on_tab_changed = function(idx)
			print("TabView tab:", idx)
		end,
	}))
end

return test
