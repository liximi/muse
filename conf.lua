function love.conf(t)
	t.window.title = "UI Test"
	t.window.width = 1280
	t.window.height = 720
	t.window.resizable = true
	t.window.minwidth = 640
	t.window.minheight = 360
	t.window.msaa = 4
	t.window.vsync = 0

	t.modules.joystick = false
	t.modules.physics = false
end