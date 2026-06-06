local Checkbox = require "ui.widgets.checkbox"
local Utils = require "ui.utils"
local Class = require "dependencies.classic"

-- 单选按钮，继承 Checkbox，渲染圆形轮廓+实心圆点
--[[datas: 与 Checkbox 相同，额外支持：
	circle_size = number  -- 圆形尺寸，默认从主题读取
	circle_color = {r, g, b, a}
	dot_color = {r, g, b, a}
	outline_width = number
	outline_color = {r, g, b, a}
]]
local RadioButton = Class(Checkbox, function(self, datas, theme)
	Checkbox.new(self, datas, theme, "RadioButton")

	self.style = "radio" -- 固定为 radio 样式，不允许切换
	self.box_size = datas and datas.circle_size or datas and datas.box_size or self.theme.radiobutton.circle_size
	self.box_color = datas and datas.circle_color or self.theme.radiobutton.circle_color
	self.check_color = datas and datas.dot_color or self.theme.radiobutton.dot_color
	self.outline_width = datas and datas.outline_width or self.theme.radiobutton.outline_width
	self.outline_color = datas and datas.outline_color or self.theme.radiobutton.outline_color
end)

-- 覆写 onDraw：绘制圆形轮廓+实心圆点
function RadioButton:onDraw()
	local x, y, w, h, r = self.transform:getGlobalBounds()

	love.graphics.push()
	if r ~= 0 and r ~= Utils.TWO_PI then
		local px, py = self.transform:getGlobalPosition()
		love.graphics.translate(px, py)
		love.graphics.rotate(r)
		love.graphics.translate(-px, -py)
	end

	local is_checked = self:isChecked()
	local cx = x + self.box_size / 2
	local cy = y + h / 2
	local radius = self.box_size / 2

	-- 填充圆形背景
	love.graphics.setColor(unpack(self.box_color))
	love.graphics.circle("fill", cx, cy, radius)

	-- 轮廓
	if self.outline_width > 0 then
		love.graphics.setLineWidth(self.outline_width)
		love.graphics.setColor(unpack(self.outline_color))
		love.graphics.circle("line", cx, cy, radius)
		love.graphics.setLineWidth(1)
	end

	-- 选中时的实心圆点
	if is_checked then
		love.graphics.setColor(unpack(self.check_color))
		love.graphics.circle("fill", cx, cy, radius * 0.55)
	end

	love.graphics.pop()
end

return RadioButton
