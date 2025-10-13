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
    WHITE = Utils.RGB(220, 220, 220),
    BLACK = Utils.RGB(37, 37, 37),
    PRIMARY_TEXT = Utils.RGB(220, 220, 220),   --主要文本颜色
    SECONDARY_TEXT = Utils.RGB(120, 120, 120),   --次要文本颜色

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
