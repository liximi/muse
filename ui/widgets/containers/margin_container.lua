--------------------------------------------------
-- MarginContainer — 在子控件四周附加像素边距
-- 参考 Godot scene/gui/margin_container.cpp
--
-- 最简单的容器：自身尺寸减去四边 margin 后，
-- 把子控件放入剩余区域。
--------------------------------------------------

local Container = require "ui.widgets.containers.container"
local Class = require "dependencies.classic"

--[[datas:
	margin_left   = number  默认 0
	margin_right  = number  默认 0
	margin_top    = number  默认 0
	margin_bottom = number  默认 0
]]
local MarginContainer = Class(Container, function(self, datas, theme)
	Container.new(self, "MarginContainer", datas, theme)

	self.margin_left = (datas and datas.margin_left) or 0
	self.margin_right = (datas and datas.margin_right) or 0
	self.margin_top = (datas and datas.margin_top) or 0
	self.margin_bottom = (datas and datas.margin_bottom) or 0
end)

--- 最小尺寸 = 子控件最小尺寸 + 四边 margin
--- 参考 Godot margin_container.cpp get_minimum_size
function MarginContainer:getMinimumSize()
	local mw, mh = 0, 0
	for _, c in ipairs(self.children) do
		if c:isShown() then
			local cw, ch = c:getCombinedMinimumSize()
			if cw > mw then mw = cw end
			if ch > mh then mh = ch end
		end
	end
	return mw + self.margin_left + self.margin_right,
	       mh + self.margin_top + self.margin_bottom
end

function MarginContainer:_sortChildren()
	-- 参考 Godot margin_container.cpp _notification(NOTIFICATION_SORT_CHILDREN)
	local w = self.transform.w - self.margin_left - self.margin_right
	local h = self.transform.h - self.margin_top - self.margin_bottom

	for _, c in ipairs(self:_visibleChildren()) do
		self:fitChildInRect(c, self.margin_left, self.margin_top, w, h)
	end
end

return MarginContainer
