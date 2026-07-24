--------------------------------------------------
-- VirtualList — 虚拟化列表容器
--
-- 只接受 VirtualListItem 子类作为元素模板。初始化时计算可见区域内
-- 能容纳的元素数量，实例化 visibleCount+2 个控件，之后数量保持不变
-- （直到容器尺寸或模板尺寸变化）。滚动仅替换数据绑定 + 视觉偏移，
-- 不实际移动控件。
--
-- 用法：
--   local list = VirtualList({
--       itemTemplate = MyChatBubble,   -- VirtualListItem 子类
--       orientation  = "vertical",
--       separation  = 4,
--       anchor       = {0, 0, 1, 1},
--   })
--   list:setData(100, function(i) return messages[i] end)
--   list:scrollTo(200)
--------------------------------------------------

local Container = require "ui.widgets.containers.container"
local Utils = require "ui.utils"
local Class = require "dependencies.classic"

local ORIENT = Utils.ORIENTATION
local SZ = Utils.SIZE_FLAGS

-- 滚动条常量
local SB_WIDTH = 6
local SB_MIN_LENGTH = 20
local SB_TRACK_COLOR = {0.15, 0.15, 0.15, 0.3}
local SB_THUMB_COLOR = {0.45, 0.45, 0.45, 0.65}
local SCROLL_SPEED = 40 -- 每次 wheel tick 滚动的像素数

--[[datas:
	itemTemplate  = VirtualListItem 子类（必填）
	itemSize      = number          沿主轴固定尺寸（可选，模板 getItemSize 优先）
	itemDatas     = table           传递给每个 item 构造函数的 datas（可选）
	orientation   = "vertical" | "horizontal"  默认 "vertical"
	separation    = number          子控件间距，默认 0
]]
local VirtualList = Class(Container, function(self, datas, theme)
	datas = datas or {}

	local orientation = Utils.validateEnum(
		datas.orientation, ORIENT, ORIENT.VERTICAL, "VirtualList.orientation")
	local is_horizontal = orientation == ORIENT.HORIZONTAL

	Container.new(self, is_horizontal and "VirtualHList" or "VirtualVList", datas, theme)

	self._is_horizontal = is_horizontal
	self._auto_size_axis = is_horizontal and "h" or "v"
	self.separation = datas.separation or 0

	-- 模板
	self.itemTemplate = datas.itemTemplate
	assert(self.itemTemplate ~= nil, "VirtualList: itemTemplate is required")

	-- 测量模板尺寸
	if datas.itemSize then
		self._itemSize = datas.itemSize
	else
		local measure = self.itemTemplate(nil, self.theme)
		self._itemSize = measure:getItemSize()
		measure:destroy()
	end
	self._itemStride = self._itemSize + self.separation

	-- 传递给每个 item 的构造参数
	self._itemDatas = datas.itemDatas or {}

	-- 数据源
	self._dataCount = 0
	self._getData = nil

	-- 滚动状态
	self._scrollOffset = 0
	self._firstIndex = 0

	-- item 实例
	self._itemWidgets = {}
	self._instanceCount = 0

	-- 尺寸缓存（用于检测变化）
	self._lastContainerW = 0
	self._lastContainerH = 0
	self._lastItemSize = self._itemSize

	-- 滚动条拖拽状态
	self._sbDragging = false
	self._sbDragStartPos = 0    -- 拖拽起始屏幕坐标
	self._sbDragStartOffset = 0 -- 拖拽起始 scrollOffset
end)

--------------------------------------------------
-- 公开方法
--------------------------------------------------

--- 设置数据源。
---@param count    number   数据总数量
---@param getData  function 按索引取数据 function(index:0-based) -> data|nil
function VirtualList:setData(count, getData)
	self._dataCount = count or 0
	self._getData = getData
	self._scrollOffset = 0
	self._firstIndex = 0
	self:_bindVisibleItems()
	self:queueSort()
end

--- 设置滚动偏移（像素）。自动 clamp 到 [0, maxScroll]。
function VirtualList:scrollTo(offset)
	if self._itemStride <= 0 then return end
	local maxScroll = self:getMaxScroll()
	self._scrollOffset = math.max(0, math.min(offset, maxScroll))

	local firstIndex = math.floor(self._scrollOffset / self._itemStride)
	if firstIndex ~= self._firstIndex then
		self._firstIndex = firstIndex
		self:_bindVisibleItems()
	end
	self:queueSort()
end

--- 获取当前滚动偏移。
function VirtualList:getScrollOffset()
	return self._scrollOffset
end

--- 获取最大可滚动偏移。
function VirtualList:getMaxScroll()
	local totalSize = math.max(0, self._dataCount * self._itemStride - self.separation)
	local viewport = self._is_horizontal and self.transform.w or self.transform.h
	return math.max(0, totalSize - viewport)
end

--- 返回当前可见的 item 控件（用于外部遍历）。
---@return Widget[]
function VirtualList:getItems()
	return self._itemWidgets
end

--------------------------------------------------
-- 内部：布局重算
--------------------------------------------------

--- 重算可见数量，必要时重建 item 实例。
function VirtualList:_recalculate()
	local cw, ch = self.transform:getSize()
	local viewport = self._is_horizontal and cw or ch
	if viewport <= 0 then return end
	if self._itemSize <= 0 then return end

	local visibleCount = math.ceil(viewport / self._itemStride)
	local instanceCount = visibleCount + 2  -- 上下各 1 个缓冲

	if instanceCount == self._instanceCount then return end

	-- 销毁旧实例
	for _, widget in ipairs(self._itemWidgets) do
		self:removeChild(widget)
		widget:destroy()
	end
	self._itemWidgets = {}

	-- 创建新实例
	for i = 1, instanceCount do
		local item = self.itemTemplate(self._itemDatas, self.theme)
		-- 交叉轴 FILL，主轴不需要容器扩张
		if self._is_horizontal then
			item.v_size_flags = SZ.FILL
			item.h_size_flags = 0
		else
			item.h_size_flags = SZ.FILL
			item.v_size_flags = 0
		end
		self:addChild(item)
		table.insert(self._itemWidgets, item)
	end

	self._instanceCount = instanceCount
	self:_bindVisibleItems()
	self:queueSort()
end

--- 将所有 item 实例绑定到当前可见范围的数据。
function VirtualList:_bindVisibleItems()
	if not self._getData then return end

	for i, widget in ipairs(self._itemWidgets) do
		local dataIndex = self._firstIndex + i - 1
		if dataIndex >= 0 and dataIndex < self._dataCount then
			local data = self._getData(dataIndex)
			widget:bindData(data, dataIndex)
			widget:show()
		else
			widget:bindData(nil, dataIndex)
			widget:hide()
		end
	end
end

--------------------------------------------------
-- Container 钩子
--------------------------------------------------

function VirtualList:_preChildrenUpdate(dt)
	local cw, ch = self.transform:getSize()

	-- 容器尺寸变化 → 重算实例数量
	if cw ~= self._lastContainerW or ch ~= self._lastContainerH then
		self._lastContainerW = cw
		self._lastContainerH = ch
		self:_recalculate()
	end

	-- 模板尺寸变化 → 重算（例如 theme 切换导致同一模板报告不同尺寸）
	if self._itemSize ~= self._lastItemSize then
		self._lastItemSize = self._itemSize
		self._itemStride = self._itemSize + self.separation
		self._instanceCount = 0  -- 强制重建
		self:_recalculate()
	end

	-- 脏标记 → 重新布局（含视觉偏移）
	if self._dirty then
		self:_sortChildren()
		self._dirty = false
	end
end

--- 定位每个 item 实例到其固定槽位，并叠加视觉滚动偏移。
--- 注意：遍历 _itemWidgets 而非 _visibleChildren()，
--- 确保隐藏的缓冲 item 也保持正确位置，滚动回来时无需重排。
function VirtualList:_sortChildren()
	if #self._itemWidgets == 0 then return end
	if self._itemStride <= 0 then return end

	local cw, ch = self.transform:getSize()
	local visualOffset = -(self._scrollOffset % self._itemStride)

	for i, child in ipairs(self._itemWidgets) do
		local rx, ry, rw, rh
		if self._is_horizontal then
			local baseX = (i - 1) * self._itemStride
			rx, ry = baseX + visualOffset, 0
			rw, rh = self._itemSize, ch
		else
			local baseY = (i - 1) * self._itemStride
			rx, ry = 0, baseY + visualOffset
			rw, rh = cw, self._itemSize
		end
		self:fitChildInRect(child, rx, ry, rw, rh)
	end
end

--- VirtualList 的子控件最小尺寸 = 0（容器尺寸由父级 / anchor 决定）。
function VirtualList:_getChildrenMinSize()
	return 0, 0
end

--------------------------------------------------
-- 滚动条
--------------------------------------------------

function VirtualList:_getScrollbarRect()
	local gx, gy, gw, gh = self.transform:getGlobalAABB()
	local maxScroll = self:getMaxScroll()
	if maxScroll <= 0 then return nil end

	local totalSize = self._dataCount * self._itemStride - self.separation
	local viewport = self._is_horizontal and gw or gh

	if self._is_horizontal then
		local track_y = gy + gh - SB_WIDTH
		local track_w = gw
		local thumb_w = math.max(SB_MIN_LENGTH, (viewport / totalSize) * track_w)
		local thumb_x = gx + (self._scrollOffset / maxScroll) * (track_w - thumb_w)
		return {
			track_x = gx, track_y = track_y, track_w = track_w, track_h = SB_WIDTH,
			thumb_x = thumb_x, thumb_y = track_y, thumb_w = thumb_w, thumb_h = SB_WIDTH,
			max_scroll = maxScroll,
		}
	else
		local track_x = gx + gw - SB_WIDTH
		local track_h = gh
		local thumb_h = math.max(SB_MIN_LENGTH, (viewport / totalSize) * track_h)
		local thumb_y = gy + (self._scrollOffset / maxScroll) * (track_h - thumb_h)
		return {
			track_x = track_x, track_y = gy, track_w = SB_WIDTH, track_h = track_h,
			thumb_x = track_x, thumb_y = thumb_y, thumb_w = SB_WIDTH, thumb_h = thumb_h,
			max_scroll = maxScroll,
		}
	end
end

--- 判断屏幕坐标是否在滑块矩形内。
function VirtualList:_hitTestThumb(sb, mx, my)
	return mx >= sb.thumb_x and mx <= sb.thumb_x + sb.thumb_w
		and my >= sb.thumb_y and my <= sb.thumb_y + sb.thumb_h
end

--- 判断屏幕坐标是否在轨道矩形内。
function VirtualList:_hitTestTrack(sb, mx, my)
	return mx >= sb.track_x and mx <= sb.track_x + sb.track_w
		and my >= sb.track_y and my <= sb.track_y + sb.track_h
end

function VirtualList:_drawScrollbar()
	local sb = self:_getScrollbarRect()
	if not sb then return end

	love.graphics.setColor(unpack(SB_TRACK_COLOR))
	love.graphics.rectangle("fill", sb.track_x, sb.track_y, sb.track_w, sb.track_h)

	love.graphics.setColor(unpack(SB_THUMB_COLOR))
	love.graphics.rectangle("fill", sb.thumb_x, sb.thumb_y, sb.thumb_w, sb.thumb_h)
end

--------------------------------------------------
-- 输入事件
--------------------------------------------------

function VirtualList:onWheelMoved(x, y)
	local mx, my = love.mouse.getPosition()
	local gx, gy, gw, gh = self.transform:getGlobalAABB()
	if mx >= gx and mx <= gx + gw and my >= gy and my <= gy + gh then
		local delta = self._is_horizontal and -x or -y
		self:scrollTo(self._scrollOffset + delta * SCROLL_SPEED)
		return true
	end
	return false
end

function VirtualList:onMousePressed(x, y, button)
	if button ~= 1 then return false end

	local sb = self:_getScrollbarRect()
	if not sb then return false end

	local mx, my = love.mouse.getPosition()

	if self:_hitTestThumb(sb, mx, my) then
		self._sbDragging = true
		self._sbDragStartPos = self._is_horizontal and mx or my
		self._sbDragStartOffset = self._scrollOffset
		return true
	elseif self:_hitTestTrack(sb, mx, my) then
		-- 点击轨道空白区 → 跳转
		local track_len = self._is_horizontal and sb.track_w or sb.track_h
		local thumb_len = self._is_horizontal and sb.thumb_w or sb.thumb_h
		local click_pos = self._is_horizontal and mx or my
		local track_start = self._is_horizontal and sb.track_x or sb.track_y

		local ratio = (click_pos - track_start - thumb_len / 2) / math.max(1, track_len - thumb_len)
		ratio = math.max(0, math.min(1, ratio))
		self:scrollTo(ratio * sb.max_scroll)
		return true
	end
	return false
end

function VirtualList:onMouseMoved(x, y, dx, dy)
	if not self._sbDragging then return false end

	local sb = self:_getScrollbarRect()
	if not sb then
		self._sbDragging = false
		return false
	end

	local mx, my = love.mouse.getPosition()
	local cur_pos = self._is_horizontal and mx or my
	local track_len = self._is_horizontal and sb.track_w or sb.track_h
	local thumb_len = self._is_horizontal and sb.thumb_w or sb.thumb_h

	local d_screen = cur_pos - self._sbDragStartPos
	local d_content = d_screen / math.max(1, track_len - thumb_len) * sb.max_scroll
	self:scrollTo(self._sbDragStartOffset + d_content)
	return true
end

function VirtualList:onMouseReleased(x, y, button)
	if button == 1 and self._sbDragging then
		self._sbDragging = false
		return true
	end
	return false
end

--------------------------------------------------
-- 渲染钩子（scissor + 滚动条）
--------------------------------------------------

function VirtualList:onDraw()
	local gx, gy = self.transform:getGlobalPosition()
	local sx, sy = self.transform:getScaledSize()
	love.graphics.setScissor(gx, gy, sx, sy)
end

function VirtualList:onPostDraw()
	self:_drawScrollbar()
	love.graphics.setScissor()
end

return VirtualList
