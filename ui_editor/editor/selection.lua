--------------------------------------------------
-- Selection — 选中状态管理
-- 职责：跟踪当前选中的 widget，提供选中/取消/高亮绘制
--------------------------------------------------

local Utils = require "ui.utils"

local SELECTION_COLOR = {0.3, 0.6, 1.0, 0.6}   -- 选中框颜色
local SELECTION_WIDTH = 2                         -- 选中框线宽
local HANDLE_SIZE = 8                             -- 拖拽手柄边长（像素）
local HANDLE_COLOR = {1, 1, 1, 0.9}              -- 拖拽手柄颜色
local HANDLE_BORDER = {0.3, 0.6, 1.0, 1}         -- 拖拽手柄描边

local Selection = Class(function(self)
    self.widget = nil      -- 当前选中的 widget
    self._handles = {}     -- 8 个拖拽手柄的屏幕坐标 {x, y}
end)

-- 选中 widgets
function Selection:select(widget)
    if self.widget == widget then return end
    self.widget = widget
end

-- 取消选中
function Selection:deselect()
    self.widget = nil
    self._handles = {}
end

-- 是否有选中
function Selection:hasSelection()
    return self.widget ~= nil
end

-- 计算 8 个拖拽手柄的屏幕坐标
function Selection:_updateHandles()
    if not self.widget then
        self._handles = {}
        return
    end
    local ax, ay, aw, ah = self.widget.transform:getGlobalAABB()
    local half_h = HANDLE_SIZE / 2

    self._handles = {
        -- 4 角
        {x = ax - half_h,         y = ay - half_h},          -- 左上
        {x = ax + aw - half_h,    y = ay - half_h},          -- 右上
        {x = ax - half_h,         y = ay + ah - half_h},     -- 左下
        {x = ax + aw - half_h,    y = ay + ah - half_h},     -- 右下
        -- 4 边中点
        {x = ax + aw / 2 - half_h, y = ay - half_h},         -- 上
        {x = ax + aw / 2 - half_h, y = ay + ah - half_h},    -- 下
        {x = ax - half_h,          y = ay + ah / 2 - half_h}, -- 左
        {x = ax + aw - half_h,     y = ay + ah / 2 - half_h}, -- 右
    }
end

-- 绘制选中框 + 拖拽手柄
function Selection:draw()
    if not self.widget then return end

    self:_updateHandles()

    -- 使用 transform 的布局包围盒，不用 getCullAABB（Text 等会覆写返回内容尺寸）
    local ax, ay, aw, ah = self.widget.transform:getGlobalAABB()

    -- 选中框
    love.graphics.setColor(unpack(SELECTION_COLOR))
    love.graphics.setLineWidth(SELECTION_WIDTH)
    love.graphics.rectangle("line", ax, ay, aw, ah)
    love.graphics.setLineWidth(1)

    -- 拖拽手柄
    for _, h in ipairs(self._handles) do
        love.graphics.setColor(unpack(HANDLE_BORDER))
        love.graphics.rectangle("fill", h.x, h.y, HANDLE_SIZE, HANDLE_SIZE)
        love.graphics.setColor(unpack(HANDLE_COLOR))
        love.graphics.rectangle("fill", h.x + 1, h.y + 1, HANDLE_SIZE - 2, HANDLE_SIZE - 2)
    end
end

-- 检测屏幕坐标命中了哪个手柄（返回 1-8 或 nil）
function Selection:hitHandle(screen_x, screen_y)
    for i, h in ipairs(self._handles) do
        if screen_x >= h.x and screen_x <= h.x + HANDLE_SIZE
            and screen_y >= h.y and screen_y <= h.y + HANDLE_SIZE then
            return i
        end
    end
    return nil
end

return Selection
