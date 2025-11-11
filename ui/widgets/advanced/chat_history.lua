local Widget = require "ui.widgets.widget"
local Text = require "ui.widgets.text"
local Panel = require "ui.widgets.panel"
local ListContainer = require "ui.widgets.containers.list_v_container"
local ScrollContainer = require "ui.widgets.containers.scroll_container"


--[[datas: 此处不包括当前Widget继承的基类所支持的字段
	chatter_id = string

	bg_color = {r, g, b, a}
	rounding_radius = number

	text = string
	font_key = string
	font_size = number
	text_color = {r, g, b, a}
	text_padding = {left, right, top, bottom}
]]
local ChatBubble = Class(Widget, function(self, datas, theme)
	Widget.new(self, "ChatBubble", datas, theme)

	self.chatter_id = datas and datas.chatter_id

	self.bg = self:addChild(Panel({
		bg_color = datas and datas.bg_color,
		outline_width = 0,
		rounding_radius = datas and datas.rounding_radius,
		anchors = {0, 0, 1, 1},
		padding = {0, 0, 0, 0},
	}))

	self.text = self:addChild(Text({
		font_key = datas and datas.font_key,
		font_size = datas and datas.font_size,
		text_color = datas and datas.text_color,
		anchors = {0, 0, 1, 1},
		padding = datas and datas.text_padding or {0, 0, 0, 0},
	}))

	self:setText(datas and datas.text)
end)

function ChatBubble:setText(text)
	self.text:setText(text)
	local text_w, text_h = self.text:getDimensions()
	self:setSize(nil, text_h + self.text.transform.top + self.text.transform.bottom)
end

function ChatBubble:getText()
	return self.text:getText(true)
end

function ChatBubble:updateStyle(style)
	self.bg:SetBGColor(style.bg_color or self.bg.theme.panel.bg_color)
	self.bg.rounding_radius = style.rounding_radius or 0

	self.text:setFont(style.font_key, style.font_size)
	self.text:setTextColor(unpack(style.text_color or self.text.theme.text.text_color))
	self.text:setPadding(style.text_padding or {0, 0, 0, 0})
end




--[[datas: 此处不包括当前Widget继承的基类所支持的字段
	space = number 气泡间隔
]]
local ChatHistory = Class(Widget, function(self, datas, theme)
	Widget.new(self, "ChatList", datas, theme)

	self.chatter_styles = {}
	self.history = {}

	self.list = ListContainer({
		space = datas and datas.space
	})
	self.scroll_container = self:addChild(ScrollContainer({
		item = self.list,
		anchors = {0, 0, 1, 1},
		padding = {0, 0, 0, 0},
	}))
end)


--- 设置要显示的聊天记录，必须在添加聊天记录之前设置样式
---@param history table {{"chatter_id", "content"}, {"chatter_id", "content"}, ...}
function ChatHistory:setChatHistory(history)
	self.history = {}
	for i, c in ipairs(history) do
		table.insert(self.history, c)
	end
	self:refresh()
end

--- 在当前聊天记录末尾追加聊天记录，必须在添加聊天记录之前设置样式
---@param history table 既可以是单个记录，比如 {"chatter_id", "content"}，也可以是记录数组
function ChatHistory:appendHistory(history)
	if #history == 2 and type(history[1]) == "string" and type(history[2]) == "string" then
		table.insert(self.history, history)
	else
		for i, c in ipairs(history) do
			table.insert(self.history, c)
		end
	end
	self:refresh()
end

--- 为不同的聊天对象设置气泡样式，必须在添加聊天记录之前设置样式
---@param chatter_id string
---@param style table self:createChatBubbleStyle()
function ChatHistory:setChatBubbleStyle(chatter_id, style)
	self.chatter_styles[chatter_id] = style
	for i, bubble in ipairs(self.list.items) do
		if bubble.chatter_id == chatter_id then
			bubble:updateStyle(style)
			local x = style.left and 1 or 0
			bubble.transform:setPivot(x, 0)
			bubble.transform:setAnchors(x, 0, x, 0)
		end
	end
end

function ChatHistory:createChatBubbleStyle(bg_color, rounding_radius, font_key, font_size, text_color, text_padding, left)
	return {
		bg_color = bg_color,
		rounding_radius = rounding_radius,
		font_key = font_key,
		font_size = font_size,
		text_color = text_color,
		text_padding = text_padding,
		left = left == true,
	}
end


function ChatHistory:refresh()
	local new_count = #self.history
	local old_count = #self.list.items
	--TODO
	if new_count > old_count then
		
	elseif new_count < old_count then
	end
end


return ChatHistory