local Utils = {
    ---@enum Utils.ANCHORS_HORI
    ANCHORS_HORI = {
        LEFT = "left",
        MIDDLE = "middle",
        RIGHT = "right",
    },
    ---@enum Utils.ANCHORS_VERT
    ANCHORS_VERT = {
        TOP = "top",
        MIDDLE = "middle",
        BOTTOM = "bottom",
    }
}


--- 构造颜色对象
---@param r number 红色通道的值 0~255
---@param g number 绿色通道的值 0~255
---@param b number 蓝色通道的值 0~255
---@param a number|nil 不透明度通道的值 0~1 默认为 1
function Utils.RGB(r, g, b, a)
    return {r / 255, g / 255, b / 255, a or 1}
end

Utils.UI_COLORS = {
    PRIMARY = Utils.RGB(3, 169, 244),   --原色
    DARK_PRIMARY = Utils.RGB(2, 136, 209),  --深原色
    LIGHT_PRIMARY = Utils.RGB(179, 229, 252),   --浅原色
    ACCENT = Utils.RGB(83, 109, 254),   --强调色
    TEXT = Utils.RGB(255, 255, 255),    --文本颜色
    ICONS = Utils.RGB(255, 255, 255),   --图标颜色
    PRIMARY_TEXT = Utils.RGB(33, 33, 33),   --主要文本颜色
    SECONDARY_TEXT = Utils.RGB(117, 117, 117),   --次要文本颜色
    DIVIDER = Utils.RGB(189, 189, 189), --分隔线颜色

    DEBUG1 = Utils.RGB(255, 70, 150),
    DEBUG2 = Utils.RGB(240, 255, 70),
}

Utils.BTN_STATES = {
    normal = "normal",
    pressed = "pressed",
    disabled = "disabled",
    seleted = "seleted",
    hover = "hover",
    seleted_hover = "seleted_hover"
}

return Utils
