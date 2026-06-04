-- 兼容层，逻辑已迁移至 list_container.lua
local ListContainer = require "ui.widgets.containers.list_container"
return function(datas, theme)
	datas = datas or {}
	datas.orientation = "horizontal"
	return ListContainer(datas, theme)
end
