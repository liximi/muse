local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local Utils = require "ui.utils"

-- 编辑器入口，目前为骨架占位
-- 后续替换为三面板布局（Tree View + Canvas + Inspector）

local function EditorApp(parent)
	parent:addChild(Panel({
		anchor = {0, 0, 1, 1},
		padding = {0, 0, 0, 0},
	}))

	parent:addChild(Text({
		text = "Muse UI Editor",
		font_size = 24,
		font_key = "default_bold",
		text_color = Utils.UI_COLORS.TITLE,
		anchor = {0.5, 0.5, 0.5, 0.5},
		pivot = {0.5, 0.5},
	}))
end

return EditorApp
