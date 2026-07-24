--------------------------------------------------
-- GridContainer — 固定列数网格布局
--
-- 算法：
--   1. 扫描子控件，收集每列最大 min_w / desired_w + 每行最大 min_h / desired_h
--   2. 按比例将剩余空间分配给 desired_size 超过 min_size 的列/行
--   3. 剩余空间按需分配给 EXPAND 列/行
--   4. 最终每列宽度 = 该列最大子控件宽度，每行高度 = 该行最大子控件高度
--------------------------------------------------

local Container = require "ui.widgets.containers.container"
local Utils = require "ui.utils"
local Class = require "dependencies.classic"

local SZ = Utils.SIZE_FLAGS

--[[datas:
	columns      = number  列数，默认 2
	h_separation = number  列间距，默认 0
	v_separation = number  行间距，默认 0
]]
local GridContainer = Class(Container, function(self, datas, theme)
	Container.new(self, "GridContainer", datas, theme)
	self.columns = (datas and datas.columns) or 2
	self.h_separation = (datas and datas.h_separation) or 0
	self.v_separation = (datas and datas.v_separation) or 0
end)

function GridContainer:setColumns(n)
	n = math.max(1, n)
	if self.columns ~= n then
		self.columns = n
		self:queueSort()
	end
end

function GridContainer:_sortChildren()
	local visible = self:_visibleChildren()
	if #visible == 0 then return end

	local cw, ch = self.transform:getSize()
	local cols = self.columns
	local h_sep = self.h_separation
	local v_sep = self.v_separation

	-- 第一趟：收集每列/每行的 min、desired + EXPAND 标记
	local col_min_w = {}
	local row_min_h = {}
	local col_desired_w = {}
	local row_desired_h = {}
	local col_max_w = {}
	local row_max_h = {}
	local col_expanded = {}
	local row_expanded = {}

	for i, child in ipairs(visible) do
		local row = math.floor((i - 1) / cols)
		local col = (i - 1) % cols

		local mw, mh = child:getCombinedMinimumSize()
		local dw, dh = child:getDesiredSize()

		col_min_w[col] = math.max(col_min_w[col] or 0, mw)
		row_min_h[row] = math.max(row_min_h[row] or 0, mh)
		col_desired_w[col] = math.max(col_desired_w[col] or 0, dw)
		row_desired_h[row] = math.max(row_desired_h[row] or 0, dh)

		col_max_w[col] = math.max(col_max_w[col] or 0, cw)
		row_max_h[row] = math.max(row_max_h[row] or 0, ch)

		if Utils.hasFlag(child.h_size_flags, SZ.EXPAND) then col_expanded[col] = true end
		if Utils.hasFlag(child.v_size_flags, SZ.EXPAND) then row_expanded[row] = true end
	end

	-- 修正 max ≥ min
	for col, maxv in pairs(col_max_w) do col_max_w[col] = math.max(maxv, col_min_w[col] or 0) end
	for row, maxv in pairs(row_max_h) do row_max_h[row] = math.max(maxv, row_min_h[row] or 0) end

	local max_col = #visible < cols and #visible or cols
	local max_row = math.ceil(#visible / cols)

	-- 空列视为 EXPAND
	for col = #visible, cols - 1 do col_expanded[col] = true end

	-- 计算剩余空间
	local remaining_w = cw - h_sep * math.max(max_col - 1, 0)
	local remaining_h = ch - v_sep * math.max(max_row - 1, 0)
	local empty_w = remaining_w
	local empty_h = remaining_h

	for col = 0, max_col - 1 do
		empty_w = empty_w - (col_min_w[col] or 0)
		if not col_expanded[col] then remaining_w = remaining_w - (col_min_w[col] or 0) end
	end
	for row = 0, max_row - 1 do
		empty_h = empty_h - (row_min_h[row] or 0)
		if not row_expanded[row] then remaining_h = remaining_h - (row_min_h[row] or 0) end
	end

	--------------------------------------------------
	-- 第二趟 A：按 desired 比例分配剩余空间
	--------------------------------------------------
	local total_desired_extra_w = 0
	for col = 0, max_col - 1 do
		local extra = (col_desired_w[col] or 0) - (col_min_w[col] or 0)
		if extra > 0 then total_desired_extra_w = total_desired_extra_w + extra end
	end
	if empty_w > 0 and total_desired_extra_w > 0 then
		local ratio = math.min(empty_w / total_desired_extra_w, 1.0)
		for col = 0, max_col - 1 do
			local extra = (col_desired_w[col] or 0) - (col_min_w[col] or 0)
			if extra > 0 then
				local inc = math.floor(extra * ratio)
				col_min_w[col] = (col_min_w[col] or 0) + inc
				if not col_expanded[col] then remaining_w = remaining_w - inc end
			end
		end
	end

	local total_desired_extra_h = 0
	for row = 0, max_row - 1 do
		local extra = (row_desired_h[row] or 0) - (row_min_h[row] or 0)
		if extra > 0 then total_desired_extra_h = total_desired_extra_h + extra end
	end
	if empty_h > 0 and total_desired_extra_h > 0 then
		local ratio = math.min(empty_h / total_desired_extra_h, 1.0)
		for row = 0, max_row - 1 do
			local extra = (row_desired_h[row] or 0) - (row_min_h[row] or 0)
			if extra > 0 then
				local inc = math.floor(extra * ratio)
				row_min_h[row] = (row_min_h[row] or 0) + inc
				if not row_expanded[row] then remaining_h = remaining_h - inc end
			end
		end
	end

	--------------------------------------------------
	-- 第二趟 B：EXPAND — 逐出装不下的列/行
	--------------------------------------------------
	local col_fixed = {}
	local col_exp_list = {}
	for col = 0, max_col - 1 do
		if col_expanded[col] then table.insert(col_exp_list, col) end
	end

	local can_fit = false
	while not can_fit and #col_exp_list > 0 do
		can_fit = true
		local max_idx = col_exp_list[1]
		for _, col in ipairs(col_exp_list) do
			if (col_min_w[col] or 0) > (col_min_w[max_idx] or 0) then max_idx = col end
			if (remaining_w / #col_exp_list) < (col_min_w[col] or 0) then can_fit = false end
		end
		if not can_fit then
			for i, col in ipairs(col_exp_list) do
				if col == max_idx then table.remove(col_exp_list, i); break end
			end
			col_expanded[max_idx] = false
			remaining_w = remaining_w - (col_min_w[max_idx] or 0)
			col_fixed[max_idx] = col_min_w[max_idx]
		end
	end

	local row_fixed = {}
	local row_exp_list = {}
	for row = 0, max_row - 1 do
		if row_expanded[row] then table.insert(row_exp_list, row) end
	end

	can_fit = false
	while not can_fit and #row_exp_list > 0 do
		can_fit = true
		local max_idx = row_exp_list[1]
		for _, row in ipairs(row_exp_list) do
			if (row_min_h[row] or 0) > (row_min_h[max_idx] or 0) then max_idx = row end
			if (remaining_h / #row_exp_list) < (row_min_h[row] or 0) then can_fit = false end
		end
		if not can_fit then
			for i, row in ipairs(row_exp_list) do
				if row == max_idx then table.remove(row_exp_list, i); break end
			end
			row_expanded[max_idx] = false
			remaining_h = remaining_h - (row_min_h[max_idx] or 0)
			row_fixed[max_idx] = row_min_h[max_idx]
		end
	end

	-- 重建 EXPAND set
	local col_is_exp = {}
	for _, col in ipairs(col_exp_list) do col_is_exp[col] = true end
	local row_is_exp = {}
	for _, row in ipairs(row_exp_list) do row_is_exp[row] = true end

	--------------------------------------------------
	-- 第二趟 C：max 约束 — 超出 max 的移出 EXPAND
	--------------------------------------------------
	can_fit = false
	while not can_fit and #col_exp_list > 0 do
		can_fit = true
		local capped = -1
		for _, col in ipairs(col_exp_list) do
			if col_max_w[col] and (remaining_w / #col_exp_list) > col_max_w[col] then
				capped = col; can_fit = false; break
			end
		end
		if capped >= 0 then
			for i, col in ipairs(col_exp_list) do
				if col == capped then table.remove(col_exp_list, i); break end
			end
			col_is_exp[capped] = false
			remaining_w = remaining_w - col_max_w[capped]
			col_fixed[capped] = col_max_w[capped]
		end
	end

	can_fit = false
	while not can_fit and #row_exp_list > 0 do
		can_fit = true
		local capped = -1
		for _, row in ipairs(row_exp_list) do
			if row_max_h[row] and (remaining_h / #row_exp_list) > row_max_h[row] then
				capped = row; can_fit = false; break
			end
		end
		if capped >= 0 then
			for i, row in ipairs(row_exp_list) do
				if row == capped then table.remove(row_exp_list, i); break end
			end
			row_is_exp[capped] = false
			remaining_h = remaining_h - row_max_h[capped]
			row_fixed[capped] = row_max_h[capped]
		end
	end

	--------------------------------------------------
	-- 第三趟：定位
	--------------------------------------------------
	local col_expand_size = 0
	local col_remainder = 0
	if #col_exp_list > 0 then
		col_expand_size = math.floor(remaining_w / #col_exp_list)
		col_remainder = remaining_w - col_expand_size * #col_exp_list
	end

	local row_expand_size = 0
	local row_remainder = 0
	if #row_exp_list > 0 then
		row_expand_size = math.floor(remaining_h / #row_exp_list)
		row_remainder = remaining_h - row_expand_size * #row_exp_list
	end

	local row_ofs = 0
	for i, child in ipairs(visible) do
		local row = math.floor((i - 1) / cols)
		local col = (i - 1) % cols

		if col == 0 and row > 0 then
			local prev = row - 1
			local ph = 0
			if row_is_exp[prev] then ph = row_expand_size
			elseif row_fixed[prev] then ph = row_fixed[prev]
			else ph = row_min_h[prev] or 0 end
			if row_is_exp[prev] and prev < row_remainder then ph = ph + 1 end
			row_ofs = row_ofs + ph + v_sep
		end

		local cell_w = 0
		if col_is_exp[col] then cell_w = col_expand_size
		elseif col_fixed[col] then cell_w = col_fixed[col]
		else cell_w = col_min_w[col] or 0 end
		if col_is_exp[col] and col < col_remainder then cell_w = cell_w + 1 end

		local cell_h = 0
		if row_is_exp[row] then cell_h = row_expand_size
		elseif row_fixed[row] then cell_h = row_fixed[row]
		else cell_h = row_min_h[row] or 0 end
		if row_is_exp[row] and row < row_remainder then cell_h = cell_h + 1 end

		local col_ofs = 0
		for c = 0, col - 1 do
			local cw2 = 0
			if col_is_exp[c] then cw2 = col_expand_size
			elseif col_fixed[c] then cw2 = col_fixed[c]
			else cw2 = col_min_w[c] or 0 end
			if col_is_exp[c] and c < col_remainder then cw2 = cw2 + 1 end
			col_ofs = col_ofs + cw2 + h_sep
		end

		self:fitChildInRect(child, col_ofs, row_ofs, cell_w, cell_h)
	end
end

function GridContainer:getMinimumSize()
	return self:_getMinSize(false)
end

function GridContainer:getDesiredSize()
	return self:_getMinSize(true)
end

function GridContainer:_getMinSize(use_desired)
	local visible = self:_visibleChildren()
	if #visible == 0 then return self.transform:getSize() end

	local cols = self.columns
	local h_sep = self.h_separation
	local v_sep = self.v_separation
	local col_min_w = {}
	local row_min_h = {}
	local max_col = 0
	local max_row = 0

	for i, child in ipairs(visible) do
		local row = math.floor((i - 1) / cols)
		local col = (i - 1) % cols
		local mw, mh
		if use_desired then mw, mh = child:getDesiredSize()
		else mw, mh = child:getCombinedMinimumSize() end
		col_min_w[col] = math.max(col_min_w[col] or 0, mw)
		row_min_h[row] = math.max(row_min_h[row] or 0, mh)
		max_col = math.max(max_col, col)
		max_row = math.max(max_row, row)
	end

	local total_w = 0
	for col = 0, max_col do total_w = total_w + (col_min_w[col] or 0) end
	total_w = total_w + h_sep * max_col

	local total_h = 0
	for row = 0, max_row do total_h = total_h + (row_min_h[row] or 0) end
	total_h = total_h + v_sep * max_row

	local cw, ch = self.transform:getSize()
	return math.max(total_w, cw), math.max(total_h, ch)
end

return GridContainer
