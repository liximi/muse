local Widget = require "ui.widgets.widget"
local Text = require "ui.widgets.text"
local Panel = require "ui.widgets.panel"
local Fonts = require "ui.fonts"
local utf8 = require "utf8"
local Utils = require "ui.utils"
local AddSizeComponent = require "ui.components".AddSize
local AddHoverState = require "ui.components".AddHoverState


local TextInput = Class(Widget, function(self, w, h, hint, enable_background)
	Widget.new(self, "TextInput")

	self.outline_color = Utils.UI_COLORS.SECONDARY_TEXT
	self.hovered_outline_color = Utils.UI_COLORS.ACCENT
	if enable_background then
		self.bg = self:AddChild(Panel(w or 200, h or 75))
		self.bg:SetBGColor(Utils.UI_COLORS.TEXT)
		self.bg:SetOutlineColor(self.outline_color)
	end

	self.text = self:AddChild(Text())
	self.text:SetTextColor(Utils.UI_COLORS.PRIMARY_TEXT)
	if hint then
		self.hint = self:AddChild(Text(hint))
		self.hint:SetTextColor(Utils.UI_COLORS.SECONDARY_TEXT)
	end

	AddSizeComponent(self)
	self:SetSize(w or 200, h or 75)

	AddHoverState(self)
end)


function TextInput:SetOutlineColor(color)
	self.outline_color = color
end

function TextInput:SetHoveredOutlineColor(color)
	self.hovered_outline_color = color
end


function TextInput:OnSetSize(w, h)
	if self.bg then
		self.bg:SetSize(w, h)
	end
	self.text:SetMaxWidth(w)
	if self.hint then
		self.hint:SetMaxWidth(w)
	end
end




function TextInput:OnMouseReleased(x, y, button)
	if button ~= 1 then
		return
	end
	local is_in_scope = self:IsInUIScope(x, y)
	local is_focus = self:IsFocus()
	if is_in_scope and not is_focus then
		self:SetFocus()
		return
	end
	if is_focus then
		self:RemoveFocus()
		self:OnHovered(is_in_scope)
	end
end

function TextInput:OnHovered(hovered, x, y, dx, dy)
	if not self.bg or self:IsFocus() then
		return
	end
	if hovered then
		self.bg:SetOutlineColor(self.hovered_outline_color)
	else
		self.bg:SetOutlineColor(self.outline_color)
	end
end

function TextInput:RefreashHint()
	if not self.hint then
		return
	end
	local text = self.text:GetText()
	if not text or text == "" then
		self.hint:Show()
	else
		self.hint:Hide()
	end
end

function TextInput:OnKeyPressed(key, isrepeat)
	if key == "backspace" then
		local text = self.text:GetText()
        local byteoffset = utf8.offset(text, -1)
        if byteoffset then
            text = string.sub(text, 1, byteoffset - 1)
			self.text:SetText(text)
			self:RefreashHint()
        end
	elseif key == "kpenter" or key == "return" then
		self:OnTextInput("\n")
	end
end

function TextInput:OnTextInput(text)
	if not self:IsFocus() then
		return
	end
	local old_text = self.text:GetText()
	self.text:SetText(old_text..text)
	self:RefreashHint()
end


return TextInput