local ButtonBase = require "ui.widgets.button_base"
local Text = require "ui.widgets.text"
local Image = require "ui.widgets.image"
local Utils = require "ui.utils"
local Components = require "ui.components"
local Fonts = require "ui.fonts"
local Class = require "dependencies.classic"
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
local ImageButton = Class(ButtonBase, function(self, datas, theme)
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
		selected_hover = datas.selected_hover
	}

	local img_datas = {
		texture = datas.normal and datas.normal.texture,
		tint = datas.normal and datas.normal.tint or (self.theme.imagebutton and self.theme.imagebutton.normal.tint),
		anchor = {0, 0, 1, 1},
		padding = {0, 0, 0, 0}
	}
	self.image = self:addChild(Image(img_datas, theme))
	self.image.raycast_target = false -- 图片不阻断射线，让父按钮处理点击

	if not datas.no_text then
		self.text = self:addChild(Text({
			pivot = {0.5, 0.5},
			anchor = {0, 0, 1, 1},
			padding = {2, 2, 2, 2},
			h_align = "center",
			v_align = "center",
			text = self.state_styles.normal and self.state_styles.normal.text or "Button",
			text_color = self.state_styles.normal and self.state_styles.normal.text_color or
				(self.theme.imagebutton and self.theme.imagebutton.normal.text_color),
			font_key = datas.font_key,
			font_size = self.state_styles.normal and self.state_styles.normal.font_size or
				(self.theme.imagebutton and self.theme.imagebutton.normal.font_size)
		}))
		self.text.raycast_target = false
	end
end)

--- 按钮最小尺寸 = 内部图片最小尺寸
function ImageButton:getMinimumSize()
	return self.image:getMinimumSize()
end

--- 设置按钮文字（no_text 模式下静默忽略）
function ImageButton:setText(t)
	if self.text then
		self.text:setText(t)
	end
end

--- 设置按钮在某个状态下的样式
---@param state "normal"|"pressed"|"disabled"|"selected"|"hover"|"seleted_hover"
---@param style Utils.newImageButtonStateStyle 配置信息表 
function ImageButton:setStateStyle(state, style)
	if not BTN_STATES[string.upper(state)] then
		print("ImageButton:setStateStyle|Invalid state:", state)
		return
	end
	self.state_styles[state] = style
	if style.text then
		self:setText(style.text)
	end
	self:setState(self.cur_state)
end

--- 获取按钮在某个状态下的样式，会自动合并自定义样式、normal状态样式和主题样式
--- state_styles里对应状态的数据 > state_styles里normal状态的数据 > 主题里对应状态的数据 > 主题里normal状态的数据
--- 注意：text 字段不参与合并 —— 按钮文字由 setText() / 构造参数独立管理
---@param state "normal"|"pressed"|"disabled"|"selected"|"hover"|"seleted_hover"
function ImageButton:getStateStyle(state)
	local style = {}
	local t1 = {self.state_styles, self.theme.imagebutton}
	local t2 = state == "normal" and {"normal"} or {state, "normal"}
	for _, t in ipairs(t1) do
		for _, s in ipairs(t2) do
			if t[s] then
				for k, v in pairs(t[s]) do
					if k ~= "text" and not style[k] then
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
	Components.applyButtonTextStyle(self, new_style)
	Components.applyButtonTransform(self, old_style, new_style)

	-- 兼容旧写法：state style 中带 text 时自动更新按钮文字
	local explicit_style = self.state_styles[new_state]
	if explicit_style and explicit_style.text then
		self:setText(explicit_style.text)
	end

	local new_texture = new_style.texture
	if new_texture then
		self.image:setTexture(new_texture)
	end
	local new_tint = new_style.tint or Utils.UI_COLORS.WHITE
	local cur_tint = self.image:getTint()
	if cur_tint[1] ~= new_tint[1] or cur_tint[2] ~= new_tint[2] or cur_tint[3] ~= new_tint[3] or cur_tint[4] ~=
		new_tint[4] then
		self.image:setTint(new_tint)
	end
end

function ImageButton:onDebugDraw()
	local x, y, w, h = self.transform:getGlobalAABB()
	love.graphics.setColor(unpack(Utils.UI_COLORS.PINK))
	love.graphics.printf(string.format("State: %s", self.cur_state), Fonts:getFont("debug", 16), x, y + h, w)
end

return ImageButton
