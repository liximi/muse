
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
	
end


function Manager:KeyReleased(key)
	
end


function Manager:TextInput(text)
	
end


function Manager:MouseMoved(x, y, dx, dy)
	
end


function Manager:MousePressed(x, y, button, presses)
	
end


function Manager:MouseReleased(x, y, button, presses)
	
end


function Manager:WheelMoved(x, y)
	
end


return Manager