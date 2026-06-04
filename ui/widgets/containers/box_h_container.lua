local Box = require "ui.widgets.containers.box_container"
return function(datas, theme)
	datas = datas or {}
	datas.orientation = "horizontal"
	return Box(datas, theme)
end
