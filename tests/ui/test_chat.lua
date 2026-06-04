local Widget = require "ui.widgets.widget"
local Text = require "ui.widgets.text"
local ChatHistory = require "ui.widgets.advanced.chat_history"
local Utils = require "ui.utils"

local test = {}
test.name = "Chat History"

function test.create(parent)
	parent:removeAllChildren()

	parent:addChild(Text({
		text = "ChatHistory — scrollable chat bubbles with ScrollContainer",
		font_size = 14,
		h = 20,
		text_color = Utils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 0},
	}))

	local chat = parent:addChild(ChatHistory({
		space = 8,
		anchor = {0, 0, 1, 1},
		padding = {0, 0, 28, 0},
	}))
	chat:setChatBubbleStyle("user", chat:createChatBubbleStyle(
		Utils.UI_COLORS.ACCENT,
		4, nil, nil, nil,
		Utils.UI_COLORS.TITLE,
		{8, 8, 6, 6}, "right"
	))
	chat:setChatBubbleStyle("agent", chat:createChatBubbleStyle(
		Utils.UI_COLORS.SURFACE,
		4, nil, nil, nil,
		Utils.UI_COLORS.PRIMARY_TEXT,
		{8, 8, 6, 6}, "left"
	))
	chat:setChatHistory({
		{"user", "Hey! What's the weather like today?"},
		{"agent", "Sunny with a high of 24°C. Perfect day for a walk!"},
		{"user", "Great, I'll head out after lunch then."},
		{"agent", "Enjoy! Don't forget sunscreen."},
		{"user", "Good call. Any cafe recommendations nearby?"},
		{"agent", "Blue Bottle on 3rd Ave has excellent pour-over. About a 10-minute walk."},
		{"user", "Sounds perfect. Thanks!"},
	})
end

return test
