local Utils = require "ui.utils"

--这是默认主题，展示了所有受支持的字段
--要创建一个新的主题，你可以继承该主题类，然后变更其中的某些字段
--如何使用主题：任何widget都应该支持theme参数作为构造函数的参数，这就是设置该widget的主题的方式
--你也可以在UiManager中设置默认主题，当一个widget没有被设置theme时，它将采用默认主题
--另外，任何widget也都支持在datas参数中设置一些样式相关的参数，这些设置是最高优先级的，将会覆盖该widget的主题中的相同设置
local Theme = Class(function(self)
	self.panel = {
		bg_color = Utils.UI_COLORS.BLACK,
		outline_color = Utils.UI_COLORS.WHITE,
		rounding_radius = 0,
	}

	self.text = {
		font_key = "default",
		font_size = 16,
		text_color = Utils.UI_COLORS.WHITE,
	}

	self.image = {
		tint = {1, 1, 1, 1}
	}
end)


return Theme