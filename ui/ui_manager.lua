local Theme = require "ui.theme"

local Manager = Class(function(self)
	self.hierarchy = {}
	self.default_theme = Theme()
end)


function Manager:addWidget(widget)
	assert(widget.parent == nil, "Cannot use a Widget with a parent as the root")
	for _, v in ipairs(self.hierarchy) do
		if v == widget then
			return widget
		end
	end
	table.insert(self.hierarchy, widget)
	return widget
end


function Manager:moveToTop(widget)
	for k, v in ipairs(self.hierarchy) do
		if v == widget then
			table.remove(self.hierarchy, k)
			table.insert(self.hierarchy, widget)
			break
		end
	end
end


function Manager:moveToBottom(widget)
	for k, v in ipairs(self.hierarchy) do
		if v == widget then
			table.remove(self.hierarchy, k)
			table.insert(self.hierarchy, 1, widget)
			break
		end
	end
end


function Manager:getDefaultTheme()
	return self.default_theme
end


function Manager:setDefaultTheme(theme)
	self.default_theme = theme
	return theme
end


--------------------------------------------------
-- Event Handlers
--------------------------------------------------

function Manager:update(dt)
	for _, widget in ipairs(self.hierarchy) do
		widget:update(dt)
	end
end


function Manager:draw()
	for _, widget in ipairs(self.hierarchy) do
		widget:draw()
	end
end


function Manager:KeyPressed(key, isrepeat)
	for i = #self.hierarchy, 1, -1 do
		local widget = self.hierarchy[i]
		widget:handleEvent("KeyPressed", key, isrepeat)
	end
end


function Manager:KeyReleased(key)
	for i = #self.hierarchy, 1, -1 do
		local widget = self.hierarchy[i]
		widget:handleEvent("KeyReleased", key)
	end
end


function Manager:TextInput(text)
	for i = #self.hierarchy, 1, -1 do
		local widget = self.hierarchy[i]
		widget:handleEvent("TextInput", text)
	end
end


function Manager:MouseMoved(x, y, dx, dy)
	for i = #self.hierarchy, 1, -1 do
		local widget = self.hierarchy[i]
		widget:handleEvent("MouseMoved", x, y, dx, dy)
	end
end


function Manager:MousePressed(x, y, button)
	for i = #self.hierarchy, 1, -1 do
		local widget = self.hierarchy[i]
		widget:handleEvent("MousePressed", x, y, button)
	end
end


function Manager:MouseReleased(x, y, button)
	for i = #self.hierarchy, 1, -1 do
		local widget = self.hierarchy[i]
		widget:handleEvent("MouseReleased", x, y, button)
	end
end


function Manager:WheelMoved(x, y)
	for i = #self.hierarchy, 1, -1 do
		local widget = self.hierarchy[i]
		widget:handleEvent("WheelMoved", x, y)
	end
end


return {
	__instance = nil,
	GetInstance = function(self)
		if not self.__instance then
			self.__instance = Manager()
		end
		return self.__instance
	end
}