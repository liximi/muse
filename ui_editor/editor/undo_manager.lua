--------------------------------------------------
-- undo_manager.lua — 编辑器撤销/重做管理
--
-- 快照式撤销：每次变更前调用 pushSnapshot(widget) 存储轻量状态，
-- 撤销时 restoreSnapshot 恢复。
--
-- 状态捕获：递归收集每个 widget 的 transform + 类型关键属性，
-- 避免完整序列化/重建的开销。
--------------------------------------------------

local Utils = require "ui.utils"

--------------------------------------------------
-- 状态捕获
--------------------------------------------------

-- 捕获单个 widget 的可恢复状态
local function captureState(widget)
	if not widget then return nil end

	local t = widget.transform
	local state = {
		-- Transform 真相源
		left   = t.left,
		right  = t.right,
		top    = t.top,
		bottom = t.bottom,
		-- 锚点 / 支点
		anchor_min = { t.anchor_min[1], t.anchor_min[2] },
		anchor_max = { t.anchor_max[1], t.anchor_max[2] },
		pivot = { t.pivot[1], t.pivot[2] },
		-- 尺寸
		w = t.w,
		h = t.h,
		-- 容器标志
		h_size_flags = widget.h_size_flags,
		v_size_flags = widget.v_size_flags,
		stretch_ratio = widget.stretch_ratio,
		-- id / 类型
		_mui_id = widget._mui_id,
		_mui_type = widget._mui_type,
	}

	-- Panel / 通用背景
	if widget.bg_color then
		state.bg_color = { widget.bg_color[1], widget.bg_color[2], widget.bg_color[3], widget.bg_color[4] }
	end
	if widget.rounding_radius then
		state.rounding_radius = widget.rounding_radius
	end

	-- Text
	if widget.text ~= nil then
		-- 只存纯文本
		local txt = widget.getText and widget:getText(true)
		state.text = txt
	end
	if widget.font_size then
		state.font_size = widget.font_size
	end
	if widget.horizontal_align then
		state.h_align = widget.horizontal_align
	end
	if widget.vertical_align then
		state.v_align = widget.vertical_align
	end

	return state
end

-- 递归捕获子树状态
local function captureTree(widget)
	if not widget then return nil end

	local node = {
		state = captureState(widget),
	}
	-- 用 _mui_id 作 key（无 id 的用引用暂存，重建时靠遍历顺序恢复）
	if widget._mui_id then
		node.id = widget._mui_id
	end

	local children = {}
	for _, child in ipairs(widget.children) do
		local childNode = captureTree(child)
		if childNode then
			children[#children + 1] = childNode
		end
	end
	if #children > 0 then
		node.children = children
	end

	return node
end

--------------------------------------------------
-- 状态恢复
--------------------------------------------------

-- 将捕获的状态写回 widget
local function restoreState(widget, state)
	if not widget or not state then return end

	local t = widget.transform

	-- 先设置锚点（影响 _recalcLayout 行为）
	t.anchor_min[1] = state.anchor_min[1]
	t.anchor_min[2] = state.anchor_min[2]
	t.anchor_max[1] = state.anchor_max[1]
	t.anchor_max[2] = state.anchor_max[2]

	-- 再设置 padding（真相源）
	t:setPadding(state.left, state.right, state.top, state.bottom)

	-- 支点
	t.pivot[1] = state.pivot[1]
	t.pivot[2] = state.pivot[2]

	-- 显式尺寸
	t:setSize(state.w, state.h)

	-- 容器标志
	widget.h_size_flags = state.h_size_flags
	widget.v_size_flags = state.v_size_flags
	widget.stretch_ratio = state.stretch_ratio

	-- _mui_id / _mui_type
	widget._mui_id = state._mui_id
	widget._mui_type = state._mui_type

	-- Panel / 背景
	if state.bg_color then
		widget.bg_color = { state.bg_color[1], state.bg_color[2], state.bg_color[3], state.bg_color[4] }
	end
	if state.rounding_radius then
		widget.rounding_radius = state.rounding_radius
	end

	-- Text
	if state.text ~= nil and widget.setText then
		widget:setText(state.text)
	end
	if state.font_size then
		widget.font_size = state.font_size
	end
	if state.h_align and widget.horizontal_align then
		widget.horizontal_align = state.h_align
	end
	if state.v_align and widget.vertical_align then
		widget.vertical_align = state.v_align
	end
end

-- 递归恢复子树状态（按 children 顺序匹配，容错处理数量不一致）
local function restoreTree(widget, node)
	if not widget or not node or not node.state then return end

	restoreState(widget, node.state)

	if node.children then
		local visibleChildren = {}
		for _, child in ipairs(widget.children) do
			if child:isShown() then
				visibleChildren[#visibleChildren + 1] = child
			end
		end
		for i = 1, math.min(#node.children, #visibleChildren) do
			restoreTree(visibleChildren[i], node.children[i])
		end
	end
end

--------------------------------------------------
-- 管理器
--------------------------------------------------

local UndoManager = Class(function(self, maxDepth)
	self._undo_stack = {}   -- { snapshot, ... }
	self._redo_stack = {}   -- { snapshot, ... }
	self._max_depth = maxDepth or 50
end)

--- 推送快照到撤销栈
---@param root widget 根 widget
function UndoManager:pushSnapshot(root)
	if not root then return end

	local snapshot = captureTree(root)
	if not snapshot then return end

	self._undo_stack[#self._undo_stack + 1] = snapshot

	-- 超出最大深度时丢弃最早
	if #self._undo_stack > self._max_depth then
		table.remove(self._undo_stack, 1)
	end

	-- 新变更清空重做栈
	self._redo_stack = {}
end

--- 撤销：返回 true 表示执行了撤销
---@param root widget
---@return boolean
function UndoManager:undo(root)
	if #self._undo_stack == 0 then return false end

	-- 当前状态入重做栈
	local current = captureTree(root)
	self._redo_stack[#self._redo_stack + 1] = current

	-- 弹出上一个快照并恢复
	local snapshot = table.remove(self._undo_stack)
	restoreTree(root, snapshot)

	return true
end

--- 重做：返回 true 表示执行了重做
---@param root widget
---@return boolean
function UndoManager:redo(root)
	if #self._redo_stack == 0 then return false end

	-- 当前状态入撤销栈
	local current = captureTree(root)
	self._undo_stack[#self._undo_stack + 1] = current

	-- 弹出重做快照并恢复
	local snapshot = table.remove(self._redo_stack)
	restoreTree(root, snapshot)

	return true
end

--- 是否有可撤销的
function UndoManager:canUndo()
	return #self._undo_stack > 0
end

--- 是否有可重做的
function UndoManager:canRedo()
	return #self._redo_stack > 0
end

--- 清空所有历史
function UndoManager:clear()
	self._undo_stack = {}
	self._redo_stack = {}
end

return UndoManager
