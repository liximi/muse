local ButtonBase = require "ui.widgets.button_base"
local Text = require "ui.widgets.text"
local Image = require "ui.widgets.image"
local Utils = require "ui.utils"
local Fonts = require "ui.fonts"
local BTN_STATES = Utils.BTN_STATES


--[[datas: 此处不包括当前Widget继承的基类所支持的字段
	no_text = boolean
	normal = Utils.newImageButtonStateStyle
	hover = Utils.newImageButtonStateStyle
	pressed = Utils.newImageButtonStateStyle
	disabled = Utils.newImageButtonStateStyle
	selected = Utils.newImageButtonStateStyle
	selected_hover = Utils.newImageButtonStateStyle
]]
local ImageButton = Class(ButtonBase, function (self, datas, theme)
	datas = datas or {}
	if not datas.w then
		datas.w = datas.normal and datas.normal.texture and datas.normal.texture:getWidth()
	end
	if not datas.h then
		datas.h = datas.normal and datas.normal.texture and datas.normal.texture:getHeight()
	end
	ButtonBase.new(self, "ImageButton", datas, theme)

	self.state_styles = {
		normal = datas.normal,
		hover = datas.hover,
		pressed = datas.pressed,
		disabled = datas.disabled,
		selected = datas.selected,
		selected_hover = datas.selected_hover,
	}

	local img_datas = {
		texture = datas.normal and datas.normal.texture,
		tint = datas.normal and datas.normal.tint or (self.theme.imagebutton and self.theme.imagebutton.normal.tint),
		anchor = {0, 0, 1, 1},
		padding = {0, 0, 0, 0},
	}
	self.image = self:addChild(Image(img_datas, theme))

	if not datas.no_text then
		self.text = self:addChild(Text({
			pivot = {0.5, 0.5},
			anchor = {0, 0, 1, 1},
			padding = {2, 2, 2, 2},
			h_align = "center",
			v_align = "center",
			text = self.state_styles.normal and self.state_styles.normal.text or "Button",
			text_color = self.state_styles.normal and self.state_styles.normal.text_color or (self.theme.imagebutton and self.theme.imagebutton.normal.text_color),
			font_key = datas.font_key,
			font_size = self.state_styles.normal and self.state_styles.normal.font_size or (self.theme.imagebutton and self.theme.imagebutton.normal.font_size),
		}))
	end
end)


--- 设置按钮在某个状态下的样式
---@param state "normal"|"pressed"|"disabled"|"selected"|"hover"|"seleted_hover"
---@param style Utils.newImageButtonStateStyle 配置信息表 
function ImageButton:setStateStyle(state, style)
	if not BTN_STATES[string.upper(state)] then
		print("ImageButton:setStateStyle|Invalid state:", state)
		return
	end
	self.state_styles[state] = style
	self:setState(self.cur_state)
end


--- 获取按钮在某个状态下的样式，会自动合并自定义样式、normal状态样式和主题样式
--- state_styles里对应状态的数据 > state_styles里normal状态的数据 > 主题里对应状态的数据 > 主题里normal状态的数据
---@param state "normal"|"pressed"|"disabled"|"selected"|"hover"|"seleted_hover"
function ImageButton:getStateStyle(state)
	local style = {}
	local t1 = { self.state_styles, self.theme.imagebutton }
	local t2 = state == "normal" and { "normal" } or { state, "normal" }
	for _, t in ipairs(t1) do
		for _, s in ipairs(t2) do
			if t[s] then
				for k, v in pairs(t[s]) do
					if not style[k] then
						style[k] = v
					end
				end
			end
		end
	end
	return style
end


function ImageButton:onSetState(old_state, new_state)
	local old_style = self:getStateStyle(old_state)
	local new_style = self:getStateStyle(new_state)
	if self.text then
		local new_text = new_style.text
		if new_text then
			self.text:setText(new_text)
		end
		local new_text_color = new_style.text_color
		if new_text_color then
			self.text:setTextColor(new_text_color)
		end
		local new_font_szie = new_style.font_size
		if new_font_szie and self.text:getFontSize() ~= new_font_szie then
			self.text:setFontSize(new_font_szie)
		end
	end

	local old_offset = old_style.offset or {0, 0}
	local offset = new_style.offset or {0, 0}
	local total_offset = {offset[1] - old_offset[1], offset[2] - old_offset[2]}
	local x, y = self:getPosition()
	self:setPosition(x+total_offset[1], y+total_offset[2])

	local scale = new_style and new_style.scale or {1, 1}
	self.transform:setScale(scale[1], scale[2])

	local new_texture = new_style.texture
	if new_texture then
		self.image:setTexture(new_texture)
	end
	local new_tint = new_style.tint or Utils.UI_COLORS.WHITE
	local cur_tint = self.image:getTint()
	if cur_tint[1] ~= new_tint[1] or cur_tint[2] ~= new_tint[2] or cur_tint[3] ~= new_tint[3] or cur_tint[4] ~= new_tint[4] then
		self.image:setTint(new_tint)
	end
end


function ImageButton:onDebugDraw()
	local x, y, w, h = self.transform:getGlobalAABB()
	love.graphics.setColor(unpack(Utils.UI_COLORS.PINK))
	love.graphics.printf(string.format("State: %s", self.cur_state), Fonts:getFont("debug", 16), x, y + h, w)
end


return ImageButton