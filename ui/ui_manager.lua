
local Manager = Class(function(self)
	self.root_widgets = {}
end)


function Manager:AddRootWidget(widget)
	for _, v in ipairs(self.root_widgets) do
		if v == widget then
			return
		end
	end
	table.insert(self.root_widgets, widget)
	return widget
end


function Manager:Update(dt)
	for _, widget in ipairs(self.root_widgets) do
		widget:Update()
	end
end


function Manager:Draw()
	for _, widget in ipairs(self.root_widgets) do
		widget:Draw()
	end
end


function Manager:KeyPressed(key, isrepeat)
	for i = #self.root_widgets, 1, -1 do
		local widget = self.root_widgets[i]
		widget:HandleEvent("KeyPressed", key, isrepeat)
	end
end


function Manager:KeyReleased(key)
	for i = #self.root_widgets, 1, -1 do
		local widget = self.root_widgets[i]
		widget:HandleEvent("KeyReleased", key)
	end
end


function Manager:TextInput(text)
	for i = #self.root_widgets, 1, -1 do
		local widget = self.root_widgets[i]
		widget:HandleEvent("TextInput", text)
	end
end


function Manager:MouseMoved(x, y, dx, dy)
	for i = #self.root_widgets, 1, -1 do
		local widget = self.root_widgets[i]
		widget:HandleEvent("MouseMoved", x, y, dx, dy)
	end
end


function Manager:MousePressed(x, y, button, presses)
	for i = #self.root_widgets, 1, -1 do
		local widget = self.root_widgets[i]
		widget:HandleEvent("MousePressed", x, y, button, presses)
	end
end


function Manager:MouseReleased(x, y, button, presses)
	for i = #self.root_widgets, 1, -1 do
		local widget = self.root_widgets[i]
		widget:HandleEvent("MouseReleased", x, y, button, presses)
	end
end


function Manager:WheelMoved(x, y)
	for i = #self.root_widgets, 1, -1 do
		local widget = self.root_widgets[i]
		widget:HandleEvent("WheelMoved", x, y)
	end
end


return Manager