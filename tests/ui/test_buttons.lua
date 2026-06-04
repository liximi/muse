local Widget = require "ui.widgets.widget"
local Text = require "ui.widgets.text"
local Button = require "ui.widgets.button"
local ImageButton = require "ui.widgets.imagebutton"
local Utils = require "ui.utils"

local test = {}
test.name = "Button / ImageButton"

function test.create(parent)
	parent:removeAllChildren()

	parent:addChild(Text({
		text = "Buttons — 6-state interactive buttons",
		font_size = 14,
		h = 20,
		text_color = Utils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 0},
	}))

	local row1 = parent:addChild(Widget({
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 28, 0},
		h = 32,
	}))

	row1:addChild(Button({
		normal = Utils.newButtonStateStyle("Normal"),
		anchor = {0, 0, 0.23, 1},
	}))
	row1:addChild(Button({
		normal = Utils.newButtonStateStyle("Hover"),
		anchor = {0.25, 0, 0.48, 1},
	}))
	row1:addChild(Button({
		normal = Utils.newButtonStateStyle("Disabled"),
		anchor = {0.5, 0, 0.73, 1},
	}))
	row1:addChild(Button({
		normal = Utils.newButtonStateStyle("OnClick"),
		anchor = {0.75, 0, 1, 1},
		on_click = function() print("Clicked!") end,
	}))

	local row2 = parent:addChild(Widget({
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 68, 0},
		h = 32,
	}))

	local btn_sel = row2:addChild(Button({
		normal = Utils.newButtonStateStyle("Selected"),
		anchor = {0, 0, 0.48, 1},
	}))
	btn_sel:setSelected(true)

	local btn_toggle = row2:addChild(Button({
		normal = Utils.newButtonStateStyle("Toggle Me"),
		anchor = {0.5, 0, 1, 1},
		on_click = function(_self)
			_self:setSelected(not (_self.cur_state == Utils.BTN_STATES.SELECTED or _self.cur_state == Utils.BTN_STATES.SELECTED_HOVER))
		end,
	}))

	-- ImageButton row
	local b_img = love.graphics.newImage("assets/panel_glass.png")
	local img_row = parent:addChild(Widget({
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 108, 0},
		h = 32,
	}))

	img_row:addChild(ImageButton({
		no_text = true,
		normal = Utils.newImageButtonStateStyle(b_img, nil, "Normal"),
		anchor = {0, 0, 0.3, 1},
	}))
	img_row:addChild(ImageButton({
		no_text = true,
		normal = Utils.newImageButtonStateStyle(b_img, nil, "Hover"),
		anchor = {0.35, 0, 0.65, 1},
	}))
	img_row:addChild(ImageButton({
		no_text = true,
		normal = Utils.newImageButtonStateStyle(b_img, nil, "Disabled"),
		anchor = {0.7, 0, 1, 1},
	}))
end

return test
