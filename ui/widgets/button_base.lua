local Widget = require "ui.widgets.widget"
local Utils = require "ui.utils"
local BTN_STATES = Utils.BTN_STATES


--按钮类的基类，请不要直接使用该类，可使用widget.button.lua中的Button类
--[[datas: 此处不包括当前Widget继承的基类所支持的字段
	on_click = function
	on_pressed = function
]]
local ButtonBase = Class(Widget, function (self, name, datas, theme)
	Widget.new(self, name or "ButtonBase", datas, theme)

	self.cur_state = BTN_STATES.NORMAL
	self.onClick = datas and datas.on_click
	self.onPressed = datas and datas.on_pressed
end)


function ButtonBase:setState(new_state)
	if not BTN_STATES[string.upper(new_state)] then
		print(self.__name .. ":setState|Invalid state:", new_state)
		return
	end
	local old_state = self.cur_state
	self.cur_state = new_state
	if self.onSetState then
		self:onSetState(old_state, new_state)
	end
end

function ButtonBase:onFocus()
	if self.cur_state == BTN_STATES.NORMAL then
		self:setState(BTN_STATES.HOVER)
	elseif self.cur_state == BTN_STATES.SELECTED then
		self:setState(BTN_STATES.SELECTED_HOVER)
	end
end

function ButtonBase:onRemoveFocus()
	if self.cur_state == BTN_STATES.SELECTED_HOVER then
		self:setState(BTN_STATES.SELECTED)
	elseif self.cur_state == BTN_STATES.HOVER then
		self:setState(BTN_STATES.NORMAL)
	end
end


function ButtonBase:onMousePressed(x, y, button)
	if button == 1 and self:regionDetection(x, y) and (not self.fineRegionDetection or self:fineRegionDetection()) then
		if self.cur_state == BTN_STATES.NORMAL or self.cur_state == BTN_STATES.HOVER then
			self:setState(BTN_STATES.PRESSED)
			if self.onPressed then
				self:onPressed(x, y)
			end
		end
		return true
	end
end

function ButtonBase:onMouseReleased(x, y, button)
	if button == 1 and self.cur_state == BTN_STATES.PRESSED then
		if self:regionDetection(x, y) and (not self.fineRegionDetection or self:fineRegionDetection()) then
			self:setState(BTN_STATES.HOVER)
		else
			self:setState(BTN_STATES.NORMAL)
		end
		if self.onClick then
			self:onClick()
		end
	end
end

function ButtonBase:onMouseMoved(x, y, dx, dy)
	if self:regionDetection(x, y) then
		if not self:isFocus() then
			self:setFocus()
			return true
		end
	elseif self:isFocus() then
		self:removeFocus()
	end
end

function ButtonBase:setSelected(selected)
	local hovered = self.cur_state == Utils.BTN_STATES.HOVER or self.cur_state == Utils.BTN_STATES.SELECTED_HOVER
	local is_selected = self.cur_state == Utils.BTN_STATES.SELECTED or self.cur_state == Utils.BTN_STATES.SELECTED_HOVER
	if selected and not is_selected then
		self:setState(hovered and Utils.BTN_STATES.SELECTED_HOVER or Utils.BTN_STATES.SELECTED)
		if self.onSelected then
			self:onSelected()
		end
		return
	end
	if not selected and is_selected then
		self:setState(hovered and Utils.BTN_STATES.HOVER or Utils.BTN_STATES.NORMAL)
		if self.onUnselected then
			self:onUnselected()
		end
	end
end

function ButtonBase:onEnabled()
	self:setState(Utils.BTN_STATES.NORMAL)
end

function ButtonBase:onDisabled()
	self:setState(Utils.BTN_STATES.DISABLED)
end


return ButtonBase