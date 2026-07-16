--------------------------------------------------
-- TreeView — 层级树
-- 职责：展示被编辑 UI 的 widget 树，点击选中，双击编辑 id
--------------------------------------------------

local Widget = require "ui.widgets.widget"
local Text = require "ui.widgets.text"
local Button = require "ui.widgets.button"
local TextInput = require "ui.widgets.textinput"
local Scroll = require "ui.widgets.containers.scroll_container"
local Box = require "ui.widgets.containers.box_container"
local Utils = require "ui.utils"

local uc = Utils.UI_COLORS

local ROW_H = 22
local INDENT = 16
local GAP = 1

local TreeView = Class(Widget, function(self, datas)
    Widget.new(self, "TreeView", datas)
    self.raycast_target = true

    self._edited_root = nil        -- 被编辑的 UI 根
    self._nodes = {}               -- {widget, depth, label, btn} 当前显示节点
    self._selected_widget = nil    -- 当前 Tree 中选中的 widget
    self._editing_node = nil       -- 正在编辑 id 的节点
    self._dirty = true             -- 需要重建树显示

    -- 回调
    self.onNodeSelected = nil      -- function(widget) 节点被点击选中

    self:_buildUI()
end)

function TreeView:_buildUI()
    self._header = self:addChild(Text({
        text = "层级树",
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
        enable_scroll_h = false,
    }))

    self._list = Box({
        auto_size = true,
        anchor = {0, 0, 1, 0},
        separation = GAP,
    })
    self._scroll:setItem(self._list)
    self._scroll:setScrollableH(0)
end

--------------------------------------------------
-- 数据
--------------------------------------------------

function TreeView:setEditedRoot(root_widget)
    self._edited_root = root_widget
    self._dirty = true
end

-- 外部通知 TreeView 选中了某个 widget（从 Canvas 来）
function TreeView:selectWidget(widget)
    self._selected_widget = widget
end

--------------------------------------------------
-- 构建树节点
--------------------------------------------------

local function getNodeLabel(widget)
    local name = widget._mui_id or widget._name or widget:__tostring()
    return name
end

function TreeView:_rebuild()
    self._list:clearChildren()
    self._nodes = {}

    if not self._edited_root then return end

    self:_addNode(self._edited_root, 0)
    self._dirty = false
end

function TreeView:_addNode(widget, depth)
    local label = getNodeLabel(widget)
    local is_selected = (widget == self._selected_widget)

    local row = Widget({
        anchor = {0, 0, 1, 0},
        h = ROW_H,
    })
    row:setCustomMinimumSize(nil, ROW_H)

    -- 缩进 + 箭头（可展开标记）
    local indent_text = string.rep("    ", depth)
    if #widget.children > 0 then
        indent_text = indent_text .. "▾ "
    else
        indent_text = indent_text .. "  "
    end

    local btn = row:addChild(Button({
        normal = Utils.newButtonStateStyle(
            indent_text .. label,
            is_selected and uc.TITLE or uc.PRIMARY_TEXT,
            11,
            is_selected and uc.BTN_SELECTED or {0, 0, 0, 0},
            0, nil, nil, nil, 0),
        hover = Utils.newButtonStateStyle(
            nil, nil, nil,
            is_selected and uc.BTN_SELECTED_HOVER or uc.BTN_HOVER,
            0, nil, nil, nil, 4),
        anchor = {0, 0, 1, 0},
        h = ROW_H,
        h_align = "left",
        text_padding = {4, 4, 2, 2},
        on_click = function()
            self:_onNodeClick(widget)
        end,
    }))

    self._list:addChild(row)
    table.insert(self._nodes, {widget = widget, depth = depth, btn = btn})

    -- 递归子节点
    for _, child in ipairs(widget.children) do
        if child:isShown() then
            self:_addNode(child, depth + 1)
        end
    end
end

function TreeView:_onNodeClick(widget)
    self._selected_widget = widget
    if self.onNodeSelected then
        self.onNodeSelected(widget)
    end
    self._dirty = true  -- 刷新高亮
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
