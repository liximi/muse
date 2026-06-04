local Box = require "ui.widgets.containers.box_container"
return function(datas, theme)
	datas = datas or {}
	datas.orientation = "vertical"
	return Box(datas, theme)
end
