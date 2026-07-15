--------------------------------------------------
-- CenterContainer — 将所有子控件居中放置
-- scene/gui/center_container.cpp
--
-- 子控件保持在最小尺寸，水平和垂直均居中于容器内。
--------------------------------------------------

local Container = require "ui.widgets.containers.container"
local Class = require "dependencies.classic"

--[[datas:
	use_top_left = bool  默认 false。设为 true 时左上对齐（退化为普通容器）
]]
local CenterContainer = Class(Container, function(self, datas, theme)
	Container.new(self, "CenterContainer", datas, theme)

	self.use_top_left = (datas and datas.use_top_left) or false
end)

function CenterContainer:getMinimumSize()
	local mw, mh = 0, 0
	for _, c in ipairs(self.children) do
		if c:isShown() then
			local cw, ch = c:getCombinedMinimumSize()
			if cw > mw then mw = cw end
			if ch > mh then mh = ch end
		end
	end
	return mw, mh
end

function CenterContainer:_sortChildren()
	-- center_container.cpp _notification(NOTIFICATION_SORT_CHILDREN)
	for _, c in ipairs(self:_visibleChildren()) do
		local mw, mh = c:getCombinedMinimumSize()
		local w = self.transform.w
		local h = self.transform.h

		if self.use_top_left then
			self:fitChildInRect(c, 0, 0, w, h)
		else
			local x = math.floor((w - mw) / 2)
			local y = math.floor((h - mh) / 2)
			self:fitChildInRect(c, x, y, w - x * 2, h - y * 2)
		end
	end
end

return CenterContainer
