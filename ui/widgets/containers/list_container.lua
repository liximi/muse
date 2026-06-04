local Widget = require "ui.widgets.widget"


local AXIS = {
	vertical   = { pos = "y", size = "h", alter = "x" },
	horizontal = { pos = "x", size = "w", alter = "y" },
}


--[[datas: 此处不包括当前Widget继承的基类所支持的字段
	orientation = "vertical" | "horizontal"
	items = {Widget, ...}
	space = number 元素之间的间隔
]]
local List = Class(Widget, function(self, datas, theme)
	datas = datas or {}
	local orientation = datas.orientation == "horizontal" and "horizontal" or "vertical"
	self._axis = AXIS[orientation]

	Widget.new(self, orientation == "vertical" and "ListVContainer" or "ListHContainer", datas, theme)

	self.items = {}
	self.space = datas.space or 8
	self._layout_dirty = true
	self._in_layout = false

	if datas.items then
		self:setItems(datas.items)
	end
end)


function List:setItems(items)
	self:removeAllChildren()
	self.items = {}
	for i, v in ipairs(items) do
		table.insert(self.items, v)
		self:addChild(v)
	end
	self:layout()
end


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
	if self._in_layout then return end
	self._in_layout = true
	local a = self._axis
	local offset = 0
	for i, v in ipairs(self.items) do
		local x_arg, y_arg
		if a.pos == "x" then
			x_arg, y_arg = offset, 0
		else
			x_arg, y_arg = nil, offset
		end
		v:setPosition(x_arg, y_arg)
		local sw, sh = v.transform:getScaledSize()
		local item_size = a.pos == "x" and sw or sh
		offset = offset + item_size + self.space
	end
	local list_total = math.max(0, offset - self.space)
	self.transform:setSize(
		a.pos == "x" and list_total or nil,
		a.pos == "y" and list_total or nil
	)
	self._layout_dirty = false
	self._in_layout = false
end


function List:onUpdate(dt)
	if self._layout_dirty then
		self:layout()
		self._layout_dirty = false
	end
end


return List
