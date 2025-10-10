local Widget = require "ui.widgets.widget"
local SliderBar = require "ui.widgets.sliderbar_v"
local Fonts = require "ui.fonts"
local Utils = require "ui.utils"
local Tween = require "dependencies.tween"
local AddSizeComponent = require "ui.components".AddSize


--一种直接将所有列表元素作为子UI的列表实现，在元素较多时性能表现不太好
local List = Class(Widget, function(self, w, h, space)
	Widget.new(self, "List")

	AddSizeComponent(self)

	self.items = {}

	self.x_offset = 0
	self.offset = 0
	self.space = space or 8	--元素之间的间距，单位：像素
	self.list_total_height = 0
	self.sensitivity = 80	--滚动灵敏度，单位：像素

	self.list_root = self:addChild(Widget("ListRoot"))
	--覆写Draw函数
	self.list_root.draw = function (_self)
		if not _self:shouldDraw() then
			return
		end
		local x, y = self:getGlobalPosition()
		local w, h = self.transform:getSize()
		love.graphics.setScissor(x, y, w, h)
		Widget.draw(_self)
		love.graphics.setScissor()
	end

	-- self.slider_bar = self:addChild(SliderBar(nil, h))
	self.transform:setSize(w, h)
end)


--- 设置要显示的内容
---@param items [Widget] 要显示的UI的数组，注意：每个UI都必须实现GetSize方法，否则列表将无法正确布局元素。
function List:SetItems(items)
	self.list_root:removeAllChildren()
	self.items = {}
	for i, v in ipairs(items) do
		table.insert(self.items, v)
		self.list_root:addChild(v)
	end
	self:RefreashListLayout()
end


--- 插入列表元素
---@param item Widget 注意：列表元素UI必须实现GetSize方法，否则列表将无法正确布局元素。
---@param pos integer | nil 如果不传递pos，则默认插入到末尾
function List:Insert(item, pos)
	if pos then
		table.insert(self.items, pos, item)
	else
		table.insert(self.items, item)
	end
	self.list_root:addChild(item)
	self:RefreashListLayout()
end


function List:SetXOffset(offset)
	self.x_offset = offset
	local x, y = self.list_root:getPosition()
	self.list_root:setPosition(offset, y)
end


function List:RefreashListLayout()
	self.list_total_height = 0
	local height_offset = 0
	for i, v in ipairs(self.items) do
		v:setPosition(0, height_offset)
		local w, h = v.transform:getSize()
		height_offset = height_offset + h + self.space
	end
	self.list_total_height = height_offset - self.space
	local w, h = self.transform:getSize()
	local max_offset = math.max(0, self.list_total_height - h)
	if max_offset < self.offset then
		self:SetOffset(max_offset)
	end
end


function List:SetOffset(offset)
	local w, h = self.transform:getSize()
	offset = math.min(math.max(offset, 0), math.max(0, self.list_total_height - h))
	if offset == self.offset then
		return
	end
	self.tween = Tween.new(0.1 * math.abs(self.offset - offset) / self.sensitivity, self, {offset = offset}, "linear")
end

function List:OnWheelMoved(x, y)
	local mousex, mousey = love.mouse.getPosition()
	if not self:isInUIScope(mousex, mousey) then
		return
	end
	if y > 0 then
		self:SetOffset(self.offset-self.sensitivity)
	elseif y < 0 then
		self:SetOffset(self.offset+self.sensitivity)
	end
end


function List:OnUpdate(dt)
	self:RefreashListLayout()
    if self.tween then
        if self.tween:update(dt) then
            self.tween = nil
        end
		self.list_root:setPosition(self.x_offset, -self.offset)
    end
end

function List:onDraw()
	if self._debug then
		local x, y = self:getGlobalPosition()
		local w, h = self:getGlobalScaledSize()
		love.graphics.setColor(unpack(Utils.debug_color1))
		love.graphics.rectangle("line", x, y, w, h)
		love.graphics.printf(string.format("Offset: %.1f|Total Height: %.1f", self.offset, self.list_total_height),
			Fonts:getFont("default", 16), x, y+h, w)
	end
end


return List
