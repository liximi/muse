-- 兼容层，逻辑已迁移至 sliderbar.lua
local SliderBar = require "ui.widgets.sliderbar"
return function(datas, theme)
	datas = datas or {}
	datas.orientation = "horizontal"
	return SliderBar(datas, theme)
end
