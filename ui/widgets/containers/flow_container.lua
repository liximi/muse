--------------------------------------------------
-- FlowContainer — 流式换行布局（CSS flex-wrap 等价物）
--
-- 子控件按主轴排列，超出容器时自动换行/换列。
-- 支持 H/V 方向、对齐、末行对齐策略。
--
-- 算法：两趟式
--   1. 第一趟：换行 + 最小尺寸计算
--   2. 第二趟：行内 EXPAND 分配 + 对齐
--------------------------------------------------

local Container = require "ui.widgets.containers.container"
local Utils = require "ui.utils"
local Class = require "dependencies.classic"

local SZ = Utils.SIZE_FLAGS
local ALIGN = Utils.ALIGNMENT

local LAST_WRAP_ALIGN = {
	INHERIT = "inherit",
	BEGIN = "begin",
	CENTER = "center",
	END = "end",
}

--[[datas:
	orientation        = "horizontal" | "vertical"  默认 "horizontal"
	h_separation        = number  列间距，默认 0
	v_separation        = number  行间距，默认 0
	alignment           = "begin" | "center" | "end"  默认 "begin"
	last_wrap_alignment = "inherit" | "begin" | "center" | "end"  末行对齐，默认 "inherit"
]]
local FlowContainer = Class(Container, function(self, datas, theme)
	datas = datas or {}
	local orientation = Utils.validateEnum(datas.orientation, Utils.ORIENTATION, Utils.ORIENTATION.HORIZONTAL, "FlowContainer.orientation")
	local is_vertical = orientation == Utils.ORIENTATION.VERTICAL

	Container.new(self, is_vertical and "VFlowContainer" or "HFlowContainer", datas, theme)

	self._vertical = is_vertical
	self.h_separation = datas.h_separation or 0
	self.v_separation = datas.v_separation or 0
	self.alignment = datas.alignment or ALIGN.BEGIN
	self.last_wrap_alignment = datas.last_wrap_alignment or LAST_WRAP_ALIGN.INHERIT

	self._cached_line_count = 0
	self._cached_line_max_children = 0
	self._cached_size = 0
end)

local function newLineData(child_count, min_line_height, min_line_length, stretch_avail, stretch_ratio_total, is_filled)
	return {
		child_count = child_count,
		min_line_height = min_line_height,
		min_line_length = min_line_length,
		stretch_avail = stretch_avail,
		stretch_ratio_total = stretch_ratio_total,
		is_filled = is_filled,
	}
end

function FlowContainer:_sortChildren()
	local visible = self:_visibleChildren()
	if #visible == 0 then
		self._cached_size = 0
		self._cached_line_count = 0
		self._cached_line_max_children = 0
		return
	end

	local cw, ch = self.transform:getSize()
	local vertical = self._vertical
	local h_sep = self.h_separation
	local v_sep = self.v_separation
	local container_size = vertical and ch or cw

	-- 第一趟：换行 + 收集每行信息
	local children_min = {}  -- child -> {w, h}
	local children_stretch = {}  -- child -> stretch_amount
	local lines = {}

	local ofs_x, ofs_y = 0, 0
	local line_height = 0
	local line_stretch_ratio_total = 0
	local children_in_line = 0

	for _, child in ipairs(visible) do
		local mw, mh = child:getDesiredSize()

		if vertical then
			if children_in_line > 0 then ofs_y = ofs_y + v_sep end
			if ofs_y + mh > container_size then
				table.insert(lines, newLineData(children_in_line, line_height, ofs_y - v_sep,
					container_size - (ofs_y - v_sep), line_stretch_ratio_total, true))
				ofs_x = ofs_x + line_height + h_sep
				ofs_y = 0
				line_height = 0
				line_stretch_ratio_total = 0
				children_in_line = 0
			end
			line_height = math.max(line_height, mw)
			if Utils.hasFlag(child.v_size_flags, SZ.EXPAND) then
				line_stretch_ratio_total = line_stretch_ratio_total + (child.stretch_ratio or 1)
			end
			ofs_y = ofs_y + mh
		else
			if children_in_line > 0 then ofs_x = ofs_x + h_sep end
			if ofs_x + mw > container_size then
				table.insert(lines, newLineData(children_in_line, line_height, ofs_x - h_sep,
					container_size - (ofs_x - h_sep), line_stretch_ratio_total, true))
				ofs_y = ofs_y + line_height + v_sep
				ofs_x = 0
				line_height = 0
				line_stretch_ratio_total = 0
				children_in_line = 0
			end
			line_height = math.max(line_height, mh)
			if Utils.hasFlag(child.h_size_flags, SZ.EXPAND) then
				line_stretch_ratio_total = line_stretch_ratio_total + (child.stretch_ratio or 1)
			end
			ofs_x = ofs_x + mw
		end

		children_min[child] = { mw, mh }
		children_in_line = children_in_line + 1
	end

	-- 最后一行
	local last_line_length = vertical and ofs_y or ofs_x
	local last_is_filled = false
	if #visible > 0 then
		local last_child = visible[#visible]
		local lm = children_min[last_child]
		if vertical then
			last_is_filled = (ofs_y + lm[2] > container_size)
		else
			last_is_filled = (ofs_x + lm[1] > container_size)
		end
	end
	table.insert(lines, newLineData(children_in_line, line_height, last_line_length,
		container_size - last_line_length, line_stretch_ratio_total, last_is_filled))

	self._cached_line_count = #lines
	self._cached_line_max_children = #lines > 0 and lines[1].child_count or 0

	-- 第二趟：行内 EXPAND + 对齐
	local line_idx = 0
	local child_idx_in_line = 0
	ofs_x, ofs_y = 0, 0
	local visible_idx = 0

	for _, child in ipairs(visible) do
		visible_idx = visible_idx + 1
		child_idx_in_line = child_idx_in_line + 1
		if child_idx_in_line > lines[line_idx + 1].child_count then
			line_idx = line_idx + 1
			child_idx_in_line = 1
			local prev_line = lines[line_idx]
			if vertical then
				ofs_x = ofs_x + prev_line.min_line_height + h_sep
				ofs_y = 0
			else
				ofs_x = 0
				ofs_y = ofs_y + prev_line.min_line_height + v_sep
			end
		end

		local line_data = lines[line_idx + 1]

		-- 行内 EXPAND 分配（每行第一个子控件触发计算）
		if child_idx_in_line == 1 then
			local line_children = {}
			local j = visible_idx
			while j <= #visible and #line_children < line_data.child_count do
				table.insert(line_children, visible[j])
				j = j + 1
			end

			local line_remaining = line_data.stretch_avail
			local stretch_children = {}
			local stretch_active = {}
			local stretch_total = 0

			for _, lc in ipairs(line_children) do
				children_stretch[lc] = 0
				local can_stretch = vertical
					and Utils.hasFlag(lc.v_size_flags, SZ.EXPAND)
					or Utils.hasFlag(lc.h_size_flags, SZ.EXPAND)
				if can_stretch then
					table.insert(stretch_children, lc)
					table.insert(stretch_active, true)
					stretch_total = stretch_total + (lc.stretch_ratio or 1)
				end
			end

			while stretch_total > 0 do
				local refit_ok = true
				for i_s, lc in ipairs(stretch_children) do
					if stretch_active[i_s] then
						local ratio = lc.stretch_ratio or 1
						local child_stretch = math.floor(line_remaining * ratio / stretch_total)
						local cm = children_min[lc]
						local child_axis_min = vertical and cm[2] or cm[1]
						local max_stretch = math.max(0, container_size - child_axis_min)

						if child_stretch > max_stretch then
							children_stretch[lc] = max_stretch
							stretch_active[i_s] = false
							stretch_total = stretch_total - ratio
							line_remaining = line_remaining - max_stretch
							refit_ok = false
							break
						end
					end
				end
				if refit_ok then
					for i_s, lc in ipairs(stretch_children) do
						if stretch_active[i_s] then
							local ratio = lc.stretch_ratio or 1
							children_stretch[lc] = math.floor(line_remaining * ratio / stretch_total)
						end
					end
					break
				end
			end

			local used = 0
			for _, lc in ipairs(line_children) do used = used + (children_stretch[lc] or 0) end
			lines[line_idx + 1].stretch_avail = math.max(line_data.stretch_avail - used, 0)
			line_data = lines[line_idx + 1]
		end

		-- 对齐偏移（仅该行第一个子控件）
		if child_idx_in_line == 1 and line_data.stretch_avail > 0 then
			local alignment_ofs = 0
			local is_not_first_and_not_filled = line_idx > 0 and not line_data.is_filled
			local prior_stretch = is_not_first_and_not_filled and lines[line_idx].stretch_avail or 0

			if self.alignment == ALIGN.BEGIN then
				if self.last_wrap_alignment ~= LAST_WRAP_ALIGN.INHERIT and is_not_first_and_not_filled then
					if self.last_wrap_alignment == LAST_WRAP_ALIGN.END then
						alignment_ofs = line_data.stretch_avail - prior_stretch
					elseif self.last_wrap_alignment == LAST_WRAP_ALIGN.CENTER then
						alignment_ofs = math.floor((line_data.stretch_avail - prior_stretch) / 2)
					end
				end
			elseif self.alignment == ALIGN.CENTER then
				if self.last_wrap_alignment ~= LAST_WRAP_ALIGN.INHERIT
					and self.last_wrap_alignment ~= LAST_WRAP_ALIGN.CENTER
					and is_not_first_and_not_filled then
					if self.last_wrap_alignment == LAST_WRAP_ALIGN.END then
						alignment_ofs = line_data.stretch_avail - math.floor(prior_stretch / 2)
					else
						alignment_ofs = math.floor(prior_stretch / 2)
					end
				else
					alignment_ofs = math.floor(line_data.stretch_avail / 2)
				end
			elseif self.alignment == ALIGN.END then
				if self.last_wrap_alignment ~= LAST_WRAP_ALIGN.INHERIT
					and self.last_wrap_alignment ~= LAST_WRAP_ALIGN.END
					and is_not_first_and_not_filled then
					if self.last_wrap_alignment == LAST_WRAP_ALIGN.BEGIN then
						alignment_ofs = prior_stretch
					else
						alignment_ofs = prior_stretch + math.floor((line_data.stretch_avail - prior_stretch) / 2)
					end
				else
					alignment_ofs = line_data.stretch_avail
				end
			end

			if vertical then ofs_y = ofs_y + alignment_ofs
			else ofs_x = ofs_x + alignment_ofs end
		end

		-- 计算子控件尺寸
		local cm = children_min[child]
		local child_w, child_h = cm[1], cm[2]

		if vertical then
			if Utils.hasFlag(child.h_size_flags, SZ.FILL)
				or Utils.hasFlag(child.h_size_flags, SZ.SHRINK_CENTER)
				or Utils.hasFlag(child.h_size_flags, SZ.SHRINK_END) then
				child_w = line_data.min_line_height
			end
			if Utils.hasFlag(child.v_size_flags, SZ.EXPAND) then
				child_h = child_h + (children_stretch[child] or 0)
			end
		else
			if Utils.hasFlag(child.v_size_flags, SZ.FILL)
				or Utils.hasFlag(child.v_size_flags, SZ.SHRINK_CENTER)
				or Utils.hasFlag(child.v_size_flags, SZ.SHRINK_END) then
				child_h = line_data.min_line_height
			end
			if Utils.hasFlag(child.h_size_flags, SZ.EXPAND) then
				child_w = child_w + (children_stretch[child] or 0)
			end
		end

		if vertical then
			child_h = math.min(child_h, container_size - ofs_y)
		else
			child_w = math.min(child_w, container_size - ofs_x)
		end

		self:fitChildInRect(child, ofs_x, ofs_y, child_w, child_h)

		if vertical then
			ofs_y = ofs_y + child_h + v_sep
		else
			ofs_x = ofs_x + child_w + h_sep
		end
	end

	-- 计算缓存尺寸（用于 getMinimumSize / getDesiredSize）
	if vertical then
		local max_x = 0
		for _, child in ipairs(visible) do
			local x, _ = child.transform:getPosition()
			local w, _ = child.transform:getSize()
			max_x = math.max(max_x, x + w)
		end
		self._cached_size = max_x
	else
		local max_y = 0
		for _, child in ipairs(visible) do
			local _, y = child.transform:getPosition()
			local _, h = child.transform:getSize()
			max_y = math.max(max_y, y + h)
		end
		self._cached_size = max_y
	end
end

function FlowContainer:getMinimumSize()
	return self:_getMinSize(false)
end

function FlowContainer:getDesiredSize()
	return self:_getMinSize(true)
end

function FlowContainer:_getMinSize(use_desired)
	local visible = self:_visibleChildren()
	if #visible == 0 then return self.transform:getSize() end

	local vertical = self._vertical
	local max_child_axis = 0  -- 主轴方向的最大子控件尺寸（用于最小宽度/高度保证）
	local max_child_cross = 0  -- 交叉轴方向的最大子控件尺寸

	for _, child in ipairs(visible) do
		local mw, mh
		if use_desired then mw, mh = child:getDesiredSize()
		else mw, mh = child:getCombinedMinimumSize() end
		if vertical then
			max_child_axis = math.max(max_child_axis, mh)
			max_child_cross = math.max(max_child_cross, mw)
		else
			max_child_axis = math.max(max_child_axis, mw)
			max_child_cross = math.max(max_child_cross, mh)
		end
	end

	local cached = self._cached_size or 0
	if vertical then
		-- 宽度 = max(总列宽, 最大子控件宽度)，高度 = max(最大子控件高度, ...)  —— 但 cached 才是真实列宽
		return math.max(cached, max_child_cross), max_child_axis
	else
		-- 宽度 = max(最大子控件宽度, ...)，高度 = max(总行高, 最大子控件高度)
		-- cached 为 0 时（初始帧），至少返回单行高度保证不为 0
		return max_child_axis, math.max(cached, max_child_cross)
	end
end

function FlowContainer:_getAllowedSizeFlagsHorizontal()
	if self._vertical then
		return { SZ.FILL, SZ.SHRINK_BEGIN, SZ.SHRINK_CENTER, SZ.SHRINK_END }
	else
		return { SZ.FILL, SZ.EXPAND, SZ.SHRINK_BEGIN, SZ.SHRINK_CENTER, SZ.SHRINK_END }
	end
end

function FlowContainer:_getAllowedSizeFlagsVertical()
	if self._vertical then
		return { SZ.FILL, SZ.EXPAND, SZ.SHRINK_BEGIN, SZ.SHRINK_CENTER, SZ.SHRINK_END }
	else
		return { SZ.FILL, SZ.SHRINK_BEGIN, SZ.SHRINK_CENTER, SZ.SHRINK_END }
	end
end

function FlowContainer:getLineCount()
	return self._cached_line_count
end

function FlowContainer:getLineMaxChildCount()
	return self._cached_line_max_children
end

return FlowContainer
