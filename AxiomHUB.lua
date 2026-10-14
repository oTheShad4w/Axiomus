
local AXIOM_CONFIG = {
	AutoQueue = false,
	AutoJoinPrivate = false,
	Farm = true,
	AutoStart = true,
	LoopRuns = true,
	AutoShop = true,
	AutoFarm = true,
	AltMode = false,
}
do
	local g = getgenv and getgenv() or {}
	local own = game.PlaceId == 142823291 and g.MM2Config or g.SlayersConfig
	for _, t in ipairs({g.AxiomConfig or {}, own or {}}) do
		for k, v in pairs(t) do AXIOM_CONFIG[k] = v end
	end
end

pcall(function()
	if not (isfolder and isfolder("AstroHUB")) then return end
	local function copy(from, to)
		if not isfolder(to) then makefolder(to) end
		for _, p in ipairs(listfiles(from)) do
			local name = p:match("([^/\\]+)$")
			if isfolder(p) then copy(p, to .. "/" .. name)
			elseif not isfile(to .. "/" .. name) then writefile(to .. "/" .. name, readfile(p)) end
		end
	end
	copy("AstroHUB", "AxiomHUB")
end)

local OUWIGAHARA_PLACE = 75556147183481
local MM2_PLACE = 142823291

local function AxiomMenu()

do
	local genv = getgenv and getgenv() or _G
	local function setAntiAFK(on)
		if genv.__AxiomAntiAFK then
			pcall(function() genv.__AxiomAntiAFK:Disconnect() end)
			genv.__AxiomAntiAFK = nil
		end
		if not on then return end
		local VirtualUser = game:GetService("VirtualUser")
		genv.__AxiomAntiAFK = game:GetService("Players").LocalPlayer.Idled:Connect(function()
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
		end)
	end
	genv.__AxiomSetAntiAFK = setAntiAFK

	local enabled = true
	pcall(function()
		if isfile and isfile("AxiomHUB/config.json") then
			local data = game:GetService("HttpService"):JSONDecode(readfile("AxiomHUB/config.json"))
			if data.AntiAFK == false then enabled = false end
		end
	end)
	setAntiAFK(enabled)
end

local MENU_PLACE_ID = 16205713724
if game.PlaceId ~= MENU_PLACE_ID then
	warn("[AxiomHUB] Hub works only in the main menu — anti-AFK active, UI not loaded in place " .. tostring(game.PlaceId) .. ".")
	return
end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local env = getgenv and getgenv() or _G

local APP_NAME, AUTHOR = "AxiomHUB", "kingping77"

for _, key in ipairs({"__AxiomHUB", "__ClanSpinner"}) do
	if env[key] then pcall(env[key].Destroy) env[key] = nil end
end
local app = {connections = {}}
env.__AxiomHUB = app
local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(app.connections, c)
	return c
end

local function isolated(fn, ...)
	local args = table.pack(...)
	local done, result = false, nil
	task.spawn(function()
		result = table.pack(pcall(fn, table.unpack(args, 1, args.n)))
		done = true
	end)
	local started = os.clock()
	while not done and os.clock() - started < 15 do task.wait() end
	if not done then return false, "timed out" end
	return table.unpack(result, 1, result.n)
end

local T = {
	Accent = Color3.fromRGB(142, 154, 78),
	Bg = Color3.fromRGB(17, 18, 15),
	Surface = Color3.fromRGB(26, 28, 22),
	Element = Color3.fromRGB(33, 35, 28),
	Hover = Color3.fromRGB(43, 46, 36),
	Off = Color3.fromRGB(60, 63, 52),
	Text = Color3.fromRGB(234, 236, 226),
	SubText = Color3.fromRGB(156, 160, 144),
	Stroke = Color3.fromRGB(68, 72, 57),
	Warn = Color3.fromRGB(232, 182, 72),
	Error = Color3.fromRGB(232, 92, 92),
	Good = Color3.fromRGB(110, 200, 120),
}
local FONT, FONT_M, FONT_B = Enum.Font.Gotham, Enum.Font.GothamMedium, Enum.Font.GothamBold
local MB1, TOUCH, MOVE = Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch, Enum.UserInputType.MouseMovement

local function tween(obj, props, t, style)
	local tw = TweenService:Create(obj, TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function make(class, props, children)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then o[k] = v end
	end
	for _, c in ipairs(children or {}) do c.Parent = o end
	if props and props.Parent then o.Parent = props.Parent end
	return o
end
local function corner(r) return make("UICorner", {CornerRadius = UDim.new(0, r or 8)}) end
local function stroke(color, tr)
	return make("UIStroke", {Color = color or T.Stroke, Transparency = tr or 0.6, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
end
local function label(props)
	local base = {BackgroundTransparency = 1, Font = FONT_M, TextSize = 13, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left}
	for k, v in pairs(props) do base[k] = v end
	return make("TextLabel", base)
end

local function fromHex(h)
	h = tostring(h):gsub("#", ""):gsub("%s", "")
	if #h ~= 6 then return nil end
	local r, g, b = tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16)
	if not (r and g and b) then return nil end
	return Color3.fromRGB(r, g, b)
end

local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end

local function makeDraggable(handle, target)
	local dragging, startInput, startPos
	connect(handle.InputBegan, function(i)
		if i.UserInputType == MB1 or i.UserInputType == TOUCH then
			dragging, startInput, startPos = true, i.Position, target.Position
		end
	end)
	connect(UIS.InputChanged, function(i)
		if dragging and (i.UserInputType == MOVE or i.UserInputType == TOUCH) then
			local d = i.Position - startInput
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	connect(UIS.InputEnded, function(i)
		if i.UserInputType == MB1 or i.UserInputType == TOUCH then dragging = false end
	end)
end

local accentBound = {}
local function accent(obj, prop)
	table.insert(accentBound, {obj, prop})
	obj[prop] = T.Accent
	return obj
end

function app.drawMark(parent, size, z)
	local k = size / 200
	local holder = make("Frame", {Parent = parent, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, ZIndex = z})
	local m = {holder = holder, scale = make("UIScale", {Parent = holder})}
	local function box(cx, cy, w, h, rot, color, zz)
		local f = make("Frame", {Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx * k, cy * k), Size = UDim2.fromOffset(math.max(1, w * k), math.max(1, h * k)),
			Rotation = rot, BackgroundColor3 = color or T.Accent, BorderSizePixel = 0, ZIndex = z + (zz or 1)})
		if not color then accent(f, "BackgroundColor3") end
		return f
	end
	local function ring(side, thick, tr)
		local f = make("Frame", {Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(100 * k, 100 * k), Size = UDim2.fromOffset(side * k, side * k), Rotation = 45, BackgroundTransparency = 1, ZIndex = z})
		local st = make("UIStroke", {Parent = f, Thickness = math.max(1, thick * k), Transparency = tr})
		accent(st, "Color")
		return f, st
	end
	local ink = Color3.fromRGB(237, 238, 230)
	m.outer, m.outerStroke = ring(133, 3, 0.45)
	m.inner, m.innerStroke = ring(110, 1.5, 0.8)
	m.legL = box(79.5, 95, 21, 120, 20.4, ink)
	m.legR = box(120.5, 95, 21, 120, -20.4, ink)
	m.bar = box(100, 122, 48, 5, 0, nil, 2)
	m.hub = box(100, 122, 18, 18, 45, nil, 3)
	m.apex = box(100, 6, 8, 8, 45, nil, 3)
	m.fills = {m.legL, m.legR, m.bar, m.hub, m.apex}
	return m
end

local Options = {}
app.Options = Options
local CONFIG_DIR = "AxiomHUB"
local PROFILE_DIR = CONFIG_DIR .. "/configs"
local LAST_FILE = CONFIG_DIR .. "/config.json"
local AUTOLOAD_FILE = CONFIG_DIR .. "/autoload.txt"
local OLD_LAST_FILE = "ClanSpinner/config.json"
local saveQueued, loading = false, true
local canFiles = writefile and readfile and isfile and isfolder and makefolder and true or false

local function ensureDirs()
	if not canFiles then return false end
	pcall(function()
		if not isfolder(CONFIG_DIR) then makefolder(CONFIG_DIR) end
		if not isfolder(PROFILE_DIR) then makefolder(PROFILE_DIR) end
	end)
	return true
end

local function collect()
	local data = {}
	for flag, o in pairs(Options) do
		if not o.NoSave then data[flag] = o.Value end
	end
	return data
end

local function saveConfig()
	if loading or saveQueued or not canFiles then return end
	saveQueued = true
	task.delay(1, function()
		saveQueued = false
		ensureDirs()
		pcall(writefile, LAST_FILE, HttpService:JSONEncode(collect()))
	end)
end

local function register(flag, value, apply)
	local o = {Value = value}
	function o:SetValue(v, silent)
		o.Value = v
		apply(v)
		if o.Callback and not silent then task.spawn(o.Callback, v) end
		saveConfig()
	end
	o.Refresh = function() apply(o.Value) end
	Options[flag] = o
	return o
end

local function applyData(data)
	loading = true
	for flag, v in pairs(data) do
		local o = Options[flag]
		if o and not o.NoSave then pcall(o.SetValue, o, v, true) end
	end
	loading = false
	saveConfig()
end

local function setAccent(c)
	T.Accent = c
	for _, b in ipairs(accentBound) do
		if b[1].Parent then tween(b[1], {[b[2]] = c}, 0.35) end
	end
	for _, o in pairs(Options) do
		if not o.NoRefresh then o.Refresh() end
	end
end

local gui = make("ScreenGui", {Name = "AxiomHUB", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true, DisplayOrder = 50})
pcall(function()
	for _, c in ipairs(((gethui and gethui()) or game:GetService("CoreGui")):GetChildren()) do
		if c.Name == "AxiomHUB" then c:Destroy() end
	end
end)
if not pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end) or not gui.Parent then
	gui.Parent = player:WaitForChild("PlayerGui")
end

local main = make("Frame", {
	Parent = gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(640, 470), BackgroundColor3 = T.Bg, BackgroundTransparency = 0.08, BorderSizePixel = 0,
}, {corner(12)})
accent(make("UIStroke", {Parent = main, Transparency = 0.65, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}), "Color")
local mainScale = make("UIScale", {Parent = main, Scale = 0.94})

local top = make("Frame", {Parent = main, Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1})
app.drawMark(make("Frame", {Parent = top, Position = UDim2.fromOffset(6, 7), Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1}), 28, 2)
label({Parent = top, Position = UDim2.fromOffset(42, 8), Size = UDim2.fromOffset(200, 18), Text = APP_NAME, Font = FONT_B, TextSize = 15})
label({Parent = top, Position = UDim2.fromOffset(42, 25), Size = UDim2.fromOffset(200, 14), Text = "Main Menu", Font = FONT, TextSize = 11, TextColor3 = T.SubText})
local status = label({
	Parent = top, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -80, 0, 0), Size = UDim2.new(0, 300, 1, 0),
	Text = "", RichText = true, Font = FONT, TextSize = 12, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Right,
})
make("Frame", {Parent = main, Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.Stroke, BackgroundTransparency = 0.5, BorderSizePixel = 0})

local function topButton(parent, text, x, onClick)
	local b = make("TextButton", {
		Parent = parent, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, x, 0.5, 0), Size = UDim2.fromOffset(26, 26),
		BackgroundColor3 = T.Hover, BackgroundTransparency = 1, AutoButtonColor = false,
		Text = text, Font = FONT_B, TextSize = 14, TextColor3 = T.SubText, ZIndex = 3,
	}, {corner(7)})
	connect(b.MouseEnter, function() tween(b, {BackgroundTransparency = 0.2, TextColor3 = T.Text}) end)
	connect(b.MouseLeave, function() tween(b, {BackgroundTransparency = 1, TextColor3 = T.SubText}) end)
	connect(b.MouseButton1Click, onClick)
	return b
end

makeDraggable(top, main)

local sidebar = make("Frame", {Parent = main, Position = UDim2.fromOffset(10, 56), Size = UDim2.new(0, 140, 1, -66), BackgroundColor3 = T.Surface, BackgroundTransparency = 0.3}, {corner(10)})
local tabList = make("Frame", {Parent = sidebar, Size = UDim2.new(1, 0, 1, -54), BackgroundTransparency = 1}, {
	make("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}),
	make("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}),
})
local indicator = accent(make("Frame", {Parent = sidebar, Position = UDim2.fromOffset(4, 16), Size = UDim2.fromOffset(3, 18), ZIndex = 3}, {corner(2)}), "BackgroundColor3")

local footer = make("Frame", {Parent = sidebar, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1})
make("Frame", {Parent = footer, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -24, 0, 1), BackgroundColor3 = T.Stroke, BackgroundTransparency = 0.4, BorderSizePixel = 0})
accent(label({Parent = footer, Position = UDim2.fromOffset(14, 9), Size = UDim2.new(1, -28, 0, 16), Text = APP_NAME, Font = FONT_B, TextSize = 13}), "TextColor3")
label({Parent = footer, Position = UDim2.fromOffset(14, 26), Size = UDim2.new(1, -28, 0, 14), Text = "@" .. AUTHOR, Font = FONT, TextSize = 11, TextColor3 = T.SubText})

local content = make("Frame", {Parent = main, Position = UDim2.fromOffset(160, 56), Size = UDim2.new(1, -170, 1, -66), BackgroundTransparency = 1, ClipsDescendants = true})

local toasts = make("Frame", {Parent = gui, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -18, 1, -18), Size = UDim2.fromOffset(310, 380), BackgroundTransparency = 1}, {
	make("UIListLayout", {Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = Enum.SortOrder.LayoutOrder}),
})
local toastCount = 0
local KINDS = {
	success = {icon = "✓", color = function() return T.Accent end},
	info = {icon = "i", color = function() return T.Accent end},
	warn = {icon = "!", color = function() return T.Warn end},
	error = {icon = "×", color = function() return T.Error end},
}

local function notifyNow(kind, title, text, duration)
	duration = duration or 4
	local k = KINDS[kind] or KINDS.info
	local col = k.color()
	toastCount += 1

	local live = {}
	for _, c in ipairs(toasts:GetChildren()) do
		if c:IsA("Frame") then table.insert(live, c) end
	end
	if #live >= 4 then live[1]:Destroy() end

	local holder = make("Frame", {Parent = toasts, LayoutOrder = toastCount, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1})
	local card = make("Frame", {Parent = holder, Position = UDim2.fromOffset(340, 0), Size = UDim2.new(1, 0, 0, 72), BackgroundColor3 = T.Bg, BackgroundTransparency = 0.04, ClipsDescendants = true}, {corner(10), stroke(col, 0.55)})
	make("Frame", {Parent = card, Size = UDim2.new(0, 80, 1, 0), BackgroundColor3 = col, BackgroundTransparency = 0.88, BorderSizePixel = 0}, {
		make("UIGradient", {Transparency = NumberSequence.new(0, 1)}),
	})
	local icon = make("Frame", {Parent = card, Position = UDim2.fromOffset(14, 20), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = col, BackgroundTransparency = 0.78, ZIndex = 2}, {corner(15)})
	local iconStroke = stroke(col, 0.35); iconStroke.Parent = icon
	label({Parent = icon, Size = UDim2.fromScale(1, 1), Text = k.icon, Font = FONT_B, TextSize = 15, TextColor3 = col, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3})
	label({Parent = card, Position = UDim2.fromOffset(56, 10), Size = UDim2.new(1, -68, 0, 14), Text = APP_NAME:upper(), Font = FONT_B, TextSize = 10, TextColor3 = col, ZIndex = 2})
	label({Parent = card, Position = UDim2.fromOffset(56, 24), Size = UDim2.new(1, -68, 0, 18), Text = title, Font = FONT_B, TextSize = 13, ZIndex = 2})
	label({Parent = card, Position = UDim2.fromOffset(56, 42), Size = UDim2.new(1, -68, 0, 26), Text = text or "", Font = FONT, TextSize = 12, TextColor3 = T.SubText, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 2})
	local bar = make("Frame", {Parent = card, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = col, BorderSizePixel = 0, ZIndex = 3})
	local click = make("TextButton", {Parent = card, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 5})

	tween(holder, {Size = UDim2.new(1, 0, 0, 72)}, 0.25)
	tween(card, {Position = UDim2.fromOffset(0, 0)}, 0.45, Enum.EasingStyle.Back)
	tween(bar, {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear)

	local gone = false
	local function dismiss()
		if gone then return end
		gone = true
		tween(card, {Position = UDim2.fromOffset(340, 0)}, 0.3)
		task.delay(0.2, function()
			if holder.Parent then tween(holder, {Size = UDim2.new(1, 0, 0, 0)}, 0.2).Completed:Wait() end
			holder:Destroy()
		end)
	end
	click.MouseButton1Click:Connect(dismiss)
	click.MouseEnter:Connect(function() tween(card, {BackgroundColor3 = T.Surface}, 0.15) end)
	click.MouseLeave:Connect(function() tween(card, {BackgroundColor3 = T.Bg}, 0.15) end)
	task.delay(duration, dismiss)
end

local toastQueue = {}
local function notify(kind, title, text, duration)
	table.insert(toastQueue, {kind, title, text, duration})
end
task.spawn(function()
	while toasts.Parent do
		while #toastQueue > 0 do
			local t = table.remove(toastQueue, 1)
			pcall(notifyNow, t[1], t[2], t[3], t[4])
		end
		task.wait(0.15)
	end
end)

local tabs, current = {}, nil

local function selectTab(tab)
	if current == tab then return end
	local prev = current
	current = tab
	for _, t in ipairs(tabs) do
		local on = t == tab
		tween(t.button, {BackgroundTransparency = on and 0.15 or 1, TextColor3 = on and T.Text or T.SubText})
	end
	tween(indicator, {Position = UDim2.fromOffset(4, 14 + (tab.index - 1) * 34)}, 0.3)
	if prev then
		local p = prev.page
		tween(p, {GroupTransparency = 1, Position = UDim2.fromOffset(0, -8)}, 0.15)
		task.delay(0.15, function()
			if current ~= prev then p.Visible = false end
		end)
	end
	local pg = tab.page
	pg.Visible, pg.GroupTransparency, pg.Position = true, 1, UDim2.fromOffset(0, 12)
	tween(pg, {GroupTransparency = 0, Position = UDim2.fromOffset(0, 0)}, 0.28)
end

local function drawIcon(parent, key)
	local h = make("Frame", {Parent = parent, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -24, 0.5, 0), Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1})
	local ink = T.Text
	local function fill(x, y, w, hh, acc, r)
		local f = make("Frame", {Parent = h, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, hh), BackgroundColor3 = ink, BorderSizePixel = 0})
		if r then corner(r).Parent = f end
		if acc then accent(f, "BackgroundColor3") end
		return f
	end
	local function box(x, y, w, hh, acc, r)
		local f = make("Frame", {Parent = h, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, hh), BackgroundTransparency = 1})
		if r then corner(r).Parent = f end
		local s = make("UIStroke", {Parent = f, Thickness = 1.5, Color = ink, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
		if acc then accent(s, "Color") end
		return f
	end
	local function ring(cx, cy, d, acc) return box(cx - d / 2, cy - d / 2, d, d, acc, d) end
	local function dot(cx, cy, d, acc) return fill(cx - d / 2, cy - d / 2, d, d, acc, d) end
	local function rbox(cx, cy, s, acc)
		local f = make("Frame", {Parent = h, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy), Size = UDim2.fromOffset(s, s), Rotation = 45, BackgroundTransparency = 1})
		local st = make("UIStroke", {Parent = f, Thickness = 1.5, Color = ink})
		if acc then accent(st, "Color") end
	end
	local function rdot(cx, cy, s, acc)
		local f = make("Frame", {Parent = h, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy), Size = UDim2.fromOffset(s, s), Rotation = 45, BackgroundColor3 = ink, BorderSizePixel = 0})
		if acc then accent(f, "BackgroundColor3") end
	end
	if key == "home" then
		rbox(9, 9, 10)
		rdot(9, 9, 3, true)
	elseif key == "spin" then
		ring(9, 9, 14)
		dot(9, 9, 4, true)
	elseif key == "swords" then
		fill(1, 3, 16, 2, true, 1)
		fill(3, 7, 12, 2)
		fill(4, 3, 2, 13, nil, 1)
		fill(12, 3, 2, 13, nil, 1)
	elseif key == "target" then
		ring(9, 9, 14)
		ring(9, 9, 6, true)
	elseif key == "compass" then
		ring(9, 9, 14)
		fill(8, 4, 2, 6, true, 1)
		dot(9, 11, 2)
	elseif key == "heal" then
		fill(7, 3, 4, 12, true, 1)
		fill(3, 7, 12, 4, true, 1)
	elseif key == "map" then
		box(2, 3, 14, 12, nil, 2)
		fill(7, 3, 2, 12)
		dot(12, 7, 4, true)
	elseif key == "cards" then
		box(2, 4, 8, 12, nil, 2)
		box(8, 2, 8, 12, true, 2)
	elseif key == "shop" then
		box(2, 7, 14, 9, nil, 2)
		box(6, 2, 6, 7, true, 3)
	elseif key == "link" then
		rbox(6.5, 9, 6)
		rbox(11.5, 9, 6, true)
	elseif key == "gear" then
		fill(2, 3, 14, 2, nil, 1) fill(2, 8, 14, 2, nil, 1) fill(2, 13, 14, 2, nil, 1)
		dot(6, 4, 5) dot(12, 9, 5, true) dot(8, 14, 5)
	elseif key == "servers" then
		ring(9, 9, 14)
		box(6, 2, 6, 14, true, 3)
		fill(2, 8, 14, 2, nil, 1)
	elseif key == "coin" then
		ring(9, 9, 14)
		ring(9, 9, 6, true)
	elseif key == "player" then
		ring(9, 5, 6)
		box(3, 11, 12, 6, true, 3)
	elseif key == "eye" then
		box(1, 5, 16, 8, nil, 4)
		dot(9, 9, 4, true)
	else
		dot(9, 9, 6, true)
	end
	return h
end

local function newTab(name, icon)
	local index = #tabs + 1
	local btn = make("TextButton", {
		Parent = tabList, LayoutOrder = index, Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = T.Element, BackgroundTransparency = 1, AutoButtonColor = false,
		Text = name, Font = FONT_M, TextSize = 13, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Left,
	}, {corner(8), make("UIPadding", {PaddingLeft = UDim.new(0, icon and 34 or 14)})})
	if icon then drawIcon(btn, icon) end
	local page = make("CanvasGroup", {Parent = content, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, GroupTransparency = 1})
	local scroll = make("ScrollingFrame", {
		Parent = page, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
	}, {
		make("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}),
		make("UIPadding", {PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8)}),
	})
	accent(scroll, "ScrollBarImageColor3")
	local tab = {index = index, button = btn, page = page, container = scroll, order = 0}
	table.insert(tabs, tab)
	connect(btn.MouseEnter, function() if current ~= tab then tween(btn, {BackgroundTransparency = 0.55, TextColor3 = T.Text}) end end)
	connect(btn.MouseLeave, function() if current ~= tab then tween(btn, {BackgroundTransparency = 1, TextColor3 = T.SubText}) end end)
	connect(btn.MouseButton1Click, function() selectTab(tab) end)
	return tab
end

local function nextOrder(tab)
	tab.order += 1
	return tab.order
end

local function baseElement(tab, height, hitHeight)
	local f = make("Frame", {Parent = tab.container, LayoutOrder = nextOrder(tab), Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = T.Element, BackgroundTransparency = 0.15}, {corner(8)})
	local s = stroke(T.Stroke, 0.7); s.Parent = f
	local hit = make("TextButton", {Parent = f, Size = UDim2.new(1, 0, 0, hitHeight or height), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 1})
	connect(f.MouseEnter, function()
		tween(f, {BackgroundColor3 = T.Hover})
		tween(s, {Color = T.Accent, Transparency = 0.5})
	end)
	connect(f.MouseLeave, function()
		tween(f, {BackgroundColor3 = T.Element})
		tween(s, {Color = T.Stroke, Transparency = 0.7})
	end)
	return f, hit
end

local function section(tab, text)
	accent(label({Parent = tab.container, LayoutOrder = nextOrder(tab), Size = UDim2.new(1, 0, 0, 24), Text = string.upper(text), Font = FONT_B, TextSize = 11, TextYAlignment = Enum.TextYAlignment.Bottom}), "TextColor3")
end

local function note(tab, text)
	return label({Parent = tab.container, LayoutOrder = nextOrder(tab), Size = UDim2.new(1, 0, 0, 30), Text = text, Font = FONT, TextSize = 12, TextColor3 = T.SubText, TextWrapped = true, RichText = true})
end

local function toggle(tab, flag, title, default, callback)
	local f, hit = baseElement(tab, 40)
	label({Parent = f, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -70, 1, 0), Text = title})
	local sw = make("Frame", {Parent = f, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(38, 20), BackgroundColor3 = T.Off}, {corner(10)})
	local knob = make("Frame", {Parent = sw, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = T.Text}, {corner(7)})
	local o = register(flag, default, function(v)
		tween(sw, {BackgroundColor3 = v and T.Accent or T.Off}, 0.2)
		tween(knob, {Position = v and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)}, 0.3, Enum.EasingStyle.Back)
	end)
	o.Callback = callback
	o:SetValue(default, true)
	connect(hit.MouseButton1Click, function() o:SetValue(not o.Value) end)
	return o
end

local function button(tab, title, desc, callback)
	local h = desc and 48 or 40
	local f, hit = baseElement(tab, h)
	label({Parent = f, Position = UDim2.fromOffset(12, desc and 7 or 0), Size = UDim2.new(1, -40, 0, desc and 18 or h), Text = title})
	local descLabel
	if desc then
		descLabel = label({Parent = f, Position = UDim2.fromOffset(12, 26), Size = UDim2.new(1, -40, 0, 14), Text = desc, Font = FONT, TextSize = 11, TextColor3 = T.SubText, TextTruncate = Enum.TextTruncate.AtEnd, RichText = true})
	end
	local arrow = label({Parent = f, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(16, 16), Text = "›", Font = FONT_B, TextSize = 18, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Center})
	local sc = make("UIScale", {Parent = f})
	connect(f.MouseEnter, function() tween(arrow, {Position = UDim2.new(1, -8, 0.5, 0), TextColor3 = T.Accent}) end)
	connect(f.MouseLeave, function() tween(arrow, {Position = UDim2.new(1, -12, 0.5, 0), TextColor3 = T.SubText}) end)
	connect(hit.MouseButton1Down, function() tween(sc, {Scale = 0.97}, 0.08) end)
	connect(hit.MouseButton1Up, function() tween(sc, {Scale = 1}, 0.25, Enum.EasingStyle.Back) end)
	connect(hit.MouseLeave, function() tween(sc, {Scale = 1}, 0.2) end)
	connect(hit.MouseButton1Click, function() task.spawn(callback) end)
	return {SetDesc = function(text) if descLabel and descLabel.Text ~= text then descLabel.Text = text end end}
end

local function slider(tab, flag, title, min, max, step, default, suffix, callback)
	local f = baseElement(tab, 54)
	label({Parent = f, Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -90, 0, 20), Text = title})
	local val = accent(label({Parent = f, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 6), Size = UDim2.fromOffset(70, 20), Font = FONT_B, TextXAlignment = Enum.TextXAlignment.Right}), "TextColor3")
	local track = make("Frame", {Parent = f, Position = UDim2.new(0, 12, 0, 36), Size = UDim2.new(1, -24, 0, 6), BackgroundColor3 = T.Off, ZIndex = 2}, {corner(3)})
	local fill = accent(make("Frame", {Parent = track, Size = UDim2.fromScale(0, 1), ZIndex = 2}, {corner(3)}), "BackgroundColor3")
	local knob = make("Frame", {Parent = track, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = T.Text, ZIndex = 3}, {corner(6)})
	local o = register(flag, default, function(v)
		local a = (v - min) / (max - min)
		tween(fill, {Size = UDim2.fromScale(a, 1)}, 0.12)
		tween(knob, {Position = UDim2.fromScale(a, 0.5)}, 0.12)
		val.Text = tostring(v) .. (suffix or "")
		if callback then callback(v) end
	end)
	o:SetValue(default, true)

	local dragging = false
	local function update(x)
		local a = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		local v = math.clamp(math.floor((min + a * (max - min)) / step + 0.5) * step, min, max)
		if v ~= o.Value then o:SetValue(v) end
	end
	local grab = make("TextButton", {Parent = f, Position = UDim2.new(0, 6, 0, 26), Size = UDim2.new(1, -12, 0, 24), BackgroundTransparency = 1, Text = "", ZIndex = 4})
	connect(grab.InputBegan, function(i)
		if i.UserInputType == MB1 or i.UserInputType == TOUCH then
			dragging = true
			tween(knob, {Size = UDim2.fromOffset(15, 15)}, 0.15)
			update(i.Position.X)
		end
	end)
	connect(UIS.InputChanged, function(i)
		if dragging and (i.UserInputType == MOVE or i.UserInputType == TOUCH) then update(i.Position.X) end
	end)
	connect(UIS.InputEnded, function(i)
		if dragging and (i.UserInputType == MB1 or i.UserInputType == TOUCH) then
			dragging = false
			tween(knob, {Size = UDim2.fromOffset(12, 12)}, 0.2, Enum.EasingStyle.Back)
		end
	end)
	return o
end

local function textBox(parent, props)
	local box = make("TextBox", {
		Parent = parent, BackgroundColor3 = T.Surface, BackgroundTransparency = 0.1, Text = "",
		PlaceholderColor3 = T.SubText, TextColor3 = T.Text, Font = FONT, TextSize = 12, ClearTextOnFocus = false,
		TextTruncate = Enum.TextTruncate.AtEnd, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2,
	}, {corner(6), make("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})})
	for k, v in pairs(props) do box[k] = v end
	local bs = stroke(T.Stroke, 0.6); bs.Parent = box
	connect(box.Focused, function() tween(bs, {Color = T.Accent, Transparency = 0.1}) end)
	connect(box.FocusLost, function() tween(bs, {Color = T.Stroke, Transparency = 0.6}) end)
	return box
end

local function input(tab, flag, title, placeholder, callback)
	local f = baseElement(tab, 40)
	label({Parent = f, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.4, 0, 1, 0), Text = title})
	local box = textBox(f, {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0.58, 0, 0, 26), PlaceholderText = placeholder or ""})
	local o = register(flag, "", function(v) box.Text = v end)
	o.Callback = callback
	connect(box.FocusLost, function()
		if box.Text ~= o.Value then o:SetValue(box.Text) end
	end)
	return o
end

local function dropdown(tab, flag, title, values, multi, default)
	local f, hit = baseElement(tab, 40, 40)
	f.ClipsDescendants = true
	label({Parent = f, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.45, 0, 0, 40), Text = title})
	local valueLabel = label({
		Parent = f, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -34, 0, 0), Size = UDim2.new(0.5, -20, 0, 40),
		Font = FONT, TextSize = 12, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local chevron = label({Parent = f, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -20, 0, 20), Size = UDim2.fromOffset(16, 16), Text = "›", Font = FONT_B, TextSize = 18, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Center, Rotation = 90})
	local list = make("ScrollingFrame", {
		Parent = f, Position = UDim2.fromOffset(6, 44), Size = UDim2.new(1, -12, 0, 30),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 2,
	}, {make("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder})})
	accent(list, "ScrollBarImageColor3")

	local items, o, open, listH = {}, nil, false, 30
	local function isOn(v)
		if multi then return type(o.Value) == "table" and o.Value[v] == true end
		return o.Value == v
	end
	local function paint(v, hover)
		local item, on = items[v], isOn(v)
		if not item then return end
		tween(item.btn, {BackgroundTransparency = on and 0.25 or (hover and 0.6 or 1), TextColor3 = (on or hover) and T.Text or T.SubText}, 0.15)
		tween(item.mark, {BackgroundTransparency = on and 0 or 1, Size = on and UDim2.fromOffset(6, 6) or UDim2.fromOffset(2, 2)}, 0.2)
	end
	local function refresh()
		if multi then
			local sel = {}
			for _, v in ipairs(values) do
				if isOn(v) then table.insert(sel, v) end
			end
			valueLabel.Text = #sel == 0 and "None" or (#sel <= 2 and table.concat(sel, ", ") or (#sel .. " selected"))
		else
			valueLabel.Text = (o.Value == nil or o.Value == "") and "None" or tostring(o.Value)
		end
		for _, v in ipairs(values) do paint(v, false) end
	end
	local function setOpen(state)
		open = state
		tween(f, {Size = UDim2.new(1, 0, 0, state and (48 + listH) or 40)}, 0.28)
		tween(chevron, {Rotation = state and 270 or 90, TextColor3 = state and T.Accent or T.SubText}, 0.28)
	end
	local function build()
		for _, it in pairs(items) do it.btn:Destroy() end
		items = {}
		listH = math.max(1, math.min(#values, 6)) * 30
		list.Size = UDim2.new(1, -12, 0, listH)
		for i, v in ipairs(values) do
			local b = make("TextButton", {
				Parent = list, LayoutOrder = i, Size = UDim2.new(1, -6, 0, 28), BackgroundColor3 = T.Hover, BackgroundTransparency = 1,
				AutoButtonColor = false, Text = v, Font = FONT, TextSize = 12, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2,
			}, {corner(6), make("UIPadding", {PaddingLeft = UDim.new(0, 22)})})
			local mark = accent(make("Frame", {Parent = b, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, -11, 0.5, 0), Size = UDim2.fromOffset(2, 2), BackgroundTransparency = 1, ZIndex = 3}, {corner(3)}), "BackgroundColor3")
			items[v] = {btn = b, mark = mark}
			b.MouseEnter:Connect(function() paint(v, true) end)
			b.MouseLeave:Connect(function() paint(v, false) end)
			b.MouseButton1Click:Connect(function()
				if multi then
					local t = table.clone(type(o.Value) == "table" and o.Value or {})
					t[v] = (not t[v]) or nil
					o:SetValue(t)
				else
					o:SetValue(v)
					setOpen(false)
				end
			end)
		end
	end

	o = register(flag, default, function() refresh() end)
	function o.SetValues(newValues)
		values = newValues
		build()
		refresh()
		if open then setOpen(true) end
	end
	build()
	connect(hit.MouseButton1Click, function() setOpen(not open) end)
	o:SetValue(default, true)
	return o
end

local PRESETS = {
	{"Olive", "#8E9A4E"}, {"Sage", "#7FA37A"}, {"Ocean", "#4F8FD6"}, {"Violet", "#9071D9"},
	{"Rose", "#D9708E"}, {"Crimson", "#D65252"}, {"Amber", "#D9A040"}, {"Mint", "#4FC2A0"}, {"Ice", "#9FB8C9"},
}
local function colorPicker(tab, flag, title, default)
	local f = baseElement(tab, 70)
	label({Parent = f, Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -110, 0, 20), Text = title})
	local nameLabel = label({Parent = f, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 6), Size = UDim2.fromOffset(120, 20), Font = FONT, TextSize = 12, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Right})
	local row = make("Frame", {Parent = f, Position = UDim2.fromOffset(12, 34), Size = UDim2.new(1, -24, 0, 26), BackgroundTransparency = 1, ZIndex = 2}, {
		make("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 9), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}),
	})
	local rings = {}
	local o = register(flag, default, function(v)
		local c = fromHex(v)
		if c then setAccent(c) end
		local name = "Custom"
		for _, p in ipairs(PRESETS) do
			local on = p[2]:upper() == tostring(v):upper()
			if on then name = p[1] end
			if rings[p[2]] then tween(rings[p[2]], {Transparency = on and 0 or 1}, 0.2) end
		end
		nameLabel.Text = name .. "  " .. tostring(v):upper()
	end)
	o.NoRefresh = true
	for i, p in ipairs(PRESETS) do
		local sw = make("TextButton", {Parent = row, LayoutOrder = i, Size = UDim2.fromOffset(22, 22), BackgroundColor3 = fromHex(p[2]), Text = "", AutoButtonColor = false, ZIndex = 2}, {corner(11)})
		rings[p[2]] = make("UIStroke", {Parent = sw, Color = T.Text, Thickness = 2, Transparency = 1})
		local sc = make("UIScale", {Parent = sw})
		connect(sw.MouseEnter, function() tween(sc, {Scale = 1.18}, 0.2, Enum.EasingStyle.Back) end)
		connect(sw.MouseLeave, function() tween(sc, {Scale = 1}, 0.2) end)
		connect(sw.MouseButton1Click, function() o:SetValue(p[2]) end)
	end
	o:SetValue(default, true)
	return o
end

local RARITIES = {"Common", "Uncommon", "Rare", "Legendary", "Mythic", "Supreme"}
local RANK = {Common = 1, Uncommon = 2, Rare = 3, Legendary = 4, Mythic = 5, Supreme = 6}
local CHANCE = {Common = "60%", Uncommon = "23%", Rare = "12%", Legendary = "4%", Mythic = "0.9%", Supreme = "0.1%"}
local HEX = {Common = "#b4b4b4", Uncommon = "#57d27a", Rare = "#4fa3ff", Legendary = "#e6c25a", Mythic = "#b47cff", Supreme = "#ff5a5a"}
local COLORS = {Common = 0xA5A5A5, Uncommon = 0x57D27A, Rare = 0x4FA3FF, Legendary = 0xE6C25A, Mythic = 0xB47CFF, Supreme = 0xFF5A5A}
local EMOJI = {Common = "⚪", Uncommon = "🟢", Rare = "🔵", Legendary = "🟡", Mythic = "🟣", Supreme = "🔴"}

local CLANS = {
	Common = {"Ando", "Aokawa", "Fujiwara", "Fukukoshi", "Hagiwara", "Hozumi", "Kanzaki", "Kazetani", "Kuroaki", "Kurosaki", "Mori", "Saito", "Sakurai", "Suzuki", "Toka", "Tsukino", "Yukimori"},
	Uncommon = {"Aori", "Aoshima", "Kaneki", "Kurotsume", "Yamagiri"},
	Rare = {"Makomo", "Sabito", "Susumaru", "Urokodaki", "Yahaba"},
	Legendary = {"Kocho", "Shabana", "Tomioka", "Ubuyashiki"},
	Mythic = {"Agatsuma", "Douma", "Himejima", "Iguro", "Shinazugawa", "Tamayo"},
	Supreme = {"Kamado", "Rengoku", "Soyama", "Uzui"},
}
local clanRarity, clanList = {}, {}
for rarity, names in pairs(CLANS) do
	for _, name in ipairs(names) do
		clanRarity[name] = rarity
		table.insert(clanList, name)
	end
end
table.sort(clanList, function(a, b)
	if RANK[clanRarity[a]] ~= RANK[clanRarity[b]] then return RANK[clanRarity[a]] > RANK[clanRarity[b]] end
	return a < b
end)
local function clanLabel(name) return string.format("%s (%s)", name, clanRarity[name] or "?") end
local clanLabels = {}
for _, name in ipairs(clanList) do table.insert(clanLabels, clanLabel(name)) end

local function tryRequire(path)
	local ok, m = pcall(function() return require(path()) end)
	return ok and m or nil
end
local Shop = tryRequire(function() return RS.CAM.Global.Shop end)
local SignalFunction = tryRequire(function() return RS.Communication.ServerAndClient.Signals.SignalFunction end)
local SignalEvent = tryRequire(function() return RS.Communication.ServerAndClient.Signals.SignalEvent end)
local QueueSignal = tryRequire(function() return RS.Communication.ServerAndClient.Signals.QueueSignal end)
local Worlds = tryRequire(function() return RS.CAM.Worlds end)
local Teleporter = tryRequire(function() return RS.CAM.Client.Modules.Teleporter end)
local PartyWatcher = tryRequire(function() return RS.CAM.Client.Modules.PartyWatcher end)
local QueuWatcher = tryRequire(function() return RS.MenuComponents.Misc.QueuWatcher end)
local DataValue = tryRequire(function() return RS.CAM.Client.Modules.DataValue end)
local SettingsKeys = tryRequire(function() return RS.CAM.Global.Subsets.Gameplay.SettingsKeys end)
local Validators = tryRequire(function() return RS.CAM.Global.MainMenuRelay.Validators end)

local MENU_ID = MENU_PLACE_ID

local function getFrame()
	local ok, result = pcall(function()
		for _, child in ipairs(player.PlayerGui.Components.Body.AvatarFrames.Left:GetChildren()) do
			if child:FindFirstChild("SpinningFrame") and child:FindFirstChild("IdentityLine") then return child end
		end
		return nil
	end)
	return ok and result or nil
end

local function getSpinsLeft()
	local f = getFrame()
	local l = f and f.SpinningFrame.Spinner.Holder.AATitleHolder:FindFirstChild("TextLabel")
	return l and tonumber(l.Text:match("%d+")) or nil
end

local function getCurrentClan()
	local f = getFrame()
	local l = f and f.IdentityLine:FindFirstChild("TextLabel")
	if not l then return nil, nil end
	local clan = l.Text:match("<b>%s*(.-)%s*</b>")
	local rarity = l.Text:gsub("<[^>]+>", ""):match("%(%s*(%a+)%s*%)")
	if rarity and not RANK[rarity] then rarity = nil end
	return clan, rarity or (clan and clanRarity[clan])
end

local function fireButton(btn, signals)
	local fired = false
	for _, sig in ipairs(signals) do
		pcall(function()
			for _, c in ipairs(getconnections(btn[sig])) do
				c:Fire()
				fired = true
			end
		end)
		if fired then break end
	end
	return fired
end

local function pressSpin()
	local f = getFrame()
	local btn = f and f.SpinningFrame.Spinner.Holder.SpinButton:FindFirstChild("Button")
	if not btn then return false end
	return fireButton(btn, {"MouseButton1Click", "Activated", "MouseButton1Down"})
end

local ORE_PACKS = {"1 Spin", "15 Spins", "25 Spins", "50 Spins", "100 Spins", "250 Spins"}

local function oreInfo(pack)
	if not Shop then return nil end
	local ok, c = isolated(Shop.GetOreContent, player, pack)
	return ok and c or nil
end

local function getOre()
	local c = oreInfo("1 Spin")
	return c and c.Held or nil
end

local function packsByValue()
	local list = {}
	for _, name in ipairs(ORE_PACKS) do
		local c = oreInfo(name)
		local spins = tonumber(name:match("%d+"))
		if c and c.Price and spins then
			table.insert(list, {name = name, spins = spins, price = c.Price, canBuy = c.CanBuy ~= false})
		end
	end
	table.sort(list, function(a, b) return a.price / a.spins < b.price / b.spins end)
	return list
end

local converting = false
local function convertOre(keep)
	if converting then return 0, 0, "busy" end
	if not (Shop and SignalFunction) then return 0, 0, "nomodule" end
	converting = true
	local bought, spent = 0, 0
	local failure
	for _ = 1, 100 do
		local held = getOre() or 0
		local pick
		for _, p in ipairs(packsByValue()) do
			if p.canBuy and held - p.price >= keep then pick = p break end
		end
		if not pick then break end
		local ok, res = isolated(SignalFunction.ToServer, "PurchaseFromShopWithOre", pick.name)
		if not ok or res ~= true then
			failure = "The game refused to buy " .. pick.name .. "."
			break
		end
		bought += pick.spins
		spent += pick.price
		local t = os.clock()
		repeat task.wait(0.15) until (getOre() or held) < held or os.clock() - t > 3
		task.wait(0.25)
	end
	converting = false
	return bought, spent, failure
end

local worldNames = {}
if Worlds and Worlds.ByName then
	for name in pairs(Worlds.ByName) do
		if name ~= "Main Menu" and not name:find("Test") then table.insert(worldNames, name) end
	end
	table.sort(worldNames)
end
if #worldNames == 0 then worldNames = {"Ouwland"} end

local function teleportTo(worldName, owner)
	if not (Worlds and Teleporter) then
		notify("error", "Can't teleport", "Game teleport modules were not found here.")
		return
	end
	local world = Worlds.ByName[worldName]
	if not world then
		notify("error", "Unknown world", tostring(worldName) .. " is not in the world list.")
		return
	end
	local request = {placeId = world.Id}
	if owner then request.privateOwner = owner end
	notify("info", owner and "Joining private server" or "Joining server", owner and (owner .. " · " .. worldName) or worldName, 5)
	local ok, result = isolated(Teleporter.Request, request)
	if not ok or result == false then
		notify("error", "Join failed", ok and "The game refused the teleport. Check the code." or tostring(result))
	end
end

local function getJoinUI()
	local ok, actual = pcall(function() return player.PlayerGui.Components.BottomHolder.JoinHolder.Actual end)
	if not ok or not actual then return nil, nil end
	local privateBox = actual:FindFirstChild("PrivateBox")
	local box = privateBox and privateBox:FindFirstChild("Textbox")
	local btn = actual:FindFirstChild("TextButton")
	if box and btn then return box, btn end
	return nil, nil
end

local function joinPrivate(code)
	local box, btn = getJoinUI()
	if box then
		box.Text = code
		task.wait(0.2)
		if fireButton(btn, {"MouseButton1Click"}) then
			notify("info", "Joining private server", "Code: " .. code, 5)
			return
		end
	end
	teleportTo(Options.ServerWorld.Value, code)
end

local fillDV, rankedDV, globalDV
if DataValue then
	pcall(function() fillDV = DataValue.new("Misc/QueueFill", true) end)
	pcall(function() rankedDV = DataValue.new("Misc/QueueRanked", false) end)
	if SettingsKeys then
		pcall(function() globalDV = DataValue.new(SettingsKeys.GlobalQueue.Path, SettingsKeys.GlobalQueue.Default, SettingsKeys.Scope) end)
	end
end

local function isQueued()
	if not QueuWatcher then return false end
	local ok, v = pcall(QueuWatcher.Get)
	return ok and v ~= nil
end

local function enforceQueueSettings()
	if not SignalEvent then return end
	if Options.ForceFillOff.Value and fillDV and fillDV:Get() == true then
		isolated(SignalEvent.ToServer, "QueueFill", false)
	end
	if Options.ForceRankedOff.Value and rankedDV and rankedDV:Get() == true then
		isolated(SignalEvent.ToServer, "QueueRanked", false)
	end
end

local userIdCache = {}
local function friendList()
	local list = {}
	for name in tostring(Options.FriendName.Value or ""):gmatch("[^,%s]+") do
		table.insert(list, name)
	end
	return list
end

local function resolveUserId(name)
	local key = name:lower()
	if userIdCache[key] == nil then
		local ok, id = isolated(Players.GetUserIdFromNameAsync, Players, name)
		userIdCache[key] = ok and id or false
	end
	return userIdCache[key] or nil
end

local function partyReady()
	local friends = friendList()
	if #friends == 0 then return true, {} end
	local members = {}
	if PartyWatcher then
		local ok, m = pcall(PartyWatcher.GetMembersInPlace, MENU_ID)
		if ok and type(m) == "table" then members = m end
	end
	local missing = {}
	for _, name in ipairs(friends) do
		local id = resolveUserId(name)
		local found = false
		for _, mem in pairs(members) do
			if (id and mem.UserId == id) or (type(mem.DisplayName) == "string" and mem.DisplayName:lower() == name:lower()) then
				found = true
				break
			end
		end
		if not found then table.insert(missing, name) end
	end
	return #missing == 0, missing
end

local function inviteFriends(names)
	if not SignalEvent then return end
	for _, name in ipairs(names) do
		isolated(SignalEvent.ToServer, "Invite To Party", name)
	end
end

local function openHub()
	local ok, btn = pcall(function()
		return player.PlayerGui.Components.Menu.OptionsHolder["3-HUB-Presenter"].Button
	end)
	if not ok or not btn then return false end
	return fireButton(btn, {"MouseButton1Click", "Activated"})
end

local function queueOuwigahara(mode)
	if not QueueSignal then return false, "Queue module not found." end
	if openHub() then task.wait(0.8) end
	if Validators then
		local ok, allowed, reason = pcall(Validators.HudGamemode, mode, player)
		if ok and not allowed then return false, reason or (mode .. " is locked for you.") end
	end
	local global = true
	if globalDV then global = globalDV:Get() == true end
	local fill = not Options.ForceFillOff.Value and fillDV and fillDV:Get() == true or false
	local ranked = not Options.ForceRankedOff.Value and rankedDV and rankedDV:Get() == true or false

	task.spawn(pcall, QueueSignal.ToServer, "Queue", mode, fill, ranked, global)
	local t = os.clock()
	repeat task.wait(0.25) until isQueued() or os.clock() - t > 8
	if not isQueued() then return false, "The game didn't start the queue (HUB closed or mode locked)." end
	return true
end

local function cancelQueue()
	if QueueSignal and isQueued() then isolated(QueueSignal.ToServer, "Cancel") end
end

local running = false
local session = {spins = 0, byRarity = {}, best = nil, started = os.time()}

local function isProtected(rarity)
	if not Options.ProtectClan.Value then return false end
	if not rarity then return true end
	return RANK[rarity] >= (RANK[Options.ProtectFrom.Value] or RANK.Legendary)
end

local function httpRequest(opts)
	local req = (env.syn and env.syn.request) or (env.http and env.http.request) or env.http_request or env.request
	if not req then return nil end
	return req(opts)
end

local function sessionTime()
	local s = os.time() - session.started
	if s >= 3600 then return string.format("%dh %02dm", s // 3600, (s % 3600) // 60) end
	return string.format("%dm %02ds", s // 60, s % 60)
end

local function rarityBreakdown()
	local lines = {}
	for i = #RARITIES, 1, -1 do
		local r = RARITIES[i]
		local n = session.byRarity[r] or 0
		if n > 0 then table.insert(lines, string.format("%s **%s** · `%d`", EMOJI[r], r, n)) end
	end
	return #lines > 0 and table.concat(lines, "\n") or "*No spins yet*"
end

local EVENTS = {
	spin = "🎰  New clan rolled",
	target = "🎯  Target clan obtained!",
	stop = "⏹️  Auto spin stopped",
	test = "🧪  Webhook connected",
	ore = "⛏️  Ore converted to spins",
}

local function sendWebhook(event, clan, rarity, reason)
	local url = Options.WebhookURL.Value
	if url == "" then return false end
	local description
	if clan then
		description = string.format("## %s %s\n> **%s** rarity  ·  %s chance", EMOJI[rarity] or "❔", clan, rarity or "?", CHANCE[rarity] or "?")
	else
		description = "> " .. (reason or "")
	end
	if event == "stop" and clan == nil and session.best then
		description ..= string.format("\n\nBest pull: %s **%s** (%s)", EMOJI[session.best.rarity], session.best.clan, session.best.rarity)
	end
	local embed = {
		author = {name = APP_NAME},
		title = EVENTS[event],
		description = description,
		color = rarity and COLORS[rarity] or (event == "stop" and 0x6E7360 or 0x8E9A4E),
		fields = {
			{name = "🎰 Session spins", value = "`" .. session.spins .. "`", inline = true},
			{name = "🎟️ Spins left", value = "`" .. tostring(getSpinsLeft() or "?") .. "`", inline = true},
			{name = "⏱️ Session time", value = "`" .. sessionTime() .. "`", inline = true},
			{name = "📊 Pulls by rarity", value = rarityBreakdown(), inline = false},
		},
		footer = {text = player.Name .. "  •  " .. APP_NAME .. " by " .. AUTHOR},
		timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
	}
	local payload = {username = APP_NAME, embeds = {embed}}
	if event == "target" and Options.PingTarget.Value then payload.content = "@everyone" end
	local ok, res = isolated(httpRequest, {
		Url = url, Method = "POST",
		Headers = {["Content-Type"] = "application/json"},
		Body = HttpService:JSONEncode(payload),
	})
	return ok and res ~= nil and (res.StatusCode == nil or (res.StatusCode >= 200 and res.StatusCode < 300))
end

local function runConversion(silentIfNothing)
	local keep = Options.KeepOre.Value
	local bought, spent, err = convertOre(keep)
	if err == "busy" then return 0 end
	if err == "nomodule" then
		notify("error", "Can't buy spins", "The game's shop modules were not found.")
		return 0
	end
	if bought > 0 then
		notify("success", "Ore converted", string.format("Bought %d spins for %d ore.", bought, spent))
		if Options.WebhookEnabled.Value and Options.WebhookOre.Value then
			task.spawn(sendWebhook, "ore", nil, nil, string.format("Bought **%d** spins for **%d** ore. Ore left: **%s**", bought, spent, tostring(getOre() or "?")))
		end
	elseif err then
		notify("error", "Purchase failed", err)
	elseif not silentIfNothing then
		notify("warn", "Not enough ore", string.format("You have %s ore — not enough for a pack (keeping %d).", tostring(getOre() or 0), keep))
	end
	return bought
end

local function spinOnce()
	local _, rarityBefore = getCurrentClan()
	if isProtected(rarityBefore) then return nil, nil, "protected" end
	local before = getSpinsLeft()
	if before == 0 then return nil, nil, "nospins" end
	if not pressSpin() then return nil, nil, "nobutton" end
	local t = os.clock()
	repeat task.wait(0.1) until os.clock() - t > 8 or (getSpinsLeft() or before) < (before or 0)
	task.wait(Options.SettleTime.Value)
	local clan, rarity = getCurrentClan()
	session.spins += 1
	if rarity then
		session.byRarity[rarity] = (session.byRarity[rarity] or 0) + 1
		if not session.best or RANK[rarity] > RANK[session.best.rarity] then
			session.best = {clan = clan, rarity = rarity}
		end
	end
	return clan, rarity
end

local REASONS = {
	protected = "Your current clan is protected. Turn protection off to spin.",
	nospins = "You are out of spins and ore.",
	nobutton = "Spin button not found. Open the clan menu first.",
}

local floatButton
local HomeTab = newTab("Home", "home")
local SpinTab = newTab("Clan Spin", "spin")
local OuwTab = newTab("Ouwigahara", "swords")
local ServerTab = newTab("Servers", "servers")
local HookTab = newTab("Webhook", "link")
local SettingsTab = newTab("Settings", "gear")

do
local RunService = game:GetService("RunService")
local Utility = tryRequire(function() return RS.CAM.Global.Utility end)
local GameSettings = tryRequire(function() return RS.CAM.Global.gameSettings end)
local Clans = tryRequire(function() return RS.CAM.Clans end)
local function getChar() return player.Character end
local homeCard = make("Frame", {Parent = HomeTab.container, LayoutOrder = nextOrder(HomeTab), Size = UDim2.new(1, 0, 0, 226), BackgroundColor3 = T.Element, BackgroundTransparency = 0.15, ClipsDescendants = true}, {corner(12)})
do
	local homeStroke = stroke(T.Accent, 0.6); homeStroke.Parent = homeCard
	accent(homeStroke, "Color")
	local glow = make("Frame", {Parent = homeCard, Size = UDim2.new(0.6, 0, 1, 0), BackgroundColor3 = T.Accent, BackgroundTransparency = 0.82, BorderSizePixel = 0}, {
		make("UIGradient", {Transparency = NumberSequence.new(0, 1)}),
	})
	accent(glow, "BackgroundColor3")

	local shine = make("UIGradient", {Parent = homeStroke, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(0.18, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 150, 150)), ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))})})
	homeStroke.Transparency = 0.35
	connect(RunService.Heartbeat, function(dt) shine.Rotation = (shine.Rotation + dt * 40) % 360 end)

	local lattice = make("Frame", {Parent = homeCard, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0.55, 0, 1, 0), BackgroundTransparency = 1, ClipsDescendants = true}, {
		make("UIGradient", {Transparency = NumberSequence.new(1, 0)}),
	})
	for i = -4, 14 do
		for _, rot in ipairs({35, -35}) do
			accent(make("Frame", {Parent = lattice, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, i * 34, 0.5, 0), Size = UDim2.fromOffset(1, 420),
				Rotation = rot, BackgroundColor3 = T.Accent, BackgroundTransparency = 0.93, BorderSizePixel = 0}), "BackgroundColor3")
		end
	end

	local function bracket(ax, ay)
		local sx, sy = ax == 0 and 1 or -1, ay == 0 and 1 or -1
		local function bar(w, h, ox, oy, tr)
			accent(make("Frame", {Parent = homeCard, AnchorPoint = Vector2.new(ax, ay), Position = UDim2.new(ax, sx * ox, ay, sy * oy),
				Size = UDim2.fromOffset(w, h), BackgroundColor3 = T.Accent, BackgroundTransparency = tr, BorderSizePixel = 0, ZIndex = 3}), "BackgroundColor3")
		end
		bar(22, 2, 5, 5, 0.1) bar(2, 22, 5, 5, 0.1)
		bar(12, 1, 10, 10, 0.45) bar(1, 12, 10, 10, 0.45)
		accent(make("Frame", {Parent = homeCard, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(ax, sx * 30, ay, sy * 6),
			Size = UDim2.fromOffset(5, 5), Rotation = 45, BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 3}), "BackgroundColor3")
		accent(make("Frame", {Parent = homeCard, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(ax, sx * 6, ay, sy * 30),
			Size = UDim2.fromOffset(5, 5), Rotation = 45, BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 3}), "BackgroundColor3")
	end
	bracket(0, 0) bracket(1, 0) bracket(0, 1) bracket(1, 1)

	local function divider(ay)
		local holder = make("Frame", {Parent = homeCard, AnchorPoint = Vector2.new(0.5, ay), Position = UDim2.new(0.62, 0, ay, ay == 0 and 3 or -3), Size = UDim2.fromOffset(150, 9), BackgroundTransparency = 1, ZIndex = 3})
		for side = -1, 1, 2 do
			accent(make("Frame", {Parent = holder, AnchorPoint = Vector2.new(side < 0 and 1 or 0, 0.5), Position = UDim2.new(0.5, side * 15, 0.5, 0), Size = UDim2.new(0.5, -15, 0, 1),
				BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 3}, {
				make("UIGradient", {Transparency = side < 0 and NumberSequence.new(1, 0.2) or NumberSequence.new(0.2, 1)}),
			}), "BackgroundColor3")
			local d = make("Frame", {Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, side * 10, 0.5, 0), Size = UDim2.fromOffset(4, 4), Rotation = 45,
				BackgroundTransparency = 1, ZIndex = 3})
			local ds = stroke(T.Accent, 0.2); ds.Parent = d accent(ds, "Color")
		end
		accent(make("Frame", {Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(7, 7), Rotation = 45,
			BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 3}), "BackgroundColor3")
	end
	divider(0) divider(1)
end

local avatarHolder = make("Frame", {Parent = homeCard, Position = UDim2.fromOffset(14, 14), Size = UDim2.fromOffset(150, 192), BackgroundColor3 = T.Bg, BackgroundTransparency = 0.3}, {corner(10)})
do
	local avStroke = stroke(T.Accent, 0.5); avStroke.Parent = avatarHolder
	accent(avStroke, "Color")
end
local viewport = make("ViewportFrame", {Parent = avatarHolder, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ImageTransparency = 1, Ambient = Color3.fromRGB(170, 170, 170), LightColor = Color3.fromRGB(255, 255, 255), LightDirection = Vector3.new(-0.5, -1, -0.8)}, {corner(10)})
local avatarLoading = label({Parent = avatarHolder, Size = UDim2.fromScale(1, 1), Text = "Loading…", Font = FONT, TextSize = 12, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Center})

local info = make("Frame", {Parent = homeCard, Position = UDim2.fromOffset(180, 16), Size = UDim2.new(1, -194, 1, -32), BackgroundTransparency = 1})
local hello = label({Parent = info, Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 0, 16), Text = "WELCOME BACK", Font = FONT_B, TextSize = 11, TextTransparency = 1})
accent(hello, "TextColor3")
local nameLabel = label({Parent = info, Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 28), Text = player.DisplayName, Font = FONT_B, TextSize = 24, TextTransparency = 1, TextTruncate = Enum.TextTruncate.AtEnd})
local userLabel = label({Parent = info, Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 16), Text = "@" .. player.Name, Font = FONT, TextSize = 13, TextColor3 = T.SubText, TextTransparency = 1})

local pills = make("Frame", {Parent = info, Position = UDim2.fromOffset(0, 74), Size = UDim2.new(1, 0, 0, 118), BackgroundTransparency = 1}, {
	make("UIPadding", {PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2)}),
	make("UIGridLayout", {CellSize = UDim2.new(0.5, -5, 0, 50), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder}),
})
local pillRefs = {}
local function pill(order, title)
	local f = make("Frame", {Parent = pills, LayoutOrder = order, BackgroundColor3 = T.Bg, BackgroundTransparency = 1}, {corner(8)})
	local s = stroke(T.Stroke, 1); s.Parent = f
	local t = label({Parent = f, Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -16, 0, 14), Text = title, Font = FONT, TextSize = 11, TextColor3 = T.SubText, TextTransparency = 1})
	local v = label({Parent = f, Position = UDim2.fromOffset(10, 22), Size = UDim2.new(1, -16, 0, 20), Text = "…", Font = FONT_B, TextSize = 15, TextTransparency = 1, TextTruncate = Enum.TextTruncate.AtEnd})
	pillRefs[order] = {f = f, s = s, t = t, v = v}
	return v
end
local levelValue = pill(1, "Level")
local artTitle
local artValue = pill(2, "Demon Art")
local clanValue = pill(3, "Clan")
local wenValue = pill(4, "Wen")

local homeTiles = make("Frame", {Parent = HomeTab.container, LayoutOrder = nextOrder(HomeTab), Size = UDim2.new(1, 0, 0, 62), BackgroundTransparency = 1}, {
	make("UIGridLayout", {CellSize = UDim2.new(0.25, -6, 0, 62), CellPadding = UDim2.fromOffset(8, 0), SortOrder = Enum.SortOrder.LayoutOrder}),
})
local tileVals = {}
for i, name in ipairs({"Session", "Players", "FPS", "Ping"}) do
	local f = make("Frame", {Parent = homeTiles, LayoutOrder = i, BackgroundColor3 = T.Element, BackgroundTransparency = 0.15}, {corner(10)})
	local s = stroke(T.Stroke, 0.7); s.Parent = f
	accent(make("Frame", {Parent = f, Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(4, 4), Rotation = 45, BorderSizePixel = 0}), "BackgroundColor3")
	label({Parent = f, Position = UDim2.fromOffset(22, 7), Size = UDim2.new(1, -30, 0, 14), Text = name, Font = FONT, TextSize = 11, TextColor3 = T.SubText})
	tileVals[name] = label({Parent = f, Position = UDim2.fromOffset(12, 26), Size = UDim2.new(1, -20, 0, 24), Text = "…", Font = FONT_B, TextSize = 17})
end
do
	local started, frames = os.clock(), 0
	connect(game:GetService("RunService").RenderStepped, function() frames += 1 end)
	task.spawn(function()
		while homeTiles.Parent do
			local el = math.floor(os.clock() - started)
			tileVals.Session.Text = string.format("%d:%02d:%02d", el // 3600, (el // 60) % 60, el % 60)
			tileVals.Players.Text = #Players:GetPlayers() .. " / " .. Players.MaxPlayers
			tileVals.FPS.Text = tostring(frames)
			frames = 0
			local ok, ping = pcall(function() return math.floor(player:GetNetworkPing() * 2000) end)
			tileVals.Ping.Text = ok and (ping .. " ms") or "—"
			task.wait(1)
		end
	end)
end

local credit = make("Frame", {Parent = HomeTab.container, LayoutOrder = nextOrder(HomeTab), Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = T.Element, BackgroundTransparency = 0.15}, {corner(10)})
local creditStroke = stroke(T.Stroke, 0.7); creditStroke.Parent = credit
app.drawMark(make("Frame", {Parent = credit, Position = UDim2.fromOffset(8, 11), Size = UDim2.fromOffset(36, 36), BackgroundTransparency = 1}), 34, 2)
label({Parent = credit, Position = UDim2.fromOffset(46, 10), Size = UDim2.new(1, -60, 0, 18), Text = APP_NAME .. " · Main Menu", Font = FONT_B, TextSize = 14})
label({Parent = credit, Position = UDim2.fromOffset(46, 30), Size = UDim2.new(1, -60, 0, 16), Text = "made by <b>" .. AUTHOR .. "</b>", RichText = true, Font = FONT, TextSize = 12, TextColor3 = T.SubText})
local function fmtNum(n)
	local s = tostring(math.floor(tonumber(n) or 0))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

local ART_COLORS = {
	Shockwave = "#3FA9FF", Tamari = "#FF8C1A", ["Blood Manipulation"] = "#FF2E3B", Pyrokenesis = "#FF6EC7",
	Arrow = "#3EDB5A", Cryokinesis = "#8FEAFF", Dream = "#B38CFF", ["Obi Manipulation"] = "#FFD23F",
	Reaper = "#8E5CFF", Thread = "#F2F2F2",
}
local BREATH_COLORS = {
	Water = "#3FA9FF", Flame = "#FF7A1A", Thunder = "#FFE14A", Wind = "#6FE39A", Stone = "#B4B4B4",
	Flower = "#FF8FC8", Insect = "#B98CFF", Serpent = "#E05CC4", Sound = "#FFB347", Beast = "#C08A5A",
}
local function colorFor(name, map)
	local hex = map[name]
	if not hex then
		for k, v in pairs(map) do
			if name:lower():find(k:lower(), 1, true) then hex = v break end
		end
	end
	return hex and fromHex(hex) or T.Text
end

local function refreshProfile()
	local data = Utility and select(2, isolated(Utility.GetData, player, true))
	if typeof(data) ~= "Instance" then return end
	pcall(function()
		local per = (GameSettings and GameSettings.expPerLevel) or 60
		levelValue.Text = tostring(math.floor(data.Exp.Goal.Value / per))
		local race = data.Race.Value
		local demonArt, breathing = data.Powers.DemonArt.Value, data.Powers.Breathing.Value
		if race == "Human" or (demonArt == "" and breathing ~= "") then
			pillRefs[2].t.Text = "Breathing"
			artValue.Text = breathing ~= "" and breathing or "None"
			artValue.TextColor3 = colorFor(breathing, BREATH_COLORS)
		else
			pillRefs[2].t.Text = race == "Hybrid" and "Demon Art · Hybrid" or "Demon Art"
			artValue.Text = demonArt ~= "" and demonArt or "None"
			artValue.TextColor3 = colorFor(demonArt, ART_COLORS)
		end
		local clan = data.Clan.Value
		clanValue.Text = (clan ~= "" and clan) or "None"
		local tier = Clans and Clans.TierOf and select(2, pcall(Clans.TierOf, clan))
		clanValue.TextColor3 = (type(tier) == "table" and typeof(tier.color) == "Color3") and tier.color or T.Text
		wenValue.Text = fmtNum(data.Wen.Value)
		wenValue.TextColor3 = Color3.fromRGB(245, 196, 81)
	end)
end

local avatarModel, avatarBase

local function cloneCharacter()
	local char = getChar()
	if not char then return nil end
	local was = char.Archivable
	char.Archivable = true
	local ok, clone = pcall(function() return char:Clone() end)
	char.Archivable = was
	if not ok or not clone then return nil end
	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("LuaSourceContainer") or d:IsA("BillboardGui") or d:IsA("Highlight") or d:IsA("Tool")
			or d:IsA("Sound") or d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail")
			or d:IsA("BodyMover") or d:IsA("Constraint") and not d:IsA("Motor6D") and d.Name ~= "AccessoryWeld" then
			pcall(function() d:Destroy() end)
		end
	end
	for _, n in ipairs({"RagdollConstraints", "NpcsFollowing", "Character Scripts"}) do
		local f = clone:FindFirstChild(n)
		if f then f:Destroy() end
	end
	return clone
end

local function buildAvatar()
	for _, c in ipairs(viewport:GetChildren()) do
		if c:IsA("WorldModel") or c:IsA("Camera") then c:Destroy() end
	end
	local model = cloneCharacter()
	if not model or not model:FindFirstChild("HumanoidRootPart") then
		avatarLoading.Text = "Avatar unavailable"
		return
	end
	local world = Instance.new("WorldModel")
	world.Parent = viewport
	model.Parent = world
	local root = model.HumanoidRootPart
	root.Anchored = true
	model:PivotTo(CFrame.new(0, 0, 0))
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then p.CanCollide = false end
	end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		pcall(function()
			local data = Utility and select(2, isolated(Utility.GetData, player, true))
			local anims = RS.Assets.Animations.mainPlace
			local idle = (typeof(data) == "Instance" and data.Race.Value == "Demon") and anims.demonIdle or anims.humanIdle
			local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
			animator:LoadAnimation(idle):Play(0)
		end)
	end
	local cam = Instance.new("Camera")
	cam.Parent = viewport
	viewport.CurrentCamera = cam
	cam.FieldOfView = 30

	local focus = root.Position + Vector3.new(0, 1.1, 0)
	cam.CFrame = CFrame.lookAt(focus + Vector3.new(-2.2, 0.6, -7.5), focus)
	avatarModel, avatarBase = model, model:GetPivot()
	avatarLoading.Text = ""
	tween(viewport, {ImageTransparency = 0}, 0.6)
end

local function playIntro()
	homeCard.Position = UDim2.fromOffset(0, 14)
	tween(homeCard, {Position = UDim2.fromOffset(0, 0)}, 0.5, Enum.EasingStyle.Back)
	for i, lbl in ipairs({hello, nameLabel, userLabel}) do
		lbl.TextTransparency = 1
		local p = lbl.Position
		lbl.Position = p + UDim2.fromOffset(16, 0)
		task.delay(0.08 * i, function()
			tween(lbl, {TextTransparency = 0, Position = p}, 0.45)
		end)
	end
	for i = 1, 4 do
		local r = pillRefs[i]
		r.f.BackgroundTransparency, r.s.Transparency, r.t.TextTransparency, r.v.TextTransparency = 1, 1, 1, 1
		task.delay(0.25 + 0.07 * i, function()
			tween(r.f, {BackgroundTransparency = 0.35}, 0.4)
			tween(r.s, {Transparency = 0.6}, 0.4)
			tween(r.t, {TextTransparency = 0}, 0.4)
			tween(r.v, {TextTransparency = 0}, 0.4)
		end)
	end
end
connect(HomeTab.button.MouseButton1Click, playIntro)

connect(RunService.RenderStepped, function()
	if avatarModel and avatarModel.Parent and main.Visible and HomeTab.page.Visible then
		avatarModel:PivotTo(avatarBase * CFrame.Angles(0, math.sin(os.clock() * 0.8) * 0.45, 0))
	end
end)

app.playIntro = playIntro

task.spawn(function()
	refreshProfile()
	buildAvatar()
	while gui.Parent do
		task.wait(5)
		refreshProfile()
	end
end)
connect(player.CharacterAdded, function() task.delay(3, function() if gui.Parent then buildAvatar() end end) end)
end

section(SpinTab, "Clan protection")
toggle(SpinTab, "ProtectClan", "Protect my current clan", true)
dropdown(SpinTab, "ProtectFrom", "Never spin if clan is at least", RARITIES, false, "Legendary")

section(SpinTab, "Auto spin")
dropdown(SpinTab, "TargetClans", "Stop when I get", clanLabels, true, {})
dropdown(SpinTab, "StopRarity", "Or stop at rarity", {"Off", "Common", "Uncommon", "Rare", "Legendary", "Mythic", "Supreme"}, false, "Off")
slider(SpinTab, "SettleTime", "Wait after spin", 1, 8, 1, 3, "s")

local function stopAuto(kind, title, reason, clan)
	running = false
	Options.AutoSpin:SetValue(false, true)
	notify(kind, title, reason)
	if Options.WebhookEnabled.Value and Options.WebhookStop.Value and not clan then
		task.spawn(sendWebhook, "stop", nil, nil, reason)
	end
end

local auto = toggle(SpinTab, "AutoSpin", "Auto spin", false, function(on)
	if not on then running = false return end
	if running then return end
	running = true
	task.spawn(function()
		while running do
			local clan, rarity, reason = spinOnce()
			if not running then break end
			if reason == "nospins" and Options.AutoBuyOre.Value then
				local before = getSpinsLeft() or 0
				if runConversion(true) > 0 then
					local t = os.clock()
					repeat task.wait(0.2) until (getSpinsLeft() or 0) > before or os.clock() - t > 5
					continue
				end
			end
			if reason then
				stopAuto("warn", "Auto spin stopped", REASONS[reason])
				break
			end
			local hit = clan and type(Options.TargetClans.Value) == "table" and Options.TargetClans.Value[clanLabel(clan)]
			local stopR = Options.StopRarity.Value
			local rarityHit = rarity and stopR ~= "Off" and RANK[rarity] >= RANK[stopR]
			if Options.WebhookEnabled.Value and rarity then
				if hit or rarityHit then
					task.spawn(sendWebhook, "target", clan, rarity)
				elseif RANK[rarity] >= RANK[Options.WebhookMin.Value] then
					task.spawn(sendWebhook, "spin", clan, rarity)
				end
			end
			if hit or rarityHit then
				stopAuto("success", "Target obtained!", string.format("%s (%s) — stopped after %d spins.", tostring(clan), tostring(rarity), session.spins), clan)
				break
			end
		end
	end)
end)
auto.NoSave = true

button(SpinTab, "Spin once", "Respects clan protection", function()
	local clan, rarity, reason = spinOnce()
	if reason then
		notify("warn", "Not spun", REASONS[reason])
	else
		notify("info", "You rolled " .. tostring(clan), string.format("%s rarity · %s chance", tostring(rarity), CHANCE[rarity] or "?"))
		if Options.WebhookEnabled.Value and rarity and RANK[rarity] >= RANK[Options.WebhookMin.Value] then
			task.spawn(sendWebhook, "spin", clan, rarity)
		end
	end
end)

section(SpinTab, "Ore → spins")
local oreButton = button(SpinTab, "Convert ore to spins", "Checking ore…", function()
	runConversion(false)
end)
slider(SpinTab, "KeepOre", "Keep this much ore", 0, 100, 1, 0)
toggle(SpinTab, "AutoBuyOre", "Auto convert ore (also when spins run out)", false)
note(SpinTab, "Buys the best-value ore packs first. Only ore is spent — never Robux.")

local partyPanel = make("Frame", {
	Parent = gui, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 24, 0.5, 0), Size = UDim2.fromOffset(270, 170),
	BackgroundColor3 = T.Bg, BackgroundTransparency = 0.08, Visible = false,
}, {corner(12)})
accent(make("UIStroke", {Parent = partyPanel, Transparency = 0.6, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}), "Color")
local partyScale = make("UIScale", {Parent = partyPanel, Scale = 0.94})
local partyTop = make("Frame", {Parent = partyPanel, Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1})
accent(make("Frame", {Parent = partyTop, Position = UDim2.fromOffset(14, 15), Size = UDim2.fromOffset(10, 10)}, {corner(5)}), "BackgroundColor3")
label({Parent = partyTop, Position = UDim2.fromOffset(32, 0), Size = UDim2.new(1, -80, 1, 0), Text = "Party", Font = FONT_B, TextSize = 14})
makeDraggable(partyTop, partyPanel)
make("Frame", {Parent = partyPanel, Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.Stroke, BackgroundTransparency = 0.5, BorderSizePixel = 0})

local friendBox = textBox(partyPanel, {Position = UDim2.fromOffset(12, 52), Size = UDim2.new(1, -24, 0, 30), PlaceholderText = "Friend's username (empty = solo)"})
local friendOpt = register("FriendName", "", function(v) friendBox.Text = v end)
connect(friendBox.FocusLost, function()
	local v = trim(friendBox.Text)
	if v ~= friendOpt.Value then
		friendOpt:SetValue(v)
		if v ~= "" then notify("info", "Party", "Auto join will wait for " .. v .. ".") end
	end
end)

local partyDot = make("Frame", {Parent = partyPanel, Position = UDim2.fromOffset(14, 97), Size = UDim2.fromOffset(8, 8), BackgroundColor3 = T.SubText}, {corner(4)})
local partyStatus = label({Parent = partyPanel, Position = UDim2.fromOffset(30, 90), Size = UDim2.new(1, -42, 0, 22), Text = "Solo", Font = FONT, TextSize = 12, TextColor3 = T.SubText, RichText = true, TextTruncate = Enum.TextTruncate.AtEnd})

local function panelButton(text, xScale, onClick)
	local b = make("TextButton", {
		Parent = partyPanel, Position = UDim2.new(xScale, xScale == 0 and 12 or 4, 1, -44), Size = UDim2.new(0.5, -16, 0, 32),
		BackgroundColor3 = T.Element, BackgroundTransparency = 0.15, AutoButtonColor = false, Text = text, Font = FONT_M, TextSize = 12, TextColor3 = T.Text,
	}, {corner(8)})
	local s = stroke(T.Stroke, 0.7); s.Parent = b
	local sc = make("UIScale", {Parent = b})
	connect(b.MouseEnter, function() tween(b, {BackgroundColor3 = T.Hover}) tween(s, {Color = T.Accent, Transparency = 0.4}) end)
	connect(b.MouseLeave, function() tween(b, {BackgroundColor3 = T.Element}) tween(s, {Color = T.Stroke, Transparency = 0.7}) tween(sc, {Scale = 1}) end)
	connect(b.MouseButton1Down, function() tween(sc, {Scale = 0.95}, 0.08) end)
	connect(b.MouseButton1Up, function() tween(sc, {Scale = 1}, 0.25, Enum.EasingStyle.Back) end)
	connect(b.MouseButton1Click, function() task.spawn(onClick) end)
	return b
end

panelButton("Invite", 0, function()
	local names = friendList()
	if #names == 0 then notify("warn", "No friend set", "Type your friend's username first.") return end
	inviteFriends(names)
	notify("success", "Invite sent", table.concat(names, ", "))
end)
panelButton("Solo (clear)", 0.5, function()
	friendOpt:SetValue("")
	notify("info", "Solo mode", "Auto join won't wait for anyone.")
end)

local function setPartyPanel(show)
	if show then
		partyPanel.Visible = true
		partyScale.Scale = 0.94
		tween(partyScale, {Scale = 1}, 0.3, Enum.EasingStyle.Back)
	else
		tween(partyScale, {Scale = 0.94}, 0.15)
		task.delay(0.15, function()
			if not (Options.ShowPartyPanel and Options.ShowPartyPanel.Value) then partyPanel.Visible = false end
		end)
	end
end

topButton(partyTop, "×", -10, function()
	Options.ShowPartyPanel:SetValue(false)
end)

section(OuwTab, "Auto join")
dropdown(OuwTab, "OuwMode", "Mode", {"Roguelike", "Normal"}, false, "Roguelike")
toggle(OuwTab, "AutoQueue", "Auto join Ouwigahara", false)
toggle(OuwTab, "ForceFillOff", "Always keep Fill Off", true, function(on) if on then task.spawn(enforceQueueSettings) end end)
toggle(OuwTab, "ForceRankedOff", "Always keep Ranked Off", true, function(on) if on then task.spawn(enforceQueueSettings) end end)
slider(OuwTab, "RequeueDelay", "Re-queue after cancel", 2, 20, 1, 5, "s")
button(OuwTab, "Cancel queue", "Leaves the current queue and stops auto join", function()
	Options.AutoQueue:SetValue(false)
	cancelQueue()
	notify("info", "Queue cancelled", "Auto join is off.")
end)

section(OuwTab, "Party")
toggle(OuwTab, "ShowPartyPanel", "Show party panel", true, function(on) setPartyPanel(on) end)
toggle(OuwTab, "AutoInvite", "Invite friend while waiting", true)
note(OuwTab, "Type a friend's name in the party panel and auto join waits until they're in your party in the menu. Leave it empty to play solo.")

section(ServerTab, "Private server")
input(ServerTab, "PrivateOwner", "Server code", "Private server code")
button(ServerTab, "Join private server", "Fills the game's private box and presses Join", function()
	local code = trim(Options.PrivateOwner.Value)
	if code == "" then
		notify("warn", "No code", "Type the private server code first.")
		return
	end
	joinPrivate(code)
end)
toggle(ServerTab, "AutoJoinPrivate", "Auto join when script starts", false)
note(ServerTab, "Joins the world selected in the game menu. The world below is used only if the menu button isn't available.")

section(ServerTab, "World")
dropdown(ServerTab, "ServerWorld", "World", worldNames, false, worldNames[1])
button(ServerTab, "Join public server", "Teleports to a normal server of this world", function()
	teleportTo(Options.ServerWorld.Value, nil)
end)

section(HookTab, "Discord")
input(HookTab, "WebhookURL", "Webhook URL", "https://discord.com/api/webhooks/...")
toggle(HookTab, "WebhookEnabled", "Send spin results", false)
dropdown(HookTab, "WebhookMin", "Only send from rarity", RARITIES, false, "Common")
toggle(HookTab, "WebhookStop", "Message when auto spin stops", true)
toggle(HookTab, "WebhookOre", "Message when ore is converted", true)
toggle(HookTab, "PingTarget", "Ping @everyone on target", false)
button(HookTab, "Test webhook", "Sends your current clan", function()
	if Options.WebhookURL.Value == "" then
		notify("warn", "No webhook URL", "Paste your Discord webhook URL first.")
		return
	end
	local clan, rarity = getCurrentClan()
	if sendWebhook("test", clan or "Tomioka", rarity or "Legendary") then
		notify("success", "Webhook connected", "Test message delivered to Discord.")
	else
		notify("error", "Webhook failed", "Discord rejected the request. Check the URL.")
	end
end)

section(SettingsTab, "General")
toggle(SettingsTab, "ShowFloatButton", "Show the round minimize button", true, function(on)
	if floatButton then floatButton.Visible = on end
end)
toggle(SettingsTab, "AntiAFK", "Anti-AFK (no 20 min idle kick)", true, function(on)
	if env.__AxiomSetAntiAFK then env.__AxiomSetAntiAFK(on) end
	notify(on and "success" or "info", "Anti-AFK", on and "On — you won't be kicked for idling." or "Off.")
end)

section(SettingsTab, "Theme")
colorPicker(SettingsTab, "AccentColor", "Accent color", "#8E9A4E")
input(SettingsTab, "CustomAccent", "Custom color", "#RRGGBB", function(v)
	if v == "" then return end
	if fromHex(v) then
		Options.AccentColor:SetValue("#" .. v:gsub("#", ""):upper())
	else
		notify("error", "Invalid color", "Use a hex code like #8E9A4E.")
	end
end)
slider(SettingsTab, "WindowOpacity", "Window opacity", 60, 100, 1, 92, "%", function(v)
	local t = 1 - v / 100
	tween(main, {BackgroundTransparency = t}, 0.2)
	tween(partyPanel, {BackgroundTransparency = t}, 0.2)
	tween(sidebar, {BackgroundTransparency = math.clamp(t + 0.22, 0, 1)}, 0.2)
end)

local function listProfiles()
	local names = {}
	if canFiles and listfiles and isfolder(PROFILE_DIR) then
		for _, path in ipairs(listfiles(PROFILE_DIR)) do
			local n = path:match("([^/\\]+)%.json$")
			if n then table.insert(names, n) end
		end
	end
	table.sort(names)
	return names
end

local function getAutoload()
	if canFiles and isfile(AUTOLOAD_FILE) then
		local ok, n = pcall(readfile, AUTOLOAD_FILE)
		if ok and n ~= "" then return n end
	end
	return nil
end

section(SettingsTab, "Configs")
local autoloadNote = note(SettingsTab, "")
local function updateAutoloadNote()
	local n = getAutoload()
	autoloadNote.Text = n and ("Autoload: <b>" .. n .. "</b>") or "Autoload: <b>off</b> — the last session is restored instead."
end
updateAutoloadNote()

local nameBox = input(SettingsTab, "ConfigName", "Config name", "e.g. Farm Supreme")
nameBox.NoSave = true
local configSelect = dropdown(SettingsTab, "ConfigSelect", "Saved configs", listProfiles(), false, "")
configSelect.NoSave = true

local function selectedProfile()
	local typed = trim(Options.ConfigName.Value):gsub("[^%w%s%-_]", "")
	if typed ~= "" then return typed end
	local picked = Options.ConfigSelect.Value
	return (picked and picked ~= "") and picked or nil
end

local function refreshProfiles(select)
	configSelect.SetValues(listProfiles())
	if select then configSelect:SetValue(select, true) end
end

button(SettingsTab, "Save config", "Saves current settings under the typed name", function()
	if not canFiles then notify("error", "Not supported", "Your executor can't write files.") return end
	local name = selectedProfile()
	if not name then notify("warn", "No name", "Type a config name or pick one from the list.") return end
	ensureDirs()
	local ok = pcall(writefile, PROFILE_DIR .. "/" .. name .. ".json", HttpService:JSONEncode(collect()))
	if ok then
		Options.ConfigName:SetValue("", true)
		refreshProfiles(name)
		notify("success", "Config saved", name)
	else
		notify("error", "Save failed", "Could not write " .. name .. ".json")
	end
end)

button(SettingsTab, "Load config", "Applies the selected config", function()
	local name = Options.ConfigSelect.Value
	if not name or name == "" then notify("warn", "Nothing selected", "Pick a config from the list.") return end
	local ok, data = pcall(function() return HttpService:JSONDecode(readfile(PROFILE_DIR .. "/" .. name .. ".json")) end)
	if ok and type(data) == "table" then
		applyData(data)
		notify("success", "Config loaded", name)
	else
		notify("error", "Load failed", name .. " could not be read.")
	end
end)

button(SettingsTab, "Delete config", "Removes the selected config file", function()
	local name = Options.ConfigSelect.Value
	if not name or name == "" then notify("warn", "Nothing selected", "Pick a config from the list.") return end
	local ok = pcall(delfile, PROFILE_DIR .. "/" .. name .. ".json")
	if ok then
		if getAutoload() == name then pcall(delfile, AUTOLOAD_FILE) end
		configSelect:SetValue("", true)
		refreshProfiles()
		updateAutoloadNote()
		notify("success", "Config deleted", name)
	else
		notify("error", "Delete failed", name)
	end
end)

button(SettingsTab, "Autoload selected", "Loads this config every time the script starts", function()
	local name = Options.ConfigSelect.Value
	if not name or name == "" then notify("warn", "Nothing selected", "Pick a config from the list.") return end
	ensureDirs()
	pcall(writefile, AUTOLOAD_FILE, name)
	updateAutoloadNote()
	notify("success", "Autoload set", name .. " will load on start.")
end)

button(SettingsTab, "Turn off autoload", nil, function()
	if canFiles and isfile(AUTOLOAD_FILE) then pcall(delfile, AUTOLOAD_FILE) end
	updateAutoloadNote()
	notify("info", "Autoload off", "The last session will be restored instead.")
end)

section(SettingsTab, "Script")
note(SettingsTab, "Press End to show or hide the window. The hub works only in the main menu.")
button(SettingsTab, "Unload " .. APP_NAME, "Stops everything and closes the UI", function() app.Destroy() end)

local visible, hintShown = true, false
local function setVisible(v)
	visible = v
	if v then
		main.Visible = true
		mainScale.Scale = 0.94
		tween(mainScale, {Scale = 1}, 0.3, Enum.EasingStyle.Back)
	else
		tween(mainScale, {Scale = 0.94}, 0.15)
		task.delay(0.15, function() if not visible then main.Visible = false end end)
	end
end

topButton(top, "–", -42, function()
	setVisible(false)
	if not hintShown then
		hintShown = true
		notify("info", "Window hidden", "Press End to bring it back.")
	end
end)
topButton(top, "×", -12, function() app.Destroy() end)

connect(UIS.InputBegan, function(i, gpe)
	if not gpe and i.KeyCode == Enum.KeyCode.End then setVisible(not visible) end
end)

do
	floatButton = make("TextButton", {
		Parent = gui, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 18, 0.5, 0), Size = UDim2.fromOffset(52, 52),
		BackgroundColor3 = Color3.fromRGB(22, 24, 18), BackgroundTransparency = 0.02, AutoButtonColor = false, Text = "", ZIndex = 20,
	}, {corner(12)})
	local fs = make("UIStroke", {Parent = floatButton, Thickness = 1.5, Transparency = 0.45, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
	accent(fs, "Color")
	app.drawMark(floatButton, 40, 21)
	local sc = make("UIScale", {Parent = floatButton})
	connect(floatButton.MouseEnter, function() tween(sc, {Scale = 1.08}, 0.2, Enum.EasingStyle.Back) end)
	connect(floatButton.MouseLeave, function() tween(sc, {Scale = 1}, 0.2) end)
	local downAt, downPos, startPos, dragging
	connect(floatButton.InputBegan, function(i)
		if i.UserInputType == MB1 or i.UserInputType == TOUCH then
			downAt, downPos, startPos, dragging = os.clock(), i.Position, floatButton.Position, false
		end
	end)
	connect(UIS.InputChanged, function(i)
		if downPos and (i.UserInputType == MOVE or i.UserInputType == TOUCH) then
			local d = i.Position - downPos
			if d.Magnitude > 6 then dragging = true end
			if dragging then
				floatButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end
	end)
	connect(UIS.InputEnded, function(i)
		if downPos and (i.UserInputType == MB1 or i.UserInputType == TOUCH) then
			if not dragging then
				tween(sc, {Scale = 0.9}, 0.08)
				task.delay(0.08, function() tween(sc, {Scale = 1}, 0.25, Enum.EasingStyle.Back) end)
				setVisible(not visible)
			end
			downPos = nil
		end
	end)
end

function app.Destroy()
	running = false
	for _, c in ipairs(app.connections) do pcall(function() c:Disconnect() end) end
	if gui.Parent then
		tween(mainScale, {Scale = 0.9}, 0.15)
		task.delay(0.15, function() gui:Destroy() end)
	end
	if env.__AxiomHUB == app then env.__AxiomHUB = nil end
end

do
	local loaded = false
	local autoName = getAutoload()
	if autoName and canFiles and isfile(PROFILE_DIR .. "/" .. autoName .. ".json") then
		local ok, data = pcall(function() return HttpService:JSONDecode(readfile(PROFILE_DIR .. "/" .. autoName .. ".json")) end)
		if ok and type(data) == "table" then
			applyData(data)
			loaded = true
			notify("success", "Config loaded", "Autoload: " .. autoName)
		end
	end
	if not loaded and canFiles then
		local file = isfile(LAST_FILE) and LAST_FILE or (isfile(OLD_LAST_FILE) and OLD_LAST_FILE or nil)
		if file then
			local ok, data = pcall(function() return HttpService:JSONDecode(readfile(file)) end)
			if ok and type(data) == "table" then applyData(data) end
		end
	end
	loading = false
	for k, v in pairs(AXIOM_CONFIG) do
		if Options[k] and type(v) == type(Options[k].Value) then pcall(Options[k].SetValue, Options[k], v, true) end
	end
	pcall(function()
		if isfile("AxiomHUB/requeue.flag") then
			local t = tonumber(readfile("AxiomHUB/requeue.flag")) or 0
			delfile("AxiomHUB/requeue.flag")
			if os.time() - t < 900 and Options.AutoQueue then Options.AutoQueue:SetValue(true, true) end
		end
	end)
	setPartyPanel(Options.ShowPartyPanel.Value)
	if env.__AxiomSetAntiAFK then env.__AxiomSetAntiAFK(Options.AntiAFK.Value) end
end

if Options.AutoJoinPrivate.Value then
	local code = trim(Options.PrivateOwner.Value)
	if code ~= "" then
		notify("info", "Auto join", "Joining private server " .. code .. " in 3s…", 3)
		task.delay(3, function()
			if gui.Parent and Options.AutoJoinPrivate.Value then joinPrivate(code) end
		end)
	end
end

task.spawn(function()
	local wasQueued = false
	local lastQueueEnd, lastInvite, lastQueueTry = 0, -100, -100
	local queueFails = 0
	local waitingFor = ""
	while gui.Parent do
		if Options.AutoQueue.Value then
			enforceQueueSettings()
			local queued = isQueued()
			if queued and not wasQueued then
				notify("success", "In queue", "Ouwigahara " .. Options.OuwMode.Value .. " · Fill Off · Ranked Off", 5)
			elseif not queued and wasQueued then
				lastQueueEnd = os.clock()
				notify("info", "Queue ended", "Re-queueing in " .. Options.RequeueDelay.Value .. "s if nothing happens.")
			end
			wasQueued = queued

			if not queued then
				local ready, missing = partyReady()
				if not ready then
					local who = table.concat(missing, ", ")
					if who ~= waitingFor then
						waitingFor = who
						notify("warn", "Waiting for party", who .. " isn't in your party in the menu yet.", 5)
					end
					if Options.AutoInvite.Value and os.clock() - lastInvite > 25 then
						lastInvite = os.clock()
						inviteFriends(missing)
					end
				else
					if waitingFor ~= "" then
						notify("success", "Party ready", waitingFor .. " joined — queueing now.")
						waitingFor = ""
					end
					if os.clock() - lastQueueEnd >= Options.RequeueDelay.Value and os.clock() - lastQueueTry >= 4 then
						lastQueueTry = os.clock()
						local ok, err = queueOuwigahara(Options.OuwMode.Value)
						if not ok then
							queueFails += 1
							notify("warn", "Queue retry " .. queueFails .. "/5", tostring(err))
							if queueFails >= 5 then
								notify("error", "Can't queue", "Gave up after 5 tries — auto join turned off.")
								Options.AutoQueue:SetValue(false)
								queueFails = 0
							end
						else
							queueFails = 0
						end
					end
				end
			end
		else
			wasQueued = false
			waitingFor = ""
		end
		task.wait(1)
	end
end)

task.spawn(function()
	local tickCount = 0
	while gui.Parent do
		local clan, rarity = getCurrentClan()
		local spins = getSpinsLeft()
		local ore = getOre()
		if not gui.Parent then break end
		if clan then
			status.Text = string.format('<font color="%s">%s · %s</font>   %s spins · %s ore', HEX[rarity] or "#ffffff", clan, rarity or "?", spins and tostring(spins) or "?", ore and tostring(ore) or "?")
		elseif isQueued() then
			status.Text = "In queue · Ouwigahara " .. tostring(Options.OuwMode.Value)
		else
			status.Text = "Main menu"
		end
		oreButton.SetDesc(ore and string.format("You have <b>%d</b> ore", ore) or "Ore balance unavailable here")

		local friends = friendList()
		if #friends == 0 then
			partyStatus.Text = "Solo — auto join won't wait"
			tween(partyDot, {BackgroundColor3 = T.SubText})
		else
			local ready, missing = partyReady()
			if ready then
				partyStatus.Text = '<font color="#6ec878">Ready</font> — ' .. table.concat(friends, ", ") .. " in party"
				tween(partyDot, {BackgroundColor3 = T.Good})
			else
				partyStatus.Text = "Waiting for <b>" .. table.concat(missing, ", ") .. "</b>"
				tween(partyDot, {BackgroundColor3 = T.Warn})
			end
		end

		tickCount += 1
		if tickCount % 10 == 0 and Options.AutoBuyOre.Value and not running and not converting then
			task.spawn(runConversion, true)
		end
		task.wait(1)
	end
end)

selectTab(tabs[1])

main.Visible = false
if floatButton then floatButton.Visible = false end
task.spawn(function()
	local Lighting = game:GetService("Lighting")
	local blur = Instance.new("BlurEffect")
	blur.Size = 0
	blur.Parent = Lighting
	local dim = make("Frame", {Parent = gui, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, ZIndex = 29})
	local card = make("Frame", {Parent = gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(640, 360),
		BackgroundColor3 = Color3.fromRGB(18, 19, 16), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 30}, {corner(16)})
	local cScale = make("UIScale", {Parent = card, Scale = 0.9})
	local cStroke = make("UIStroke", {Parent = card, Thickness = 1.5, Transparency = 1})
	accent(cStroke, "Color")
	local fades = {}
	local function fx(o, prop, shown) table.insert(fades, {o, prop, shown}) return o end

	local lattice = make("Frame", {Parent = card, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromScale(0.62, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 30}, {
		make("UIGradient", {Transparency = NumberSequence.new(1, 0)}),
	})
	for i = -3, 12 do
		for _, rot in ipairs({35, -35}) do
			fx(accent(make("Frame", {Parent = lattice, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, i * 40, 0.5, 0), Size = UDim2.fromOffset(1, 520),
				Rotation = rot, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 30}), "BackgroundColor3"), "BackgroundTransparency", 0.9)
		end
	end

	for _, c in ipairs({{0, 0}, {1, 0}, {0, 1}, {1, 1}}) do
		local ax, ay = c[1], c[2]
		local sx, sy = ax == 0 and 1 or -1, ay == 0 and 1 or -1
		fx(accent(make("Frame", {Parent = card, AnchorPoint = Vector2.new(ax, ay), Position = UDim2.new(ax, sx * 16, ay, sy * 16), Size = UDim2.fromOffset(24, 2), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 31}), "BackgroundColor3"), "BackgroundTransparency", 0.1)
		fx(accent(make("Frame", {Parent = card, AnchorPoint = Vector2.new(ax, ay), Position = UDim2.new(ax, sx * 16, ay, sy * 16), Size = UDim2.fromOffset(2, 24), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 31}), "BackgroundColor3"), "BackgroundTransparency", 0.1)
		fx(accent(make("Frame", {Parent = card, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(ax, sx * 46, ay, sy * 17), Size = UDim2.fromOffset(5, 5), Rotation = 45, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 31}), "BackgroundColor3"), "BackgroundTransparency", 0)
	end

	local markBox = make("Frame", {Parent = card, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.47), Size = UDim2.fromOffset(150, 150), BackgroundTransparency = 1, ZIndex = 31})
	local mk = app.drawMark(markBox, 150, 32)
	mk.scale.Scale = 0.3
	mk.outerStroke.Transparency, mk.innerStroke.Transparency = 1, 1
	for _, f in ipairs(mk.fills) do f.BackgroundTransparency = 1 end
	local pulse = make("Frame", {Parent = markBox, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(60, 60), Rotation = 45, BackgroundTransparency = 1, ZIndex = 31})
	local pulseStroke = make("UIStroke", {Parent = pulse, Thickness = 2, Transparency = 1})
	accent(pulseStroke, "Color")

	local textBox = make("Frame", {Parent = card, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 262, 0.47, 0), Size = UDim2.fromOffset(340, 110), BackgroundTransparency = 1, ZIndex = 31})
	local title = label({Parent = textBox, Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 58), Text = "", RichText = true, Font = FONT_B, TextSize = 54, ZIndex = 32})
	local line = make("Frame", {Parent = textBox, Position = UDim2.fromOffset(2, 80), Size = UDim2.fromOffset(0, 2), BorderSizePixel = 0, ZIndex = 32})
	accent(line, "BackgroundColor3")
	local tag = label({Parent = textBox, Position = UDim2.fromOffset(52, 72), Size = UDim2.new(1, -52, 0, 18), Text = "", Font = Enum.Font.Code, TextSize = 13, TextColor3 = Color3.fromRGB(169, 173, 156), ZIndex = 32})

	local bar = make("Frame", {Parent = card, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -34), Size = UDim2.fromOffset(220, 3), BackgroundColor3 = T.Off, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 31}, {corner(2)})
	local fill = make("Frame", {Parent = bar, Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, ZIndex = 32}, {corner(2)})
	accent(fill, "BackgroundColor3")
	local step = label({Parent = card, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.fromOffset(300, 14), Text = "", Font = FONT, TextSize = 11, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 31})
	local spin = game:GetService("RunService").RenderStepped:Connect(function(dt)
		mk.outer.Rotation = (mk.outer.Rotation + dt * 40) % 360
		mk.inner.Rotation = (mk.inner.Rotation - dt * 28) % 360
	end)

	tween(blur, {Size = 14}, 0.5)
	tween(dim, {BackgroundTransparency = 0.45}, 0.5)
	tween(card, {BackgroundTransparency = 0.02}, 0.4)
	tween(cStroke, {Transparency = 0.55}, 0.5)
	tween(cScale, {Scale = 1}, 0.6, Enum.EasingStyle.Back)
	for _, f in ipairs(fades) do tween(f[1], {[f[2]] = f[3]}, 0.8) end

	task.wait(0.25)
	tween(mk.scale, {Scale = 1}, 0.6, Enum.EasingStyle.Back)
	tween(mk.outerStroke, {Transparency = 0.45}, 0.5)
	tween(mk.innerStroke, {Transparency = 0.8}, 0.6)
	task.wait(0.2)
	tween(mk.legL, {BackgroundTransparency = 0}, 0.35)
	tween(mk.legR, {BackgroundTransparency = 0}, 0.35)
	task.wait(0.3)
	tween(mk.bar, {BackgroundTransparency = 0}, 0.3)
	local hubSize = mk.hub.Size
	mk.hub.Size = UDim2.fromOffset(0, 0)
	tween(mk.hub, {BackgroundTransparency = 0, Size = hubSize}, 0.4, Enum.EasingStyle.Back)
	tween(mk.apex, {BackgroundTransparency = 0}, 0.3)
	pulseStroke.Transparency = 0.2
	tween(pulse, {Size = UDim2.fromOffset(230, 230)}, 0.8, Enum.EasingStyle.Quad)
	tween(pulseStroke, {Transparency = 1, Thickness = 0.5}, 0.8, Enum.EasingStyle.Quad)
	task.wait(0.55)

	tween(markBox, {Position = UDim2.new(0, 160, 0.47, 0)}, 0.55, Enum.EasingStyle.Quint)
	task.wait(0.4)
	local hubHex = string.format("#%02X%02X%02X", T.Accent.R * 255, T.Accent.G * 255, T.Accent.B * 255)
	for i = 1, #APP_NAME do
		local t = APP_NAME:sub(1, i)
		title.Text = #t > 5 and (t:sub(1, 5) .. '<font color="' .. hubHex .. '">' .. t:sub(6) .. "</font>") or t
		task.wait(0.05)
	end
	tween(line, {Size = UDim2.fromOffset(40, 2)}, 0.3)
	local tagline = "SCRIPT HUB  ·  BY " .. string.upper(AUTHOR)
	for i = 1, #tagline do
		tag.Text = tagline:sub(1, i)
		task.wait(0.018)
	end
	tween(bar, {BackgroundTransparency = 0.3}, 0.3)
	for i, txt in ipairs({"Reading your clan…", "Checking the queue…", "Reading your profile…", "Ready"}) do
		step.Text = txt
		tween(fill, {Size = UDim2.fromScale(i / #{"Reading your clan…", "Checking the queue…", "Reading your profile…", "Ready"}, 1)}, 0.28)
		task.wait(0.3)
	end
	task.wait(0.35)

	tween(cScale, {Scale = 1.06}, 0.35)
	for _, o in ipairs(card:GetDescendants()) do
		if o:IsA("TextLabel") then tween(o, {TextTransparency = 1}, 0.3)
		elseif o:IsA("Frame") then tween(o, {BackgroundTransparency = 1}, 0.3)
		elseif o:IsA("UIStroke") then tween(o, {Transparency = 1}, 0.3) end
	end
	tween(card, {BackgroundTransparency = 1}, 0.35)
	tween(cStroke, {Transparency = 1}, 0.3)
	tween(dim, {BackgroundTransparency = 1}, 0.45)
	tween(blur, {Size = 0}, 0.45)
	task.wait(0.15)
	main.Visible = true
	mainScale.Scale = 0.85
	tween(mainScale, {Scale = 1}, 0.45, Enum.EasingStyle.Back)
	if app.playIntro then app.playIntro() end
	if floatButton then floatButton.Visible = Options.ShowFloatButton.Value end
	task.wait(0.35)
	spin:Disconnect()
	card:Destroy()
	dim:Destroy()
	blur:Destroy()
end)
notify("success", APP_NAME .. " loaded", "Welcome, " .. player.DisplayName .. ". Press End to toggle.")

end

local function AxiomOuwigahara()

do
	local genv = getgenv and getgenv() or _G
	if genv.__AxiomAntiAFK then pcall(function() genv.__AxiomAntiAFK:Disconnect() end) end
	local VirtualUser = game:GetService("VirtualUser")
	genv.__AxiomAntiAFK = game:GetService("Players").LocalPlayer.Idled:Connect(function()
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end)
end

local OUW_PLACE_ID = 75556147183481
if game.PlaceId ~= OUW_PLACE_ID then
	warn("[AxiomHUB] Ouwigahara farm works only in the Ouwigahara place — use the menu.")
	return
end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local env = getgenv and getgenv() or _G

local APP_NAME, AUTHOR = "AxiomHUB", "kingping77"

for _, key in ipairs({"__AxiomOuw"}) do
	if env[key] then pcall(env[key].Destroy) env[key] = nil end
end
local app = {connections = {}}
env.__AxiomOuw = app
local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(app.connections, c)
	return c
end

local function isolated(fn, ...)
	local args = table.pack(...)
	local done, result = false, nil
	task.spawn(function()
		result = table.pack(pcall(fn, table.unpack(args, 1, args.n)))
		done = true
	end)
	local started = os.clock()
	while not done and os.clock() - started < 15 do task.wait() end
	if not done then return false, "timed out" end
	return table.unpack(result, 1, result.n)
end

local T = {
	Accent = Color3.fromRGB(142, 154, 78),
	Bg = Color3.fromRGB(17, 18, 15),
	Surface = Color3.fromRGB(26, 28, 22),
	Element = Color3.fromRGB(33, 35, 28),
	Hover = Color3.fromRGB(43, 46, 36),
	Off = Color3.fromRGB(60, 63, 52),
	Text = Color3.fromRGB(234, 236, 226),
	SubText = Color3.fromRGB(156, 160, 144),
	Stroke = Color3.fromRGB(68, 72, 57),
	Warn = Color3.fromRGB(232, 182, 72),
	Error = Color3.fromRGB(232, 92, 92),
	Good = Color3.fromRGB(110, 200, 120),
}
local FONT, FONT_M, FONT_B = Enum.Font.Gotham, Enum.Font.GothamMedium, Enum.Font.GothamBold
local MB1, TOUCH, MOVE = Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch, Enum.UserInputType.MouseMovement

local function tween(obj, props, t, style)
	local tw = TweenService:Create(obj, TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function make(class, props, children)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then o[k] = v end
	end
	for _, c in ipairs(children or {}) do c.Parent = o end
	if props and props.Parent then o.Parent = props.Parent end
	return o
end
local function corner(r) return make("UICorner", {CornerRadius = UDim.new(0, r or 8)}) end
local function stroke(color, tr)
	return make("UIStroke", {Color = color or T.Stroke, Transparency = tr or 0.6, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
end
local function label(props)
	local base = {BackgroundTransparency = 1, Font = FONT_M, TextSize = 13, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left}
	for k, v in pairs(props) do base[k] = v end
	return make("TextLabel", base)
end

local function fromHex(h)
	h = tostring(h):gsub("#", ""):gsub("%s", "")
	if #h ~= 6 then return nil end
	local r, g, b = tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16)
	if not (r and g and b) then return nil end
	return Color3.fromRGB(r, g, b)
end

local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end

local function makeDraggable(handle, target)
	local dragging, startInput, startPos
	connect(handle.InputBegan, function(i)
		if i.UserInputType == MB1 or i.UserInputType == TOUCH then
			dragging, startInput, startPos = true, i.Position, target.Position
		end
	end)
	connect(UIS.InputChanged, function(i)
		if dragging and (i.UserInputType == MOVE or i.UserInputType == TOUCH) then
			local d = i.Position - startInput
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	connect(UIS.InputEnded, function(i)
		if i.UserInputType == MB1 or i.UserInputType == TOUCH then dragging = false end
	end)
end

local accentBound = {}
local function accent(obj, prop)
	table.insert(accentBound, {obj, prop})
	obj[prop] = T.Accent
	return obj
end

function app.drawMark(parent, size, z)
	local k = size / 200
	local holder = make("Frame", {Parent = parent, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, ZIndex = z})
	local m = {holder = holder, scale = make("UIScale", {Parent = holder})}
	local function box(cx, cy, w, h, rot, color, zz)
		local f = make("Frame", {Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx * k, cy * k), Size = UDim2.fromOffset(math.max(1, w * k), math.max(1, h * k)),
			Rotation = rot, BackgroundColor3 = color or T.Accent, BorderSizePixel = 0, ZIndex = z + (zz or 1)})
		if not color then accent(f, "BackgroundColor3") end
		return f
	end
	local function ring(side, thick, tr)
		local f = make("Frame", {Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(100 * k, 100 * k), Size = UDim2.fromOffset(side * k, side * k), Rotation = 45, BackgroundTransparency = 1, ZIndex = z})
		local st = make("UIStroke", {Parent = f, Thickness = math.max(1, thick * k), Transparency = tr})
		accent(st, "Color")
		return f, st
	end
	local ink = Color3.fromRGB(237, 238, 230)
	m.outer, m.outerStroke = ring(133, 3, 0.45)
	m.inner, m.innerStroke = ring(110, 1.5, 0.8)
	m.legL = box(79.5, 95, 21, 120, 20.4, ink)
	m.legR = box(120.5, 95, 21, 120, -20.4, ink)
	m.bar = box(100, 122, 48, 5, 0, nil, 2)
	m.hub = box(100, 122, 18, 18, 45, nil, 3)
	m.apex = box(100, 6, 8, 8, 45, nil, 3)
	m.fills = {m.legL, m.legR, m.bar, m.hub, m.apex}
	return m
end

local Options = {}
local CONFIG_DIR = "AxiomHUB"
local PROFILE_DIR = CONFIG_DIR .. "/configs"
local LAST_FILE = CONFIG_DIR .. "/ouwigahara.json"
local saveQueued, loading = false, true
local canFiles = writefile and readfile and isfile and isfolder and makefolder and true or false

local function ensureDirs()
	if not canFiles then return false end
	pcall(function()
		if not isfolder(CONFIG_DIR) then makefolder(CONFIG_DIR) end
		if not isfolder(PROFILE_DIR) then makefolder(PROFILE_DIR) end
	end)
	return true
end

local function collect()
	local data = {}
	for flag, o in pairs(Options) do
		if not o.NoSave then data[flag] = o.Value end
	end
	return data
end

local function saveConfig()
	if loading or saveQueued or not canFiles then return end
	saveQueued = true
	task.delay(1, function()
		saveQueued = false
		ensureDirs()
		pcall(writefile, LAST_FILE, HttpService:JSONEncode(collect()))
	end)
end

local function register(flag, value, apply)
	local o = {Value = value}
	function o:SetValue(v, silent)
		o.Value = v
		apply(v)
		if o.Callback and not silent then task.spawn(o.Callback, v) end
		saveConfig()
	end
	o.Refresh = function() apply(o.Value) end
	Options[flag] = o
	return o
end

local function applyData(data)
	loading = true
	for flag, v in pairs(data) do
		local o = Options[flag]
		if o and not o.NoSave then pcall(o.SetValue, o, v, true) end
	end
	loading = false
	saveConfig()
end

local function setAccent(c)
	T.Accent = c
	for _, b in ipairs(accentBound) do
		if b[1].Parent then tween(b[1], {[b[2]] = c}, 0.35) end
	end
	for _, o in pairs(Options) do
		if not o.NoRefresh then o.Refresh() end
	end
end

local gui = make("ScreenGui", {Name = "AxiomHUB_Ouw", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true, DisplayOrder = 50})
pcall(function()
	for _, c in ipairs(((gethui and gethui()) or game:GetService("CoreGui")):GetChildren()) do
		if c.Name == "AxiomHUB_Ouw" then c:Destroy() end
	end
end)
if not pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end) or not gui.Parent then
	gui.Parent = player:WaitForChild("PlayerGui")
end

local main = make("Frame", {
	Parent = gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(640, 470), BackgroundColor3 = T.Bg, BackgroundTransparency = 0.08, BorderSizePixel = 0,
}, {corner(12)})
accent(make("UIStroke", {Parent = main, Transparency = 0.65, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}), "Color")
local mainScale = make("UIScale", {Parent = main, Scale = 0.94})

local top = make("Frame", {Parent = main, Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1})
app.drawMark(make("Frame", {Parent = top, Position = UDim2.fromOffset(6, 7), Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1}), 28, 2)
label({Parent = top, Position = UDim2.fromOffset(42, 8), Size = UDim2.fromOffset(200, 18), Text = APP_NAME, Font = FONT_B, TextSize = 15})
label({Parent = top, Position = UDim2.fromOffset(42, 25), Size = UDim2.fromOffset(200, 14), Text = "Ouwigahara Normal", Font = FONT, TextSize = 11, TextColor3 = T.SubText})
local status = label({
	Parent = top, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -80, 0, 0), Size = UDim2.new(0, 300, 1, 0),
	Text = "", RichText = true, Font = FONT, TextSize = 12, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Right,
})
make("Frame", {Parent = main, Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.Stroke, BackgroundTransparency = 0.5, BorderSizePixel = 0})

local function topButton(parent, text, x, onClick)
	local b = make("TextButton", {
		Parent = parent, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, x, 0.5, 0), Size = UDim2.fromOffset(26, 26),
		BackgroundColor3 = T.Hover, BackgroundTransparency = 1, AutoButtonColor = false,
		Text = text, Font = FONT_B, TextSize = 14, TextColor3 = T.SubText, ZIndex = 3,
	}, {corner(7)})
	connect(b.MouseEnter, function() tween(b, {BackgroundTransparency = 0.2, TextColor3 = T.Text}) end)
	connect(b.MouseLeave, function() tween(b, {BackgroundTransparency = 1, TextColor3 = T.SubText}) end)
	connect(b.MouseButton1Click, onClick)
	return b
end

makeDraggable(top, main)

local sidebar = make("Frame", {Parent = main, Position = UDim2.fromOffset(10, 56), Size = UDim2.new(0, 140, 1, -66), BackgroundColor3 = T.Surface, BackgroundTransparency = 0.3}, {corner(10)})
local tabList = make("Frame", {Parent = sidebar, Size = UDim2.new(1, 0, 1, -54), BackgroundTransparency = 1}, {
	make("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}),
	make("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}),
})
local indicator = accent(make("Frame", {Parent = sidebar, Position = UDim2.fromOffset(4, 16), Size = UDim2.fromOffset(3, 18), ZIndex = 3}, {corner(2)}), "BackgroundColor3")

local footer = make("Frame", {Parent = sidebar, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1})
make("Frame", {Parent = footer, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -24, 0, 1), BackgroundColor3 = T.Stroke, BackgroundTransparency = 0.4, BorderSizePixel = 0})
accent(label({Parent = footer, Position = UDim2.fromOffset(14, 9), Size = UDim2.new(1, -28, 0, 16), Text = APP_NAME, Font = FONT_B, TextSize = 13}), "TextColor3")
label({Parent = footer, Position = UDim2.fromOffset(14, 26), Size = UDim2.new(1, -28, 0, 14), Text = "@" .. AUTHOR, Font = FONT, TextSize = 11, TextColor3 = T.SubText})

local content = make("Frame", {Parent = main, Position = UDim2.fromOffset(160, 56), Size = UDim2.new(1, -170, 1, -66), BackgroundTransparency = 1, ClipsDescendants = true})

local toasts = make("Frame", {Parent = gui, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -18, 1, -18), Size = UDim2.fromOffset(310, 380), BackgroundTransparency = 1}, {
	make("UIListLayout", {Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = Enum.SortOrder.LayoutOrder}),
})
local toastCount = 0
local KINDS = {
	success = {icon = "✓", color = function() return T.Accent end},
	info = {icon = "i", color = function() return T.Accent end},
	warn = {icon = "!", color = function() return T.Warn end},
	error = {icon = "×", color = function() return T.Error end},
}

local function notifyNow(kind, title, text, duration)
	duration = duration or 4
	local k = KINDS[kind] or KINDS.info
	local col = k.color()
	toastCount += 1

	local live = {}
	for _, c in ipairs(toasts:GetChildren()) do
		if c:IsA("Frame") then table.insert(live, c) end
	end
	if #live >= 4 then live[1]:Destroy() end

	local holder = make("Frame", {Parent = toasts, LayoutOrder = toastCount, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1})
	local card = make("Frame", {Parent = holder, Position = UDim2.fromOffset(340, 0), Size = UDim2.new(1, 0, 0, 72), BackgroundColor3 = T.Bg, BackgroundTransparency = 0.04, ClipsDescendants = true}, {corner(10), stroke(col, 0.55)})
	make("Frame", {Parent = card, Size = UDim2.new(0, 80, 1, 0), BackgroundColor3 = col, BackgroundTransparency = 0.88, BorderSizePixel = 0}, {
		make("UIGradient", {Transparency = NumberSequence.new(0, 1)}),
	})
	local icon = make("Frame", {Parent = card, Position = UDim2.fromOffset(14, 20), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = col, BackgroundTransparency = 0.78, ZIndex = 2}, {corner(15)})
	local iconStroke = stroke(col, 0.35); iconStroke.Parent = icon
	label({Parent = icon, Size = UDim2.fromScale(1, 1), Text = k.icon, Font = FONT_B, TextSize = 15, TextColor3 = col, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3})
	label({Parent = card, Position = UDim2.fromOffset(56, 10), Size = UDim2.new(1, -68, 0, 14), Text = APP_NAME:upper(), Font = FONT_B, TextSize = 10, TextColor3 = col, ZIndex = 2})
	label({Parent = card, Position = UDim2.fromOffset(56, 24), Size = UDim2.new(1, -68, 0, 18), Text = title, Font = FONT_B, TextSize = 13, ZIndex = 2})
	label({Parent = card, Position = UDim2.fromOffset(56, 42), Size = UDim2.new(1, -68, 0, 26), Text = text or "", Font = FONT, TextSize = 12, TextColor3 = T.SubText, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 2})
	local bar = make("Frame", {Parent = card, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = col, BorderSizePixel = 0, ZIndex = 3})
	local click = make("TextButton", {Parent = card, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 5})

	tween(holder, {Size = UDim2.new(1, 0, 0, 72)}, 0.25)
	tween(card, {Position = UDim2.fromOffset(0, 0)}, 0.45, Enum.EasingStyle.Back)
	tween(bar, {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear)

	local gone = false
	local function dismiss()
		if gone then return end
		gone = true
		tween(card, {Position = UDim2.fromOffset(340, 0)}, 0.3)
		task.delay(0.2, function()
			if holder.Parent then tween(holder, {Size = UDim2.new(1, 0, 0, 0)}, 0.2).Completed:Wait() end
			holder:Destroy()
		end)
	end
	click.MouseButton1Click:Connect(dismiss)
	click.MouseEnter:Connect(function() tween(card, {BackgroundColor3 = T.Surface}, 0.15) end)
	click.MouseLeave:Connect(function() tween(card, {BackgroundColor3 = T.Bg}, 0.15) end)
	task.delay(duration, dismiss)
end

local toastQueue = {}
local function notify(kind, title, text, duration)
	table.insert(toastQueue, {kind, title, text, duration})
end
task.spawn(function()
	while toasts.Parent do
		while #toastQueue > 0 do
			local t = table.remove(toastQueue, 1)
			pcall(notifyNow, t[1], t[2], t[3], t[4])
		end
		task.wait(0.15)
	end
end)

local tabs, current = {}, nil

local function selectTab(tab)
	if current == tab then return end
	local prev = current
	current = tab
	for _, t in ipairs(tabs) do
		local on = t == tab
		tween(t.button, {BackgroundTransparency = on and 0.15 or 1, TextColor3 = on and T.Text or T.SubText})
	end
	tween(indicator, {Position = UDim2.fromOffset(4, 14 + (tab.index - 1) * 34)}, 0.3)
	if prev then
		local p = prev.page
		tween(p, {GroupTransparency = 1, Position = UDim2.fromOffset(0, -8)}, 0.15)
		task.delay(0.15, function()
			if current ~= prev then p.Visible = false end
		end)
	end
	local pg = tab.page
	pg.Visible, pg.GroupTransparency, pg.Position = true, 1, UDim2.fromOffset(0, 12)
	tween(pg, {GroupTransparency = 0, Position = UDim2.fromOffset(0, 0)}, 0.28)
end

local function drawIcon(parent, key)
	local h = make("Frame", {Parent = parent, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -24, 0.5, 0), Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1})
	local ink = T.Text
	local function fill(x, y, w, hh, acc, r)
		local f = make("Frame", {Parent = h, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, hh), BackgroundColor3 = ink, BorderSizePixel = 0})
		if r then corner(r).Parent = f end
		if acc then accent(f, "BackgroundColor3") end
		return f
	end
	local function box(x, y, w, hh, acc, r)
		local f = make("Frame", {Parent = h, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, hh), BackgroundTransparency = 1})
		if r then corner(r).Parent = f end
		local s = make("UIStroke", {Parent = f, Thickness = 1.5, Color = ink, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
		if acc then accent(s, "Color") end
		return f
	end
	local function ring(cx, cy, d, acc) return box(cx - d / 2, cy - d / 2, d, d, acc, d) end
	local function dot(cx, cy, d, acc) return fill(cx - d / 2, cy - d / 2, d, d, acc, d) end
	local function rbox(cx, cy, s, acc)
		local f = make("Frame", {Parent = h, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy), Size = UDim2.fromOffset(s, s), Rotation = 45, BackgroundTransparency = 1})
		local st = make("UIStroke", {Parent = f, Thickness = 1.5, Color = ink})
		if acc then accent(st, "Color") end
	end
	local function rdot(cx, cy, s, acc)
		local f = make("Frame", {Parent = h, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy), Size = UDim2.fromOffset(s, s), Rotation = 45, BackgroundColor3 = ink, BorderSizePixel = 0})
		if acc then accent(f, "BackgroundColor3") end
	end
	if key == "home" then
		rbox(9, 9, 10)
		rdot(9, 9, 3, true)
	elseif key == "spin" then
		ring(9, 9, 14)
		dot(9, 9, 4, true)
	elseif key == "swords" then
		fill(1, 3, 16, 2, true, 1)
		fill(3, 7, 12, 2)
		fill(4, 3, 2, 13, nil, 1)
		fill(12, 3, 2, 13, nil, 1)
	elseif key == "target" then
		ring(9, 9, 14)
		ring(9, 9, 6, true)
	elseif key == "compass" then
		ring(9, 9, 14)
		fill(8, 4, 2, 6, true, 1)
		dot(9, 11, 2)
	elseif key == "heal" then
		fill(7, 3, 4, 12, true, 1)
		fill(3, 7, 12, 4, true, 1)
	elseif key == "map" then
		box(2, 3, 14, 12, nil, 2)
		fill(7, 3, 2, 12)
		dot(12, 7, 4, true)
	elseif key == "cards" then
		box(2, 4, 8, 12, nil, 2)
		box(8, 2, 8, 12, true, 2)
	elseif key == "shop" then
		box(2, 7, 14, 9, nil, 2)
		box(6, 2, 6, 7, true, 3)
	elseif key == "link" then
		rbox(6.5, 9, 6)
		rbox(11.5, 9, 6, true)
	elseif key == "gear" then
		fill(2, 3, 14, 2, nil, 1) fill(2, 8, 14, 2, nil, 1) fill(2, 13, 14, 2, nil, 1)
		dot(6, 4, 5) dot(12, 9, 5, true) dot(8, 14, 5)
	elseif key == "servers" then
		ring(9, 9, 14)
		box(6, 2, 6, 14, true, 3)
		fill(2, 8, 14, 2, nil, 1)
	elseif key == "coin" then
		ring(9, 9, 14)
		ring(9, 9, 6, true)
	elseif key == "player" then
		ring(9, 5, 6)
		box(3, 11, 12, 6, true, 3)
	elseif key == "eye" then
		box(1, 5, 16, 8, nil, 4)
		dot(9, 9, 4, true)
	else
		dot(9, 9, 6, true)
	end
	return h
end

local function newTab(name, icon)
	local index = #tabs + 1
	local btn = make("TextButton", {
		Parent = tabList, LayoutOrder = index, Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = T.Element, BackgroundTransparency = 1, AutoButtonColor = false,
		Text = name, Font = FONT_M, TextSize = 13, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Left,
	}, {corner(8), make("UIPadding", {PaddingLeft = UDim.new(0, icon and 34 or 14)})})
	if icon then drawIcon(btn, icon) end
	local page = make("CanvasGroup", {Parent = content, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, GroupTransparency = 1})
	local scroll = make("ScrollingFrame", {
		Parent = page, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
	}, {
		make("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}),
		make("UIPadding", {PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8)}),
	})
	accent(scroll, "ScrollBarImageColor3")
	local tab = {index = index, button = btn, page = page, container = scroll, order = 0}
	table.insert(tabs, tab)
	connect(btn.MouseEnter, function() if current ~= tab then tween(btn, {BackgroundTransparency = 0.55, TextColor3 = T.Text}) end end)
	connect(btn.MouseLeave, function() if current ~= tab then tween(btn, {BackgroundTransparency = 1, TextColor3 = T.SubText}) end end)
	connect(btn.MouseButton1Click, function() selectTab(tab) end)
	return tab
end

local function nextOrder(tab)
	tab.order += 1
	return tab.order
end

local function baseElement(tab, height, hitHeight)
	local f = make("Frame", {Parent = tab.container, LayoutOrder = nextOrder(tab), Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = T.Element, BackgroundTransparency = 0.15}, {corner(8)})
	local s = stroke(T.Stroke, 0.7); s.Parent = f
	local hit = make("TextButton", {Parent = f, Size = UDim2.new(1, 0, 0, hitHeight or height), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 1})
	connect(f.MouseEnter, function()
		tween(f, {BackgroundColor3 = T.Hover})
		tween(s, {Color = T.Accent, Transparency = 0.5})
	end)
	connect(f.MouseLeave, function()
		tween(f, {BackgroundColor3 = T.Element})
		tween(s, {Color = T.Stroke, Transparency = 0.7})
	end)
	return f, hit
end

local function section(tab, text)
	accent(label({Parent = tab.container, LayoutOrder = nextOrder(tab), Size = UDim2.new(1, 0, 0, 24), Text = string.upper(text), Font = FONT_B, TextSize = 11, TextYAlignment = Enum.TextYAlignment.Bottom}), "TextColor3")
end

local function note(tab, text)
	return label({Parent = tab.container, LayoutOrder = nextOrder(tab), Size = UDim2.new(1, 0, 0, 30), Text = text, Font = FONT, TextSize = 12, TextColor3 = T.SubText, TextWrapped = true, RichText = true})
end

local function toggle(tab, flag, title, default, callback)
	local f, hit = baseElement(tab, 40)
	label({Parent = f, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -70, 1, 0), Text = title})
	local sw = make("Frame", {Parent = f, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(38, 20), BackgroundColor3 = T.Off}, {corner(10)})
	local knob = make("Frame", {Parent = sw, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = T.Text}, {corner(7)})
	local o = register(flag, default, function(v)
		tween(sw, {BackgroundColor3 = v and T.Accent or T.Off}, 0.2)
		tween(knob, {Position = v and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)}, 0.3, Enum.EasingStyle.Back)
	end)
	o.Callback = callback
	o:SetValue(default, true)
	connect(hit.MouseButton1Click, function() o:SetValue(not o.Value) end)
	return o
end

local function button(tab, title, desc, callback)
	local h = desc and 48 or 40
	local f, hit = baseElement(tab, h)
	label({Parent = f, Position = UDim2.fromOffset(12, desc and 7 or 0), Size = UDim2.new(1, -40, 0, desc and 18 or h), Text = title})
	local descLabel
	if desc then
		descLabel = label({Parent = f, Position = UDim2.fromOffset(12, 26), Size = UDim2.new(1, -40, 0, 14), Text = desc, Font = FONT, TextSize = 11, TextColor3 = T.SubText, TextTruncate = Enum.TextTruncate.AtEnd, RichText = true})
	end
	local arrow = label({Parent = f, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(16, 16), Text = "›", Font = FONT_B, TextSize = 18, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Center})
	local sc = make("UIScale", {Parent = f})
	connect(f.MouseEnter, function() tween(arrow, {Position = UDim2.new(1, -8, 0.5, 0), TextColor3 = T.Accent}) end)
	connect(f.MouseLeave, function() tween(arrow, {Position = UDim2.new(1, -12, 0.5, 0), TextColor3 = T.SubText}) end)
	connect(hit.MouseButton1Down, function() tween(sc, {Scale = 0.97}, 0.08) end)
	connect(hit.MouseButton1Up, function() tween(sc, {Scale = 1}, 0.25, Enum.EasingStyle.Back) end)
	connect(hit.MouseLeave, function() tween(sc, {Scale = 1}, 0.2) end)
	connect(hit.MouseButton1Click, function() task.spawn(callback) end)
	return {SetDesc = function(text) if descLabel and descLabel.Text ~= text then descLabel.Text = text end end}
end

local function slider(tab, flag, title, min, max, step, default, suffix, callback)
	local f = baseElement(tab, 54)
	label({Parent = f, Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -90, 0, 20), Text = title})
	local val = accent(label({Parent = f, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 6), Size = UDim2.fromOffset(70, 20), Font = FONT_B, TextXAlignment = Enum.TextXAlignment.Right}), "TextColor3")
	local track = make("Frame", {Parent = f, Position = UDim2.new(0, 12, 0, 36), Size = UDim2.new(1, -24, 0, 6), BackgroundColor3 = T.Off, ZIndex = 2}, {corner(3)})
	local fill = accent(make("Frame", {Parent = track, Size = UDim2.fromScale(0, 1), ZIndex = 2}, {corner(3)}), "BackgroundColor3")
	local knob = make("Frame", {Parent = track, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = T.Text, ZIndex = 3}, {corner(6)})
	local o = register(flag, default, function(v)
		local a = (v - min) / (max - min)
		tween(fill, {Size = UDim2.fromScale(a, 1)}, 0.12)
		tween(knob, {Position = UDim2.fromScale(a, 0.5)}, 0.12)
		val.Text = string.format("%g", v) .. (suffix or "")
		if callback then callback(v) end
	end)
	o:SetValue(default, true)

	local dragging = false
	local function update(x)
		local a = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		local v = math.clamp(math.floor((min + a * (max - min)) / step + 0.5) * step, min, max)
		if v ~= o.Value then o:SetValue(v) end
	end
	local grab = make("TextButton", {Parent = f, Position = UDim2.new(0, 6, 0, 26), Size = UDim2.new(1, -12, 0, 24), BackgroundTransparency = 1, Text = "", ZIndex = 4})
	connect(grab.InputBegan, function(i)
		if i.UserInputType == MB1 or i.UserInputType == TOUCH then
			dragging = true
			tween(knob, {Size = UDim2.fromOffset(15, 15)}, 0.15)
			update(i.Position.X)
		end
	end)
	connect(UIS.InputChanged, function(i)
		if dragging and (i.UserInputType == MOVE or i.UserInputType == TOUCH) then update(i.Position.X) end
	end)
	connect(UIS.InputEnded, function(i)
		if dragging and (i.UserInputType == MB1 or i.UserInputType == TOUCH) then
			dragging = false
			tween(knob, {Size = UDim2.fromOffset(12, 12)}, 0.2, Enum.EasingStyle.Back)
		end
	end)
	return o
end

local function textBox(parent, props)
	local box = make("TextBox", {
		Parent = parent, BackgroundColor3 = T.Surface, BackgroundTransparency = 0.1, Text = "",
		PlaceholderColor3 = T.SubText, TextColor3 = T.Text, Font = FONT, TextSize = 12, ClearTextOnFocus = false,
		TextTruncate = Enum.TextTruncate.AtEnd, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2,
	}, {corner(6), make("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})})
	for k, v in pairs(props) do box[k] = v end
	local bs = stroke(T.Stroke, 0.6); bs.Parent = box
	connect(box.Focused, function() tween(bs, {Color = T.Accent, Transparency = 0.1}) end)
	connect(box.FocusLost, function() tween(bs, {Color = T.Stroke, Transparency = 0.6}) end)
	return box
end

local function input(tab, flag, title, placeholder, callback)
	local f = baseElement(tab, 40)
	label({Parent = f, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.4, 0, 1, 0), Text = title})
	local box = textBox(f, {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0.58, 0, 0, 26), PlaceholderText = placeholder or ""})
	local o = register(flag, "", function(v) box.Text = v end)
	o.Callback = callback
	connect(box.FocusLost, function()
		if box.Text ~= o.Value then o:SetValue(box.Text) end
	end)
	return o
end

local function dropdown(tab, flag, title, values, multi, default)
	local f, hit = baseElement(tab, 40, 40)
	f.ClipsDescendants = true
	label({Parent = f, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.45, 0, 0, 40), Text = title})
	local valueLabel = label({
		Parent = f, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -34, 0, 0), Size = UDim2.new(0.5, -20, 0, 40),
		Font = FONT, TextSize = 12, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local chevron = label({Parent = f, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -20, 0, 20), Size = UDim2.fromOffset(16, 16), Text = "›", Font = FONT_B, TextSize = 18, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Center, Rotation = 90})
	local list = make("ScrollingFrame", {
		Parent = f, Position = UDim2.fromOffset(6, 44), Size = UDim2.new(1, -12, 0, 30),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 2,
	}, {make("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder})})
	accent(list, "ScrollBarImageColor3")

	local items, o, open, listH = {}, nil, false, 30
	local function isOn(v)
		if multi then return type(o.Value) == "table" and o.Value[v] == true end
		return o.Value == v
	end
	local function paint(v, hover)
		local item, on = items[v], isOn(v)
		if not item then return end
		tween(item.btn, {BackgroundTransparency = on and 0.25 or (hover and 0.6 or 1), TextColor3 = (on or hover) and T.Text or T.SubText}, 0.15)
		tween(item.mark, {BackgroundTransparency = on and 0 or 1, Size = on and UDim2.fromOffset(6, 6) or UDim2.fromOffset(2, 2)}, 0.2)
	end
	local function refresh()
		if multi then
			local sel = {}
			for _, v in ipairs(values) do
				if isOn(v) then table.insert(sel, v) end
			end
			valueLabel.Text = #sel == 0 and "None" or (#sel <= 2 and table.concat(sel, ", ") or (#sel .. " selected"))
		else
			valueLabel.Text = (o.Value == nil or o.Value == "") and "None" or tostring(o.Value)
		end
		for _, v in ipairs(values) do paint(v, false) end
	end
	local function setOpen(state)
		open = state
		tween(f, {Size = UDim2.new(1, 0, 0, state and (48 + listH) or 40)}, 0.28)
		tween(chevron, {Rotation = state and 270 or 90, TextColor3 = state and T.Accent or T.SubText}, 0.28)
	end
	local function build()
		for _, it in pairs(items) do it.btn:Destroy() end
		items = {}
		listH = math.max(1, math.min(#values, 6)) * 30
		list.Size = UDim2.new(1, -12, 0, listH)
		for i, v in ipairs(values) do
			local b = make("TextButton", {
				Parent = list, LayoutOrder = i, Size = UDim2.new(1, -6, 0, 28), BackgroundColor3 = T.Hover, BackgroundTransparency = 1,
				AutoButtonColor = false, Text = v, Font = FONT, TextSize = 12, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2,
			}, {corner(6), make("UIPadding", {PaddingLeft = UDim.new(0, 22)})})
			local mark = accent(make("Frame", {Parent = b, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, -11, 0.5, 0), Size = UDim2.fromOffset(2, 2), BackgroundTransparency = 1, ZIndex = 3}, {corner(3)}), "BackgroundColor3")
			items[v] = {btn = b, mark = mark}
			b.MouseEnter:Connect(function() paint(v, true) end)
			b.MouseLeave:Connect(function() paint(v, false) end)
			b.MouseButton1Click:Connect(function()
				if multi then
					local t = table.clone(type(o.Value) == "table" and o.Value or {})
					t[v] = (not t[v]) or nil
					o:SetValue(t)
				else
					o:SetValue(v)
					setOpen(false)
				end
			end)
		end
	end

	o = register(flag, default, function() refresh() end)
	function o.SetValues(newValues)
		values = newValues
		build()
		refresh()
		if open then setOpen(true) end
	end
	build()
	connect(hit.MouseButton1Click, function() setOpen(not open) end)
	o:SetValue(default, true)
	return o
end

local PRESETS = {
	{"Olive", "#8E9A4E"}, {"Sage", "#7FA37A"}, {"Ocean", "#4F8FD6"}, {"Violet", "#9071D9"},
	{"Rose", "#D9708E"}, {"Crimson", "#D65252"}, {"Amber", "#D9A040"}, {"Mint", "#4FC2A0"}, {"Ice", "#9FB8C9"},
}
local function colorPicker(tab, flag, title, default)
	local f = baseElement(tab, 70)
	label({Parent = f, Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -110, 0, 20), Text = title})
	local nameLabel = label({Parent = f, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 6), Size = UDim2.fromOffset(120, 20), Font = FONT, TextSize = 12, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Right})
	local row = make("Frame", {Parent = f, Position = UDim2.fromOffset(12, 34), Size = UDim2.new(1, -24, 0, 26), BackgroundTransparency = 1, ZIndex = 2}, {
		make("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 9), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}),
	})
	local rings = {}
	local o = register(flag, default, function(v)
		local c = fromHex(v)
		if c then setAccent(c) end
		local name = "Custom"
		for _, p in ipairs(PRESETS) do
			local on = p[2]:upper() == tostring(v):upper()
			if on then name = p[1] end
			if rings[p[2]] then tween(rings[p[2]], {Transparency = on and 0 or 1}, 0.2) end
		end
		nameLabel.Text = name .. "  " .. tostring(v):upper()
	end)
	o.NoRefresh = true
	for i, p in ipairs(PRESETS) do
		local sw = make("TextButton", {Parent = row, LayoutOrder = i, Size = UDim2.fromOffset(22, 22), BackgroundColor3 = fromHex(p[2]), Text = "", AutoButtonColor = false, ZIndex = 2}, {corner(11)})
		rings[p[2]] = make("UIStroke", {Parent = sw, Color = T.Text, Thickness = 2, Transparency = 1})
		local sc = make("UIScale", {Parent = sw})
		connect(sw.MouseEnter, function() tween(sc, {Scale = 1.18}, 0.2, Enum.EasingStyle.Back) end)
		connect(sw.MouseLeave, function() tween(sc, {Scale = 1}, 0.2) end)
		connect(sw.MouseButton1Click, function() o:SetValue(p[2]) end)
	end
	o:SetValue(default, true)
	return o
end

local function runHub()

local RunService = game:GetService("RunService")
local function tryRequire(path)
	local ok, m = pcall(function() return require(path()) end)
	return ok and m or nil
end
local SignalEvent = tryRequire(function() return RS.Communication.ServerAndClient.Signals.SignalEvent end)
local Platform = tryRequire(function() return RS.CAM.Client.Controllers.Platform_Handler end)
local SkillCtl = tryRequire(function() return RS.CAM.Client.Controllers.Skill_Controller end)
local SkillsMod = tryRequire(function() return RS.CAM.Global.Skills_Module end)
local Utility = tryRequire(function() return RS.CAM.Global.Utility end)
local GameSettings = tryRequire(function() return RS.CAM.Global.gameSettings end)
local PlayerProfile = tryRequire(function() return RS.CAM.Global.PlayerProfile end)
local Clans = tryRequire(function() return RS.CAM.Clans end)
local DoubleJump = tryRequire(function() return RS.Skills.Misc["Double Jump"] end)
local Controls
pcall(function() Controls = require(player.PlayerScripts:WaitForChild("PlayerModule", 5)):GetControls() end)
local StatsMod
pcall(function()
	for _, d in ipairs(RS.CAM.Global:GetDescendants()) do
		if d.Name == "Stats" and d:IsA("ModuleScript") then StatsMod = require(d) break end
	end
end)

local OUW = RS:FindFirstChild("Minigames Place") and RS["Minigames Place"].Minigames:FindFirstChild("Ouwigahara")

local function getChar() return player.Character end
local function getRoot() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c = getChar() return c and c:FindFirstChildOfClass("Humanoid") end

local logQueue = {}

local dbg = {history = {}, casts = 0, fails = 0, kills = 0, floors = 0, blocks = 0, hits = 0, hitsBlocked = 0, stuns = 0, heals = 0,
	lastSkill = "-", lastSkillAt = 0, skillStats = {}, refusedRow = {}, hitBuf = nil, lastStunAt = 0, floorStart = os.clock(), fps = 60, file = CONFIG_DIR .. "/log.txt"}
if canFiles then
	pcall(function()
		if not isfolder(CONFIG_DIR) then makefolder(CONFIG_DIR) end
		if isfile(dbg.file) then writefile(CONFIG_DIR .. "/log_prev.txt", readfile(dbg.file)) end
		writefile(dbg.file, "=== AxiomHUB session " .. os.date("%Y-%m-%d %H:%M:%S") .. " ===\n")
	end)
end
local function dlog(kind, text)
	local entry = {kind = kind, text = text, t = os.date("%H:%M:%S")}
	table.insert(logQueue, entry)
	if #logQueue > 60 then table.remove(logQueue, 1) end
	table.insert(dbg.history, entry)
	if #dbg.history > 300 then table.remove(dbg.history, 1) end
	if canFiles and appendfile then pcall(appendfile, dbg.file, entry.t .. " [" .. kind .. "] " .. tostring(text) .. "\n") end
end

local function vlog(kind, text)
	if Options.VerboseLog == nil or Options.VerboseLog.Value then dlog(kind, text) end
end

local function request(data)
	if SignalEvent then task.spawn(pcall, SignalEvent.ToServer, "OuwigaharaRequest", data) end
end

local lastRealMap
local function currentMap()
	local a = workspace:GetAttribute("MinigameMap")
	if type(a) == "string" and a ~= "" and a ~= "LightsOut" then lastRealMap = a end
	return lastRealMap
end
local function floorNum() return tonumber(workspace:GetAttribute("MinigameFloor")) or 0 end
local function runState() return tostring(workspace:GetAttribute("MinigameState") or "?") end
local function inRun()
	local s = runState()
	return s ~= "Lobby" and s ~= "?" and workspace:GetAttribute("MinigameKey") == "Ouwigahara"
end

local enemyCache, enemyCacheAt = {}, 0
local function getEnemies()
	if os.clock() - enemyCacheAt < 0.2 then return enemyCache end
	enemyCacheAt = os.clock()
	local out, seen = {}, {}
	local H = workspace:FindFirstChild("Humanoids")
	local roots = {}
	if H then
		if H:FindFirstChild("Regions") then table.insert(roots, H.Regions) end
		local mine = H:FindFirstChild(player.Name)
		mine = mine and mine:FindFirstChild("NpcsFollowing")
		if mine then table.insert(roots, mine) end
	end
	for _, r in ipairs(roots) do
		for _, hum in ipairs(r:GetDescendants()) do
			if hum:IsA("Humanoid") then
				local m = hum.Parent
				if m and not seen[m] and not Players:GetPlayerFromCharacter(m) and hum.Health > 0 then
					seen[m] = true
					local root = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
					if root then table.insert(out, {model = m, hum = hum, root = root}) end
				end
			end
		end
	end
	enemyCache = out
	return out
end

local losParams = RaycastParams.new()
losParams.FilterType = Enum.RaycastFilterType.Exclude
losParams.RespectCanCollide = true
local function clearShot(e)
	local root = getRoot()
	if not root then return false end
	local filter = {getChar(), workspace:FindFirstChild("Humanoids"), workspace:FindFirstChild("Debree")}
	losParams.FilterDescendantsInstances = filter

	local under = workspace:Raycast(root.Position, Vector3.new(0, -10, 0), losParams)
	if under then
		table.insert(filter, under.Instance)
		losParams.FilterDescendantsInstances = filter
	end

	local flat = e.root.Position - root.Position
	flat = Vector3.new(flat.X, 0, flat.Z)
	local step = flat.Magnitude > 0.1 and flat.Unit * 3 or Vector3.zero
	for _, off in ipairs({Vector3.new(0, 1.5, 0), Vector3.new(0, 7, 0), step + Vector3.new(0, 3, 0)}) do
		local from = root.Position + off
		local hit = workspace:Raycast(from, e.root.Position - from, losParams)
		if hit == nil or hit.Instance:IsDescendantOf(e.model) then return true end
	end
	return false
end

local aimTarget = nil
local aimEnabled = false
if Platform then
	env.__AxiomOrigMousepos = env.__AxiomOrigMousepos or Platform.mousepos
	local orig = env.__AxiomOrigMousepos
	Platform.mousepos = function(range, params, skill)
		local t = aimTarget
		if aimEnabled and typeof(t) == "Vector3" then
			if range then
				local root = getRoot()
				if root then
					local d = t - root.Position
					if d.Magnitude > range then return root.Position + d.Unit * range end
				end
			end
			return t
		end
		return orig(range, params, skill)
	end
end
local function restoreAim()
	if Platform and env.__AxiomOrigMousepos then Platform.mousepos = env.__AxiomOrigMousepos end
end

local currentTarget
local function targetPos(e)
	local p = e.root.Position
	local lead = (Options.AimLead and Options.AimLead.Value or 0) / 100
	local v = e.root.AssemblyLinearVelocity
	return p + Vector3.new(v.X, 0, v.Z) * lead
end
local function updateAim()
	if currentTarget and currentTarget.hum.Health > 0 and currentTarget.root.Parent then
		aimTarget = targetPos(currentTarget)
	end
end

local blockedCount = 0
local function pickTarget(maxRange, ignoreLOS)
	local root = getRoot()
	if not root then return nil end
	local best, bestScore
	blockedCount = 0
	for _, e in ipairs(getEnemies()) do
		local dist = (e.root.Position - root.Position).Magnitude
		if dist <= maxRange then
			if not ignoreLOS and Options.NeedLOS.Value and not clearShot(e) then
				blockedCount += 1
			else
				local score = Options.TargetMode.Value == "Weakest mob (lowest HP)" and e.hum.Health or dist
				if not bestScore or score < bestScore then best, bestScore = e, score end
			end
		end
	end
	return best
end

local SKILL_TIMES = {
	["Spiraling Shot"] = {hold = 0.25, after = 1.9},
	["Meteor"] = {hold = 3.0, after = 0.4},
	["Spinning Throw"] = {hold = 2.6, after = 0.5},
	["Dunk"] = {hold = 0.35, after = 1.5},
	["Piercing Kick"] = {hold = 0.2, after = 1.7},
}
local TAMARI = {"Spiraling Shot", "Meteor", "Spinning Throw", "Dunk", "Piercing Kick"}
local NOT_ATTACKS = {Blocking = true, Dash = true, ["Double Jump"] = true, ["Wall Climb"] = true, ["Flashing Willow Aerial"] = true, ["Compass Needle"] = true}

local InputHandler = tryRequire(function() return RS.CAM.Client.Components.Client.InputHandler end)
local blockWanted = false
if InputHandler and InputHandler.IsDown then
	env.__AxiomOrigIsDown = env.__AxiomOrigIsDown or InputHandler.IsDown
	local origIsDown = env.__AxiomOrigIsDown
	InputHandler.IsDown = function(name, ...)
		if blockWanted and name == "Skills_1st" then return true end
		return origIsDown(name, ...)
	end
end

local RunHandler = tryRequire(function() return RS.CAM.Client.Modules.GamePlay.Run_Handler end)
if RunHandler and RunHandler.SetShiftLock then
	env.__AxiomOrigShiftLock = env.__AxiomOrigShiftLock or RunHandler.SetShiftLock
	local origShift = env.__AxiomOrigShiftLock
	RunHandler.SetShiftLock = function(v, ...)
		if v == 1 and Options.Farm and Options.Farm.Value and Options.NoShiftLock and Options.NoShiftLock.Value then
			return origShift(0, ...)
		end
		return origShift(v, ...)
	end
end

local function skillCategory(name)
	local info = PlayerProfile and PlayerProfile.skill_info and PlayerProfile.skill_info[name]
	return info and info.CategoryType
end

local function availableSkills()
	local list = {}
	if not (StatsMod and PlayerProfile and PlayerProfile.skill_info) then return list end
	for name in pairs(PlayerProfile.skill_info) do
		if not NOT_ATTACKS[name] then
			local ok, has = pcall(StatsMod.SourceCheck, player, name)
			if ok and has then table.insert(list, name) end
		end
	end
	table.sort(list, function(a, b)
		local ta, tb = table.find(TAMARI, a), table.find(TAMARI, b)
		if ta and tb then return ta < tb end
		if ta or tb then return ta ~= nil end
		local ea, eb = skillCategory(a) == "Evil Art", skillCategory(b) == "Evil Art"
		if ea ~= eb then return ea end
		return a < b
	end)
	return list
end

local function skillTimes(name)
	local t = SKILL_TIMES[name]
	return {key = name, hold = t and t.hold or Options.DefaultHold.Value, after = t and t.after or 0.5}
end

local skillFail = {}
local skillList = {}
local casting = false

local function getSHC()
	local c = getChar()
	return c and c:FindFirstChild("SHC")
end

local function releaseStuck()
	local shc = getSHC()
	if shc and shc.Value ~= "" and shc:GetAttribute("en") ~= true and SkillCtl then
		pcall(SkillCtl.StopHold, shc.Value)
	end
end

local function skillReady(sk)
	if not (SkillCtl and SkillsMod) then return false end
	if skillFail[sk.key] and os.clock() - skillFail[sk.key] < 3 then return false end
	if StatsMod then
		local ok, has = pcall(StatsMod.SourceCheck, player, sk.key)
		if ok and not has then return false end
	end
	local ok, r = pcall(SkillsMod.Can_Skill, player, sk.key)
	if not ok then return true end
	return r == true
end

local function castSkill(sk)
	casting = true
	releaseStuck()
	local done, res = false, nil
	task.spawn(function()
		local ok, r = pcall(SkillCtl.Attempt_Hold, sk.key)
		res = ok and r or nil
		done = true
	end)
	local t0 = os.clock()

	while not done and os.clock() - t0 < 6 do updateAim() task.wait(0.03) end
	if res == true then
		dbg.casts += 1
		dbg.refusedRow[sk.key] = 0
		dbg.lastSkill, dbg.lastSkillAt = sk.key, os.clock()
		dlog("skill", sk.key .. (currentTarget and (" → " .. currentTarget.model.Name) or ""))

		do
			local before, blockedBy = {}, {}
			for _, e in ipairs(getEnemies()) do
				before[e.hum] = e.hum.Health
				blockedBy[e.model] = e.model:GetAttribute("LastBlockedHitTime")
			end
			task.delay(sk.hold + 2.2, function()
				local dmg, blk = 0, 0
				for h, hp in pairs(before) do dmg += math.max(0, hp - math.max(h.Health, 0)) end
				for m, v in pairs(blockedBy) do if m.Parent and m:GetAttribute("LastBlockedHitTime") ~= v then blk += 1 end end
				local st = dbg.skillStats[sk.key] or {n = 0, dmg = 0, blocked = 0, zero = 0}
				dbg.skillStats[sk.key] = st
				st.n += 1
				st.dmg += dmg
				if blk > 0 then st.blocked += 1 end
				if dmg < 0.5 then st.zero += 1 end
				vlog("dbg", string.format("   ↳ %s: %s%s", sk.key, dmg >= 0.5 and (math.floor(dmg + 0.5) .. " dmg") or "no damage",
					blk > 0 and (" · blocked by " .. blk) or ""))
			end)
		end
		while os.clock() - t0 < sk.hold do updateAim() task.wait(0.05) end
		local t1 = os.clock()
		repeat
			updateAim()
			local ok, r = pcall(SkillCtl.StopHold, sk.key)
			if ok and r then break end
			local shc = getSHC()
			if shc and shc.Value ~= sk.key and shc:GetAttribute("en") ~= true then break end
			task.wait(0.05)
		until os.clock() - t1 > 2.5
		local t2 = os.clock()
		while os.clock() - t2 < sk.after do updateAim() task.wait(0.05) end
	else
		skillFail[sk.key] = os.clock()
		dbg.fails += 1

		dbg.refusedRow[sk.key] = (dbg.refusedRow[sk.key] or 0) + 1
		if dbg.refusedRow[sk.key] == 5 then
			local why = os.clock() - dbg.lastStunAt < 0.6 and "stunned" or (not done and "timed out" or "server keeps refusing")
			vlog("warn", sk.key .. " failed 5× in a row (" .. why .. ")")
		end
		releaseStuck()
	end
	casting = false
	return res == true
end

local function castNextSkill()
	local sel = Options.UseSkills.Value
	if type(sel) ~= "table" then return false end
	for _, name in ipairs(skillList) do
		if sel[name] then
			local sk = skillTimes(name)
			if skillReady(sk) then
				castSkill(sk)
				return true
			end
		end
	end
	return false
end

local punchFn = env.__AxiomPunch
task.spawn(function()
	while not punchFn and gui.Parent do
		pcall(function()
			for _, f in ipairs(getgc()) do
				if type(f) == "function" then
					local ok, n = pcall(debug.info, f, "n")
					if ok and n == "punch" then
						local src = debug.info(f, "s")
						if tostring(src):find("CU.Combat", 1, true) then
							punchFn = f
							env.__AxiomPunch = f
							break
						end
					end
				end
			end
		end)
		if not punchFn then task.wait(3) end
	end
end)

local lastEquipTry = 0
local function equipWeapon(force)
	if os.clock() - lastEquipTry < 2 then return end
	local cfg = player:FindFirstChild("Items_Config")
	local eq = cfg and cfg:FindFirstChild("Equipped")
	if not eq then return end
	if force or eq.Value ~= Options.WeaponSlot.Value then
		lastEquipTry = os.clock()
		if force and eq.Value == Options.WeaponSlot.Value then eq.Value = 0 task.wait(0.2) end
		eq.Value = Options.WeaponSlot.Value
	end
end

local nextPunch, punchMisses = 0, 0
local function doPunch()
	if not punchFn or blockWanted or os.clock() < nextPunch then return end
	equipWeapon(false)
	local wait = nil
	task.spawn(function()
		local ok, r = pcall(punchFn)
		wait = ok and r or nil
	end)
	if tonumber(wait) then
		punchMisses = 0
	else
		punchMisses += 1
		if punchMisses >= 8 then punchMisses = 0 equipWeapon(true) end
	end
	nextPunch = os.clock() + (tonumber(wait) or 0.15)
end

local moving = false
local noclipConn
local function setNoclip(on)
	if noclipConn then noclipConn:Disconnect() noclipConn = nil end
	if on then
		noclipConn = RunService.Stepped:Connect(function()
			local c = getChar()
			if not c then return end
			for _, p in ipairs(c:GetDescendants()) do
				if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
			end
		end)
	else
		local c = getChar()
		if c then
			for _, n in ipairs({"HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso", "Head"}) do
				local p = c:FindFirstChild(n)
				if p and p:IsA("BasePart") then p.CanCollide = true end
			end
		end
		local root = getRoot()
		if root then root.AssemblyLinearVelocity = Vector3.zero end
	end
end

local inputLocked = false
local function blockInput(on)
	if on and not Options.BlockInput.Value then on = false end
	if on == inputLocked then return end
	inputLocked = on
	if Controls then pcall(function() if on then Controls:Disable() else Controls:Enable() end end) end
end

local lastDash = 0
local function dashToward(dir, anyAngle)
	if not SkillCtl or os.clock() - lastDash < 1.1 then return end
	local look = workspace.CurrentCamera.CFrame.LookVector
	look = Vector3.new(look.X, 0, look.Z)
	if look.Magnitude < 0.05 then return end
	look = look.Unit
	local right = Vector3.new(-look.Z, 0, look.X)
	local bestL, bestDot = nil, -2
	for l, v in pairs({W = look, S = -look, D = right, A = -right}) do
		local d = v:Dot(dir)
		if d > bestDot then bestL, bestDot = l, d end
	end
	if not anyAngle and bestDot < 0.8 then return end
	lastDash = os.clock()
	task.spawn(function()
		local ok, r = pcall(SkillCtl.Attempt_Hold, "Dash", bestL)
		if ok and r == true then pcall(SkillCtl.StopHold, "Dash") end
	end)
end

local moveToken = 0

local function infDash(dir)
	local shc = getSHC()
	if not (SkillCtl and shc) or dir.Magnitude < 0.1 then return false end
	local cam = workspace.CurrentCamera
	local saved = cam.CFrame
	cam.CFrame = CFrame.lookAt(saved.Position, saved.Position + Vector3.new(dir.X, 0, dir.Z))
	local ok, r = pcall(SkillCtl.Attempt_Hold, "Dash", "W")
	cam.CFrame = saved
	if ok and r == true then
		task.spawn(pcall, SkillCtl.StopHold, "Dash")
		return true
	end
	return false
end

local function flyTo(target, token)
	local started = os.clock()
	local goal = target + Vector3.new(0, 1.2, 0)
	while token == moveToken and os.clock() - started < 25 do
		local root, hum = getRoot(), getHum()
		if not (root and hum) or hum.Health <= 0 then return false end
		local d = goal - root.Position
		if d.Magnitude < 1.5 then
			root.AssemblyLinearVelocity = Vector3.zero
			return true
		end
		local speed = math.min(Options.MoveSpeed.Value, math.max(d.Magnitude * 5, 8))
		root.AssemblyLinearVelocity = d.Unit * speed
		local flat = Vector3.new(d.X, 0, d.Z)
		if flat.Magnitude > 1 then
			root.CFrame = CFrame.lookAt(root.Position, root.Position + flat)
		end
		RunService.Heartbeat:Wait()
	end
	return false
end

local function goTo(target)
	moveToken += 1
	local token = moveToken
	moving = true
	blockInput(true)
	setNoclip(true)
	local started, lastPos, stuck, lastJump = os.clock(), nil, 0, 0
	local result = false
	local r0 = getRoot()
	local far = r0 ~= nil and (target - r0.Position).Magnitude > 5
	do
		if far then vlog("move", string.format("Moving %dm (%s)", math.floor((target - r0.Position).Magnitude), Options.MoveMethod.Value:match("^%S+ %S+") or "")) end
	end
	if Options.MoveMethod.Value == "Fly straight (reliable)" then
		result = flyTo(target, token)
		if far or not result then vlog(result and "move" or "warn", result and string.format("Arrived in %.1fs", os.clock() - started) or "Move interrupted / failed") end
		if token == moveToken then
			setNoclip(false)
			blockInput(false)
			moving = false
		end
		return result
	end
	local lastDashAt = 0
	while token == moveToken and os.clock() - started < 30 do
		local root, hum = getRoot(), getHum()
		if not (root and hum) or hum.Health <= 0 then break end
		local d = target - root.Position
		local flat = Vector3.new(d.X, 0, d.Z)
		if flat.Magnitude < 2.2 and math.abs(d.Y) < 4 then result = true break end
		local dir = flat.Magnitude > 0.1 and flat.Unit or Vector3.zero
		hum:Move(dir, false)
		if lastPos and (root.Position - lastPos).Magnitude < 0.15 then stuck += 0.05 else stuck = 0 end
		lastPos = root.Position

		if d.Y > 2.5 and Options.InfJump.Value and os.clock() - lastJump > 0.33 then
			lastJump = os.clock()
			if hum.FloorMaterial ~= Enum.Material.Air then
				hum.Jump = true
			elseif DoubleJump and DoubleJump.Hold then
				task.spawn(pcall, DoubleJump.Hold, player)
			end
		end

		if Options.UseDash.Value and flat.Magnitude > 7 and os.clock() - lastDashAt > Options.DashGap.Value + math.random() * 0.25 then
			if infDash(dir) then lastDashAt = os.clock() else lastDashAt = os.clock() - Options.DashGap.Value + 0.15 end
		end
		if Options.FlyAssist.Value and stuck > 1.5 and d.Y > 2.5 then
			root.AssemblyLinearVelocity = dir * 12 + Vector3.new(0, 40, 0)
		end
		if flat.Magnitude < 6 then
			local v = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(dir.X * 14, v.Y, dir.Z * 14)
		end
		task.wait(0.05)
	end
	if far or not result then vlog(result and "move" or "warn", result and string.format("Arrived in %.1fs", os.clock() - started) or "Move interrupted / failed") end
	if token == moveToken then
		local hum, root = getHum(), getRoot()
		if hum then hum:Move(Vector3.zero, false) end
		if root and result then root.AssemblyLinearVelocity = Vector3.zero end
		setNoclip(false)
		blockInput(false)
		moving = false
	end
	return result
end

local hoverConn
local function stopHover()
	if hoverConn then hoverConn:Disconnect() hoverConn = nil end
end

local function stopMoving()
	moveToken += 1
	moving = false
	stopHover()
	setNoclip(false)
	blockInput(false)
	local hum = getHum()
	if hum then hum:Move(Vector3.zero, false) end
end

local hoverTarget
local function startHover()
	if hoverConn then return end
	setNoclip(true)
	blockInput(true)
	hoverConn = RunService.Heartbeat:Connect(function(dt)
		local root = getRoot()
		local t = hoverTarget
		if not (root and t and t.root.Parent and t.hum.Health > 0) then
			if root then root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0) end
			return
		end
		local tp = t.root.Position
		local h = Options.HoverHeight.Value
		local back = t.root.CFrame.LookVector
		back = Vector3.new(back.X, 0, back.Z)
		back = back.Magnitude > 0.1 and back.Unit or Vector3.new(0, 0, 1)
		local goal = tp + Vector3.new(0, h, 0) - back * 1.5

		local cur = root.Position
		local delta = goal - cur
		local maxStep = Options.HoverSpeed.Value * dt
		local pos = delta.Magnitude > maxStep and (cur + delta.Unit * maxStep) or goal
		root.CFrame = CFrame.lookAt(pos, tp)
		root.AssemblyLinearVelocity = delta.Magnitude > maxStep and delta.Unit * Options.HoverSpeed.Value or Vector3.zero
	end)
end

local RECOMMENDED_SPOTS = {
	["Rock Dungeon"] = {1674.9, 181.1, -167.7},
	["Lava Dungeon"] = {-887.1, 421, -1315.1},
	["Ice Dungeon"] = {-618.5, 158.4, -1550.3},
	["Desert Dungeon"] = {-657.8, 155.2, -276.9},
}
local function spotFor(map)
	if not map then return nil end
	local s = Options.Spots.Value[map]
	if not (type(s) == "table" and #s == 3) and Options.UseRecommended.Value then s = RECOMMENDED_SPOTS[map] end
	if type(s) == "table" and #s == 3 then return Vector3.new(s[1], s[2], s[3]) end
	return nil
end

local DEFAULT_ORDER = {
	"LoadedDice", "JackpotFloor", "SkipFloor", "SecondChance", "Revive", "ExtraLife", "Vampiric", "Momentum",
	"Frenzy", "Berserk", "HeavyHitter", "FocusedMind", "LuckyDraw", "Stat", "Streak", "Ascension", "Marathon",
	"Reincarnation", "ThickBlood", "EnduranceTraining", "LoneWolf", "Wildfire", "DeepFreeze", "VenomFang",
	"PlagueBearer", "Rally", "CommunalHeal", "Medic", "Warcry", "Adrenaline", "Bulwark", "SecondSkin", "Mulligan",
	"Lifeline", "TicketPack", "DoubleDown", "Fortune", "Potion", "Reroll", "Heal", "Points", "Bounty", "RushHour",
	"LastRites", "ClanHeir", "PartingGift", "Cartographer", "SplitTheTake", "Ignition", "Chill", "TaintedEdge",
	"Envenomed", "Event", "Skip", "FairFight", "EliteGuard", "Berserkers", "ThickSkin", "NoGuard", "Headhunter", "Wager",
	"CheapSeats", "Handoff", "LongNight", "SwapMap", "TimeAttack", "FogOfWar", "DoubleTime", "LightsOut",
	"Tribute", "ThinAir", "HeavyAir", "CursedCoin", "BossHunt", "Featherweight", "TheHorde", "GoldRush", "Champion",
	"BloodMoon", "BleedingFloor", "BloodPact", "TwinBosses", "GlassCannon", "TollGate", "Sacrifice", "GlassFloor",
	"LastStand", "IronTower", "BossRush", "BareHands", "Reincarnated", "Pacifist", "IronDiscipline", "Grounded",
}
local TYPE_NAMES = {
	Stat = "Stat card", Revive = "Revive", ExtraLife = "Extra Life", Potion = "Potion", Heal = "Heal",
	Points = "Points", Fortune = "Fortune", Reroll = "Reroll ticket", SwapMap = "Tectonic Shift (swap map)",
	Skip = "Skip", SkipFloor = "Skip Floor", Event = "Other event",
}
local TITLE_TO_KEY, DISPLAY = {}, {}
for k, v in pairs(TYPE_NAMES) do DISPLAY[k] = v end
if OUW and OUW:FindFirstChild("Events") then
	for _, m in ipairs(OUW.Events:GetDescendants()) do
		if m:IsA("ModuleScript") then
			local ok, t = pcall(require, m)
			if ok and type(t) == "table" and type(t.Title) == "string" then
				TITLE_TO_KEY[t.Title] = m.Name
				DISPLAY[m.Name] = t.Title
			end
		end
	end
end
local function displayName(key) return DISPLAY[key] or key end

local seenUnknown = {}
local function cardKey(card)
	local order = Options.CardOrder.Value
	local function known(k) return type(k) == "string" and table.find(order, k) ~= nil end
	for _, attr in ipairs({"Event", "EventName", "Key", "Id"}) do
		local v = card:GetAttribute(attr)
		if known(v) then return v end
	end
	local title = card:GetAttribute("Title")
	if type(title) == "string" and TITLE_TO_KEY[title] then return TITLE_TO_KEY[title] end
	for _, attr in ipairs({"Type", "Kind", "Reward", "Category"}) do
		local v = card:GetAttribute(attr)
		if known(v) then return v end
	end
	if type(title) == "string" then
		local low = title:lower()
		for _, g in ipairs({
			{"tectonic", "SwapMap"}, {"revive", "Revive"}, {"extra life", "ExtraLife"}, {"potion", "Potion"},
			{"heal", "Heal"}, {"reroll", "Reroll"}, {"fortune", "Fortune"}, {"skip floor", "SkipFloor"}, {"points", "Points"},
		}) do
			if low:find(g[1], 1, true) then return g[2] end
		end
		return title
	end
	return card.Name
end

local function rankOf(key)
	return table.find(Options.CardOrder.Value, key) or 50
end

local function mapIsGood(map)
	local good = Options.GoodMaps.Value
	if type(good) ~= "table" or next(good) == nil then return true end
	return map ~= nil and good[map] == true
end

local function effectiveRank(key)
	if key == "SwapMap" and Options.SwapBadMaps.Value then
		return mapIsGood(currentMap()) and 999 or 0
	end
	return rankOf(key)
end

local healing = false
task.spawn(function()
	while gui.Parent do
		task.wait(2)
		if Options.Farm.Value and inRun() and not healing then pcall(equipWeapon, false) end
	end
end)
local LOCOMOTION = {walkanim = true, run = true, jump = true, fall = true, idle = true, climb = true, swim = true, sit = true, landed = true, toolnone = true, walk = true}
local learnedIgnore = {}
local lastDefend = 0
local defenseCount = 0

local function jumpAway()
	local hum = getHum()
	if not hum then return end
	if hum.FloorMaterial ~= Enum.Material.Air then
		hum.Jump = true
		task.wait(0.18)
	end
	if DoubleJump and DoubleJump.Hold then pcall(DoubleJump.Hold, player) end
end

local combo
local blocking, blockUntil, lastBlockTry = false, 0, 0
local function blockActive()
	local v = RS:FindFirstChild("Player_Service") and RS.Player_Service.Values:FindFirstChild(player.Name)
	if v ~= nil and v:FindFirstChild("Blocking") ~= nil then return true end

	local shc = getSHC()
	return shc ~= nil and shc.Value == "Blocking" and os.clock() - lastBlockTry < 0.4
end
local function startBlock(duration)
	blockUntil = math.max(blockUntil, os.clock() + duration)
	if not SkillCtl then return end
	blocking, blockWanted = true, true
	if not blockActive() and os.clock() - lastBlockTry > 0.2 then
		lastBlockTry = os.clock()
		task.spawn(pcall, SkillCtl.Attempt_Hold, "Blocking", "F")
	end
end
local function stopBlock()
	if not blocking then return end
	blocking, blockWanted = false, false
	blockUntil = 0
	task.spawn(pcall, SkillCtl.StopHold, "Blocking")
end

combo = {lastHitAt = 0, hitGap = 0.35, lastAnim = nil, hitDelay = {}, lastPressAt = 0, aggro = setmetatable({}, {__mode = "k"}), counterUntil = 0}
local function defenseOn()
	return Options.Farm.Value or Options.DefenseAlways.Value
end
local function pressBlockFresh(duration)
	if os.clock() - combo.lastPressAt < 0.2 then
		blockUntil = math.max(blockUntil, os.clock() + duration)
		return
	end
	combo.lastPressAt = os.clock()
	if blocking then stopBlock() task.wait(0.04) end
	lastBlockTry = 0
	startBlock(duration)
end

local function defend(attackerRoot, why, animId)
	local mode = Options.DefenseMode.Value
	if mode == "Do nothing" or moving or healing or hoverConn then return end
	local who = tostring(attackerRoot and attackerRoot.Parent and attackerRoot.Parent.Name or "mob")
	local fresh = os.clock() - lastDefend > 1.2
	if mode == "Jump away (double jump)" then
		if not fresh then return end
		lastDefend = os.clock()
		defenseCount += 1
		dlog("defend", "Jumped away from " .. who)
		task.spawn(jumpAway)
		return
	end
	if fresh then defenseCount += 1 end
	lastDefend = os.clock()
	if mode == "Perfect block (timed)" and animId then
		if fresh then dlog("defend", "Perfect-blocking " .. who) end
		local delay = combo.hitDelay[animId] or 0.27
		task.delay(math.max(0, delay - Options.PerfectLead.Value), function()
			pressBlockFresh(Options.PerfectLead.Value + 0.25)
		end)
	else
		if fresh then dbg.blocks += 1 dlog("defend", "Blocking " .. who .. "'s combo") end
		startBlock(Options.BlockHold.Value)
	end
end

local watchedAnimators = setmetatable({}, {__mode = "k"})
local function watchEnemy(e)
	local animator = e.hum:FindFirstChildOfClass("Animator")
	if not animator or watchedAnimators[animator] then return end
	watchedAnimators[animator] = true
	connect(animator.AnimationPlayed, function(track)
		if not defenseOn() then return end
		local anim = track.Animation
		if not anim then return end
		local root = getRoot()
		if not root or not e.root.Parent then return end
		local id = anim.AnimationId
		local dist = (e.root.Position - root.Position).Magnitude

		if dist > 35 then learnedIgnore[id] = true return end
		local name = anim.Name:lower()
		if learnedIgnore[id] or LOCOMOTION[name] or name:find("walk") or name:find("idle") or name:find("run") then return end
		if track.Looped and track.Priority ~= Enum.AnimationPriority.Action and track.Priority ~= Enum.AnimationPriority.Action2
			and track.Priority ~= Enum.AnimationPriority.Action3 and track.Priority ~= Enum.AnimationPriority.Action4 then return end
		if dist <= Options.ParryRange.Value then
			combo.lastAnim = {t = os.clock(), id = id}
			combo.aggro[e.model] = os.clock()
			defend(e.root, "anim", id)
		end
	end)
end

local session = {started = os.time(), picks = 0, deaths = 0}
local function httpRequest(opts)
	local req = (env.syn and env.syn.request) or (env.http and env.http.request) or env.http_request or env.request
	if not req then return nil end
	return req(opts)
end
local function sessionTime()
	local s = os.time() - session.started
	if s >= 3600 then return string.format("%dh %02dm", s // 3600, (s % 3600) // 60) end
	return string.format("%dm %02ds", s // 60, s % 60)
end
local HOOK_TITLES = {
	test = "🧪  Webhook connected", floor = "🏯  Floor cleared", map = "🗺️  New map", target = "🎯  Target floor reached!",
	death = "💀  You died", card = "🃏  Card picked", start = "▶️  Farm started",
}
local HOOK_COLORS = {test = 0x8E9A4E, floor = 0x8E9A4E, map = 0x4F8FD6, target = 0xE6C25A, death = 0xD65252, card = 0x9071D9, start = 0x6EC878}
local function sendWebhook(event, text)
	local url = trim(Options.WebhookURL.Value)
	if url == "" then return false end
	local embed = {
		author = {name = APP_NAME .. " · Ouwigahara"},
		title = HOOK_TITLES[event] or event,
		description = text and ("> " .. text) or nil,
		color = HOOK_COLORS[event] or 0x8E9A4E,
		fields = {
			{name = "🏯 Floor", value = "`" .. floorNum() .. "`", inline = true},
			{name = "🗺️ Map", value = "`" .. tostring(currentMap() or "?") .. "`", inline = true},
			{name = "🎯 Target", value = "`" .. tostring(Options.TargetFloor.Value) .. "`", inline = true},
			{name = "🃏 Cards picked", value = "`" .. session.picks .. "`", inline = true},
			{name = "💀 Deaths", value = "`" .. session.deaths .. "`", inline = true},
			{name = "⏱️ Session", value = "`" .. sessionTime() .. "`", inline = true},
		},
		footer = {text = player.Name .. "  •  " .. APP_NAME .. " by " .. AUTHOR},
		timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
	}
	local payload = {username = APP_NAME, embeds = {embed}}
	if event == "target" and Options.PingTarget.Value then payload.content = "@everyone" end
	local ok, res = isolated(httpRequest, {
		Url = url, Method = "POST",
		Headers = {["Content-Type"] = "application/json"},
		Body = HttpService:JSONEncode(payload),
	})
	return ok and res ~= nil and (res.StatusCode == nil or (res.StatusCode >= 200 and res.StatusCode < 300))
end
local function hook(event, text)
	if not Options.WebhookEnabled.Value then return end
	local need = {map = "HookMaps", death = "HookDeaths", card = "HookCards"}
	if need[event] and not Options[need[event]].Value then return end
	task.spawn(sendWebhook, event, text)
end

local function toggleD(tab, flag, title, desc, default, callback)
	local f, hit = baseElement(tab, 54)
	label({Parent = f, Position = UDim2.fromOffset(12, 7), Size = UDim2.new(1, -70, 0, 18), Text = title})
	label({Parent = f, Position = UDim2.fromOffset(12, 25), Size = UDim2.new(1, -70, 0, 24), Text = desc, Font = FONT, TextSize = 11, TextColor3 = T.SubText, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top})
	local sw = make("Frame", {Parent = f, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(38, 20), BackgroundColor3 = T.Off}, {corner(10)})
	local knob = make("Frame", {Parent = sw, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = T.Text}, {corner(7)})
	local o = register(flag, default, function(v)
		tween(sw, {BackgroundColor3 = v and T.Accent or T.Off}, 0.2)
		tween(knob, {Position = v and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)}, 0.3, Enum.EasingStyle.Back)
	end)
	o.Callback = callback
	o:SetValue(default, true)
	connect(hit.MouseButton1Click, function() o:SetValue(not o.Value) end)
	return o
end

local HomeTab = newTab("Home", "home")
local FarmTab = newTab("Farm", "swords")
local CombatTab = newTab("Combat", "target")
local MoveTab = newTab("Movement", "compass")
local HealTab = newTab("Healing", "heal")
local SpotTab = newTab("Spots & Maps", "map")
local CardTab = newTab("Cards", "cards")
dbg.shopTab = newTab("Dungeon Shop", "shop")
local HookTab = newTab("Webhook", "link")
local SettingsTab = newTab("Settings", "gear")
local floatButton

local homeCard = make("Frame", {Parent = HomeTab.container, LayoutOrder = nextOrder(HomeTab), Size = UDim2.new(1, 0, 0, 226), BackgroundColor3 = T.Element, BackgroundTransparency = 0.15, ClipsDescendants = true}, {corner(12)})
do
	local homeStroke = stroke(T.Accent, 0.6); homeStroke.Parent = homeCard
	accent(homeStroke, "Color")
	local glow = make("Frame", {Parent = homeCard, Size = UDim2.new(0.6, 0, 1, 0), BackgroundColor3 = T.Accent, BackgroundTransparency = 0.82, BorderSizePixel = 0}, {
		make("UIGradient", {Transparency = NumberSequence.new(0, 1)}),
	})
	accent(glow, "BackgroundColor3")

	local shine = make("UIGradient", {Parent = homeStroke, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(0.18, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 150, 150)), ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))})})
	homeStroke.Transparency = 0.35
	connect(RunService.Heartbeat, function(dt) shine.Rotation = (shine.Rotation + dt * 40) % 360 end)

	local lattice = make("Frame", {Parent = homeCard, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0.55, 0, 1, 0), BackgroundTransparency = 1, ClipsDescendants = true}, {
		make("UIGradient", {Transparency = NumberSequence.new(1, 0)}),
	})
	for i = -4, 14 do
		for _, rot in ipairs({35, -35}) do
			accent(make("Frame", {Parent = lattice, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, i * 34, 0.5, 0), Size = UDim2.fromOffset(1, 420),
				Rotation = rot, BackgroundColor3 = T.Accent, BackgroundTransparency = 0.93, BorderSizePixel = 0}), "BackgroundColor3")
		end
	end

	local function bracket(ax, ay)
		local sx, sy = ax == 0 and 1 or -1, ay == 0 and 1 or -1
		local function bar(w, h, ox, oy, tr)
			accent(make("Frame", {Parent = homeCard, AnchorPoint = Vector2.new(ax, ay), Position = UDim2.new(ax, sx * ox, ay, sy * oy),
				Size = UDim2.fromOffset(w, h), BackgroundColor3 = T.Accent, BackgroundTransparency = tr, BorderSizePixel = 0, ZIndex = 3}), "BackgroundColor3")
		end
		bar(22, 2, 5, 5, 0.1) bar(2, 22, 5, 5, 0.1)
		bar(12, 1, 10, 10, 0.45) bar(1, 12, 10, 10, 0.45)
		accent(make("Frame", {Parent = homeCard, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(ax, sx * 30, ay, sy * 6),
			Size = UDim2.fromOffset(5, 5), Rotation = 45, BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 3}), "BackgroundColor3")
		accent(make("Frame", {Parent = homeCard, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(ax, sx * 6, ay, sy * 30),
			Size = UDim2.fromOffset(5, 5), Rotation = 45, BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 3}), "BackgroundColor3")
	end
	bracket(0, 0) bracket(1, 0) bracket(0, 1) bracket(1, 1)

	local function divider(ay)
		local holder = make("Frame", {Parent = homeCard, AnchorPoint = Vector2.new(0.5, ay), Position = UDim2.new(0.62, 0, ay, ay == 0 and 3 or -3), Size = UDim2.fromOffset(150, 9), BackgroundTransparency = 1, ZIndex = 3})
		for side = -1, 1, 2 do
			accent(make("Frame", {Parent = holder, AnchorPoint = Vector2.new(side < 0 and 1 or 0, 0.5), Position = UDim2.new(0.5, side * 15, 0.5, 0), Size = UDim2.new(0.5, -15, 0, 1),
				BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 3}, {
				make("UIGradient", {Transparency = side < 0 and NumberSequence.new(1, 0.2) or NumberSequence.new(0.2, 1)}),
			}), "BackgroundColor3")
			local d = make("Frame", {Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, side * 10, 0.5, 0), Size = UDim2.fromOffset(4, 4), Rotation = 45,
				BackgroundTransparency = 1, ZIndex = 3})
			local ds = stroke(T.Accent, 0.2); ds.Parent = d accent(ds, "Color")
		end
		accent(make("Frame", {Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(7, 7), Rotation = 45,
			BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 3}), "BackgroundColor3")
	end
	divider(0) divider(1)
end

local avatarHolder = make("Frame", {Parent = homeCard, Position = UDim2.fromOffset(14, 14), Size = UDim2.fromOffset(150, 192), BackgroundColor3 = T.Bg, BackgroundTransparency = 0.3}, {corner(10)})
do
	local avStroke = stroke(T.Accent, 0.5); avStroke.Parent = avatarHolder
	accent(avStroke, "Color")
end
local viewport = make("ViewportFrame", {Parent = avatarHolder, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ImageTransparency = 1, Ambient = Color3.fromRGB(170, 170, 170), LightColor = Color3.fromRGB(255, 255, 255), LightDirection = Vector3.new(-0.5, -1, -0.8)}, {corner(10)})
local avatarLoading = label({Parent = avatarHolder, Size = UDim2.fromScale(1, 1), Text = "Loading…", Font = FONT, TextSize = 12, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Center})

local info = make("Frame", {Parent = homeCard, Position = UDim2.fromOffset(180, 16), Size = UDim2.new(1, -194, 1, -32), BackgroundTransparency = 1})
local hello = label({Parent = info, Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 0, 16), Text = "WELCOME BACK", Font = FONT_B, TextSize = 11, TextTransparency = 1})
accent(hello, "TextColor3")
local nameLabel = label({Parent = info, Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 28), Text = player.DisplayName, Font = FONT_B, TextSize = 24, TextTransparency = 1, TextTruncate = Enum.TextTruncate.AtEnd})
local userLabel = label({Parent = info, Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 16), Text = "@" .. player.Name, Font = FONT, TextSize = 13, TextColor3 = T.SubText, TextTransparency = 1})

local pills = make("Frame", {Parent = info, Position = UDim2.fromOffset(0, 74), Size = UDim2.new(1, 0, 0, 118), BackgroundTransparency = 1}, {
	make("UIPadding", {PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2)}),
	make("UIGridLayout", {CellSize = UDim2.new(0.5, -5, 0, 50), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder}),
})
local pillRefs = {}
local function pill(order, title)
	local f = make("Frame", {Parent = pills, LayoutOrder = order, BackgroundColor3 = T.Bg, BackgroundTransparency = 1}, {corner(8)})
	local s = stroke(T.Stroke, 1); s.Parent = f
	local t = label({Parent = f, Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -16, 0, 14), Text = title, Font = FONT, TextSize = 11, TextColor3 = T.SubText, TextTransparency = 1})
	local v = label({Parent = f, Position = UDim2.fromOffset(10, 22), Size = UDim2.new(1, -16, 0, 20), Text = "…", Font = FONT_B, TextSize = 15, TextTransparency = 1, TextTruncate = Enum.TextTruncate.AtEnd})
	pillRefs[order] = {f = f, s = s, t = t, v = v}
	return v
end
local levelValue = pill(1, "Level")
local artTitle
local artValue = pill(2, "Demon Art")
local clanValue = pill(3, "Clan")
local wenValue = pill(4, "Wen")

local dbgUI = {btns = {}, v = {}, order = {}, skillChips = {}, skillKey = ""}
local logDot, logScroll
do
	local function card(title, height)
		local c = make("Frame", {Parent = HomeTab.container, LayoutOrder = nextOrder(HomeTab), Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = T.Element, BackgroundTransparency = 0.15}, {corner(10)})
		stroke(T.Stroke, 0.7).Parent = c
		local dot = make("Frame", {Parent = c, Position = UDim2.fromOffset(14, 15), Size = UDim2.fromOffset(7, 7), Rotation = 45, BackgroundColor3 = T.Accent, BorderSizePixel = 0})
		accent(dot, "BackgroundColor3")
		accent(label({Parent = c, Position = UDim2.fromOffset(30, 8), Size = UDim2.fromOffset(200, 22), Text = title, Font = FONT_B, TextSize = 11}), "TextColor3")
		return c, dot
	end
	local function grid(parent, y, cols, cellH)
		return make("Frame", {Parent = parent, Position = UDim2.fromOffset(12, y), Size = UDim2.new(1, -24, 1, -(y + 12)), BackgroundTransparency = 1}, {
			make("UIGridLayout", {CellSize = UDim2.new(1 / cols, -6, 0, cellH), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder}),
		})
	end
	local function tile(parent, key, caption, small)
		local f = make("Frame", {Parent = parent, LayoutOrder = #dbgUI.order + 1, BackgroundColor3 = T.Bg, BackgroundTransparency = 0.35}, {corner(7)})
		stroke(T.Stroke, 0.75).Parent = f
		label({Parent = f, Position = UDim2.fromOffset(9, small and 4 or 6), Size = UDim2.new(1, -14, 0, 12), Text = caption, Font = FONT_M, TextSize = 10, TextColor3 = T.SubText})
		dbgUI.v[key] = label({Parent = f, Position = UDim2.fromOffset(9, small and 17 or 20), Size = UDim2.new(1, -14, 0, small and 16 or 18), Text = "-", RichText = true,
			Font = FONT_B, TextSize = small and 13 or 14, TextTruncate = Enum.TextTruncate.AtEnd})
		table.insert(dbgUI.order, {key, caption})
	end

	local live
	live, logDot = card("ACTIVITY", 222)
	dbgUI.badge = make("TextLabel", {Parent = live, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 8), Size = UDim2.fromOffset(150, 22), BackgroundColor3 = T.Bg,
		BackgroundTransparency = 0.2, Text = "Idle", RichText = true, Font = FONT_B, TextSize = 12, TextColor3 = T.Text}, {corner(11)})
	stroke(T.Stroke, 0.5).Parent = dbgUI.badge
	dbgUI.note = label({Parent = live, Position = UDim2.fromOffset(14, 34), Size = UDim2.new(1, -28, 0, 16), Text = "", Font = FONT, TextSize = 12, TextColor3 = T.SubText, TextTruncate = Enum.TextTruncate.AtEnd})
	local g = grid(live, 58, 4, 46)
	tile(g, "floor", "FLOOR") tile(g, "map", "MAP") tile(g, "ftime", "FLOOR TIME") tile(g, "mode", "MODE")
	tile(g, "target", "TARGET") tile(g, "mobs", "MOBS LEFT") tile(g, "shot", "LAST SHOT") tile(g, "hp", "YOUR HP")
	tile(g, "pots", "POTIONS") tile(g, "block", "BLOCK") tile(g, "ping", "PING") tile(g, "fps", "FPS")

	local sk = card("SKILLS", 118)
	dbgUI.skillCard = sk
	dbgUI.skillLast = label({Parent = sk, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 8), Size = UDim2.fromOffset(260, 22), Text = "", RichText = true,
		Font = FONT, TextSize = 11, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Right})
	dbgUI.skillGrid = grid(sk, 38, 2, 58)

	local ses = card("THIS SESSION", 200)
	local g2 = grid(ses, 38, 4, 46)
	tile(g2, "time", "TIME", true) tile(g2, "kills", "KILLS", true) tile(g2, "floors", "FLOORS", true) tile(g2, "casts", "CASTS", true)
	tile(g2, "refused", "REFUSED", true) tile(g2, "cards", "CARDS", true)
	tile(g2, "hits", "HITS TAKEN", true) tile(g2, "blocked", "IN BLOCK", true) tile(g2, "stuns", "STUNS", true) tile(g2, "heals", "POTIONS USED", true)
	tile(g2, "deaths", "DEATHS", true) tile(g2, "blocks", "BLOCKS", true)

	local lg = card("LOG", 262)
	for i, name in ipairs({"Clear", "Copy"}) do
		local b = make("TextButton", {Parent = lg, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12 - (i - 1) * 64, 0, 8), Size = UDim2.fromOffset(58, 22),
			BackgroundColor3 = T.Bg, BackgroundTransparency = 0.3, Text = name, Font = FONT_M, TextSize = 11, TextColor3 = T.SubText, AutoButtonColor = false}, {corner(6)})
		stroke(T.Stroke, 0.6).Parent = b
		connect(b.MouseEnter, function() tween(b, {TextColor3 = T.Accent}) end)
		connect(b.MouseLeave, function() tween(b, {TextColor3 = T.SubText}) end)
		dbgUI.btns[name] = b
	end
	label({Parent = lg, Position = UDim2.fromOffset(14, 236), Size = UDim2.new(1, -28, 0, 16), Text = "Saved to AxiomHUB/log.txt  ·  previous run in log_prev.txt", Font = FONT, TextSize = 10, TextColor3 = T.SubText})
	logScroll = make("ScrollingFrame", {Parent = lg, Position = UDim2.fromOffset(10, 38), Size = UDim2.new(1, -20, 0, 194), BackgroundColor3 = T.Bg, BackgroundTransparency = 0.4, BorderSizePixel = 0,
		ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y}, {
		corner(8),
		make("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}),
		make("UIPadding", {PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 6)}),
	})
	accent(logScroll, "ScrollBarImageColor3")
end
local LOG_COLORS = {info = "#c8ccbc", move = "#6fb7ff", skill = "#ffb35c", card = "#c39bff", heal = "#6ee39a", defend = "#ffd75c", warn = "#ff7a6e",
	dbg = "#8a8f7c", kill = "#e8e8e8", hit = "#ff9d8a", target = "#9fd8ff"}
local logCount = 0
local function drawLog(entry)
	logCount += 1
	local line = label({Parent = logScroll, LayoutOrder = logCount, Size = UDim2.new(1, 0, 0, 17), RichText = true, Font = FONT, TextSize = 12, TextTransparency = 1, TextTruncate = Enum.TextTruncate.AtEnd,
		Text = string.format('<font color="#7c8070">%s</font>  <font color="%s">%s</font>', entry.t, LOG_COLORS[entry.kind] or LOG_COLORS.info, entry.text)})
	tween(line, {TextTransparency = 0}, 0.3)
	local kids = {}
	for _, c in ipairs(logScroll:GetChildren()) do if c:IsA("TextLabel") then table.insert(kids, c) end end
	if #kids > 40 then
		table.sort(kids, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
		kids[1]:Destroy()
	end
	task.defer(function() logScroll.CanvasPosition = Vector2.new(0, math.huge) end)
end

do

local credit = make("Frame", {Parent = HomeTab.container, LayoutOrder = nextOrder(HomeTab), Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = T.Element, BackgroundTransparency = 0.15}, {corner(10)})
local creditStroke = stroke(T.Stroke, 0.7); creditStroke.Parent = credit
app.drawMark(make("Frame", {Parent = credit, Position = UDim2.fromOffset(8, 11), Size = UDim2.fromOffset(36, 36), BackgroundTransparency = 1}), 34, 2)
label({Parent = credit, Position = UDim2.fromOffset(46, 10), Size = UDim2.new(1, -60, 0, 18), Text = APP_NAME .. " · Ouwigahara Normal", Font = FONT_B, TextSize = 14})
local creditBy = label({Parent = credit, Position = UDim2.fromOffset(46, 30), Size = UDim2.new(1, -60, 0, 16), Text = "made by <b>" .. AUTHOR .. "</b>", RichText = true, Font = FONT, TextSize = 12, TextColor3 = T.SubText})
end

local function fmtNum(n)
	local s = tostring(math.floor(tonumber(n) or 0))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

local ART_COLORS = {
	Shockwave = "#3FA9FF", Tamari = "#FF8C1A", ["Blood Manipulation"] = "#FF2E3B", Pyrokenesis = "#FF6EC7",
	Arrow = "#3EDB5A", Cryokinesis = "#8FEAFF", Dream = "#B38CFF", ["Obi Manipulation"] = "#FFD23F",
	Reaper = "#8E5CFF", Thread = "#F2F2F2",
}
local BREATH_COLORS = {
	Water = "#3FA9FF", Flame = "#FF7A1A", Thunder = "#FFE14A", Wind = "#6FE39A", Stone = "#B4B4B4",
	Flower = "#FF8FC8", Insect = "#B98CFF", Serpent = "#E05CC4", Sound = "#FFB347", Beast = "#C08A5A",
}
local function colorFor(name, map)
	local hex = map[name]
	if not hex then
		for k, v in pairs(map) do
			if name:lower():find(k:lower(), 1, true) then hex = v break end
		end
	end
	return hex and fromHex(hex) or T.Text
end

local function refreshProfile()
	local data = Utility and select(2, isolated(Utility.GetData, player, true))
	if typeof(data) ~= "Instance" then return end
	pcall(function()
		local per = (GameSettings and GameSettings.expPerLevel) or 60
		levelValue.Text = tostring(math.floor(data.Exp.Goal.Value / per))
		local race = data.Race.Value
		local demonArt, breathing = data.Powers.DemonArt.Value, data.Powers.Breathing.Value
		if race == "Human" or (demonArt == "" and breathing ~= "") then
			pillRefs[2].t.Text = "Breathing"
			artValue.Text = breathing ~= "" and breathing or "None"
			artValue.TextColor3 = colorFor(breathing, BREATH_COLORS)
		else
			pillRefs[2].t.Text = race == "Hybrid" and "Demon Art · Hybrid" or "Demon Art"
			artValue.Text = demonArt ~= "" and demonArt or "None"
			artValue.TextColor3 = colorFor(demonArt, ART_COLORS)
		end
		local clan = data.Clan.Value
		clanValue.Text = (clan ~= "" and clan) or "None"
		local tier = Clans and Clans.TierOf and select(2, pcall(Clans.TierOf, clan))
		clanValue.TextColor3 = (type(tier) == "table" and typeof(tier.color) == "Color3") and tier.color or T.Text
		wenValue.Text = fmtNum(data.Wen.Value)
		wenValue.TextColor3 = Color3.fromRGB(245, 196, 81)
	end)
end

local avatarModel, avatarBase

local function cloneCharacter()
	local char = getChar()
	if not char then return nil end
	local was = char.Archivable
	char.Archivable = true
	local ok, clone = pcall(function() return char:Clone() end)
	char.Archivable = was
	if not ok or not clone then return nil end
	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("LuaSourceContainer") or d:IsA("BillboardGui") or d:IsA("Highlight") or d:IsA("Tool")
			or d:IsA("Sound") or d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail")
			or d:IsA("BodyMover") or d:IsA("Constraint") and not d:IsA("Motor6D") and d.Name ~= "AccessoryWeld" then
			pcall(function() d:Destroy() end)
		end
	end
	for _, n in ipairs({"RagdollConstraints", "NpcsFollowing", "Character Scripts"}) do
		local f = clone:FindFirstChild(n)
		if f then f:Destroy() end
	end
	return clone
end

local function buildAvatar()
	for _, c in ipairs(viewport:GetChildren()) do
		if c:IsA("WorldModel") or c:IsA("Camera") then c:Destroy() end
	end
	local model = cloneCharacter()
	if not model or not model:FindFirstChild("HumanoidRootPart") then
		avatarLoading.Text = "Avatar unavailable"
		return
	end
	local world = Instance.new("WorldModel")
	world.Parent = viewport
	model.Parent = world
	local root = model.HumanoidRootPart
	root.Anchored = true
	model:PivotTo(CFrame.new(0, 0, 0))
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then p.CanCollide = false end
	end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		pcall(function()
			local data = Utility and select(2, isolated(Utility.GetData, player, true))
			local anims = RS.Assets.Animations.mainPlace
			local idle = (typeof(data) == "Instance" and data.Race.Value == "Demon") and anims.demonIdle or anims.humanIdle
			local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
			animator:LoadAnimation(idle):Play(0)
		end)
	end
	local cam = Instance.new("Camera")
	cam.Parent = viewport
	viewport.CurrentCamera = cam
	cam.FieldOfView = 30

	local focus = root.Position + Vector3.new(0, 1.1, 0)
	cam.CFrame = CFrame.lookAt(focus + Vector3.new(-2.2, 0.6, -7.5), focus)
	avatarModel, avatarBase = model, model:GetPivot()
	avatarLoading.Text = ""
	tween(viewport, {ImageTransparency = 0}, 0.6)
end

local function playIntro()
	homeCard.Position = UDim2.fromOffset(0, 14)
	tween(homeCard, {Position = UDim2.fromOffset(0, 0)}, 0.5, Enum.EasingStyle.Back)
	for i, lbl in ipairs({hello, nameLabel, userLabel}) do
		lbl.TextTransparency = 1
		local p = lbl.Position
		lbl.Position = p + UDim2.fromOffset(16, 0)
		task.delay(0.08 * i, function()
			tween(lbl, {TextTransparency = 0, Position = p}, 0.45)
		end)
	end
	for i = 1, 4 do
		local r = pillRefs[i]
		r.f.BackgroundTransparency, r.s.Transparency, r.t.TextTransparency, r.v.TextTransparency = 1, 1, 1, 1
		task.delay(0.25 + 0.07 * i, function()
			tween(r.f, {BackgroundTransparency = 0.35}, 0.4)
			tween(r.s, {Transparency = 0.6}, 0.4)
			tween(r.t, {TextTransparency = 0}, 0.4)
			tween(r.v, {TextTransparency = 0}, 0.4)
		end)
	end
end
connect(HomeTab.button.MouseButton1Click, playIntro)

connect(RunService.RenderStepped, function()
	if avatarModel and avatarModel.Parent and main.Visible and HomeTab.page.Visible then
		avatarModel:PivotTo(avatarBase * CFrame.Angles(0, math.sin(os.clock() * 0.8) * 0.45, 0))
	end
end)

section(FarmTab, "Farm")
local farmToggle = toggleD(FarmTab, "Farm", "Start farming", "Fights on its own until the target floor", false)
dropdown(FarmTab, "FarmMode", "How to fight", {"Skills from a high spot", "Hover above mobs + M1"}, false, "Skills from a high spot")
note(FarmTab, "<b>High spot</b> — skills from safety.  <b>Hover</b> — M1 from above the mob.")
section(FarmTab, "Run")
slider(FarmTab, "TargetFloor", "Stop at floor", 5, 200, 1, 50)
dropdown(FarmTab, "AtTarget", "When that floor is reached", {"Just stop farming", "Leave the run (Multi-Player)"}, false, "Just stop farming")
note(FarmTab, "<b>Stop</b> — stays in the run, farm off.  <b>Give Up</b> — ends the run, spends the points in town (Dungeon Shop list), then starts a new run.")
toggle(FarmTab, "AutoStart", "Auto start the run (T prompt)", true)
toggle(FarmTab, "AutoSkipBreak", "Skip the break between waves", true)

section(CombatTab, "Skills · silent aim")
local skillNote = note(CombatTab, "")
local startSkills = select(2, isolated(availableSkills)) or {}
local defaultSel = {}
for _, n in ipairs({"Spiraling Shot", "Meteor", "Spinning Throw", "Dunk"}) do
	if table.find(startSkills, n) then defaultSel[n] = true end
end
if next(defaultSel) == nil then
	for _, n in ipairs(startSkills) do
		if skillCategory(n) == "Evil Art" then defaultSel[n] = true end
	end
end
local skillDrop = dropdown(CombatTab, "UseSkills", "Skills to use", startSkills, true, defaultSel)
slider(CombatTab, "DefaultHold", "Skill hold time (non-Tamari)", 0, 3, 0.05, 0.3, "s")
toggleD(CombatTab, "NeedLOS", "Don't shoot through walls", "Skips mobs behind barriers", true)
dropdown(CombatTab, "TargetMode", "Who to attack first", {"Closest mob", "Weakest mob (lowest HP)"}, false, "Closest mob")
slider(CombatTab, "AttackRange", "Max attack distance", 30, 200, 5, 95, " studs")
slider(CombatTab, "AimLead", "Aim ahead of running mobs", 0, 40, 1, 12, "%")
local function refreshSkillNote(list)
	local hasTamari = false
	for _, n in ipairs(list) do if table.find(TAMARI, n) then hasTamari = true break end end
	skillNote.Text = hasTamari and "Tamari: keep <b>Piercing Kick</b> off — it dashes you off the spot."
		or "Your current kit's skills:"
end
refreshSkillNote(startSkills)

section(CombatTab, "Hover + M1 mode")
slider(CombatTab, "HoverHeight", "Height above the mob", 2, 12, 0.5, 4.5, " studs")
slider(CombatTab, "HoverSpeed", "Flying speed (lower = safer)", 16, 80, 2, 36, " studs/s")
toggleD(CombatTab, "HoverBreaks", "Land 2–3 s after each kill", "Looks more natural; also after a hard hit", true)
toggle(CombatTab, "HoverSkills", "Use skills while hovering too", true)
slider(CombatTab, "WeaponSlot", "Weapon toolbar slot", 1, 5, 1, 2)

section(CombatTab, "Defense")
dropdown(CombatTab, "DefenseMode", "When a mob attacks you", {"Do nothing", "Block (hold through combo)", "Perfect block (timed)", "Jump away (double jump)"}, false, "Block (hold through combo)")
toggleD(CombatTab, "DefenseAlways", "Defend even when the farm is off", "Handy when you fight by hand", true)
slider(CombatTab, "ParryRange", "React within", 6, 30, 1, 14, " studs")
slider(CombatTab, "BlockHold", "Keep blocking after the mob's last attack", 1, 8, 0.5, 4, "s")
slider(CombatTab, "PerfectLead", "Perfect block: press before the hit", 0.05, 0.35, 0.01, 0.18, "s")
toggle(CombatTab, "AntiRagdoll", "Don't get knocked down (anti-ragdoll)", true)
toggleD(CombatTab, "NoStun", "No stun", "Hits don't freeze you; you can keep moving and acting", true)

section(MoveTab, "Getting to the spot")
dropdown(MoveTab, "MoveMethod", "How to get there", {"Fly straight (reliable)", "Dash & double jump"}, false, "Fly straight (reliable)")
slider(MoveTab, "MoveSpeed", "Flying speed (lower = safer)", 16, 80, 2, 34, " studs/s")
slider(MoveTab, "HoldRadius", "Go back if pushed farther than", 3, 20, 1, 6, " studs")
toggle(MoveTab, "BlockInput", "Lock my controls while moving", true)
toggleD(MoveTab, "NoShiftLock", "Block shift-lock (Alt)", "Shift-lock turns you with the camera and breaks the farm", true)
section(MoveTab, "Dash & double jump mode")
toggle(MoveTab, "InfJump", "Infinite double jump (climb)", true)
toggle(MoveTab, "UseDash", "Dash toward the spot", true)
slider(MoveTab, "DashGap", "Time between dashes (game cooldown ≈ 0.9)", 0.9, 3, 0.1, 1.1, "s")
toggle(MoveTab, "FlyAssist", "Push up if stuck", false)

section(HealTab, "Health potion")
toggleD(HealTab, "AutoHeal", "Auto heal with a potion", "Goes to the spot, drinks, waits, comes back", true)
slider(HealTab, "HealAt", "Drink below", 10, 80, 5, 40, "% HP")
slider(HealTab, "HealUntil", "Back to fight at", 40, 100, 5, 85, "% HP")
slider(HealTab, "PotionSlot", "Potion toolbar slot", 1, 5, 1, 5)
toggleD(HealTab, "RefillPotion", "Refill the slot from inventory", "When the slot runs dry, puts your next potion from the bag into it", true)
dropdown(HealTab, "NoPotions", "When all potions are gone", {"Keep fighting (no heal)", "Play safe (high spot)"}, false, "Keep fighting (no heal)")
note(HealTab, "<b>Keep fighting</b> — farms on until the hearts run out (checks for new potions every minute).  <b>Play safe</b> — low HP switches to skills from the spot.")
slider(HealTab, "HealMaxWait", "Max wait for regen", 5, 60, 5, 25, "s")
toggle(HealTab, "HealAtSpot", "Heal on the high spot", true)

section(HealTab, "Buy potions before a run")
toggleD(HealTab, "BuyPotions", "Buy from Meku before each run", "walks to Meku, buys, then readies up", true)
dropdown(HealTab, "BuyPotionType", "Which potion", {"Health Regen Elixir", "Health Elixir", "Health Regen Potion", "Health Potion"}, false, "Health Regen Elixir")
slider(HealTab, "BuyPotionCount", "How many", 1, 500, 1, 2)

section(SpotTab, "Farming spot on each map")
local spotsOpt = register("Spots", {}, function() end)
toggleD(SpotTab, "UseRecommended", "Use recommended spots", "Your own saved spot always wins", true)
local spotList = note(SpotTab, "")
spotList.Size = UDim2.new(1, 0, 0, 92)
spotList.TextYAlignment = Enum.TextYAlignment.Top
local function refreshSpots()
	local lines, maps = {}, {}
	for map in pairs(RECOMMENDED_SPOTS) do maps[map] = true end
	for map in pairs(spotsOpt.Value) do maps[map] = true end
	for map in pairs(maps) do
		local own = spotsOpt.Value[map]
		local s = own or RECOMMENDED_SPOTS[map]
		local tag = own and '<font color="#6ec878">yours</font>' or (Options.UseRecommended.Value and '<font color="#e8b648">recommended</font>' or '<font color="#9ca090">recommended (off)</font>')
		table.insert(lines, string.format("<b>%s</b>  ·  %s  ·  %d, %d, %d", map, tag, s[1], s[2], s[3]))
	end
	table.sort(lines)
	spotList.Text = #lines > 0 and table.concat(lines, "\n") or "No spots yet."
end
spotsOpt.Refresh = refreshSpots
Options.UseRecommended.Callback = function() refreshSpots() end
button(SpotTab, "Save my position as this map's spot", nil, function()
	local map, root = currentMap(), getRoot()
	if not map then notify("warn", "No map yet", "Start a run first — the lobby has no map.") return end
	if not root then return end
	local p = root.Position
	local t = table.clone(spotsOpt.Value)
	t[map] = {math.floor(p.X * 10 + 0.5) / 10, math.floor(p.Y * 10 + 0.5) / 10, math.floor(p.Z * 10 + 0.5) / 10}
	spotsOpt:SetValue(t)
	refreshSpots()
	notify("success", "Spot saved", map)
end)
button(SpotTab, "Go to this map's spot now", nil, function()
	local s = spotFor(currentMap())
	if not s then notify("warn", "No spot", "No spot for " .. tostring(currentMap()) .. " yet.") return end
	notify("info", "Moving", "Heading to the spot…")
	if goTo(s) then notify("success", "Arrived", "On the spot.") else notify("warn", "Didn't make it", "Try again, or pick an easier spot.") end
end)
button(SpotTab, "Stop moving", nil, stopMoving)
button(SpotTab, "Reset this map to the recommended spot", nil, function()
	local map = currentMap()
	if not map then return end
	local t = table.clone(spotsOpt.Value)
	t[map] = nil
	spotsOpt:SetValue(t)
	refreshSpots()
	notify("info", "Spot reset", map .. (RECOMMENDED_SPOTS[map] and " → recommended spot" or " has no recommended spot"))
end)

section(SpotTab, "Maps")
dropdown(SpotTab, "GoodMaps", "Maps that are good to farm", {"Rock Dungeon", "Lava Dungeon", "Ice Dungeon", "Desert Dungeon"}, true, {["Rock Dungeon"] = true, ["Lava Dungeon"] = true, ["Ice Dungeon"] = true, ["Desert Dungeon"] = true})
toggleD(SpotTab, "SwapBadMaps", "Tectonic Shift away from bad maps", "Farms there anyway until the card shows up", true)

section(CardTab, "Auto pick")
toggle(CardTab, "AutoCards", "Pick cards automatically", true)
slider(CardTab, "PickDelay", "Wait before picking", 0, 10, 0.5, 1.5, "s")
toggle(CardTab, "AutoReroll", "Reroll when the whole hand is bad", true)
slider(CardTab, "BadRank", "Bad card from rank", 30, 99, 1, 72)

section(CardTab, "Priority · drag ⋮⋮ or type 1–99 (1 = best)")
local orderOpt = register("CardOrder", table.clone(DEFAULT_ORDER), function() end)
orderOpt.NoRefresh = true

local ROW_H = 30
local listFrame = make("Frame", {Parent = CardTab.container, LayoutOrder = nextOrder(CardTab), Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1})
local rows = {}
local dragging

local function layoutRows(instant)
	local order = orderOpt.Value
	listFrame.Size = UDim2.new(1, 0, 0, #order * ROW_H)
	for i, key in ipairs(order) do
		local r = rows[key]
		if r then
			r.box.Text = tostring(i)
			local pos = UDim2.fromOffset(0, (i - 1) * ROW_H)
			if r ~= dragging then
				if instant then r.frame.Position = pos else tween(r.frame, {Position = pos}, 0.2) end
			end
			r.name.TextColor3 = i >= Options.BadRank.Value and T.Error or (i <= 15 and T.Good or T.Text)
		end
	end
end

local function moveKey(key, newIndex)
	local order = table.clone(orderOpt.Value)
	local idx = table.find(order, key)
	if not idx then return end
	table.remove(order, idx)
	table.insert(order, math.clamp(newIndex, 1, #order + 1), key)
	orderOpt:SetValue(order)
	layoutRows()
end

local function makeRow(key)
	local f = make("Frame", {Parent = listFrame, Size = UDim2.new(1, 0, 0, ROW_H - 4), BackgroundColor3 = T.Element, BackgroundTransparency = 0.15}, {corner(6)})
	local s = stroke(T.Stroke, 0.75); s.Parent = f
	local handle = make("TextButton", {Parent = f, Size = UDim2.fromOffset(24, ROW_H - 4), BackgroundTransparency = 1, Text = "⋮⋮", Font = FONT_B, TextSize = 12, TextColor3 = T.SubText, AutoButtonColor = false})
	local box = textBox(f, {Position = UDim2.fromOffset(26, 3), Size = UDim2.fromOffset(38, ROW_H - 10), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 12})
	local name = label({Parent = f, Position = UDim2.fromOffset(72, 0), Size = UDim2.new(1, -78, 1, 0), Text = displayName(key), Font = FONT, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd})
	rows[key] = {frame = f, box = box, name = name}
	connect(f.MouseEnter, function() tween(s, {Color = T.Accent, Transparency = 0.5}) end)
	connect(f.MouseLeave, function() tween(s, {Color = T.Stroke, Transparency = 0.75}) end)
	connect(box.FocusLost, function()
		local n = tonumber(box.Text)
		if n then moveKey(key, math.clamp(math.floor(n), 1, 99)) else layoutRows() end
	end)
	connect(handle.InputBegan, function(i)
		if i.UserInputType == MB1 or i.UserInputType == TOUCH then
			dragging = rows[key]
			dragging.key = key
			f.ZIndex = 5
			tween(f, {BackgroundColor3 = T.Hover}, 0.1)
		end
	end)
end

local function rebuildRows()
	for k, r in pairs(rows) do r.frame:Destroy() rows[k] = nil end
	local order = table.clone(orderOpt.Value)
	local present = {}
	for _, k in ipairs(order) do present[k] = true end
	for _, k in ipairs(DEFAULT_ORDER) do
		if not present[k] then table.insert(order, math.min(50, #order + 1), k) present[k] = true end
	end
	for k in pairs(seenUnknown) do
		if not present[k] then table.insert(order, math.min(50, #order + 1), k) present[k] = true end
	end
	while #order > 99 do table.remove(order) end
	orderOpt.Value = order
	for _, k in ipairs(order) do makeRow(k) end
	layoutRows(true)
end
orderOpt.Refresh = rebuildRows

connect(UIS.InputChanged, function(i)
	if dragging and (i.UserInputType == MOVE or i.UserInputType == TOUCH) then
		local y = i.Position.Y - listFrame.AbsolutePosition.Y - ROW_H / 2
		dragging.frame.Position = UDim2.fromOffset(0, math.clamp(y, 0, listFrame.AbsoluteSize.Y - ROW_H))
	end
end)
connect(UIS.InputEnded, function(i)
	if dragging and (i.UserInputType == MB1 or i.UserInputType == TOUCH) then
		local d = dragging
		dragging = nil
		d.frame.ZIndex = 1
		tween(d.frame, {BackgroundColor3 = T.Element}, 0.15)
		moveKey(d.key, math.floor((d.frame.Position.Y.Offset + ROW_H / 2) / ROW_H) + 1)
	end
end)

button(CardTab, "Reset to the recommended order", nil, function()
	orderOpt:SetValue(table.clone(DEFAULT_ORDER))
	rebuildRows()
	notify("success", "Priority reset", "Recommended order restored.")
end)

section(HookTab, "Discord")
input(HookTab, "WebhookURL", "Webhook URL", "https://discord.com/api/webhooks/...")
toggle(HookTab, "WebhookEnabled", "Send updates to Discord", false)
slider(HookTab, "HookEvery", "Progress every N floors", 1, 25, 1, 5)
toggle(HookTab, "HookMaps", "Map changes", true)
toggle(HookTab, "HookDeaths", "Deaths", true)
toggle(HookTab, "HookCards", "Picked cards (spammy)", false)
toggle(HookTab, "PingTarget", "@everyone at the target floor", true)
button(HookTab, "Send a test message", nil, function()
	if trim(Options.WebhookURL.Value) == "" then notify("warn", "No URL", "Paste your Discord webhook URL first.") return end
	if sendWebhook("test", "Ouwigahara farm is connected.") then
		notify("success", "Webhook connected", "Test message delivered.")
	else
		notify("error", "Webhook failed", "Discord rejected the request. Check the URL.")
	end
end)

section(SettingsTab, "Window")
toggle(SettingsTab, "ShowFloatButton", "Show the round minimize button", true, function(on)
	if floatButton then floatButton.Visible = on end
end)
section(SettingsTab, "Theme")
colorPicker(SettingsTab, "AccentColor", "Accent color", "#8E9A4E")

do
section(SettingsTab, "Configs")
local CFG_DIR = CONFIG_DIR .. "/ouwigahara-configs"
local CFG_AUTO = CONFIG_DIR .. "/ouwigahara-autoload.txt"
local cfgName = input(SettingsTab, "ConfigName", "Config name", "e.g. hover-farm")
cfgName.NoSave = true
local function listConfigs()
	local names = {}
	if canFiles then
		pcall(function()
			if not isfolder(CFG_DIR) then makefolder(CFG_DIR) end
			for _, f in ipairs(listfiles(CFG_DIR)) do
				local n = tostring(f):match("([^/\\]+)%.json$")
				if n then table.insert(names, n) end
			end
		end)
	end
	table.sort(names)
	return names
end
local cfgSelect = dropdown(SettingsTab, "ConfigSelect", "Saved configs", listConfigs(), false, "")
cfgSelect.NoSave = true
local autoNote = note(SettingsTab, "")
local function getAutoload()
	if not canFiles then return nil end
	local ok, n = pcall(function() return isfile(CFG_AUTO) and readfile(CFG_AUTO) or nil end)
	n = ok and n and trim(n) or nil
	return (n ~= "" and n) or nil
end
local function refreshCfg()
	cfgSelect.SetValues(listConfigs())
	local a = getAutoload()
	autoNote.Text = a and ("Autoload: <b>" .. a .. "</b>") or "Autoload: off (the last session is restored)"
end
local function selectedCfg()
	local n = trim(cfgName.Value)
	if n == "" then n = cfgSelect.Value or "" end
	return n ~= "" and n or nil
end
button(SettingsTab, "Save config", nil, function()
	local n = selectedCfg()
	if not n then notify("warn", "No name", "Type a config name first.") return end
	ensureDirs()
	pcall(function() if not isfolder(CFG_DIR) then makefolder(CFG_DIR) end end)
	local ok = pcall(writefile, CFG_DIR .. "/" .. n .. ".json", HttpService:JSONEncode(collect()))
	refreshCfg()
	cfgSelect:SetValue(n, true)
	notify(ok and "success" or "error", ok and "Config saved" or "Save failed", n)
end)
button(SettingsTab, "Load selected config", nil, function()
	local n = cfgSelect.Value
	if not n or n == "" then notify("warn", "Nothing selected", "Pick a config from the list.") return end
	local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CFG_DIR .. "/" .. n .. ".json")) end)
	if ok and type(data) == "table" then
		applyData(data)
		rebuildRows()
		refreshSpots()
		notify("success", "Config loaded", n)
	else
		notify("error", "Load failed", n)
	end
end)
button(SettingsTab, "Delete selected config", nil, function()
	local n = cfgSelect.Value
	if not n or n == "" then return end
	pcall(delfile, CFG_DIR .. "/" .. n .. ".json")
	if getAutoload() == n then pcall(delfile, CFG_AUTO) end
	cfgSelect:SetValue("", true)
	refreshCfg()
	notify("info", "Config deleted", n)
end)
button(SettingsTab, "Autoload selected config", nil, function()
	local n = cfgSelect.Value
	if not n or n == "" then notify("warn", "Nothing selected", "Pick a config from the list.") return end
	ensureDirs()
	pcall(writefile, CFG_AUTO, n)
	refreshCfg()
	notify("success", "Autoload set", n)
end)
button(SettingsTab, "Turn off autoload", nil, function()
	pcall(delfile, CFG_AUTO)
	refreshCfg()
	notify("info", "Autoload off", "The last session will be restored instead.")
end)
refreshCfg()
end

section(SettingsTab, "Script")
toggle(SettingsTab, "VerboseLog", "Detailed log (kills, hits, refusals, moves)", true)
note(SettingsTab, "End key or the round button hides the window. Anti-AFK is always on.")
button(SettingsTab, "Unload", nil, function() app.Destroy() end)

local visible, hintShown = true, false
local function setVisible(v)
	visible = v
	if v then
		main.Visible = true
		mainScale.Scale = 0.94
		tween(mainScale, {Scale = 1}, 0.3, Enum.EasingStyle.Back)
	else
		tween(mainScale, {Scale = 0.94}, 0.15)
		task.delay(0.15, function() if not visible then main.Visible = false end end)
	end
end
topButton(top, "–", -42, function()
	setVisible(false)
	if not hintShown then
		hintShown = true
		notify("info", "Window hidden", "Press End to bring it back.")
	end
end)
topButton(top, "×", -12, function() app.Destroy() end)
connect(UIS.InputBegan, function(i, gpe)
	if not gpe and i.KeyCode == Enum.KeyCode.End then setVisible(not visible) end
end)

do
	floatButton = make("TextButton", {
		Parent = gui, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 18, 0.5, 0), Size = UDim2.fromOffset(52, 52),
		BackgroundColor3 = Color3.fromRGB(22, 24, 18), BackgroundTransparency = 0.02, AutoButtonColor = false, Text = "", ZIndex = 20,
	}, {corner(12)})
	local fs = make("UIStroke", {Parent = floatButton, Thickness = 1.5, Transparency = 0.45, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
	accent(fs, "Color")
	app.drawMark(floatButton, 40, 21)
	local sc = make("UIScale", {Parent = floatButton})
	connect(floatButton.MouseEnter, function() tween(sc, {Scale = 1.08}, 0.2, Enum.EasingStyle.Back) end)
	connect(floatButton.MouseLeave, function() tween(sc, {Scale = 1}, 0.2) end)
	local downAt, downPos, startPos, dragging
	connect(floatButton.InputBegan, function(i)
		if i.UserInputType == MB1 or i.UserInputType == TOUCH then
			downAt, downPos, startPos, dragging = os.clock(), i.Position, floatButton.Position, false
		end
	end)
	connect(UIS.InputChanged, function(i)
		if downPos and (i.UserInputType == MOVE or i.UserInputType == TOUCH) then
			local d = i.Position - downPos
			if d.Magnitude > 6 then dragging = true end
			if dragging then
				floatButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end
	end)
	connect(UIS.InputEnded, function(i)
		if downPos and (i.UserInputType == MB1 or i.UserInputType == TOUCH) then
			if not dragging then
				tween(sc, {Scale = 0.9}, 0.08)
				task.delay(0.08, function() tween(sc, {Scale = 1}, 0.25, Enum.EasingStyle.Back) end)
				setVisible(not visible)
			end
			downPos = nil
		end
	end)
end

local alive = true
function app.Destroy()
	alive = false
	aimEnabled = false
	restoreAim()
	blockWanted = false
	if InputHandler and env.__AxiomOrigIsDown then InputHandler.IsDown = env.__AxiomOrigIsDown end
	if RunHandler and env.__AxiomOrigShiftLock then RunHandler.SetShiftLock = env.__AxiomOrigShiftLock end
	stopMoving()
	for _, c in ipairs(app.connections) do pcall(function() c:Disconnect() end) end
	if gui.Parent then
		tween(mainScale, {Scale = 0.9}, 0.15)
		task.delay(0.15, function() gui:Destroy() end)
	end
	if env.__AxiomOuw == app then env.__AxiomOuw = nil end
end

do
	local ShopTab = dbg.shopTab
	local SignalFunction = tryRequire(function() return RS.Communication.ServerAndClient.Signals.SignalFunction end)
	local S = {}
	S.npc = {
		Zeni = Vector3.new(-2290.3, 1141.7, -2634.8),
		Togane = Vector3.new(-2312.1, 1144.3, -2684.9),
	}

	S.damascus = {
		{"Damascus Sickles", "damascus_sickles", "Sickles"}, {"Damascus Scythe", "damascus_scythe", "Scythe"},
		{"Damascus Gauntlet", "damascus_gauntlet", "Gauntlet"}, {"Damascus Claws", "damascus_claws", "Claws"},
		{"Damascus Spear", "damascus_spear", "Spear"}, {"Damascus Tanto", "damascus_tanto", "Tanto"},
		{"Damascus War Fans", "damascus_war_fans", "War Fans"}, {"Damascus Shotgun", "damascus_shotgun", "Shotgun"},
		{"Damascus Bladed Wagasa", "damascus_bladed_wagasa", "Bladed Wagasa"},
		{"Tidal Katana", "tidal_katana", "Water Katana"}, {"Tornadic Katana", "tornadic_katana", "Wind Katana"},
		{"Volcanic Katana", "volcanic_katana", "Flame Katana"}, {"Thundercloud Katana", "thundercloud_katana", "Thunder Katana"},
		{"Serpentine Katana", "serpentine_katana", "Serpent Katana"}, {"Butterfly Katana", "butterfly_katana", "Insect Katana"},
		{"Reverb Cleavers", "reverb_cleavers", "Sound Katanas"}, {"Seismic Axe and Mace", "seismic_axe_and_mace", "Axe and Mace"},
	}
	S.items = {
		{label = "Mythic Refinement Ore · 30k", cost = 30000, npc = "Zeni", item = "Mythic Refinement Ore"},
		{label = "Ouwigahara Chest · 30k", cost = 30000, chest = true},
		{label = "Damascus weapon · 90k", cost = 90000, craft = true},
		{label = "1,000 Exp · 3.5k", cost = 3500, npc = "Crystal", item = "1,000 Exp"},
		{label = "+1,000 Mastery · 3k", cost = 3000, npc = "Crystal", mastery = true},
		{label = "Refinement Ore · 1.5k", cost = 1500, npc = "Zeni", item = "Refinement Ore"},
		{label = "1,000 Wen · 2.5k", cost = 2500, npc = "Zeni", item = "1,000 Wen"},
	}
	local labels, dnames = {}, {}
	for _, it in ipairs(S.items) do table.insert(labels, it.label) end
	for _, d in ipairs(S.damascus) do table.insert(dnames, d[1]) end

	section(ShopTab, "Run points")
	S.pointsNote = note(ShopTab, "")
	toggleD(ShopTab, "AutoShop", "Spend points when the run ends", "In town after the last heart (or after leaving at the target floor): buys what you picked below", true)
	toggleD(ShopTab, "LoopRuns", "Start a new run afterwards", "Leaving at the target floor keeps the farm on: shop, then ready up again", true)
	section(ShopTab, "What to buy")
	note(ShopTab, "Goes top to bottom: buys as many of the first ticked item as it can, then the next.")
	dropdown(ShopTab, "ShopBuy", "Buy (in this order)", labels, true, {[labels[1]] = true, [labels[4]] = true})
	dropdown(ShopTab, "DamascusPick", "Damascus weapon to craft", dnames, false, "Damascus Sickles")
	dropdown(ShopTab, "MasteryFor", "Mastery goes to", {"Demon Art", "Breathing"}, false, "Demon Art")
	slider(ShopTab, "ShopKeep", "Always keep", 0, 100000, 1000, 0, " pts")
	slider(ShopTab, "ShopMaxEach", "At most per item, per trip", 1, 30, 1, 10)
	toggleD(ShopTab, "OpenCaches", "Open the free floor chests", "Chests from every 10th floor (better loot the higher you got)", true)

	function S.points() return tonumber(player:GetAttribute("RunPoints")) or 0 end
	function S.bag(name)
		local data = Utility and select(2, pcall(Utility.GetData, player))
		if typeof(data) ~= "Instance" then return 0 end
		local n = 0
		for _, it in ipairs(data.Inventory.Inventory:GetChildren()) do
			if it.Name == name then
				local a = it:FindFirstChild("Amount")
				n += a and a.Value or 1
			end
		end
		return n
	end

	function S.travel(pos, near)
		near = near or 10
		for _ = 1, 8 do
			local r = getRoot()
			if not r then return false end
			if (r.Position - pos).Magnitude <= near then return true end
			goTo(pos)
		end
		local r = getRoot()
		return r ~= nil and (r.Position - pos).Magnitude <= near + 4
	end
	dbg.travel = S.travel
	function S.posOf(inst)
		if inst:IsA("BasePart") then return inst.Position end
		if inst:IsA("Attachment") then return inst.WorldPosition end
		if inst:IsA("Model") then return inst:GetPivot().Position end
		return nil
	end

	function S.prompts(pos, radius, want)
		local out = {}
		for _, p in ipairs(workspace:GetDescendants()) do
			if p:IsA("ProximityPrompt") and p.Enabled then
				local at = p.Parent and S.posOf(p.Parent)
				if at and (not pos or (at - pos).Magnitude <= radius) and (not want or want(p)) then
					table.insert(out, {p = p, pos = at})
				end
			end
		end
		return out
	end
	function S.fire(p)
		if not pcall(fireproximityprompt, p) then
			pcall(function()
				p:InputHoldBegin()
				task.wait(p.HoldDuration + 0.2)
				p:InputHoldEnd()
			end)
		end
	end
	function S.buyPotions()
		local item, want = Options.BuyPotionType.Value, Options.BuyPotionCount.Value
		local okM, meku = pcall(require, RS["Minigames Place"].Content.Ouwigahara.Npcs.Meku)
		local price = okM and type(meku) == "table" and meku.Shop and meku.Shop[item] and meku.Shop[item].Price
		local data = Utility and select(2, pcall(Utility.GetData, player))
		if not (price and typeof(data) == "Instance") then dlog("warn", "Potions: shop data not found") return end
		local wenV = data:FindFirstChild("Wen", true)
		local wen = wenV and wenV.Value or 0
		local function bagAmt(n)
			local it = data.Inventory.Inventory:FindFirstChild(n)
			local a = it and it:FindFirstChild("Amount")
			return a and a.Value or 0
		end
		local can = want
		for cur, cost in pairs(price) do
			local have = cur == "Wen" and wen or bagAmt(cur)
			can = math.min(can, math.floor(have / math.max(cost, 1)))
		end
		if can <= 0 then
			dlog("warn", ("Potions: not enough to buy %s (Wen %d)"):format(item, wen))
			hook("start", ("Couldn't buy %s — not enough Wen (%d, need %d each)."):format(item, wen, price.Wen or 0))
			return
		end
		local m = S.findNamed("Meku")
		local at = m and S.posOf(m) or Vector3.new(-2452.15, 1142.35, -5163.36)
		local root = getRoot()
		if not root or (root.Position - at).Magnitude > 250 then dlog("warn", "Potions: Meku too far — skipped") return end
		if not S.travel(at, 8) then dlog("warn", "Potions: couldn't reach Meku") return end
		local before = bagAmt(item)
		local list = S.prompts(at, 25)
		if #list > 0 then S.fire(list[1].p) task.wait(1) end
		local left = can
		while left > 0 do
			local chunk = math.min(left, 99)
			local was = bagAmt(item)
			pcall(SignalEvent.ToServer, "PurchaseFromShop", item, chunk)
			local t0 = os.clock()
			repeat task.wait(0.1) until bagAmt(item) > was or os.clock() - t0 > 2
			task.wait(0.2)
			local now = bagAmt(item) - was
			if now <= 0 then
				pcall(SignalEvent.ToServer, "PurchaseFromShop", item, 1)
				task.wait(0.8)
				now = bagAmt(item) - was
				if now <= 0 then break end
			end
			left -= now
		end
		local got = bagAmt(item) - before
		if got > 0 then
			pcall(S.equipPotion, item)
			dlog("heal", ("Bought %d× %s%s"):format(got, item, got < want and (" (wanted " .. want .. ", money ran out)") or ""))
			if got < want then hook("start", ("Bought only %d/%d %s — not enough Wen."):format(got, want, item)) end
		else
			dlog("warn", "Potions: Meku didn't sell")
			hook("start", "Couldn't buy " .. item .. " — Meku refused.")
		end
	end
	dbg.buyPotions = S.buyPotions
	dbg.equipPotion = function(i) return S.equipPotion(i) end
	function S.equipPotion(item)
		local data = Utility and select(2, pcall(Utility.GetData, player))
		if typeof(data) ~= "Instance" then return end
		local it = data.Inventory.Inventory:FindFirstChild(item)
		local idV = it and it:FindFirstChild("Id")
		if not idV then return end
		local tb = data.Inventory:FindFirstChild("Toolbar")
		if not tb then return end
		local NAMES = {"One", "Two", "Three", "Four", "Five"}
		local cip
		pcall(function() cip = require(RS.CAM:FindFirstChild("Character_info_provider", true)) end)
		local function nameIn(i)
			local v = tb:FindFirstChild(NAMES[i])
			if not v or v.Value == 0 then return nil end
			if v.Value == idV.Value then return item end
			local ok, obj = pcall(function() return cip and cip.GetItemFromId(player, v.Value) end)
			return ok and obj and obj.Name or "?"
		end
		for i = 1, 5 do
			if nameIn(i) == item then
				if Options.PotionSlot.Value ~= i then Options.PotionSlot:SetValue(i) end
				return
			end
		end
		local pick
		for i = 5, 1, -1 do if not nameIn(i) then pick = i break end end
		if not pick then
			for i = 5, 1, -1 do
				local n = nameIn(i) or ""
				local keep = i == Options.WeaponSlot.Value or n:find("Skill") or n:find("Art") or n:find("Potion") or n:find("Elixir")
				if not keep then pick = i break end
			end
		end
		if not pick then dlog("warn", "Potions: no slot to free") return end
		local was = nameIn(pick)
		pcall(SignalEvent.ToServer, "Toolbar_Equip", NAMES[pick], idV.Value)
		task.wait(1)
		if Options.PotionSlot.Value ~= pick then Options.PotionSlot:SetValue(pick) end
		dlog("heal", ("Put %s in slot %d%s"):format(item, pick, was and (" (was " .. was .. ")") or ""))
	end
	function S.findNamed(pattern)
		for _, d in ipairs(workspace:GetDescendants()) do
			if (d:IsA("Model") or d:IsA("BasePart")) and d.Name:find(pattern) then return d end
		end
		return nil
	end
	function S.masteryItem()
		local ok, crystal = pcall(require, RS["Minigames Place"].Content.Ouwigahara.Crystal)
		local data = Utility and select(2, pcall(Utility.GetData, player, true))
		if not (ok and type(crystal) == "table" and crystal.Sources and typeof(data) == "Instance") then return nil end
		local key = Options.MasteryFor.Value == "Breathing" and "Breathing" or "DemonArt"
		local v = data:FindFirstChild(key, true)
		local name = v and v:IsA("ValueBase") and tostring(v.Value) or nil
		return name and crystal.Sources[name] or nil
	end

	function S.buyOne(item, where)
		if where and not S.travel(where, 10) then return false, "couldn't reach the shop" end
		local before = S.points()
		pcall(SignalEvent.ToServer, "PurchaseFromShop", item, 1)
		local t0 = os.clock()
		repeat task.wait(0.1) until S.points() < before or os.clock() - t0 > 1.2
		if S.points() < before then return true end

		local list = where and S.prompts(where, 25) or {}
		if #list > 0 then
			S.fire(list[1].p)
			task.wait(1)
			pcall(SignalEvent.ToServer, "PurchaseFromShop", item, 1)
			task.wait(1.2)
			if S.points() < before then return true end
		end
		return false, "shop refused"
	end
	function S.buyMany(item, where, n, cost)
		if where and not S.travel(where, 10) then return 0 end
		local before = S.points()
		pcall(SignalEvent.ToServer, "PurchaseFromShop", item, n)
		local t = os.clock()
		repeat task.wait(0.1) until S.points() < before or os.clock() - t > 1.5
		task.wait(0.2)
		return math.floor((before - S.points()) / math.max(cost, 1) + 0.5)
	end
	function S.craftDamascus()
		local pick
		for _, d in ipairs(S.damascus) do if d[1] == Options.DamascusPick.Value then pick = d end end
		if not pick then return false, "no weapon picked" end
		local need = {{pick[3], 1}, {"Mythic Refinement Ore", 10}, {"Metal Scraps", 500}, {"Silk Thread", 300}}
		for _, n in ipairs(need) do
			local have = S.bag(n[1])
			if have < n[2] then return false, ("need %s %d/%d"):format(n[1], have, n[2]) end
		end
		if not SignalFunction then return false, "craft request not found" end
		if not S.travel(S.npc.Togane, 10) then return false, "couldn't reach the blacksmith" end
		local before = S.points()
		local list = S.prompts(S.npc.Togane, 25)
		if #list > 0 then S.fire(list[1].p) task.wait(1) end
		pcall(SignalFunction.ToServer, "CraftRecipe", pick[2])
		task.wait(1.5)
		if S.points() < before then return true end
		return false, "blacksmith refused"
	end
	function S.openPointsChest()
		local c = S.findNamed("^Ouwigahara Chest")
		local at = c and S.posOf(c)
		if not at then return false, "points chest not found" end
		if not S.travel(at, 8) then return false, "couldn't reach the chest" end
		local before = S.points()
		local list = S.prompts(at, 15)
		if #list == 0 then return false, "chest has no prompt" end
		S.fire(list[1].p)
		task.wait(2.5)
		if S.points() < before then task.wait(1) S.collectLoot() return true end
		return false, "chest didn't open"
	end
	function S.collectLoot()
		local tag = "LootDrop"
		pcall(function() tag = require(RS.CAM.Global.gameSettings).Tags.LootDrop or tag end)
		local CS = game:GetService("CollectionService")
		local got, fired = 0, {}
		for _ = 1, 25 do
			local root = getRoot()
			if not root then break end
			local best, bestD, bestP
			for _, part in ipairs(CS:GetTagged(tag)) do
				if part:IsA("BasePart") and part.Parent then
					local owner, reserved = part:GetAttribute("DropOwnerUserId"), part:GetAttribute("DropReservedFor")
					local mine = (typeof(owner) ~= "number" or owner == player.UserId)
						and (typeof(reserved) ~= "string" or reserved:find("," .. player.UserId .. ",", 1, true) ~= nil)
					local pr = mine and part:FindFirstChildWhichIsA("ProximityPrompt", true)
					if pr and pr.Enabled and not fired[pr] then
						local d = (part.Position - root.Position).Magnitude
						if d < 150 and (not bestD or d < bestD) then best, bestD, bestP = part, d, pr end
					end
				end
			end
			if not best then break end
			if bestD > bestP.MaxActivationDistance - 1 and not S.travel(best.Position, 4) then break end
			root = getRoot()
			for _, part in ipairs(CS:GetTagged(tag)) do
				local pr = part:IsA("BasePart") and part:FindFirstChildWhichIsA("ProximityPrompt", true)
				if pr and pr.Enabled and not fired[pr] and root and (part.Position - root.Position).Magnitude <= pr.MaxActivationDistance - 0.5 then
					local owner = part:GetAttribute("DropOwnerUserId")
					if typeof(owner) ~= "number" or owner == player.UserId then
						fired[pr] = true
						task.spawn(S.fire, pr)
						got += 1
					end
				end
			end
			task.wait(0.25)
		end
		if got > 0 then dlog("card", "Picked up " .. got .. " drop" .. (got == 1 and "" or "s")) end
		return got
	end
	function S.openCaches()
		local opened = 0
		for _ = 1, 12 do
			local list = S.prompts(nil, 0, function(p)
				local m = p:FindFirstAncestorOfClass("Model")
				return m ~= nil and (m.Name:find("Cache") ~= nil or (m.Name:find("Chest") ~= nil and not m.Name:find("^Ouwigahara Chest")))
			end)
			if #list == 0 then break end
			local r = getRoot()
			table.sort(list, function(a, b) return r and (a.pos - r.Position).Magnitude < (b.pos - r.Position).Magnitude or false end)
			local c = list[1]
			if not S.travel(c.pos, 7) then break end
			S.fire(c.p)
			opened += 1
			task.wait(1.2)
		end
		if opened > 0 then dlog("card", "Opened " .. opened .. " floor chest" .. (opened == 1 and "" or "s")) end
		if opened > 0 then task.wait(1) S.collectLoot() end
	end
	function S.spend()
		if dbg.shopBusy then return end
		dbg.shopBusy = true
		local spent0 = S.points()
		local log = {}
		pcall(function()
			dlog("info", ("Shopping in town · %s points"):format(fmtNum(S.points())))
			if Options.OpenCaches.Value then S.openCaches() end
			local sel = Options.ShopBuy.Value
			for _, it in ipairs(S.items) do
				if type(sel) == "table" and sel[it.label] then
					local bought = 0
					while bought < Options.ShopMaxEach.Value and S.points() - it.cost >= Options.ShopKeep.Value do
						local ok, why
						if it.craft then
							ok, why = S.craftDamascus()
						elseif it.chest then
							ok, why = S.openPointsChest()
						else
							local item = it.mastery and S.masteryItem() or it.item
							local where = S.npc[it.npc]
							if not where then
								local c = S.findNamed("Crystal")
								where = c and S.posOf(c)
							end
							if not item then ok, why = false, "mastery item not found"
							else
								local n = math.min(99, Options.ShopMaxEach.Value - bought, math.floor((S.points() - Options.ShopKeep.Value) / it.cost))
								local got = n > 1 and S.buyMany(item, where, n, it.cost) or 0
								if got > 0 then
									bought += got - 1
									ok = true
								else
									ok, why = S.buyOne(item, where)
								end
							end
						end
						if not ok then
							dlog("warn", it.label:match("^(.-) ·") .. ": " .. tostring(why))
							break
						end
						bought += 1
					end
					if bought > 0 then
						table.insert(log, bought .. "× " .. it.label:match("^(.-) ·"))
						dlog("card", "Bought " .. bought .. "× " .. it.label:match("^(.-) ·"))
					end
				end
			end
		end)
		local spent = spent0 - S.points()
		if #log > 0 then
			notify("success", "Shopping done", table.concat(log, ", "))
			hook("card", "Spent " .. spent .. " points: " .. table.concat(log, ", "))
		else
			dlog("info", "Shop: nothing bought (" .. S.points() .. " points)")
		end
		dbg.shopBusy = false
		dbg.shopDone = true
	end
	button(ShopTab, "Spend points now", "Runs the shopping list right away (you must be in town)", function() task.spawn(S.spend) end)

	dbg.shopDone = false

	task.spawn(function()
		while alive do
			S.pointsNote.Text = ("You have <b>%s</b> run points%s"):format(fmtNum(S.points()), dbg.shopBusy and "  ·  shopping…" or "")
			task.wait(1)
		end
	end)
	task.spawn(function()
		while alive do
			if inRun() then
				dbg.shopDone = false
				dbg.potionsDone = false
			elseif runState() == "Lobby" and not dbg.shopDone and not dbg.shopBusy then
				if Options.AutoShop.Value or dbg.gaveUp then
					task.wait(4)
					S.spend()
					dbg.gaveUp = false
				else
					dbg.shopDone = true
				end
			end
			task.wait(1)
		end
	end)
end

do
	local loadedAuto = false
	pcall(function()
		local auto = isfile(CONFIG_DIR .. "/ouwigahara-autoload.txt") and trim(readfile(CONFIG_DIR .. "/ouwigahara-autoload.txt")) or ""
		local file = CONFIG_DIR .. "/ouwigahara-configs/" .. auto .. ".json"
		if auto ~= "" and isfile(file) then
			local data = HttpService:JSONDecode(readfile(file))
			if type(data) == "table" then applyData(data) loadedAuto = true end
		end
	end)
	if not loadedAuto and canFiles then

		local file = isfile(LAST_FILE) and LAST_FILE or (isfile("AxiomHUB/ouwigahara.json") and "AxiomHUB/ouwigahara.json" or nil)
		if file then
			local ok, data = pcall(function() return HttpService:JSONDecode(readfile(file)) end)
			if ok and type(data) == "table" then applyData(data) end
		end
	end
	loading = false
	for k, v in pairs(AXIOM_CONFIG) do
		if Options[k] and type(v) == type(Options[k].Value) then pcall(Options[k].SetValue, Options[k], v, true) end
	end
	if Options.MoveMethod.Value == "Walk, jump & dash" then Options.MoveMethod:SetValue("Dash & double jump", true) end
	if Options.DefenseMode.Value == "Dash away" then Options.DefenseMode:SetValue("Jump away (double jump)", true) end
	if Options.DefenseMode.Value == "Hold block near mobs" then Options.DefenseMode:SetValue("Block (hold through combo)", true) end
	if Options.DefenseMode.Value == "Block (parry)" then Options.DefenseMode:SetValue("Block (hold through combo)", true) end
	if Options.AtTarget.Value == "Leave the run (Give Up)" then Options.AtTarget:SetValue("Leave the run (Multi-Player)", true)
	elseif Options.AtTarget.Value ~= "Leave the run (Multi-Player)" then Options.AtTarget:SetValue("Just stop farming", true) end
	rebuildRows()
	refreshSpots()
	if floatButton then floatButton.Visible = Options.ShowFloatButton.Value end
end

farmToggle.Callback = function(on)
	if on then
		if Options.NoShiftLock.Value and RunHandler and RunHandler.SetShiftLock then pcall(RunHandler.SetShiftLock, 0) end
		dlog("info", "Farm started · " .. Options.FarmMode.Value)
		session.started = os.time()
		notify("success", "Farm on", Options.FarmMode.Value)
		hook("start", "Farm started on floor " .. floorNum())
	else
		aimEnabled = false
		aimTarget = nil
		hoverTarget = nil
		stopMoving()
		notify("info", "Farm off", "Stopped.")
		dlog("info", "Farm stopped")
	end
end

task.spawn(function()
	refreshProfile()
	buildAvatar()
	while alive do
		task.wait(5)
		refreshProfile()
	end
end)

task.spawn(function()
	local handled = {}
	while alive do
		local offers = player:FindFirstChild("OuwigaharaOffers")
		if offers and Options.AutoCards.Value then
			task.wait(Options.PickDelay.Value)
			local sent, rerolled = 0, false
			while alive and offers.Parent and sent < 8 do
				local cards = {}
				for _, c in ipairs(offers:GetChildren()) do
					if not handled[c] and c:GetAttribute("Title") ~= nil then
						local key = cardKey(c)
						if not table.find(orderOpt.Value, key) and not seenUnknown[key] then
							seenUnknown[key] = true
							task.defer(rebuildRows)
						end
						table.insert(cards, {card = c, key = key, rank = effectiveRank(key)})
					end
				end
				if #cards == 0 then break end
				table.sort(cards, function(a, b) return a.rank < b.rank end)
				local best = cards[1]
				local rerolls = tonumber(offers:GetAttribute("Rerolls")) or tonumber(player:GetAttribute("Rerolls")) or 0
				if Options.AutoReroll.Value and best.rank >= Options.BadRank.Value and rerolls > 0 and not rerolled then
					rerolled = true
					request({action = "Reroll"})
					dlog("card", "Rerolled a bad hand")
					task.wait(1.2)
				else

					for _, c in ipairs(cards) do handled[c.card] = true end
					request({action = "Pick", id = best.card.Name})
					session.picks += 1
					dlog("card", "Picked " .. displayName(best.key) .. " (rank " .. math.min(best.rank, 99) .. ")")
					hook("card", displayName(best.key))
					sent += 1
					task.wait(1.1)
				end
			end
			handled = {}
			while alive and offers.Parent do task.wait(0.3) end
		end
		task.wait(0.3)
	end
end)

task.spawn(function()
	local lastFloor, lastMap = floorNum(), currentMap()
	local skippedBreak
	local lastStartTry = 0
	while alive do
		local f, map = floorNum(), currentMap()
		if f > lastFloor and Options.Farm.Value then
			if Options.WebhookEnabled.Value and f % Options.HookEvery.Value == 0 then hook("floor", "Reached floor " .. f) end
			if f >= Options.TargetFloor.Value then
				hook("target", "Reached floor " .. f)
				notify("success", "Target reached", "Floor " .. f)
				if Options.AtTarget.Value == "Leave the run (Multi-Player)" then
					request({action = "GiveUp"})
					dbg.gaveUp = true

					if not Options.LoopRuns.Value then Options.Farm:SetValue(false) end
				else
					Options.Farm:SetValue(false)
				end
			end
		end
		if map and map ~= lastMap and Options.Farm.Value then hook("map", "Now on " .. map) end
		lastFloor, lastMap = f, map

		local brk = workspace:GetAttribute("MinigameWaveBreak")
		if not brk or brk == 0 then skippedBreak = nil end
		if Options.Farm.Value and Options.AutoSkipBreak.Value and brk and brk ~= 0 and skippedBreak == nil then
			skippedBreak = true
			task.delay(1.5, function() request({action = "Skip"}) end)
		end

		if Options.Farm.Value and Options.AutoStart.Value and runState() == "Lobby" and os.clock() - lastStartTry > 25
			and not dbg.shopBusy and (dbg.shopDone ~= false or not Options.AutoShop.Value) then
			lastStartTry = os.clock()
			task.spawn(function()

				local function isReady(p)
					if not (p:IsA("ProximityPrompt") and p.Enabled) then return false end
					local t = tostring(p.ActionText):lower()
					return p.Name == "ReadyUp" or (t:find("ready") ~= nil and not t:find("unready") and not t:find("leave") and not t:find("exit"))
				end
				local function findReady()
					local ok, ru = pcall(function() return workspace.Map["Minigame Map"].StartPad.ReadyUp end)
					if ok and ru and isReady(ru) then return ru end
					for _, d in ipairs(workspace:GetDescendants()) do if isReady(d) then return d end end
					return nil
				end
				local list = {findReady()}
				if #list == 0 then
					local root = getRoot()
					local pad = workspace.Map:FindFirstChild("Shops") and workspace.Map.Shops:FindFirstChild("LeavePad")
					local leave = pad and pad:FindFirstChildWhichIsA("ProximityPrompt")
					if not (Options.LoopRuns.Value and leave and root and pad:IsA("BasePart")) then
						dlog("info", "In town · Ready Up isn't here, waiting")
						return
					end
					if (root.Position - pad.Position).Magnitude > 300 then dlog("warn", "Leave pad too far — not moving") return end
					if dbg.shopBusy or (Options.AutoShop.Value and dbg.shopDone ~= true) then dlog("info", "Waiting for the shop first") return end
					dlog("info", "Shop done → back to menu for a new run")
					hook("start", "Run over, going back to the menu to queue again.")
					pcall(writefile, "AxiomHUB/requeue.flag", tostring(os.time()))
					if (root.Position - pad.Position).Magnitude > leave.MaxActivationDistance - 1 then dbg.travel(pad.Position + Vector3.new(0, 3, 0), 4) end
					if not pcall(fireproximityprompt, leave) then
						pcall(function() leave:InputHoldBegin() task.wait(leave.HoldDuration + 0.15) leave:InputHoldEnd() end)
					end
					return
				end
				if Options.BuyPotions.Value and not dbg.potionsDone and dbg.buyPotions then
					dbg.potionsDone = true
					pcall(dbg.buyPotions)
				end
				for _, p in ipairs(list) do
					if isReady(p) then
						dlog("info", "Lobby → pressing " .. tostring(p.ActionText) .. " (T)")
						local part = p.Parent
						local pos = part and (part:IsA("Attachment") and part.WorldPosition or (part:IsA("BasePart") and part.Position))
						local root = getRoot()
						if pos and root and (root.Position - pos).Magnitude > p.MaxActivationDistance - 1 then
							if dbg.travel then dbg.travel(pos, 5) else goTo(pos) end
						end
						if not pcall(fireproximityprompt, p) then
							pcall(function()
								p:InputHoldBegin()
								task.wait(p.HoldDuration + 0.15)
								p:InputHoldEnd()
							end)
						end
						break
					end
				end
			end)
		end
		task.wait(0.5)
	end
end)

connect(player.CharacterAdded, function()
	task.delay(3, function() if alive then buildAvatar() end end)
	if Options.Farm.Value then
		session.deaths += 1
		hook("death", "Respawning, heading back.")
		dlog("warn", "Died — respawning")
		stopMoving()
	end
end)

skillList = startSkills
task.spawn(function()
	while alive do
		task.wait(8)
		local okL, list = isolated(availableSkills)
		if okL and type(list) == "table" and table.concat(list, "|") ~= table.concat(skillList, "|") then
			skillList = list
			skillDrop.SetValues(list)
			refreshSkillNote(list)
		end
	end
end)

connect(RunService.Heartbeat, function()

	if Options.DefenseMode.Value == "Block (hold through combo)" and defenseOn() and not moving and not healing and not hoverConn then
		local root = getRoot()
		if root then
			for _, e in ipairs(getEnemies()) do
				local t = combo.aggro[e.model]
				if t and os.clock() - t < Options.BlockHold.Value and (e.root.Position - root.Position).Magnitude <= Options.ParryRange.Value then
					startBlock(0.3)
					break
				end
			end
		end
	end
	if blocking then
		if moving or hoverConn or os.clock() > blockUntil then
			stopBlock()
		elseif not blockActive() and os.clock() - lastBlockTry > 0.2 then
			lastBlockTry = os.clock()
			task.spawn(pcall, SkillCtl.Attempt_Hold, "Blocking", "F")
		end
	end
end)

do
	local STUN = {CombatStun = true, Stun = true, Strict_Stun = true, novelocity = true}
	local function watchValues()
		local v = RS:FindFirstChild("Player_Service") and RS.Player_Service:FindFirstChild("Values")
		v = v and v:WaitForChild(player.Name, 10)
		if not v then return end
		connect(v.ChildAdded, function(c)
			if STUN[c.Name] then
				if os.clock() - dbg.lastStunAt > 0.5 then dbg.stuns += 1 end
				dbg.lastStunAt = os.clock()
			end
			if STUN[c.Name] and Options.NoStun.Value then
				task.defer(function() pcall(function() c:Destroy() end) end)
			end
		end)
	end
	task.spawn(watchValues)
end

local function watchMyHealth(char)
	local hum = char:WaitForChild("Humanoid", 10)
	if not hum then return end
	local last = hum.Health
	connect(hum.HealthChanged, function(h)
		local dropped = h < last - 0.5
		if dropped and Options.Farm.Value then
			dbg.hits += 1
			local blk = blockActive()
			if blk then dbg.hitsBlocked += 1 end

			local b = dbg.hitBuf
			if not b then
				b = {dmg = 0, n = 0, blk = 0, max = hum.MaxHealth}
				dbg.hitBuf = b
				task.delay(1.2, function()
					dbg.hitBuf = nil
					vlog("hit", string.format("Took %d dmg (%d%%) from %d hit%s%s", math.floor(b.dmg + 0.5), math.floor(b.dmg / math.max(b.max, 1) * 100 + 0.5),
						b.n, b.n == 1 and "" or "s", b.blk > 0 and (", " .. b.blk .. " while blocking") or ""))
				end)
			end
			b.dmg += last - h
			b.n += 1
			if blk then b.blk += 1 end
		end
		last = h
		if not (dropped and defenseOn()) then return end
		local now = os.clock()
		local gap = now - combo.lastHitAt
		if gap > 0.15 and gap < 0.9 then combo.hitGap = combo.hitGap * 0.6 + gap * 0.4 end
		combo.lastHitAt = now
		local la = combo.lastAnim
		if la and now - la.t < 0.8 then
			local d = now - la.t
			local old = combo.hitDelay[la.id]
			combo.hitDelay[la.id] = old and (old * 0.5 + d * 0.5) or d
			combo.lastAnim = nil
		end
		local root = getRoot()
		if not root then return end
		local best, bestD
		for _, e in ipairs(getEnemies()) do
			local d = (e.root.Position - root.Position).Magnitude
			if d <= Options.ParryRange.Value and (not bestD or d < bestD) then best, bestD = e, d end
		end
		if best then
			combo.aggro[best.model] = os.clock()
			defend(best.root, "hit")
		end
	end)
end
if getChar() then task.spawn(watchMyHealth, getChar()) end
connect(player.CharacterAdded, function(c) task.spawn(watchMyHealth, c) end)

task.spawn(function()
	while alive do
		for _, e in ipairs(getEnemies()) do
			watchEnemy(e)
			if not dbg.watchedHum then dbg.watchedHum = setmetatable({}, {__mode = "k"}) end
			if not dbg.watchedHum[e.hum] then
				dbg.watchedHum[e.hum] = true
				local name = e.model.Name
				connect(e.hum.Died, function()
					if not Options.Farm.Value then return end
					dbg.kills += 1
					vlog("kill", name .. " killed  (#" .. dbg.kills .. ")")
				end)
			end
		end
		task.wait(1)
	end
end)

local statusNote = ""
local lastAttackAt, tempHover = os.clock(), false
local settleUntil = 0
local function onRelocate(reason)
	if dbg.shopBusy or not inRun() then return end
	moveToken += 1
	moving = false
	stopHover()
	setNoclip(false)
	blockInput(false)
	aimEnabled, aimTarget, hoverTarget, currentTarget = false, nil, nil, nil
	settleUntil = os.clock() + 3
	lastAttackAt = os.clock() + 3
	statusNote = "map changed — settling"
	dlog("move", "Map changed → " .. tostring(currentMap() or "?"))
end
connect(workspace:GetAttributeChangedSignal("MinigameMap"), function() onRelocate("map") end)
connect(workspace:GetAttributeChangedSignal("MinigameFloor"), function()
	local took = os.clock() - dbg.floorStart
	dbg.floorStart = os.clock()
	if floorNum() > 0 then
		dbg.floors += 1
		dlog("info", string.format("Floor %d  (last one took %d:%02d)", floorNum(), took // 60, math.floor(took % 60)))
	end
end)

local function restoreJoints(char)
	local rc = char and char:FindFirstChild("RagdollConstraints")
	if not rc then return end
	for _, c in ipairs(rc:GetChildren()) do
		if c:IsA("Constraint") then
			local rj = c:FindFirstChild("RigidJoint")
			if rj and rj.Value and c.Attachment1 then pcall(function() rj.Value.Part1 = c.Attachment1.Parent end) end
		end
	end
end
local function watchRagdoll(char)
	local hum = char:WaitForChild("Humanoid", 10)
	if not hum then return end
	connect(hum.StateChanged, function(_, new)
		if not (Options.Farm.Value and Options.AntiRagdoll.Value) then return end
		if new == Enum.HumanoidStateType.Physics or new == Enum.HumanoidStateType.FallingDown or new == Enum.HumanoidStateType.Ragdoll then
			restoreJoints(char)
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)
end
if getChar() then task.spawn(watchRagdoll, getChar()) end
connect(player.CharacterAdded, function(c) task.spawn(watchRagdoll, c) end)
pcall(function()
	local CS = game:GetService("CollectionService")
	connect(CS:GetInstanceAddedSignal("Ragdoll"), function(inst)
		local char = getChar()
		if char and inst:IsDescendantOf(char) and Options.Farm.Value and Options.AntiRagdoll.Value then
			task.defer(function()
				pcall(function() CS:RemoveTag(inst, "Ragdoll") end)
				restoreJoints(char)
				local hum = getHum()
				if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
			end)
		end
	end)
end)

local lastHeal, potionWarned = 0, false
local function potionAmount()
	local data = Utility and select(2, pcall(Utility.GetData, player))
	if typeof(data) ~= "Instance" then return nil end
	local slotNames = {"One", "Two", "Three", "Four", "Five"}
	local slot = data.Inventory.Toolbar:FindFirstChild(slotNames[Options.PotionSlot.Value])
	if not slot or slot.Value == 0 then return 0 end
	for _, it in ipairs(data.Inventory.Inventory:GetChildren()) do
		local id = it:FindFirstChild("Id")
		if (id and id.Value == slot.Value) or it.Name == tostring(slot.Value) then
			local amt = it:FindFirstChild("Amount")
			return amt and amt.Value or 1, it.Name
		end
	end
	return 0
end
local function drinkPotion()
	local cfg = player:FindFirstChild("Items_Config")
	local eq = cfg and cfg:FindFirstChild("Equipped")
	if not (eq and SignalEvent) then return false end
	eq.Value = Options.PotionSlot.Value
	task.wait(0.7)
	local root = getRoot()
	local pos = root and root.Position or Vector3.zero
	task.spawn(pcall, SignalEvent.ToServer, "Tool_Mouse", "Down", pos)
	task.wait(2.6)
	task.spawn(pcall, SignalEvent.ToServer, "Tool_Mouse", "Up", pos)
	task.wait(0.6)
	eq.Value = Options.WeaponSlot.Value
	return true
end
local function healRoutine()
	healing = true
	lastHeal = os.clock()
	stopHover()
	setNoclip(false)
	blockInput(false)
	aimEnabled, hoverTarget = false, nil
	local amount = potionAmount()
	if amount == 0 and Options.RefillPotion.Value then

		local data = Utility and select(2, pcall(Utility.GetData, player))
		if typeof(data) == "Instance" then
			for _, want in ipairs({"Health Regen Elixir", "Health Elixir", "Health Regen Potion", "Health Potion"}) do
				local it = data.Inventory.Inventory:FindFirstChild(want)
				local amt, id = it and it:FindFirstChild("Amount"), it and it:FindFirstChild("Id")
				if amt and id and amt.Value > 0 then
					local slotName = ({"One", "Two", "Three", "Four", "Five"})[Options.PotionSlot.Value]
					pcall(SignalEvent.ToServer, "Toolbar_Equip", slotName, id.Value)
					task.wait(1.5)
					dlog("heal", "Slot was empty → put " .. want .. " (" .. amt.Value .. ") in it")
					amount = potionAmount()
					break
				end
			end
		end
	end
	if amount == 0 then

		if not dbg.noPotions then
			dlog("warn", Options.NoPotions.Value == "Play safe (high spot)" and "Out of potions — staying on the safe spot while HP is low"
				or "Out of potions — fighting on without healing")
		end
		dbg.noPotions = true
		if not potionWarned then
			potionWarned = true
			notify("warn", "No potion", "Put a health potion in toolbar slot " .. Options.PotionSlot.Value .. ".")
		end
		healing = false
		return
	end
	dbg.noPotions = nil
	statusNote = "low HP — going to heal"
	local spot = spotFor(currentMap())

	local pin
	if Options.HealAtSpot.Value and spot then
		for try = 1, 3 do
			goTo(spot)
			local root = getRoot()
			if root and (root.Position - spot).Magnitude < 6 then break end
			dlog("warn", "Didn't reach the heal spot (try " .. try .. ") — flying again")
		end
		local root = getRoot()
		if root and (root.Position - spot).Magnitude < 8 then
			local hold = CFrame.new(spot + Vector3.new(0, 1.2, 0)) * (root.CFrame - root.Position)
			if dbg.healPin then dbg.healPin:Disconnect() end
			pin = RunService.Heartbeat:Connect(function()
				local r = getRoot()
				if not r then return end
				r.AssemblyLinearVelocity = Vector3.zero
				if (r.Position - hold.Position).Magnitude > 0.5 then r.CFrame = hold end
			end)
			dbg.healPin = pin
		else
			dlog("warn", "Heal spot unreachable — drinking where I am")
		end
	end
	statusNote = "drinking potion"
	dlog("heal", "Drinking potion (" .. tostring(amount) .. " left)")
	dbg.heals += 1
	pcall(drinkPotion)
	local t = os.clock()
	while alive and Options.Farm.Value and os.clock() - t < Options.HealMaxWait.Value do
		local hum = getHum()
		if not hum or hum.Health <= 0 then break end
		if hum.Health / hum.MaxHealth * 100 >= Options.HealUntil.Value then break end
		statusNote = string.format("healing %d%%", hum.Health / hum.MaxHealth * 100)
		task.wait(0.3)
	end
	if pin then pin:Disconnect() end
	healing = false
end

local hoverPhase, restUntil, lastHp = "attack", 0, nil

task.spawn(function()
	local lastPos, wasFarming
	while alive do

		local okStep, errStep = pcall(function()
			if Options.Farm.Value ~= wasFarming then
				wasFarming = Options.Farm.Value
				lastAttackAt, tempHover = os.clock(), false
			end
			local fighting = Options.Farm.Value and inRun()
			if not fighting and tempHover then tempHover = false lastAttackAt = os.clock() end
			local root, hum = getRoot(), getHum()
			if root then
				if lastPos and (root.Position - lastPos).Magnitude > 150 and not hoverConn then onRelocate("teleport") end
				lastPos = root.Position
			end
			if fighting and os.clock() < settleUntil then

			elseif fighting and root and hum and hum.Health > 0 and Options.AutoHeal.Value and not healing
				and hum.Health / hum.MaxHealth * 100 < Options.HealAt.Value
				and os.clock() - lastHeal > ((dbg.noPotions and Options.NoPotions.Value == "Keep fighting (no heal)") and 60 or 10) then
				healRoutine()
			elseif fighting and root and hum and hum.Health > 0 then
				local spot = spotFor(currentMap())
				local mobs = #getEnemies()
				if mobs == 0 then lastAttackAt = os.clock() end

				if (Options.FarmMode.Value == "Skills from a high spot" or dbg.noPotions) and not tempHover
					and mobs > 0 and os.clock() - lastAttackAt > 300 then
					tempHover = true
					hoverPhase = "attack"
					notify("info", "Stuck", "No mob in sight for 5 min — finishing them with M1.")
					dlog("warn", "No clear shot for 5 min → M1 clean-up")
				end
				if tempHover and mobs == 0 then
					tempHover = false
					lastAttackAt = os.clock()
					stopHover() setNoclip(false) blockInput(false)
					hoverTarget = nil
					notify("success", "Cleared", "Back to the spot.")
				end
				local lowNoPots = dbg.noPotions and Options.NoPotions.Value == "Play safe (high spot)" and hum.Health / hum.MaxHealth * 100 < Options.HealAt.Value

				local allIn = dbg.noPotions and Options.NoPotions.Value == "Keep fighting (no heal)"
				if (Options.FarmMode.Value == "Hover above mobs + M1" and not lowNoPots) or tempHover or allIn then
					if hoverPhase == "rest" then
						if os.clock() >= restUntil then
							local near = pickTarget(40, true)
							if near then
								local away = root.Position - near.root.Position
								away = Vector3.new(away.X, 0, away.Z)
								if away.Magnitude > 0.1 then dashToward(away.Unit, true) end
							end
							hoverPhase = "attack"
						end
						statusNote = string.format("resting %.1fs", math.max(0, restUntil - os.clock()))
					else
						local t = hoverTarget
						if not (t and t.root.Parent and t.hum.Health > 0) then t = pickTarget(1000, true) end
						if t then

							if hoverTarget and hoverTarget ~= t and hoverTarget.hum.Health <= 0 and Options.HoverBreaks.Value then
								hoverTarget = nil
								stopHover() setNoclip(false) blockInput(false)
								hoverPhase, restUntil = "rest", os.clock() + 2 + math.random()
							else
								currentTarget, hoverTarget = t, t
								aimTarget, aimEnabled = targetPos(t), true
								startHover()
								if (t.root.Position - root.Position).Magnitude < Options.HoverHeight.Value + 6 then doPunch() end
								if Options.HoverSkills.Value and not casting then task.spawn(castNextSkill) end

								if lastHp and Options.HoverBreaks.Value and lastHp - hum.Health > hum.MaxHealth * 0.12 then
									hoverTarget = nil
									stopHover() setNoclip(false) blockInput(false)
									hoverPhase, restUntil = "rest", os.clock() + 2 + math.random()
								end
								statusNote = (tempHover and "stuck-clear · " or "hovering · ") .. t.model.Name
							end
						else
							hoverTarget = nil
							aimEnabled = false
							if hoverConn then stopHover() setNoclip(false) blockInput(false) end
							if spot and not moving and (root.Position - spot).Magnitude > Options.HoldRadius.Value then goTo(spot) end
							statusNote = "waiting for mobs"
						end
					end
				else
					if hoverConn then stopHover() setNoclip(false) blockInput(false) end
					if spot and not moving and not casting and (root.Position - spot).Magnitude > Options.HoldRadius.Value then
						aimEnabled = false
						statusNote = "moving to spot"
						goTo(spot)
					end
					if not moving and not casting then
						local t = pickTarget(Options.AttackRange.Value)
						currentTarget = t
						if t then
							lastAttackAt = os.clock()
							aimTarget, aimEnabled = targetPos(t), true
							statusNote = "attacking · " .. t.model.Name
							isolated(castNextSkill)
						else
							aimEnabled = false
							statusNote = blockedCount > 0 and ("no clear shot (" .. blockedCount .. " behind walls)") or "waiting for mobs"
						end
					end
				end
				lastHp = hum.Health
			else
				aimEnabled = false
				if hoverConn then stopMoving() end
			end
			task.wait(fighting and 0.08 or 0.3)
		end)
		if not okStep then
			healing, casting, moving = false, false, false
			if dbg.healPin then dbg.healPin:Disconnect() dbg.healPin = nil end
			dlog("warn", "Farm step error (recovered): " .. tostring(errStep):sub(1, 120))
			task.wait(1)
		end
	end
end)

dlog("info", APP_NAME .. " loaded — " .. (inRun() and ("floor " .. floorNum() .. ", " .. tostring(currentMap())) or "in the lobby"))
do
do
	local frames, fpsAt = 0, os.clock()
	connect(RunService.RenderStepped, function()
		frames += 1
		if os.clock() - fpsAt >= 1 then dbg.fps, frames, fpsAt = frames / (os.clock() - fpsAt), 0, os.clock() end
	end)
end
local U = {}
function U.C(hex, text) return '<font color="' .. hex .. '">' .. text .. '</font>' end
function U.K(text) return U.C("#7c8070", text) end
function U.mmss(sec) sec = math.max(0, math.floor(sec)) return string.format("%d:%02d", sec // 60, sec % 60) end
function U.pctColor(p) return p >= 60 and "#6ee39a" or p >= 30 and "#ffd75c" or "#ff7a6e" end
function U.phaseText()
	if not Options.Farm.Value then return U.C("#7c8070", "Idle") end
	if not inRun() then return U.C("#c8ccbc", "Lobby") end
	if os.clock() < settleUntil then return U.C("#6fb7ff", "Settling (map load)") end
	if healing then return U.C("#6ee39a", "Healing") end
	if moving then return U.C("#6fb7ff", "Moving") end
	if tempHover then return U.C("#ff7a6e", "Stuck-clear (M1)") end
	if hoverConn then return U.C("#ffb35c", "Hovering") end
	if hoverPhase == "rest" then return U.C("#c8ccbc", "Resting") end
	if casting then return U.C("#ffb35c", "Casting") end
	return U.C("#c8ccbc", "On spot")
end
function U.snapshot()
	local lines = {"state: " .. (dbgUI.badge.Text:gsub("<[^>]+>", "")) .. " — " .. tostring(statusNote)}
	for _, kv in ipairs(dbgUI.order) do
		table.insert(lines, kv[2]:lower() .. ": " .. (dbgUI.v[kv[1]].Text:gsub("<[^>]+>", "")))
	end
	for name, st in pairs(dbg.skillStats) do
		table.insert(lines, string.format("skill %s: %d casts, avg %d dmg, %d did nothing, %d blocked", name, st.n, math.floor(st.dmg / math.max(st.n, 1)), st.zero, st.blocked))
	end
	table.insert(lines, "--- log ---")
	for _, e in ipairs(dbg.history) do table.insert(lines, e.t .. " [" .. e.kind .. "] " .. tostring(e.text)) end
	return table.concat(lines, "\n")
end
app.Debug_snapshot = U.snapshot
connect(dbgUI.btns.Copy.MouseButton1Click, function()
	local cb = setclipboard or toclipboard or (env.Clipboard and env.Clipboard.set)
	if cb and pcall(cb, U.snapshot()) then notify("success", "Copied", "Debug info is in your clipboard.") else notify("warn", "Copy", "Clipboard isn't supported here — see AxiomHUB/log.txt") end
end)
connect(dbgUI.btns.Clear.MouseButton1Click, function()
	for _, c in ipairs(logScroll:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
end)

function U.skillChip(name, order)
	local f = make("Frame", {Parent = dbgUI.skillGrid, LayoutOrder = order, BackgroundColor3 = T.Bg, BackgroundTransparency = 0.35}, {corner(7)})
	local st = stroke(T.Stroke, 0.75); st.Parent = f
	local dot = make("Frame", {Parent = f, Position = UDim2.fromOffset(9, 11), Size = UDim2.fromOffset(7, 7), BackgroundColor3 = T.SubText}, {corner(4)})
	local n = label({Parent = f, Position = UDim2.fromOffset(22, 6), Size = UDim2.new(1, -28, 0, 16), Text = name, Font = FONT_B, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd})
	local a1 = label({Parent = f, Position = UDim2.fromOffset(22, 23), Size = UDim2.new(1, -28, 0, 14), Text = "", RichText = true, Font = FONT, TextSize = 11, TextColor3 = T.SubText, TextTruncate = Enum.TextTruncate.AtEnd})
	local a2 = label({Parent = f, Position = UDim2.fromOffset(22, 38), Size = UDim2.new(1, -28, 0, 14), Text = "", RichText = true, Font = FONT, TextSize = 10, TextColor3 = T.SubText, TextTruncate = Enum.TextTruncate.AtEnd})
	return {f = f, st = st, dot = dot, n = n, a1 = a1, a2 = a2}
end
task.spawn(function()
	local lastNote = ""
	local skillAt = 0
	while alive do
		local farming = Options.Farm.Value
		local where = inRun() and string.format("Floor <b>%d</b>  ·  %s", floorNum(), tostring(currentMap() or "?")) or "Lobby"
		local dot = farming and '<font color="#6ee39a">●</font>' or '<font color="#7c8070">●</font>'
		status.Text = dot .. "  " .. (farming and "Farming" or "Idle") .. "   " .. where
		tween(logDot, {BackgroundColor3 = farming and Color3.fromRGB(110, 227, 154) or T.Accent}, 0.3)
		local root, hum = getRoot(), getHum()
		local enemies = getEnemies()
		local V = dbgUI.v

		dbgUI.badge.Text = U.phaseText()
		dbgUI.note.Text = farming and (statusNote ~= "" and statusNote or "…") or "Farm is off — turn it on in the Farm tab"
		V.floor.Text = inRun() and tostring(floorNum()) or "Lobby"
		V.map.Text = (tostring(currentMap() or "-"):gsub(" Dungeon$", ""))
		V.ftime.Text = inRun() and U.mmss(os.clock() - dbg.floorStart) or "-"
		V.mode.Text = Options.FarmMode.Value:find("Hover") and "Hover + M1" or "High spot"

		local t = currentTarget
		if t and t.root and t.root.Parent and t.hum and t.hum.Health > 0 then
			local thp = t.hum.Health / math.max(t.hum.MaxHealth, 1) * 100
			V.target.Text = U.C(U.pctColor(thp), string.format("%d%%", math.floor(thp))) .. " " .. t.model.Name
		else
			V.target.Text = U.C("#7c8070", "none")
		end
		V.mobs.Text = #enemies .. (blockedCount > 0 and U.C("#ffd75c", "  (" .. blockedCount .. " hidden)") or "")
		V.shot.Text = farming and (U.mmss(os.clock() - lastAttackAt) .. " ago") or "-"

		local hp = hum and hum.Health / math.max(hum.MaxHealth, 1) * 100 or 0
		local okP, pots = isolated(potionAmount)
		local okB, blkUp = isolated(blockActive)
		local ping = math.floor((select(2, pcall(function() return player:GetNetworkPing() end)) or 0) * 1000)
		V.hp.Text = U.C(U.pctColor(hp), string.format("%d%%", math.floor(hp)))
		V.pots.Text = not okP and "?" or (pots == 0 and U.C("#ff7a6e", "0 — empty") or tostring(pots))
		V.block.Text = (okB and blkUp and U.C("#6ee39a", "UP") or U.C("#7c8070", "down"))
			.. (os.clock() - dbg.lastStunAt < 0.5 and U.C("#ff7a6e", "  · stunned") or "")
		V.ping.Text = U.C(ping < 150 and "#6ee39a" or ping < 300 and "#ffd75c" or "#ff7a6e", ping .. " ms")
		V.fps.Text = tostring(math.floor(dbg.fps))

		if os.clock() - skillAt > 0.6 then
			skillAt = os.clock()
			local sel, names = Options.UseSkills.Value, {}
			for _, name in ipairs(skillList or {}) do
				if type(sel) == "table" and sel[name] then table.insert(names, name) end
			end
			local key = table.concat(names, "|")
			if key ~= dbgUI.skillKey then
				dbgUI.skillKey = key
				for _, c in pairs(dbgUI.skillChips) do c.f:Destroy() end
				dbgUI.skillChips = {}
				for i, name in ipairs(names) do dbgUI.skillChips[name] = U.skillChip(name, i) end
				local rows = math.max(1, math.ceil(#names / 2))
				dbgUI.skillCard.Size = UDim2.new(1, 0, 0, 38 + rows * 58 + (rows - 1) * 6 + 12)
			end
			for _, name in ipairs(names) do
				local c = dbgUI.skillChips[name]
				local okR, ready = isolated(skillReady, skillTimes(name))
				local on = okR and ready
				tween(c.dot, {BackgroundColor3 = on and Color3.fromRGB(110, 227, 154) or T.SubText}, 0.2)
				c.n.TextColor3 = on and T.Text or T.SubText
				local st = dbg.skillStats[name]
				if st and st.n > 0 then
					c.a1.Text = string.format("<b>%d</b> avg dmg · %d×", math.floor(st.dmg / st.n + 0.5), st.n)
					c.a2.Text = (st.zero > 0 and U.C("#ff9d8a", st.zero .. " missed") or "no misses") .. (st.blocked > 0 and ("  · " .. st.blocked .. " blocked") or "")
				else
					c.a1.Text = on and "ready" or "cooling down"
					c.a2.Text = "not used yet"
				end
			end
			dbgUI.skillLast.Text = dbg.lastSkillAt > 0 and ("last: <b>" .. dbg.lastSkill .. "</b> · " .. U.mmss(os.clock() - dbg.lastSkillAt) .. " ago") or ""
		end

		V.time.Text = sessionTime()
		V.kills.Text = tostring(dbg.kills)
		V.floors.Text = tostring(dbg.floors)
		V.casts.Text = tostring(dbg.casts)
		V.refused.Text = tostring(dbg.fails)
		V.cards.Text = tostring(session.picks)
		V.hits.Text = tostring(dbg.hits)
		V.blocked.Text = tostring(dbg.hitsBlocked)
		V.stuns.Text = tostring(dbg.stuns)
		V.heals.Text = tostring(dbg.heals)
		V.deaths.Text = session.deaths > 0 and U.C("#ff7a6e", tostring(session.deaths)) or "0"
		V.blocks.Text = tostring(dbg.blocks)
		if farming and statusNote ~= "" and statusNote ~= lastNote then
			lastNote = statusNote
			local kind = statusNote:find("moving") and "move" or statusNote:find("heal") and "heal" or statusNote:find("drink") and "heal" or "info"
			local skip = statusNote:find("^resting") or statusNote == "drinking potion" or statusNote:find("^healing %d") or statusNote:find("^attacking")
				or statusNote:find("^hovering") or statusNote:find("^stuck%-clear")
			if not skip then dlog(kind, statusNote) end
		end
		while #logQueue > 0 do drawLog(table.remove(logQueue, 1)) end
		task.wait(0.3)
	end
end)

end
app.dbg = dbg
app.Options = Options
app.Debug = {cast = castSkill, castNext = castNextSkill, enemies = getEnemies, pick = pickTarget, goTo = goTo, punch = doPunch, defend = defend, stats = function() return {defense = defenseCount, phase = hoverPhase, note = statusNote, dbg = dbg} end, snapshot = app.Debug_snapshot}
selectTab(tabs[1])

main.Visible = false
if floatButton then floatButton.Visible = false end
task.spawn(function()
	local Lighting = game:GetService("Lighting")
	local blur = Instance.new("BlurEffect")
	blur.Size = 0
	blur.Parent = Lighting
	local dim = make("Frame", {Parent = gui, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, ZIndex = 29})
	local card = make("Frame", {Parent = gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(640, 360),
		BackgroundColor3 = Color3.fromRGB(18, 19, 16), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 30}, {corner(16)})
	local cScale = make("UIScale", {Parent = card, Scale = 0.9})
	local cStroke = make("UIStroke", {Parent = card, Thickness = 1.5, Transparency = 1})
	accent(cStroke, "Color")
	local fades = {}
	local function fx(o, prop, shown) table.insert(fades, {o, prop, shown}) return o end

	local lattice = make("Frame", {Parent = card, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromScale(0.62, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 30}, {
		make("UIGradient", {Transparency = NumberSequence.new(1, 0)}),
	})
	for i = -3, 12 do
		for _, rot in ipairs({35, -35}) do
			fx(accent(make("Frame", {Parent = lattice, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, i * 40, 0.5, 0), Size = UDim2.fromOffset(1, 520),
				Rotation = rot, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 30}), "BackgroundColor3"), "BackgroundTransparency", 0.9)
		end
	end

	for _, c in ipairs({{0, 0}, {1, 0}, {0, 1}, {1, 1}}) do
		local ax, ay = c[1], c[2]
		local sx, sy = ax == 0 and 1 or -1, ay == 0 and 1 or -1
		fx(accent(make("Frame", {Parent = card, AnchorPoint = Vector2.new(ax, ay), Position = UDim2.new(ax, sx * 16, ay, sy * 16), Size = UDim2.fromOffset(24, 2), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 31}), "BackgroundColor3"), "BackgroundTransparency", 0.1)
		fx(accent(make("Frame", {Parent = card, AnchorPoint = Vector2.new(ax, ay), Position = UDim2.new(ax, sx * 16, ay, sy * 16), Size = UDim2.fromOffset(2, 24), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 31}), "BackgroundColor3"), "BackgroundTransparency", 0.1)
		fx(accent(make("Frame", {Parent = card, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(ax, sx * 46, ay, sy * 17), Size = UDim2.fromOffset(5, 5), Rotation = 45, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 31}), "BackgroundColor3"), "BackgroundTransparency", 0)
	end

	local markBox = make("Frame", {Parent = card, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.47), Size = UDim2.fromOffset(150, 150), BackgroundTransparency = 1, ZIndex = 31})
	local mk = app.drawMark(markBox, 150, 32)
	mk.scale.Scale = 0.3
	mk.outerStroke.Transparency, mk.innerStroke.Transparency = 1, 1
	for _, f in ipairs(mk.fills) do f.BackgroundTransparency = 1 end
	local pulse = make("Frame", {Parent = markBox, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(60, 60), Rotation = 45, BackgroundTransparency = 1, ZIndex = 31})
	local pulseStroke = make("UIStroke", {Parent = pulse, Thickness = 2, Transparency = 1})
	accent(pulseStroke, "Color")

	local textBox = make("Frame", {Parent = card, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 262, 0.47, 0), Size = UDim2.fromOffset(340, 110), BackgroundTransparency = 1, ZIndex = 31})
	local title = label({Parent = textBox, Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 58), Text = "", RichText = true, Font = FONT_B, TextSize = 54, ZIndex = 32})
	local line = make("Frame", {Parent = textBox, Position = UDim2.fromOffset(2, 80), Size = UDim2.fromOffset(0, 2), BorderSizePixel = 0, ZIndex = 32})
	accent(line, "BackgroundColor3")
	local tag = label({Parent = textBox, Position = UDim2.fromOffset(52, 72), Size = UDim2.new(1, -52, 0, 18), Text = "", Font = Enum.Font.Code, TextSize = 13, TextColor3 = Color3.fromRGB(169, 173, 156), ZIndex = 32})

	local bar = make("Frame", {Parent = card, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -34), Size = UDim2.fromOffset(220, 3), BackgroundColor3 = T.Off, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 31}, {corner(2)})
	local fill = make("Frame", {Parent = bar, Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, ZIndex = 32}, {corner(2)})
	accent(fill, "BackgroundColor3")
	local step = label({Parent = card, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.fromOffset(300, 14), Text = "", Font = FONT, TextSize = 11, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 31})
	local spin = game:GetService("RunService").RenderStepped:Connect(function(dt)
		mk.outer.Rotation = (mk.outer.Rotation + dt * 40) % 360
		mk.inner.Rotation = (mk.inner.Rotation - dt * 28) % 360
	end)

	tween(blur, {Size = 14}, 0.5)
	tween(dim, {BackgroundTransparency = 0.45}, 0.5)
	tween(card, {BackgroundTransparency = 0.02}, 0.4)
	tween(cStroke, {Transparency = 0.55}, 0.5)
	tween(cScale, {Scale = 1}, 0.6, Enum.EasingStyle.Back)
	for _, f in ipairs(fades) do tween(f[1], {[f[2]] = f[3]}, 0.8) end

	task.wait(0.25)
	tween(mk.scale, {Scale = 1}, 0.6, Enum.EasingStyle.Back)
	tween(mk.outerStroke, {Transparency = 0.45}, 0.5)
	tween(mk.innerStroke, {Transparency = 0.8}, 0.6)
	task.wait(0.2)
	tween(mk.legL, {BackgroundTransparency = 0}, 0.35)
	tween(mk.legR, {BackgroundTransparency = 0}, 0.35)
	task.wait(0.3)
	tween(mk.bar, {BackgroundTransparency = 0}, 0.3)
	local hubSize = mk.hub.Size
	mk.hub.Size = UDim2.fromOffset(0, 0)
	tween(mk.hub, {BackgroundTransparency = 0, Size = hubSize}, 0.4, Enum.EasingStyle.Back)
	tween(mk.apex, {BackgroundTransparency = 0}, 0.3)
	pulseStroke.Transparency = 0.2
	tween(pulse, {Size = UDim2.fromOffset(230, 230)}, 0.8, Enum.EasingStyle.Quad)
	tween(pulseStroke, {Transparency = 1, Thickness = 0.5}, 0.8, Enum.EasingStyle.Quad)
	task.wait(0.55)

	tween(markBox, {Position = UDim2.new(0, 160, 0.47, 0)}, 0.55, Enum.EasingStyle.Quint)
	task.wait(0.4)
	local hubHex = string.format("#%02X%02X%02X", T.Accent.R * 255, T.Accent.G * 255, T.Accent.B * 255)
	for i = 1, #APP_NAME do
		local t = APP_NAME:sub(1, i)
		title.Text = #t > 5 and (t:sub(1, 5) .. '<font color="' .. hubHex .. '">' .. t:sub(6) .. "</font>") or t
		task.wait(0.05)
	end
	tween(line, {Size = UDim2.fromOffset(40, 2)}, 0.3)
	local tagline = "SCRIPT HUB  ·  BY " .. string.upper(AUTHOR)
	for i = 1, #tagline do
		tag.Text = tagline:sub(1, i)
		task.wait(0.018)
	end
	tween(bar, {BackgroundTransparency = 0.3}, 0.3)
	for i, txt in ipairs({"Hooking silent aim…", "Loading cards & spots…", "Reading your profile…", "Ready"}) do
		step.Text = txt
		tween(fill, {Size = UDim2.fromScale(i / #{"Hooking silent aim…", "Loading cards & spots…", "Reading your profile…", "Ready"}, 1)}, 0.28)
		task.wait(0.3)
	end
	task.wait(0.35)

	tween(cScale, {Scale = 1.06}, 0.35)
	for _, o in ipairs(card:GetDescendants()) do
		if o:IsA("TextLabel") then tween(o, {TextTransparency = 1}, 0.3)
		elseif o:IsA("Frame") then tween(o, {BackgroundTransparency = 1}, 0.3)
		elseif o:IsA("UIStroke") then tween(o, {Transparency = 1}, 0.3) end
	end
	tween(card, {BackgroundTransparency = 1}, 0.35)
	tween(cStroke, {Transparency = 1}, 0.3)
	tween(dim, {BackgroundTransparency = 1}, 0.45)
	tween(blur, {Size = 0}, 0.45)
	task.wait(0.15)
	main.Visible = true
	mainScale.Scale = 0.85
	tween(mainScale, {Scale = 1}, 0.45, Enum.EasingStyle.Back)
	playIntro()
	if floatButton then floatButton.Visible = Options.ShowFloatButton.Value end
	task.wait(0.35)
	spin:Disconnect()
	card:Destroy()
	dim:Destroy()
	blur:Destroy()
end)
notify("success", APP_NAME .. " · Ouwigahara", "Welcome, " .. player.DisplayName .. ". Press End to toggle.")

end
runHub()

end

local function AxiomMM2()
do
	local genv = getgenv and getgenv() or _G
	if genv.__AxiomAntiAFK then pcall(function() genv.__AxiomAntiAFK:Disconnect() end) end
	local VirtualUser = game:GetService("VirtualUser")
	genv.__AxiomAntiAFK = game:GetService("Players").LocalPlayer.Idled:Connect(function()
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end)
end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local env = getgenv and getgenv() or _G

local APP_NAME, AUTHOR = "AxiomHUB", "kingping77"

if env.__AxiomMM2 then pcall(env.__AxiomMM2.Destroy) env.__AxiomMM2 = nil end
local app = {connections = {}}
env.__AxiomMM2 = app
local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(app.connections, c)
	return c
end

local T = {
	Accent = Color3.fromRGB(142, 154, 78),
	Bg = Color3.fromRGB(17, 18, 15),
	Surface = Color3.fromRGB(26, 28, 22),
	Element = Color3.fromRGB(33, 35, 28),
	Hover = Color3.fromRGB(43, 46, 36),
	Off = Color3.fromRGB(60, 63, 52),
	Text = Color3.fromRGB(234, 236, 226),
	SubText = Color3.fromRGB(156, 160, 144),
	Stroke = Color3.fromRGB(68, 72, 57),
	Warn = Color3.fromRGB(232, 182, 72),
	Error = Color3.fromRGB(232, 92, 92),
	Good = Color3.fromRGB(110, 200, 120),
}
local FONT, FONT_M, FONT_B = Enum.Font.Gotham, Enum.Font.GothamMedium, Enum.Font.GothamBold
local MB1, TOUCH, MOVE = Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch, Enum.UserInputType.MouseMovement

local function tween(obj, props, t, style)
	local tw = TweenService:Create(obj, TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function make(class, props, children)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then o[k] = v end
	end
	for _, c in ipairs(children or {}) do c.Parent = o end
	if props and props.Parent then o.Parent = props.Parent end
	return o
end
local function corner(r) return make("UICorner", {CornerRadius = UDim.new(0, r or 8)}) end
local function stroke(color, tr)
	return make("UIStroke", {Color = color or T.Stroke, Transparency = tr or 0.6, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
end
local function label(props)
	local base = {BackgroundTransparency = 1, Font = FONT_M, TextSize = 13, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left}
	for k, v in pairs(props) do base[k] = v end
	return make("TextLabel", base)
end

local function fromHex(h)
	h = tostring(h):gsub("#", ""):gsub("%s", "")
	if #h ~= 6 then return nil end
	local r, g, b = tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16)
	if not (r and g and b) then return nil end
	return Color3.fromRGB(r, g, b)
end

local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end

local function makeDraggable(handle, target)
	local dragging, startInput, startPos
	connect(handle.InputBegan, function(i)
		if i.UserInputType == MB1 or i.UserInputType == TOUCH then
			dragging, startInput, startPos = true, i.Position, target.Position
		end
	end)
	connect(UIS.InputChanged, function(i)
		if dragging and (i.UserInputType == MOVE or i.UserInputType == TOUCH) then
			local d = i.Position - startInput
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	connect(UIS.InputEnded, function(i)
		if i.UserInputType == MB1 or i.UserInputType == TOUCH then dragging = false end
	end)
end

local accentBound = {}
local function accent(obj, prop)
	table.insert(accentBound, {obj, prop})
	obj[prop] = T.Accent
	return obj
end

function app.drawMark(parent, size, z)
	local k = size / 200
	local holder = make("Frame", {Parent = parent, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, ZIndex = z})
	local m = {holder = holder, scale = make("UIScale", {Parent = holder})}
	local function box(cx, cy, w, h, rot, color, zz)
		local f = make("Frame", {Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx * k, cy * k), Size = UDim2.fromOffset(math.max(1, w * k), math.max(1, h * k)),
			Rotation = rot, BackgroundColor3 = color or T.Accent, BorderSizePixel = 0, ZIndex = z + (zz or 1)})
		if not color then accent(f, "BackgroundColor3") end
		return f
	end
	local function ring(side, thick, tr)
		local f = make("Frame", {Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(100 * k, 100 * k), Size = UDim2.fromOffset(side * k, side * k), Rotation = 45, BackgroundTransparency = 1, ZIndex = z})
		local st = make("UIStroke", {Parent = f, Thickness = math.max(1, thick * k), Transparency = tr})
		accent(st, "Color")
		return f, st
	end
	local ink = Color3.fromRGB(237, 238, 230)
	m.outer, m.outerStroke = ring(133, 3, 0.45)
	m.inner, m.innerStroke = ring(110, 1.5, 0.8)
	m.legL = box(79.5, 95, 21, 120, 20.4, ink)
	m.legR = box(120.5, 95, 21, 120, -20.4, ink)
	m.bar = box(100, 122, 48, 5, 0, nil, 2)
	m.hub = box(100, 122, 18, 18, 45, nil, 3)
	m.apex = box(100, 6, 8, 8, 45, nil, 3)
	m.fills = {m.legL, m.legR, m.bar, m.hub, m.apex}
	return m
end

local Options = {}
local CONFIG_DIR = "AxiomHUB"
local PROFILE_DIR = CONFIG_DIR .. "/configs"
local LAST_FILE = CONFIG_DIR .. "/mm2.json"
local saveQueued, loading = false, true
local canFiles = writefile and readfile and isfile and isfolder and makefolder and true or false

local function ensureDirs()
	if not canFiles then return false end
	pcall(function()
		if not isfolder(CONFIG_DIR) then makefolder(CONFIG_DIR) end
		if not isfolder(PROFILE_DIR) then makefolder(PROFILE_DIR) end
	end)
	return true
end

local function collect()
	local data = {}
	for flag, o in pairs(Options) do
		if not o.NoSave then data[flag] = o.Value end
	end
	return data
end

local function saveConfig()
	if loading or saveQueued or not canFiles then return end
	saveQueued = true
	task.delay(1, function()
		saveQueued = false
		ensureDirs()
		pcall(writefile, LAST_FILE, HttpService:JSONEncode(collect()))
	end)
end

local function register(flag, value, apply)
	local o = {Value = value}
	function o:SetValue(v, silent)
		o.Value = v
		apply(v)
		if o.Callback and not silent then task.spawn(o.Callback, v) end
		saveConfig()
	end
	o.Refresh = function() apply(o.Value) end
	Options[flag] = o
	return o
end

local function applyData(data)
	loading = true
	for flag, v in pairs(data) do
		local o = Options[flag]
		if o and not o.NoSave then pcall(o.SetValue, o, v, true) end
	end
	loading = false
	saveConfig()
end

local function setAccent(c)
	T.Accent = c
	for _, b in ipairs(accentBound) do
		if b[1].Parent then tween(b[1], {[b[2]] = c}, 0.35) end
	end
	for _, o in pairs(Options) do
		if not o.NoRefresh then o.Refresh() end
	end
end

local gui = make("ScreenGui", {Name = "AxiomHUB_MM2", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true, DisplayOrder = 50})
pcall(function()
	for _, c in ipairs(((gethui and gethui()) or game:GetService("CoreGui")):GetChildren()) do
		if c.Name == "AxiomHUB_MM2" then c:Destroy() end
	end
end)
if not pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end) or not gui.Parent then
	gui.Parent = player:WaitForChild("PlayerGui")
end

local main = make("Frame", {
	Parent = gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(640, 470), BackgroundColor3 = T.Bg, BackgroundTransparency = 0.08, BorderSizePixel = 0,
}, {corner(12)})
accent(make("UIStroke", {Parent = main, Transparency = 0.65, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}), "Color")
local mainScale = make("UIScale", {Parent = main, Scale = 0.94})

local top = make("Frame", {Parent = main, Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1})
app.drawMark(make("Frame", {Parent = top, Position = UDim2.fromOffset(6, 7), Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1}), 28, 2)
label({Parent = top, Position = UDim2.fromOffset(42, 8), Size = UDim2.fromOffset(200, 18), Text = APP_NAME, Font = FONT_B, TextSize = 15})
label({Parent = top, Position = UDim2.fromOffset(42, 25), Size = UDim2.fromOffset(200, 14), Text = "Murder Mystery 2", Font = FONT, TextSize = 11, TextColor3 = T.SubText})
local status = label({
	Parent = top, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -80, 0, 0), Size = UDim2.new(0, 300, 1, 0),
	Text = "", RichText = true, Font = FONT, TextSize = 12, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Right,
})
make("Frame", {Parent = main, Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.Stroke, BackgroundTransparency = 0.5, BorderSizePixel = 0})

local function topButton(parent, text, x, onClick)
	local b = make("TextButton", {
		Parent = parent, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, x, 0.5, 0), Size = UDim2.fromOffset(26, 26),
		BackgroundColor3 = T.Hover, BackgroundTransparency = 1, AutoButtonColor = false,
		Text = text, Font = FONT_B, TextSize = 14, TextColor3 = T.SubText, ZIndex = 3,
	}, {corner(7)})
	connect(b.MouseEnter, function() tween(b, {BackgroundTransparency = 0.2, TextColor3 = T.Text}) end)
	connect(b.MouseLeave, function() tween(b, {BackgroundTransparency = 1, TextColor3 = T.SubText}) end)
	connect(b.MouseButton1Click, onClick)
	return b
end

makeDraggable(top, main)

local sidebar = make("Frame", {Parent = main, Position = UDim2.fromOffset(10, 56), Size = UDim2.new(0, 140, 1, -66), BackgroundColor3 = T.Surface, BackgroundTransparency = 0.3}, {corner(10)})
local tabList = make("Frame", {Parent = sidebar, Size = UDim2.new(1, 0, 1, -54), BackgroundTransparency = 1}, {
	make("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}),
	make("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}),
})
local indicator = accent(make("Frame", {Parent = sidebar, Position = UDim2.fromOffset(4, 16), Size = UDim2.fromOffset(3, 18), ZIndex = 3}, {corner(2)}), "BackgroundColor3")

local footer = make("Frame", {Parent = sidebar, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1})
make("Frame", {Parent = footer, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -24, 0, 1), BackgroundColor3 = T.Stroke, BackgroundTransparency = 0.4, BorderSizePixel = 0})
accent(label({Parent = footer, Position = UDim2.fromOffset(14, 9), Size = UDim2.new(1, -28, 0, 16), Text = APP_NAME, Font = FONT_B, TextSize = 13}), "TextColor3")
label({Parent = footer, Position = UDim2.fromOffset(14, 26), Size = UDim2.new(1, -28, 0, 14), Text = "@" .. AUTHOR, Font = FONT, TextSize = 11, TextColor3 = T.SubText})

local content = make("Frame", {Parent = main, Position = UDim2.fromOffset(160, 56), Size = UDim2.new(1, -170, 1, -66), BackgroundTransparency = 1, ClipsDescendants = true})

local toasts = make("Frame", {Parent = gui, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -18, 1, -18), Size = UDim2.fromOffset(310, 380), BackgroundTransparency = 1}, {
	make("UIListLayout", {Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = Enum.SortOrder.LayoutOrder}),
})
local toastCount = 0
local KINDS = {
	success = {icon = "✓", color = function() return T.Accent end},
	info = {icon = "i", color = function() return T.Accent end},
	warn = {icon = "!", color = function() return T.Warn end},
	error = {icon = "×", color = function() return T.Error end},
}

local function notifyNow(kind, title, text, duration)
	duration = duration or 4
	local k = KINDS[kind] or KINDS.info
	local col = k.color()
	toastCount += 1

	local live = {}
	for _, c in ipairs(toasts:GetChildren()) do
		if c:IsA("Frame") then table.insert(live, c) end
	end
	if #live >= 4 then live[1]:Destroy() end

	local holder = make("Frame", {Parent = toasts, LayoutOrder = toastCount, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1})
	local card = make("Frame", {Parent = holder, Position = UDim2.fromOffset(340, 0), Size = UDim2.new(1, 0, 0, 72), BackgroundColor3 = T.Bg, BackgroundTransparency = 0.04, ClipsDescendants = true}, {corner(10), stroke(col, 0.55)})
	make("Frame", {Parent = card, Size = UDim2.new(0, 80, 1, 0), BackgroundColor3 = col, BackgroundTransparency = 0.88, BorderSizePixel = 0}, {
		make("UIGradient", {Transparency = NumberSequence.new(0, 1)}),
	})
	local icon = make("Frame", {Parent = card, Position = UDim2.fromOffset(14, 20), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = col, BackgroundTransparency = 0.78, ZIndex = 2}, {corner(15)})
	local iconStroke = stroke(col, 0.35); iconStroke.Parent = icon
	label({Parent = icon, Size = UDim2.fromScale(1, 1), Text = k.icon, Font = FONT_B, TextSize = 15, TextColor3 = col, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3})
	label({Parent = card, Position = UDim2.fromOffset(56, 10), Size = UDim2.new(1, -68, 0, 14), Text = APP_NAME:upper(), Font = FONT_B, TextSize = 10, TextColor3 = col, ZIndex = 2})
	label({Parent = card, Position = UDim2.fromOffset(56, 24), Size = UDim2.new(1, -68, 0, 18), Text = title, Font = FONT_B, TextSize = 13, ZIndex = 2})
	label({Parent = card, Position = UDim2.fromOffset(56, 42), Size = UDim2.new(1, -68, 0, 26), Text = text or "", Font = FONT, TextSize = 12, TextColor3 = T.SubText, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 2})
	local bar = make("Frame", {Parent = card, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = col, BorderSizePixel = 0, ZIndex = 3})
	local click = make("TextButton", {Parent = card, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 5})

	tween(holder, {Size = UDim2.new(1, 0, 0, 72)}, 0.25)
	tween(card, {Position = UDim2.fromOffset(0, 0)}, 0.45, Enum.EasingStyle.Back)
	tween(bar, {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear)

	local gone = false
	local function dismiss()
		if gone then return end
		gone = true
		tween(card, {Position = UDim2.fromOffset(340, 0)}, 0.3)
		task.delay(0.2, function()
			if holder.Parent then tween(holder, {Size = UDim2.new(1, 0, 0, 0)}, 0.2).Completed:Wait() end
			holder:Destroy()
		end)
	end
	click.MouseButton1Click:Connect(dismiss)
	click.MouseEnter:Connect(function() tween(card, {BackgroundColor3 = T.Surface}, 0.15) end)
	click.MouseLeave:Connect(function() tween(card, {BackgroundColor3 = T.Bg}, 0.15) end)
	task.delay(duration, dismiss)
end

local toastQueue = {}
local function notify(kind, title, text, duration)
	table.insert(toastQueue, {kind, title, text, duration})
end
task.spawn(function()
	while toasts.Parent do
		while #toastQueue > 0 do
			local t = table.remove(toastQueue, 1)
			pcall(notifyNow, t[1], t[2], t[3], t[4])
		end
		task.wait(0.15)
	end
end)

local tabs, current = {}, nil

local function selectTab(tab)
	if current == tab then return end
	local prev = current
	current = tab
	for _, t in ipairs(tabs) do
		local on = t == tab
		tween(t.button, {BackgroundTransparency = on and 0.15 or 1, TextColor3 = on and T.Text or T.SubText})
	end
	tween(indicator, {Position = UDim2.fromOffset(4, 14 + (tab.index - 1) * 34)}, 0.3)
	if prev then
		local p = prev.page
		tween(p, {GroupTransparency = 1, Position = UDim2.fromOffset(0, -8)}, 0.15)
		task.delay(0.15, function()
			if current ~= prev then p.Visible = false end
		end)
	end
	local pg = tab.page
	pg.Visible, pg.GroupTransparency, pg.Position = true, 1, UDim2.fromOffset(0, 12)
	tween(pg, {GroupTransparency = 0, Position = UDim2.fromOffset(0, 0)}, 0.28)
end

local function drawIcon(parent, key)
	local h = make("Frame", {Parent = parent, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -24, 0.5, 0), Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1})
	local ink = T.Text
	local function fill(x, y, w, hh, acc, r)
		local f = make("Frame", {Parent = h, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, hh), BackgroundColor3 = ink, BorderSizePixel = 0})
		if r then corner(r).Parent = f end
		if acc then accent(f, "BackgroundColor3") end
		return f
	end
	local function box(x, y, w, hh, acc, r)
		local f = make("Frame", {Parent = h, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, hh), BackgroundTransparency = 1})
		if r then corner(r).Parent = f end
		local s = make("UIStroke", {Parent = f, Thickness = 1.5, Color = ink, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
		if acc then accent(s, "Color") end
		return f
	end
	local function ring(cx, cy, d, acc) return box(cx - d / 2, cy - d / 2, d, d, acc, d) end
	local function dot(cx, cy, d, acc) return fill(cx - d / 2, cy - d / 2, d, d, acc, d) end
	local function rbox(cx, cy, s, acc)
		local f = make("Frame", {Parent = h, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy), Size = UDim2.fromOffset(s, s), Rotation = 45, BackgroundTransparency = 1})
		local st = make("UIStroke", {Parent = f, Thickness = 1.5, Color = ink})
		if acc then accent(st, "Color") end
	end
	local function rdot(cx, cy, s, acc)
		local f = make("Frame", {Parent = h, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy), Size = UDim2.fromOffset(s, s), Rotation = 45, BackgroundColor3 = ink, BorderSizePixel = 0})
		if acc then accent(f, "BackgroundColor3") end
	end
	if key == "home" then
		rbox(9, 9, 10)
		rdot(9, 9, 3, true)
	elseif key == "spin" then
		ring(9, 9, 14)
		dot(9, 9, 4, true)
	elseif key == "swords" then
		fill(1, 3, 16, 2, true, 1)
		fill(3, 7, 12, 2)
		fill(4, 3, 2, 13, nil, 1)
		fill(12, 3, 2, 13, nil, 1)
	elseif key == "target" then
		ring(9, 9, 14)
		ring(9, 9, 6, true)
	elseif key == "compass" then
		ring(9, 9, 14)
		fill(8, 4, 2, 6, true, 1)
		dot(9, 11, 2)
	elseif key == "heal" then
		fill(7, 3, 4, 12, true, 1)
		fill(3, 7, 12, 4, true, 1)
	elseif key == "map" then
		box(2, 3, 14, 12, nil, 2)
		fill(7, 3, 2, 12)
		dot(12, 7, 4, true)
	elseif key == "cards" then
		box(2, 4, 8, 12, nil, 2)
		box(8, 2, 8, 12, true, 2)
	elseif key == "shop" then
		box(2, 7, 14, 9, nil, 2)
		box(6, 2, 6, 7, true, 3)
	elseif key == "link" then
		rbox(6.5, 9, 6)
		rbox(11.5, 9, 6, true)
	elseif key == "gear" then
		fill(2, 3, 14, 2, nil, 1) fill(2, 8, 14, 2, nil, 1) fill(2, 13, 14, 2, nil, 1)
		dot(6, 4, 5) dot(12, 9, 5, true) dot(8, 14, 5)
	elseif key == "servers" then
		ring(9, 9, 14)
		box(6, 2, 6, 14, true, 3)
		fill(2, 8, 14, 2, nil, 1)
	elseif key == "coin" then
		ring(9, 9, 14)
		ring(9, 9, 6, true)
	elseif key == "player" then
		ring(9, 5, 6)
		box(3, 11, 12, 6, true, 3)
	elseif key == "eye" then
		box(1, 5, 16, 8, nil, 4)
		dot(9, 9, 4, true)
	else
		dot(9, 9, 6, true)
	end
	return h
end

local function newTab(name, icon)
	local index = #tabs + 1
	local btn = make("TextButton", {
		Parent = tabList, LayoutOrder = index, Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = T.Element, BackgroundTransparency = 1, AutoButtonColor = false,
		Text = name, Font = FONT_M, TextSize = 13, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Left,
	}, {corner(8), make("UIPadding", {PaddingLeft = UDim.new(0, icon and 34 or 14)})})
	if icon then drawIcon(btn, icon) end
	local page = make("CanvasGroup", {Parent = content, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, GroupTransparency = 1})
	local scroll = make("ScrollingFrame", {
		Parent = page, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
	}, {
		make("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}),
		make("UIPadding", {PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8)}),
	})
	accent(scroll, "ScrollBarImageColor3")
	local tab = {index = index, button = btn, page = page, container = scroll, order = 0}
	table.insert(tabs, tab)
	connect(btn.MouseEnter, function() if current ~= tab then tween(btn, {BackgroundTransparency = 0.55, TextColor3 = T.Text}) end end)
	connect(btn.MouseLeave, function() if current ~= tab then tween(btn, {BackgroundTransparency = 1, TextColor3 = T.SubText}) end end)
	connect(btn.MouseButton1Click, function() selectTab(tab) end)
	return tab
end

local function nextOrder(tab)
	tab.order += 1
	return tab.order
end

local function baseElement(tab, height, hitHeight)
	local f = make("Frame", {Parent = tab.container, LayoutOrder = nextOrder(tab), Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = T.Element, BackgroundTransparency = 0.15}, {corner(8)})
	local s = stroke(T.Stroke, 0.7); s.Parent = f
	local hit = make("TextButton", {Parent = f, Size = UDim2.new(1, 0, 0, hitHeight or height), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 1})
	connect(f.MouseEnter, function()
		tween(f, {BackgroundColor3 = T.Hover})
		tween(s, {Color = T.Accent, Transparency = 0.5})
	end)
	connect(f.MouseLeave, function()
		tween(f, {BackgroundColor3 = T.Element})
		tween(s, {Color = T.Stroke, Transparency = 0.7})
	end)
	return f, hit
end

local function section(tab, text)
	accent(label({Parent = tab.container, LayoutOrder = nextOrder(tab), Size = UDim2.new(1, 0, 0, 24), Text = string.upper(text), Font = FONT_B, TextSize = 11, TextYAlignment = Enum.TextYAlignment.Bottom}), "TextColor3")
end

local function note(tab, text)
	return label({Parent = tab.container, LayoutOrder = nextOrder(tab), Size = UDim2.new(1, 0, 0, 30), Text = text, Font = FONT, TextSize = 12, TextColor3 = T.SubText, TextWrapped = true, RichText = true})
end

local function toggle(tab, flag, title, default, callback)
	local f, hit = baseElement(tab, 40)
	label({Parent = f, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -70, 1, 0), Text = title})
	local sw = make("Frame", {Parent = f, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(38, 20), BackgroundColor3 = T.Off}, {corner(10)})
	local knob = make("Frame", {Parent = sw, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = T.Text}, {corner(7)})
	local o = register(flag, default, function(v)
		tween(sw, {BackgroundColor3 = v and T.Accent or T.Off}, 0.2)
		tween(knob, {Position = v and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)}, 0.3, Enum.EasingStyle.Back)
	end)
	o.Callback = callback
	o:SetValue(default, true)
	connect(hit.MouseButton1Click, function() o:SetValue(not o.Value) end)
	return o
end

local function button(tab, title, desc, callback)
	local h = desc and 48 or 40
	local f, hit = baseElement(tab, h)
	label({Parent = f, Position = UDim2.fromOffset(12, desc and 7 or 0), Size = UDim2.new(1, -40, 0, desc and 18 or h), Text = title})
	local descLabel
	if desc then
		descLabel = label({Parent = f, Position = UDim2.fromOffset(12, 26), Size = UDim2.new(1, -40, 0, 14), Text = desc, Font = FONT, TextSize = 11, TextColor3 = T.SubText, TextTruncate = Enum.TextTruncate.AtEnd, RichText = true})
	end
	local arrow = label({Parent = f, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(16, 16), Text = "›", Font = FONT_B, TextSize = 18, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Center})
	local sc = make("UIScale", {Parent = f})
	connect(f.MouseEnter, function() tween(arrow, {Position = UDim2.new(1, -8, 0.5, 0), TextColor3 = T.Accent}) end)
	connect(f.MouseLeave, function() tween(arrow, {Position = UDim2.new(1, -12, 0.5, 0), TextColor3 = T.SubText}) end)
	connect(hit.MouseButton1Down, function() tween(sc, {Scale = 0.97}, 0.08) end)
	connect(hit.MouseButton1Up, function() tween(sc, {Scale = 1}, 0.25, Enum.EasingStyle.Back) end)
	connect(hit.MouseLeave, function() tween(sc, {Scale = 1}, 0.2) end)
	connect(hit.MouseButton1Click, function() task.spawn(callback) end)
	return {SetDesc = function(text) if descLabel and descLabel.Text ~= text then descLabel.Text = text end end}
end

local function slider(tab, flag, title, min, max, step, default, suffix, callback)
	local f = baseElement(tab, 54)
	label({Parent = f, Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -90, 0, 20), Text = title})
	local val = accent(label({Parent = f, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 6), Size = UDim2.fromOffset(70, 20), Font = FONT_B, TextXAlignment = Enum.TextXAlignment.Right}), "TextColor3")
	local track = make("Frame", {Parent = f, Position = UDim2.new(0, 12, 0, 36), Size = UDim2.new(1, -24, 0, 6), BackgroundColor3 = T.Off, ZIndex = 2}, {corner(3)})
	local fill = accent(make("Frame", {Parent = track, Size = UDim2.fromScale(0, 1), ZIndex = 2}, {corner(3)}), "BackgroundColor3")
	local knob = make("Frame", {Parent = track, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = T.Text, ZIndex = 3}, {corner(6)})
	local o = register(flag, default, function(v)
		local a = (v - min) / (max - min)
		tween(fill, {Size = UDim2.fromScale(a, 1)}, 0.12)
		tween(knob, {Position = UDim2.fromScale(a, 0.5)}, 0.12)
		val.Text = string.format("%g", v) .. (suffix or "")
		if callback then callback(v) end
	end)
	o:SetValue(default, true)

	local dragging = false
	local function update(x)
		local a = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		local v = math.clamp(math.floor((min + a * (max - min)) / step + 0.5) * step, min, max)
		if v ~= o.Value then o:SetValue(v) end
	end
	local grab = make("TextButton", {Parent = f, Position = UDim2.new(0, 6, 0, 26), Size = UDim2.new(1, -12, 0, 24), BackgroundTransparency = 1, Text = "", ZIndex = 4})
	connect(grab.InputBegan, function(i)
		if i.UserInputType == MB1 or i.UserInputType == TOUCH then
			dragging = true
			tween(knob, {Size = UDim2.fromOffset(15, 15)}, 0.15)
			update(i.Position.X)
		end
	end)
	connect(UIS.InputChanged, function(i)
		if dragging and (i.UserInputType == MOVE or i.UserInputType == TOUCH) then update(i.Position.X) end
	end)
	connect(UIS.InputEnded, function(i)
		if dragging and (i.UserInputType == MB1 or i.UserInputType == TOUCH) then
			dragging = false
			tween(knob, {Size = UDim2.fromOffset(12, 12)}, 0.2, Enum.EasingStyle.Back)
		end
	end)
	return o
end

local function textBox(parent, props)
	local box = make("TextBox", {
		Parent = parent, BackgroundColor3 = T.Surface, BackgroundTransparency = 0.1, Text = "",
		PlaceholderColor3 = T.SubText, TextColor3 = T.Text, Font = FONT, TextSize = 12, ClearTextOnFocus = false,
		TextTruncate = Enum.TextTruncate.AtEnd, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2,
	}, {corner(6), make("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})})
	for k, v in pairs(props) do box[k] = v end
	local bs = stroke(T.Stroke, 0.6); bs.Parent = box
	connect(box.Focused, function() tween(bs, {Color = T.Accent, Transparency = 0.1}) end)
	connect(box.FocusLost, function() tween(bs, {Color = T.Stroke, Transparency = 0.6}) end)
	return box
end

local function input(tab, flag, title, placeholder, callback)
	local f = baseElement(tab, 40)
	label({Parent = f, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.4, 0, 1, 0), Text = title})
	local box = textBox(f, {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0.58, 0, 0, 26), PlaceholderText = placeholder or ""})
	local o = register(flag, "", function(v) box.Text = v end)
	o.Callback = callback
	connect(box.FocusLost, function()
		if box.Text ~= o.Value then o:SetValue(box.Text) end
	end)
	return o
end

local function dropdown(tab, flag, title, values, multi, default)
	local f, hit = baseElement(tab, 40, 40)
	f.ClipsDescendants = true
	label({Parent = f, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.45, 0, 0, 40), Text = title})
	local valueLabel = label({
		Parent = f, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -34, 0, 0), Size = UDim2.new(0.5, -20, 0, 40),
		Font = FONT, TextSize = 12, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local chevron = label({Parent = f, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -20, 0, 20), Size = UDim2.fromOffset(16, 16), Text = "›", Font = FONT_B, TextSize = 18, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Center, Rotation = 90})
	local list = make("ScrollingFrame", {
		Parent = f, Position = UDim2.fromOffset(6, 44), Size = UDim2.new(1, -12, 0, 30),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 2,
	}, {make("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder})})
	accent(list, "ScrollBarImageColor3")

	local items, o, open, listH = {}, nil, false, 30
	local function isOn(v)
		if multi then return type(o.Value) == "table" and o.Value[v] == true end
		return o.Value == v
	end
	local function paint(v, hover)
		local item, on = items[v], isOn(v)
		if not item then return end
		tween(item.btn, {BackgroundTransparency = on and 0.25 or (hover and 0.6 or 1), TextColor3 = (on or hover) and T.Text or T.SubText}, 0.15)
		tween(item.mark, {BackgroundTransparency = on and 0 or 1, Size = on and UDim2.fromOffset(6, 6) or UDim2.fromOffset(2, 2)}, 0.2)
	end
	local function refresh()
		if multi then
			local sel = {}
			for _, v in ipairs(values) do
				if isOn(v) then table.insert(sel, v) end
			end
			valueLabel.Text = #sel == 0 and "None" or (#sel <= 2 and table.concat(sel, ", ") or (#sel .. " selected"))
		else
			valueLabel.Text = (o.Value == nil or o.Value == "") and "None" or tostring(o.Value)
		end
		for _, v in ipairs(values) do paint(v, false) end
	end
	local function setOpen(state)
		open = state
		tween(f, {Size = UDim2.new(1, 0, 0, state and (48 + listH) or 40)}, 0.28)
		tween(chevron, {Rotation = state and 270 or 90, TextColor3 = state and T.Accent or T.SubText}, 0.28)
	end
	local function build()
		for _, it in pairs(items) do it.btn:Destroy() end
		items = {}
		listH = math.max(1, math.min(#values, 6)) * 30
		list.Size = UDim2.new(1, -12, 0, listH)
		for i, v in ipairs(values) do
			local b = make("TextButton", {
				Parent = list, LayoutOrder = i, Size = UDim2.new(1, -6, 0, 28), BackgroundColor3 = T.Hover, BackgroundTransparency = 1,
				AutoButtonColor = false, Text = v, Font = FONT, TextSize = 12, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2,
			}, {corner(6), make("UIPadding", {PaddingLeft = UDim.new(0, 22)})})
			local mark = accent(make("Frame", {Parent = b, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, -11, 0.5, 0), Size = UDim2.fromOffset(2, 2), BackgroundTransparency = 1, ZIndex = 3}, {corner(3)}), "BackgroundColor3")
			items[v] = {btn = b, mark = mark}
			b.MouseEnter:Connect(function() paint(v, true) end)
			b.MouseLeave:Connect(function() paint(v, false) end)
			b.MouseButton1Click:Connect(function()
				if multi then
					local t = table.clone(type(o.Value) == "table" and o.Value or {})
					t[v] = (not t[v]) or nil
					o:SetValue(t)
				else
					o:SetValue(v)
					setOpen(false)
				end
			end)
		end
	end

	o = register(flag, default, function() refresh() end)
	function o.SetValues(newValues)
		values = newValues
		build()
		refresh()
		if open then setOpen(true) end
	end
	build()
	connect(hit.MouseButton1Click, function() setOpen(not open) end)
	o:SetValue(default, true)
	return o
end

local PRESETS = {
	{"Olive", "#8E9A4E"}, {"Sage", "#7FA37A"}, {"Ocean", "#4F8FD6"}, {"Violet", "#9071D9"},
	{"Rose", "#D9708E"}, {"Crimson", "#D65252"}, {"Amber", "#D9A040"}, {"Mint", "#4FC2A0"}, {"Ice", "#9FB8C9"},
}
local function colorPicker(tab, flag, title, default)
	local f = baseElement(tab, 70)
	label({Parent = f, Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -110, 0, 20), Text = title})
	local nameLabel = label({Parent = f, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 6), Size = UDim2.fromOffset(120, 20), Font = FONT, TextSize = 12, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Right})
	local row = make("Frame", {Parent = f, Position = UDim2.fromOffset(12, 34), Size = UDim2.new(1, -24, 0, 26), BackgroundTransparency = 1, ZIndex = 2}, {
		make("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 9), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}),
	})
	local rings = {}
	local o = register(flag, default, function(v)
		local c = fromHex(v)
		if c then setAccent(c) end
		local name = "Custom"
		for _, p in ipairs(PRESETS) do
			local on = p[2]:upper() == tostring(v):upper()
			if on then name = p[1] end
			if rings[p[2]] then tween(rings[p[2]], {Transparency = on and 0 or 1}, 0.2) end
		end
		nameLabel.Text = name .. "  " .. tostring(v):upper()
	end)
	o.NoRefresh = true
	for i, p in ipairs(PRESETS) do
		local sw = make("TextButton", {Parent = row, LayoutOrder = i, Size = UDim2.fromOffset(22, 22), BackgroundColor3 = fromHex(p[2]), Text = "", AutoButtonColor = false, ZIndex = 2}, {corner(11)})
		rings[p[2]] = make("UIStroke", {Parent = sw, Color = T.Text, Thickness = 2, Transparency = 1})
		local sc = make("UIScale", {Parent = sw})
		connect(sw.MouseEnter, function() tween(sc, {Scale = 1.18}, 0.2, Enum.EasingStyle.Back) end)
		connect(sw.MouseLeave, function() tween(sc, {Scale = 1}, 0.2) end)
		connect(sw.MouseButton1Click, function() o:SetValue(p[2]) end)
	end
	o:SetValue(default, true)
	return o
end
local Axiom = (function()
local Axiom = {}
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

Axiom.APP_NAME = "AxiomHUB"
Axiom.AUTHOR = "kingping77"
Axiom.COLORS = {
	olive = Color3.fromRGB(154, 166, 90), azure = Color3.fromRGB(79, 143, 214),
	amber = Color3.fromRGB(224, 164, 60), rose = Color3.fromRGB(201, 102, 122),
	ground = Color3.fromRGB(18, 19, 16), ink = Color3.fromRGB(237, 238, 230), sub = Color3.fromRGB(169, 173, 156),
}

local function tween(o, props, t, style)
	local tw = TweenService:Create(o, TweenInfo.new(t or 0.25, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end
local function make(class, props, kids)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do if k ~= "Parent" then o[k] = v end end
	for _, c in ipairs(kids or {}) do c.Parent = o end
	if props and props.Parent then o.Parent = props.Parent end
	return o
end
local function corner(r) return make("UICorner", {CornerRadius = UDim.new(0, r)}) end

function Axiom.drawMark(parent, size, accent, z)
	accent, z = accent or Axiom.COLORS.olive, z or 1
	local k = size / 200
	local holder = make("Frame", {Parent = parent, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, ZIndex = z})
	local m = {holder = holder, scale = make("UIScale", {Parent = holder})}
	local function box(cx, cy, w, h, rot, color, zz)
		return make("Frame", {Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx * k, cy * k), Size = UDim2.fromOffset(math.max(1, w * k), math.max(1, h * k)),
			Rotation = rot, BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = z + (zz or 1)})
	end
	local function ring(side, thick, tr)
		local f = make("Frame", {Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(100 * k, 100 * k), Size = UDim2.fromOffset(side * k, side * k), Rotation = 45, BackgroundTransparency = 1, ZIndex = z})
		return f, make("UIStroke", {Parent = f, Color = accent, Thickness = math.max(1, thick * k), Transparency = tr})
	end
	m.outer, m.outerStroke = ring(133, 3, 0.45)
	m.inner, m.innerStroke = ring(110, 1.5, 0.8)
	m.legL = box(79.5, 95, 21, 120, 20.4, Axiom.COLORS.ink)
	m.legR = box(120.5, 95, 21, 120, -20.4, Axiom.COLORS.ink)
	m.bar = box(100, 122, 48, 5, 0, accent, 2)
	m.hub = box(100, 122, 18, 18, 45, accent, 3)
	m.apex = box(100, 6, 8, 8, 45, accent, 3)
	m.fills = {m.legL, m.legR, m.bar, m.hub, m.apex}
	return m
end

function Axiom.play(opts)
	opts = opts or {}
	local accent = opts.accent or Axiom.COLORS.olive
	local name, author = opts.appName or Axiom.APP_NAME, opts.author or Axiom.AUTHOR
	local steps = opts.steps or {"Loading…", "Ready"}
	local gui = make("ScreenGui", {Name = "AxiomIntro", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
	if not pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end) or not gui.Parent then
		gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	end
	local blur = Instance.new("BlurEffect")
	blur.Size = 0
	blur.Parent = game:GetService("Lighting")
	local dim = make("Frame", {Parent = gui, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1})
	local card = make("Frame", {Parent = gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(640, 360),
		BackgroundColor3 = Axiom.COLORS.ground, BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 2}, {corner(16)})
	local cScale = make("UIScale", {Parent = card, Scale = 0.9})
	local cStroke = make("UIStroke", {Parent = card, Color = accent, Thickness = 1.5, Transparency = 1})
	local fades = {}
	local lattice = make("Frame", {Parent = card, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromScale(0.62, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 2},
		{make("UIGradient", {Transparency = NumberSequence.new(1, 0)})})
	for i = -3, 12 do
		for _, rot in ipairs({35, -35}) do
			table.insert(fades, {make("Frame", {Parent = lattice, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, i * 40, 0.5, 0), Size = UDim2.fromOffset(1, 520),
				Rotation = rot, BackgroundColor3 = accent, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2}), 0.9})
		end
	end
	for _, c in ipairs({{0, 0}, {1, 0}, {0, 1}, {1, 1}}) do
		local ax, ay = c[1], c[2]
		local sx, sy = ax == 0 and 1 or -1, ay == 0 and 1 or -1
		for _, sz in ipairs({{24, 2}, {2, 24}}) do
			table.insert(fades, {make("Frame", {Parent = card, AnchorPoint = Vector2.new(ax, ay), Position = UDim2.new(ax, sx * 16, ay, sy * 16), Size = UDim2.fromOffset(sz[1], sz[2]),
				BackgroundColor3 = accent, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3}), 0.1})
		end
		table.insert(fades, {make("Frame", {Parent = card, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(ax, sx * 46, ay, sy * 17), Size = UDim2.fromOffset(5, 5), Rotation = 45,
			BackgroundColor3 = accent, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3}), 0})
	end
	local markBox = make("Frame", {Parent = card, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.47), Size = UDim2.fromOffset(150, 150), BackgroundTransparency = 1, ZIndex = 3})
	local mk = Axiom.drawMark(markBox, 150, accent, 4)
	mk.scale.Scale = 0.3
	mk.outerStroke.Transparency, mk.innerStroke.Transparency = 1, 1
	for _, f in ipairs(mk.fills) do f.BackgroundTransparency = 1 end
	local pulse = make("Frame", {Parent = markBox, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(60, 60), Rotation = 45, BackgroundTransparency = 1, ZIndex = 3})
	local pulseStroke = make("UIStroke", {Parent = pulse, Color = accent, Thickness = 2, Transparency = 1})
	local textBox = make("Frame", {Parent = card, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 262, 0.47, 0), Size = UDim2.fromOffset(340, 110), BackgroundTransparency = 1, ZIndex = 3})
	local title = make("TextLabel", {Parent = textBox, Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 58), BackgroundTransparency = 1, Text = "", RichText = true,
		Font = Enum.Font.GothamBold, TextSize = 54, TextColor3 = Axiom.COLORS.ink, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4})
	local line = make("Frame", {Parent = textBox, Position = UDim2.fromOffset(2, 80), Size = UDim2.fromOffset(0, 2), BackgroundColor3 = accent, BorderSizePixel = 0, ZIndex = 4})
	local tag = make("TextLabel", {Parent = textBox, Position = UDim2.fromOffset(52, 72), Size = UDim2.new(1, -52, 0, 18), BackgroundTransparency = 1, Text = "",
		Font = Enum.Font.Code, TextSize = 13, TextColor3 = Axiom.COLORS.sub, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4})
	local bar = make("Frame", {Parent = card, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -34), Size = UDim2.fromOffset(220, 3), BackgroundColor3 = Color3.fromRGB(50, 52, 44), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3}, {corner(2)})
	local fill = make("Frame", {Parent = bar, Size = UDim2.fromScale(0, 1), BackgroundColor3 = accent, BorderSizePixel = 0, ZIndex = 4}, {corner(2)})
	local step = make("TextLabel", {Parent = card, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.fromOffset(300, 14), BackgroundTransparency = 1, Text = "",
		Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Axiom.COLORS.sub, ZIndex = 3})
	local spin = RunService.RenderStepped:Connect(function(dt)
		mk.outer.Rotation = (mk.outer.Rotation + dt * 40) % 360
		mk.inner.Rotation = (mk.inner.Rotation - dt * 28) % 360
	end)

	tween(blur, {Size = 14}, 0.5)
	tween(dim, {BackgroundTransparency = 0.45}, 0.5)
	tween(card, {BackgroundTransparency = 0.02}, 0.4)
	tween(cStroke, {Transparency = 0.55}, 0.5)
	tween(cScale, {Scale = 1}, 0.6, Enum.EasingStyle.Back)
	for _, f in ipairs(fades) do tween(f[1], {BackgroundTransparency = f[2]}, 0.8) end
	task.wait(0.25)
	tween(mk.scale, {Scale = 1}, 0.6, Enum.EasingStyle.Back)
	tween(mk.outerStroke, {Transparency = 0.45}, 0.5)
	tween(mk.innerStroke, {Transparency = 0.8}, 0.6)
	task.wait(0.2)
	tween(mk.legL, {BackgroundTransparency = 0}, 0.35)
	tween(mk.legR, {BackgroundTransparency = 0}, 0.35)
	task.wait(0.3)
	tween(mk.bar, {BackgroundTransparency = 0}, 0.3)
	local hubSize = mk.hub.Size
	mk.hub.Size = UDim2.fromOffset(0, 0)
	tween(mk.hub, {BackgroundTransparency = 0, Size = hubSize}, 0.4, Enum.EasingStyle.Back)
	tween(mk.apex, {BackgroundTransparency = 0}, 0.3)
	pulseStroke.Transparency = 0.2
	tween(pulse, {Size = UDim2.fromOffset(230, 230)}, 0.8, Enum.EasingStyle.Quad)
	tween(pulseStroke, {Transparency = 1, Thickness = 0.5}, 0.8, Enum.EasingStyle.Quad)
	task.wait(0.55)
	tween(markBox, {Position = UDim2.new(0, 160, 0.47, 0)}, 0.55, Enum.EasingStyle.Quint)
	task.wait(0.4)
	local hex = string.format("#%02X%02X%02X", accent.R * 255, accent.G * 255, accent.B * 255)
	local split = name:find("HUB") or (#name + 1)
	for i = 1, #name do
		local t = name:sub(1, i)
		title.Text = #t >= split and (t:sub(1, split - 1) .. '<font color="' .. hex .. '">' .. t:sub(split) .. "</font>") or t
		task.wait(0.05)
	end
	tween(line, {Size = UDim2.fromOffset(40, 2)}, 0.3)
	local tagline = opts.tagline or ("SCRIPT HUB  ·  BY " .. string.upper(author))
	for i = 1, #tagline do
		tag.Text = tagline:sub(1, i)
		task.wait(0.018)
	end
	tween(bar, {BackgroundTransparency = 0.3}, 0.3)
	for i, txt in ipairs(steps) do
		step.Text = txt
		tween(fill, {Size = UDim2.fromScale(i / #steps, 1)}, 0.28)
		task.wait(0.3)
	end
	task.wait(0.35)
	tween(cScale, {Scale = 1.06}, 0.35)
	for _, o in ipairs(card:GetDescendants()) do
		if o:IsA("TextLabel") then tween(o, {TextTransparency = 1}, 0.3)
		elseif o:IsA("Frame") then tween(o, {BackgroundTransparency = 1}, 0.3)
		elseif o:IsA("UIStroke") then tween(o, {Transparency = 1}, 0.3) end
	end
	tween(card, {BackgroundTransparency = 1}, 0.35)
	tween(cStroke, {Transparency = 1}, 0.3)
	tween(dim, {BackgroundTransparency = 1}, 0.45)
	tween(blur, {Size = 0}, 0.45)
	task.wait(0.15)
	if opts.onDone then task.spawn(opts.onDone) end
	task.wait(0.35)
	spin:Disconnect()
	gui:Destroy()
	blur:Destroy()
end

return Axiom
end)()

local floatButton
local DEFAULT_HOOK = ""
local function runHub()
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local camera = workspace.CurrentCamera
local LOBBY = Vector3.new(0, 500, 0)

local Remotes = RS:WaitForChild("Remotes", 10)
local Gameplay = Remotes and Remotes:FindFirstChild("Gameplay")

local stats = {started = os.clock(), coins = 0, rounds = 0, bags = 0, cur = 0, max = 40, full = false, state = "Waiting for round"}
app.stats = stats

local function char() return player.Character end
local function hrp() local c = char() return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = char() return c and c:FindFirstChildOfClass("Humanoid") end
local function alive() local h = hum() return h and h.Health > 0 and hrp() ~= nil end
local function currentMap()
	for _, m in ipairs(workspace:GetChildren()) do
		if m:IsA("Model") and m:FindFirstChild("CoinContainer") then return m end
	end
end

local function inRound()
	local r, m = hrp(), currentMap()
	if not (r and m) then return false end
	if (r.Position - LOBBY).Magnitude < 300 then return false end
	return (r.Position - m:GetPivot().Position).Magnitude < 900
end
local function fmtTime(s)
	s = math.floor(s)
	return string.format("%d:%02d:%02d", s // 3600, (s // 60) % 60, s % 60)
end
local function httpRequest(t)
	local fn = (syn and syn.request) or (http and http.request) or http_request or request
	if not fn then return false end
	return pcall(fn, t)
end

local HomeTab = newTab("Home", "home")
local FarmTab = newTab("Farm", "coin")
local PlayerTab = newTab("Player", "player")
local VisualTab = newTab("Visuals", "eye")
local ServerTab = newTab("Server", "servers")
local SettingsTab = newTab("Settings", "gear")

local homeRows = {}
do
	section(HomeTab, "Session")
	homeRows.time = button(HomeTab, "Session time", "0:00:00", function() end)
	homeRows.coins = button(HomeTab, "Coins collected", "0", function() end)
	homeRows.rate = button(HomeTab, "Coins per hour", "0", function() end)
	homeRows.rounds = button(HomeTab, "Rounds / full bags", "0 / 0", function() end)
	homeRows.state = button(HomeTab, "Status", "Waiting for round", function() end)
	section(HomeTab, "About")
	note(HomeTab, "made by @" .. AUTHOR .. " · config saves itself")
end

local F = {moving = false, tw = nil, target = nil}
app.farm = F
do
	section(FarmTab, "Alt mode")
	toggle(FarmTab, "AltMode", "Alt mode", false, function(on)
		if on then
			for _, f in ipairs({"AutoFarm", "NoRender", "FPSCapOn", "LowGfx", "SkipIntro", "AutoRejoin"}) do
				if not Options[f].Value then Options[f]:SetValue(true) end
			end
			Options.CoinESP:SetValue(false)
			Options.Shaders:SetValue(false)
			notify("success", "Alt mode", "farm on, fps low")
			task.delay(3, function() if Options.AltMode.Value then app.setVisible(false) end end)
		else
			Options.NoRender:SetValue(false)
			Options.FPSCapOn:SetValue(false)
		end
	end)
	note(FarmTab, "turn on for alts, low fps + farm")

	section(FarmTab, "Coin farm")
	F.toggle = toggle(FarmTab, "AutoFarm", "Auto farm coins", false, function(on)
		notify(on and "success" or "info", on and "Farm on" or "Farm off", on and "farming" or "Stopped.")
	end)
	slider(FarmTab, "FarmSpeed", "Farm speed", 14, 26, 1, 22, " st/s")
	dropdown(FarmTab, "FullBag", "When the bag is full", {"Reset (faster rounds)", "Do nothing"}, false, "Reset (faster rounds)")
	toggle(FarmTab, "PreferEvent", "Event coins first", true)
	toggle(FarmTab, "SkipFar", "Only close coins", false)
	note(FarmTab, "dont go too fast or you get kicked")

	section(FarmTab, "Map vote")
	toggle(FarmTab, "AutoVote", "Auto vote for a map", false)
	dropdown(FarmTab, "VoteMaps", "Preferred maps", {"Bank 2", "Bio Lab", "Factory", "Hospital 3", "Hotel 2", "House 2", "Mansion 2", "Mil Base", "Office 3", "Police Station", "Research Facility", "Workplace"}, true, {["House 2"] = true, ["Factory"] = true})
	note(FarmTab, "small maps farm faster")
end

if Gameplay then
	local cc, cs, rs = Gameplay:FindFirstChild("CoinCollected"), Gameplay:FindFirstChild("CoinsStarted"), Gameplay:FindFirstChild("RoundStart")
	stats.kinds = {}
	if cc then connect(cc.OnClientEvent, function(kind, cur, max)
		kind = tostring(kind or "Coin")
		stats.kinds[kind] = (stats.kinds[kind] or 0) + 1
		stats.cur, stats.max = tonumber(cur) or stats.cur, tonumber(max) or stats.max
		stats.coins += 1
		if stats.cur >= stats.max and not stats.full then
			stats.full = true
			stats.bags += 1
		end
	end) end
	local function live() stats.liveAt = os.clock() + 2.5 end
	if cs then connect(cs.OnClientEvent, function() stats.full, stats.cur = false, 0; live() end) end
	if rs then connect(rs.OnClientEvent, function() stats.rounds += 1; stats.full, stats.cur = false, 0; live() end) end
	for _, n in ipairs({"GameOver", "RoundEndFade", "LoadingMap", "RoleSelect"}) do
		local e = Gameplay:FindFirstChild(n)
		if e then connect(e.OnClientEvent, function() stats.liveAt, stats.sawEvent = nil, true end) end
	end
end

local noclipOn = false
local charParts, partsOf = {}, nil
connect(RunService.Stepped, function()
	if not (F.moving or noclipOn) then return end
	local c = char()
	if not c then return end
	if partsOf ~= c then
		partsOf, charParts = c, {}
		for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then table.insert(charParts, p) end end
	end
	for _, p in ipairs(charParts) do
		if p.CanCollide then p.CanCollide = false end
	end
end)

local function coinContainer()
	local m = currentMap()
	return m and m:FindFirstChild("CoinContainer")
end
local function nearestCoin(from)
	local cc = coinContainer()
	if not cc then return nil end
	local best, bestD
	local maxD = Options.SkipFar.Value and 150 or 300
	for _, c in ipairs(cc:GetChildren()) do
		if c:IsA("BasePart") and c:FindFirstChildOfClass("TouchTransmitter") and c ~= F.skip then
			local d = (c.Position - from).Magnitude
			if Options.PreferEvent.Value then
				local id = c:GetAttribute("CoinID")
				if id and id ~= "Coin" then d *= 0.4 end
			end
			if d < maxD and (not bestD or d < bestD) then best, bestD = c, d end
		end
	end
	return best, bestD
end
local function stopMove()
	if F.tw then pcall(function() F.tw:Cancel() end) F.tw = nil end
	F.moving = false
	local r = hrp()
	if r then r.AssemblyLinearVelocity = Vector3.zero end
end

local hideSpot
local function farmStep()
	if not Options.AutoFarm.Value then
		if F.moving then stopMove() end
		hideSpot = nil
		stats.state = "Farm off"
		return
	end
	if not alive() then stats.state = "Dead / waiting"; hideSpot = nil return end
	if not inRound() then stats.state = "In lobby · waiting for round"; hideSpot = nil return end

	if not stats.liveAt then

		local cc = coinContainer()
		if not stats.sawEvent and cc and #cc:GetChildren() > 0 then stats.liveAt = os.clock() else stats.state = "Waiting for round start" return end
	end
	if os.clock() < stats.liveAt then stats.state = "Round starting…" return end
	local r = hrp()
	if r.Anchored then stats.state = "Frozen by the game" return end
	if stats.full then
		local mode = Options.FullBag.Value
		if mode == "Reset (faster rounds)" then
			stats.state = "Bag full · reset"
			stopMove()
			local h = hum()
			if h then h.Health = 0 end
			task.wait(1)
		else
			stats.state = "Bag full"
		end
		return
	end
	hideSpot = nil
	local coin, d = nearestCoin(r.Position)
	if not coin then stats.state = "No coins yet" return end
	stats.state = string.format("Collecting · bag %d/%d", stats.cur, stats.max)
	F.moving = true
	local t = d / Options.FarmSpeed.Value
	F.tw = TweenService:Create(r, TweenInfo.new(t, Enum.EasingStyle.Linear), {CFrame = CFrame.new(coin.Position)})
	F.tw:Play()
	local t0 = os.clock()

	while os.clock() - t0 < t + 0.05 do
		if not coin.Parent or not coin:FindFirstChildOfClass("TouchTransmitter") or not Options.AutoFarm.Value or not alive() then break end
		r.AssemblyLinearVelocity = Vector3.zero
		task.wait()
	end
	if F.tw then F.tw:Cancel() F.tw = nil end
	r.AssemblyLinearVelocity = Vector3.zero

	local w0 = os.clock()
	while coin.Parent and coin:FindFirstChildOfClass("TouchTransmitter") and os.clock() - w0 < 0.35 do task.wait() end
	if coin.Parent and coin:FindFirstChildOfClass("TouchTransmitter") then F.skip = coin end
end

task.spawn(function()
	while app.alive ~= false and gui.Parent do
		local ok, err = pcall(farmStep)
		if not ok then
			stopMove()
			warn("[AxiomHUB] farm: " .. tostring(err))
			task.wait(0.5)
		end
		if not F.moving then task.wait(0.15) end
		if not Options.AutoFarm.Value or not inRound() then F.moving = false end
	end
end)

task.spawn(function()
	while gui.Parent do
		task.wait(1)
		pcall(function()
			if not Options.AutoVote.Value or not alive() or inRound() then return end
			local L = workspace:FindFirstChild("RegularLobby")
			local icons = L and L:FindFirstChild("VoteIcons")
			if not icons then return end
			local want = Options.VoteMaps.Value or {}
			for i = 1, 3 do
				local icon = icons:FindFirstChild("VotePad" .. i)
				local voting = icon and icon:FindFirstChild("Voting")
				if voting and voting.Value then
					local name
					for _, d in ipairs(icon:GetDescendants()) do
						if d:IsA("TextLabel") and d.Name == "MapName" then name = d.Text end
					end
					if name then
						for map in pairs(want) do
							if name:lower():gsub("%s", "") == map:lower():gsub("%s", "") then
								local pad = L:FindFirstChild("VotePad" .. i)
								local part = pad and pad:FindFirstChild("Pad", true)
								local r = hrp()
								if part and r and (r.Position - part.Position).Magnitude > 4 then
									local h = hum()
									if h then h:MoveTo(part.Position) end
									notify("info", "Map vote", "Voted for " .. name)
								end
								return
							end
						end
					end
				end
			end
		end)
	end
end)

do
	section(PlayerTab, "Speed & jump")
	toggle(PlayerTab, "WSOn", "Walk speed", false)
	slider(PlayerTab, "WSValue", "Walk speed value", 16, 120, 1, 24)
	toggle(PlayerTab, "JPOn", "Jump power", false)
	slider(PlayerTab, "JPValue", "Jump power value", 50, 200, 5, 75)
	toggle(PlayerTab, "GravOn", "Custom gravity", false, function(on) if not on then workspace.Gravity = 196.2 end end)
	slider(PlayerTab, "GravValue", "Gravity", 20, 196, 2, 120)

	section(PlayerTab, "Movement")
	toggle(PlayerTab, "Noclip", "No clip", false, function(on) noclipOn = on end)
	toggle(PlayerTab, "InfJump", "Infinite jumps", false)
	toggle(PlayerTab, "Fly", "Fly", false)
	slider(PlayerTab, "FlySpeed", "Fly speed", 10, 150, 5, 60)
	note(PlayerTab, "F to fly, space up, ctrl down")

	section(PlayerTab, "Protection")
	toggle(PlayerTab, "AntiFling", "Anti-fling", true)
end

connect(UIS.JumpRequest, function()
	if Options.InfJump.Value then
		local h = hum()
		if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)
connect(UIS.InputBegan, function(i, gpe)
	if not gpe and i.KeyCode == Enum.KeyCode.F then Options.Fly:SetValue(not Options.Fly.Value) end
end)

local defaults = {}
connect(RunService.Heartbeat, function()
	local h, r = hum(), hrp()
	if h then
		if Options.WSOn.Value and not F.moving then h.WalkSpeed = Options.WSValue.Value end
		if Options.JPOn.Value then h.UseJumpPower = true; h.JumpPower = Options.JPValue.Value end
	end
	if Options.GravOn.Value then workspace.Gravity = Options.GravValue.Value end
	if r and Options.Fly.Value and not F.moving then
		local dir = Vector3.zero
		local cf = camera.CFrame
		if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end
		if h and h.MoveDirection.Magnitude > 0 and dir.Magnitude == 0 then dir = h.MoveDirection end
		r.AssemblyLinearVelocity = dir.Magnitude > 0 and dir.Unit * Options.FlySpeed.Value or Vector3.new(0, 0.6, 0)
	end
	if Options.AntiFling.Value and os.clock() - (F.lastFling or 0) > 0.5 then
		F.lastFling = os.clock()
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and p.Character then
				for _, part in ipairs(p.Character:GetChildren()) do
					if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
				end
			end
		end
		if r and not F.moving and not Options.Fly.Value and r.AssemblyLinearVelocity.Magnitude > 250 then
			r.AssemblyLinearVelocity = Vector3.zero
			r.AssemblyAngularVelocity = Vector3.zero
		end
	end
end)

local V = {orig = {}, coinBoxes = {}}
do
	local L = Lighting
	V.orig = {Brightness = L.Brightness, ClockTime = L.ClockTime, FogEnd = L.FogEnd, GlobalShadows = L.GlobalShadows, Ambient = L.Ambient, OutdoorAmbient = L.OutdoorAmbient}
	local function restoreLighting()
		for k, v in pairs(V.orig) do pcall(function() L[k] = v end) end
	end
	V.restore = restoreLighting

	section(VisualTab, "World")
	toggle(VisualTab, "Fullbright", "Fullbright", false, function(on) if not on then restoreLighting() end end)
	toggle(VisualTab, "NoFog", "No fog", false, function(on) if not on then L.FogEnd = V.orig.FogEnd end end)
	toggle(VisualTab, "TimeOn", "Custom time of day", false, function(on) if not on then L.ClockTime = V.orig.ClockTime end end)
	slider(VisualTab, "TimeValue", "Time of day", 0, 24, 0.5, 14, " h")
	toggle(VisualTab, "Shaders", "Shaders (bloom + color)", false, function(on)
		if V.fx then for _, o in ipairs(V.fx) do o:Destroy() end V.fx = nil end
		if on then
			V.fx = {
				make("BloomEffect", {Parent = L, Intensity = 0.6, Size = 30, Threshold = 1.4}),
				make("ColorCorrectionEffect", {Parent = L, Saturation = 0.18, Contrast = 0.12, Brightness = 0.02}),
				make("SunRaysEffect", {Parent = L, Intensity = 0.06, Spread = 0.8}),
			}
		end
	end)

	section(VisualTab, "Camera")
	toggle(VisualTab, "FOVOn", "Custom FOV", false, function(on) if not on then camera.FieldOfView = 70 end end)
	slider(VisualTab, "FOVValue", "Field of view", 50, 120, 1, 90)

	section(VisualTab, "Coins & you")
	toggle(VisualTab, "CoinESP", "Coin ESP", false)
	toggle(VisualTab, "SelfChams", "Self chams", false)
	toggle(VisualTab, "Trail", "Movement trail", false)
end

connect(RunService.RenderStepped, function()
	local L = Lighting
	if Options.Fullbright.Value then
		L.Brightness, L.GlobalShadows = 2, false
		L.Ambient, L.OutdoorAmbient = Color3.fromRGB(170, 170, 170), Color3.fromRGB(170, 170, 170)
	end
	if Options.NoFog.Value then L.FogEnd = 1e6 end
	if Options.TimeOn.Value then L.ClockTime = Options.TimeValue.Value end
	if Options.FOVOn.Value then camera.FieldOfView = Options.FOVValue.Value end
end)

local espFolder = make("Folder", {Parent = gui, Name = "ESP"})
task.spawn(function()
	while gui.Parent do
		pcall(function()

			local want = {}
			if Options.CoinESP.Value then
				local cc = coinContainer()
				if cc then
					for _, c in ipairs(cc:GetChildren()) do
						if c:IsA("BasePart") and c:FindFirstChildOfClass("TouchTransmitter") then want[c] = true end
					end
				end
			end
			for coin, box in pairs(V.coinBoxes) do
				if not want[coin] then box:Destroy() V.coinBoxes[coin] = nil end
			end
			for coin in pairs(want) do
				if not V.coinBoxes[coin] then
					V.coinBoxes[coin] = make("BoxHandleAdornment", {Parent = espFolder, Adornee = coin, Size = Vector3.new(1.4, 1.4, 1.4), AlwaysOnTop = true, ZIndex = 5, Transparency = 0.25, Color3 = T.Accent})
				end
			end

			local c = char()
			local hl = c and c:FindFirstChild("AxiomChams")
			if Options.SelfChams.Value and c then
				if not hl then hl = make("Highlight", {Name = "AxiomChams", Parent = c, FillTransparency = 0.55, OutlineTransparency = 0, DepthMode = Enum.HighlightDepthMode.Occluded}) end
				hl.FillColor, hl.OutlineColor = T.Accent, T.Accent
			elseif hl then hl:Destroy() end

			local r = hrp()
			local tr = r and r:FindFirstChild("AxiomTrail")
			if Options.Trail.Value and r then
				if not tr then
					local a0 = make("Attachment", {Name = "AxiomTrailA0", Parent = r, Position = Vector3.new(0, 1, 0)})
					local a1 = make("Attachment", {Name = "AxiomTrailA1", Parent = r, Position = Vector3.new(0, -1, 0)})
					tr = make("Trail", {Name = "AxiomTrail", Parent = r, Attachment0 = a0, Attachment1 = a1, Lifetime = 0.6, LightEmission = 0.6,
						Transparency = NumberSequence.new(0.2, 1), WidthScale = NumberSequence.new(1, 0)})
				end
				tr.Color = ColorSequence.new(T.Accent)
			elseif tr then
				tr:Destroy()
				for _, n in ipairs({"AxiomTrailA0", "AxiomTrailA1"}) do local a = r:FindFirstChild(n) if a then a:Destroy() end end
			end
		end)
		task.wait(0.3)
	end
end)

local function serverList(order)
	local ok, body = pcall(function()
		return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=" .. order .. "&limit=100")
	end)
	if not ok then return {} end
	local ok2, data = pcall(function() return HttpService:JSONDecode(body) end)
	return ok2 and data and data.data or {}
end
local function hop(small)
	notify("info", small and "Small server" or "Server hop", "Searching…")
	local list = serverList(small and "Asc" or "Desc")
	local pick
	for _, s in ipairs(list) do
		if s.id ~= game.JobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers - 1 and (not small or s.playing > 0) then
			pick = s
			break
		end
	end
	if not pick then notify("warn", "No server", "no servers found") return end
	TeleportService:TeleportToPlaceInstance(game.PlaceId, pick.id, player)
end
do
	section(ServerTab, "Server")
	button(ServerTab, "Rejoin server", "Same server", function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end)
	button(ServerTab, "Server hop", "another server", function() hop(false) end)
	button(ServerTab, "Join small server", "Fewest players", function() hop(true) end)
	button(ServerTab, "Copy Job ID", game.JobId ~= "" and game.JobId or "—", function()
		if setclipboard then setclipboard(game.JobId) notify("success", "Copied", "Job ID copied.") end
	end)
	local jobBox = input(ServerTab, "JoinJob", "Join Job ID", "paste a Job ID")
	jobBox.NoSave = true
	button(ServerTab, "Join that server", nil, function()
		local id = trim(Options.JoinJob.Value)
		if id ~= "" then TeleportService:TeleportToPlaceInstance(game.PlaceId, id, player) end
	end)

	section(ServerTab, "Staying online")
	toggle(ServerTab, "AutoRejoin", "Auto rejoin when kicked", true)
	note(ServerTab, "anti afk is always on")
end

do
	local rejoining = false
	local function rejoin()
		if rejoining or not Options.AutoRejoin.Value then return end
		rejoining = true
		task.wait(3)
		while true do
			pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
			task.wait(15)
		end
	end
	pcall(function()
		local overlay = game:GetService("CoreGui"):FindFirstChild("RobloxPromptGui")
		overlay = overlay and overlay:FindFirstChild("promptOverlay")
		if overlay then
			connect(overlay.ChildAdded, function(c)
				if c.Name == "ErrorPrompt" then task.spawn(rejoin) end
			end)
		end
	end)
end

local P = {}
do
	section(SettingsTab, "Performance (for alts)")
	toggle(SettingsTab, "NoRender", "Disable 3D rendering", false, function(on) pcall(function() RunService:Set3dRenderingEnabled(not on) end) end)
	toggle(SettingsTab, "FPSCapOn", "FPS cap", false, function(on) if setfpscap then pcall(setfpscap, on and Options.FPSCap.Value or 240) end end)
	slider(SettingsTab, "FPSCap", "FPS cap value", 5, 60, 5, 15, " fps", function(v) if Options.FPSCapOn and Options.FPSCapOn.Value and setfpscap then pcall(setfpscap, v) end end)
	toggle(SettingsTab, "LowGfx", "Low graphics", false, function(on)
		if not on then return end
		pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
		for _, d in ipairs(workspace:GetDescendants()) do
			if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") then d.Enabled = false
			elseif d:IsA("Decal") or d:IsA("Texture") then d.Transparency = 1 end
		end
		Lighting.GlobalShadows = false
	end)
	toggle(SettingsTab, "SkipIntro", "Skip intro animation", false)

	section(SettingsTab, "Discord webhook")
	toggle(SettingsTab, "WebhookOn", "Send stats to Discord", true)
	input(SettingsTab, "WebhookURL", "Webhook URL", "https://discord.com/api/webhooks/…")
	if Options.WebhookURL.Value == "" then Options.WebhookURL:SetValue(DEFAULT_HOOK, true) end
	slider(SettingsTab, "WebhookEvery", "Send every", 5, 120, 5, 30, " min")
	button(SettingsTab, "Send test message", nil, function() P.sendHook(true) end)
	button(SettingsTab, "Send all accounts now", nil, function() P.writeMine() P.sendAll() end)

	section(SettingsTab, "Look")
	colorPicker(SettingsTab, "AccentColor", "Accent color", "#8E9A4E")
	toggle(SettingsTab, "ShowFloatButton", "Show floating button", true, function(on) if floatButton then floatButton.Visible = on end end)
	button(SettingsTab, "Unload hub", nil, function() app.Destroy() end)
end

function P.sendHook(test)
	local url = trim(Options.WebhookURL.Value)
	if url == "" then notify("warn", "Webhook", "paste url first") return end
	local el = os.clock() - stats.started
	local rate = el > 60 and math.floor(stats.coins / el * 3600) or 0
	local body = HttpService:JSONEncode({
		username = APP_NAME,
		embeds = {{
			title = (test and "Test · " or "") .. "MM2 farm · " .. player.Name,
			color = tonumber(string.format("%02X%02X%02X", T.Accent.R * 255, T.Accent.G * 255, T.Accent.B * 255), 16),
			fields = {
				{name = "Session", value = fmtTime(el), inline = true},
				{name = "Coins", value = tostring(stats.coins), inline = true},
				{name = "Coins / hour", value = tostring(rate), inline = true},
				{name = "Rounds", value = tostring(stats.rounds), inline = true},
				{name = "Full bags", value = tostring(stats.bags), inline = true},
				{name = "Players in server", value = tostring(#Players:GetPlayers()), inline = true},
				{name = "By coin type", value = (function() local t = {} for k, v in pairs(stats.kinds or {}) do table.insert(t, k .. ": " .. v) end return #t > 0 and table.concat(t, "\n") or "—" end)(), inline = false},
			},
			footer = {text = APP_NAME .. " · by " .. AUTHOR},
		}},
	})
	local ok = httpRequest({Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = body})
	if test then notify(ok and "success" or "error", "Webhook", ok and "Sent." or "Couldn't send.") end
end

P.dir = CONFIG_DIR .. "/mm2_stats"
function P.writeMine()
	if not canFiles then return end
	pcall(function()
		if not isfolder(P.dir) then makefolder(P.dir) end
		local el = os.clock() - stats.started
		writefile(P.dir .. "/" .. player.Name .. ".json", HttpService:JSONEncode({name = player.Name, coins = stats.coins, rounds = stats.rounds, bags = stats.bags, el = el, at = os.time(), kinds = stats.kinds}))
	end)
end
function P.readAll()
	local list = {}
	pcall(function()
		for _, f in ipairs(listfiles(P.dir)) do
			local ok, d = pcall(function() return HttpService:JSONDecode(readfile(f)) end)
			if ok and type(d) == "table" and os.time() - (d.at or 0) < 180 then table.insert(list, d) end
		end
	end)
	table.sort(list, function(x, y) return x.name < y.name end)
	return list
end
function P.sendAll()
	local url = trim(Options.WebhookURL.Value)
	if url == "" then return end
	local list = P.readAll()
	if #list == 0 then return end
	local lines, total, totalRate = {}, 0, 0
	for _, d in ipairs(list) do
		local rate = d.el > 60 and math.floor(d.coins / d.el * 3600) or 0
		total += d.coins
		totalRate += rate
		table.insert(lines, string.format("`%s` — %d coins · %d/h · %d bags", d.name, d.coins, rate, d.bags))
	end
	local body = HttpService:JSONEncode({
		username = APP_NAME,
		embeds = {{
			title = "MM2 farm · " .. #list .. " accounts",
			description = table.concat(lines, "\n"),
			color = tonumber(string.format("%02X%02X%02X", T.Accent.R * 255, T.Accent.G * 255, T.Accent.B * 255), 16),
			fields = {{name = "Total coins", value = tostring(total), inline = true}, {name = "Total per hour", value = tostring(totalRate), inline = true}},
			footer = {text = APP_NAME .. " · by " .. AUTHOR},
		}},
	})
	httpRequest({Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = body})
end
task.spawn(function()
	local last = os.clock()
	while gui.Parent do
		P.writeMine()
		task.wait(20)
		if Options.WebhookOn.Value and os.clock() - last >= Options.WebhookEvery.Value * 60 then
			last = os.clock()
			local list = P.readAll()

			if #list == 0 then pcall(P.sendHook, false)
			elseif list[1].name == player.Name then pcall(P.sendAll) end
		end
	end
end)

local visible, hintShown = true, false
local function setVisible(v)
	visible = v
	if v then
		main.Visible = true
		mainScale.Scale = 0.94
		tween(mainScale, {Scale = 1}, 0.3, Enum.EasingStyle.Back)
	else
		tween(mainScale, {Scale = 0.94}, 0.15)
		task.delay(0.15, function() if not visible then main.Visible = false end end)
	end
end
app.setVisible = setVisible
topButton(top, "–", -42, function()
	setVisible(false)
	if not hintShown then
		hintShown = true
		notify("info", "Window hidden", "press End to open")
	end
end)
topButton(top, "×", -12, function() app.Destroy() end)
connect(UIS.InputBegan, function(i, gpe)
	if not gpe and i.KeyCode == Enum.KeyCode.End then setVisible(not visible) end
end)

do
	floatButton = make("TextButton", {
		Parent = gui, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 18, 0.5, 0), Size = UDim2.fromOffset(52, 52),
		BackgroundColor3 = Color3.fromRGB(22, 24, 18), BackgroundTransparency = 0.02, AutoButtonColor = false, Text = "", ZIndex = 20,
	}, {corner(12)})
	accent(make("UIStroke", {Parent = floatButton, Thickness = 1.5, Transparency = 0.45, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}), "Color")
	app.drawMark(floatButton, 40, 21)
	local sc = make("UIScale", {Parent = floatButton})
	connect(floatButton.MouseEnter, function() tween(sc, {Scale = 1.08}, 0.2, Enum.EasingStyle.Back) end)
	connect(floatButton.MouseLeave, function() tween(sc, {Scale = 1}, 0.2) end)
	local downPos, startPos, dragging
	connect(floatButton.InputBegan, function(i)
		if i.UserInputType == MB1 or i.UserInputType == TOUCH then
			downPos, startPos, dragging = i.Position, floatButton.Position, false
		end
	end)
	connect(UIS.InputChanged, function(i)
		if downPos and (i.UserInputType == MOVE or i.UserInputType == TOUCH) then
			local d = i.Position - downPos
			if d.Magnitude > 6 then dragging = true end
			if dragging then floatButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y) end
		end
	end)
	connect(UIS.InputEnded, function(i)
		if downPos and (i.UserInputType == MB1 or i.UserInputType == TOUCH) then
			if not dragging then setVisible(not visible) end
			downPos = nil
		end
	end)
end

function app.Destroy()
	app.alive = false
	Options.AutoFarm.Value = false
	stopMove()
	noclipOn = false
	for _, c in ipairs(app.connections) do pcall(function() c:Disconnect() end) end
	pcall(V.restore)
	if V.fx then for _, o in ipairs(V.fx) do pcall(function() o:Destroy() end) end end
	pcall(function() RunService:Set3dRenderingEnabled(true) end)
	pcall(function() workspace.Gravity = 196.2 end)
	pcall(function()
		local c = char()
		if c and c:FindFirstChild("AxiomChams") then c.AxiomChams:Destroy() end
		local r = hrp()
		if r then for _, n in ipairs({"AxiomTrail", "AxiomTrailA0", "AxiomTrailA1"}) do local o = r:FindFirstChild(n) if o then o:Destroy() end end end
	end)
	if gui.Parent then
		tween(mainScale, {Scale = 0.9}, 0.15)
		task.delay(0.15, function() gui:Destroy() end)
	end
	if env.__AxiomMM2 == app then env.__AxiomMM2 = nil end
end

do
	if canFiles and isfile(LAST_FILE) then
		local ok, data = pcall(function() return HttpService:JSONDecode(readfile(LAST_FILE)) end)
		if ok and type(data) == "table" then applyData(data) end
	end
	loading = false
	for k, v in pairs(AXIOM_CONFIG) do
		if Options[k] and type(v) == type(Options[k].Value) then pcall(Options[k].SetValue, Options[k], v, true) end
	end
	if Options.AltMode.Value and Options.AltMode.Callback then task.spawn(Options.AltMode.Callback, true) end
	if Options.FarmSpeed.Value > 26 then Options.FarmSpeed:SetValue(22, true) end
	if Options.FullBag.Value ~= "Do nothing" then Options.FullBag:SetValue("Reset (faster rounds)", true) end
	if trim(Options.WebhookURL.Value) == "" then Options.WebhookURL:SetValue(DEFAULT_HOOK, true) end
	noclipOn = Options.Noclip.Value
	floatButton.Visible = Options.ShowFloatButton.Value
	if Options.NoRender.Value then pcall(function() RunService:Set3dRenderingEnabled(false) end) end
	if Options.FPSCapOn.Value and setfpscap then pcall(setfpscap, Options.FPSCap.Value) end
	for _, flag in ipairs({"Shaders", "LowGfx"}) do
		if Options[flag].Value and Options[flag].Callback then task.spawn(Options[flag].Callback, true) end
	end
end

task.spawn(function()
	while gui.Parent do
		local el = os.clock() - stats.started
		homeRows.time.SetDesc(fmtTime(el))
		homeRows.coins.SetDesc(tostring(stats.coins))
		homeRows.rate.SetDesc(el > 60 and tostring(math.floor(stats.coins / el * 3600)) or "…")
		homeRows.rounds.SetDesc(stats.rounds .. " / " .. stats.bags)
		homeRows.state.SetDesc(stats.state)
		status.Text = string.format("%s  ·  <b>%d/%d</b>", stats.state, stats.cur, stats.max)
		task.wait(1)
	end
end)

main.Visible = false
selectTab(HomeTab)
if Options.AltMode.Value then
	setVisible(false)
elseif Options.SkipIntro.Value then
	setVisible(true)
else
	task.spawn(function()
		Axiom.play({accent = T.Accent, steps = {"Loading Murder Mystery 2…", "Coins & rounds", "Ready"}, tagline = "MURDER MYSTERY 2  ·  BY " .. string.upper(AUTHOR), onDone = function() setVisible(true) end})
	end)
end
notify("success", APP_NAME .. " loaded", Options.AutoFarm.Value and "Auto farm is on." or "End to hide")
end

runHub()

end

if game.PlaceId == OUWIGAHARA_PLACE then AxiomOuwigahara()
elseif game.PlaceId == MM2_PLACE then AxiomMM2()
else AxiomMenu() end
