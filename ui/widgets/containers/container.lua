--------------------------------------------------
-- Container 基类
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
--- 非 FILL 时尺寸在 [minsize, MIN(desired, rect_size)] 之间。
---@param child Widget
---@param x number 矩形左上角 X
---@param y number 矩形左上角 Y
---@param w number 矩形宽度
---@param h number 矩形高度
function Container:fitChildInRect(child, x, y, w, h)
	local mw, mh = child:getCombinedMinimumSize()
	local dw, dh = child:getDesiredSize()
	local hf = child.h_size_flags
	local vf = child.v_size_flags

	-- 水平 Fill/Shrink
	if not Utils.hasFlag(hf, SZ.FILL) then
		local fw = math.max(math.min(dw, w), mw)
		if Utils.hasFlag(hf, SZ.SHRINK_END) then
			x = x + w - fw
		elseif Utils.hasFlag(hf, SZ.SHRINK_CENTER) then
			x = x + math.floor((w - fw) / 2)
		end
		w = fw
	end

	-- 垂直 Fill/Shrink
	if not Utils.hasFlag(vf, SZ.FILL) then
		local fh = math.max(math.min(dh, h), mh)
		if Utils.hasFlag(vf, SZ.SHRINK_END) then
			y = y + h - fh
		elseif Utils.hasFlag(vf, SZ.SHRINK_CENTER) then
			y = y + math.floor((h - fh) / 2)
		end
		h = fh
	end

	local old_w, old_h = child.transform:getSize()
	child.transform:setPosition(x, y)
	child.transform:setSize(w, h)

	-- 立即触发 SizeChanged：让 Text 等控件在父容器继续排其余子控件之前完成重排，
	-- 避免"宽度变了但文本高度还是旧的"导致下方控件定位错误。
	if child._notifySizeChanged and (w ~= old_w or h ~= old_h) then
		child:_notifySizeChanged(w, h)
	end
end

--- 返回容器内部可用最大尺寸（扣除自身装饰如 padding/margin 后的空间）。
--- 默认返回自身尺寸。子类覆写以减去边距。
---@return number w
---@return number h
function Container:getInnerCombinedMaximumSize()
	return self.transform:getSize()
end

--- 返回容器的期望尺寸（基于子控件 desired_size 计算）。
--- 默认等于 getMinimumSize()。子类覆写以报告基于子控件 desired_size 的尺寸。
---@return number w
---@return number h
function Container:getDesiredSize()
	return self:getMinimumSize()
end

--- 返回本容器允许子控件使用的水平 size_flags 列表。
--- 子类可覆写以限制子控件的行为（如 PanelContainer 禁止 EXPAND）。
---@return table
function Container:_getAllowedSizeFlagsHorizontal()
	return { SZ.FILL, SZ.EXPAND, SZ.SHRINK_BEGIN, SZ.SHRINK_CENTER, SZ.SHRINK_END }
end

--- 返回本容器允许子控件使用的垂直 size_flags 列表。
---@return table
function Container:_getAllowedSizeFlagsVertical()
	return { SZ.FILL, SZ.EXPAND, SZ.SHRINK_BEGIN, SZ.SHRINK_CENTER, SZ.SHRINK_END }
end

--- 返回可见的子控件列表。
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
function Container:_sortChildren()
	-- 子类覆写
end

--- 返回纯子控件推导的最小尺寸（不含容器自身尺寸的 cap）。
--- 用于 _preChildrenUpdate 中检测子控件尺寸变化。
--- 默认委托给 getMinimumSize()；BoxContainer 需覆写以避免 math.max(children, container_size) 的掩盖效应。
---@return number w
---@return number h
function Container:_getChildrenMinSize()
	return self:getMinimumSize()
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
--- 用 _getChildrenMinSize()（纯子控件最小尺寸）而非 getMinimumSize() 检测变化，
--- 避免 BoxContainer 中 math.max(children, container_size) 将子控件增长掩盖掉。
function Container:_preChildrenUpdate(dt)
	local cw, ch = self.transform:getSize()
	local children_min_w, children_min_h = self:_getChildrenMinSize()
	if self._dirty
		or cw ~= self._last_sort_w or ch ~= self._last_sort_h
		or children_min_w ~= self._last_children_min_w
		or children_min_h ~= self._last_children_min_h then
		self:_sortChildren()

		-- fitChildInRect 可能触发子控件 SizeChanged → reflow（如文本换行），
		-- 子控件 min size 可能已变，再排一次确保下方元素不会定位错误。
		local new_cw, new_ch = self:_getChildrenMinSize()
		if new_cw ~= children_min_w or new_ch ~= children_min_h then
			self:_sortChildren()
			new_cw, new_ch = self:_getChildrenMinSize()
		end

		self._last_sort_w = cw
		self._last_sort_h = ch
		self._last_children_min_w = new_cw
		self._last_children_min_h = new_ch
		self._dirty = false
		if self.auto_size then
			if self._auto_size_axis == "h" then
				if new_cw > 0 then self.transform:setSize(new_cw, nil) end
			elseif self._auto_size_axis == "v" then
				if new_ch > 0 then self.transform:setSize(nil, new_ch) end
			else
				if new_cw > 0 or new_ch > 0 then self.transform:setSize(new_cw, new_ch) end
			end
		end
	end
end

--- 尺寸变化时标记脏。实际排序在 update() 中完成。
function Container:onSizeChanged(w, h)
	self._dirty = true
end

return Container
