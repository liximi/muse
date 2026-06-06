local Widget = require "ui.widgets.widget"
local Utils = require "ui.utils"
local Components = require "ui.components"
local Class = require "dependencies.classic"

-- 伪常量
local DEFAULT_THUMB_RADIUS_RATIO = 1.2  -- 滑块半径相对薄边一半的比例
local MIN_THUMB_RADIUS = 5              -- 滑块最小半径（像素）

-- 进度条组件，支持水平和垂直方向，支持开启交互模式让用户拖拽调节
--[[datas: 此处不包括当前Widget继承的基类所支持的字段
    value = number           -- 0~1，当前进度
    orientation = "horizontal" | "vertical"
    fill_color = {r, g, b, a}
    bg_color = {r, g, b, a}
    rounding_radius = number

    -- 交互模式
    interactive = boolean           -- 是否允许用户手动调节，默认 false
    thumb_radius = number           -- 滑块圆点半径（像素），默认自动计算
    thumb_color = {r, g, b, a}      -- 滑块颜色，默认 fill_color
    thumb_outline_color = {r, g, b, a}  -- 滑块描边色，默认 nil
    thumb_outline_width = number    -- 滑块描边宽度，默认 2
    on_value_changed = function(value)  -- 值变化回调
]]
local ProgressBar = Class(Widget, function(self, datas, theme)
	Widget.new(self, "ProgressBar", datas, theme)
	self.value = Utils.clamp(datas and datas.value or 0, 0, 1)
	self.fill_color = datas and datas.fill_color or self.theme.progressbar.fill_color
	self.bg_color = datas and datas.bg_color or self.theme.progressbar.bg_color
	self.rounding_radius = datas and datas.rounding_radius or self.theme.progressbar.rounding_radius
	self.orientation = datas and datas.orientation or "horizontal"

	-- 交互模式
	self.interactive = datas and datas.interactive == true
	if self.interactive then
		self.thumb_radius = datas.thumb_radius  -- nil 时自动计算
		self.thumb_color = datas.thumb_color or self.fill_color
		self.thumb_outline_color = datas.thumb_outline_color
		self.thumb_outline_width = datas.thumb_outline_width or 2
		self.onValueChanged = datas.on_value_changed

		self._dragging = false
		self._hover_thumb = false
		self.focusable = true

		Components.addHoverState(self)
	end
end)

--------------------------------------------------
-- Value
--------------------------------------------------

--- 设置当前进度值
---@param v number 0~1
function ProgressBar:setValue(v)
	local old = self.value
	self.value = Utils.clamp(v, 0, 1)
	if self.interactive and old ~= self.value and self.onValueChanged then
		self.onValueChanged(self.value)
	end
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

--------------------------------------------------
-- Thumb Helpers
--------------------------------------------------

--- 获取滑块的实际半径
function ProgressBar:_getThumbRadius()
	if self.thumb_radius then
		return self.thumb_radius
	end
	local x, y, w, h, r = self.transform:getGlobalBounds()
	local thin = self.orientation == "horizontal" and h or w
	return math.max(MIN_THUMB_RADIUS, thin / 2 * DEFAULT_THUMB_RADIUS_RATIO)
end

--- 获取滑块中心点（全局坐标）
function ProgressBar:_getThumbCenter()
	local x, y, w, h, r = self.transform:getGlobalBounds()
	local cx, cy
	if self.orientation == "horizontal" then
		cx = x + w * self.value
		cy = y + h / 2
	else
		cx = x + w / 2
		cy = y + h * (1 - self.value)
	end
	return cx, cy
end

--- 检测屏幕坐标是否在滑块范围内
function ProgressBar:_hitThumb(screen_x, screen_y)
	local cx, cy = self:_getThumbCenter()
	local tr = self:_getThumbRadius()
	local dx = screen_x - cx
	local dy = screen_y - cy
	return dx * dx + dy * dy <= tr * tr
end

--- 根据屏幕坐标更新 value
function ProgressBar:_updateValueFromScreen(screen_x, screen_y)
	local lx, ly = self.transform:screenToLocal(screen_x, screen_y)
	local w, h = self.transform:getSize()

	local new_val
	if self.orientation == "horizontal" then
		new_val = lx / w
	else
		new_val = 1 - ly / h
	end
	self:setValue(new_val)
end

--------------------------------------------------
-- Mouse Events (interactive mode)
--------------------------------------------------

function ProgressBar:onMousePressed(x, y, button)
	if not self.interactive or button ~= 1 then
		return
	end
	if not self:regionDetection(x, y) then
		return
	end
	self._dragging = true
	self:_updateValueFromScreen(x, y)
	return true
end

function ProgressBar:onMouseMoved(x, y, dx, dy)
	if not self.interactive then
		return
	end

	-- 拖拽时不改变光标
	if not self._dragging then
		local is_over = self:regionDetection(x, y)
		if is_over and self:_hitThumb(x, y) then
			if not self._hover_thumb then
				self._hover_thumb = true
				love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
			end
		else
			if self._hover_thumb then
				self._hover_thumb = false
				love.mouse.setCursor()
			end
		end
	else
		self:_updateValueFromScreen(x, y)
		return true
	end
end

function ProgressBar:onMouseReleased(x, y, button)
	if not self.interactive or button ~= 1 then
		return
	end
	self._dragging = false
	-- 释放后根据鼠标是否在滑块上来更新光标
	if not self:_hitThumb(x, y) and self._hover_thumb then
		self._hover_thumb = false
		love.mouse.setCursor()
	end
end

function ProgressBar:onHovered(hovered, x, y, dx, dy)
	if not hovered and self._hover_thumb then
		self._hover_thumb = false
		love.mouse.setCursor()
	end
end

--------------------------------------------------
-- Draw
--------------------------------------------------

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

	-- 交互模式：滑块
	if self.interactive then
		local cx, cy = self:_getThumbCenter()
		local tr = self:_getThumbRadius()

		-- 描边
		if self.thumb_outline_color and self.thumb_outline_width > 0 then
			love.graphics.setLineWidth(self.thumb_outline_width)
			love.graphics.setColor(unpack(self.thumb_outline_color))
			love.graphics.circle("line", cx, cy, tr)
			love.graphics.setLineWidth(1)
		end

		-- 填充
		love.graphics.setColor(unpack(self.thumb_color))
		love.graphics.circle("fill", cx, cy, tr)
	end

	love.graphics.pop()
end

return ProgressBar
