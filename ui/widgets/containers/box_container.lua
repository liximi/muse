local Widget = require "ui.widgets.widget"
local Class = require "dependencies.classic"

local AXIS = {
	vertical = {
		pos = "y",
		size = "h",
		alter_pos = "x",
		alter_size = "w"
	},
	horizontal = {
		pos = "x",
		size = "w",
		alter_pos = "y",
		alter_size = "h"
	}
}

-- Flexbox 式布局容器，子元素按 flex 权重伸缩
-- 子 widget 上设置 flex_grow / flex_shrink / flex_min_size 字段来控制布局行为
--[[datas: 此处不包括基类所支持的字段
	orientation = "vertical" | "horizontal"
	space = number  -- 子元素间隔，默认 0
	cross_align = "stretch" | "start" | "center" | "end"  -- 交叉轴对齐，默认 "stretch"
]]
local Box = Class(Widget, function(self, datas, theme)
	datas = datas or {}
	local orientation = datas.orientation == "horizontal" and "horizontal" or "vertical"
	self._axis = AXIS[orientation]

	Widget.new(self, orientation == "vertical" and "BoxVContainer" or "BoxHContainer", datas, theme)

	self.space = datas.space or 0
	self.cross_align = datas.cross_align or "stretch"
	self._layout_dirty = true
	self._in_layout = false

	self:enableSizeChangedEvent(true)
end)

function Box:layout()
	if self._in_layout then
		return
	end
	self._in_layout = true

	local a = self._axis
	local container_main = self.transform[a.size]
	local container_cross = self.transform[a.alter_size]

	-- 收集可见子元素及其首选尺寸
	local visible = {}
	local total_preferred = 0
	local total_flex_grow = 0

	-- cross_align=stretch 时将 cross 约束传给子元素，使其能根据宽度计算自动换行高度（如 Text）
	local cross_constraint = (self.cross_align == "stretch") and container_cross or nil

	for _, child in ipairs(self.children) do
		if not child.shown then
			goto continue
		end
		-- 用 measure() 替代 getScaledSize()：子元素根据内容 + 约束返回自然尺寸
		local m
		if a.pos == "x" then
			-- 水平 Box：cross=height，约束高度
			m = child:measure(nil, cross_constraint)
		else
			-- 垂直 Box：cross=width，约束宽度
			m = child:measure(cross_constraint, nil)
		end
		local main_size = a.pos == "x" and m.w or m.h
		local cross_size = a.pos == "x" and m.h or m.w
		local entry = {
			child = child,
			main_size = main_size,
			cross_size = cross_size,
			flex_grow = child.flex_grow or 0,
			flex_shrink = child.flex_shrink or 1,
			min_size = child.flex_min_size or 0
		}
		table.insert(visible, entry)
		total_preferred = total_preferred + main_size
		total_flex_grow = total_flex_grow + entry.flex_grow
		::continue::
	end

	local n = #visible
	if n == 0 then
		self._in_layout = false
		return
	end

	total_preferred = total_preferred + self.space * (n - 1)

	-- 计算每个元素的主轴分配尺寸
	local remaining = container_main - total_preferred

	for _, entry in ipairs(visible) do
		if remaining > 0 and total_flex_grow > 0 then
			-- 有剩余空间，按 flex_grow 分配
			local extra = entry.flex_grow / total_flex_grow * remaining
			entry.allocated = entry.main_size + extra
		elseif remaining < 0 then
			-- 空间不足，按 flex_shrink 压缩
			local total_shrink = 0
			for _, e in ipairs(visible) do
				total_shrink = total_shrink + e.flex_shrink
			end
			local reduction = entry.flex_shrink / total_shrink * math.abs(remaining)
			entry.allocated = math.max(entry.min_size, entry.main_size - reduction)
		else
			entry.allocated = entry.main_size
		end
	end

	-- 计算交叉轴尺寸
	for _, entry in ipairs(visible) do
		if self.cross_align == "stretch" then
			entry.cross_allocated = container_cross
		else
			entry.cross_allocated = entry.cross_size
		end
	end

	-- 应用位置和尺寸
	local offset = 0
	for _, entry in ipairs(visible) do
		local child = entry.child

		-- 主轴位置
		if a.pos == "x" then
			child:setPosition(offset, nil)
		else
			child:setPosition(nil, offset)
		end

		-- 交叉轴位置
		local cross_offset
		if self.cross_align == "start" then
			cross_offset = 0
		elseif self.cross_align == "center" then
			cross_offset = (container_cross - entry.cross_allocated) / 2
		elseif self.cross_align == "end" then
			cross_offset = container_cross - entry.cross_allocated
		else
			cross_offset = 0 -- stretch 模式，由尺寸填充
		end

		if a.pos == "x" then
			child:setPosition(nil, cross_offset)
		else
			child:setPosition(cross_offset, nil)
		end

		-- 设置子元素尺寸
		if a.pos == "x" then
			child.transform:setSize(entry.allocated, entry.cross_allocated)
		else
			child.transform:setSize(entry.cross_allocated, entry.allocated)
		end

		offset = offset + entry.allocated + self.space
	end

	self._layout_dirty = false
	self._in_layout = false
end

function Box:addChild(child)
	Widget.addChild(self, child)
	self._layout_dirty = true
	return child
end

function Box:removeChild(child)
	Widget.removeChild(self, child)
	self._layout_dirty = true
	return child
end

function Box:onUpdate(dt)
	if self._layout_dirty then
		self:layout()
		self._layout_dirty = false
	end
end

function Box:onSizeChanged(w, h)
	self._layout_dirty = true
end

return Box
