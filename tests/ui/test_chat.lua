local Widget = require "ui.widgets.widget"
local Text = require "ui.widgets.text"
local Panel = require "ui.widgets.panel"
local ChatHistory = require "ui.widgets.advanced.chat_history"
local Utils = require "ui.utils"

local test = {}
test.name = "Chat History"

function test.create(parent)
	parent:removeAllChildren()

	parent:addChild(Text({
		text = "ChatHistory — scrollable chat bubbles",
		font_size = 14, h = 20,
		text_color = Utils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0}, padding = {0, 0, 0},
	}))

	-- 描边框
	local chat_frame = parent:addChild(Panel({
		anchor = {0, 0, 1, 1},
		padding = {0, 0, 28, 0},
		bg_color = {0, 0, 0, 0},
		outline_width = 1,
		outline_color = Utils.UI_COLORS.LINE,
		rounding_radius = 4,
	}))

	local chat = chat_frame:addChild(ChatHistory({
		space = 8,
		anchor = {0, 0, 1, 1},
		padding = {4, 4, 4, 4},
	}))
	chat:setChatBubbleStyle("user", chat:createChatBubbleStyle(
		Utils.UI_COLORS.ACCENT, 4, nil, nil, nil,
		Utils.UI_COLORS.TITLE, {8, 8, 6, 6}, "right"
	))
	chat:setChatBubbleStyle("agent", chat:createChatBubbleStyle(
		Utils.UI_COLORS.SURFACE, 4, nil, nil, nil,
		Utils.UI_COLORS.PRIMARY_TEXT, {8, 8, 6, 6}, "left"
	))
	chat:setChatHistory({
		{"user", "Hey! What's the weather like today?"},
		{"agent", "Sunny with a high of 24°C. Perfect day for a walk!"},
		{"user", "Great, I'll head out after lunch then."},
		{"agent", "Enjoy! Don't forget sunscreen."},
		{"user", "Good call. Any cafe recommendations nearby?"},
		{"agent", "Blue Bottle on 3rd Ave has excellent pour-over. About a 10-minute walk."},
		{"user", "Sounds perfect. Thanks!"},
		{"agent", "Anytime! Let me know if you need anything else."},
		{"user", "Actually, what time do they close?"},
		{"agent", "Blue Bottle closes at 7pm on weekdays, 8pm on weekends."},
		{"user", "Perfect, I'll have plenty of time then."},
		{"agent", "They also have great pastries if you're interested."},
		{"user", "You had me at pastries. I'm sold!"},
		{"agent", "Haha, the almond croissant is legendary. Don't skip it."},
		{"user", "Noted. Almond croissant it is. Heading out now, thanks for all the tips!"},
		{"agent", "Have a great afternoon! Enjoy the sun and the coffee."},
		{"user", "Will do! Bye!"},
		{"agent", "Bye! :)"},
	})
end

return test
