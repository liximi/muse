--------------------------------------------------
-- TreeView — 层级树
-- 职责：展示被编辑 UI 的 widget 树，点击选中，三角形图标
--------------------------------------------------

local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local Image = require "ui.widgets.image"
local Button = require "ui.widgets.button"
local Scroll = require "ui.widgets.containers.scroll_container"
local Box = require "ui.widgets.containers.box_container"
local Utils = require "ui.utils"
local LEAF_TYPES = require "ui_editor.editor.widget_meta"

local uc = Utils.UI_COLORS
local BTN_STATES = Utils.BTN_STATES

local ROW_H = 22
local INDENT = 12
local GAP = 1
local ICON_SIZE = 8

--------------------------------------------------
-- 三角形图标纹理（惰性生成）
--------------------------------------------------

local _triangleDown = nil

local function makeTriangleTexture()
	local size = ICON_SIZE
	local id = love.image.newImageData(size, size)
	for y = 0, size - 1 do
		-- ▼: wide at top → narrow tip at bottom
		local progress = 1 - y / (size - 1)
		local w = 1 + progress * (size - 1)
		local left = (size - w) / 2
		for x = math.floor(left), math.floor(left + w) - 1 do
			if x >= 0 and x < size then
				id:setPixel(x, y, 0.55, 0.65, 0.75, 1)
			end
		end
	end
	return love.graphics.newImage(id)
end

local function getTriangleDown()
	if not _triangleDown then
		_triangleDown = makeTriangleTexture()
	end
	return _triangleDown
end

--------------------------------------------------
-- TreeView
--------------------------------------------------

local TreeView = Class(Widget, function(self, datas)
    Widget.new(self, "TreeView", datas)
    self.raycast_target = true

    self._edited_root = nil
    self._nodes = {}
    self._selected_widget = nil
    self._dirty = true

    self.onNodeSelected = nil    -- function(widget)
    self.onNodeDelete = nil      -- function(widget)

    self:_buildUI()
end)

function TreeView:_buildUI()
    -- 背景
    self:addChild(Panel({
        bg_color = {0.08, 0.08, 0.10, 1},
        rounding_radius = 0,
        anchor = {0, 0, 1, 1},
    }))

    self._header = self:addChild(Text({
        text = "Tree",
        font_size = 11,
        font_key = "default_bold",
        text_color = uc.HINT,
        h = 20,
        anchor = {0, 0, 1, 0},
        padding = {8, 8, 4, 0},
    }))

    self._scroll = self:addChild(Scroll({
        anchor = {0, 0, 1, 1},
        padding = {2, 2, 26, 2},
        enable_scroll_h = true,
        enable_scroll_v = true,
    }))

    self._list = Box({
        auto_size = true,
        anchor = {0, 0, 0, 0},
        separation = GAP,
    })
    self._scroll:setItem(self._list)
end

--------------------------------------------------
-- 数据
--------------------------------------------------

function TreeView:setEditedRoot(root_widget)
    self._edited_root = root_widget
    self._selected_widget = nil
    self._nodes = {}
    self._dirty = true
end

function TreeView:selectWidget(widget)
    local old = self._selected_widget
    self._selected_widget = widget
    self:_setNodeSelected(old, false)
    self:_setNodeSelected(widget, true)
end

--------------------------------------------------
-- 构建树节点
--------------------------------------------------

local function getNodeLabel(widget)
    return widget._mui_id or widget._name or widget:__tostring()
end

--- 递归计算最大嵌套深度
local function _maxDepth(widget, depth, is_leaf)
    local max_d = depth
    -- 非叶子类型：递归子节点
    if not is_leaf then
        for _, child in ipairs(widget.children) do
            if child:isShown() then
                local mui_type = child._mui_type or child._name
                local child_leaf = mui_type and LEAF_TYPES[mui_type]
                local d = _maxDepth(child, depth + 1, child_leaf)
                if d > max_d then max_d = d end
            end
        end
    else
        -- 叶子类型也递归用户子节点（带 _mui_type）
        for _, child in ipairs(widget.children) do
            if child:isShown() and child._mui_type then
                local mui_type = child._mui_type or child._name
                local child_leaf = mui_type and LEAF_TYPES[mui_type]
                local d = _maxDepth(child, depth + 1, child_leaf)
                if d > max_d then max_d = d end
            end
        end
    end
    return max_d
end

function TreeView:_rebuild()
    self._list:clearChildren()
    self._nodes = {}

    if not self._edited_root then return end

    -- 计算内容所需最小宽度
    local root_mui = self._edited_root._mui_type or self._edited_root._name
    local root_leaf = root_mui and LEAF_TYPES[root_mui]
    local max_depth = _maxDepth(self._edited_root, 0, root_leaf)
    local viewport_w = self.transform.w - 4
    local content_w = math.max(viewport_w, max_depth * INDENT + 100)
    self._list.transform:setSize(content_w, nil)
    self._scroll:setScrollableW(content_w)

    self:_addNode(self._edited_root, 0)
    self._dirty = false
end

--- 强制下次 update 重建（外部修改了 widget 树后调用）
function TreeView:markDirty()
    self._dirty = true
end

-- 所有树节点共用同一套 Button state_styles
local NODE_STYLES = {
    normal = Utils.newButtonStateStyle(
        nil, uc.PRIMARY_TEXT, 11, {0, 0, 0, 0}, 0, nil, nil, nil, 0),
    hover = Utils.newButtonStateStyle(
        nil, nil, nil, uc.BTN_HOVER, 0, nil, nil, nil, 4),
    selected = Utils.newButtonStateStyle(
        nil, uc.TITLE, nil, uc.BTN_SELECTED, 0, nil, nil, nil, 0),
    selected_hover = Utils.newButtonStateStyle(
        nil, nil, nil, uc.BTN_SELECTED_HOVER, 0, nil, nil, nil, 4),
}

function TreeView:_addNode(widget, depth)
    local label = getNodeLabel(widget)
    local mui_type = widget._mui_type or widget._name
    local is_leaf = mui_type and LEAF_TYPES[mui_type]

    -- 用户添加的子节点（带 _mui_type 标记）——叶子类型的内部子节点跳过
    local user_children = {}
    for _, child in ipairs(widget.children) do
        if child:isShown() and child._mui_type then
            user_children[#user_children + 1] = child
        end
    end
    -- 非叶子类型：全部可见子节点
    if not is_leaf then
        user_children = {}
        for _, child in ipairs(widget.children) do
            if child:isShown() then
                user_children[#user_children + 1] = child
            end
        end
    end
    local has_children = #user_children > 0

    local row = Widget({
        anchor = {0, 0, 1, 0},
        h = ROW_H,
    })
    row:setCustomMinimumSize(nil, ROW_H)

    -- 三角形图标
    local icon_x = depth * INDENT + 4
    if has_children then
        row:addChild(Image({
            texture = getTriangleDown(),
            anchor = {0, 0, 0, 0},
            padding = {icon_x, 0, (ROW_H - ICON_SIZE) / 2, 0},
            w = ICON_SIZE,
            h = ICON_SIZE,
        }))
    end

    -- 按钮（文本标签）
    local text_x = icon_x + ICON_SIZE + 4
    local btn = row:addChild(Button({
        normal = NODE_STYLES.normal,
        hover = NODE_STYLES.hover,
        selected = NODE_STYLES.selected,
        selected_hover = NODE_STYLES.selected_hover,
        anchor = {0, 0, 1, 0},
        padding = {text_x, 0, 0, 0},
        h = ROW_H,
        h_align = "left",
        text_padding = {4, 4, 2, 2},
        on_click = function()
            self:_onNodeClick(widget)
        end,
    }))
    btn:setText(label)

    -- 初始选中状态走 Button 内置 SELECTED 状态
    if widget == self._selected_widget then
        btn:setState(BTN_STATES.SELECTED)
    end

    self._list:addChild(row)
    table.insert(self._nodes, {widget = widget, btn = btn})

    -- 展开子节点
    for _, child in ipairs(user_children) do
        self:_addNode(child, depth + 1)
    end
end

--------------------------------------------------
-- 选中切换
--------------------------------------------------

function TreeView:_onNodeClick(widget)
    local old = self._selected_widget
    self._selected_widget = widget
    self:_setNodeSelected(old, false)
    self:_setNodeSelected(widget, true)

    if self.onNodeSelected then
        self.onNodeSelected(widget)
    end
end

--------------------------------------------------
-- 右键菜单
--------------------------------------------------

function TreeView:onMousePressed(x, y, button)
    if button ~= 1 then return end  -- 只处理左键；右键走 onMouseReleased
end

function TreeView:onMouseReleased(x, y, button)
    if button ~= 2 then return end  -- 右键
    if not self:regionDetection(x, y) then return end

    -- 在 _scroll 区域内检测命中的行
    if not self._scroll:regionDetection(x, y) then return end

    -- 遍历 nodes 的 row，检测命中
    for _, node in ipairs(self._nodes) do
        local row = node.btn.parent  -- btn → row Widget
        if row and row:regionDetection(x, y) then
            if self.onNodeDelete then
                self:onNodeDelete(node.widget)
            end
            return true
        end
    end
    return false
end

--- 利用 Button 内置 SELECTED 状态切换高亮，不重建控件
function TreeView:_setNodeSelected(widget, selected)
    if not widget then return end
    for _, node in ipairs(self._nodes) do
        if node.widget == widget then
            node.btn:setState(selected and BTN_STATES.SELECTED or BTN_STATES.NORMAL)
            break
        end
    end
end

--------------------------------------------------
-- 更新
--------------------------------------------------

function TreeView:onUpdate(dt)
    if self._dirty then
        self:_rebuild()
    end
end

return TreeView
