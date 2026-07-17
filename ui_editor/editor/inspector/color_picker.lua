--------------------------------------------------
-- color_picker.lua — HSV 选色器
-- 所有鼠标交互统一由 popup 分发，避免子 widget 事件竞争
--------------------------------------------------

local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local UiManager = require "ui.ui_manager"
local Utils = require "ui.utils"

local uc = Utils.UI_COLORS
local SV_SIZE, HUE_W, ALPHA_H = 140, 16, 16
local HANDLE_R = 5

--------------------------------------------------
-- HSV ↔ RGB
--------------------------------------------------
local function hsv2rgb(h, s, v)
	if s <= 0 then return v, v, v end
	h = (h % 1) * 6
	local i = math.floor(h); local f = h - i
	local p = v * (1 - s); local q = v * (1 - f * s); local t = v * (1 - (1 - f) * s)
	if i == 0 then return v, t, p
	elseif i == 1 then return q, v, p
	elseif i == 2 then return p, v, t
	elseif i == 3 then return p, q, v
	elseif i == 4 then return t, p, v
	else return v, p, q end
end

local function rgb2hsv(r, g, b)
	local mx, mn = math.max(r, g, b), math.min(r, g, b); local d = mx - mn
	local h = 0
	if d > 0 then
		if mx == r then h = ((g - b) / d) % 6
		elseif mx == g then h = (b - r) / d + 2
		else h = (r - g) / d + 4 end
		h = h / 6
	end
	return h % 1, mx > 0 and (d / mx) or 0, mx
end

--------------------------------------------------
-- 渐变 Canvas
--------------------------------------------------
local _svCache = {}
local function makeSVCanvas(hue)
	local k = math.floor(hue * 100)
	if _svCache[k] then return _svCache[k] end
	local c = love.graphics.newCanvas(SV_SIZE, SV_SIZE)
	local prev = love.graphics.getCanvas()
	love.graphics.setCanvas(c); love.graphics.clear(0,0,0,0)
	for y = 0, SV_SIZE - 1 do for x = 0, SV_SIZE - 1 do
		local r, g, b = hsv2rgb(hue, x/(SV_SIZE-1), 1 - y/(SV_SIZE-1))
		love.graphics.setColor(r,g,b); love.graphics.points(x, y)
	end end
	love.graphics.setCanvas(prev); _svCache[k] = c; return c
end

local _hueCanvas = nil
local function makeHueCanvas()
	if _hueCanvas then return _hueCanvas end
	local c = love.graphics.newCanvas(HUE_W, SV_SIZE)
	local prev = love.graphics.getCanvas()
	love.graphics.setCanvas(c); love.graphics.clear(0,0,0,0)
	for y = 0, SV_SIZE - 1 do
		local r, g, b = hsv2rgb(1 - y/(SV_SIZE-1), 1, 1)
		love.graphics.setColor(r,g,b); love.graphics.line(0, y, HUE_W, y)
	end
	love.graphics.setCanvas(prev); _hueCanvas = c; return c
end

--------------------------------------------------
-- 绘制辅助
--------------------------------------------------
-- 区域定义（相对于面板左上角）
local function svRect(px, py) return px+8, py+8, SV_SIZE, SV_SIZE end
local function hueRect(px, py) return px+8+SV_SIZE+4, py+8, HUE_W, SV_SIZE end
local function alphaRect(px, py) return px+8, py+8+SV_SIZE+4, SV_SIZE+HUE_W+4, ALPHA_H end

local function ptInRect(mx, my, rx, ry, rw, rh)
	return mx >= rx and mx <= rx + rw and my >= ry and my <= ry + rh
end

--------------------------------------------------
-- 主入口
--------------------------------------------------
local function showPicker(swatch_widget, getter, setter, onChangeHook)
	if onChangeHook then onChangeHook() end

	local cur = getter()
	local cr, cg, cb_, ca = cur[1] or 0.5, cur[2] or 0.5, cur[3] or 0.5, cur[4] or 1
	local h, s, v = rgb2hsv(cr, cg, cb_)

	local popup = Widget({ anchor={0,0,1,1}, padding={0,0,0,0}, raycast_target=true })
	popup.render_layer = Utils.RENDER_LAYERS.DROPDOWN

	local swx, swy = swatch_widget.transform:getGlobalPosition()
	local _, swh = swatch_widget.transform:getGlobalScaledSize()
	local pw, ph = SV_SIZE + HUE_W + 4 + 24, SV_SIZE + ALPHA_H + 40
	local px = math.min(swx, love.graphics.getWidth() - pw - 8)
	local py = math.min(swy + swh + 4, love.graphics.getHeight() - ph - 8)

	-- 面板背景
	popup:addChild(Panel({
		bg_color={0.14,0.14,0.17,1}, outline_width=1, outline_color=uc.LINE,
		rounding_radius=6, anchor={0,0,0,0}, padding={px,0,py,0}, w=pw, h=ph,
	}))

	-- 预览色块
	local by = py + 8 + SV_SIZE + 4 + ALPHA_H + 4
	local preview = popup:addChild(Panel({
		bg_color={cr,cg,cb_,ca}, outline_width=1, outline_color=uc.LINE,
		rounding_radius=3, anchor={0,0,0,0}, padding={px+8,0,by,0}, w=24, h=24,
	}))
	local hex = popup:addChild(Text({
		text="", font_size=11, text_color=uc.PRIMARY_TEXT,
		anchor={0,0,0,0}, padding={px+8+24+6,0,by+4,0},
	}))

	-- === 状态 ===
	local st = {
		h=h, s=s, v=v, ca=ca, cr=cr, cg=cg, cb=cb_,
		sv_tex=makeSVCanvas(h), hue_tex=makeHueCanvas(),
		drag=nil, -- "sv" | "hue" | "alpha" | nil
	}

	-- === 内部函数 ===
	local function updateColor()
		local r, g, b = hsv2rgb(st.h, st.s, st.v)
		st.cr, st.cg, st.cb = r, g, b
		preview.bg_color = {r, g, b, st.ca}
		hex:setText(string.format("#%02X%02X%02X  α=%.0f%%",
			math.floor(r*255+0.5), math.floor(g*255+0.5), math.floor(b*255+0.5), st.ca*100))
		setter({r, g, b, st.ca})
	end

	local function handleSV(mx, my)
		local rx, ry, rw, rh = svRect(px, py)
		st.s = math.max(0, math.min(1, (mx - rx) / rw))
		st.v = math.max(0, math.min(1, 1 - (my - ry) / rh))
		updateColor()
	end

	local function handleHue(mx, my)
		local _, ry, _, rh = hueRect(px, py)
		st.h = 1 - math.max(0, math.min(1, (my - ry) / rh))
		st.sv_tex = makeSVCanvas(st.h)
		updateColor()
	end

	local function handleAlpha(mx, my)
		local rx, _, rw = alphaRect(px, py)
		st.ca = math.max(0, math.min(1, (mx - rx) / rw))
		updateColor()
	end

	-- === 绘制层（纯显示，不参与事件）===
	local draw_layer = popup:addChild(Widget({ anchor={0,0,0,0}, padding={0,0,0,0}, w=0, h=0 }))
	draw_layer.raycast_target = false

	function draw_layer.onDraw(self)
		-- SV 渐变
		local svx, svy = svRect(px, py)
		love.graphics.setColor(1,1,1,1)
		love.graphics.draw(st.sv_tex, svx, svy)
		local hx = svx + st.s * SV_SIZE
		local hy = svy + (1 - st.v) * SV_SIZE
		love.graphics.setColor(1,1,1,1); love.graphics.circle("line", hx, hy, HANDLE_R)
		love.graphics.setColor(0,0,0,1); love.graphics.circle("line", hx, hy, HANDLE_R+1)
		love.graphics.setColor(1,1,1,1); love.graphics.circle("line", hx, hy, HANDLE_R-1)

		-- 色相条
		local huex, huey = hueRect(px, py)
		love.graphics.setColor(1,1,1,1)
		love.graphics.draw(st.hue_tex, huex, huey)
		local hy2 = huey + (1 - st.h) * SV_SIZE
		love.graphics.setColor(1,1,1,1); love.graphics.rectangle("fill", huex-2, hy2-1, HUE_W+4, 3)
		love.graphics.setColor(0,0,0,1); love.graphics.rectangle("line", huex-2, hy2-1, HUE_W+4, 3)

		-- Alpha 条
		local ax, ay, aw, ah = alphaRect(px, py)
		local r, g, b = hsv2rgb(st.h, st.s, st.v)
		for bx = 0, aw-1, 4 do for by_ = 0, ah-1, 4 do
			local vv = ((bx/4)+(by_/4))%2==0 and 0.55 or 0.38
			love.graphics.setColor(vv,vv,vv); love.graphics.rectangle("fill", ax+bx, ay+by_, 4, 4)
		end end
		for x = 0, aw-1 do
			love.graphics.setColor(r, g, b, x/(aw-1)); love.graphics.line(ax+x, ay, ax+x, ay+ah)
		end
		local axp = ax + st.ca * aw
		love.graphics.setColor(1,1,1,1); love.graphics.line(axp, ay-2, axp, ay+ah+2)
		love.graphics.setColor(0,0,0,0.6)
		love.graphics.line(axp-1, ay-2, axp-1, ay+ah+2); love.graphics.line(axp+1, ay-2, axp+1, ay+ah+2)
	end

	-- === 关闭逻辑（必须在 onMousePressed 之前定义！）===
	popup._closed = false
	local function close()
		if popup._closed then return end
		popup._closed = true
		setter({st.cr, st.cg, st.cb, st.ca})
		popup:hide(); popup._destroy = true
	end

	-- === 统一鼠标处理（在 popup 层，子 widget 不参与事件）===
	function popup.onMousePressed(self, mx, my, btn)
		if btn ~= 1 then return false end

		if ptInRect(mx, my, svRect(px, py)) then
			st.drag = "sv"; handleSV(mx, my); return true
		elseif ptInRect(mx, my, hueRect(px, py)) then
			st.drag = "hue"; handleHue(mx, my); return true
		elseif ptInRect(mx, my, alphaRect(px, py)) then
			st.drag = "alpha"; handleAlpha(mx, my); return true
		elseif ptInRect(mx, my, px, py, pw, ph) then
			return true -- 点面板内非交互区，吞掉事件但不做任何事
		end
		-- 面板外 → 关闭
		close()
		return true
	end

	function popup.onMouseMoved(self, mx, my, dx, dy)
		if st.drag == "sv" then handleSV(mx, my); return true
		elseif st.drag == "hue" then handleHue(mx, my); return true
		elseif st.drag == "alpha" then handleAlpha(mx, my); return true
		end
		return false
	end

	function popup.onMouseReleased(self, mx, my, btn)
		st.drag = nil; return true
	end

	-- === 初始化 ===
	updateColor()

	function popup.onUpdate(self, dt)
		if self._destroy then UiManager:GetInstance():removeWidget(self) end
	end

	UiManager:GetInstance():addWidget(popup)
	return popup
end

return { showPicker = showPicker }
