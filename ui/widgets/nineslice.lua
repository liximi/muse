local Widget = require "ui.widgets.widget"
local Utils = require "ui.utils"
local Class = require "dependencies.classic"

--[[datas: 此处不包括当前Widget继承的基类所支持的字段
	texture = love.Texture
	center_padding = {left, right, top, bottom}
]]
local NineSlice = Class(Widget, function(self, datas)
	Widget.new(self, "NineSlice", datas)
	self.raycast_target = true

	self.texture = datas.texture ---@type love.Texture
	--[[self.quads:
		1, 2, 3,
		4, 5, 6,
		7, 8, 9
	]]
	self.tex_w, self.tex_h = self.texture:getDimensions()
	self.center_padding = datas.center_padding
	local l, r, t, b = unpack(datas.center_padding)
	local x1, y1 = self.tex_w - r, self.tex_h - b
	local w, h = x1 - l, y1 - t
	self.quads = {love.graphics.newQuad(0, 0, l, t, self.tex_w, self.tex_h),
				  love.graphics.newQuad(l, 0, w, t, self.tex_w, self.tex_h),
				  love.graphics.newQuad(x1, 0, r, t, self.tex_w, self.tex_h),
				  love.graphics.newQuad(0, t, l, h, self.tex_w, self.tex_h),
				  love.graphics.newQuad(l, t, w, h, self.tex_w, self.tex_h),
				  love.graphics.newQuad(x1, t, r, h, self.tex_w, self.tex_h),
				  love.graphics.newQuad(0, y1, l, b, self.tex_w, self.tex_h),
				  love.graphics.newQuad(l, y1, w, b, self.tex_w, self.tex_h),
				  love.graphics.newQuad(x1, y1, r, b, self.tex_w, self.tex_h)}
end)

function NineSlice:onDraw()
	local x, y, w, h, r = self.transform:getGlobalBounds()

	love.graphics.push()
	if r ~= 0 and r ~= Utils.TWO_PI then
		local px, py = self.transform:getGlobalPosition()
		love.graphics.translate(px, py)
		love.graphics.rotate(r)
		love.graphics.translate(-px, -py)
	end
	love.graphics.setColor(1, 1, 1, 1)
	for i = 1, 3 do
		for j = 1, 3 do
			local lx, ly, lsx, lsy
			if j == 1 then
				lx = x
				lsx = 1
			elseif j == 2 then
				lx = x + self.center_padding[1]
				lsx = (w - self.center_padding[1] - self.center_padding[2]) /
						  (self.tex_w - self.center_padding[1] - self.center_padding[2])
			else
				lx = x + w - self.center_padding[2]
				lsx = 1
			end
			if i == 1 then
				ly = y
				lsy = 1
			elseif i == 2 then
				ly = y + self.center_padding[3]
				lsy = (h - self.center_padding[3] - self.center_padding[4]) /
						  (self.tex_h - self.center_padding[3] - self.center_padding[4])
			else
				ly = y + h - self.center_padding[4]
				lsy = 1
			end
			love.graphics.draw(self.texture, self.quads[(i - 1) * 3 + j], lx, ly, nil, lsx, lsy)
		end
	end

	love.graphics.pop()
end

function NineSlice:onDebugDraw()
	local x, y, w, h, r = self.transform:getGlobalBounds()

	love.graphics.push()
	if r ~= 0 and r ~= Utils.TWO_PI then
		local px, py = self.transform:getGlobalPosition()
		love.graphics.translate(px, py)
		love.graphics.rotate(r)
		love.graphics.translate(-px, -py)
	end

	love.graphics.setColor(unpack(Utils.UI_COLORS.PINK))
	local x0 = x + self.center_padding[1]
	local y0 = y + self.center_padding[3]
	local x1 = x + w - self.center_padding[2]
	local y1 = y + h - self.center_padding[4]
	local x2 = x + w
	local y2 = y + h
	love.graphics.line(x, y0, x2, y0) -- 上面的水平分割线
	love.graphics.line(x, y1, x2, y1) -- 下面的水平分割线
	love.graphics.line(x0, y, x0, y2) -- 左面的垂直分割线
	love.graphics.line(x1, y, x1, y2) -- 右面的垂直分割线

	love.graphics.pop()
end

return NineSlice
