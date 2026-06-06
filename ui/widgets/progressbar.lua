local Widget = require "ui.widgets.widget"
local Utils = require "ui.utils"
local Class = require "dependencies.classic"


-- 进度条组件，支持水平和垂直方向
--[[datas: 此处不包括当前Widget继承的基类所支持的字段
	fill_color = {r, g, b, a}
	bg_color = {r, g, b, a}
	rounding_radius = number
	value = number  -- 0~1，当前进度
	orientation = "horizontal" | "vertical"
]]
local ProgressBar = Class(Widget, function(self, datas, theme)
	Widget.new(self, "ProgressBar", datas, theme)
	self.value = Utils.clamp(datas and datas.value or 0, 0, 1)
	self.fill_color = datas and datas.fill_color or self.theme.progressbar.fill_color
	self.bg_color = datas and datas.bg_color or self.theme.progressbar.bg_color
	self.rounding_radius = datas and datas.rounding_radius
		or self.theme.progressbar.rounding_radius
	self.orientation = datas and datas.orientation or "horizontal"
end)


--- 设置当前进度值
---@param v number 0~1
function ProgressBar:setValue(v)
	self.value = Utils.clamp(v, 0, 1)
end

--- setValue 的别名
---@param v number 0~1
function ProgressBar:setProgress(v)
	self:setValue(v)
end

--- 获取当前进度值
---@return number 0~1
function ProgressBar:getValue()
	return self.value
end


function ProgressBar:onDraw()
	local x, y, w, h, r = self.transform:getGlobalBounds()

	love.graphics.push()
	if r ~= 0 and r ~= Utils.TWO_PI then
		local px, py = self.transform:getGlobalPosition()
		love.graphics.translate(px, py)
		love.graphics.rotate(r)
		love.graphics.translate(-px, -py)
	end

	-- 背景
	love.graphics.setColor(unpack(self.bg_color))
	love.graphics.rectangle("fill", x, y, w, h, self.rounding_radius)

	-- 填充
	local fill_x, fill_y, fill_w, fill_h
	if self.orientation == "horizontal" then
		fill_x, fill_y = x, y
		fill_w, fill_h = w * self.value, h
	else
		fill_x, fill_y = x, y + h * (1 - self.value)
		fill_w, fill_h = w, h * self.value
	end

	if fill_w > 0 and fill_h > 0 then
		love.graphics.setColor(unpack(self.fill_color))
		love.graphics.rectangle("fill", fill_x, fill_y, fill_w, fill_h, self.rounding_radius)
	end

	love.graphics.pop()
end


return ProgressBar
