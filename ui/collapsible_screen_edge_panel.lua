local Lf = require "dependencies.loveframes"
local Tween = require "dependencies.tween"

local Panel = Class(function(self, width)
    self.open = true
	self.width = width

    self.panel = Lf.Create("panel")
    self.panel:SetSize(width, love.graphics.getHeight())
    self.panel:SetPos(0, 0)

	self.tween = nil
    function self.panel.Update(_self, dt)
		self.panel:SetSize(width, love.graphics.getHeight())
		if self.tween then
			if self.tween:update(dt) then
				self.tween = nil
			end
		end
    end

    self.collapse_btn = Lf.Create("imagebutton", self.panel)
    self.collapse_btn:SetImage("assets/ui/TablerLayoutSidebarLeftCollapseFilled.png")
    self.collapse_btn:SetText("")
    self.collapse_btn.scalex = 1 / 28
    self.collapse_btn.scaley = 1 / 28
    self.collapse_btn:SetPos(width - 5 - self.collapse_btn:GetImageWidth() / 28, 5)

    function self.collapse_btn.OnClick(_self, x, y)
        self:ToggleOpen()
    end

end)

function Panel:ToggleOpen()
    self.open = not self.open
    if self.tween then
        self.tween:reset()
    end
	self.tween = self.open and Tween.new(0.3, self.panel, {x = 0}, "outQuint") or Tween.new(0.3, self.panel, {x = -self.width + 26}, "inQuint")
	self.collapse_btn:SetImage(self.open and "assets/ui/TablerLayoutSidebarLeftCollapseFilled.png" or "assets/ui/TablerLayoutSidebarRightCollapseFilled.png")
end

return Panel
