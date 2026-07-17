--------------------------------------------------
-- Canvas — 设计画布
-- 职责：承载目标 UI、拦截鼠标/键盘事件实现选中、绘制选中覆盖层
--------------------------------------------------

local Widget = require "ui.widgets.widget"
local Selection = require "ui_editor.editor.selection"
local Utils = require "ui.utils"
local Fonts = require "ui.fonts"
local UiManager = require "ui.ui_manager":GetInstance()
local LEAF_TYPES = require "ui_editor.editor.widget_meta"

--------------------------------------------------
-- 设计模式下需要 Canvas 优先拦截的事件（其余事件走正常子节点优先传播）
--------------------------------------------------
local INTERCEPT_FIRST = {
    KeyPressed     = true,
    MousePressed   = true,
    MouseReleased  = true,
    MouseMoved     = true,
}

local MIN_WIDGET_SIZE = 10  -- 缩放最小尺寸约束

local Canvas = Class(Widget, function(self, datas)
    Widget.new(self, "Canvas", datas)
    self.raycast_target = true

    self.selection = Selection()
    self._edited_root = nil
    self._design_mode = true
    self.onSelectionChanged = nil
    -- 快捷键回调：function(key, ctrl) → boolean（返回 true 表示已处理，Canvas 不再处理）
    self.onShortcut = nil
    -- 操作前/后回调（撤销用）
    self.onBeforeModify = nil   -- function(widget)
    self.onAfterModify = nil    -- function(widget)

    -- 拖拽状态
    self._drag = nil  -- { type="move"|"resize", widget, start_lx, start_ly, ... }
end)

--------------------------------------------------
-- 被编辑 UI 的管理
--------------------------------------------------

function Canvas:setEditedRoot(root_widget)
    if self._edited_root then
        self:removeChild(self._edited_root)
    end
    self._edited_root = root_widget
    self:addChild(root_widget)
    self.selection:deselect()
end

function Canvas:getEditedRoot()
    return self._edited_root
end

--------------------------------------------------
-- 事件拦截
--
-- 设计模式：
--   KeyPressed / Mouse* → Canvas 优先处理（选中/导航），未消耗才传给子节点
--   TextInput / WheelMoved 等 → 正常子节点优先，Canvas 无 handler 则不拦截
--   进入设计模式时清除焦点，确保被编辑 UI 不会收到文本输入
-- 交互模式：
--   完全正常传播，子节点优先
--------------------------------------------------

function Canvas:handleEvent(event_type, ...)
    if not self:isOperational() then return end

    if self._design_mode and INTERCEPT_FIRST[event_type] then
        local handler = self["on" .. event_type]
        if handler and handler(self, ...) then
            return true
        end
    end

    -- 传播给子节点
    for i = #self.children, 1, -1 do
        if self.children[i]:handleEvent(event_type, ...) then
            return true
        end
    end

    -- 未被优先拦截的事件 / 交互模式：Canvas handler 兜底
    if not self._design_mode or not INTERCEPT_FIRST[event_type] then
        local handler = self["on" .. event_type]
        if handler and handler(self, ...) then
            return true
        end
    end

    return false
end

--------------------------------------------------
-- 命中检测
--------------------------------------------------

local function isAtomic(widget)
    local mui_type = widget._mui_type or widget._name
    return mui_type and LEAF_TYPES[mui_type]
end

-- 检测屏幕坐标是否落在 widget 的 transform 布局区域内（非内容区域）
local function hitTestTransform(widget, screen_x, screen_y)
    local ax, ay, aw, ah = widget.transform:getGlobalAABB()
    return screen_x >= ax and screen_x <= ax + aw
        and screen_y >= ay and screen_y <= ay + ah
end

function Canvas:_hitTest(widget, screen_x, screen_y)
    if not widget or not widget:isOperational() then
        return nil
    end

    local mui_type = widget._mui_type or widget._name
    local is_leaf = mui_type and LEAF_TYPES[mui_type]

    if is_leaf then
        -- 叶子类型：只递归用户添加的子节点（带 _mui_type），跳过内部实现子节点
        for i = #widget.children, 1, -1 do
            local child = widget.children[i]
            if child._mui_type then
                local hit = self:_hitTest(child, screen_x, screen_y)
                if hit then return hit end
            end
        end
    else
        -- 容器类型：递归全部子节点
        for i = #widget.children, 1, -1 do
            local hit = self:_hitTest(widget.children[i], screen_x, screen_y)
            if hit then return hit end
        end
    end

    if widget ~= self and hitTestTransform(widget, screen_x, screen_y) then
        return widget
    end
    return nil
end

function Canvas:_findWidgetAt(screen_x, screen_y)
    if not self._edited_root then return nil end
    return self:_hitTest(self._edited_root, screen_x, screen_y)
end

function Canvas:_getParentInTree(widget)
    if not widget or widget == self._edited_root then return nil end
    local parent = widget.parent
    if parent == self or parent == nil then return nil end
    return parent
end

--------------------------------------------------
-- 键盘事件
--------------------------------------------------

function Canvas:onKeyPressed(key, isrepeat)
    -- 快捷键回调优先（由外部注入，如编辑器级 Ctrl+Z/Y/S/N）
    local ctrl = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
    if self.onShortcut and self:onShortcut(key, ctrl) then
        return true
    end

    if key == "escape" then
        if self.selection:hasSelection() then
            self.selection:deselect()
            self:_notifySelection()
            return true
        end
    elseif key == "p" then
        local current = self.selection.widget
        if current then
            local parent = self:_getParentInTree(current)
            if parent then
                self.selection:select(parent)
                self:_notifySelection()
            end
        end
        return true
    elseif key == "e" then
        self._design_mode = not self._design_mode
        if self._design_mode then
            UiManager:clearFocus()
        else
            self.selection:deselect()
            self:_notifySelection()
        end
        return true
    end
    return false
end

--------------------------------------------------
-- 鼠标事件
--------------------------------------------------

function Canvas:onMousePressed(x, y, button)
    if button ~= 1 then return end
    if not self:regionDetection(x, y) then return end

    -- 优先检测手柄（缩放）
    if self.selection:hasSelection() then
        local handle = self.selection:hitHandle(x, y)
        if handle then
            self:_startResize(x, y, handle)
            return true
        end
    end

    local hit = self:_findWidgetAt(x, y)
    if hit then
        -- 如果点击的是已选中的 widget → 开始拖拽移动
        if hit == self.selection.widget then
            self:_startDrag(x, y)
            return true
        end
        self.selection:select(hit)
    else
        self.selection:deselect()
    end
    self:_notifySelection()
    return true
end

function Canvas:onMouseReleased(x, y, button)
    if button ~= 1 then return end
    if self._drag then
        self:_endDrag()
        return true
    end
    return false
end

function Canvas:onMouseMoved(x, y, dx, dy)
    if not self._drag then return false end

    local lx, ly = self.transform:screenToLocal(x, y)

    if self._drag.type == "move" then
        self:_updateDrag(lx, ly)
    elseif self._drag.type == "resize" then
        self:_updateResize(lx, ly)
    end
    return true
end

--------------------------------------------------
-- 拖拽移动
--------------------------------------------------

function Canvas:_startDrag(screen_x, screen_y)
    local lx, ly = self.transform:screenToLocal(screen_x, screen_y)
    local w = self.selection.widget
    local wx, wy = w.transform:getPosition()

    if self.onBeforeModify then self:onBeforeModify(w) end

    self._drag = {
        type = "move",
        widget = w,
        start_lx = lx,
        start_ly = ly,
        start_wx = wx,
        start_wy = wy,
    }
end

function Canvas:_updateDrag(lx, ly)
    local d = self._drag
    local dx = lx - d.start_lx
    local dy = ly - d.start_ly
    d.widget.transform:setPosition(d.start_wx + dx, d.start_wy + dy)
end

--------------------------------------------------
-- 手柄缩放
--------------------------------------------------

-- 获取 widget 在 Canvas 本地坐标系中的 AABB
local function getLocalAABB(widget)
    local pix, piy = widget.transform:getPivot()
    local wx, wy = widget.transform:getPosition()
    local ww, wh = widget.transform:getSize()
    return wx - ww * pix, wy - wh * piy, ww, wh
end

-- 根据 local AABB + delta + handle_idx 计算新的 position + size
local function applyResizeDelta(aabb_x, aabb_y, aabb_w, aabb_h, dx, dy, handle_idx)
    -- handle: 1=TL 2=TR 3=BL 4=BR 5=T 6=B 7=L 8=R
    local new_x, new_y = aabb_x, aabb_y
    local new_w, new_h = aabb_w, aabb_h

    if handle_idx == 1 or handle_idx == 3 or handle_idx == 7 then -- left edge
        new_x = aabb_x + dx
        new_w = aabb_w - dx
    end
    if handle_idx == 1 or handle_idx == 2 or handle_idx == 5 then -- top edge
        new_y = aabb_y + dy
        new_h = aabb_h - dy
    end
    if handle_idx == 2 or handle_idx == 4 or handle_idx == 8 then -- right edge
        new_w = aabb_w + dx
    end
    if handle_idx == 3 or handle_idx == 4 or handle_idx == 6 then -- bottom edge
        new_h = aabb_h + dy
    end

    -- min size 约束
    if new_w < MIN_WIDGET_SIZE then
        new_w = MIN_WIDGET_SIZE
        if handle_idx == 1 or handle_idx == 3 or handle_idx == 7 then
            new_x = aabb_x + aabb_w - MIN_WIDGET_SIZE
        end
    end
    if new_h < MIN_WIDGET_SIZE then
        new_h = MIN_WIDGET_SIZE
        if handle_idx == 1 or handle_idx == 2 or handle_idx == 5 then
            new_y = aabb_y + aabb_h - MIN_WIDGET_SIZE
        end
    end

    return new_x, new_y, new_w, new_h
end

function Canvas:_startResize(screen_x, screen_y, handle_idx)
    local lx, ly = self.transform:screenToLocal(screen_x, screen_y)
    local w = self.selection.widget
    local ax, ay, aw, ah = getLocalAABB(w)

    if self.onBeforeModify then self:onBeforeModify(w) end

    self._drag = {
        type = "resize",
        widget = w,
        handle = handle_idx,
        start_lx = lx,
        start_ly = ly,
        start_ax = ax,
        start_ay = ay,
        start_aw = aw,
        start_ah = ah,
    }
end

function Canvas:_updateResize(lx, ly)
    local d = self._drag
    local dx = lx - d.start_lx
    local dy = ly - d.start_ly

    local new_ax, new_ay, new_aw, new_ah =
        applyResizeDelta(d.start_ax, d.start_ay, d.start_aw, d.start_ah, dx, dy, d.handle)

    local pix, piy = d.widget.transform:getPivot()
    local new_x = new_ax + new_aw * pix
    local new_y = new_ay + new_ah * piy

    d.widget.transform:setPosition(new_x, new_y)
    d.widget.transform:setSize(new_aw, new_ah)
end

--------------------------------------------------
-- 拖拽结束
--------------------------------------------------

function Canvas:_endDrag()
    local widget = self._drag.widget
    self._drag = nil
    if self.onAfterModify then self:onAfterModify(widget) end
end

--------------------------------------------------
-- 锚点可视化
--------------------------------------------------

function Canvas:_drawAnchorGizmo()
    local widget = self.selection.widget
    if not widget then return end

    local parent = widget.parent
    if not parent or parent == self then
        parent = self
    end

    -- 父容器的屏幕空间包围盒
    local ptx, pty, ptw, pth = parent.transform:getGlobalBounds()
    if ptw <= 0 or pth <= 0 then return end

    local amin1, amin2, amax1, amax2 = widget.transform:getAnchor()
    local ax1 = ptx + ptw * amin1
    local ay1 = pty + pth * amin2
    local ax2 = ptx + ptw * amax1
    local ay2 = pty + pth * amax2

    local is_point = math.abs(ax1 - ax2) < 2 and math.abs(ay1 - ay2) < 2
    local r = 5

    if is_point then
        -- 点锚点：十字准星
        love.graphics.setColor(0.2, 0.85, 0.9, 0.9)
        love.graphics.setLineWidth(2)
        love.graphics.line(ax1 - r, ay1, ax1 + r, ay1)
        love.graphics.line(ax1, ay1 - r, ax1, ay1 + r)
        love.graphics.setColor(0.1, 0.3, 0.4, 0.9)
        love.graphics.circle("line", ax1, ay1, r)
        love.graphics.setLineWidth(1)
    else
        -- 拉伸锚点：四角小方块
        local sz = 5
        local corners = {
            {ax1, ay1}, {ax2, ay1}, {ax1, ay2}, {ax2, ay2},
        }
        for _, c in ipairs(corners) do
            love.graphics.setColor(0.2, 0.85, 0.9, 0.9)
            love.graphics.rectangle("fill", c[1] - sz, c[2] - sz, sz * 2, sz * 2)
            love.graphics.setColor(0.1, 0.3, 0.4, 0.9)
            love.graphics.rectangle("line", c[1] - sz, c[2] - sz, sz * 2, sz * 2)
        end
        -- 锚点范围虚线框
        love.graphics.setColor(0.2, 0.85, 0.9, 0.35)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", ax1, ay1, ax2 - ax1, ay2 - ay1)
    end

    -- 支点（pivot）小圆点
    local wx, wy = widget.transform:getGlobalPosition()
    love.graphics.setColor(1, 0.8, 0.2, 0.9)
    love.graphics.circle("fill", wx, wy, 3)
    love.graphics.setColor(0.5, 0.35, 0, 0.9)
    love.graphics.circle("line", wx, wy, 3)
end

--------------------------------------------------
-- 内部
--------------------------------------------------

function Canvas:_notifySelection()
    if self.onSelectionChanged then
        self.onSelectionChanged(self.selection.widget)
    end
end

--------------------------------------------------
-- 绘制
--------------------------------------------------

function Canvas:onDraw()
    local cx, cy, cw, ch = self.transform:getGlobalBounds()

    -- 画布背景（比编辑器底色略深，区分画布区域）
    love.graphics.setColor(0.06, 0.06, 0.09, 1)
    love.graphics.rectangle("fill", cx, cy, cw, ch)

    -- 画布边框
    love.graphics.setColor(0.18, 0.18, 0.22, 1)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", cx + 0.5, cy + 0.5, cw - 1, ch - 1)

    -- 裁剪：防止子控件绘制溢出到侧边栏 / 工具栏
    love.graphics.push("all")
    love.graphics.setScissor(cx, cy, cw, ch)
    self._clip_rect = {cx, cy, cw, ch}
end

function Canvas:onPostDraw()
    -- 选中框 + 锚点 gizmo（scissor 内，不溢出）
    if self._design_mode and self.selection:hasSelection() then
        self.selection:draw()
        self:_drawAnchorGizmo()
    end

    -- 底部模式指示标签
    local prev_font = love.graphics.getFont()
    local cx, cy, cw, ch = self.transform:getGlobalBounds()
    local label = self._design_mode
        and "[Design]  E=Play  P=Parent  Esc=Deselect"
        or  "[Play]  E=Design"
    local font = Fonts:getFont("default", 11)
    love.graphics.setFont(font)
    love.graphics.setColor(0.3, 0.6, 1.0, 0.5)
    love.graphics.print(label, cx + 6, cy + ch - 16)
    love.graphics.setFont(prev_font)

    -- 恢复裁剪
    love.graphics.pop()
    self._clip_rect = nil
end

return Canvas
