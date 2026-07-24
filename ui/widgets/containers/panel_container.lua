--------------------------------------------------
-- PanelContainer — 带样式盒背景的容器
--
-- 在内部子控件周围绘制一个面板背景。
-- 子控件被限制在面板边距的内部区域。
-- 禁止子控件使用 EXPAND（Panel 自身不参与弹性分配）。
--------------------------------------------------

local Container = require "ui.widgets.containers.container"
local Utils = require "ui.utils"
local Class = require "dependencies.classic"

local SZ = Utils.SIZE_FLAGS

--[[datas:
	bg_color        = {r, g, b, a}  面板背景色
	outline_width   = number         边框宽度
	outline_color   = {r, g, b, a}  边框颜色
	rounding_radius = number         圆角半径
]]
local PanelContainer = Class(Container, function(self, datas, theme)
	Container.new(self, "PanelContainer", datas, theme)
	-- Panel 作为可见背景，默认拦截鼠标
	self.raycast_target = true

	self.bg_color = datas and datas.bg_color or self.theme.panel.bg_color
	self.outline_width = datas and datas.outline_width or self.theme.panel.outline_width
	self.outline_color = datas and datas.outline_color or self.theme.panel.outline_color
	self.rounding_radius = datas and datas.rounding_radius or self.theme.panel.rounding_radius
end)

function PanelContainer:getMinimumSize()
	local mw, mh = 0, 0
	for _, c in ipairs(self.children) do
		if c:isShown() then
			local cmw, cmh = c:getCombinedMinimumSize()
			mw = math.max(mw, cmw)
			mh = math.max(mh, cmh)
		end
	end
	local margin = self.outline_width or 0
	return mw + margin * 2, mh + margin * 2
end

function PanelContainer:getDesiredSize()
	local dw, dh = 0, 0
	for _, c in ipairs(self.children) do
		if c:isShown() then
			local cdw, cdh = c:getDesiredSize()
			dw = math.max(dw, cdw)
			dh = math.max(dh, cdh)
		end
	end
	local margin = self.outline_width or 0
	return dw + margin * 2, dh + margin * 2
end

function PanelContainer:getInnerCombinedMaximumSize()
	local cw, ch = Container.getInnerCombinedMaximumSize(self)
	local margin = self.outline_width or 0
	return math.max(0, cw - margin * 2), math.max(0, ch - margin * 2)
end

function PanelContainer:_getAllowedSizeFlagsHorizontal()
	return { SZ.FILL, SZ.SHRINK_BEGIN, SZ.SHRINK_CENTER, SZ.SHRINK_END }
end

function PanelContainer:_getAllowedSizeFlagsVertical()
	return { SZ.FILL, SZ.SHRINK_BEGIN, SZ.SHRINK_CENTER, SZ.SHRINK_END }
end

function PanelContainer:_sortChildren()
	local cw, ch = self.transform:getSize()
	local margin = self.outline_width or 0
	local inner_x = margin
	local inner_y = margin
	local inner_w = math.max(0, cw - margin * 2)
	local inner_h = math.max(0, ch - margin * 2)

	for _, c in ipairs(self.children) do
		if c:isShown() then
			self:fitChildInRect(c, inner_x, inner_y, inner_w, inner_h)
		end
	end
end

function PanelContainer:onDraw()
	local cw, ch = self.transform:getSize()
	if self.bg_color then
		love.graphics.setColor(self.bg_color)
		if self.rounding_radius and self.rounding_radius > 0 then
			love.graphics.rectangle("fill", 0, 0, cw, ch, self.rounding_radius, self.rounding_radius)
		else
			love.graphics.rectangle("fill", 0, 0, cw, ch)
		end
	end
	if self.outline_width and self.outline_width > 0 and self.outline_color then
		love.graphics.setColor(self.outline_color)
		love.graphics.setLineWidth(self.outline_width)
		if self.rounding_radius and self.rounding_radius > 0 then
			love.graphics.rectangle("line", 0, 0, cw, ch, self.rounding_radius, self.rounding_radius)
		else
			love.graphics.rectangle("line", 0, 0, cw, ch)
		end
		love.graphics.setLineWidth(1)
	end
end

return PanelContainer
