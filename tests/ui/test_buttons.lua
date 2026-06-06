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
		text = "Buttons — 6 种状态 + 选中切换 + ImageButton",
		font_size = 14, h = 20,
		text_color = Utils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0}, padding = {0, 0, 0},
	}))

	--------------------------------------------------
	-- Row 1: 四种预设状态
	--------------------------------------------------
	local row1 = parent:addChild(Widget({
		anchor = {0, 0, 1, 0}, padding = {0, 0, 28, 0}, h = 36,
	}))

	-- Normal
	row1:addChild(Button({
		normal = Utils.newButtonStateStyle("Normal", Utils.UI_COLORS.TITLE, nil, Utils.UI_COLORS.BTN_NORMAL, nil, nil, nil, nil, 4),
		anchor = {0, 0, 0.23, 1}, padding = {0, 2, 0, 0},
		on_click = function() print("Normal clicked") end,
	}))

	-- Hover (preset to hover state)
	local btn_hover = row1:addChild(Button({
		normal = Utils.newButtonStateStyle("Hover", Utils.UI_COLORS.TITLE, nil, Utils.UI_COLORS.BTN_NORMAL, nil, nil, nil, nil, 4),
		hover = Utils.newButtonStateStyle(nil, nil, nil, Utils.UI_COLORS.BTN_HOVER, nil, nil, {0, -1}),
		anchor = {0.25, 0, 0.48, 1}, padding = {0, 2, 0, 0},
	}))
	btn_hover:setState(Utils.BTN_STATES.HOVER)

	-- Selected
	local btn_sel = row1:addChild(Button({
		normal = Utils.newButtonStateStyle("Selected", Utils.UI_COLORS.TITLE, nil, Utils.UI_COLORS.BTN_NORMAL, nil, nil, nil, nil, 4),
		selected = Utils.newButtonStateStyle(nil, Utils.UI_COLORS.TITLE, nil, Utils.UI_COLORS.BTN_SELECTED, 1, Utils.UI_COLORS.ACCENT),
		selected_hover = Utils.newButtonStateStyle(nil, nil, nil, Utils.UI_COLORS.BTN_SELECTED_HOVER, 1, Utils.UI_COLORS.ACCENT_LIGHT),
		anchor = {0.5, 0, 0.73, 1}, padding = {0, 2, 0, 0},
		on_click = function(_self)
			local is_sel = _self.cur_state == Utils.BTN_STATES.SELECTED or _self.cur_state == Utils.BTN_STATES.SELECTED_HOVER
			_self:setSelected(not is_sel)
		end,
	}))
	btn_sel:setSelected(true)

	-- Disabled
	local btn_dis = row1:addChild(Button({
		normal = Utils.newButtonStateStyle("Disabled", Utils.UI_COLORS.SECONDARY_TEXT, nil, Utils.UI_COLORS.BTN_DISABLED, nil, nil, nil, nil, 4),
		anchor = {0.75, 0, 1, 1}, padding = {0, 2, 0, 2},
	}))
	btn_dis:disable()

	--------------------------------------------------
	-- Row 2: Toggle + 说明
	--------------------------------------------------
	local row2 = parent:addChild(Widget({
		anchor = {0, 0, 1, 0}, padding = {0, 0, 72, 0}, h = 36,
	}))

	local btn_toggle = row2:addChild(Button({
		normal = Utils.newButtonStateStyle("Toggle: OFF", Utils.UI_COLORS.TITLE, nil, Utils.UI_COLORS.BTN_NORMAL, nil, nil, nil, nil, 4),
		selected = Utils.newButtonStateStyle("Toggle: ON", Utils.UI_COLORS.TITLE, nil, Utils.UI_COLORS.BTN_SELECTED, 1, Utils.UI_COLORS.ACCENT),
		selected_hover = Utils.newButtonStateStyle("Toggle: ON", Utils.UI_COLORS.TITLE, nil, Utils.UI_COLORS.BTN_SELECTED_HOVER, 1, Utils.UI_COLORS.ACCENT_LIGHT),
		anchor = {0, 0, 0.5, 1}, padding = {0, 2, 0, 0},
		on_click = function(_self)
			local is_sel = _self.cur_state == Utils.BTN_STATES.SELECTED or _self.cur_state == Utils.BTN_STATES.SELECTED_HOVER
			_self:setSelected(not is_sel)
		end,
	}))

	row2:addChild(Text({
		text = "← 点击切换 SELECTED 状态，再点切回",
		font_size = 12, h = 14,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0.52, 0, 1, 0}, padding = {16, 0, 8, 0},
		v_align = "center",
	}))

	--------------------------------------------------
	-- Row 3: 回调演示
	--------------------------------------------------
	local row3 = parent:addChild(Widget({
		anchor = {0, 0, 1, 0}, padding = {0, 0, 116, 0}, h = 36,
	}))

	row3:addChild(Button({
		normal = Utils.newButtonStateStyle("onClick → print", Utils.UI_COLORS.TITLE, nil, Utils.UI_COLORS.BTN_NORMAL, nil, nil, nil, nil, 4),
		anchor = {0, 0, 0.45, 1}, padding = {0, 2, 0, 0},
		on_click = function()
			print("Button: onClick fired!")
		end,
	}))

	row3:addChild(Button({
		normal = Utils.newButtonStateStyle("onPressed → print", Utils.UI_COLORS.TITLE, nil, Utils.UI_COLORS.BTN_NORMAL, nil, nil, nil, nil, 4),
		anchor = {0.5, 0, 1, 1}, padding = {0, 2, 0, 0},
		on_pressed = function(_self, x, y)
			print("Button: onPressed at", x, y)
		end,
	}))

	--------------------------------------------------
	-- Row 4: ImageButton 演示
	--------------------------------------------------
	local tex = love.graphics.newImage("assets/example_image_128x128.png")

	local row4 = parent:addChild(Widget({
		anchor = {0, 0, 1, 0}, padding = {0, 0, 160, 0}, h = 80,
	}))

	row4:addChild(Text({
		text = "ImageButton：",
		font_size = 12, h = 16,
		text_color = Utils.UI_COLORS.PRIMARY_TEXT,
		anchor = {0, 0, 1, 0},
	}))

	-- 带文字的 ImageButton
	local ibtn1 = row4:addChild(ImageButton({
		normal = Utils.newImageButtonStateStyle(tex, nil, "图片按钮"),
		hover = Utils.newImageButtonStateStyle(tex, {0.7, 0.7, 1, 1}, "悬停中"),
		pressed = Utils.newImageButtonStateStyle(tex, {0.5, 0.5, 0.8, 1}, "按下了!"),
		anchor = {0, 0, 0, 0},
		w = 160, h = 48,
		padding = {0, 0, 20, 0},
		on_click = function()
			print("ImageButton (text) clicked!")
		end,
	}))
	ibtn1:enableDebug(true)

	-- 纯图片 ImageButton（无文字）
	local ibtn2 = row4:addChild(ImageButton({
		normal = Utils.newImageButtonStateStyle(tex, nil, nil),
		hover = Utils.newImageButtonStateStyle(tex, {0.8, 0.8, 1, 1}, nil),
		pressed = Utils.newImageButtonStateStyle(tex, {0.5, 0.5, 0.9, 1}, nil),
		no_text = true,
		anchor = {0, 0, 0, 0},
		w = 48, h = 48,
		padding = {175, 0, 20, 0},
		on_click = function()
			print("ImageButton (no text) clicked!")
		end,
	}))
	ibtn2:enableDebug(true)

	row4:addChild(Text({
		text = "← 带文字  /  纯图片 →",
		font_size = 11,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 0, 0, 0},
		padding = {240, 0, 30, 0},
	}))
end

return test
