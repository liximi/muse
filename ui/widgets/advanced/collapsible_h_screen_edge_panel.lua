local muse = require("init")
local ImageButton = require "ui.widgets.imagebutton"
local Panel = require "ui.widgets.panel"
local Utils = require "ui.utils"
local Tween = require "dependencies.tween"
local Class = require "dependencies.classic"

-- 水平屏幕边缘停靠可收起面板
--[[datas: 此处不包括当前Widget继承的基类所支持的字段
]]
local CollapsiblePanel = Class(Panel, function(self, datas, theme)
	Panel.new(self, datas, theme)
	self._name = "CpllapsibleHScreenEdgePanel"

	self.transform:setAnchor(0, 0, 0, 1)
	self.transform:setPadding(nil, nil, 0, 0)

	self.open = true
	self.right = false

	self.open_x = 0
	self.close_x = 0
	self.collapse_btn_x = 0

	self.left_arrow = love.graphics.newImage(muse.resolve("assets/ui/TablerLayoutSidebarLeftCollapseFilled.png"))
	self.right_arrow = love.graphics.newImage(muse.resolve("assets/ui/TablerLayoutSidebarRightCollapseFilled.png"))
	self.collapse_btn_icon = {
		open = self.left_arrow,
		close = self.right_arrow
	}

	self:setMode(datas.right)
	self:setPosition(self.open_x, 0)

	self.tween = nil
	self.tween_btn = nil

	self.collapse_btn = self:addChild(ImageButton({
		no_text = true,
		w = 24,
		h = 24,
		x = self.collapse_btn_x,
		y = 5,
		normal = Utils.newImageButtonStateStyle(self.collapse_btn_icon.close),
		pressed = Utils.newImageButtonStateStyle(nil, nil, nil, nil, nil, {0, 2}),
		on_click = function(_self)
			self:toggleOpen()
		end
	}))
end)

function CollapsiblePanel:toggleOpen()
	self.open = not self.open
	-- if self.tween then
	--     self.tween:reset()
	-- end
	self.tween = Tween.newFunctionalTween(0.3, {
		x = {self.transform.x, self.open and self.open_x or self.close_x, function(val)
			self.transform:setPosition(val)
		end}
	}, "outQuint")
	self.tween_btn = Tween.newFunctionalTween(0.3, {
		x = {self.collapse_btn.transform.x, self.open and self.collapse_btn_x or self.collapse_btn_x_close,
			 function(val)
			self.collapse_btn.transform:setPosition(val)
		end}
	}, "outQuint")
	self.collapse_btn:setStateStyle("normal", {
		text = "",
		texture = self.open and self.collapse_btn_icon.close or self.collapse_btn_icon.open
	})
end

function CollapsiblePanel:setMode(right)
	self.right = right == true
	local w = self.transform:getSize()
	if self.right then
		self.open_x = love.graphics.getWidth() - w
		self.close_x = love.graphics.getWidth()
		self.collapse_btn_x = 5
		self.collapse_btn_x_close = self.collapse_btn_x - 10 - 24
		self.collapse_btn_icon = {
			open = self.left_arrow,
			close = self.right_arrow
		}
	else
		self.open_x = 0
		self.close_x = -w
		self.collapse_btn_x = w - 5 - 24
		self.collapse_btn_x_close = self.collapse_btn_x + 10 + 24
		self.collapse_btn_icon = {
			open = self.right_arrow,
			close = self.left_arrow
		}
	end
end

function CollapsiblePanel:onUpdate(dt)
	if self.tween_btn then
		if self.tween_btn:update(dt) then
			self.tween_btn = nil
		end
	end
	if self.tween then
		if self.tween:update(dt) then
			self.tween = nil
		end
	end
end

return CollapsiblePanel
