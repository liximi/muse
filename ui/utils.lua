local Utils = {}


--- 构造颜色对象
---@param r number 红色通道的值 0~255
---@param g number 绿色通道的值 0~255
---@param b number 蓝色通道的值 0~255
---@param a number|nil 透明度通道的值 0~1 默认为 1
function Utils.RGB(r, g, b, a)
	return {r/255, g/255, b/255, a or 1}
end


return Utils