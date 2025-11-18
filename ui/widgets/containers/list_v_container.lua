local Widget = require "ui.widgets.widget"
local Utils = require "ui.utils"


--会按照元子素的transform:getScaledSize()得到的高度自动排列所有子元素，并且会因此修改自己的高度
--如需固定高度的列表(自动拉伸或压缩子元素的高度)，请使用 box_v_container.lua

--注意：子元素的锚点不能设置为范围锚点
--[[datas: 此处不包括当前Widget继承的基类所支持的字段
	items = {Widget, ...} 要显示的UI的数组，注意：每个UI都必须实现GetSize方法，否则列表将无法正确布局元素。
	space = number 元素之间的间隔
]]
local List = Class(Widget, function(self, datas, theme)
	Widget.new(self, "ListVContainer", datas, theme)

	self.items = {}
	self.space = datas and datas.space or 8	--元素之间的间距，单位：像素
	self.list_total_height = 0

	if datas and datas.items then
		self:setItems(datas.items)
	end
end)


--- 设置要显示的内容
---@param items [Widget] 要显示的UI的数组，注意：每个UI都必须实现GetSize方法，否则列表将无法正确布局元素。
function List:setItems(items)
	self:removeAllChildren()
	self.items = {}
	for i, v in ipairs(items) do
		table.insert(self.items, v)
		self:addChild(v)
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
	self:addChild(item)
	self:layout()
end

function List:remove(item)
	for i, _item in ipairs(self.items) do
		if _item == item then
			table.remove(self.items, i)
			self:removeChild(item)
			self:layout()
			return
		end
	end
end

function List:removeAtPos(pos)
	local item = table.remove(self.items, pos)
	self:removeChild(item)
	self:layout()
	return item
end


function List:layout()
	self.list_total_height = 0
	local height_offset = 0
	for i, v in ipairs(self.items) do
		v:setPosition(nil, height_offset)
		local w, h = v.transform:getScaledSize()
		height_offset = height_offset + h + self.space
	end
	self.list_total_height = math.max(0, height_offset - self.space)
	self.transform:setSize(nil, self.list_total_height)
end


function List:onUpdate(dt)
	self:layout()
end


return List
