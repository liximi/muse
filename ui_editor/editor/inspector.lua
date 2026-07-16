--------------------------------------------------
-- Inspector — 属性面板
-- 职责：显示选中 widget 的属性，实时编辑
--------------------------------------------------

local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local TextInput = require "ui.widgets.textinput"
local Button = require "ui.widgets.button"
local Box = require "ui.widgets.containers.box_container"
local Scroll = require "ui.widgets.containers.scroll_container"
local Utils = require "ui.utils"

local uc = Utils.UI_COLORS

local ROW_H = 28
local LABEL_W = 72
local GAP = 4

local Inspector = Class(Widget, function(self, datas)
    Widget.new(self, "Inspector", datas)
    self.raycast_target = true
    self._target = nil     -- 当前被检视的 widget
    self._rows = {}        -- {label widget, input widget} 用于动态更新
    self._dirty = false    -- 需要重建控件

    self:_buildUI()
end)

--------------------------------------------------
-- UI 构建
--------------------------------------------------

function Inspector:_buildUI()
    -- 标题
    self._header = self:addChild(Text({
        text = "Inspector",
        font_size = 13,
        font_key = "default_bold",
        text_color = uc.HINT,
        h = 24,
        anchor = {0, 0, 1, 0},
        padding = {12, 12, 8, 0},
    }))

    -- 类型 + id 标签
    self._type_label = self:addChild(Text({
        text = "无选中",
        font_size = 12,
        text_color = uc.SECONDARY_TEXT,
        h = 18,
        anchor = {0, 0, 1, 0},
        padding = {12, 12, 36, 0},
    }))

    -- 可滚动属性列表
    self._scroll = self:addChild(Scroll({
        anchor = {0, 0, 1, 1},
        padding = {4, 4, 58, 4},
        enable_scroll_h = false,
    }))

    self._form = Box({
        auto_size = true,
        anchor = {0, 0, 1, 0},
        separation = GAP,
    })
    self._scroll:setItem(self._form)
    self._scroll:setScrollableH(0)
end

--------------------------------------------------
-- 检视目标
--------------------------------------------------

-- 设置检视目标 widget，nil 表示清空
function Inspector:inspect(widget)
    self._target = widget
    self._dirty = true
end

--------------------------------------------------
-- 属性行工厂
--------------------------------------------------

local function makeRow(label_text, value_str, on_change)
    local row = Widget({
        anchor = {0, 0, 1, 0},
        h = ROW_H,
    })
    row:setCustomMinimumSize(nil, ROW_H)

    local lbl = row:addChild(Text({
        text = label_text,
        font_size = 11,
        text_color = uc.SECONDARY_TEXT,
        v_align = "center",
        anchor = {0, 0, 0, 0},
        w = LABEL_W,
        h = ROW_H,
        padding = {12, 0, 0, 0},
    }))

    -- 先声明变量，再赋值，避免闭包内引用自身赋值语句的 forward reference
    local input
    input = row:addChild(TextInput({
        text = value_str,
        font_size = 11,
        text_color = uc.PRIMARY_TEXT,
        single_line = true,
        anchor = {0, 0, 0, 0},
        w = 130,
        h = 22,
        padding = {LABEL_W + 12, 0, (ROW_H - 22) / 2, 0},
        on_submit = function()
            if on_change then on_change(input:getText()) end
        end,
    }))

    return row, input
end

-- 将数字四舍五入到 2 位小数显示
local function fmt(n)
    if n == nil then return "" end
    if type(n) == "number" then
        if n == math.floor(n) then return tostring(n) end
        return string.format("%.2f", n)
    end
    return tostring(n)
end

--------------------------------------------------
-- 重建属性行
--------------------------------------------------

function Inspector:_rebuild()
    self._form:clearChildren()
    self._rows = {}

    if not self._target then
        self._type_label:setText("无选中")
        return
    end

    local target = self._target
    local name = target._name or target._mui_id or target:__tostring()
    self._type_label:setText(name)

    -- 读取当前 transform 值
    local w, h = target.transform:getSize()
    local am1, am2, am3, am4 = target.transform:getAnchor()
    local pv1, pv2 = target.transform:getPivot()
    local pad = target.transform:getPadding()

    -- 定义属性行：label, getter, setter, formatter
    local fields = {
        {label = "宽度", get = function() return fmt(w) end,
            set = function(v) target.transform:setSize(tonumber(v), nil) end},
        {label = "高度", get = function() return fmt(h) end,
            set = function(v) target.transform:setSize(nil, tonumber(v)) end},
        {label = "锚点 X", get = function() return fmt(am1) .. ", " .. fmt(am3) end,
            set = function(v) -- TODO: parse two numbers
            end},
        {label = "锚点 Y", get = function() return fmt(am2) .. ", " .. fmt(am4) end,
            set = function(v) -- TODO: parse two numbers
            end},
        {label = "左间距", get = function() return fmt(pad.left) end,
            set = function(v) target.transform:setPadding(tonumber(v), nil, nil, nil) end},
        {label = "右间距", get = function() return fmt(pad.right) end,
            set = function(v) target.transform:setPadding(nil, tonumber(v), nil, nil) end},
        {label = "上间距", get = function() return fmt(pad.top) end,
            set = function(v) target.transform:setPadding(nil, nil, tonumber(v), nil) end},
        {label = "下间距", get = function() return fmt(pad.bottom) end,
            set = function(v) target.transform:setPadding(nil, nil, nil, tonumber(v)) end},
    }

    for _, f in ipairs(fields) do
        local row, input = makeRow(f.label, f.get(), f.set)
        self._form:addChild(row)
        table.insert(self._rows, {input = input, getter = f.get})
    end
end

--------------------------------------------------
-- 更新
--------------------------------------------------

function Inspector:onUpdate(dt)
    if self._dirty then
        self:_rebuild()
        self._dirty = false
    end

    -- 持续刷新显示值（部分属性可能被外部修改）
    if self._target then
        for _, entry in ipairs(self._rows) do
            local current = entry.getter()
            if entry.input:getText() ~= current then
                -- 只在输入框未聚焦时刷新，避免覆盖用户正在编辑的内容
                if not entry.input:isFocus() then
                    entry.input:setText(current)
                end
            end
        end
    end
end

return Inspector
