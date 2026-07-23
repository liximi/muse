local Widget = require "ui.widgets.widget"
local ButtonBase = require "ui.widgets.button_base"
local Utils = require "ui.utils"
local Class = require "dependencies.classic"
local BTN_STATES = Utils.BTN_STATES

-- 伪常量
local TOGGLE_WIDTH_RATIO = 1.8   -- 滑动开关轨道宽度与 box_size 的比例
local LABEL_GAP = 6              -- checkbox 与标签文本之间的间距（像素）
local KNOB_INSET = 2             -- 滑动开关滑块与轨道边缘的缩进（像素）
local CHECK_LINE_WIDTH = 2       -- 对勾绘制线宽
local CHECK_PAD_RATIO = 0.3      -- 对勾相对 box 的边距比例
local CHECK_MID_X_RATIO = 0.15   -- 对勾中点水平偏移比例
local CHECK_MID_Y_RATIO = 0.05   -- 对勾中点垂直偏移比例

-- 复选框组件，支持方框+对勾或滑动开关两种样式
--[[datas: 此处不包括基类所支持的字段
	checked = boolean  -- 初始选中状态
	style = "checkbox" | "toggle"  -- 样式，默认 "checkbox"
	box_size = number  -- 复选框尺寸，默认从主题读取
	box_color = {r, g, b, a}
	check_color = {r, g, b, a}
	outline_width = number
	outline_color = {r, g, b, a}
	rounding_radius = number
	on_checked = function(checked)  -- 选中状态改变时的回调
	label = string | table  -- 可选标签文本（coloredtext）
	label_color = {r, g, b, a}
	label_font_size = number
]]
local Checkbox = Class(ButtonBase, function(self, datas, theme, widget_name)
	ButtonBase.new(self, widget_name or "Checkbox", datas, theme)

	self.style = Utils.validateEnum(
		datas and datas.style, Utils.CHECKBOX_STYLE, Utils.CHECKBOX_STYLE.CHECKBOX, "Checkbox.style")
	self.box_size = datas and datas.box_size or self.theme.checkbox.box_size
	self.box_color = datas and datas.box_color or self.theme.checkbox.box_color
	self.check_color = datas and datas.check_color or self.theme.checkbox.check_color
	self.outline_width = datas and datas.outline_width or self.theme.checkbox.outline_width
	self.outline_color = datas and datas.outline_color or self.theme.checkbox.outline_color
	self.rounding_radius = datas and datas.rounding_radius or self.theme.checkbox.rounding_radius

	-- 用独立字段追踪逻辑选中状态（cur_state 在 PRESSED 时会丢失）
	self._checked = datas and datas.checked or false
	self.onChecked = datas and datas.on_checked

	-- 初始视觉状态
	if self._checked then
		ButtonBase.setSelected(self, true)
	end

	-- 可选标签
	if datas and datas.label then
		local Text = require "ui.widgets.text"
		-- toggle 的轨道比 checkbox 宽（1.8x），label 需要相应偏移
		local vis_w = self.style == "toggle" and (self.box_size * TOGGLE_WIDTH_RATIO) or self.box_size
		self.label = self:addChild(Text({
			text = datas.label,
			text_color = datas.label_color or self.theme.checkbox.label_color,
			font_size = datas.label_font_size,
			anchor = {0, 0, 0, 1},
			pivot = {0, 0.5},
			padding = {vis_w + LABEL_GAP, 0, 0, 0}
		}))
		self.label.raycast_target = false -- 标签文字不阻断射线，让复选框处理点击
	end
end)

--- 报告最小尺寸（容器布局需要）
function Checkbox:getMinimumSize()
	local w, h = self.transform:getSize()
	return w, h
end

--- 是否处于选中状态（逻辑状态，不依赖视觉 cur_state）
function Checkbox:isChecked()
	return self._checked
end

--- 编程式设置选中状态
---@param checked boolean
function Checkbox:setChecked(checked)
	if checked ~= self._checked then
		self:setSelected(checked)
	end
end

--- 切换选中状态
function Checkbox:toggle()
	self:setChecked(not self._checked)
end

--- 将点击检测限定在视觉范围内（box + label），而非整个 widget 宽度
function Checkbox:regionDetection(px, py)
	if not Widget.regionDetection(self, px, py) then
		return false
	end
	local lx = self.transform:screenToLocal(px, py)
	local eff_w = self.style == "toggle" and (self.box_size * TOGGLE_WIDTH_RATIO) or self.box_size
	if self.label then
		eff_w = eff_w + LABEL_GAP + self.label:getDimensions()
	end
	return lx >= 0 and lx <= eff_w
end

-- 覆写：允许从 SELECTED/SELECTED_HOVER 状态按下（普通按钮只允许 NORMAL/HOVER）
function Checkbox:onMousePressed(x, y, button)
	if button == 1 and self:regionDetection(x, y) and (not self.fineRegionDetection or self:fineRegionDetection()) then
		if self.cur_state ~= BTN_STATES.PRESSED and self.cur_state ~= BTN_STATES.DISABLED then
			self:setState(BTN_STATES.PRESSED)
			if self.onPressed then
				self:onPressed(x, y)
			end
		end
		return true
	end
end

-- 覆写：释放时切换选中状态
function Checkbox:onMouseReleased(x, y, button)
	if button == 1 and self.cur_state == BTN_STATES.PRESSED then
		local inside = self:regionDetection(x, y) and (not self.fineRegionDetection or self:fineRegionDetection())
		self:toggle()
		if inside then
			self:setState(self._checked and BTN_STATES.SELECTED_HOVER or BTN_STATES.HOVER)
		else
			self:setState(self._checked and BTN_STATES.SELECTED or BTN_STATES.NORMAL)
		end
		if self.onClick then
			self:onClick()
		end
	end
end

-- 覆写：同步 _checked 并触发 onChecked 回调
function Checkbox:setSelected(selected)
	local old = self._checked
	self._checked = selected
	-- 从 PRESSED 恢复时需要先回到基础状态
	if self.cur_state == BTN_STATES.PRESSED then
		self.cur_state = old and BTN_STATES.SELECTED_HOVER or BTN_STATES.HOVER
	end
	ButtonBase.setSelected(self, selected)
	if old ~= selected and self.onChecked then
		self:onChecked(selected)
	end
end

function Checkbox:onDraw()
	local x, y, w, h, r = self.transform:getGlobalBounds()

	love.graphics.push()
	if r ~= 0 and r ~= Utils.TWO_PI then
		local px, py = self.transform:getGlobalPosition()
		love.graphics.translate(px, py)
		love.graphics.rotate(r)
		love.graphics.translate(-px, -py)
	end

	local is_checked = self._checked
	local box_cx = x + self.box_size / 2
	local box_cy = y + h / 2
	local half = self.box_size / 2

	if self.style == "toggle" then
		-- 滑动开关样式
		local track_w = self.box_size * TOGGLE_WIDTH_RATIO
		local track_h = self.box_size
		local track_x = x
		local track_y = box_cy - track_h / 2
		local knob_r = track_h / 2 - KNOB_INSET

		-- 轨道背景
		local track_color = is_checked and self.check_color or self.box_color
		love.graphics.setColor(unpack(track_color))
		love.graphics.rectangle("fill", track_x, track_y, track_w, track_h, track_h / 2)

		-- 滑块
		local knob_x = is_checked and (track_x + track_w - knob_r - KNOB_INSET) or (track_x + knob_r + KNOB_INSET)
		local knob_y = track_y + track_h / 2
		love.graphics.setColor(unpack(self.theme.checkbox.knob_color))
		love.graphics.circle("fill", knob_x, knob_y, knob_r)
	else
		-- 默认方框样式
		local box_x = box_cx - half
		local box_y = box_cy - half

		-- 填充背景
		love.graphics.setColor(unpack(self.box_color))
		love.graphics.rectangle("fill", box_x, box_y, self.box_size, self.box_size, self.rounding_radius)

		-- 边框
		if self.outline_width > 0 then
			love.graphics.setLineWidth(self.outline_width)
			love.graphics.setColor(unpack(self.outline_color))
			love.graphics.rectangle("line", box_x, box_y, self.box_size, self.box_size, self.rounding_radius)
			love.graphics.setLineWidth(1)
		end

		-- 对勾
		if is_checked then
			love.graphics.setLineWidth(CHECK_LINE_WIDTH)
			love.graphics.setColor(unpack(self.check_color))
			local pad = half * CHECK_PAD_RATIO
			local mid_x = box_cx - half * CHECK_MID_X_RATIO
			local mid_y = box_cy + half * CHECK_MID_Y_RATIO
			love.graphics.line(mid_x - half * 0.5, mid_y - half * 0.1, mid_x, mid_y + half * 0.45, mid_x + half * 0.8,
				mid_y - half * 0.45)
			love.graphics.setLineWidth(1)
		end
	end

	love.graphics.pop()
end

return Checkbox
