local Widget = require "ui.widgets.widget"
local Text = require "ui.widgets.text"
local Panel = require "ui.widgets.panel"
local ListContainer = require "ui.widgets.containers.list_v_container"
local ScrollContainer = require "ui.widgets.containers.scroll_container"


--[[datas: 此处不包括当前Widget继承的基类所支持的字段
	chatter_id = string

	bg_color = {r, g, b, a}
	rounding_radius = number
	max_width = number
	alignment = "left"|"right"

	text = string
	font_key = string
	font_size = number
	text_color = {r, g, b, a}
	text_padding = {left, right, top, bottom}
]]
local ChatBubble = Class(Widget, function(self, datas, theme)
	Widget.new(self, "ChatBubble", datas, theme)

	self.chatter_id = datas and datas.chatter_id
	self.max_width = datas and datas.max_width
	self.alignment = datas and datas.alignment or "left"

	local x = self.alignment == "right" and 1 or 0
	self.root = self:addChild(Widget("BubbleRoot", {
		anchor = {x, 0, x, 0},
		padding = {0, 0, 0, 0},
		pivot = {x, 0},
	}))

	self.bg = self.root:addChild(Panel({
		bg_color = datas and datas.bg_color,
		outline_width = 0,
		rounding_radius = datas and datas.rounding_radius,
		anchor = {0, 0, 1, 1},
		padding = {0, 0, 0, 0},
	}))

	self.text = self.root:addChild(Text({
		font_key = datas and datas.font_key,
		font_size = datas and datas.font_size,
		text_color = datas and datas.text_color,
		anchor = {0, 0, 1, 1},
		padding = datas and datas.text_padding or {0, 0, 0, 0},
	}))
	self:setText(datas and datas.text)
end)

function ChatBubble:setText(text)
	local font = self.text:getFont()
	text = text or self.text:getText(true)
	local w = font:getWrap(text, self.max_width)
	self.root.transform:setSize(w + self.text.transform.left + self.text.transform.right)
	self.text.transform:onUpdate()
	self.text:setText(text)
	local text_w, text_h = self.text:getDimensions()
	self.transform:setSize(nil, text_h + self.text.transform.top + self.text.transform.bottom)
	self.root.transform:setSize(nil, text_h + self.text.transform.top + self.text.transform.bottom)
end

function ChatBubble:getText()
	return self.text:getText(true)
end

function ChatBubble:updateStyle(style)
	self.bg:SetBGColor(style.bg_color or self.bg.theme.panel.bg_color)
	self.bg.rounding_radius = style.rounding_radius or 0

	self.text:setFont(style.font_key, style.font_size)
	self.text:setTextColor(style.text_color or self.text.theme.text.text_color)
	self.text:setPadding(style.text_padding or {0, 0, 0, 0})
	self:setText()
end









--[[datas: 此处不包括当前Widget继承的基类所支持的字段
	space = number 气泡间隔
]]
local ChatHistory = Class(Widget, function(self, datas, theme)
	Widget.new(self, "ChatList", datas, theme)

	self.chatter_styles = {}
	self.history = {}

	self.list = ListContainer({
		space = datas and datas.space,
		anchor = {0, 0, 1, 0},
		padding = {0, 12, 0, 0},
	})
	self.scroll_container = self:addChild(ScrollContainer({
		item = self.list,
		anchor = {0, 0, 1, 1},
		padding = {0, 0, 0, 0},
		-- show_slider_bar = false,
        -- hide_slider_when_cannot_scroll = true,
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
		local bubble = self:createChatBubble(history[1], history[2])
		self.list:insert(bubble)
	else
		for i, c in ipairs(history) do
			table.insert(self.history, c)
			local bubble = self:createChatBubble(c[1], c[2])
			self.list:insert(bubble)
		end
	end
end

--- 为不同的聊天对象设置气泡样式，必须在添加聊天记录之前设置样式
---@param chatter_id string
---@param style table self:createChatBubbleStyle()
function ChatHistory:setChatBubbleStyle(chatter_id, style)
	self.chatter_styles[chatter_id] = style
	for i, bubble in ipairs(self.list.items) do
		if bubble.chatter_id == chatter_id then
			bubble:updateStyle(style)
		end
	end
end

--- 创建一个聊天气泡样式
---@param bg_color table {r, g, b, a}
---@param rounding_radius number
---@param max_width number
---@param font_key string
---@param font_size number
---@param text_color table {r, g, b, a}
---@param text_padding table {left, right, top, bottom}
---@param alignment "left"|"right"
function ChatHistory:createChatBubbleStyle(bg_color, rounding_radius, max_width, font_key, font_size, text_color, text_padding, alignment)
	return {
		bg_color = bg_color,
		rounding_radius = rounding_radius,
		max_width = max_width,
		font_key = font_key,
		font_size = font_size,
		text_color = text_color,
		text_padding = text_padding,
		alignment = alignment,
	}
end


function ChatHistory:createChatBubble(chatter_id, text)
	local bubble_style = self.chatter_styles[chatter_id]
	local bubble = ChatBubble({
		chatter_id = chatter_id,
		text = text,
		bg_color = bubble_style.bg_color,
		rounding_radius = bubble_style.rounding_radius,
		max_width = bubble_style.max_width or self.transform.w * 0.8,
		alignment = bubble_style.alignment,
		font_key = bubble_style.font_key,
		font_size = bubble_style.font_size,
		text_color = bubble_style.text_color,
		text_padding = bubble_style.text_padding,

		anchor = {0, 0, 1, 0},
		padding = {0, 0},
	})
	return bubble
end

function ChatHistory:updateChatBubble(bubble, chatter_id, text)
	if chatter_id ~= bubble.chatter_id or text ~= bubble:getText() then
		bubble.chatter_id = chatter_id
		bubble:setText(text)
		bubble:updateStyle(self.chatter_styles[chatter_id])
	end
end


function ChatHistory:refresh()
	local new_count = #self.history
	local old_count = #self.list.items
	if new_count >= old_count then
		for i, content in ipairs(self.history) do
			local bubble = self.list.items[i]
			if not bubble then
				bubble = self:createChatBubble(content[1], content[2])
				self.list:insert(bubble)
			else
				self:updateChatBubble(bubble, content[1], content[2])
			end
		end
	elseif new_count < old_count then
		for i = #self.list.items, 1, -1 do
			local chat_content = self.history[i]
			if chat_content then
				local bubble = self.list.items[i]
				self:updateChatBubble(bubble, chat_content[1], chat_content[2])
			else
				self.list:removeAtPos(i)
			end
		end
	end
end


function ChatHistory:onUpdate(dt)
	local list_h = self.list.transform.h
	local scrollable_h = self.scroll_container.scrollable_h
	if scrollable_h ~= list_h then
		self.scroll_container:setScrollableH(list_h)
	end
end


return ChatHistory