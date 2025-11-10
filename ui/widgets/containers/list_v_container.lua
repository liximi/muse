local Widget = require "ui.widgets.widget"
local Utils = require "ui.utils"


--会按照元子素的transform:getScaledSize()得到的高度自动排列所有子元素，并且会因此修改自己的高度
--如需固定高度的列表(自动拉伸或压缩子元素的高度)，请使用 box_v_container.lua

--注意：子元素的锚点不能设置为范围锚点
local List = Class(Widget, function(self, w, h, space)
	Widget.new(self, "VerticalList")

	self.items = {}
	self.space = space or 8	--元素之间的间距，单位：像素
	self.list_total_height = 0

	self.list_root = self:addChild(Widget("ListRoot"))
end)


--- 设置要显示的内容
---@param items [Widget] 要显示的UI的数组，注意：每个UI都必须实现GetSize方法，否则列表将无法正确布局元素。
function List:setItems(items)
	self.list_root:removeAllChildren()
	self.items = {}
	for i, v in ipairs(items) do
		table.insert(self.items, v)
		self.list_root:addChild(v)
	end
	self:layout()
end


--- 插入列表元素
---@param item Widget 注意：列表元素UI必须实现GetSize方法，否则列表将无法正确布局元素。
---@param pos integer | nil 如果不传递pos，则默认插入到末尾
function List:insert(item, pos)
	if pos then
		table.insert(self.items, pos, item)
	else
		table.insert(self.items, item)
	end
	self.list_root:addChild(item)
	self:layout()
end


function List:layout()
	self.list_total_height = 0
	local height_offset = 0
	for i, v in ipairs(self.items) do
		v:setPosition(0, height_offset)
		local w, h = v.transform:getScaledSize()
		height_offset = height_offset + h + self.space
	end
	self.list_total_height = height_offset - self.space
	self.transform:setSize(nil, self.list_total_height)
end


function List:onUpdate(dt)
	self:layout()
end


return List
