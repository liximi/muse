local Widget = require "ui.widgets.widget"
local Utils = require "ui.utils"
local Panel = require "ui.widgets.panel"
local Button = require "ui.widgets.button"


local function updateValueInteral(self, value, call_callback, update_block_pos)
	local old_val = self.value
	local new_val = Utils.clamp(value, 0, self.max_limit)
	self.value = new_val
	if old_val ~= new_val and call_callback and self.onValueUpdate then
		self.onValueUpdate(self.value, self.value / self.max_limit)
	end
	if update_block_pos then
		local new_x = (self.transform.w - self.block.transform.w) * new_val / self.max_limit
		self.block:setPosition(new_x)
	end
end


--[[datas: 此处不包括当前Widget继承的基类所支持的字段
	max_limit = number
	block_length_percent = number
	sensitivity = number
	on_value_update = function(value, percent)
]]
local SliderBar = Class(Widget, function (self, datas, theme)
	Widget.new(self, "SliderBar Vertical", datas, theme)

	self.drag = false--鼠标按在滑块内部时，会将drag改为true
	self.pressed = false--鼠标按在滑块外部时，会将pressed改为true
	self.pressed_timer = 0
	self.sensitivity = datas and datas.sensitivity or 0.8--鼠标按在滑块外部时，滑块自动移动的距离占滑块高度的比例
	self.block_length_percent = datas and datas.block_length_percent or 0.1--滑块高度占整个滑动条的高度的比例

	self.max_limit = datas and datas.max_limit or 1
	self.value = 0	--0 ~ max_limit

	self.onValueUpdate = datas and datas.on_value_update

	self.bg = self:addChild(Panel({
		anchors = {0, 0, 1, 1},
		padding = {0, 0, 0, 0},
		rounding_radius = self.transform.h / 2,
		bg_color = Utils.UI_COLORS.LINE,
		outline_width = 0
	}))

	local block_rounding_radius = (self.transform.h + 2)/2
	local block_style = Utils.newButtonStateStyle("", nil, nil,
		Utils.UI_COLORS.BTN_NORMAL, 1, Utils.UI_COLORS.LINE,
		{0, 0}, {1, 1}, block_rounding_radius)
	local block_hover_style = Utils.newButtonStateStyle(nil, nil, nil,
		Utils.UI_COLORS.BTN_HOVER, 1, Utils.UI_COLORS.LINE,
		{0, 0}, {1, 1}, block_rounding_radius)

	self.block = self:addChild(Button({
		anchors = {0, 0, 0, 1},
		padding = {0, nil, -1, -1},
		w = self.block_length_percent * self.transform.w,
		on_pressed = function(_self, x, y)
			self.drag = true
		end,
		on_click = function (_self)
			self.drag = false
		end,
		normal = block_style,
		hover = block_hover_style,
		pressed = block_hover_style,
	}))

	self:enableSizeChangedEvent(true)
end)


--- 供外部更新value的接口
function SliderBar:setValue(val)
	updateValueInteral(self, val, false, true)
end

--- 供外部更新value的接口
function SliderBar:setPercent(percent)
	updateValueInteral(self, self.max_limit * percent, false, true)
end

--- 设置最大值
function SliderBar:setMaxLimit(max)
	self.max_limit = math.max(0, max)
	updateValueInteral(self, self.value, true, true)
end

function SliderBar:setBlockLengthtPercent(percent)
	self.block_length_percent = Utils.clamp(percent, 0, 1)
	self.block.transform:setSize(self.block_length_percent * self.transform.w)
end

function SliderBar:setOnValueUpdateFn(callback_fn)
	self.onValueUpdate = callback_fn
end


---向上或向下移动滑块固定距离
---@param dir "left"|"right"
local function moveBlock(self, dir)
	local cur_x, cur_y = self.block:getPosition()
	local max_x = self.transform.w - self.block.transform.w
	local delta = self.block.transform.w * self.sensitivity
	local new_x = Utils.clamp(cur_x + (dir == "left" and -delta or delta), 0, max_x)
	if new_x ~= cur_x then
		self.block:setPosition(new_x)
		updateValueInteral(self, self.max_limit * new_x / max_x, true)
	end
end

function SliderBar:onMousePressed(x, y, button)
	if button ~= 1 then
		return
	end
	local is_in_scope = self:regionDetection(x, y)
	if is_in_scope then
		self.pressed = true
		self.pressed_timer = 0
		local lx, ly = self.transform:screenToLocal(x, y)
		if lx <= self.block.transform.x then
			moveBlock(self, "left")
		elseif lx >= self.block.transform.x + self.block.transform.w then
			moveBlock(self, "right")
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
	if self.drag then
		local cur_x, cur_y = self.block:getPosition()
		local sx, sy = self:getGlobalScale()
		local max_x = self.transform.w - self.block.transform.w
		local new_x = Utils.clamp(cur_x + dx / sx, 0, max_x)
		self.block:setPosition(new_x)
		updateValueInteral(self, self.max_limit * new_x / max_x, true)
	end
end


function SliderBar:onUpdate(dt)
	if self.pressed then
		self.pressed_timer = self.pressed_timer + dt
		if self.pressed_timer > 0.25 then
			local x, y = love.mouse:getPosition()
			local lx, ly = self.transform:screenToLocal(x, y)
			if lx <= self.block.transform.x then
				moveBlock(self, "left")
			elseif lx >= self.block.transform.x + self.block.transform.w then
				moveBlock(self, "right")
			end
			self.pressed_timer = 0
		end
	end
end


function SliderBar:onSizeChanged(w, h)
	self.block.transform:setSize(self.block_length_percent * w)
	updateValueInteral(self, self.value, false, true)
end


return SliderBar