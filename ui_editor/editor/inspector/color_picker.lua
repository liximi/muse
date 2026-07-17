--------------------------------------------------
-- color_picker.lua — HSV 选色器
-- 点击色块弹出：SV 方形渐变 + 拖拽十字准星 + 色相条 + Alpha 条
--------------------------------------------------

local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local UiManager = require "ui.ui_manager"
local Utils = require "ui.utils"

local uc = Utils.UI_COLORS

local SV_SIZE = 140
local HUE_W = 16
local ALPHA_H = 16
local HANDLE_R = 5

--------------------------------------------------
-- HSV ↔ RGB 转换
--------------------------------------------------
local function hsv2rgb(h, s, v)
	if s <= 0 then return v, v, v end
	h = (h % 1) * 6
	local i = math.floor(h)
	local f = h - i
	local p = v * (1 - s)
	local q = v * (1 - f * s)
	local t = v * (1 - (1 - f) * s)
	if i == 0 then return v, t, p
	elseif i == 1 then return q, v, p
	elseif i == 2 then return p, v, t
	elseif i == 3 then return p, q, v
	elseif i == 4 then return t, p, v
	else return v, p, q end
end

local function rgb2hsv(r, g, b)
	local mx = math.max(r, g, b)
	local mn = math.min(r, g, b)
	local d = mx - mn
	local h = 0
	if d > 0 then
		if mx == r then h = ((g - b) / d) % 6
		elseif mx == g then h = (b - r) / d + 2
		else h = (r - g) / d + 4 end
		h = h / 6
	end
	local s = mx > 0 and (d / mx) or 0
	return h % 1, s, mx
end

--------------------------------------------------
-- 渐变 Canvas 缓存
--------------------------------------------------
local _svCache = {}

local function makeSVCanvas(hue)
	local key = math.floor(hue * 100)
	if _svCache[key] then return _svCache[key] end
	local canvas = love.graphics.newCanvas(SV_SIZE, SV_SIZE)
	local prev = love.graphics.getCanvas()
	love.graphics.setCanvas(canvas)
	love.graphics.clear(0, 0, 0, 0)
	for y = 0, SV_SIZE - 1 do
		for x = 0, SV_SIZE - 1 do
			local sr = x / (SV_SIZE - 1)
			local vr = 1 - y / (SV_SIZE - 1)
			local r, g, b = hsv2rgb(hue, sr, vr)
			love.graphics.setColor(r, g, b)
			love.graphics.points(x, y)
		end
	end
	love.graphics.setCanvas(prev)
	_svCache[key] = canvas
	return canvas
end

local _hueCanvas = nil

local function makeHueCanvas()
	if _hueCanvas then return _hueCanvas end
	local canvas = love.graphics.newCanvas(HUE_W, SV_SIZE)
	local prev = love.graphics.getCanvas()
	love.graphics.setCanvas(canvas)
	love.graphics.clear(0, 0, 0, 0)
	for y = 0, SV_SIZE - 1 do
		local hr = 1 - y / (SV_SIZE - 1)
		local r, g, b = hsv2rgb(hr, 1, 1)
		love.graphics.setColor(r, g, b)
		love.graphics.line(0, y, HUE_W, y)
	end
	love.graphics.setCanvas(prev)
	_hueCanvas = canvas
	return canvas
end

--------------------------------------------------
-- 主入口
--------------------------------------------------

local function showPicker(swatch_widget, getter, setter, onChangeHook)
	if onChangeHook then onChangeHook() end

	local current = getter()
	local cr = current[1] or 0.5
	local cg = current[2] or 0.5
	local cb_ = current[3] or 0.5
	local ca = current[4] or 1
	local h, s, v = rgb2hsv(cr, cg, cb_)

	-- 弹出层
	local popup = Widget({
		anchor = {0, 0, 1, 1}, padding = {0, 0, 0, 0},
		raycast_target = true,
	})
	popup.render_layer = Utils.RENDER_LAYERS.DROPDOWN

	local sx, sy = swatch_widget.transform:getGlobalPosition()
	local _, sh = swatch_widget.transform:getGlobalScaledSize()
	local panel_w = SV_SIZE + HUE_W + 4 + 24
	local panel_h = SV_SIZE + ALPHA_H + 40
	local px = math.min(sx, love.graphics.getWidth() - panel_w - 8)
	local py = math.min(sy + sh + 4, love.graphics.getHeight() - panel_h - 8)

	local panel = popup:addChild(Panel({
		bg_color = {0.14, 0.14, 0.17, 1}, outline_width = 1,
		outline_color = uc.LINE, rounding_radius = 6,
		anchor = {0, 0, 0, 0}, padding = {px, 0, py, 0},
		w = panel_w, h = panel_h,
	}))

	-- === 底部预览 + hex（先创建，_updateColor 需要引用）===
	local bottom_y = py + 8 + SV_SIZE + 4 + ALPHA_H + 4
	local preview_swatch = popup:addChild(Panel({
		bg_color = {cr, cg, cb_, ca}, outline_width = 1,
		outline_color = uc.LINE, rounding_radius = 3,
		anchor = {0, 0, 0, 0}, padding = {px + 8, 0, bottom_y, 0},
		w = 24, h = 24,
	}))
	local hex_label = popup:addChild(Text({
		text = "#FFFFFF", font_size = 11, text_color = uc.PRIMARY_TEXT,
		anchor = {0, 0, 0, 0}, padding = {px + 8 + 24 + 6, 0, bottom_y + 4, 0},
	}))

	-- === 状态表（所有拖拽方法通过它共享状态）===
	local state = {
		h = h, s = s, v = v, ca = ca,
		cr = cr, cg = cg, cb = cb_,
		sv_tex = makeSVCanvas(h),
		hue_tex = makeHueCanvas(),
		sv_drag = false, hue_drag = false, alpha_drag = false,
	}

	-- === 内部更新函数 ===
	local function updateColor()
		local r, g, b = hsv2rgb(state.h, state.s, state.v)
		state.cr, state.cg, state.cb = r, g, b
		preview_swatch.bg_color = {r, g, b, state.ca}
		local rh = math.floor(r * 255 + 0.5)
		local gh = math.floor(g * 255 + 0.5)
		local bh = math.floor(b * 255 + 0.5)
		hex_label:setText(string.format("#%02X%02X%02X  α=%.0f%%", rh, gh, bh, state.ca * 100))
		setter({r, g, b, state.ca})
	end

	-- === SV 方形 ===
	local sv_img = popup:addChild(Widget({
		anchor = {0, 0, 0, 0}, padding = {px + 8, 0, py + 8, 0},
		w = SV_SIZE, h = SV_SIZE,
	}))

	function sv_img.onDraw(self)
		local sx_, sy_ = self.transform:getGlobalPosition()
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(state.sv_tex, sx_, sy_)
		local hx = sx_ + state.s * SV_SIZE
		local hy = sy_ + (1 - state.v) * SV_SIZE
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.circle("line", hx, hy, HANDLE_R)
		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.circle("line", hx, hy, HANDLE_R + 1)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.circle("line", hx, hy, HANDLE_R - 1)
	end

	function sv_img.onMousePressed(self, mx, my, btn)
		if btn == 1 then state.sv_drag = true; updateSV(mx, my); return true end
		return false
	end
	function sv_img.onMouseMoved(self, mx, my, dx, dy)
		if state.sv_drag then updateSV(mx, my); return true end
		return false
	end
	function sv_img.onMouseReleased(self, mx, my, btn)
		state.sv_drag = false; return true
	end

	local function updateSV(mx, my)
		local sx_, sy_ = sv_img.transform:getGlobalPosition()
		state.s = math.max(0, math.min(1, (mx - sx_) / SV_SIZE))
		state.v = math.max(0, math.min(1, 1 - (my - sy_) / SV_SIZE))
		updateColor()
	end

	-- === 色相条 ===
	local hue_img = popup:addChild(Widget({
		anchor = {0, 0, 0, 0}, padding = {px + 8 + SV_SIZE + 4, 0, py + 8, 0},
		w = HUE_W, h = SV_SIZE,
	}))

	function hue_img.onDraw(self)
		local sx_, sy_ = self.transform:getGlobalPosition()
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(state.hue_tex, sx_, sy_)
		local hy = sy_ + (1 - state.h) * SV_SIZE
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.rectangle("fill", sx_ - 2, hy - 1, HUE_W + 4, 3)
		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.rectangle("line", sx_ - 2, hy - 1, HUE_W + 4, 3)
	end

	function hue_img.onMousePressed(self, mx, my, btn)
		if btn == 1 then state.hue_drag = true; updateHue(mx, my); return true end
		return false
	end
	function hue_img.onMouseMoved(self, mx, my, dx, dy)
		if state.hue_drag then updateHue(mx, my); return true end
		return false
	end
	function hue_img.onMouseReleased(self, mx, my, btn)
		state.hue_drag = false; return true
	end

	local function updateHue(mx, my)
		local _, sy_ = hue_img.transform:getGlobalPosition()
		state.h = 1 - math.max(0, math.min(1, (my - sy_) / SV_SIZE))
		state.sv_tex = makeSVCanvas(state.h)
		updateColor()
	end

	-- === Alpha 条 ===
	local alpha_img = popup:addChild(Widget({
		anchor = {0, 0, 0, 0}, padding = {px + 8, 0, py + 8 + SV_SIZE + 4, 0},
		w = SV_SIZE + HUE_W + 4, h = ALPHA_H,
	}))

	function alpha_img.onDraw(self)
		local ax, ay = self.transform:getGlobalPosition()
		local aw, ah = self.transform.w, self.transform.h
		local r, g, b = hsv2rgb(state.h, state.s, state.v)
		for bx = 0, aw - 1, 4 do
			for by = 0, ah - 1, 4 do
				local bright = ((bx / 4) + (by / 4)) % 2 == 0 and 0.55 or 0.38
				love.graphics.setColor(bright, bright, bright)
				love.graphics.rectangle("fill", ax + bx, ay + by, 4, 4)
			end
		end
		for x = 0, aw - 1 do
			local ar = x / (aw - 1)
			love.graphics.setColor(r, g, b, ar)
			love.graphics.line(ax + x, ay, ax + x, ay + ah)
		end
		local ax_pos = ax + state.ca * aw
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.line(ax_pos, ay - 2, ax_pos, ay + ah + 2)
		love.graphics.setColor(0, 0, 0, 0.6)
		love.graphics.line(ax_pos - 1, ay - 2, ax_pos - 1, ay + ah + 2)
		love.graphics.line(ax_pos + 1, ay - 2, ax_pos + 1, ay + ah + 2)
	end

	function alpha_img.onMousePressed(self, mx, my, btn)
		if btn == 1 then state.alpha_drag = true; updateAlpha(mx); return true end
		return false
	end
	function alpha_img.onMouseMoved(self, mx, my, dx, dy)
		if state.alpha_drag then updateAlpha(mx); return true end
		return false
	end
	function alpha_img.onMouseReleased(self, mx, my, btn)
		state.alpha_drag = false; return true
	end

	local function updateAlpha(mx)
		local ax, _ = alpha_img.transform:getGlobalPosition()
		local aw = alpha_img.transform.w
		state.ca = math.max(0, math.min(1, (mx - ax) / aw))
		updateColor()
	end

	-- === 初始化 ===
	updateColor()

	-- === 关闭逻辑 ===
	popup._closed = false
	local function close()
		if popup._closed then return end
		popup._closed = true
		setter({state.cr, state.cg, state.cb, state.ca})
		popup:hide()
		popup._destroy = true
	end

	function popup.onMousePressed(self, mx, my, btn)
		if not panel:regionDetection(mx, my) then
			close()
			return true
		end
		return false
	end

	function popup.onUpdate(self, dt)
		if self._destroy then
			UiManager:GetInstance():removeWidget(self)
		end
	end

	UiManager:GetInstance():addWidget(popup)
	return popup
end

return { showPicker = showPicker }
