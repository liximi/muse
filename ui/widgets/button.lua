local Widget = require "ui.widgets.widget"
local Text = require "ui.widgets.text"
local Utils = require "ui.utils"
local Fonts = require "ui.fonts"
local AddSizeComponent = require "ui.components".AddSize
local BTN_STATES = Utils.BTN_STATES

local Button = Class(Widget, function (self, text)
	Widget.new(self, "Button")

	AddSizeComponent(self)

	self.cur_state = BTN_STATES.normal
	self.state_defs = {
		normal = {
			text = text or "Button",
			text_color = Utils.UI_COLORS.PRIMARY_TEXT,
			bg_color = Utils.UI_COLORS.ACCENT,
			outline_color = Utils.UI_COLORS.DARK_PRIMARY,
		},
		pressed = {
			outline_color = Utils.UI_COLORS.LIGHT_PRIMARY,
			offset = {0, 1.5},
			scale = {1.01, 1.01},
		},
		hover = {
			offset = {0, 1},
			scale = {1.01, 1.01},
		}
	}

	self.text = self:addChild(Text(text or "Button"))
	self.text:setTextColor(self.state_defs.normal.text_color)
	self.text:setHAlign("center")

	self.transform:setSize(120, 50)
end)


--- 设置按钮在某个状态下的样子
---@param state "normal"|"pressed"|"disabled"|"seleted"|"hover"|"seleted_hover"
---@param def {text:string, text_color:table, bg_color:table, outline_color:table, offset:table, scale:table} 配置信息表 
function Button:setStateDef(state, def)
	if not BTN_STATES[state] then
		print("Button:setStateDef|Invalid state:", state)
		return
	end
	self.state_defs[state] = def
	self:setState(self.cur_state)
end


function Button:setState(new_state)
	if not BTN_STATES[new_state] then
		print("Button:setStateDef|Invalid state:", new_state)
		return
	end
	local old_state = self.cur_state
	self.cur_state = new_state

	local new_text = self.state_defs[new_state] and self.state_defs[new_state].text
	if new_text then
		self.text:setText(new_text)
	end
	local new_text_color = self.state_defs[new_state] and self.state_defs[new_state].text_color
	if new_text_color then
		self.text:setTextColor(new_text_color)
	end

	local old_offset = self.state_defs[old_state] and self.state_defs[old_state].offset or {0, 0}
	local offset = self.state_defs[new_state] and self.state_defs[new_state].offset or {0, 0}
	local total_offset = {offset[1] - old_offset[1], offset[2] - old_offset[2]}
	local x, y = self:getPosition()
	self:setPosition(x+total_offset[1], y+total_offset[2])

	local scale = self.state_defs[new_state] and self.state_defs[new_state].scale or {1, 1}
	self.transform:setScale(scale[1], scale[2])
end

function Button:onFocus()
	if self.cur_state == BTN_STATES.normal then
		self:setState(BTN_STATES.hover)
	elseif self.cur_state == BTN_STATES.seleted then
		self:setState(BTN_STATES.seleted_hover)
	end
end

function Button:onRemoveFocus()
	if self.cur_state == BTN_STATES.seleted_hover then
		self:setState(BTN_STATES.seleted)
	elseif self.cur_state == BTN_STATES.hover then
		self:setState(BTN_STATES.normal)
	end
end


function Button:onMousePressed(x, y, button)
	if button == 1 and self:isInUIScope(x, y) then
		if self.cur_state == BTN_STATES.normal or self.cur_state == BTN_STATES.hover then
			self:setState(BTN_STATES.pressed)
		end
	end
end

function Button:onMouseReleased(x, y, button)
	if button == 1 and self.cur_state == BTN_STATES.pressed then
		self:setState(BTN_STATES.normal)
		if self.onClick then
			self:onClick()
		end
	end
end

function Button:onMouseMoved(x, y, dx, dy)
	if self:isInUIScope(x, y) then
		if not self:isFocus() then
			self:setFocus()
		end
	elseif self:isFocus() then
		self:removeFocus()
	end
end



function Button:onDraw()
	local cur_state_def = self.state_defs[self.cur_state]
	local x, y = self:getGlobalPosition()
	local w, h = self:getGlobalScaledSize()
	local bg_color = cur_state_def.bg_color or self.state_defs.normal.bg_color
	local outline_color = cur_state_def.outline_color or self.state_defs.normal.outline_color

	if bg_color then
		love.graphics.setColor(unpack(bg_color))
		love.graphics.rectangle("fill", x, y, w, h)
	end
	if outline_color then
		love.graphics.setColor(unpack(outline_color))
		love.graphics.rectangle("line", x, y, w, h)
	end

	if self._debug then
		love.graphics.setColor(unpack(Utils.debug_color1))
		love.graphics.rectangle("line", x-1, y-1, w + 2, h + 2)
		love.graphics.printf(string.format("State: %s", self.cur_state), Fonts:getFont("default", 16), x, y + h, self.width)
	end
end


return Button