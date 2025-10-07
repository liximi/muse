local Widget = require "ui.widgets.widget"
local Text = require "ui.widgets.text"
local Utils = require "ui.utils"
local Fonts = require "ui.fonts"
local AddSizeComponent = require "ui.components".AddSize
local BTN_STATES = Utils.BTN_STATES

local Button = Class(Widget, function (self)
	Widget.new(self, "Button")

	AddSizeComponent(self)

	self.cur_state = BTN_STATES.normal
	self.state_defs = {
		normal = {
			text = "Button",
			text_color = Utils.RGB(0, 0, 0),
			bg_color = Utils.RGB(92, 200, 245),
			outline_color = Utils.RGB(70, 135, 170),
		},
		pressed = {
			bg_color = Utils.RGB(70, 135, 170),
			outline_color = Utils.RGB(20, 80, 100),
			offset = {0, 1},
		},
		hover = {
			text_color = Utils.RGB(255, 255, 255),
			bg_color = Utils.RGB(100, 210, 250),
			outline_color = Utils.RGB(75, 140, 180),
			offset = {0, 2},
			scale = {1.05, 1.05},
		}
	}

	self.text = self:AddChild(Text("Button"))
	self.text:SetTextColor(self.state_defs.normal.text_color)
	self.text:SetHAlign("center")

	self:SetSize(120, 50)
end)


--- 设置按钮在某个状态下的样子
---@param state "normal"|"pressed"|"disabled"|"seleted"|"hover"|"seleted_hover"
---@param def {text:string, text_color:table, bg_color:table, outline_color:table, offset:table, scale:table} 配置信息表 
function Button:SetStateDef(state, def)
	if not BTN_STATES[state] then
		print("Button:SetStateDef|Invalid state:", state)
		return
	end
	self.state_defs[state] = def
	self:SetState(self.cur_state)
end


function Button:OnSetSize(w, h)
	self.text:SetMaxWidth(w)
	local textw, texth = self.text:GetSize()
	self.text:SetPosition(0, (h-texth)*0.5)
end

function Button:SetState(new_state)
	if not BTN_STATES[new_state] then
		print("Button:SetStateDef|Invalid state:", new_state)
		return
	end
	local old_state = self.cur_state
	self.cur_state = new_state

	local new_text = self.state_defs[new_state] and self.state_defs[new_state].text
	if new_text then
		self.text:SetText(new_text)
	end
	local new_text_color = self.state_defs[new_state] and self.state_defs[new_state].text_color
	if new_text_color then
		self.text:SetTextColor(new_text_color)
	end

	local old_offset = self.state_defs[old_state] and self.state_defs[old_state].offset or {0, 0}
	local offset = self.state_defs[new_state] and self.state_defs[new_state].offset or {0, 0}
	local total_offset = {offset[1] - old_offset[1], offset[2] - old_offset[2]}
	local x, y = self:GetPosition()
	self:SetPosition(x+total_offset[1], y+total_offset[2])

	local scale = self.state_defs[new_state] and self.state_defs[new_state].scale or {1, 1}
	self:SetScale(scale[1], scale[2])
end

function Button:OnFocus()
	if self.cur_state == BTN_STATES.normal then
		self:SetState(BTN_STATES.hover)
	elseif self.cur_state == BTN_STATES.seleted then
		self:SetState(BTN_STATES.seleted_hover)
	end
end

function Button:OnRemoveFocus()
	if self.cur_state == BTN_STATES.seleted_hover then
		self:SetState(BTN_STATES.seleted)
	elseif self.cur_state == BTN_STATES.hover then
		self:SetState(BTN_STATES.normal)
	end
end


function Button:OnMousePressed(x, y, button)
	if button == 1 and self:IsInUIScope(x, y) then
		if self.cur_state == BTN_STATES.normal or self.cur_state == BTN_STATES.hover then
			self:SetState(BTN_STATES.pressed)
		end
	end
end

function Button:OnMouseReleased(x, y, button)
	if button == 1 and self.cur_state == BTN_STATES.pressed then
		self:SetState(BTN_STATES.normal)
		if self.OnClick then
			self:OnClick()
		end
	end
end

function Button:OnMouseMoved(x, y, dx, dy)
	if self:IsInUIScope(x, y) then
		if not self:IsFocus() then
			self:SetFocus()
		end
	elseif self:IsFocus() then
		self:RemoveFocus()
	end
end



function Button:OnDraw()
	local cur_state_def = self.state_defs[self.cur_state]
	local x, y = self:GetGlobalPosition()
	local w, h = self:GetGlobalScaledSize()
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
		love.graphics.printf(string.format("State: %s", self.cur_state), Fonts:GetFont("default", 16), x, y + h, self.width)
	end
end


return Button