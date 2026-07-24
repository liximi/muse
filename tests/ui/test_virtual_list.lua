--------------------------------------------------
-- VirtualList 测试 — 3000 项虚拟化列表
--------------------------------------------------

local Widget = require "ui.widgets.widget"
local Text = require "ui.widgets.text"
local Panel = require "ui.widgets.panel"
local VirtualList = require "ui.widgets.containers.virtual_list"
local VirtualListItem = require "ui.widgets.virtual_list_item"
local Utils = require "ui.utils"
local Class = require "dependencies.classic"

local ITEM_COUNT = 3000
local ITEM_HEIGHT = 28
local SEPARATION = 2

--------------------------------------------------
-- 模板：一个简单的行 item
--------------------------------------------------
--[[datas: 此处不包括基类所支持的字段
]]
local RowItem = Class(VirtualListItem, function(self, datas, theme)
	VirtualListItem.new(self, datas, theme)

	self.label = self:addChild(Text({
		text = "",
		font_size = 13,
		text_color = Utils.UI_COLORS.PRIMARY_TEXT,
		anchor = {0, 0, 1, 0.5},
		padding = {8, 0, 0, 0},
	}))

	self.index_label = self:addChild(Text({
		text = "",
		font_size = 11,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {1, 0, 1, 0.5},
		padding = {0, 8, 0, 0},
	}))
end)

function RowItem:getItemSize()
	return ITEM_HEIGHT
end

function RowItem:bindData(data, index)
	if data then
		self.label:setText(string.format("  %s", data))
		self.index_label:setText(string.format("#%d  ", index))
	else
		self.label:setText("")
		self.index_label:setText("")
	end
end

--------------------------------------------------
-- 测试入口
--------------------------------------------------
local test = {}
test.name = "Virtual List"

function test.create(parent)
	parent:removeAllChildren()

	-- 标题
	parent:addChild(Text({
		text = string.format("VirtualList — %d data items, only ~10 widgets instantiated (scroll to verify)", ITEM_COUNT),
		font_size = 14, h = 20,
		text_color = Utils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0}, padding = {0, 0, 0, 0},
	}))

	-- VirtualList 容器
	local list_frame = parent:addChild(Panel({
		anchor = {0, 0, 1, 1},
		padding = {0, 0, 28, 0},
		bg_color = Utils.UI_COLORS.BASE,
		outline_width = 1,
		outline_color = Utils.UI_COLORS.LINE,
		rounding_radius = 4,
	}))

	local vlist = list_frame:addChild(VirtualList({
		itemTemplate = RowItem,
		itemSize = ITEM_HEIGHT,
		separation = SEPARATION,
		orientation = "vertical",
		anchor = {0, 0, 1, 1},
		padding = {4, 12, 4, 4},  -- 右侧留 12px 给滚动条
	}))

	-- 生成 3000 条假数据
	local fake_data = {}
	for i = 0, ITEM_COUNT - 1 do
		fake_data[i] = string.format("Virtual list item #%04d — this row should recycle smoothly", i)
	end

	vlist:setData(ITEM_COUNT, function(index)
		return fake_data[index]
	end)
end

return test
