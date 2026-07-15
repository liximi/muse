local Widget = require "ui.widgets.widget"
local Utils = require "ui.utils"
local Panel = require "ui.widgets.panel"
local Button = require "ui.widgets.button"
local Tween = require "dependencies.tween"
local Class = require "dependencies.classic"

local AXIS = {
	vertical = {
		pos = "y",
		size = "h",
		delta = "dy",
		scale = "sy",
		neg_dir = "up",
		pos_dir = "down",
		alter_pos = "x",
		alter_size = "w"
	},
	horizontal = {
		pos = "x",
		size = "w",
		delta = "dx",
		scale = "sx",
		neg_dir = "left",
		pos_dir = "right",
		alter_pos = "y",
		alter_size = "h"
	}
}

-- 伪常量
local BLOCK_OVERHANG = 1       -- 滑块超出轨道的像素数（单侧）
local BLOCK_SIZE_ADJUST = 2    -- 滑块总尺寸调整（双侧超出之和）
local MIN_ROUNDING = 1         -- 滑块圆角最小值（确保半圆两端不小于 1px）
local LONG_PRESS_DELAY = 0.25  -- 长按重复触发间隔（秒）
local SNAP_TWEEN_DURATION = 0.15 -- 吸附缓动时长（秒）

local function updateValueInternal(self, value, call_callback, update_block_pos)
	local a = self._axis
	local old_val = self.value
	local new_val = Utils.clamp(value, 0, self.max_limit)
	-- 整数步长模式：snap 到最近步长倍数
	if self.step > 0 then
		new_val = math.floor(new_val / self.step + 0.5) * self.step
		new_val = Utils.clamp(new_val, 0, self.max_limit)
	end
	self.value = new_val
	if old_val ~= new_val and call_callback and self.onValueUpdate then
		self.onValueUpdate(self.value, self.value / self.max_limit)
	end
	if update_block_pos then
		local track_len = self.transform[a.size] - self.block.transform[a.size]
		local new_pos = track_len * new_val / self.max_limit
		self.block:setPosition(a.pos == "x" and new_pos or nil, a.pos == "y" and new_pos or nil)
	end
end

--[[datas: 此处不包括当前Widget继承的基类所支持的字段
	orientation = "vertical" | "horizontal"
	max_limit = number
	block_length_percent = number
	block_min_len = number       滑块最小长度（像素，默认 0 不限制）
	step = number                步长（默认 0 连续模式，>0 时值会 snap 到最近的步长倍数）
	sensitivity = number
	on_value_update = function(value, percent)
]]
local SliderBar = Class(Widget, function(self, datas, theme)
	datas = datas or {}
	local orientation = datas.orientation == "horizontal" and "horizontal" or "vertical"
	self._axis = AXIS[orientation]
	local a = self._axis

	Widget.new(self, orientation == "vertical" and "SliderBarV" or "SliderBarH", datas, theme)
	self.raycast_target = true

	self.drag = false
	self.pressed = false
	self.pressed_timer = 0
	self.sensitivity = datas.sensitivity or self.theme.sliderbar.sensitivity
	self.block_length_percent = datas.block_length_percent or self.theme.sliderbar.block_length_percent
	self.block_min_len = datas.block_min_len or 0

	self.max_limit = datas.max_limit or 1
	self.step = datas.step or 0
	self.value = 0

	-- 步长吸附相关状态
	self._snap_tween = nil        -- 缓动动画对象
	self._snap_target = 0         -- 当前吸附目标值
	self._drag_raw_position = nil -- 拖动时的原始位置（未经吸附）

	self.onValueUpdate = datas.on_value_update

	-- 背景 track
	local track_rounding = orientation == "vertical" and self.transform.w / 2 or self.transform.h / 2
	self.bg = self:addChild(Panel({
		anchor = {0, 0, 1, 1},
		padding = {0, 0, 0, 0},
		rounding_radius = track_rounding,
		bg_color = self.theme.sliderbar.track_color,
		outline_width = 0
	}))

	-- 滑块 block（初始圆角由 _updateBlockRounding 在 enableSizeChangedEvent 后的首帧更新）
	local block_style = Utils.newButtonStateStyle("", nil, nil, self.theme.sliderbar.block_color, 1,
		self.theme.sliderbar.outline_color, {0, 0}, {1, 1}, 0)
	local block_hover_style = Utils.newButtonStateStyle(nil, nil, nil, self.theme.sliderbar.block_hover_color, 1,
		self.theme.sliderbar.outline_color, {0, 0}, {1, 1}, 0)

	-- 锚点和 padding 根据方向不同
	local block_anchor = orientation == "vertical" and {0, 0, 1, 0} -- 水平方向拉伸
	or {0, 0, 0, 1} -- 垂直方向拉伸
	local block_padding = orientation == "vertical" and {-BLOCK_OVERHANG, -BLOCK_OVERHANG, 0, nil} or {0, nil, -BLOCK_OVERHANG, -BLOCK_OVERHANG}

	self.block = self:addChild(Button({
		anchor = block_anchor,
		padding = block_padding,
		on_pressed = function(_self, x, y)
			self.drag = true
			if self.step > 0 then
				self._drag_raw_position = self.block.transform[a.pos]
				self._snap_target = self.value
				self._snap_tween = nil
			end
		end,
		on_click = function(_self)
			self.drag = false
		end,
		normal = block_style,
		hover = block_hover_style,
		pressed = block_hover_style,
	}))

	-- 显式设置滑块初始尺寸（不再依赖 onSizeChanged 做初始化）
	local block_len = self.block_length_percent * self.transform[a.size]
	if self.block_min_len > 0 then
		block_len = math.max(self.block_min_len, block_len)
	end
	self.block.transform:setSize(a.pos == "x" and block_len or nil,
		a.pos == "y" and block_len or nil)

	self:enableSizeChangedEvent(true)
	self:_updateBlockRounding()
end)

function SliderBar:setValue(val)
	updateValueInternal(self, val, false, true)
end

function SliderBar:setPercent(percent)
	updateValueInternal(self, self.max_limit * percent, false, true)
end

function SliderBar:setMaxLimit(max)
	self.max_limit = math.max(0, max)
	updateValueInternal(self, self.value, true, true)
end

function SliderBar:setBlockLengthPercent(percent)
	local a = self._axis
	self.block_length_percent = Utils.clamp(percent, 0, 1)
	local block_len = self.block_length_percent * self.transform[a.size]
	if self.block_min_len and self.block_min_len > 0 then
		block_len = math.max(self.block_min_len, block_len)
	end
	self.block.transform:setSize(a.pos == "x" and block_len or nil,
		a.pos == "y" and block_len or nil)
	self:_updateBlockRounding()
end

function SliderBar:setOnValueUpdateFn(callback_fn)
	self.onValueUpdate = callback_fn
end

-- 带缓动动画的轨道/长按移动
local function animateBlockMove(self, dir)
	local a = self._axis
	local cur_pos = self.block.transform[a.pos]
	local track_len = self.transform[a.size] - self.block.transform[a.size]
	local delta = self.block.transform[a.size] * self.sensitivity
	local new_pos = Utils.clamp(cur_pos + (dir == a.neg_dir and -delta or delta), 0, track_len)
	if new_pos == cur_pos then
		return
	end
	-- 计算目标值（含步长吸附）
	local target_val = self.max_limit * new_pos / track_len
	if self.step > 0 then
		target_val = math.floor(target_val / self.step + 0.5) * self.step
		target_val = Utils.clamp(target_val, 0, self.max_limit)
		new_pos = track_len * target_val / self.max_limit
	end
	-- 启动缓动动画
	self._snap_tween = Tween.newFunctionalTween(SNAP_TWEEN_DURATION, {
		pos = {cur_pos, new_pos, function(val)
			self.block:setPosition(a.pos == "x" and val or nil, a.pos == "y" and val or nil)
		end}
	}, "outQuad")
	-- 值立即更新，位置由 tween 驱动
	updateValueInternal(self, target_val, true, false)
end

function SliderBar:onMousePressed(x, y, button)
	if button ~= 1 then
		return
	end
	local a = self._axis
	local is_in_scope = self:regionDetection(x, y)
	if is_in_scope then
		self.pressed = true
		self.pressed_timer = 0
		local local_pos = {self.transform:screenToLocal(x, y)}
		local lp = local_pos[a.pos == "x" and 1 or 2]
		if lp <= self.block.transform[a.pos] then
			animateBlockMove(self, a.neg_dir)
		elseif lp >= self.block.transform[a.pos] + self.block.transform[a.size] then
			animateBlockMove(self, a.pos_dir)
		end
		return true
	end
end

function SliderBar:onMouseReleased(x, y, button)
	if button ~= 1 then
		return
	end
	self.pressed = false
end

function SliderBar:onMouseMoved(x, y, dx, dy)
	if not self.drag then
		return
	end
	local a = self._axis
	local sx, sy = self:getGlobalScale()
	local gs_axis = a.pos == "x" and sx or sy
	local mouse_delta = a.pos == "x" and dx or dy
	local track_len = self.transform[a.size] - self.block.transform[a.size]

	if self.step > 0 then
		-- 步长模式：累计原始拖动位置，越过吸附边界时用缓动动画 snap
		self._drag_raw_position = Utils.clamp(
			self._drag_raw_position + mouse_delta / gs_axis, 0, track_len)
		local raw_val = self.max_limit * self._drag_raw_position / track_len
		local nearest = math.floor(raw_val / self.step + 0.5) * self.step
		nearest = Utils.clamp(nearest, 0, self.max_limit)
		if nearest ~= self._snap_target then
			self._snap_target = nearest
			local cur_block_pos = self.block.transform[a.pos]
			local target_pos = track_len * nearest / self.max_limit
			-- 复用 tween 对象：从当前视觉位置 start → 新目标，避免每帧重建导致停滞
			if self._snap_tween then
				self._snap_tween:setInitialValue("pos", cur_block_pos)
				self._snap_tween:setTargetValue("pos", target_pos)
				self._snap_tween:reset()
			else
				self._snap_tween = Tween.newFunctionalTween(SNAP_TWEEN_DURATION, {
					pos = {cur_block_pos, target_pos, function(val)
						self.block:setPosition(a.pos == "x" and val or nil, a.pos == "y" and val or nil)
					end}
				}, "outQuad")
			end
		end
		-- 值立即更新（回调取最终值），位置由 tween 驱动
		updateValueInternal(self, self._snap_target, true, false)
	else
		-- 连续模式（现有行为）
		local cur_pos = self.block.transform[a.pos]
		local new_pos = Utils.clamp(cur_pos + mouse_delta / gs_axis, 0, track_len)
		self.block:setPosition(a.pos == "x" and new_pos or nil, a.pos == "y" and new_pos or nil)
		updateValueInternal(self, self.max_limit * new_pos / track_len, true)
	end
end

function SliderBar:onUpdate(dt)
	-- 驱动步长吸附缓动动画
	if self._snap_tween then
		if self._snap_tween:update(dt) then
			self._snap_tween = nil
		end
	end

	if not self.pressed then
		return
	end
	local a = self._axis
	self.pressed_timer = self.pressed_timer + dt
	if self.pressed_timer > LONG_PRESS_DELAY then
		-- 长按与轨道点击统一使用缓动动画
		local mx, my = love.mouse:getPosition()
		local local_pos = {self.transform:screenToLocal(mx, my)}
		local lp = local_pos[a.pos == "x" and 1 or 2]
		if lp <= self.block.transform[a.pos] then
			animateBlockMove(self, a.neg_dir)
		elseif lp >= self.block.transform[a.pos] + self.block.transform[a.size] then
			animateBlockMove(self, a.pos_dir)
		end
		self.pressed_timer = 0
	end
end

function SliderBar:onSizeChanged(w, h)
	-- 尺寸变化后缓动目标坐标失效，取消动画
	self._snap_tween = nil
	local a = self._axis
	local size = a.pos == "x" and w or h
	local block_len = self.block_length_percent * size
	if self.block_min_len and self.block_min_len > 0 then
		block_len = math.max(self.block_min_len, block_len)
	end
	self.block.transform:setSize(a.pos == "x" and block_len or nil,
		a.pos == "y" and block_len or nil)
	self:_updateBlockRounding()
	updateValueInternal(self, self.value, false, true)
end

-- 更新 block 圆角为半圆两端（基于滑块薄边尺寸）
function SliderBar:_updateBlockRounding()
	local a = self._axis
	local thin_edge = self.transform[a.alter_size] -- 垂直滑块取宽度，水平滑块取高度
	local r = math.max(MIN_ROUNDING, (thin_edge + BLOCK_SIZE_ADJUST) / 2)
	self.block.state_styles.normal.rounding_radius = r
	self.block.state_styles.hover.rounding_radius = r
	self.block.state_styles.pressed.rounding_radius = r
end

return SliderBar
