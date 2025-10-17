local Utils = require "ui.utils"

--这是默认主题，展示了所有受支持的字段
--要创建一个新的主题，你可以继承该主题类，然后变更其中的某些字段
--如何使用主题：任何widget都应该支持theme参数作为构造函数的参数，这就是设置该widget的主题的方式
--你也可以在UiManager中设置默认主题，当一个widget没有被设置theme时，它将采用默认主题
--另外，任何widget也都支持在datas参数中设置一些样式相关的参数，这些设置是最高优先级的，将会覆盖该widget的主题中的相同设置
local Theme = Class(function(self)
	self.panel = {
		bg_color = Utils.UI_COLORS.BLACK,
		outline_color = Utils.UI_COLORS.PALE_GRAY,
		rounding_radius = 0,
		outline_width = 2,
		enable_outline = true,
	}

	self.text = {
		font_key = "default",
		font_size = 16,
		text_color = Utils.UI_COLORS.PALE_GRAY,
	}

	self.image = {
		tint = {1, 1, 1, 1}
	}

	self.button = {
		font_key = "default",--不支持在按钮状态改变时切换字体
		outline_width = 2,--不支持在按钮状态改变时改变描边粗细
		--normal
		font_size = 16,
		text_color = Utils.UI_COLORS.BLACK,
		bg_color = Utils.UI_COLORS.PALE_GRAY,
		outline_color = Utils.UI_COLORS.PALE_GRAY,
		rounding_radius = 5,
		-- offset = {0, 0},--此处不需要设置该字段的值，但是仍然展示在这里，表示支持设置其值
		-- scale = {1, 1},--此处不需要设置该字段的值，但是仍然展示在这里，表示支持设置其值

		--以下所有设置，都是表示按钮在不同状态下的样式，如果缺少某种样式，则会使用normal状态下的对应样式
		--这些设置的字段名采用 normal状态下的字段名+"_"+对应的状态名（小写），比如"font_size_pressed"表示pressed状态下的font_size
		--pressed
		-- text_color_pressed = Utils.UI_COLORS.PINK,
		-- outline_color_pressed = Utils.UI_COLORS.PINK,
		offset_pressed = {0, 2},
		--disabled
		text_color_disabled = Utils.UI_COLORS.SECONDARY_TEXT,
		bg_color_disabled = Utils.UI_COLORS.DISABLED,
		outline_color_disabled = Utils.UI_COLORS.DISABLED,
		--selected
		text_color_selected = Utils.UI_COLORS.PINK,
		outline_color_selected = Utils.UI_COLORS.PINK,
		--hover
		bg_color_hover = Utils.UI_COLORS.WHITE,
		outline_color_hover = Utils.UI_COLORS.WHITE,
		--selected_hover
		text_color_selected_hover = Utils.UI_COLORS.PINK,
		bg_color_selected_hover = Utils.UI_COLORS.DISABLED,
		outline_color_selected_hover = Utils.UI_COLORS.PINK,
	}
end)


return Theme