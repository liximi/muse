local Utils = require "ui.utils"

--这是默认主题，展示了所有受支持的字段
--要创建一个新的主题，你可以继承该主题类，然后变更其中的某些字段
--如何使用主题：任何widget都应该支持theme参数作为构造函数的参数，这就是设置该widget的主题的方式
--你也可以在UiManager中设置默认主题，当一个widget没有被设置theme时，它将采用默认主题
--另外，任何widget也都支持在datas参数中设置一些样式相关的参数，这些设置是最高优先级的，将会覆盖该widget的主题中的相同设置
local Theme = Class(function(self)
	self.panel = {
		bg_color = Utils.UI_COLORS.BG,
		outline_color = Utils.UI_COLORS.LINE,
		rounding_radius = 8,
		outline_width = 1,
	}

	self.text = {
		font_key = "default",
		font_size = 16,
		text_color = Utils.UI_COLORS.PRIMARY_TEXT,
	}

	self.textinput = {
		font_key = "default",
		font_size = 16,
		text_color = Utils.UI_COLORS.PRIMARY_TEXT,
		text_padding = {8, 8, 8, 8},
		hint_color = Utils.UI_COLORS.SECONDARY_TEXT,
	}

	self.image = {
		tint = {1, 1, 1, 1}
	}

	self.button = {
		font_key = "default",--不支持在按钮状态改变时切换字体
		normal = Utils.newButtonStateStyle(
			"Botton", Utils.UI_COLORS.TITLE, 18,--text, text_color, font_size
			Utils.UI_COLORS.LIGHT_PINK,--bg_color
			nil, nil, nil, nil, 8--outline_width, outline_color, offset, scale, rounding_radius
		),
		--以下所有设置，都是表示按钮在不同状态下的样式，如果缺少某种样式，则会使用normal状态下的对应样式
		pressed = Utils.newButtonStateStyle(
			nil, nil, nil, nil, nil, nil, {0, 2}--offset
		),
		selected = Utils.newButtonStateStyle(
			nil, nil, nil,
			Utils.UI_COLORS.BTN_SELECTED,
			2, Utils.UI_COLORS.LIGHT_PINK
		),
		hover = Utils.newButtonStateStyle(
			nil, nil, nil,
			Utils.UI_COLORS.PINK,
			nil, nil, {0, -1}
		),
		selected_hover = Utils.newButtonStateStyle(
			nil, nil, nil,
			Utils.UI_COLORS.BTN_SELECTED_HOVER,
			2, Utils.UI_COLORS.LIGHT_PINK
		),
		disabled = Utils.newButtonStateStyle(
			nil, Utils.UI_COLORS.SECONDARY_TEXT, nil,
			Utils.UI_COLORS.BTN_DISABLED
		),
	}

	self.imagebutton = {
		font_key = "default",--不支持在按钮状态改变时切换字体
		normal = Utils.newImageButtonStateStyle(
			nil, nil,--texture, tint
			"Botton", Utils.UI_COLORS.TITLE, 18,--text, text_color, font_size
			nil, nil--offset, scale
		),
		--以下所有设置，都是表示按钮在不同状态下的样式，如果缺少某种样式，则会使用normal状态下的对应样式
		pressed = Utils.newImageButtonStateStyle(
			nil, nil, nil, nil, nil, {0, 2}--offset
		),
		selected = Utils.newImageButtonStateStyle(),
		hover = Utils.newImageButtonStateStyle(
			nil, nil, nil, nil, nil, {0, -1}
		),
		selected_hover = Utils.newImageButtonStateStyle(),
		disabled = Utils.newImageButtonStateStyle(
			nil, Utils.UI_COLORS.BTN_DISABLED,
			nil, Utils.UI_COLORS.SECONDARY_TEXT
		),
	}
end)


return Theme