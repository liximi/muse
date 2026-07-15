--------------------------------------------------
-- Container 基类 — scene/gui/container.cpp
--
-- 核心契约：子控件进入 Container 后放弃自主定位权，
-- 由容器的 _sortChildren() 统一管理位置和尺寸。
-- addChild/removeChild 自动触发重排（queueSort）。
--
-- 子类只需覆写 _sortChildren()，在其中调用
-- fitChildInRect(child, x, y, w, h) 定位每个子控件。
--------------------------------------------------

local Widget = require "ui.widgets.widget"
local Utils = require "ui.utils"
local Class = require "dependencies.classic"

local SZ = Utils.SIZE_FLAGS

--[[datas: 此处不包括基类所支持的字段
	（Container 本身无额外 datas 字段，由子类定义）
]]
local Container = Class(Widget, function(self, name, datas, theme)
	Widget.new(self, name, datas, theme)
	self._dirty = true
	-- 开启后每次 _sortChildren 之后自动根据子控件最小尺寸调整自身尺寸
	self.auto_size = (datas and datas.auto_size) or false
end)

--- 标记需要重排。下一帧 onUpdate 时自动调用 _sortChildren。
function Container:queueSort()
	self._dirty = true
end

--- 将子控件放入给定的矩形区域内，根据其 size_flags 决定 Fill/Shrink 行为。
--- container.cpp:130 fit_child_in_rect
---@param child Widget
---@param x number 矩形左上角 X
---@param y number 矩形左上角 Y
---@param w number 矩形宽度
---@param h number 矩形高度
function Container:fitChildInRect(child, x, y, w, h)
	local mw, mh = child:getCombinedMinimumSize()
	local hf = child.h_size_flags
	local vf = child.v_size_flags

	-- 水平 Fill/Shrink
	if not Utils.hasFlag(hf, SZ.FILL) then
		local fw = mw
		if Utils.hasFlag(hf, SZ.SHRINK_END) then
			x = x + w - fw
		elseif Utils.hasFlag(hf, SZ.SHRINK_CENTER) then
			x = x + math.floor((w - fw) / 2)
		end
		w = fw
	end

	-- 垂直 Fill/Shrink
	if not Utils.hasFlag(vf, SZ.FILL) then
		local fh = mh
		if Utils.hasFlag(vf, SZ.SHRINK_END) then
			y = y + h - fh
		elseif Utils.hasFlag(vf, SZ.SHRINK_CENTER) then
			y = y + math.floor((h - fh) / 2)
		end
		h = fh
	end

	child.transform:setPosition(x, y)
	child.transform:setSize(w, h)
end

--- 返回可见且可排序的子控件列表（排除非 Control、隐藏、top_level）。
--- container.cpp as_sortable_control
---@return Widget[]
function Container:_visibleChildren()
	local result = {}
	for _, child in ipairs(self.children) do
		if child:isShown() then
			table.insert(result, child)
		end
	end
	return result
end

--- 子类覆写此方法实现具体布局逻辑。
--- box_container.cpp _resort
function Container:_sortChildren()
	-- 子类覆写
end

function Container:addChild(child)
	Widget.addChild(self, child)
	self:queueSort()
	return child
end

function Container:removeChild(child)
	Widget.removeChild(self, child)
	self:queueSort()
	return child
end

--- 在子控件 update 之前排序。Widget:_preChildrenUpdate 的覆写。
--- 确保子控件本帧就能拿到容器分配的尺寸。
--- 同时检测子控件内容变化（通过 getMinimumSize 缓存），自动触发重排。
function Container:_preChildrenUpdate(dt)
	local cw, ch = self.transform:getSize()
	-- 容器自身尺寸变了、或子控件内容尺寸变了（某个子控件自适应增高/变宽），都需要重排
	local min_w, min_h = self:getMinimumSize()
	if self._dirty
		or cw ~= self._last_sort_w or ch ~= self._last_sort_h
		or min_w ~= self._last_min_w or min_h ~= self._last_min_h then
		print(string.format("[Container] %s RE-SORT | cw=%.0f->%.0f ch=%.0f->%.0f min_w=%.0f->%.0f min_h=%.0f->%.0f dirty=%s",
			self._name, tostring(self._last_sort_w), cw, tostring(self._last_sort_h), ch,
			tostring(self._last_min_w), min_w, tostring(self._last_min_h), min_h,
			tostring(self._dirty)))
		self:_sortChildren()
		self._last_sort_w = cw
		self._last_sort_h = ch
		self._last_min_w = min_w
		self._last_min_h = min_h
		self._dirty = false
		-- auto_size：只在主轴方向自动调整尺寸
		if self.auto_size then
			-- 复用上面已计算的 min_w/min_h
			if self._auto_size_axis == "h" then
				if min_w > 0 then self.transform:setSize(min_w, nil) end
			elseif self._auto_size_axis == "v" then
				if min_h > 0 then self.transform:setSize(nil, min_h) end
			else
				if min_w > 0 or min_h > 0 then self.transform:setSize(min_w, min_h) end
			end
		end
	end
end

--- 尺寸变化时标记脏。实际排序在 update() 中完成。
function Container:onSizeChanged(w, h)
	self._dirty = true
end

return Container
