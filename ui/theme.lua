local Utils = require "ui.utils"
local Class = require "dependencies.classic"

-- 这是默认主题，展示了所有受支持的字段
-- 要创建一个新的主题，你可以继承该主题类，然后变更其中的某些字段
-- 如何使用主题：任何widget都应该支持theme参数作为构造函数的参数，这就是设置该widget的主题的方式
-- 你也可以在UiManager中设置默认主题，当一个widget没有被设置theme时，它将采用默认主题
-- 另外，任何widget也都支持在datas参数中设置一些样式相关的参数，这些设置是最高优先级的，将会覆盖该widget的主题中的相同设置
local Theme = Class(function(self)
	self.panel = {
		bg_color = Utils.UI_COLORS.SURFACE,
		outline_color = Utils.UI_COLORS.LINE,
		rounding_radius = 4,
		outline_width = 1
	}

	self.text = {
		font_key = "default",
		font_size = 16,
		text_color = Utils.UI_COLORS.PRIMARY_TEXT
	}

	self.textinput = {
		font_key = "default",
		font_size = 16,
		text_color = Utils.UI_COLORS.PRIMARY_TEXT,
		text_padding = {8, 8, 8, 8},
		hint_color = Utils.UI_COLORS.SECONDARY_TEXT
	}

	self.image = {
		tint = {1, 1, 1, 1}
	}

	self.button = {
		font_key = "default",
		normal = Utils.newButtonStateStyle("Botton", Utils.UI_COLORS.TITLE, 16, Utils.UI_COLORS.BTN_NORMAL, nil, nil,
			nil, nil, 4),
		pressed = Utils.newButtonStateStyle(nil, nil, nil, nil, nil, nil, {0, 2}),
		selected = Utils.newButtonStateStyle(nil, Utils.UI_COLORS.TITLE, nil, Utils.UI_COLORS.BTN_SELECTED, 1,
			Utils.UI_COLORS.ACCENT),
		hover = Utils.newButtonStateStyle(nil, nil, nil, Utils.UI_COLORS.BTN_HOVER, nil, nil, {0, -1}),
		selected_hover = Utils.newButtonStateStyle(nil, nil, nil, Utils.UI_COLORS.BTN_SELECTED_HOVER, 1,
			Utils.UI_COLORS.ACCENT_LIGHT),
		disabled = Utils.newButtonStateStyle(nil, Utils.UI_COLORS.SECONDARY_TEXT, nil, Utils.UI_COLORS.BTN_DISABLED)
	}

	self.sliderbar = {
		track_color = Utils.UI_COLORS.BG,
		block_color = Utils.UI_COLORS.BTN_NORMAL,
		block_hover_color = Utils.UI_COLORS.BTN_HOVER,
		outline_color = Utils.UI_COLORS.LINE,
		block_length_percent = 0.1,
		sensitivity = 0.8
	}

	self.progressbar = {
		bg_color = Utils.UI_COLORS.BG,
		fill_color = Utils.UI_COLORS.ACCENT,
		rounding_radius = 4
	}

	self.checkbox = {
		box_color = Utils.UI_COLORS.BTN_NORMAL,
		check_color = Utils.UI_COLORS.ACCENT,
		box_size = 20,
		outline_width = 1,
		outline_color = Utils.UI_COLORS.LINE,
		rounding_radius = 3,
		label_color = Utils.UI_COLORS.PRIMARY_TEXT,
		knob_color = Utils.UI_COLORS.TITLE
	}

	self.radiobutton = {
		circle_color = Utils.UI_COLORS.BTN_NORMAL,
		dot_color = Utils.UI_COLORS.ACCENT,
		circle_size = 20,
		outline_width = 1,
		outline_color = Utils.UI_COLORS.LINE,
		label_color = Utils.UI_COLORS.PRIMARY_TEXT
	}

	self.modal = {
		overlay_color = {0, 0, 0, 0.5}
	}

	self.tabview = {
		tab_height = 36,
		tab_bg_normal = Utils.UI_COLORS.BTN_NORMAL,
		tab_bg_selected = Utils.UI_COLORS.SURFACE,
		tab_text_normal = Utils.UI_COLORS.SECONDARY_TEXT,
		tab_text_selected = Utils.UI_COLORS.TITLE,
		tab_font_size = 14,
		tab_outline_color = Utils.UI_COLORS.LINE,
		content_bg = Utils.UI_COLORS.SURFACE,
		content_rounding_radius = 4
	}

	self.imagebutton = {
		font_key = "default",
		normal = Utils.newImageButtonStateStyle(nil, nil, "Botton", Utils.UI_COLORS.TITLE, 16, nil, nil),
		pressed = Utils.newImageButtonStateStyle(nil, nil, nil, nil, nil, {0, 2}),
		selected = Utils.newImageButtonStateStyle(nil, {1, 1, 1, 1}, nil, nil, nil, nil, nil),
		hover = Utils.newImageButtonStateStyle(nil, nil, nil, nil, nil, {0, -1}),
		selected_hover = Utils.newImageButtonStateStyle(),
		disabled = Utils.newImageButtonStateStyle(nil, {0.4, 0.4, 0.4, 1}, nil, Utils.UI_COLORS.SECONDARY_TEXT)
	}
end)

return Theme
