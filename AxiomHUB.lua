
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
local OUWLAND_PLACE = 136406881576517

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
local OUWLAND_PLACE_ID = 136406881576517
local IS_OUWLAND = game.PlaceId == OUWLAND_PLACE_ID
if game.PlaceId ~= MENU_PLACE_ID and not IS_OUWLAND then
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
label({Parent = top, Position = UDim2.fromOffset(42, 25), Size = UDim2.fromOffset(200, 14), Text = IS_OUWLAND and "Ouwland" or "Main Menu", Font = FONT, TextSize = 11, TextColor3 = T.SubText})
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
local QueueSignal = not IS_OUWLAND and tryRequire(function() return RS.Communication.ServerAndClient.Signals.QueueSignal end)
local Worlds = not IS_OUWLAND and tryRequire(function() return RS.CAM.Worlds end)
local Teleporter = not IS_OUWLAND and tryRequire(function() return RS.CAM.Client.Modules.Teleporter end)
local PartyWatcher = not IS_OUWLAND and tryRequire(function() return RS.CAM.Client.Modules.PartyWatcher end)
local QueuWatcher = not IS_OUWLAND and tryRequire(function() return RS.MenuComponents.Misc.QueuWatcher end)
local DataValue = not IS_OUWLAND and tryRequire(function() return RS.CAM.Client.Modules.DataValue end)
local SettingsKeys = not IS_OUWLAND and tryRequire(function() return RS.CAM.Global.Subsets.Gameplay.SettingsKeys end)
local Validators = not IS_OUWLAND and tryRequire(function() return RS.CAM.Global.MainMenuRelay.Validators end)

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
if IS_OUWLAND then
	for _, t in ipairs({SpinTab, OuwTab, ServerTab, HookTab}) do t.button.Visible = false end
end

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
label({Parent = credit, Position = UDim2.fromOffset(46, 10), Size = UDim2.new(1, -60, 0, 18), Text = APP_NAME .. (IS_OUWLAND and " · Ouwland" or " · Main Menu"), Font = FONT_B, TextSize = 14})
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
	if IS_OUWLAND then return end
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
		if not IS_OUWLAND and isfile("AxiomHUB/requeue.flag") then
			local t = tonumber(readfile("AxiomHUB/requeue.flag")) or 0
			delfile("AxiomHUB/requeue.flag")
			if os.time() - t < 900 and Options.AutoQueue then Options.AutoQueue:SetValue(true, true) end
		end
	end)
	setPartyPanel(Options.ShowPartyPanel.Value)
	if env.__AxiomSetAntiAFK then env.__AxiomSetAntiAFK(Options.AntiAFK.Value) end
end

if Options.AutoJoinPrivate.Value and not IS_OUWLAND then
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
		if Options.AutoQueue.Value and not IS_OUWLAND then
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
		if tickCount % 10 == 0 and not IS_OUWLAND and Options.AutoBuyOre.Value and not running and not converting then
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

local function AxiomOuwland()

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

local OUWLAND_ID = 136406881576517
if game.PlaceId ~= OUWLAND_ID then
	warn("[AxiomHUB] The Ouwland module works only in Ouwland.")
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

for _, key in ipairs({"__AxiomOuwland", "__AxiomHUB"}) do
	if env[key] then pcall(env[key].Destroy) env[key] = nil end
end
local app = {connections = {}}
env.__AxiomOuwland = app
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
local LAST_FILE = CONFIG_DIR .. "/ouwland.json"
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
		local ok, json = pcall(HttpService.JSONEncode, HttpService, collect())
		if ok and type(json) == "string" and #json > 2 then pcall(writefile, LAST_FILE, json) end
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

local gui = make("ScreenGui", {Name = "AxiomHUB_Ouwland", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true, DisplayOrder = 50})
pcall(function()
	for _, c in ipairs(((gethui and gethui()) or game:GetService("CoreGui")):GetChildren()) do
		if c.Name == "AxiomHUB_Ouwland" or c.Name == "AxiomHUB" then c:Destroy() end
	end
end)
if not pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end) or not gui.Parent then
	gui.Parent = player:WaitForChild("PlayerGui")
end

local main = make("Frame", {
	Parent = gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(780, 500), BackgroundColor3 = T.Bg, BackgroundTransparency = 0.08, BorderSizePixel = 0,
}, {corner(12)})
accent(make("UIStroke", {Parent = main, Transparency = 0.65, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}), "Color")
local mainScale = make("UIScale", {Parent = main, Scale = 0.94})

local top = make("Frame", {Parent = main, Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1})
app.drawMark(make("Frame", {Parent = top, Position = UDim2.fromOffset(6, 7), Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1}), 28, 2)
label({Parent = top, Position = UDim2.fromOffset(42, 8), Size = UDim2.fromOffset(200, 18), Text = APP_NAME, Font = FONT_B, TextSize = 15})
label({Parent = top, Position = UDim2.fromOffset(42, 25), Size = UDim2.fromOffset(200, 14), Text = "Ouwland", Font = FONT, TextSize = 11, TextColor3 = T.SubText})
local status = label({
	Parent = top, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -80, 0, 0), Size = UDim2.new(0, 420, 1, 0),
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
	elseif key == "skull" then
		ring(9, 7, 12)
		dot(6.5, 7, 3, true) dot(11.5, 7, 3, true)
		fill(6, 13, 6, 4, nil, 1)
	elseif key == "scroll" then
		box(3, 2, 12, 14, nil, 2)
		fill(6, 6, 6, 2, true, 1)
		fill(6, 10, 6, 2, nil, 1)
	elseif key == "globe" then
		ring(9, 9, 14)
		fill(2, 8, 14, 2, nil, 1)
		ring(9, 9, 6, true)
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
	if tab.grow then tab.grow(height + 4) end
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
	if tab.grow then tab.grow(28) end
	accent(label({Parent = tab.container, LayoutOrder = nextOrder(tab), Size = UDim2.new(1, 0, 0, 24), Text = string.upper(text), Font = FONT_B, TextSize = 11, TextYAlignment = Enum.TextYAlignment.Bottom}), "TextColor3")
end

local function note(tab, text, height)
	if tab.grow then tab.grow((height or 30) + 4) end
	return label({Parent = tab.container, LayoutOrder = nextOrder(tab), Size = UDim2.new(1, 0, 0, height or 30), Text = text, Font = FONT, TextSize = 12, TextColor3 = T.SubText, TextWrapped = true, RichText = true, TextYAlignment = Enum.TextYAlignment.Top})
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

local function columns(tab)
	if tab.cols then return tab.cols end
	local row = make("Frame", {Parent = tab.container, LayoutOrder = nextOrder(tab), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1})
	local cols = {}
	for i = 1, 2 do
		cols[i] = {
			frame = make("Frame", {Parent = row, Position = UDim2.new((i - 1) * 0.5, i == 2 and 4 or 0, 0, 0), Size = UDim2.new(0.5, -4, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, {
				make("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}),
			}),
			est = 0, order = 0,
		}
	end
	tab.cols = cols
	return cols
end

local function card(tab, title, opts)
	opts = opts or {}
	local cols = columns(tab)
	local col = opts.side and cols[opts.side] or (cols[1].est <= cols[2].est and cols[1] or cols[2])
	col.order += 1
	local box = make("Frame", {Parent = col.frame, LayoutOrder = col.order, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.Surface, BackgroundTransparency = 0.1}, {
		corner(10),
		make("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}),
	})
	local bs = stroke(T.Stroke, 0.55); bs.Parent = box
	local head = make("Frame", {Parent = box, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1})
	accent(make("Frame", {Parent = head, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.fromOffset(5, 5), Rotation = 45, BorderSizePixel = 0}), "BackgroundColor3")
	accent(label({Parent = head, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -74, 1, 0), Text = string.upper(title), Font = FONT_B, TextSize = 11, TextTruncate = Enum.TextTruncate.AtEnd}), "TextColor3")
	local badge
	if opts.priority then
		badge = label({Parent = head, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(56, 18), Text = "", Font = FONT_B, TextSize = 10, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Center, BackgroundColor3 = T.Element, BackgroundTransparency = 0.2})
		corner(6).Parent = badge
	end
	local inner = make("Frame", {Parent = box, Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, {
		make("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}),
	})
	local c = {container = inner, order = 0, box = box, col = col, badge = badge, stroke = bs}
	col.est += 42
	c.grow = function(h) col.est += h end
	return c
end

local function cardNote(c, text, height)
	return note(c, text, height or 28)
end

local Farms = {list = {}, active = nil, reason = "", status = "Idle"}
app.Farms = Farms

function Farms.add(def)
	def.priority = def.priority or 5
	table.insert(Farms.list, def)
	return def
end

function Farms.prio(f)
	local o = f.prioFlag and Options[f.prioFlag]
	return o and tonumber(o.Value) or f.priority
end

function Farms.pick()
	local best, bestP
	for _, f in ipairs(Farms.list) do
		local okE, on = pcall(f.enabled)
		if okE and on then
			local ok, has = pcall(f.ready)
			local p = Farms.prio(f)
			if ok and has and (not best or p < bestP) then best, bestP = f, p end
		end
	end
	return best
end

local function priorityBox(c, flag, default, farm)
	local o = slider(c, flag, "Priority (1 = first)", 1, 10, 1, default, nil, function(v)
		if farm then farm.priority = v end
		if c.badge then c.badge.Text = "P" .. v end
	end)
	return o
end

local Overlay = {}
function Overlay.build(lines)
	local f = make("Frame", {Parent = gui, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(10, 11, 9), Visible = false, ZIndex = 40})
	make("Frame", {Parent = f, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0, BorderSizePixel = 0, ZIndex = 40}, {
		make("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(26, 28, 22), Color3.fromRGB(8, 9, 7)), Rotation = 90}),
	})
	local center = make("Frame", {Parent = f, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(460, 330), BackgroundTransparency = 1, ZIndex = 41})
	local mark = make("Frame", {Parent = center, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.fromOffset(96, 96), BackgroundTransparency = 1, ZIndex = 41})
	app.drawMark(mark, 92, 42)
	local hubHex = string.format("#%02X%02X%02X", T.Accent.R * 255, T.Accent.G * 255, T.Accent.B * 255)
	Overlay.title = label({Parent = center, Position = UDim2.fromOffset(0, 104), Size = UDim2.new(1, 0, 0, 34), Text = 'Axiom<font color="' .. hubHex .. '">HUB</font>', RichText = true, Font = FONT_B, TextSize = 30, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 41})
	Overlay.sub = label({Parent = center, Position = UDim2.fromOffset(0, 138), Size = UDim2.new(1, 0, 0, 16), Text = "RENDERING PAUSED  ·  FARMING", Font = FONT, TextSize = 11, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 41})
	local grid = make("Frame", {Parent = center, Position = UDim2.fromOffset(0, 170), Size = UDim2.new(1, 0, 0, 150), BackgroundTransparency = 1, ZIndex = 41}, {
		make("UIGridLayout", {CellSize = UDim2.new(0.333, -6, 0, 58), CellPadding = UDim2.fromOffset(8, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}),
	})
	local vals = {}
	for i, name in ipairs(lines) do
		local tile = make("Frame", {Parent = grid, LayoutOrder = i, BackgroundColor3 = T.Element, BackgroundTransparency = 0.2, ZIndex = 41}, {corner(10)})
		local s = stroke(T.Stroke, 0.6); s.Parent = tile
		label({Parent = tile, Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -20, 0, 14), Text = name, Font = FONT, TextSize = 11, TextColor3 = T.SubText, ZIndex = 42})
		vals[name] = accent(label({Parent = tile, Position = UDim2.fromOffset(10, 24), Size = UDim2.new(1, -20, 0, 26), Text = "…", Font = FONT_B, TextSize = 18, ZIndex = 42, TextTruncate = Enum.TextTruncate.AtEnd}), "TextColor3")
	end
	local back = make("TextButton", {Parent = f, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -40), Size = UDim2.fromOffset(200, 40),
		BackgroundColor3 = T.Element, BackgroundTransparency = 0.1, Text = "Show game", Font = FONT_B, TextSize = 14, TextColor3 = T.Text, AutoButtonColor = false, ZIndex = 43}, {corner(10)})
	local bs = stroke(T.Accent, 0.3); bs.Parent = back
	accent(bs, "Color")
	connect(back.MouseEnter, function() tween(back, {TextColor3 = T.Accent}) end)
	connect(back.MouseLeave, function() tween(back, {TextColor3 = T.Text}) end)
	connect(back.MouseButton1Click, function()
		if Options.NoRender then Options.NoRender:SetValue(false) end
		Overlay.set(false)
	end)
	Overlay.frame, Overlay.vals = f, vals
	return f
end

function Overlay.set(on)
	if not Overlay.frame then return end
	Overlay.frame.Visible = on
	pcall(function() game:GetService("RunService"):Set3dRenderingEnabled(not on) end)
end

function Overlay.update(values)
	if not (Overlay.frame and Overlay.frame.Visible) then return end
	for k, v in pairs(values) do
		if Overlay.vals[k] then Overlay.vals[k].Text = tostring(v) end
	end
end

local function runHub()

local alive = true
local RunService = game:GetService("RunService")
local CS = game:GetService("CollectionService")
local function tryRequire(path)
	local ok, m = pcall(function() return require(path()) end)
	return ok and m or nil
end
local M = {}
M.SignalEvent = tryRequire(function() return RS.Communication.ServerAndClient.Signals.SignalEvent end)
M.SignalFunction = tryRequire(function() return RS.Communication.ServerAndClient.Signals.SignalFunction end)
M.Platform = tryRequire(function() return RS.CAM.Client.Controllers.Platform_Handler end)
M.SkillCtl = tryRequire(function() return RS.CAM.Client.Controllers.Skill_Controller end)
M.SkillsMod = tryRequire(function() return RS.CAM.Global.Skills_Module end)
M.Utility = tryRequire(function() return RS.CAM.Global.Utility end)
M.GameSettings = tryRequire(function() return RS.CAM.Global.gameSettings end)
M.PlayerProfile = tryRequire(function() return RS.CAM.Global.PlayerProfile end)
M.Clans = tryRequire(function() return RS.CAM.Clans end)
M.DoubleJump = tryRequire(function() return RS.Skills.Misc["Double Jump"] end)
M.Quests = tryRequire(function() return RS.CAM.Global.Subsets.Gameplay.Quests end)
M.BossHunts = tryRequire(function() return RS.CAM.Global.Subsets.Gameplay.Quests.BossHunts end)
M.InCombat = tryRequire(function() return RS.CAM.Global.Subsets.Gameplay.InCombat end)
M.Archives = tryRequire(function() return RS.CAM.Client.Modules.Archives end)
M.Regions = tryRequire(function() return RS.Regions end)
M.InputHandler = tryRequire(function() return RS.CAM.Client.Components.Client.InputHandler end)
M.RunHandler = tryRequire(function() return RS.CAM.Client.Modules.GamePlay.Run_Handler end)
M.Caps = tryRequire(function() return RS.CAM.Global.Caps end)
M.CIP = tryRequire(function() return RS.CAM:FindFirstChild("Character_info_provider", true) end)
pcall(function() M.Controls = require(player.PlayerScripts:WaitForChild("PlayerModule", 5)):GetControls() end)
pcall(function()
	for _, d in ipairs(RS.CAM.Global:GetDescendants()) do
		if d.Name == "Stats" and d:IsA("ModuleScript") then M.StatsMod = require(d) break end
	end
end)

local function getChar() return player.Character end
local function getRoot() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c = getChar() return c and c:FindFirstChildOfClass("Humanoid") end
local dataCache
local function getData(fresh)
	if dataCache and dataCache.Parent and not fresh then return dataCache end
	if not M.Utility then return nil end
	local ok, d = isolated(M.Utility.GetData, player, fresh)
	if ok and typeof(d) == "Instance" then dataCache = d end
	return dataCache
end
local function fmtNum(n)
	local s = tostring(math.floor(tonumber(n) or 0))
	local neg = s:sub(1, 1) == "-"
	if neg then s = s:sub(2) end
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	return (neg and "-" or "") .. out
end
local function posOf(inst)
	if typeof(inst) == "Vector3" then return inst end
	if typeof(inst) == "CFrame" then return inst.Position end
	if typeof(inst) ~= "Instance" then return nil end
	if inst:IsA("BasePart") then return inst.Position end
	if inst:IsA("Attachment") then return inst.WorldPosition end
	if inst:IsA("Model") then local ok, p = pcall(function() return inst:GetPivot().Position end) return ok and p or nil end
	return nil
end

local logQueue = {}
local dbg = {history = {}, kills = 0, casts = 0, fails = 0, deaths = 0, loot = 0, quests = 0, bosses = 0, heals = 0, hits = 0, blocks = 0, stuns = 0,
	lastStunAt = 0, refusedRow = {}, skillStats = {}, fps = 60, file = CONFIG_DIR .. "/ouwland_log.txt", startWen = nil, startRep = nil, started = os.time()}
if canFiles then
	pcall(function()
		if not isfolder(CONFIG_DIR) then makefolder(CONFIG_DIR) end
		if isfile(dbg.file) then writefile(CONFIG_DIR .. "/ouwland_log_prev.txt", readfile(dbg.file)) end
		writefile(dbg.file, "=== AxiomHUB Ouwland " .. os.date("%Y-%m-%d %H:%M:%S") .. " ===\n")
	end)
end
local function dlog(kind, text)
	local entry = {kind = kind, text = tostring(text), t = os.date("%H:%M:%S")}
	table.insert(logQueue, entry)
	if #logQueue > 60 then table.remove(logQueue, 1) end
	table.insert(dbg.history, entry)
	if #dbg.history > 300 then table.remove(dbg.history, 1) end
	if canFiles and appendfile then pcall(appendfile, dbg.file, entry.t .. " [" .. kind .. "] " .. entry.text .. "\n") end
end

local W = {groups = {}, byName = {}, byCode = {}, npcs = {}, shrines = {}, regionMods = {}, bossSpots = {}}
do
	local content = RS:FindFirstChild("Ouwland") and RS.Ouwland:FindFirstChild("Content")
	for _, mod in ipairs(content and content:GetChildren() or {}) do
		local ok, r = pcall(require, mod)
		if ok and type(r) == "table" then
			W.regionMods[mod.Name] = r
			for _, n in ipairs(r.Npcs or {}) do
				local so = type(n.SendOver) == "table" and n.SendOver or {}
				if n.Type == 2 and type(so.Spawning) == "table" then
					local sp = so.Spawning
					local locs = {}
					for _, l in pairs(sp.Locations or {}) do
						local p = posOf(l)
						if p then table.insert(locs, p) end
					end
					local center = posOf(sp.Center) or locs[1]
					if center then
						local g = {name = n.Name, region = mod.Name, sub = n.SubArea, center = center, locs = locs,
							code = type(so.Settings) == "table" and so.Settings.NpcCode or n.Name, boss = so.Boss ~= nil,
							spawnTime = sp.SpawnTime or 60, quantity = n.Quantity or 1, despawn = sp.DespawnDistance or 250}
						table.insert(W.groups, g)
						W.byName[g.name] = g
						W.byCode[g.code] = g
					end
				elseif (n.Type == 1 or n.Type == 3) and n.Spawns then
					local first = n.Spawns[1]
					if type(first) == "table" then first = first[1] end
					local p = posOf(first)
					if p then W.npcs[n.Name] = {name = n.Name, pos = p, region = mod.Name, code = so.Code or n.Name, sub = n.SubArea, walking = n.Type == 3} end
				end
			end
		end
	end
	local SPOTS = {
		Datai = {-167.8, 1045.4, -1135.3}, Gyutai = {-265.1, 1045.7, -1139.5}, Zuko = {-280.3, 1226.6, -1039}, Akazo = {-1130, 1383.4, -1747.4},
		["Serpent Trainee"] = {-273.4, 1294.4, -1534.2}, Reaper = {95.7, 1045.4, -575.6}, Sumari = {396.5, 1020.4, -622}, Yahari = {823.4, 1021.7, -638.4},
		["Water Trainee Sabito"] = {815.1, 1020.6, 100.5}, Giyen = {389.7, 1020.4, -87.4}, Saneri = {-381.7, 1095.8, -423}, Shinora = {-449.8, 966.9, -0.3},
		Rengu = {-711, 967.4, 887}, ["Flame Trainee"] = {-1125.6, 1031.5, 995.4}, Nezura = {-1461.3, 278.4, 936.5}, Fujiko = {-2461.7, 40.3, 1119.8},
		["Insect Trainee"] = {-1392.4, 263.9, 68}, ["Soryu Trainee Goki"] = {-424.8, 291.2, 542.5}, Enru = {822.5, 798, 547.5}, Kaiden = {584, 1149, -1308},
		Obari = {767.3, 1123.4, -1045.2}, Zentaro = {1331.2, 823.4, -1019.9}, Gyorei = {2576.9, 1091.4, -741.4}, ["Stone Trainee"] = {2685.5, 1075.9, -566.7},
		["Thunder Trainee"] = {2423.5, 1076.1, -558.3}, ["Mother Bear"] = {544.3, 1123.4, -1026.1}, Tengai = {-132.2, 1351.4, -2631.1}, Domae = {-297.6, 1352.9, -3456.7},
		["Wind Trainee"] = {-943.5, 1383.4, -2635.2}, ["Reaper Trainee Kuzan"] = {-1219.1, 1376.6, -3032.5}, ["Sound Trainee"] = {191.1, 1351.4, -2579.7},
		Hoyuzo = {745.8, 1003.4, -1413.8},
	}
	pcall(function()
		if isfile and isfile("AxiomHUB/ouwland_spots.json") then
			for _, s in ipairs(HttpService:JSONDecode(readfile("AxiomHUB/ouwland_spots.json"))) do
				if type(s) == "table" and s.name and s.x then SPOTS[s.name] = {s.x, s.y, s.z} end
			end
		end
	end)
	for name, p in pairs(SPOTS) do
		local g = W.byName[name]
		if g then
			g.gameCenter = g.center
			g.center = Vector3.new(p[1], p[2], p[3])
		end
	end
	local regions = M.Regions and M.Regions.Regions
	for rname, r in pairs(type(regions) == "table" and regions or {}) do
		for _, s in ipairs(r.Shrines or {}) do
			local p = posOf(s.At)
			if p then table.insert(W.shrines, {name = s.Name, pos = p, region = rname, price = s.Price and s.Price.Wen or 0}) end
		end
	end
end

W.LEVELS = {
	KaruVillageBandit = 1, BearCub = 10, KaidenSub = 26, HoyuzoSub = 40, BeastBornDemon_MistfallHarbor = 47,
	Mizunoto_MistfallHarbor = 62, BloodHoundedDemon_MistfallHarbor = 62, LesserDemon_ButterflyEstate = 75,
	MizunoeDemonSlayer = 75, GreaterDemon_ButterflyEstate = 83, HighDemon = 90, KanoeDemonSlayer = 90,
	IceProfoundDemon = 105, FireProfoundDemon = 115,
}
W.SLAYER_MOBS = {Mizunoto_MistfallHarbor = true, MizunoeDemonSlayer = true, KanoeDemonSlayer = true}

local function playerLevel()
	local d = getData()
	local per = (M.GameSettings and M.GameSettings.expPerLevel) or 60
	return d and math.floor(d.Exp.Goal.Value / per) or 0
end
local function playerRace()
	local d = getData()
	return d and d.Race.Value or "?"
end
local function isSlayerSide()
	local r = playerRace()
	return r == "Slayer" or r == "Human" or r == "Hybrid"
end
local function isDemonSide()
	local r = playerRace()
	return r == "Demon" or r == "Hybrid"
end

local E = {}
E.enemyCache, E.enemyAt = {}, 0
function E.enemies()
	if os.clock() - E.enemyAt < 0.25 then return E.enemyCache end
	E.enemyAt = os.clock()
	local out = {}
	local H = workspace:FindFirstChild("Humanoids")
	local R = H and H:FindFirstChild("Regions")
	if R then
		for _, hum in ipairs(R:GetDescendants()) do
			if hum:IsA("Humanoid") and hum.Health > 0 then
				local m = hum.Parent
				if m and not Players:GetPlayerFromCharacter(m) then
					local root = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
					if root then
						local folder = m.Parent and m.Parent.Name or ""
						local g = W.byName[folder] or W.byName[m.Name]
						table.insert(out, {model = m, hum = hum, root = root, name = m.Name, folder = folder, group = g, code = g and g.code})
					end
				end
			end
		end
	end
	E.enemyCache = out
	return out
end

E.badTarget = setmetatable({}, {__mode = "k"})
function E.sane(e, root)
	if E.badTarget[e.model] and os.clock() < E.badTarget[e.model] then return false end
	if not root then return true end
	local dy = e.root.Position.Y - root.Position.Y
	if E.target and E.target.model == e.model then return dy > -120 and dy < 120 end
	if e.root.AssemblyLinearVelocity.Y < -60 and dy < -30 then return false end
	return math.abs(dy) <= 80
end
function E.nearest(filter, maxRange, from)
	local root = getRoot()
	from = from or (root and root.Position)
	if not from then return nil end
	local best, bestD
	for _, e in ipairs(E.enemies()) do
		if (not filter or filter(e)) and E.sane(e, root) then
			local d = (e.root.Position - from).Magnitude
			if d <= (maxRange or 1e9) and (not bestD or d < bestD) then best, bestD = e, d end
		end
	end
	return best, bestD
end

E.aimTarget, E.aimOn = nil, false
if M.Platform then
	env.__AxiomOwOrigMousepos = env.__AxiomOwOrigMousepos or env.__AxiomOrigMousepos or M.Platform.mousepos
	local orig = env.__AxiomOwOrigMousepos
	M.Platform.mousepos = function(range, params, skill)
		local t = E.aimTarget
		if E.aimOn and typeof(t) == "Vector3" then
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
function E.restoreAim()
	if M.Platform and env.__AxiomOwOrigMousepos then M.Platform.mousepos = env.__AxiomOwOrigMousepos end
end
function E.targetPos(e)
	local p = e.root.Position
	local v = e.root.AssemblyLinearVelocity
	return p + Vector3.new(v.X, 0, v.Z) * 0.12
end

E.NOT_ATTACKS = {Blocking = true, Dash = true, ["Double Jump"] = true, ["Wall Climb"] = true, ["Flashing Willow Aerial"] = true, ["Compass Needle"] = true}
E.SKILL_TIMES = {
	["Spiraling Shot"] = {hold = 0.25, after = 1.9}, ["Meteor"] = {hold = 3.0, after = 0.4}, ["Spinning Throw"] = {hold = 2.6, after = 0.5},
	["Dunk"] = {hold = 0.35, after = 1.5}, ["Piercing Kick"] = {hold = 0.2, after = 1.7},
}
function E.skillCategory(name)
	local info = M.PlayerProfile and M.PlayerProfile.skill_info and M.PlayerProfile.skill_info[name]
	return info and info.CategoryType
end
function E.availableSkills()
	local list = {}
	if not (M.StatsMod and M.PlayerProfile and M.PlayerProfile.skill_info) then return list end
	for name in pairs(M.PlayerProfile.skill_info) do
		if not E.NOT_ATTACKS[name] then
			local ok, has = pcall(M.StatsMod.SourceCheck, player, name)
			if ok and has then table.insert(list, name) end
		end
	end
	table.sort(list, function(a, b)
		local ea, eb = E.skillCategory(a) == "Evil Art", E.skillCategory(b) == "Evil Art"
		if ea ~= eb then return ea end
		return a < b
	end)
	return list
end
E.skillFail, E.casting, E.skillList = {}, false, {}
function E.getSHC() local c = getChar() return c and c:FindFirstChild("SHC") end
function E.releaseStuck()
	local shc = E.getSHC()
	if shc and shc.Value ~= "" and shc:GetAttribute("en") ~= true and M.SkillCtl then pcall(M.SkillCtl.StopHold, shc.Value) end
end
function E.skillReady(name)
	if not (M.SkillCtl and M.SkillsMod) then return false end
	if E.skillFail[name] and os.clock() - E.skillFail[name] < 3 then return false end
	if M.StatsMod then
		local ok, has = pcall(M.StatsMod.SourceCheck, player, name)
		if ok and not has then return false end
	end
	local ok, r = pcall(M.SkillsMod.Can_Skill, player, name)
	if not ok then return true end
	return r == true
end
function E.updateAim()
	local t = E.target
	if t and t.hum.Health > 0 and t.root.Parent then E.aimTarget = E.targetPos(t) end
end
function E.castSkill(name)
	local t = E.SKILL_TIMES[name]
	local hold, after = t and t.hold or Options.SkillHold.Value, t and t.after or 0.45
	E.casting = true
	E.releaseStuck()
	local done, res = false, nil
	task.spawn(function()
		local ok, r = pcall(M.SkillCtl.Attempt_Hold, name)
		res = ok and r or nil
		done = true
	end)
	local t0 = os.clock()
	while not done and os.clock() - t0 < 6 do E.updateAim() task.wait(0.03) end
	if res == true then
		dbg.casts += 1
		dbg.lastSkill = name
		while os.clock() - t0 < hold do E.updateAim() task.wait(0.05) end
		local t1 = os.clock()
		repeat
			E.updateAim()
			local ok, r = pcall(M.SkillCtl.StopHold, name)
			if ok and r then break end
			local shc = E.getSHC()
			if shc and shc.Value ~= name and shc:GetAttribute("en") ~= true then break end
			task.wait(0.05)
		until os.clock() - t1 > 2.5
		local t2 = os.clock()
		while os.clock() - t2 < after do E.updateAim() task.wait(0.05) end
	else
		E.skillFail[name] = os.clock()
		dbg.fails += 1
		E.releaseStuck()
	end
	E.casting = false
	return res == true
end
function E.castNext()
	local sel = Options.UseSkills and Options.UseSkills.Value
	if type(sel) ~= "table" then return false end
	for _, name in ipairs(E.skillList) do
		if sel[name] and E.skillReady(name) then
			E.castSkill(name)
			return true
		end
	end
	return false
end

E.punchFn = env.__AxiomPunch
task.spawn(function()
	while not E.punchFn and gui.Parent do
		pcall(function()
			for _, f in ipairs(getgc()) do
				if type(f) == "function" then
					local ok, n = pcall(debug.info, f, "n")
					if ok and n == "punch" then
						local src = debug.info(f, "s")
						if tostring(src):find("CU.Combat", 1, true) then
							E.punchFn = f
							env.__AxiomPunch = f
							break
						end
					end
				end
			end
		end)
		if not E.punchFn then task.wait(3) end
	end
end)

E.lastEquipTry = 0
function E.weaponSlot()
	if E.slotOverride then return E.slotOverride end
	local v = Options.WeaponPick and Options.WeaponPick.Value
	return tonumber(type(v) == "string" and v:match("^(%d)")) or 2
end
function E.equipWeapon(force, slot)
	slot = slot or E.weaponSlot()
	if os.clock() - E.lastEquipTry < 2 then return end
	local cfg = player:FindFirstChild("Items_Config")
	local eq = cfg and cfg:FindFirstChild("Equipped")
	if not eq then return end
	if force or eq.Value ~= slot then
		E.lastEquipTry = os.clock()
		if force and eq.Value == slot then eq.Value = 0 task.wait(0.2) end
		eq.Value = slot
	end
end
E.nextPunch, E.punchMisses = 0, 0
function E.punch()
	if not E.punchFn or E.blockWanted or os.clock() < E.nextPunch then return end
	E.equipWeapon(false)
	local wait
	task.spawn(function()
		local ok, r = pcall(E.punchFn)
		wait = ok and r or nil
	end)
	if tonumber(wait) then E.punchMisses = 0 E.lastPunchAt = os.clock() else
		E.punchMisses += 1
		if E.punchMisses >= 8 then E.punchMisses = 0 E.equipWeapon(true) end
	end
	E.nextPunch = os.clock() + math.min(tonumber(wait) or 0.08, 0.35)
end
connect(RunService.Heartbeat, function()
	if not alive or E.moving then return end
	local t = E.hoverTarget
	if not (t and E.hoverConn and t.root.Parent and t.hum.Health > 0) then return end
	local root = getRoot()
	if root and (t.root.Position - root.Position).Magnitude < Options.HoverHeight.Value + 8 then E.punch() end
end)

E.noclipConn = nil
E.noclipSrc = {}
function E.clearNoclip()
	table.clear(E.noclipSrc)
	E.setNoclip(false)
end
function E.setNoclip(on, src)
	E.noclipSrc[src or "main"] = on and true or nil
	local want = next(E.noclipSrc) ~= nil
	if want then
		if E.noclipConn then return end
		E.noclipConn = RunService.Stepped:Connect(function()
			local c = getChar()
			if not c then return end
			for _, p in ipairs(c:GetDescendants()) do
				if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
			end
		end)
	else
		if not E.noclipConn then return end
		E.noclipConn:Disconnect()
		E.noclipConn = nil
		local c = getChar()
		if c then
			for _, n in ipairs({"HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso", "Head"}) do
				local p = c:FindFirstChild(n)
				if p and p:IsA("BasePart") then p.CanCollide = true end
			end
		end
		local root = getRoot()
		if root and src ~= "walk" then root.AssemblyLinearVelocity = Vector3.zero end
	end
end
E.inputLocked = false
function E.blockInput(on)
	if on and not (Options.LockControls and Options.LockControls.Value) then on = false end
	if on == E.inputLocked then return end
	E.inputLocked = on
	if M.Controls then pcall(function() if on then M.Controls:Disable() else M.Controls:Enable() end end) end
end

E.moveToken, E.moving = 0, false
function E.flyTo(target, token, speed)
	local root0 = getRoot()
	if not root0 then return false end
	local goal = target + Vector3.new(0, 1.2, 0)
	speed = speed or Options.FlySpeed.Value
	local limit = (goal - root0.Position).Magnitude / math.max(speed, 1) * 1.6 + 12
	local started = os.clock()
	while token == E.moveToken and os.clock() - started < limit do
		local root, hum = getRoot(), getHum()
		if not (root and hum) or hum.Health <= 0 then return false end
		local d = goal - root.Position
		if d.Magnitude < 2 then
			root.AssemblyLinearVelocity = Vector3.zero
			return true
		end
		local v = math.min(speed, math.max(d.Magnitude * 5, 8))
		root.AssemblyLinearVelocity = d.Unit * v
		local flat = Vector3.new(d.X, 0, d.Z)
		if flat.Magnitude > 1 then root.CFrame = CFrame.lookAt(root.Position, root.Position + flat) end
		E.flyStatus = string.format("%dm left", math.floor(d.Magnitude))
		RunService.Heartbeat:Wait()
	end
	return false
end
function E.goTo(target, speed)
	E.moveToken += 1
	local token = E.moveToken
	E.moving = true
	E.blockInput(true)
	E.setNoclip(true)
	local ok = E.flyTo(target, token, speed)
	if token == E.moveToken then
		E.setNoclip(false)
		E.blockInput(false)
		E.moving = false
		E.flyStatus = nil
	end
	return ok
end
E.travelGen = 0
function E.stopMoving()
	E.travelGen += 1
	E.moveToken += 1
	pcall(function() RunService:UnbindFromRenderStep("AxiomWalk") end)
	E.moving = false
	E.flyStatus = nil
	E.stopHover()
	E.clearNoclip()
	E.blockInput(false)
	local hum = getHum()
	if hum then hum:Move(Vector3.zero, false) end
end

function E.inCombat()
	if not M.InCombat then return false end
	local ok, r = isolated(M.InCombat.biasedCheck, player)
	return ok and r == true
end
function E.shrineUnlocked(name)
	if not M.Archives then return true end
	local ok, r = isolated(M.Archives.IsUnlocked, "Shrines", name)
	return not ok or r == true
end
function E.bestShrine(dest)
	local root = getRoot()
	if not root then return nil end
	local here = (dest - root.Position).Magnitude
	local best, bestD
	for _, s in ipairs(W.shrines) do
		if E.shrineUnlocked(s.name) then
			local d = (s.pos - dest).Magnitude
			if not bestD or d < bestD then best, bestD = s, d end
		end
	end
	if best and bestD + (Options.ShrineGain and Options.ShrineGain.Value or 400) < here then return best, bestD end
	return nil
end
function E.useShrine(s)
	if not M.SignalEvent then return false end
	local t0 = os.clock()
	while E.inCombat() and os.clock() - t0 < 25 do
		E.flyStatus = "waiting out combat for the shrine"
		task.wait(0.5)
	end
	if E.inCombat() then return false end
	dlog("move", "Shrine → " .. s.name)
	E.stopHover()
	E.clearNoclip()
	if E.WK then E.WK.settleGen += 1 end
	local r0 = getRoot()
	if r0 then r0.AssemblyLinearVelocity = Vector3.zero end
	pcall(M.SignalEvent.ToServer, "TravelShrine", s.name)
	local t1 = os.clock()
	while os.clock() - t1 < 8 do
		local r = getRoot()
		E.clearNoclip()
		if r and (r.Position - s.pos).Magnitude < 200 then
			local h = getHum()
			local t2 = os.clock()
			repeat task.wait(0.2) until not h or h.FloorMaterial ~= Enum.Material.Air or os.clock() - t2 > 3
			if E.WK then E.WK.lastFree = r.Position end
			return true
		end
		task.wait(0.2)
	end
	return false
end
function E.travel(dest, near)
	near = near or 8
	local gen = E.travelGen
	local root = getRoot()
	if not root then return false end
	do
		local d0 = dest - root.Position
		if Vector3.new(d0.X, 0, d0.Z).Magnitude <= near and math.abs(d0.Y) < 10 then return true end
	end
	if Options.UseShrines.Value then
		local s = E.bestShrine(dest)
		if s then E.useShrine(s) end
	end
	if gen ~= E.travelGen then return false end
	if Options.UseHorse and Options.UseHorse.Value and E.HR and select(2, E.HR.toolbar()) ~= nil then
		for _ = 1, 2 do
			if gen ~= E.travelGen then return false end
			local r = getRoot()
			if not (r and (r.Position - dest).Magnitude > Options.HorseMinDist.Value) then break end
			if not E.HR.travel(dest + Vector3.new(0, 3, 0)) and not E.HR.riding() then break end
		end
	end
	for _ = 1, 3 do
		if gen ~= E.travelGen then return false end
		root = getRoot()
		if not root then return false end
		local d = dest - root.Position
		if Vector3.new(d.X, 0, d.Z).Magnitude <= near and math.abs(d.Y) < 10 then return true end
		local mover = (E.WK.natural or (Options.TravelMode and Options.TravelMode.Value == "Walk")) and E.WK.walkTo or E.WK.tweenTo
		if not mover(dest, near) and E.WK.lastUnreachable then return false end
	end
	root = getRoot()
	if not root then return false end
	local d = dest - root.Position
	return Vector3.new(d.X, 0, d.Z).Magnitude <= near + 6
end

E.hoverConn, E.hoverTarget = nil, nil
function E.stopHover()
	if E.hoverConn then E.hoverConn:Disconnect() E.hoverConn = nil end
end
function E.startHover()
	if E.hoverConn then return end
	E.setNoclip(true)
	E.blockInput(true)
	E.hoverIdleSince = nil
	E.hoverConn = RunService.Heartbeat:Connect(function(dt)
		local root = getRoot()
		local t = E.hoverTarget
		if not (root and t and t.root.Parent and t.hum.Health > 0) then
			E.hoverIdleSince = E.hoverIdleSince or os.clock()
			if os.clock() - E.hoverIdleSince > 0.4 or not Farms.active then
				E.stopHover()
				E.setNoclip(false)
				E.blockInput(false)
				return
			end
			if root then root.AssemblyLinearVelocity = Vector3.zero end
			return
		end
		E.hoverIdleSince = nil
		local tp = t.root.Position
		local h = Options.HoverHeight.Value
		local back = t.root.CFrame.LookVector
		back = Vector3.new(back.X, 0, back.Z)
		back = back.Magnitude > 0.1 and back.Unit or Vector3.new(0, 0, 1)
		local goal = tp + Vector3.new(0, h, 0) - back * Options.HoverBack.Value
		local cur = root.Position
		local delta = goal - cur
		local maxStep = Options.HoverSpeed.Value * dt
		local pos = delta.Magnitude > maxStep and (cur + delta.Unit * maxStep) or goal
		root.CFrame = CFrame.lookAt(pos, tp)
		root.AssemblyLinearVelocity = Vector3.zero
	end)
end

E.blocking, E.blockUntil, E.lastBlockTry, E.blockWanted = false, 0, 0, false
if M.InputHandler and M.InputHandler.IsDown then
	env.__AxiomOwOrigIsDown = env.__AxiomOwOrigIsDown or env.__AxiomOrigIsDown or M.InputHandler.IsDown
	local origIsDown = env.__AxiomOwOrigIsDown
	M.InputHandler.IsDown = function(name, ...)
		if E.blockWanted and name == "Skills_1st" then return true end
		return origIsDown(name, ...)
	end
end
if M.RunHandler and M.RunHandler.SetShiftLock then
	env.__AxiomOwOrigShiftLock = env.__AxiomOwOrigShiftLock or env.__AxiomOrigShiftLock or M.RunHandler.SetShiftLock
	local origShift = env.__AxiomOwOrigShiftLock
	M.RunHandler.SetShiftLock = function(v, ...)
		if v == 1 and Farms.active then return origShift(0, ...) end
		return origShift(v, ...)
	end
end
if M.SignalFunction and M.SignalFunction.ToServer then
	env.__AxiomOwOrigSF = env.__AxiomOwOrigSF or M.SignalFunction.ToServer
	local origSF = env.__AxiomOwOrigSF
	M.SignalFunction.ToServer = function(name, ...)
		if name == "SunDamage" and Options.SunImmunity and Options.SunImmunity.Value then
			return origSF("SunDamage", false)
		end
		return origSF(name, ...)
	end
end
function E.setSunImmunity(on)
	if on and env.__AxiomOwOrigSF then task.spawn(pcall, env.__AxiomOwOrigSF, "SunDamage", false) end
end
function E.blockActive()
	local v = RS:FindFirstChild("Player_Service") and RS.Player_Service.Values:FindFirstChild(player.Name)
	if v ~= nil and v:FindFirstChild("Blocking") ~= nil then return true end
	local shc = E.getSHC()
	return shc ~= nil and shc.Value == "Blocking" and os.clock() - E.lastBlockTry < 0.4
end
function E.startBlock(duration)
	E.blockUntil = math.max(E.blockUntil, os.clock() + duration)
	if not M.SkillCtl then return end
	E.blocking, E.blockWanted = true, true
	if not E.blockActive() and os.clock() - E.lastBlockTry > 0.2 then
		E.lastBlockTry = os.clock()
		task.spawn(pcall, M.SkillCtl.Attempt_Hold, "Blocking", "F")
	end
end
function E.stopBlock()
	if not E.blocking then return end
	E.blocking, E.blockWanted = false, false
	E.blockUntil = 0
	if M.SkillCtl then task.spawn(pcall, M.SkillCtl.StopHold, "Blocking") end
end

E.lootTag = "LootDrop"
pcall(function() E.lootTag = M.GameSettings.Tags.LootDrop or E.lootTag end)
function E.fire(p)
	if not pcall(fireproximityprompt, p) then
		pcall(function()
			p:InputHoldBegin()
			task.wait(p.HoldDuration + 0.2)
			p:InputHoldEnd()
		end)
	end
end
function E.holdPrompt(p, extra)
	local hold = p.HoldDuration or 0
	if hold <= 0.05 then
		pcall(fireproximityprompt, p)
		return
	end
	pcall(function()
		p:InputHoldBegin()
		task.wait(hold + (extra or 0.3))
		p:InputHoldEnd()
	end)
	task.wait(0.3)
	if p.Parent and p.Enabled then pcall(fireproximityprompt, p) end
end
function E.promptPos(p)
	local par = p.Parent
	if not par then return nil end
	if par:IsA("Attachment") then return par.WorldPosition end
	if par:IsA("BasePart") then return par.Position end
	local m = p:FindFirstAncestorOfClass("Model")
	return m and posOf(m)
end
function E.usePrompt(p, extra)
	local at = E.promptPos(p)
	if not at then return false end
	local r = getRoot()
	if r and (r.Position - at).Magnitude > math.max(p.MaxActivationDistance - 3, 2) then
		E.travel(at + Vector3.new(0, 2, 0), math.max(math.min(p.MaxActivationDistance - 4, 6), 2))
	end
	E.holdPrompt(p, extra)
	return true
end
function E.myDrop(part)
	local owner, reserved = part:GetAttribute("DropOwnerUserId"), part:GetAttribute("DropReservedFor")
	return (typeof(owner) ~= "number" or owner == player.UserId)
		and (typeof(reserved) ~= "string" or reserved:find("," .. player.UserId .. ",", 1, true) ~= nil)
end
function E.collectLoot(radius)
	radius = radius or 150
	local got, fired = 0, {}
	for _ = 1, 30 do
		local root = getRoot()
		if not root then break end
		local best, bestD, bestP
		for _, part in ipairs(CS:GetTagged(E.lootTag)) do
			if part:IsA("BasePart") and part.Parent and E.myDrop(part) then
				local pr = part:FindFirstChildWhichIsA("ProximityPrompt", true)
				if pr and pr.Enabled and not fired[pr] then
					local d = (part.Position - root.Position).Magnitude
					if d < radius and (not bestD or d < bestD) then best, bestD, bestP = part, d, pr end
				end
			end
		end
		if not best then break end
		if bestD > bestP.MaxActivationDistance - 1 then (E.WK.natural and E.WK.walkTo or E.WK.tweenTo)(best.Position, math.max(bestP.MaxActivationDistance - 3, 2)) end
		root = getRoot()
		for _, part in ipairs(CS:GetTagged(E.lootTag)) do
			local pr = part:IsA("BasePart") and part:FindFirstChildWhichIsA("ProximityPrompt", true)
			if pr and pr.Enabled and not fired[pr] and root and E.myDrop(part) and (part.Position - root.Position).Magnitude <= pr.MaxActivationDistance - 0.5 then
				fired[pr] = true
				task.spawn(E.fire, pr)
				got += 1
			end
		end
		task.wait(0.3)
	end
	if got > 0 then
		dbg.loot += got
		dlog("loot", "Picked up " .. got .. " drop" .. (got == 1 and "" or "s"))
	end
	return got
end
function E.lootNearby()
	for _, part in ipairs(CS:GetTagged(E.lootTag)) do
		local root = getRoot()
		if root and part:IsA("BasePart") and part.Parent and E.myDrop(part) and (part.Position - root.Position).Magnitude < 120 then
			return true
		end
	end
	return false
end

local HR = {restore = nil, failUntil = 0}
E.HR = HR
HR.SLOTS = {"One", "Two", "Three", "Four", "Five"}
function HR.riding()
	local c = getChar()
	return c ~= nil and c:GetAttribute("OnHorse") == true
end
function HR.toolbar()
	local d = getData()
	if not d then return nil end
	local it = d.Inventory.Inventory:FindFirstChild("Horse")
	local hid = it and it:FindFirstChild("Id")
	if not hid then return nil end
	for i, n in ipairs(HR.SLOTS) do
		local v = d.Inventory.Toolbar:FindFirstChild(n)
		if v and v.Value == hid.Value then return i, hid.Value end
	end
	return nil, hid.Value
end
function HR.module()
	if HR.mod then return HR.mod end
	local ok, m = pcall(function() return require(RS.ToolScripts.Horse.Horse) end)
	if ok and type(m) == "table" then HR.mod = m end
	return HR.mod
end
function HR.gaitUpvalues()
	local m = HR.module()
	local fn = m and m.cycleSpeedMode
	if type(fn) ~= "function" then return nil end
	local ok, ups = pcall(debug.getupvalues, fn)
	if not ok or type(ups) ~= "table" then return nil end
	if type(ups[2]) == "number" and type(ups[3]) == "table" and type(ups[4]) == "number" then return fn, 2, 4, ups[3] end
	for i = 1, #ups - 2 do
		if type(ups[i]) == "number" and type(ups[i + 1]) == "table" and type(ups[i + 1][1]) == "table" and ups[i + 1][1].Speed and type(ups[i + 2]) == "number" then
			return fn, i, i + 2, ups[i + 1]
		end
	end
	return nil
end
function HR.boost()
	local fn, gaitIdx, stamIdx, gaits = HR.gaitUpvalues()
	if not fn then return end
	pcall(debug.setupvalue, fn, gaitIdx, #gaits)
	pcall(debug.setupvalue, fn, stamIdx, 45)
end
function HR.mount()
	if HR.riding() then return true end
	if os.clock() < HR.failUntil then return false, "horse cooling down" end
	local tw = os.clock()
	while E.inCombat() and os.clock() - tw < 8 do
		E.flyStatus = "waiting out combat to call the horse"
		task.wait(0.4)
	end
	if E.inCombat() then HR.failUntil = os.clock() + 5 return false, "in combat" end
	local slot, hid = HR.toolbar()
	if not hid then return false, "no Horse in the bag" end
	if not slot then
		slot = Options.HorseSlot.Value
		local d = getData()
		local cur = d and d.Inventory.Toolbar:FindFirstChild(HR.SLOTS[slot])
		HR.restore = {slot = slot, id = cur and cur.Value or 0}
		pcall(M.SignalEvent.ToServer, "Toolbar_Equip", HR.SLOTS[slot], hid)
		task.wait(1.2)
	end
	local cfg = player:FindFirstChild("Items_Config")
	local eq = cfg and cfg:FindFirstChild("Equipped")
	if not eq then return false, "no equip value" end
	if eq.Value == slot then eq.Value = 0 task.wait(0.2) end
	eq.Value = slot
	pcall(M.SignalEvent.ToServer, "Item_Equip", slot)
	local t0 = os.clock()
	repeat task.wait(0.2) until HR.riding() or os.clock() - t0 > 3
	if not HR.riding() then
		local r = getRoot()
		local pos = r and r.Position or Vector3.zero
		pcall(M.SignalEvent.ToServer, "Tool_Mouse", "Down", pos)
		task.wait(0.15)
		pcall(M.SignalEvent.ToServer, "Tool_Mouse", "Up", pos)
		repeat task.wait(0.2) until HR.riding() or os.clock() - t0 > 7
	end
	if not HR.riding() then HR.failUntil = os.clock() + 30 return false, "the horse didn't come" end
	return true
end
function HR.dismount()
	local cfg = player:FindFirstChild("Items_Config")
	local eq = cfg and cfg:FindFirstChild("Equipped")
	if eq then eq.Value = E.weaponSlot() end
	local t0 = os.clock()
	while HR.riding() and os.clock() - t0 < 3 do task.wait(0.15) end
	if HR.restore and not Options.KeepHorse.Value then
		local r = HR.restore
		HR.restore = nil
		if r.id and r.id ~= 0 then pcall(M.SignalEvent.ToServer, "Toolbar_Equip", HR.SLOTS[r.slot], r.id) end
	end
end
function HR.horseParts()
	local c = getChar()
	local root = getRoot()
	local out = {}
	for _, d in ipairs(workspace:GetDescendants()) do
		if d.Name == "Horse" and d:IsA("Model") and d:FindFirstChild("HumanoidRootPart") and root then
			if (d.HumanoidRootPart.Position - root.Position).Magnitude < 12 then
				for _, p in ipairs(d:GetDescendants()) do if p:IsA("BasePart") then table.insert(out, p) end end
			end
		end
	end
	return out
end
function HR.drive(dest, token)
	local speed = Options.HorseSpeed.Value
	local r0 = getRoot()
	if not r0 then return false end
	local limit = (dest - r0.Position).Magnitude / math.max(speed, 1) * 1.6 + 15
	local started = os.clock()
	local parts = HR.horseParts()
	local nc = RunService.Stepped:Connect(function()
		for _, p in ipairs(parts) do if p.Parent and p.CanCollide then p.CanCollide = false end end
	end)
	local reached = false
	while token == E.moveToken and os.clock() - started < limit and HR.riding() do
		local root, hum = getRoot(), getHum()
		if not (root and hum) or hum.Health <= 0 then break end
		local d = dest - root.Position
		local flat = Vector3.new(d.X, 0, d.Z)
		if flat.Magnitude < 18 then reached = true break end
		local dir = flat.Unit
		local vy = math.clamp(d.Y * 0.6, -35, 35)
		HR.boost()
		hum:Move(dir, false)
		local mover = root:FindFirstChild("HorseMover")
		if mover then
			for _, lv in ipairs(mover:GetChildren()) do
				if lv:IsA("LinearVelocity") then
					if lv.VelocityConstraintMode == Enum.VelocityConstraintMode.Plane then
						lv.PlaneVelocity = Vector2.new(dir.X * speed, dir.Z * speed)
					elseif lv.VelocityConstraintMode == Enum.VelocityConstraintMode.Line then
						lv.Enabled = true
						lv.LineVelocity = vy
					end
				elseif lv:IsA("AlignOrientation") then
					lv.CFrame = CFrame.lookAlong(Vector3.zero, dir, Vector3.yAxis)
				end
			end
		end
		root.AssemblyLinearVelocity = Vector3.new(dir.X * speed, vy, dir.Z * speed)
		E.flyStatus = string.format("on horse · %dm left", math.floor(d.Magnitude))
		RunService.Heartbeat:Wait()
	end
	nc:Disconnect()
	local hum = getHum()
	if hum then hum:Move(Vector3.zero, false) end
	return reached
end
function HR.travel(dest)
	if E.hoverConn then
		E.stopHover()
		E.setNoclip(false)
		E.blockInput(false)
	end
	E.stopBlock()
	local ok, why = HR.mount()
	if not ok then
		dlog("move", "Horse: " .. tostring(why) .. " — walking instead")
		return false
	end
	dlog("move", string.format("Riding %dm", math.floor((dest - getRoot().Position).Magnitude)))
	E.moveToken += 1
	local token = E.moveToken
	E.moving = true
	E.blockInput(true)
	E.setNoclip(true, "horse")
	local reached = HR.drive(dest, token)
	E.setNoclip(false, "horse")
	E.blockInput(false)
	E.moving = false
	E.flyStatus = nil
	if token == E.moveToken then HR.dismount() end
	return reached
end

local WK = {}
E.WK = WK
WK.rayParams = RaycastParams.new()
WK.rayParams.FilterType = Enum.RaycastFilterType.Exclude
pcall(function() WK.rayParams.RespectCanCollide = true end)
function WK.setFilter()
	local filter = {getChar()}
	local H = workspace:FindFirstChild("Humanoids")
	if H then table.insert(filter, H) end
	local D = workspace:FindFirstChild("Debree")
	if D then table.insert(filter, D) end
	local trees = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Trees")
	if trees then table.insert(filter, trees) end
	WK.rayParams.FilterDescendantsInstances = filter
end
function WK.groundBelow(root, depth)
	WK.setFilter()
	return workspace:Raycast(root.Position, Vector3.new(0, -(depth or 60), 0), WK.rayParams)
end
WK.overlap = OverlapParams.new()
WK.overlap.FilterType = Enum.RaycastFilterType.Include
function WK.inside(root)
	local map = workspace:FindFirstChild("Map")
	if not map then return false end
	WK.overlap.FilterDescendantsInstances = {map}
	local ok, parts = pcall(workspace.GetPartBoundsInBox, workspace, root.CFrame, Vector3.new(1.6, 2.4, 1.6), WK.overlap)
	if not ok then return false end
	for _, p in ipairs(parts) do
		if p.CanCollide and p.Transparency < 1 then return true end
	end
	return false
end
function WK.sunk(root)
	WK.setFilter()
	local down = workspace:Raycast(root.Position + Vector3.new(0, 2.5, 0), Vector3.new(0, -5, 0), WK.rayParams)
	return down ~= nil and down.Position.Y > root.Position.Y - 1.8
end
function WK.floorAbove(root, range)
	WK.setFilter()
	return workspace:Raycast(root.Position, Vector3.new(0, range or 20, 0), WK.rayParams) ~= nil
end
function WK.safeHere(root, hum)
	if hum.FloorMaterial == Enum.Material.Air or WK.sunk(root) then return false end
	local g = WK.groundBelow(root, 6)
	return g ~= nil
end
WK.lastDash, WK.lastJump = 0, 0
function WK.dash(dir)
	if not (M.SkillCtl and E.getSHC()) or dir.Magnitude < 0.1 then return false end
	if os.clock() - WK.lastDash < (Options.WalkDashGap and Options.WalkDashGap.Value or 1.2) then return false end
	WK.lastDash = os.clock()
	local cam = workspace.CurrentCamera
	local saved = cam.CFrame
	cam.CFrame = CFrame.lookAt(saved.Position, saved.Position + Vector3.new(dir.X, 0, dir.Z))
	local ok, r = pcall(M.SkillCtl.Attempt_Hold, "Dash", "W")
	cam.CFrame = saved
	if ok and r == true then task.spawn(pcall, M.SkillCtl.StopHold, "Dash") return true end
	return false
end
function WK.jump(hum, forceDouble)
	if os.clock() - WK.lastJump < 0.28 then return end
	WK.lastJump = os.clock()
	if hum.FloorMaterial ~= Enum.Material.Air and not forceDouble then
		hum.Jump = true
	else
		if M.DoubleJump and M.DoubleJump.Hold then task.spawn(pcall, M.DoubleJump.Hold, player) end
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end
WK.tweenSpeed = 25
function WK.noSwim(root)
	local sa = root and root:FindFirstChild("SwimAttachment")
	if not sa then return end
	for _, c in ipairs(sa:GetChildren()) do
		if c:IsA("Constraint") and c.Enabled then c.Enabled = false end
	end
end
function WK.groundAt(pos)
	WK.setFilter()
	local hit = workspace:Raycast(pos + Vector3.new(0, 120, 0), Vector3.new(0, -300, 0), WK.rayParams)
	return hit and hit.Position.Y or nil
end
function WK.tweenTo(target, near)
	near = near or 5
	local r0 = getRoot()
	if not r0 then return false end
	if E.hoverConn then E.stopHover() E.setNoclip(false) end
	E.blockInput(false)
	E.stopBlock()
	E.moveToken += 1
	local token = E.moveToken
	E.moving = true
	WK.settleGen += 1
	WK.walking = true
	WK.lastUnreachable = false
	E.setNoclip(true, "walk")
	local dist0 = (target - r0.Position).Magnitude
	local started, limit = os.clock(), dist0 / 10 + 25
	local result = false
	local backs, lastPos = 0, r0.Position
	local lastGround = WK.groundAt(r0.Position) or (r0.Position.Y - 3)
	local done = false
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if done then return end
		local root, hum = getRoot(), getHum()
		if not (root and hum) or hum.Health <= 0 or token ~= E.moveToken or os.clock() - started > limit then done = true return end
		WK.noSwim(root)
		WK.noteFree(root)
		local pos = root.Position
		local off = pos - lastPos
		local dirNow = Vector3.new(target.X - pos.X, 0, target.Z - pos.Z)
		dirNow = dirNow.Magnitude > 0.1 and dirNow.Unit or Vector3.zero
		local sameBody = root == WK.tweenRoot
		WK.tweenRoot = root
		local pulled = sameBody and os.clock() - started > 0.5 and off.Magnitude > 8 and off:Dot(dirNow) < -4
		if pulled then
			backs += 1
			WK.backs = (WK.backs or 0) + 1
			if WK.backs == 1 then WK.tweenSpeed = 22 end
			if WK.backs >= 2 then
				WK.natural = true
				dlog("warn", "Pulled back again · switching to running with dashes and jumps")
				done = true
				return
			end
			dlog("warn", string.format("Pulled back %.0f studs by the game · speed now %d", off.Magnitude, WK.tweenSpeed))
		end
		lastPos = pos
		local d = target - pos
		local flat = Vector3.new(d.X, 0, d.Z)
		if flat.Magnitude < near and math.abs(d.Y) < 10 then result = true done = true return end
		local dir = flat.Magnitude > 0.1 and flat.Unit or Vector3.zero
		local speed = flat.Magnitude < 25 and math.min(12, WK.tweenSpeed) or WK.tweenSpeed
		local g = WK.groundAt(pos + dir * 3)
		if g then lastGround = g end
		local wantY = lastGround + 3.2
		if flat.Magnitude < 60 then wantY = target.Y + 1 end
		local vy = math.clamp((wantY - pos.Y) * 5, -speed, speed)
		local sinkThrough = wantY < pos.Y - 2
		if hum.PlatformStand ~= sinkThrough then hum.PlatformStand = sinkThrough end
		root.AssemblyLinearVelocity = Vector3.new(dir.X * speed, vy, dir.Z * speed)
		if flat.Magnitude > 1 then root.CFrame = CFrame.lookAt(pos, pos + dir) end
		hum:Move(dir, false)
		E.flyStatus = string.format("tween · %dm left · %d", math.floor(flat.Magnitude), speed)
	end)
	while not done do task.wait(0.05) end
	conn:Disconnect()
	local root = getRoot()
	if root then root.AssemblyLinearVelocity = Vector3.zero end
	local hum = getHum()
	if hum then
		hum.PlatformStand = false
		hum:Move(Vector3.zero, false)
	end
	WK.walking = false
	WK.settle()
	if token == E.moveToken then
		E.moving = false
		E.flyStatus = nil
	end
	return result
end
function WK.airTo(target, near, minAlt)
	near, minAlt = near or 8, minAlt or 25
	local r0 = getRoot()
	if not r0 then return false end
	if E.hoverConn then E.stopHover() E.setNoclip(false) end
	E.blockInput(false)
	E.stopBlock()
	E.moveToken += 1
	local token = E.moveToken
	E.moving = true
	WK.walking = true
	WK.dir = Vector3.zero
	pcall(function() RunService:UnbindFromRenderStep("AxiomWalk") end)
	RunService:BindToRenderStep("AxiomWalk", Enum.RenderPriority.Input.Value + 5, function()
		local h = getHum()
		if h and WK.dir then h:Move(WK.dir, false) end
	end)
	local started, limit = os.clock(), (target - r0.Position).Magnitude / 10 + 40
	local result = false
	WK.settleGen += 1
	E.setNoclip(true, "walk")
	while token == E.moveToken and os.clock() - started < limit do
		local root, hum = getRoot(), getHum()
		if not (root and hum) or hum.Health <= 0 then break end
		WK.noSwim(root)
		WK.noteFree(root)
		local pos = root.Position
		local d = target - pos
		local flat = Vector3.new(d.X, 0, d.Z)
		if flat.Magnitude < near and (math.abs(d.Y) < 15 or hum.FloorMaterial ~= Enum.Material.Air) then result = true break end
		local dir = flat.Magnitude > 0.1 and flat.Unit or Vector3.zero
		WK.dir = dir
		WK.setFilter()
		local gh = workspace:Raycast(pos, Vector3.new(0, -400, 0), WK.rayParams)
		local g = gh and gh.Position.Y or (pos.Y - 400)
		local alt = pos.Y - g
		local landing = flat.Magnitude < near * 2.5
		local v = root.AssemblyLinearVelocity
		if not landing then
			if hum.FloorMaterial ~= Enum.Material.Air then
				hum.Jump = true
			elseif alt < minAlt or (alt < minAlt + 10 and v.Y < -12) then
				WK.jump(hum, true)
			end
			if os.clock() - WK.lastDash > 0.9 then WK.dash(dir) end
		end
		E.flyStatus = string.format("air · %dm left · %d up", math.floor(flat.Magnitude), math.floor(alt))
		task.wait(0.06)
	end
	WK.dir = nil
	WK.walking = false
	pcall(function() RunService:UnbindFromRenderStep("AxiomWalk") end)
	local hum = getHum()
	if hum then hum:Move(Vector3.zero, false) end
	WK.settle()
	if token == E.moveToken then
		E.moving = false
		E.flyStatus = nil
	end
	return result
end
WK.PFS = game:GetService("PathfindingService")
function WK.path(from, to)
	local ok, path = pcall(WK.PFS.CreatePath, WK.PFS, {AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, AgentCanClimb = true, WaypointSpacing = 8})
	if not ok or not path then return nil end
	local okC = pcall(path.ComputeAsync, path, from, to)
	if not okC or path.Status ~= Enum.PathStatus.Success then return nil end
	local wps = path:GetWaypoints()
	return #wps > 1 and wps or nil
end
WK.lastClimb = 0
function WK.climb(dir)
	if not (M.SkillCtl and E.getSHC()) or os.clock() - WK.lastClimb < 1.5 then return end
	WK.lastClimb = os.clock()
	local cam = workspace.CurrentCamera
	local saved = cam.CFrame
	cam.CFrame = CFrame.lookAt(saved.Position, saved.Position + Vector3.new(dir.X, 0, dir.Z))
	task.spawn(pcall, M.SkillCtl.Attempt_Hold, "Wall Climb")
	cam.CFrame = saved
	task.delay(1.2, function() pcall(M.SkillCtl.StopHold, "Wall Climb") end)
end
function WK.setRun(on)
	if on == WK.runOn or not M.InputHandler then return end
	WK.runOn = on
	if on then
		if M.InputHandler.VirtualPress then pcall(M.InputHandler.VirtualPress, "Run") end
	else
		if M.InputHandler.VirtualRelease then pcall(M.InputHandler.VirtualRelease, "Run") end
	end
end
WK.inParams = OverlapParams.new()
WK.inParams.FilterType = Enum.RaycastFilterType.Exclude
pcall(function() WK.inParams.RespectCanCollide = true end)
function WK.insideNow(root)
	local filter = {getChar()}
	local H = workspace:FindFirstChild("Humanoids")
	if H then table.insert(filter, H) end
	local D = workspace:FindFirstChild("Debree")
	if D then table.insert(filter, D) end
	WK.inParams.FilterDescendantsInstances = filter
	local ok, parts = pcall(workspace.GetPartBoundsInRadius, workspace, root.Position, 1.6, WK.inParams)
	if not ok or #parts == 0 then return false end
	local ok2, exact = pcall(workspace.GetPartsInPart, workspace, root, WK.inParams)
	return ok2 and #exact > 0
end
WK.lastFree, WK.lastFreeAt = nil, 0
function WK.noteFree(root)
	if os.clock() - WK.lastFreeAt < 0.3 then return end
	WK.lastFreeAt = os.clock()
	if not WK.insideNow(root) then WK.lastFree = root.Position end
end
WK.settleGen = 0
function WK.settle()
	WK.settleGen += 1
	local gen = WK.settleGen
	task.spawn(function()
		local t0 = os.clock()
		local pushing = false
		while gen == WK.settleGen and os.clock() - t0 < 8 do
			local root, hum = getRoot(), getHum()
			if not (root and hum) or hum.Health <= 0 then break end
			if not WK.insideNow(root) and not WK.floorAbove(root, 3) then break end
			local free = WK.lastFree
			if free and (free - root.Position).Magnitude > 1 then
				if not pushing then pushing = true dlog("move", "Stuck in a wall · moving back out") end
				local dd = free - root.Position
				root.AssemblyLinearVelocity = dd.Unit * math.min(20, dd.Magnitude * 6)
			else
				root.AssemblyLinearVelocity = Vector3.new(0, 20, 0)
			end
			task.wait(0.05)
		end
		if gen == WK.settleGen then E.setNoclip(false, "walk") end
	end)
end
function WK.rescue(hum, root, safe, token)
	E.flyStatus = "climbing out"
	E.setNoclip(true, "walk")
	local t0 = os.clock()
	while token == E.moveToken and os.clock() - t0 < 6 do
		root, hum = getRoot(), getHum()
		if not (root and hum) or hum.Health <= 0 then return false end
		local d = safe - root.Position
		local flat = Vector3.new(d.X, 0, d.Z)
		WK.dir = flat.Magnitude > 1.5 and flat.Unit or Vector3.zero
		local covered = WK.floorAbove(root, 30)
		if root.Position.Y >= safe.Y - 1 and not WK.floorAbove(root, 4) then return true end
		if root.Position.Y < safe.Y + 4 then
			WK.jump(hum, true)
			if covered then
				local v = root.AssemblyLinearVelocity
				root.AssemblyLinearVelocity = Vector3.new(v.X, math.max(v.Y, 38), v.Z)
			end
		end
		task.wait(0.05)
	end
	return false
end
function WK.walkTo(target, near)
	near = near or 5
	local r0 = getRoot()
	if not r0 then return false end
	if E.hoverConn then
		E.stopHover()
		E.setNoclip(false)
	end
	E.blockInput(false)
	E.stopBlock()
	E.moveToken += 1
	local token = E.moveToken
	E.moving = true
	WK.settleGen += 1
	WK.dir = Vector3.zero
	pcall(function() RunService:UnbindFromRenderStep("AxiomWalk") end)
	RunService:BindToRenderStep("AxiomWalk", Enum.RenderPriority.Input.Value + 5, function()
		local h = getHum()
		if h and WK.dir then h:Move(WK.dir, false) end
	end)
	WK.runOn = false
	WK.walking = true
	E.setNoclip(WK.insideNow(r0), "walk")
	local dist0 = (target - r0.Position).Magnitude
	local limit = dist0 / 10 + 20
	local started = os.clock()
	local lastPos, stuck = nil, 0
	local best, bestAt = math.huge, os.clock()
	local result = false
	local safe
	do
		local h0 = getHum()
		if h0 and WK.safeHere(r0, h0) then safe = r0.Position else
			local g = WK.groundBelow(r0, 200)
			if g then safe = g.Position + Vector3.new(0, 3, 0) end
		end
	end
	WK.lastUnreachable = false
	local wps, wi, pathTries = nil, 2, 0
	local segGoal = target
	local function repath(from)
		pathTries += 1
		wps, wi = nil, 2
		local full = target - from
		local flatFull = Vector3.new(full.X, 0, full.Z)
		if flatFull.Magnitude <= 320 then
			segGoal = target
			wps = WK.path(from, target)
		else
			local base = flatFull.Unit
			for _, ang in ipairs({0, 30, -30, 60, -60}) do
				local dir2 = (CFrame.Angles(0, math.rad(ang), 0) * CFrame.new(base)).Position
				local p = from + dir2 * 280
				local g = WK.groundAt(p)
				if g then
					p = Vector3.new(p.X, g + 3, p.Z)
					local w = WK.path(from, p)
					if w then wps, segGoal = w, p break end
				end
			end
		end
		local rr = getRoot()
		E.setNoclip(rr ~= nil and WK.insideNow(rr), "walk")
	end
	if dist0 > near + 10 then repath(r0.Position) end
	while token == E.moveToken and os.clock() - started < limit do
		local root, hum = getRoot(), getHum()
		if not (root and hum) or hum.Health <= 0 then break end
		local d = target - root.Position
		local flat = Vector3.new(d.X, 0, d.Z)
		if flat.Magnitude < near and d.Y < 8 then result = true break end
		if flat.Magnitude < near * 1.5 and math.abs(d.Y) > 25 then WK.lastUnreachable = true break end
		if flat.Magnitude < best - 2 then best, bestAt = flat.Magnitude, os.clock() end
		if os.clock() - bestAt > 7 then
			if pathTries < 3 then repath(root.Position) bestAt = os.clock() else WK.lastUnreachable = true break end
		end
		local dir = flat.Magnitude > 0.1 and flat.Unit or Vector3.zero
		if wps and segGoal ~= target and Vector3.new(segGoal.X - root.Position.X, 0, segGoal.Z - root.Position.Z).Magnitude < 12 then
			pathTries = 0
			repath(root.Position)
		end
		if wps then
			local bestK, bestDist = wi, math.huge
			for k = wi, math.min(wi + 8, #wps) do
				local dd = (wps[k].Position - root.Position).Magnitude
				if dd < bestDist then bestK, bestDist = k, dd end
			end
			if bestK > wi then wi = bestK end
			local wp = wps[wi]
			while wp and Vector3.new(wp.Position.X - root.Position.X, 0, wp.Position.Z - root.Position.Z).Magnitude < 4 and wi < #wps do
				wi += 1
				wp = wps[wi]
				if wp.Action == Enum.PathWaypointAction.Jump then hum.Jump = true end
			end
			if wp then
				local wd = wp.Position - root.Position
				local wf = Vector3.new(wd.X, 0, wd.Z)
				if wf.Magnitude > 0.1 then dir = wf.Unit end
				if wd.Y > 2.5 and stuck > 0.3 then hum.Jump = true end
			end
		end
		WK.dir = dir
		if Options.WalkRun and Options.WalkRun.Value and flat.Magnitude > 8 then WK.setRun(true) end
		WK.noteFree(root)
		local moved = lastPos and Vector3.new(root.Position.X - lastPos.X, 0, root.Position.Z - lastPos.Z).Magnitude or 1
		lastPos = root.Position
		if moved < 0.25 then stuck += 0.1 else stuck = math.max(0, stuck - 0.1) end
		local v = root.AssemblyLinearVelocity
		local inAir = hum.FloorMaterial == Enum.Material.Air
		if WK.safeHere(root, hum) then safe = root.Position end
		local targetLow = d.Y < -12
		local fellThrough = safe and not targetLow and root.Position.Y < safe.Y - 6 and WK.floorAbove(root, 25)
		local void = safe and inAir and v.Y < -20 and not WK.groundBelow(root, 90)
		if fellThrough or void then
			if os.clock() - (WK.lastFallLog or 0) > 10 then
				WK.lastFallLog = os.clock()
				dlog("move", "Fell in, double-jumping back up")
			end
			if not WK.rescue(hum, root, safe, token) then WK.lastUnreachable = true break end
			best, bestAt, stuck, lastPos = math.huge, os.clock(), 0, nil
		elseif wps then
			if stuck > 2 then
				if pathTries < 3 then repath(root.Position) stuck = 0 else wps = nil end
			end
			if wps and not inAir and Options.WalkDash and Options.WalkDash.Value then
				local straight = true
				local last = root.Position
				for k = wi, math.min(wi + 4, #wps) do
					local w = wps[k]
					if w.Action == Enum.PathWaypointAction.Jump then straight = false break end
					local seg = Vector3.new(w.Position.X - last.X, 0, w.Position.Z - last.Z)
					if seg.Magnitude > 0.5 and seg.Unit:Dot(dir) < 0.9 then straight = false break end
					if math.abs(w.Position.Y - last.Y) > 4 then straight = false break end
					last = w.Position
				end
				if straight and wi + 4 <= #wps then WK.dash(dir) end
			end
		else
			WK.setFilter()
			local ahead = dir.Magnitude > 0 and workspace:Raycast(root.Position - Vector3.new(0, 1.8, 0), dir * 4, WK.rayParams)
			local chest = dir.Magnitude > 0 and workspace:Raycast(root.Position + Vector3.new(0, 0.5, 0), dir * 4, WK.rayParams)
			local wall = (chest and chest.Normal.Y < 0.5) or (ahead and ahead.Normal.Y < 0.35)
			if ahead and stuck > 0.4 and not wall then WK.jump(hum, inAir) end
			E.setNoclip(wall or stuck > 1.5 or WK.insideNow(root), "walk")
			if stuck > 1 and d.Y > 6 and flat.Magnitude > near + 20 and not inAir and os.clock() - WK.lastJump > 1.5 then
				WK.lastJump = os.clock()
				hum.Jump = true
			end
			local dashFrom = math.max((Options.EngageDist and Options.EngageDist.Value or 14) + 6, near + 12)
			if flat.Magnitude > dashFrom and not inAir and Options.WalkDash and Options.WalkDash.Value then WK.dash(dir) end
		end
		E.flyStatus = string.format("on foot · %dm left", math.floor(flat.Magnitude))
		task.wait(0.1)
	end
	WK.dir = nil
	WK.walking = false
	WK.setRun(false)
	pcall(function() RunService:UnbindFromRenderStep("AxiomWalk") end)
	local hum = getHum()
	if hum then hum:Move(Vector3.zero, false) end
	WK.settle()
	if token == E.moveToken then
		E.moving = false
		E.flyStatus = nil
	end
	return result
end

local C = {lastKillAt = os.clock(), lastHit = 0, healing = false, lastHeal = 0, status = ""}
function C.disengage(keepTarget)
	local t = E.target
	if t and (t.hum.Health <= 0 or not t.model.Parent) and C.countKill then C.countKill(t) end
	if not keepTarget then E.target = nil end
	E.hoverTarget, E.aimOn = nil, false
	if E.hoverConn then
		E.stopHover()
		E.setNoclip(false)
		E.blockInput(false)
	end
end
function C.engage(t)
	E.target, E.hoverTarget = t, t
	E.aimTarget, E.aimOn = E.targetPos(t), true
	E.startHover()
	local root = getRoot()
	if root and (t.root.Position - root.Position).Magnitude < Options.HoverHeight.Value + 8 then E.punch() end
	if Options.SkillsOn.Value and not E.casting and not C.othersNear(t) then task.spawn(E.castNext) end
end
function C.othersNear(t)
	if t.group and t.group.boss then return false end
	local filter = C.filter
	for _, e in ipairs(E.enemies()) do
		if e.model ~= t.model and not (filter and filter(e)) then
			local d = (e.root.Position - t.root.Position).Magnitude
			if d < 28 or (e.group and e.group.boss and d < 60) then return true end
		end
	end
	return false
end

function C.potionInfo()
	local d = getData()
	if not d then return nil end
	local NAMES = {"One", "Two", "Three", "Four", "Five"}
	local slot = d.Inventory.Toolbar:FindFirstChild(NAMES[Options.PotionSlot.Value])
	if not slot or slot.Value == 0 then return 0 end
	for _, it in ipairs(d.Inventory.Inventory:GetChildren()) do
		local id = it:FindFirstChild("Id")
		if id and id.Value == slot.Value then
			local amt = it:FindFirstChild("Amount")
			return amt and amt.Value or 1, it.Name
		end
	end
	return 0
end
function C.drink()
	local cfg = player:FindFirstChild("Items_Config")
	local eq = cfg and cfg:FindFirstChild("Equipped")
	if not (eq and M.SignalEvent) then return false end
	eq.Value = Options.PotionSlot.Value
	task.wait(0.7)
	local root = getRoot()
	local pos = root and root.Position or Vector3.zero
	task.spawn(pcall, M.SignalEvent.ToServer, "Tool_Mouse", "Down", pos)
	task.wait(2.6)
	task.spawn(pcall, M.SignalEvent.ToServer, "Tool_Mouse", "Up", pos)
	task.wait(0.6)
	eq.Value = E.weaponSlot()
	return true
end
C.INSTANT = {"Health Elixir", "Health Potion"}
C.REGEN = {"Health Regen Elixir", "Health Regen Potion"}
C.lastRegen = 0
function C.bagItem(list)
	local d = getData()
	if not d then return nil end
	for _, want in ipairs(list) do
		local it = d.Inventory.Inventory:FindFirstChild(want)
		local amt, id = it and it:FindFirstChild("Amount"), it and it:FindFirstChild("Id")
		if amt and id and amt.Value > 0 then return want, id.Value, amt.Value end
	end
	return nil
end
function C.needHeal()
	local hum = getHum()
	if not (hum and Options.AutoHeal.Value) or C.healing or hum.Health <= 0 then return false end
	local pct = hum.Health / hum.MaxHealth * 100
	if pct < Options.HealAt.Value and os.clock() - C.lastHeal > 6 then return "instant" end
	if pct < 75 and os.clock() - C.lastRegen > 25 and C.bagItem(C.REGEN) then return "regen" end
	return false
end
function C.slotItem(list)
	local name, id, amt = C.bagItem(list)
	if not name then return nil end
	local d = getData()
	local key = ({"One", "Two", "Three", "Four", "Five"})[Options.PotionSlot.Value]
	local slot = d and d.Inventory.Toolbar:FindFirstChild(key)
	if slot and slot.Value ~= id then
		pcall(M.SignalEvent.ToServer, "Toolbar_Equip", key, id)
		task.wait(0.8)
	end
	return name, amt
end
C.POTIONS = {"Health Elixir", "Health Regen Elixir", "Health Regen Potion", "Health Potion"}
function C.refillPotion()
	local d = getData()
	if not (d and M.SignalEvent) then return false end
	for _, want in ipairs(C.POTIONS) do
		local it = d.Inventory.Inventory:FindFirstChild(want)
		local amt, id = it and it:FindFirstChild("Amount"), it and it:FindFirstChild("Id")
		if amt and id and amt.Value > 0 then
			pcall(M.SignalEvent.ToServer, "Toolbar_Equip", ({"One", "Two", "Three", "Four", "Five"})[Options.PotionSlot.Value], id.Value)
			task.wait(1.2)
			dlog("heal", "Potion slot was empty → put " .. want .. " (" .. amt.Value .. ") in it")
			return true
		end
	end
	return false
end
function C.retreatPoint()
	local root = getRoot()
	if not root then return nil end
	return root.Position + Vector3.new(0, Options.HealHeight.Value, 0)
end
function C.heal(kind)
	C.healing = true
	kind = kind or "instant"
	if kind == "regen" then C.lastRegen = os.clock() else C.lastHeal = os.clock() end
	local potName, amount = C.slotItem(kind == "regen" and C.REGEN or C.INSTANT)
	if not potName then potName, amount = C.slotItem(kind == "regen" and C.INSTANT or C.REGEN) end
	amount = amount or C.potionInfo()
	if amount == 0 and C.refillPotion() then amount = C.potionInfo() end
	if amount == 0 and not C.noPotWarned then
		C.noPotWarned = true
		notify("warn", "No potion", "Put a health potion in toolbar slot " .. Options.PotionSlot.Value .. ".")
		dlog("warn", "No potion — retreating to regen instead")
	end
	local spot = C.retreatPoint()
	C.disengage(true)
	E.stopBlock()
	if spot then
		C.status = "flying up to heal"
		E.moveToken += 1
		local token = E.moveToken
		E.moving = true
		E.setNoclip(true)
		E.blockInput(true)
		E.flyTo(spot, token, Options.FlySpeed.Value)
		E.moving = false
	end
	local pin
	local r2 = getRoot()
	if r2 then
		local hold = r2.CFrame
		pin = RunService.Heartbeat:Connect(function()
			local r = getRoot()
			if r then r.AssemblyLinearVelocity = Vector3.zero r.CFrame = hold end
		end)
	end
	if amount and amount > 0 then
		dlog("heal", "Drinking " .. tostring(potName or "potion") .. " (" .. tostring(amount) .. " left)")
		dbg.heals += 1
		pcall(C.drink)
	end
	local t = os.clock()
	local limit = (amount and amount > 0) and 25 or 45
	if kind == "regen" and amount and amount > 0 then limit = 0 end
	while alive and os.clock() - t < limit do
		local hum = getHum()
		if not hum or hum.Health <= 0 then break end
		if hum.Health / hum.MaxHealth * 100 >= Options.HealUntil.Value then break end
		C.status = string.format("healing %d%%", hum.Health / hum.MaxHealth * 100)
		task.wait(0.3)
	end
	if pin then pin:Disconnect() end
	E.setNoclip(false)
	E.blockInput(false)
	C.healing = false
end

function C.finishTarget()
	local t = E.target
	local root = getRoot()
	if not (t and root and t.model.Parent and t.hum.Health > 0 and t.hum.Health < t.hum.MaxHealth) then return false end
	if (t.root.Position - root.Position).Magnitude > 80 then return false end
	local model = t.model
	C.fight(function(e) return e.model == model end, nil, 100, "finishing")
	return true
end
C.lastNameAt = {}
function C.countKill(t)
	if not t or C.counted[t.model] then return end
	C.counted[t.model] = true
	if C.lastNameAt[t.name] and os.clock() - C.lastNameAt[t.name] < 4 and t.group and t.group.boss then return end
	C.lastNameAt[t.name] = os.clock()
	dbg.kills += 1
	C.lastKillAt = os.clock()
	if t.group and t.group.boss then
		dbg.bosses += 1
		dlog("boss", t.name .. " defeated")
	end
end
C.counted = setmetatable({}, {__mode = "k"})
C.soulTried = setmetatable({}, {__mode = "k"})
function C.souls(range)
	local out = {}
	local root = getRoot()
	local deb = workspace:FindFirstChild("Debree")
	if not (root and deb) then return out end
	range = range or (Options.SoulRange and Options.SoulRange.Value) or 60
	for _, m in ipairs(deb:GetChildren()) do
		local sp = m:FindFirstChild("SoulPrompt", true)
		if sp and sp:IsA("ProximityPrompt") and sp.Enabled and (C.soulTried[sp] or 0) < 3 then
			local pos = E.promptPos(sp)
			if pos and (pos - root.Position).Magnitude <= range then table.insert(out, sp) end
		end
	end
	return out
end
function C.eatSouls(range)
	local n = 0
	for _, sp in ipairs(C.souls(range)) do
		C.soulTried[sp] = (C.soulTried[sp] or 0) + 1
		local m = sp:FindFirstAncestorOfClass("Model")
		E.usePrompt(sp, 0.4)
		task.wait(0.5)
		if not sp.Parent or not sp.Enabled then
			n += 1
			dbg.souls = (dbg.souls or 0) + 1
			dlog("loot", "Claimed " .. (m and m.Name or "a soul"))
		end
	end
	return n
end
function C.fight(filter, center, radius, label)
	local root, hum = getRoot(), getHum()
	if not (root and hum) or hum.Health <= 0 then C.disengage() return "dead" end
	local healKind = C.needHeal()
	if healKind then C.heal(healKind) return "heal" end
	local t = E.target
	if t and (t.hum.Health <= 0 or not t.model.Parent) then C.countKill(t) end
	if not (t and t.root.Parent and t.hum.Health > 0 and (not filter or filter(t)) and E.sane(t, root)) then
		t = nil
		local area = center or root.Position
		local bestD
		for _, e in ipairs(E.enemies()) do
			if (not filter or filter(e)) and E.sane(e, root) and (e.root.Position - area).Magnitude <= (radius or 300) then
				local d = (e.root.Position - root.Position).Magnitude
				if not bestD or d < bestD then t, bestD = e, d end
			end
		end
	end
	if t then
		local d = (t.root.Position - root.Position).Magnitude
		local engage = Options.EngageDist.Value
		local harmless = tostring(t.folder):find("Civilian") or tostring(t.name):find("Civilian")
		local downed = t.hum:GetState() == Enum.HumanoidStateType.Physics and not (t.group and t.group.boss) and not harmless
		local justUp = C.ragTarget == t.model and d < 30
		if ((d > engage and not E.hoverConn) or d > engage * 4) and not (downed and d < 40) and not justUp then
			C.disengage(true)
			E.target = t
			C.status = "walking to " .. t.name
			if not E.travel(t.root.Position, math.max(engage - 4, 5)) and E.WK.lastUnreachable then
				E.badTarget[t.model] = os.clock() + 40
				E.target = nil
			end
			return "travel"
		end
		if downed then
			E.target = t
			if C.ragTarget ~= t.model then
				C.ragTarget = t.model
				if E.hoverConn then
					E.stopHover()
					E.setNoclip(false)
					E.blockInput(false)
				end
				E.aimOn = false
				local root2 = getRoot()
				if root2 then
					local away = Vector3.new(root2.Position.X - t.root.Position.X, 0, root2.Position.Z - t.root.Position.Z)
					if away.Magnitude > 0.1 then E.WK.lastDash = 0 E.WK.dash(away.Unit) end
				end
			end
			C.status = "mob knocked down · waiting · " .. t.name
			return "ragdoll", t
		end
		C.ragTarget = nil
		C.status = (label or "fighting") .. " · " .. t.name
		C.filter = filter
		C.engage(t)
		return "fight", t
	end
	C.disengage()
	if Options.AutoLoot.Value and E.lootNearby() then
		C.status = "looting"
		E.collectLoot(140)
		return "loot"
	end
	if Options.EatSouls.Value and #C.souls() > 0 then
		C.status = "eating souls"
		C.eatSouls()
		return "souls"
	end
	if center and (center - root.Position).Magnitude > (Options.HoldRadius.Value or 60) then
		C.status = "going to " .. (label or "the spot")
		E.travel(center, 10)
		return "travel"
	end
	C.status = "waiting for " .. (label or "mobs")
	local r = getRoot()
	if r and not E.moving then r.AssemblyLinearVelocity = Vector3.zero end
	return "wait"
end

local Q = {}
function Q.info(name) return M.Quests and M.Quests.Holder and M.Quests.Holder[name] end
function Q.active()
	local d = getData()
	local out = {}
	if not d then return out end
	for _, c in ipairs(d.Quests.Holder:GetChildren()) do
		local qs = c:FindFirstChild("QuestString")
		local q = {inst = c, name = qs and qs.Value or c.Name, tasks = {}, done = true}
		local tf = c:FindFirstChild("Tasks")
		for _, tk in ipairs(tf and tf:GetChildren() or {}) do
			local v, mx, code = tk:FindFirstChild("Value"), tk:FindFirstChild("Max"), tk:FindFirstChild("Code")
			local item = {name = tk.Name, value = v and v.Value or 0, max = mx and mx.Value or 1, code = code and code.Value or tk.Name, inst = tk}
			item.done = item.value >= item.max
			if not item.done then q.done = false end
			table.insert(q.tasks, item)
		end
		local info = Q.info(q.name)
		q.category = info and info.Category or "?"
		table.insert(out, q)
	end
	return out
end
function Q.activeByCategory(cat)
	for _, q in ipairs(Q.active()) do
		if q.category == cat then return q end
	end
	return nil
end
function Q.state(name)
	if not M.Quests then return "None" end
	local ok, s = isolated(M.Quests.GetPlayerQuestState, player, name)
	return ok and s or "None"
end
function Q.canAdd(name, ignoreCd)
	if not M.Quests then return false end
	local ok, a, b, c = isolated(M.Quests.CanAddQuest, player, name, ignoreCd)
	return ok and a == true, b, c
end
function Q.npcModel(npcName)
	local R = workspace:FindFirstChild("Debree") and workspace.Debree:FindFirstChild("Regions")
	if not R then return nil end
	local n = W.npcs[npcName]
	for _, reg in ipairs(R:GetChildren()) do
		local st = reg:FindFirstChild("StationaryNpcs")
		local m = st and (st:FindFirstChild(npcName) or (n and st:FindFirstChild(n.code)))
		if m then return m end
	end
	return nil
end
function Q.chatPrompt(m)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("ProximityPrompt") and d.Enabled and (d.ActionText == "Chat" or d.ActionText == "Talk") then return d end
	end
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("ProximityPrompt") and d.Enabled then return d end
	end
	return nil
end
function Q.buttons()
	local ch = player.PlayerGui:FindFirstChild("ComponentsHolder")
	local df = ch and ch:FindFirstChild("DialogueFrame")
	local bh = df and df:FindFirstChild("Actual") and df.Actual:FindFirstChild("ButtonHolder")
	return bh, df
end
function Q.click(holder)
	local btn = holder and (holder:IsA("GuiButton") and holder or holder:FindFirstChildWhichIsA("GuiButton", true))
	if not btn then return false end
	local fired = false
	for _, sig in ipairs({"MouseButton1Click", "Activated", "MouseButton1Down"}) do
		local ok, cons = pcall(getconnections, btn[sig])
		if ok then
			for _, c in ipairs(cons) do
				if c.Function then task.spawn(c.Function) fired = true end
			end
		end
		if fired then break end
	end
	return fired
end
function Q.closeDialogue()
	for _ = 1, 4 do
		local bh, df = Q.buttons()
		if not df then return true end
		local close
		for _, b in ipairs(bh and bh:GetChildren() or {}) do
			if b.Name:find("^ZZZZ") then close = b end
		end
		if close then Q.click(close) else
			if M.SignalEvent then pcall(M.SignalEvent.ToServer, "NpcTalking", "Ended") end
			break
		end
		task.wait(0.6)
	end
	if M.SignalEvent then pcall(M.SignalEvent.ToServer, "NpcTalking", "Ended") end
	return Q.buttons() == nil
end
function Q.talk(npcName)
	local n = W.npcs[npcName]
	local m = Q.npcModel(npcName)
	if not m and n then
		E.travel(n.pos + Vector3.new(0, 3, 0), 30)
		local t0 = os.clock()
		repeat task.wait(0.3) m = Q.npcModel(npcName) until m or os.clock() - t0 > 6
	end
	if not m then return false, "NPC " .. tostring(npcName) .. " not found" end
	local pr = Q.chatPrompt(m)
	local at = posOf(m:FindFirstChild("HumanoidRootPart") or m)
	if not (pr and at) then return false, "no chat prompt" end
	local root = getRoot()
	if root and (root.Position - at).Magnitude > math.max(pr.MaxActivationDistance - 2, 4) then
		E.travel(at + Vector3.new(0, 1, 0), math.max(pr.MaxActivationDistance - 3, 3))
	end
	for _ = 1, 2 do
		E.fire(pr)
		local t0 = os.clock()
		repeat task.wait(0.2) until Q.buttons() or os.clock() - t0 > 3
		if Q.buttons() then return true end
		pcall(function() pr:InputHoldBegin() task.wait(0.15) pr:InputHoldEnd() end)
	end
	return Q.buttons() ~= nil, "dialogue didn't open"
end
function Q.waitDoing(name, secs)
	local t0 = os.clock()
	repeat
		if Q.state(name) == "Doing" then return true end
		task.wait(0.25)
	until os.clock() - t0 > secs
	return Q.state(name) == "Doing"
end
function Q.waitCooldown(name)
	local t0 = os.clock()
	while os.clock() - t0 < 11 do
		local ok, _, other = Q.canAdd(name)
		if ok then return true end
		if type(other) == "string" and other ~= name and Q.state(other) == "Doing" then return false, "already doing " .. other end
		task.wait(0.5)
	end
	return true
end
function Q.findButton(bh, name)
	if not bh then return nil end
	local btn = bh:FindFirstChild(name)
	if btn then return btn end
	local low = name:lower()
	for _, b in ipairs(bh:GetChildren()) do
		if b.Name:lower() == low then return b end
		local lbl = b:FindFirstChildWhichIsA("TextLabel", true) or (b:IsA("TextButton") and b)
		if lbl and tostring(lbl.Text):lower():find(low, 1, true) then return b end
	end
	return nil
end
function Q.accept(name)
	local info = Q.info(name)
	if not info then return false, "unknown quest" end
	if Q.state(name) == "Doing" then return true end
	local cdOk, cdWhy = Q.waitCooldown(name)
	if not cdOk then return false, "can't take it: " .. tostring(cdWhy) end
	local npc = info.OfferNpc
	if not npc then
		for _ = 1, 2 do
			if M.SignalEvent then pcall(M.SignalEvent.ToServer, "AddQuest", name) end
			if Q.waitDoing(name, 2) then return true end
		end
		return false, "server refused"
	end
	local ok, why = Q.talk(npc)
	if not ok then Q.closeDialogue() return false, why end
	task.wait(0.4)
	local names = {}
	local bh = Q.buttons()
	for _, b in ipairs(bh and bh:GetChildren() or {}) do if b:IsA("GuiObject") then table.insert(names, b.Name) end end
	local btn = Q.findButton(bh, name)
	if btn then Q.click(btn) end
	local taken = Q.waitDoing(name, btn and 3 or 0.5)
	for _ = 1, 2 do
		if taken or not M.SignalEvent then break end
		pcall(M.SignalEvent.ToServer, "AddQuest", name)
		taken = Q.waitDoing(name, 2)
	end
	Q.closeDialogue()
	if taken or Q.state(name) == "Doing" then
		dlog("quest", "Took quest: " .. name)
		return true
	end
	return false, (btn and "clicked but not taken" or "no button for it") .. (#names > 0 and (" [" .. table.concat(names, ", ") .. "]") or "")
end
function Q.deliver(questName, taskName, npcName)
	local ok, why = Q.talk(npcName)
	if not ok then return false, why end
	task.wait(0.4)
	if M.SignalEvent then pcall(M.SignalEvent.ToServer, "QuestProgress", questName, taskName) end
	task.wait(1)
	Q.closeDialogue()
	return true
end
function Q.abandon(q)
	if M.SignalEvent and q and q.inst then pcall(M.SignalEvent.ToServer, "RemoveQuest", q.inst.Name) end
end

function Q.killQuest(info)
	if type(info) ~= "table" or not info.QuestInstance then return false end
	if info.WenCostOnAccept or info.ItemCostOnAccept or info.GrantItemOnAccept then return false end
	local tf = info.QuestInstance:FindFirstChild("Tasks")
	if not tf or #tf:GetChildren() == 0 then return false end
	for _, tk in ipairs(tf:GetChildren()) do
		local code = tk:FindFirstChild("Code")
		if not (code and W.byCode[code.Value]) then return false end
	end
	return true
end
function Q.eligible(name, info)
	info = info or Q.info(name)
	if not info then return false end
	local req = info.Requirements or {}
	local lvl = playerLevel()
	if req.Level and lvl < req.Level then return false end
	if req.MaxLevel and lvl > req.MaxLevel then return false end
	if req.Race then
		local race = playerRace()
		if not table.find(req.Race, race) and not (race == "Human" and table.find(req.Race, "Slayer")) then return false end
	end
	if info.LogCompletion and Q.state(name) == "Done" then return false end
	return true
end
function Q.estimate(info)
	local secs = 40
	local tf = info.QuestInstance:FindFirstChild("Tasks")
	for _, tk in ipairs(tf:GetChildren()) do
		local mx, code = tk:FindFirstChild("Max"), tk:FindFirstChild("Code")
		local g = code and W.byCode[code.Value]
		local n = mx and mx.Value or 1
		if g and g.boss then secs += n * (45 + g.spawnTime * 0.35) else secs += n * 14 end
	end
	return secs
end
function Q.sideOf(info)
	local race = info.Requirements and info.Requirements.Race
	if not race then return "Any" end
	local d, s = table.find(race, "Demon") ~= nil, table.find(race, "Slayer") ~= nil
	if d and not s then return "Demon" end
	if s and not d then return "Slayer" end
	return "Any"
end
function Q.candidates(side)
	local out = {}
	for name, info in pairs(M.Quests and M.Quests.Holder or {}) do
		if info.Category == "Combat" and Q.killQuest(info) and Q.eligible(name, info) then
			local s = Q.sideOf(info)
			if side == nil or side == "Any" or s == side then
				local wen = info.Rewards and info.Rewards.Wen or 0
				local secs = Q.estimate(info)
				table.insert(out, {name = name, info = info, wen = wen, exp = info.Rewards and info.Rewards.Exp or 0, secs = secs, rate = wen / secs * 3600, side = s})
			end
		end
	end
	table.sort(out, function(a, b) return a.rate > b.rate end)
	return out
end
function Q.groupForTask(tk)
	return W.byCode[tk.code]
end
function Q.runStep(q, label)
	for _, tk in ipairs(q.tasks) do
		if not tk.done then
			local g = Q.groupForTask(tk)
			if g then
				local filter = function(e) return e.code == g.code or e.folder == g.name end
				C.fight(filter, g.center, math.max(g.despawn, 250), (label or "quest") .. " · " .. g.name .. " " .. tk.value .. "/" .. tk.max)
				return true
			end
			local info = Q.info(q.name)
			local spec = info and info.TaskSpecs and info.TaskSpecs[tk.name]
			if spec and spec.Type == "Deliver" and spec.TargetNpc then
				C.disengage()
				C.status = "handing in to " .. spec.TargetNpc
				Q.deliver(q.name, tk.name, spec.TargetNpc)
				task.wait(1)
				return true
			end
			return false
		end
	end
	return true
end

local B = {cooldown = {}, current = nil, lastAccept = 0, deaths = {}, skip = {}}
function B.hunts()
	local out = {}
	local now = workspace:GetServerTimeNow()
	for _, h in ipairs(RS:FindFirstChild("BossHunts") and RS.BossHunts:GetChildren() or {}) do
		local boss = h:GetAttribute("Boss")
		local entry = boss and M.BossHunts and M.BossHunts.Entry(boss)
		local ok, elig = false, false
		if entry then ok, elig = isolated(M.BossHunts.Eligible, entry, player) end
		table.insert(out, {id = h.Name, boss = boss, tier = h:GetAttribute("Tier"), side = h:GetAttribute("Side"), quest = h:GetAttribute("Quest") or (boss and "Eliminate " .. boss),
			expires = tonumber(h:GetAttribute("ExpiresAt")) or 0, left = (tonumber(h:GetAttribute("ExpiresAt")) or 0) - now, eligible = ok and elig == true, entry = entry})
	end
	return out
end
B.TIER = {Mythic = 6, Legendary = 5, Epic = 4, Rare = 3, UnCommon = 2, Common = 1}
function B.pick()
	local best, bestScore
	for _, h in ipairs(B.hunts()) do
		local big = h.entry and h.entry.MaxLevel == nil and (h.entry.Level or 0) >= 200
		if h.eligible and big and h.left > 90 and h.boss and W.byName[h.boss]
			and Q.state(h.quest) ~= "Done" and not (B.cooldown[h.boss] and os.clock() < B.cooldown[h.boss]) then
			local g = W.byName[h.boss]
			local root = getRoot()
			local dist = root and (g.center - root.Position).Magnitude or 0
			local score = (B.TIER[h.tier] or 0) * 1000 - dist / 10
			if not bestScore or score > bestScore then best, bestScore = h, score end
		end
	end
	return best
end
function B.claim(h)
	if not (M.SignalEvent and h and h.id) then return false, "no hunt" end
	pcall(M.SignalEvent.ToServer, "BossHuntsRequest", {action = "Claim", id = h.id})
	local t0 = os.clock()
	repeat task.wait(0.3) until Q.activeByCategory("BossHunt") or os.clock() - t0 > 4
	if Q.activeByCategory("BossHunt") then return true end
	return false, "the crow refused"
end
function B.bossAlive(name)
	for _, e in ipairs(E.enemies()) do
		if e.folder == name or e.name == name then return e end
	end
	return nil
end

local HomeTab = newTab("Home", "home")
local FarmTab = newTab("Farm", "swords")
local BossTab = newTab("Bosses", "skull")
local WorldTab = newTab("World", "globe")
local CombatTab = newTab("Combat", "target")
local PlayerTab = newTab("Player", "player")
local SettingsTab = newTab("Settings", "gear")
local QuestTab, VisualTab, HookTab = FarmTab, PlayerTab, SettingsTab
local UI = {}
register("CfgVer", 0, function() end)

do
	local homeCard = make("Frame", {Parent = HomeTab.container, LayoutOrder = nextOrder(HomeTab), Size = UDim2.new(1, 0, 0, 214), BackgroundColor3 = T.Element, BackgroundTransparency = 0.15, ClipsDescendants = true}, {corner(12)})
	UI.homeCard = homeCard
	local homeStroke = stroke(T.Accent, 0.35); homeStroke.Parent = homeCard
	accent(homeStroke, "Color")
	local glow = make("Frame", {Parent = homeCard, Size = UDim2.new(0.6, 0, 1, 0), BackgroundColor3 = T.Accent, BackgroundTransparency = 0.82, BorderSizePixel = 0}, {
		make("UIGradient", {Transparency = NumberSequence.new(0, 1)}),
	})
	accent(glow, "BackgroundColor3")
	local shine = make("UIGradient", {Parent = homeStroke, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(0.18, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 150, 150)), ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))})})
	connect(RunService.Heartbeat, function(dt) shine.Rotation = (shine.Rotation + dt * 40) % 360 end)
	local lattice = make("Frame", {Parent = homeCard, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0.55, 0, 1, 0), BackgroundTransparency = 1, ClipsDescendants = true}, {
		make("UIGradient", {Transparency = NumberSequence.new(1, 0)}),
	})
	for i = -4, 16 do
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
	end
	bracket(0, 0) bracket(1, 0) bracket(0, 1) bracket(1, 1)

	local avatarHolder = make("Frame", {Parent = homeCard, Position = UDim2.fromOffset(14, 14), Size = UDim2.fromOffset(142, 186), BackgroundColor3 = T.Bg, BackgroundTransparency = 0.3}, {corner(10)})
	local avStroke = stroke(T.Accent, 0.5); avStroke.Parent = avatarHolder
	accent(avStroke, "Color")
	UI.viewport = make("ViewportFrame", {Parent = avatarHolder, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ImageTransparency = 1, Ambient = Color3.fromRGB(170, 170, 170), LightColor = Color3.fromRGB(255, 255, 255), LightDirection = Vector3.new(-0.5, -1, -0.8)}, {corner(10)})
	UI.avatarLoading = label({Parent = avatarHolder, Size = UDim2.fromScale(1, 1), Text = "Loading…", Font = FONT, TextSize = 12, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Center})

	local info = make("Frame", {Parent = homeCard, Position = UDim2.fromOffset(170, 14), Size = UDim2.new(1, -184, 1, -28), BackgroundTransparency = 1})
	UI.hello = accent(label({Parent = info, Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 0, 16), Text = "WELCOME BACK", Font = FONT_B, TextSize = 11}), "TextColor3")
	UI.nameLabel = label({Parent = info, Position = UDim2.fromOffset(0, 16), Size = UDim2.new(0.6, 0, 0, 28), Text = player.DisplayName, Font = FONT_B, TextSize = 24, TextTruncate = Enum.TextTruncate.AtEnd})
	UI.userLabel = label({Parent = info, Position = UDim2.fromOffset(0, 44), Size = UDim2.new(0.6, 0, 0, 16), Text = "@" .. player.Name, Font = FONT, TextSize = 13, TextColor3 = T.SubText})

	local repBox = make("Frame", {Parent = info, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(190, 62), BackgroundColor3 = T.Bg, BackgroundTransparency = 0.25}, {corner(10)})
	local rs = stroke(T.Accent, 0.45); rs.Parent = repBox accent(rs, "Color")
	label({Parent = repBox, Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -24, 0, 14), Text = "REPUTATION", Font = FONT_B, TextSize = 10, TextColor3 = T.SubText})
	UI.repValue = label({Parent = repBox, Position = UDim2.fromOffset(12, 20), Size = UDim2.new(1, -24, 0, 30), Text = "…", Font = FONT_B, TextSize = 26, TextTruncate = Enum.TextTruncate.AtEnd})
	UI.repDelta = label({Parent = repBox, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 6), Size = UDim2.fromOffset(90, 14), Text = "", Font = FONT_M, TextSize = 10, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Right})

	local pills = make("Frame", {Parent = info, Position = UDim2.fromOffset(0, 72), Size = UDim2.new(1, 0, 0, 112), BackgroundTransparency = 1}, {
		make("UIGridLayout", {CellSize = UDim2.new(0.333, -6, 0, 50), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder}),
	})
	UI.pills = {}
	local function pill(order, title)
		local f = make("Frame", {Parent = pills, LayoutOrder = order, BackgroundColor3 = T.Bg, BackgroundTransparency = 0.35}, {corner(8)})
		local s = stroke(T.Stroke, 0.6); s.Parent = f
		local t = label({Parent = f, Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -16, 0, 14), Text = title, Font = FONT, TextSize = 11, TextColor3 = T.SubText})
		local v = label({Parent = f, Position = UDim2.fromOffset(10, 22), Size = UDim2.new(1, -16, 0, 20), Text = "…", Font = FONT_B, TextSize = 15, TextTruncate = Enum.TextTruncate.AtEnd})
		UI.pills[order] = {t = t, v = v}
		return v
	end
	UI.levelValue = pill(1, "Level")
	UI.wenValue = pill(2, "Wen")
	UI.raceValue = pill(3, "Race")
	UI.artValue = pill(4, "Demon Art")
	UI.clanValue = pill(5, "Clan")
	UI.rankValue = pill(6, "Rank")
end

do
	local function card2(title, height)
		local c = make("Frame", {Parent = HomeTab.container, LayoutOrder = nextOrder(HomeTab), Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = T.Element, BackgroundTransparency = 0.15}, {corner(10)})
		stroke(T.Stroke, 0.7).Parent = c
		local dot = make("Frame", {Parent = c, Position = UDim2.fromOffset(14, 15), Size = UDim2.fromOffset(7, 7), Rotation = 45, BackgroundColor3 = T.Accent, BorderSizePixel = 0})
		accent(dot, "BackgroundColor3")
		accent(label({Parent = c, Position = UDim2.fromOffset(30, 8), Size = UDim2.fromOffset(240, 22), Text = title, Font = FONT_B, TextSize = 11}), "TextColor3")
		return c, dot
	end
	UI.tiles = {}
	local function grid(parent, y, cols, cellH)
		return make("Frame", {Parent = parent, Position = UDim2.fromOffset(12, y), Size = UDim2.new(1, -24, 1, -(y + 12)), BackgroundTransparency = 1}, {
			make("UIGridLayout", {CellSize = UDim2.new(1 / cols, -6, 0, cellH), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder}),
		})
	end
	local order = 0
	local function tile(parent, key, caption)
		order += 1
		local f = make("Frame", {Parent = parent, LayoutOrder = order, BackgroundColor3 = T.Bg, BackgroundTransparency = 0.35}, {corner(7)})
		stroke(T.Stroke, 0.75).Parent = f
		label({Parent = f, Position = UDim2.fromOffset(9, 5), Size = UDim2.new(1, -14, 0, 12), Text = caption, Font = FONT_M, TextSize = 10, TextColor3 = T.SubText})
		UI.tiles[key] = label({Parent = f, Position = UDim2.fromOffset(9, 19), Size = UDim2.new(1, -14, 0, 18), Text = "-", RichText = true, Font = FONT_B, TextSize = 14, TextTruncate = Enum.TextTruncate.AtEnd})
	end
	local live
	live, UI.logDot = card2("ACTIVITY", 214)
	UI.badge = make("TextLabel", {Parent = live, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 8), Size = UDim2.fromOffset(190, 22), BackgroundColor3 = T.Bg,
		BackgroundTransparency = 0.2, Text = "Idle", RichText = true, Font = FONT_B, TextSize = 12, TextColor3 = T.Text, TextTruncate = Enum.TextTruncate.AtEnd}, {corner(11)})
	stroke(T.Stroke, 0.5).Parent = UI.badge
	UI.note = label({Parent = live, Position = UDim2.fromOffset(14, 34), Size = UDim2.new(1, -28, 0, 16), Text = "", Font = FONT, TextSize = 12, TextColor3 = T.SubText, TextTruncate = Enum.TextTruncate.AtEnd})
	local g = grid(live, 58, 5, 44)
	tile(g, "farm", "FARM") tile(g, "target", "TARGET") tile(g, "hp", "YOUR HP") tile(g, "region", "REGION") tile(g, "quest", "QUEST")
	tile(g, "time", "SESSION") tile(g, "wen", "WEN EARNED") tile(g, "rep", "REP CHANGE") tile(g, "kills", "KILLS") tile(g, "bosses", "BOSSES")
	tile(g, "quests", "QUESTS DONE") tile(g, "loot", "DROPS") tile(g, "deaths", "DEATHS") tile(g, "ping", "PING") tile(g, "fps", "FPS")

	local lg = card2("LOG", 250)
	UI.logBtns = {}
	for i, name in ipairs({"Clear", "Copy"}) do
		local b = make("TextButton", {Parent = lg, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12 - (i - 1) * 64, 0, 8), Size = UDim2.fromOffset(58, 22),
			BackgroundColor3 = T.Bg, BackgroundTransparency = 0.3, Text = name, Font = FONT_M, TextSize = 11, TextColor3 = T.SubText, AutoButtonColor = false}, {corner(6)})
		stroke(T.Stroke, 0.6).Parent = b
		connect(b.MouseEnter, function() tween(b, {TextColor3 = T.Accent}) end)
		connect(b.MouseLeave, function() tween(b, {TextColor3 = T.SubText}) end)
		UI.logBtns[name] = b
	end
	label({Parent = lg, Position = UDim2.fromOffset(14, 226), Size = UDim2.new(1, -28, 0, 16), Text = "Saved to AxiomHUB/ouwland_log.txt", Font = FONT, TextSize = 10, TextColor3 = T.SubText})
	UI.logScroll = make("ScrollingFrame", {Parent = lg, Position = UDim2.fromOffset(10, 38), Size = UDim2.new(1, -20, 0, 184), BackgroundColor3 = T.Bg, BackgroundTransparency = 0.4, BorderSizePixel = 0,
		ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y}, {
		corner(8),
		make("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}),
		make("UIPadding", {PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 6)}),
	})
	accent(UI.logScroll, "ScrollBarImageColor3")

	local credit = make("Frame", {Parent = HomeTab.container, LayoutOrder = nextOrder(HomeTab), Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = T.Element, BackgroundTransparency = 0.15}, {corner(10)})
	stroke(T.Stroke, 0.7).Parent = credit
	app.drawMark(make("Frame", {Parent = credit, Position = UDim2.fromOffset(8, 11), Size = UDim2.fromOffset(36, 36), BackgroundTransparency = 1}), 34, 2)
	label({Parent = credit, Position = UDim2.fromOffset(46, 10), Size = UDim2.new(1, -60, 0, 18), Text = APP_NAME .. " · Ouwland", Font = FONT_B, TextSize = 14})
	label({Parent = credit, Position = UDim2.fromOffset(46, 30), Size = UDim2.new(1, -60, 0, 16), Text = "made by <b>" .. AUTHOR .. "</b>", RichText = true, Font = FONT, TextSize = 12, TextColor3 = T.SubText})
end

UI.LOG_COLORS = {info = "#c8ccbc", move = "#6fb7ff", skill = "#ffb35c", quest = "#c39bff", heal = "#6ee39a", loot = "#ffd75c", warn = "#ff7a6e",
	kill = "#e8e8e8", boss = "#ff9d8a", farm = "#9fd8ff", world = "#8fd6b0"}
UI.logCount = 0
function UI.drawLog(entry)
	UI.logCount += 1
	local line = label({Parent = UI.logScroll, LayoutOrder = UI.logCount, Size = UDim2.new(1, 0, 0, 17), RichText = true, Font = FONT, TextSize = 12, TextTransparency = 1, TextTruncate = Enum.TextTruncate.AtEnd,
		Text = string.format('<font color="#7c8070">%s</font>  <font color="%s">%s</font>', entry.t, UI.LOG_COLORS[entry.kind] or UI.LOG_COLORS.info, entry.text)})
	tween(line, {TextTransparency = 0}, 0.3)
	local kids = {}
	for _, c in ipairs(UI.logScroll:GetChildren()) do if c:IsA("TextLabel") then table.insert(kids, c) end end
	if #kids > 50 then
		table.sort(kids, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
		kids[1]:Destroy()
	end
	task.defer(function() UI.logScroll.CanvasPosition = Vector2.new(0, math.huge) end)
end

function UI.toolbarItems()
	local d = getData()
	local out = {}
	if not d then return out end
	local NAMES = {"One", "Two", "Three", "Four", "Five"}
	for i, n in ipairs(NAMES) do
		local v = d.Inventory.Toolbar:FindFirstChild(n)
		local name = "empty"
		if v and v.Value ~= 0 and M.CIP then
			local ok, obj = isolated(M.CIP.GetItemFromId, player, v.Value)
			name = ok and obj and obj.Name or ("#" .. v.Value)
		end
		out[i] = name
	end
	return out
end
function UI.weaponChoices()
	local items = UI.toolbarItems()
	local out = {}
	for i = 1, 5 do table.insert(out, i .. " · " .. (items[i] or "empty")) end
	return out
end

local function hidden(flag, value)
	local o = register(flag, value, function() end)
	o.NoSave = true
	o.NoRefresh = true
	return o
end
for flag, v in pairs({
	SoulRange = 60, SkillHold = 0.3, HoverBack = 1.5, HoverSpeed = 16, EngageDist = 14,
	WalkRun = true, WalkDash = true, WalkDashGap = 1, WalkStamina = true, HoldRadius = 70, AutoLoot = true,
	HealAt = 45, HealUntil = 85, PotionSlot = 5, HealHeight = 60, BlockHold = 0.5, ParryRange = 14, PerfectLead = 0.18,
	ShrineGain = 400, FlySpeed = 34, LockControls = true, HorseMinDist = 80, HorseSpeed = 50, HorseSlot = 4, KeepHorse = false,
	LevelQuest = true, BuyPotsAt = 5, BuyPotCount = 30, HorseBudget = 15000, DashCD = 0.3, ESPRange = 500, HookEvery = 30,
	UseShrines = true, UseHorse = true, TravelMode = "Tween", BossBlock = true, ColdLantern = true, SunHat = true,
}) do hidden(flag, v) end
hidden("SealedTiers", {T1 = true, T2 = true, T3 = true})

UI.groupNames = {}
function UI.groupFromChoice() return nil end

do
	local c = card(FarmTab, "Auto Farm Level", {side = 1})
	toggleD(c, "LevelFarm", "Auto Farm Level", "Best mobs + quest for your level", false)
	slider(c, "HoverHeight", "Distance from mob", 2, 10, 0.5, 5, " studs")
	UI.levelNote = cardNote(c, "")
end
UI.prioCard = card(FarmTab, "Priority", {side = 2})
do
	local c = card(FarmTab, "Weapon", {side = 2})
	UI.weaponDrop = dropdown(c, "WeaponPick", "Fight with", UI.weaponChoices(), false, "1 · " .. (UI.toolbarItems()[1] or "?"))
	button(c, "Refresh toolbar", "Re-reads your 5 toolbar slots", function()
		UI.weaponDrop.SetValues(UI.weaponChoices())
		UI.masteryDrop.SetValues(UI.weaponChoices())
		notify("success", "Toolbar", "Slots refreshed.")
	end)
end
do
	local c = card(FarmTab, "Auto Farm Mastery", {side = 2})
	toggleD(c, "MasteryFarm", "Auto Farm Mastery", "Trains the picked item on easy mobs", false)
	UI.masteryDrop = dropdown(c, "MasteryItem", "Item to train", UI.weaponChoices(), false, "1 · " .. (UI.toolbarItems()[1] or "?"))
	UI.masteryNote = cardNote(c, "")
end

do
	local c = card(BossTab, "Boss Hunts", {side = 1})
	toggleD(c, "BossFarm", "Auto Farm Bosses", "3k HP hunts · kill, chest, loot", false)
	UI.huntList = cardNote(c, "", 120)
end
do
	local c = card(BossTab, "Pick Bosses to Kill", {side = 2})
	toggleD(c, "WorldBossFarm", "Kill picked bosses", "Any HP, waits for respawns", false)
	local names = {}
	for _, g in ipairs(W.groups) do if g.boss then table.insert(names, g.name) end end
	table.sort(names)
	dropdown(c, "WorldBosses", "Bosses", names, true, {})
	UI.worldBossNote = cardNote(c, "", 44)
end

UI.SPOT_FILE = "AxiomHUB/ouwland_spots.json"
function UI.loadSpots()
	local ok, t = pcall(function() return HttpService:JSONDecode(readfile(UI.SPOT_FILE)) end)
	return (ok and type(t) == "table") and t or {}
end
function UI.saveSpots(t)
	pcall(writefile, UI.SPOT_FILE, HttpService:JSONEncode(t))
end
do
	local c = card(BossTab, "Mark Spots", {side = 1})
	local names = {}
	for _, g in ipairs(W.groups) do if g.boss then table.insert(names, g.name) end end
	table.sort(names)
	local pick = dropdown(c, "SpotBoss", "Boss", names, false, names[1])
	pick.NoSave = true
	local noteL = cardNote(c, "", 34)
	local function refresh()
		local t = UI.loadSpots()
		local n, total = 0, 0
		for _, s in ipairs(t) do total += 1 if s.name == Options.SpotBoss.Value then n += 1 end end
		noteL.Text = string.format("<b>%s</b>: %d marked  ·  %d total", tostring(Options.SpotBoss.Value), n, total)
	end
	button(c, "Mark here", "Stand in the boss room and press", function()
		local r = getRoot()
		if not r then return end
		local t = UI.loadSpots()
		local p = r.Position
		table.insert(t, {name = Options.SpotBoss.Value, x = math.floor(p.X * 10) / 10, y = math.floor(p.Y * 10) / 10, z = math.floor(p.Z * 10) / 10})
		UI.saveSpots(t)
		dlog("world", string.format("Marked %s at %.0f, %.0f, %.0f", Options.SpotBoss.Value, p.X, p.Y, p.Z))
		notify("success", "Spot saved", Options.SpotBoss.Value)
		refresh()
	end)
	button(c, "Undo last", nil, function()
		local t = UI.loadSpots()
		local last = table.remove(t)
		UI.saveSpots(t)
		if last then notify("info", "Removed", last.name) end
		refresh()
	end)
	pick.Callback = refresh
	refresh()
end

do
	local c = card(QuestTab, "Auto Wen Farm", {side = 1})
	toggleD(c, "WenFarm", "Auto Wen Farm", "Best paying quest for your level", false)
	UI.wenList = cardNote(c, "", 96)
end
do
	local c = card(QuestTab, "Demon Quest Farm", {side = 1})
	toggleD(c, "DemonQuests", "Demon Quest Farm", "Demon-only quests for your level", false)
	UI.demonNote = cardNote(c, "", 44)
end
do
	local c = card(QuestTab, "Slayer Quest Farm", {side = 1})
	toggleD(c, "SlayerQuests", "Slayer Quest Farm", "Slayer-only quests for your level", false)
	UI.slayerNote = cardNote(c, "", 44)
end
do
	local c = card(QuestTab, "Current Quests", {side = 2})
	UI.activeQuests = cardNote(c, "", 70)
	button(c, "Abandon my kill quest", "Frees the slot for the farm", function()
		local q = Q.activeByCategory("Combat")
		if q then Q.abandon(q) notify("info", "Quest abandoned", q.name) else notify("warn", "No kill quest", "Nothing to abandon.") end
	end)
end
do
	local c = card(FarmTab, "Reputation", {side = 1})
	toggleD(c, "RepFarm", "Auto Rep", "Demon: -Rep · Slayer: +Rep", false)
	UI.repBig = label({Parent = c.container, LayoutOrder = nextOrder(c), Size = UDim2.new(1, 0, 0, 40), Text = "…", Font = FONT_B, TextSize = 30, TextXAlignment = Enum.TextXAlignment.Center})
	c.grow(44)
	UI.repNote = cardNote(c, "")
end
do
	local c = card(FarmTab, "Souls", {side = 2})
	toggleD(c, "EatSouls", "Auto Eat Souls", "Claims soul drops near you", false)
end

do
	local c = card(CombatTab, "Skills · silent aim", {side = 1})
	UI.skillNote = cardNote(c, "Skills from your current kit:", 20)
	local start = select(2, isolated(E.availableSkills)) or {}
	E.skillList = start
	local def = {}
	for _, n in ipairs(start) do if E.skillCategory(n) == "Evil Art" or E.skillCategory(n) == "Breathing" then def[n] = true end end
	UI.skillDrop = dropdown(c, "UseSkills", "Skills to use", start, true, def)
	toggle(c, "SkillsOn", "Use skills while fighting", true)
end
do
	local c = card(CombatTab, "Healing", {side = 2})
	toggleD(c, "AutoHeal", "Auto heal", "Flies up, drinks, comes back", true)
	cardNote(c, "Finds the potion in your toolbar or bag by itself.", 30)
end

do
	local c = card(CombatTab, "Survival", {side = 1})
	toggleD(c, "SunImmunity", "Sun Immunity", "Demons don't burn in the sun", true, function(on) E.setSunImmunity(on) end)
	toggle(c, "AntiStun", "Anti Stun", true)
	toggle(c, "AntiRagdoll", "Anti Ragdoll", true)
	toggle(c, "AntiKnockback", "Anti Knockback", true)
end
do
	local c = card(CombatTab, "Defense", {side = 2})
	toggle(c, "AutoBlock", "Auto Block", false)
	toggle(c, "AutoParry", "Auto Perfect Block", false)
end

do
	local c = card(WorldTab, "Travel", {side = 1})
	cardNote(c, "Shrines + Horse, or running with dashes.", 20)
	local names = {}
	for _, s in ipairs(W.shrines) do table.insert(names, s.name) end
	table.sort(names)
	local pick = dropdown(c, "ShrinePick", "Shrine", names, false, names[1])
	pick.NoSave = true
	button(c, "Travel to that shrine", nil, function()
		for _, s in ipairs(W.shrines) do
			if s.name == Options.ShrinePick.Value then
				if E.useShrine(s) then notify("success", "Shrine", s.name) else notify("warn", "Shrine", "Couldn't travel (combat?)") end
			end
		end
	end)
	button(c, "Stop moving", nil, function() E.stopMoving() C.disengage() end)
end

do
	local c = card(SettingsTab, "Performance", {side = 1})
	toggleD(c, "NoRender", "Disable 3D rendering", "Logo screen with live counters", false, function(on) Overlay.set(on) end)
	toggle(c, "FPSCapOn", "FPS cap", false, function(on) if setfpscap then pcall(setfpscap, on and Options.FPSCap.Value or 0) end end)
	slider(c, "FPSCap", "Max FPS", 5, 240, 5, 30, nil, function(v) if Options.FPSCapOn and Options.FPSCapOn.Value and setfpscap then pcall(setfpscap, v) end end)
	toggleD(c, "LowGfx", "Low graphics for long AFK", "Quality 1, no shadows, no particles", false)
end
do
	local c = card(SettingsTab, "Window", {side = 2})
	toggle(c, "ShowFloatButton", "Round minimize button", true, function(on) if UI.floatButton then UI.floatButton.Visible = on end end)
	toggle(c, "SkipIntro", "Skip the intro animation", false)
	colorPicker(c, "AccentColor", "Accent color", "#8E9A4E")
end

local F = {retry = {}, noQuest = {}}
function F.questTargets(info, code)
	local tf = info.QuestInstance and info.QuestInstance:FindFirstChild("Tasks")
	if not tf then return false end
	for _, tk in ipairs(tf:GetChildren()) do
		local c = tk:FindFirstChild("Code")
		if not (c and c.Value == code) then return false end
	end
	return true
end
F.tooHard, F.groupDeaths = {}, {}
function F.noteDeath()
	local code = F.lastLevelCode
	if not code then return end
	local list = F.groupDeaths[code] or {}
	F.groupDeaths[code] = list
	table.insert(list, os.clock())
	while list[1] and os.clock() - list[1] > 600 do table.remove(list, 1) end
	if #list >= 2 then
		F.tooHard[code] = os.clock() + 1800
		F.groupDeaths[code] = {}
		local g = W.byCode[code]
		dlog("warn", "Died twice at " .. (g and g.name or code) .. " · farming easier mobs for 30 min")
	end
end
function F.levelGroup()
	local lvl = playerLevel()
	local best
	for _, x in ipairs(W.groups) do
		local need = W.LEVELS[x.code]
		if need and need <= lvl and not x.boss and os.clock() > (F.tooHard[x.code] or 0) then
			if not best or need > W.LEVELS[best.code] then best = x end
		end
	end
	return best
end
function F.groupFilter(g)
	return function(e) return e.code == g.code or e.folder == g.name end
end
function F.waitRetry(key)
	return F.retry[key] and os.clock() < F.retry[key]
end

Farms.add({name = "Level farm", flag = "LevelFarm", priority = 7,
	enabled = function() return Options.LevelFarm.Value end,
	ready = function() return F.levelGroup() ~= nil end,
	step = function()
		local g = F.levelGroup()
		F.lastLevelCode = g.code
		if Options.LevelQuest.Value and not Q.activeByCategory("Combat") and not F.waitRetry("levelQuest") then
			if C.finishTarget() then return end
			local pick
			for _, cand in ipairs(Q.candidates()) do
				if F.questTargets(cand.info, g.code) then pick = cand break end
			end
			if not pick then
				F.retry.levelQuest = os.clock() + 60
			elseif not Q.canAdd(pick.name) and os.clock() - (F.cdSince or os.clock()) < 15 then
				F.cdSince = F.cdSince or os.clock()
				return C.fight(F.groupFilter(g), g.center, math.max(g.despawn, 250), "level · quest on cooldown")
			else
				F.cdSince = nil
				F.retry.levelQuest = os.clock() + 12
				C.disengage()
				C.status = "taking quest · " .. pick.name
				local ok, why = Q.accept(pick.name)
				if not ok then dlog("warn", "Quest " .. pick.name .. ": " .. tostring(why) .. " — trying again soon") end
				return
			end
		end
		local q = Q.activeByCategory("Combat")
		if q and not q.done and Options.LevelQuest.Value then
			for _, tk in ipairs(q.tasks) do
				if tk.code == g.code and not tk.done then return C.fight(F.groupFilter(g), g.center, math.max(g.despawn, 250), "level · " .. tk.value .. "/" .. tk.max) end
			end
		end
		C.fight(F.groupFilter(g), g.center, math.max(g.despawn, 250), "level · " .. g.name)
	end})

function F.masterySpot()
	local lvl = playerLevel()
	for _, s in ipairs({{"Mizunoto", 62}, {"Hoyuzo Subordinate", 40}, {"Bear Cub", 10}, {"Bandit", 0}}) do
		if lvl >= s[2] and W.byName[s[1]] then return W.byName[s[1]] end
	end
	return W.byName.Bandit
end
Farms.add({name = "Mastery farm", flag = "MasteryFarm", priority = 9,
	enabled = function() return Options.MasteryFarm.Value end,
	ready = function() return F.masterySpot() ~= nil end,
	start = function()
		local v = Options.MasteryItem.Value
		E.slotOverride = tonumber(type(v) == "string" and v:match("^(%d)"))
		E.lastEquipTry = 0
	end,
	stop = function() E.slotOverride = nil E.lastEquipTry = 0 end,
	step = function()
		local v = Options.MasteryItem.Value
		E.slotOverride = tonumber(type(v) == "string" and v:match("^(%d)"))
		local g = F.masterySpot()
		C.fight(F.groupFilter(g), g.center, math.max(g.despawn, 250), "mastery · " .. g.name)
	end})

function F.repTarget(forceMinus)
	if forceMinus or isDemonSide() and playerRace() ~= "Hybrid" or (playerRace() == "Hybrid" and Options.RepDirection and Options.RepDirection.Value == "-Rep") then
		local best, bestD
		local root = getRoot()
		for _, g in ipairs(W.groups) do
			if g.code == "Civilian" or g.name:find("Civilian") then
				local d = (root and (g.center - root.Position).Magnitude or 0) - (g.quantity or 1) * 1000
				if not bestD or d < bestD then best, bestD = g, d end
			end
		end
		return best, function(e) return e.folder:find("Civilian") ~= nil or e.name:find("Civilian") ~= nil end, "-Rep"
	end
	local lvl = playerLevel()
	local best
	for _, code in ipairs({"FireProfoundDemon", "IceProfoundDemon", "HighDemon", "GreaterDemon_ButterflyEstate", "LesserDemon_ButterflyEstate", "BloodHoundedDemon_MistfallHarbor", "BeastBornDemon_MistfallHarbor"}) do
		local g = W.byCode[code]
		if g and (W.LEVELS[code] or 0) <= lvl then best = g break end
	end
	return best, best and F.groupFilter(best), "+Rep"
end
Farms.add({name = "Rep farm", flag = "RepFarm", priority = 6,
	enabled = function() return Options.RepFarm.Value end,
	ready = function() return F.repTarget() ~= nil end,
	step = function()
		local g, filter, dir = F.repTarget()
		C.fight(filter, g.center, math.max(g.despawn, 300), dir .. " · " .. g.name)
	end})

function F.huntQuest()
	return Q.activeByCategory("BossHunt")
end
Farms.add({name = "Boss hunts", flag = "BossFarm", priority = 2,
	enabled = function() return Options.BossFarm.Value end,
	ready = function()
		if F.huntQuest() or B.lastBoss then return true end
		return not F.waitRetry("huntPick") and B.pick() ~= nil
	end,
	step = function()
		local q = F.huntQuest()
		if not q then
			if B.lastBoss then
				local at = B.lastBoss
				B.lastBoss = nil
				C.disengage()
				C.status = "looting the boss"
				B.lootBoss(at)
				return
			end
			local h = B.pick()
			if not h then F.retry.huntPick = os.clock() + 20 return end
			C.status = "taking hunt · " .. h.boss
			local ok, why = B.claim(h)
			if ok then
				dlog("boss", "Boss hunt taken: " .. h.boss .. " (" .. tostring(h.tier) .. ")")
				B.current = h
			else
				dlog("warn", "Hunt " .. h.boss .. " not given yet (hunt cooldown) — retrying in 30s")
				B.cooldown[h.boss] = os.clock() + 60
				F.retry.huntPick = os.clock() + 30
			end
			return
		end
		local tk = q.tasks[1]
		local g = tk and (W.byCode[tk.code] or W.byName[tk.code])
		if not g then
			for _, x in ipairs(W.groups) do
				if tk and x.boss and (x.code == tk.code or tk.name:find(x.name, 1, true)) then g = x break end
			end
		end
		if not g then C.status = "boss location unknown for " .. tostring(tk and tk.code) task.wait(2) return end
		B.lastBoss = g.center
		local e = B.bossAlive(g.name)
		if e then
			B.lastSeen = os.clock()
			local r = C.fight(function(x) return x.folder == g.name or x.name == g.name end, g.center, 400, "boss · " .. g.name)
			if e.hum.Health <= 0 then B.lastBoss = e.root.Position end
			return r
		end
		local root = getRoot()
		if root and (root.Position - g.center).Magnitude > 60 then
			C.status = "going to " .. g.name
			C.disengage()
			E.travel(g.center, 25)
			return
		end
		C.disengage()
		C.status = "waiting for " .. g.name .. " to spawn"
		task.wait(0.5)
	end})

function B.lootBoss(at)
	local t0 = os.clock()
	local killedAt = workspace:GetServerTimeNow() - 20
	while os.clock() - t0 < 8 do
		local opened = false
		for _, chest in ipairs(workspace:FindFirstChild("Chests") and workspace.Chests:GetChildren() or {}) do
			local p = chest:FindFirstChild("ChestPrompt", true)
			local pos = p and E.promptPos(p)
			local fresh = (tonumber(chest:GetAttribute("SpawnedAt")) or 0) >= killedAt
			if p and p.Enabled and pos and chest:GetAttribute("IsOpen") ~= true and ((fresh and (pos - at).Magnitude < 400) or (pos - at).Magnitude < 120)
				and not tostring(chest:GetAttribute("ChestId") or chest.Name):find("Sealed") then
				for _ = 1, 3 do
					E.usePrompt(p)
					task.wait(1)
					if chest:GetAttribute("IsOpen") == true then break end
				end
				dlog("loot", (chest:GetAttribute("IsOpen") == true and "Opened " or "Couldn't open ") .. chest.Name)
				opened = true
			end
		end
		if opened then break end
		task.wait(0.5)
	end
	task.wait(0.8)
	E.collectLoot(160)
	if Options.EatSouls.Value then C.eatSouls(120) end
end

B.worldState = {}
function B.worldPick()
	local sel = Options.WorldBosses.Value
	if type(sel) ~= "table" then return nil end
	local root = getRoot()
	local best, bestD
	for name, on in pairs(sel) do
		local g = on and W.byName[name]
		if g and not (B.worldState[name] and os.clock() < B.worldState[name]) then
			local d = root and (g.center - root.Position).Magnitude or 0
			if not bestD or d < bestD then best, bestD = g, d end
		end
	end
	return best
end
Farms.add({name = "Pick bosses", flag = "WorldBossFarm", priority = 4,
	enabled = function() return Options.WorldBossFarm.Value end,
	ready = function() return B.worldPick() ~= nil or B.worldCurrent ~= nil end,
	step = function()
		local g = B.worldCurrent or B.worldPick()
		if not g then return end
		B.worldCurrent = g
		local e = B.bossAlive(g.name)
		if e then
			B.worldSeen = os.clock()
			B.worldLast = e.root.Position
			C.fight(function(x) return x.folder == g.name or x.name == g.name end, g.center, 400, "boss · " .. g.name)
			return
		end
		local root = getRoot()
		if root and (root.Position - g.center).Magnitude > 60 then
			C.disengage()
			C.status = "going to " .. g.name
			B.worldArrived = nil
			E.travel(g.center, 25)
			return
		end
		C.disengage()
		B.worldArrived = B.worldArrived or os.clock()
		if B.worldSeen and os.clock() - B.worldSeen < 5 then
			dlog("boss", g.name .. " down")
			dbg.bosses += 1
			B.lootBoss(B.worldLast or g.center)
			B.worldState[g.name] = os.clock() + math.max(g.spawnTime - 20, 30)
			B.worldCurrent, B.worldSeen, B.worldArrived = nil, nil, nil
			return
		end
		if os.clock() - B.worldArrived > 12 then
			B.worldState[g.name] = os.clock() + math.min(g.spawnTime, 120)
			B.worldCurrent, B.worldArrived = nil, nil
			return
		end
		C.status = "waiting for " .. g.name
		task.wait(0.5)
	end})

function F.questFarm(side, choiceFlag, key, label)
	local q = Q.activeByCategory("Combat")
	if q then
		if q.done then C.disengage() C.status = "turning in " .. q.name task.wait(1) return end
		if not Q.runStep(q, label) then
			C.status = "quest task I can't do: " .. q.name
			if F.ownQuest == q.name then Q.abandon(q) F.ownQuest = nil end
			task.wait(2)
		end
		return
	end
	if C.finishTarget() then return end
	if F.waitRetry(key) then
		C.disengage()
		C.status = "waiting to take the next quest"
		task.wait(0.2)
		return
	end
	local list = Q.candidates(side)
	local want = choiceFlag and Options[choiceFlag] and Options[choiceFlag].Value
	local pick
	if type(want) == "string" and not want:find("^Auto") then
		local name = want:match("^(.-) · ") or want
		for _, c in ipairs(list) do if c.name == name then pick = c end end
	end
	pick = pick or list[1]
	if not pick then C.status = "no quest fits your level/race" F.retry[key] = os.clock() + 30 F.noQuest[key] = os.clock() + 30 return end
	local ok, okAdd = Q.canAdd(pick.name)
	if not ok then F.retry[key] = os.clock() + 4 return end
	C.status = "taking " .. pick.name
	local got, why = Q.accept(pick.name)
	if got then F.ownQuest = pick.name else
		dlog("warn", "Quest " .. pick.name .. ": " .. tostring(why) .. " — trying again")
		F.retry[key] = os.clock() + 8
	end
end
Farms.add({name = "Wen farm", flag = "WenFarm", priority = 5,
	enabled = function() return Options.WenFarm.Value end,
	ready = function() return os.clock() > (F.noQuest.wen or 0) end,
	step = function() F.questFarm(nil, nil, "wen", "wen") end})
Farms.add({name = "Demon quests", flag = "DemonQuests", priority = 4,
	enabled = function() return Options.DemonQuests.Value end,
	ready = function() return isDemonSide() end,
	step = function() F.questFarm("Demon", nil, "demonq", "demon quest") end})
Farms.add({name = "Slayer quests", flag = "SlayerQuests", priority = 4,
	enabled = function() return Options.SlayerQuests.Value end,
	ready = function() return isSlayerSide() end,
	step = function() F.questFarm("Slayer", nil, "slayerq", "slayer quest") end})

for _, f in ipairs(Farms.list) do
	local fixed = ({["Boss hunts"] = 3, ["Pick bosses"] = 4, ["Demon quests"] = 6, ["Slayer quests"] = 6, ["Wen farm"] = 7,
		["Rep farm"] = 8, ["Mastery farm"] = 9, ["Level farm"] = 10})[f.name]
	if fixed then f.priority = fixed end
	local o = f.flag and Options[f.flag]
	if o then
		o.Callback = function(on)
			if on then
				notify("success", f.name .. " on", "Started.")
				dlog("farm", f.name .. " on")
			else
				if Farms.active == f then E.stopMoving() C.disengage() end
				dlog("farm", f.name .. " off")
			end
		end
	end
end

local Wd = {done = setmetatable({}, {__mode = "k"}), scouted = {}, studyTried = setmetatable({}, {__mode = "k"}), chestSeenLocked = setmetatable({}, {__mode = "k"})}
function Wd.itemCount(name)
	local d = getData()
	local it = d and d.Inventory.Inventory:FindFirstChild(name)
	if not it then return 0 end
	local a = it:FindFirstChild("Amount")
	return a and a.Value or 1
end
function Wd.potionTotal()
	local n = 0
	for _, p in ipairs(C.POTIONS) do n += Wd.itemCount(p) end
	return n
end

do
	local c = card(WorldTab, "Potions", {side = 2})
	toggleD(c, "AutoBuyPots", "Auto buy potions", "Buys a stack when you run low", false)
	UI.potNote = cardNote(c, "", 20)
end
do
	local c = card(WorldTab, "Coin Pouches", {side = 1})
	toggleD(c, "AutoSellPouch", "Auto sell Coin Pouches", "Sells to Ginzo; other farms wait meanwhile", false)
	slider(c, "SellPouchAt", "Sell at", 1, 300, 1, 50)
	toggle(c, "SellCoinsToo", "Also sell Coin Stacks and Coins", false)
	UI.pouchNote = cardNote(c, "", 20)
end
do
	local c = card(WorldTab, "Sealed Chests", {side = 2})
	toggleD(c, "SealedFarm", "Auto Sealed Chests", "Kills the guards, unseals, holds to loot", false)
	UI.sealedNote = cardNote(c, "", 34)
end
do
	local c = card(WorldTab, "Schematics", {side = 1})
	toggleD(c, "SchematicFarm", "Get all Schematics", "Goes to every study spot and studies it", false)
	UI.schemNote = cardNote(c, "", 48)
end
function Wd.potShop()
	if Wd.itemCount("Demon Horns") >= 2 then return "Alchemist Meku", "Health Regen Elixir" end
	return "Rika", "Health Regen Potion"
end

W.sealedSpots = {}
do
	local misc = W.regionMods.Misc
	for _, n in ipairs(misc and misc.Npcs or {}) do
		local tier = type(n.Name) == "string" and n.Name:match("^Sealed Chest (T%d)$")
		if tier and n.Spawns then
			for i, s in pairs(n.Spawns) do
				local p = posOf(s)
				if p then table.insert(W.sealedSpots, {tier = tier, pos = p, key = tier .. "#" .. tostring(i)}) end
			end
		end
	end
end

Farms.add({name = "Buy potions", flag = "AutoBuyPots", priority = 1,
	enabled = function() return Options.AutoBuyPots.Value end,
	ready = function() return not F.waitRetry("pots") and Wd.potionTotal() < Options.BuyPotsAt.Value end,
	step = function()
		F.retry.pots = os.clock() + 300
		local npc, item = Wd.potShop()
		C.disengage()
		C.status = "buying " .. item .. " from " .. npc
		local ok, why = Q.talk(npc)
		if not ok then dlog("warn", "Potions: " .. tostring(why)) return end
		task.wait(0.6)
		local before = Wd.itemCount(item)
		local wen = getData() and getData().Wen.Value or 0
		local left = math.min(Options.BuyPotCount.Value, math.floor(wen / 650))
		while left > 0 do
			local chunk = math.min(99, left)
			local was = Wd.itemCount(item)
			pcall(M.SignalEvent.ToServer, "PurchaseFromShop", item, chunk)
			local t0 = os.clock()
			repeat task.wait(0.15) until Wd.itemCount(item) > was or os.clock() - t0 > 3
			local got = Wd.itemCount(item) - was
			if got <= 0 then break end
			left -= got
		end
		Q.closeDialogue()
		local got = Wd.itemCount(item) - before
		if got > 0 then
			dlog("heal", "Bought " .. got .. "× " .. item)
			notify("success", "Potions", "Bought " .. got .. "× " .. item)
			if C.potionInfo() == 0 then C.refillPotion() end
		else
			dlog("warn", npc .. " sold nothing (not enough Wen?)")
		end
	end})

Farms.add({name = "Sell pouches", flag = "AutoSellPouch", priority = 1,
	enabled = function() return Options.AutoSellPouch.Value end,
	ready = function() return not F.waitRetry("sell") and Wd.itemCount("Coin Pouch") >= Options.SellPouchAt.Value end,
	step = function()
		F.retry.sell = os.clock() + 180
		C.disengage()
		C.status = "selling Coin Pouches to Ginzo"
		local ok, why = Q.talk("Ginzo")
		if not ok then dlog("warn", "Sell: " .. tostring(why)) return end
		task.wait(0.6)
		local sel = {["Coin Pouch"] = Wd.itemCount("Coin Pouch")}
		if Options.SellCoinsToo.Value then
			for _, n in ipairs({"Coin Stack", "Coin"}) do
				local k = Wd.itemCount(n)
				if k > 0 then sel[n] = k end
			end
		end
		local wen0 = getData() and getData().Wen.Value or 0
		local okS, res = isolated(env.__AxiomOwOrigSF or M.SignalFunction.ToServer, "SellItems", sel)
		task.wait(1)
		Q.closeDialogue()
		local wen1 = getData() and getData().Wen.Value or 0
		if wen1 > wen0 then
			dlog("loot", "Sold pouches for " .. fmtNum(wen1 - wen0) .. " Wen")
			notify("success", "Sold", "+" .. fmtNum(wen1 - wen0) .. " Wen")
		else
			dlog("warn", "Ginzo didn't buy (" .. tostring(okS) .. " " .. tostring(typeof(res) == "table" and HttpService:JSONEncode(res) or res) .. ")")
		end
	end})

function Wd.sealedVisible()
	local out = {}
	local sel = Options.SealedTiers.Value
	for _, chest in ipairs(workspace:FindFirstChild("Chests") and workspace.Chests:GetChildren() or {}) do
		local id = tostring(chest:GetAttribute("ChestId") or chest.Name)
		local tier = id:match("Sealed Cache (T%d)")
		if tier and type(sel) == "table" and sel[tier] and chest:GetAttribute("IsOpen") ~= true and not Wd.done[chest] then
			table.insert(out, chest)
		end
	end
	return out
end
function Wd.nextScout()
	local root = getRoot()
	local sel = Options.SealedTiers.Value
	local best, bestD
	for _, s in ipairs(W.sealedSpots) do
		if type(sel) == "table" and sel[s.tier] and not (Wd.scouted[s.key] and os.clock() - Wd.scouted[s.key] < 900) then
			local d = root and (s.pos - root.Position).Magnitude or 0
			if not bestD or d < bestD then best, bestD = s, d end
		end
	end
	return best
end
Wd.GUARD_WORDS = {"Raider", "Captain", "Cache", "Lancer", "Prowler"}
function Wd.isGuard(e, at)
	if (e.root.Position - at).Magnitude > 110 then return false end
	for _, w in ipairs(Wd.GUARD_WORDS) do if e.name:find(w) or e.folder:find(w) then return true end end
	return false
end
Farms.add({name = "Sealed chests", flag = "SealedFarm", priority = 5,
	enabled = function() return Options.SealedFarm.Value end,
	ready = function() return not F.waitRetry("sealed") end,
	step = function()
		local root = getRoot()
		if not root then return end
		local best, bestD
		for _, ch in ipairs(Wd.sealedVisible()) do
			local d = (ch:GetPivot().Position - root.Position).Magnitude
			if not bestD or d < bestD then best, bestD = ch, d end
		end
		if not best then
			local s = Wd.nextScout()
			if not s then
				C.status = "all sealed chest spots checked — next round in a bit"
				F.retry.sealed = os.clock() + 120
				for k in pairs(Wd.scouted) do Wd.scouted[k] = nil end
				return
			end
			C.disengage()
			C.status = "checking sealed chest spot " .. s.key
			E.travel(s.pos, 30)
			task.wait(1.2)
			Wd.scouted[s.key] = os.clock()
			return
		end
		local at = best:GetPivot().Position
		if bestD > 40 and not E.hoverConn then
			C.status = "flying to " .. best.Name
			E.travel(at, 20)
			return
		end
		if best:GetAttribute("ChestState") == "Locked" then
			Wd.chestSeenLocked[best] = Wd.chestSeenLocked[best] or os.clock()
			local r = C.fight(function(e) return Wd.isGuard(e, at) end, at, 110, "sealed chest guards")
			if r == "wait" and os.clock() - Wd.chestSeenLocked[best] > 25 then
				dlog("warn", best.Name .. " stays locked with no guards — skipping")
				Wd.done[best] = true
			end
			return
		end
		C.disengage()
		local p = best:FindFirstChild("ChestPrompt", true)
		if p and p.Enabled then
			C.status = "opening " .. best.Name
			for _ = 1, 3 do
				E.usePrompt(p, 0.6)
				task.wait(1.2)
				if best:GetAttribute("IsOpen") == true or not p.Enabled then break end
			end
			dlog("loot", (best:GetAttribute("IsOpen") == true and "Opened " or "Tried to open ") .. best.Name)
			task.wait(0.8)
			E.collectLoot(120)
			Wd.done[best] = true
		else
			task.wait(0.5)
			if os.clock() - (Wd.chestSeenLocked[best] or os.clock()) > 40 then Wd.done[best] = true end
		end
	end})

function Wd.studyProps()
	local out = {}
	for _, j in ipairs(CS:GetTagged("StudyProp")) do
		local item = j:GetAttribute("Item")
		local pr = j:FindFirstChildWhichIsA("ProximityPrompt", true)
		if type(item) == "string" and pr and not j:GetAttribute("Locked") and Wd.itemCount(item .. " Schematic") == 0 and (Wd.studyTried[j] or 0) < 3 then
			table.insert(out, {model = j, prompt = pr, item = item})
		end
	end
	return out
end
Farms.add({name = "Schematics", flag = "SchematicFarm", priority = 8,
	enabled = function() return Options.SchematicFarm.Value end,
	ready = function() return #Wd.studyProps() > 0 end,
	step = function()
		local list = Wd.studyProps()
		local root = getRoot()
		table.sort(list, function(a, b)
			return root and (posOf(a.model) - root.Position).Magnitude < (posOf(b.model) - root.Position).Magnitude or false
		end)
		local s = list[1]
		if not s then return end
		C.disengage()
		Wd.studyTried[s.model] = (Wd.studyTried[s.model] or 0) + 1
		C.status = "studying " .. s.item
		local at = E.promptPos(s.prompt) or posOf(s.model)
		local reach = math.max((s.prompt.MaxActivationDistance or 8) - 2, 3)
		E.travel(Vector3.new(at.X, at.Y, at.Z), 6)
		local root = getRoot()
		if root and (root.Position - at).Magnitude > reach then
			E.moveToken += 1
			local token = E.moveToken
			E.moving = true
			E.setNoclip(true)
			E.blockInput(true)
			E.flyTo(at + Vector3.new(0, 1, 0), token, 16)
			E.moving = false
		end
		local pin
		local r2 = getRoot()
		if r2 then
			local hold = r2.CFrame
			pin = RunService.Heartbeat:Connect(function()
				local r = getRoot()
				if r then r.AssemblyLinearVelocity = Vector3.zero r.CFrame = hold end
			end)
		end
		task.wait(0.3)
		E.holdPrompt(s.prompt, 0.5)
		task.wait(1.5)
		if s.prompt.Parent and s.prompt.Enabled and Wd.itemCount(s.item .. " Schematic") == 0 then
			pcall(fireproximityprompt, s.prompt)
			task.wait(1.5)
		end
		if pin then pin:Disconnect() end
		E.setNoclip(false)
		E.blockInput(false)
		if Wd.itemCount(s.item .. " Schematic") > 0 then
			dlog("loot", "Got " .. s.item .. " Schematic")
			notify("success", "Schematic", s.item)
		else
			local r3 = getRoot()
			dlog("warn", "Couldn't study " .. s.item .. (r3 and string.format(" (%.0f studs away)", (r3.Position - at).Magnitude) or ""))
		end
	end})

for _, f in ipairs(Farms.list) do
	local pf = ({["Buy potions"] = 1, ["Sell pouches"] = 1, ["Sealed chests"] = 5, ["Schematics"] = 11})[f.name]
	if pf then
		f.priority = pf
		local o = f.flag and Options[f.flag]
		if o and not o.Callback then
			o.Callback = function(on)
				if on then dlog("farm", f.name .. " on") else
					if Farms.active == f then E.stopMoving() C.disengage() end
					dlog("farm", f.name .. " off")
				end
			end
		end
	end
end

local P = {}
do
	local c = card(PlayerTab, "Movement", {side = 1})
	toggle(c, "InfJump", "Inf Jump (double jump)", false)
	toggle(c, "InfDash", "Inf Dash (Q)", false)
	toggle(c, "InfStamina", "Inf Stamina", false)
	toggle(c, "InfHorseStamina", "Inf Horse Stamina", false)
end
do
	local c = card(PlayerTab, "Party", {side = 2})
	input(c, "PartyFriend", "Friend", "nickname")
	toggleD(c, "AutoParty", "Auto Party", "Invites the friend and accepts their invite", false)
	UI.partyNote = cardNote(c, "", 20)
end

P.lastJump = 0
connect(UIS.JumpRequest, function()
	if not Options.InfJump.Value then return end
	local hum = getHum()
	if hum and hum.Health > 0 and hum.FloorMaterial == Enum.Material.Air and os.clock() - P.lastJump > 0.28 then
		P.lastJump = os.clock()
		if M.DoubleJump and M.DoubleJump.Hold then
			task.spawn(pcall, M.DoubleJump.Hold, player)
		else
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)
P.lastDash = 0
function P.dash(dir)
	local shc = E.getSHC()
	if not (M.SkillCtl and shc) or dir.Magnitude < 0.1 then return false end
	local cam = workspace.CurrentCamera
	local saved = cam.CFrame
	cam.CFrame = CFrame.lookAt(saved.Position, saved.Position + Vector3.new(dir.X, 0, dir.Z))
	local ok, r = pcall(M.SkillCtl.Attempt_Hold, "Dash", "W")
	cam.CFrame = saved
	if ok and r == true then
		task.spawn(pcall, M.SkillCtl.StopHold, "Dash")
		return true
	end
	return false
end
P.dashLoop = false
connect(UIS.InputBegan, function(i, gpe)
	if gpe or not Options.InfDash.Value or i.KeyCode ~= Enum.KeyCode.Q or P.dashLoop then return end
	P.dashLoop = true
	task.spawn(function()
		while alive and Options.InfDash.Value and UIS:IsKeyDown(Enum.KeyCode.Q) do
			if os.clock() - P.lastDash >= Options.DashCD.Value then
				P.lastDash = os.clock()
				local hum, root = getHum(), getRoot()
				if hum and root then
					local dir = hum.MoveDirection.Magnitude > 0.1 and hum.MoveDirection or root.CFrame.LookVector
					task.spawn(P.dash, Vector3.new(dir.X, 0, dir.Z).Unit)
				end
			end
			task.wait(0.05)
		end
		P.dashLoop = false
	end)
end)
P.horseFn = nil
function P.findHorseStamina()
	if P.horseIdx then return P.horseFn, P.horseIdx end
	local ok, mod = pcall(function() return require(RS.ToolScripts.Horse.Horse) end)
	local fn = ok and type(mod) == "table" and mod.cycleSpeedMode
	if type(fn) ~= "function" then return nil end
	local ups = debug.getupvalues(fn)
	for i, v in pairs(ups) do
		if type(v) == "number" and v >= 0 and v <= 45 and i > 1 then
			local tbl = ups[i - 1]
			if type(tbl) == "table" and type(tbl[1]) == "table" and tbl[1].Speed then
				P.horseFn, P.horseIdx = fn, i
				return fn, i
			end
		end
	end
	return nil
end
connect(RunService.Heartbeat, function()
	if Options.InfStamina.Value or (Options.WalkStamina.Value and E.WK.walking) then
		local v = RS:FindFirstChild("Player_Service") and RS.Player_Service.Values:FindFirstChild(player.Name)
		local st = v and v:FindFirstChild("Stamina")
		if st and st.Value < st.MaxValue then pcall(function() st.Value = st.MaxValue end) end
	end
	if Options.InfHorseStamina.Value then
		local c = getChar()
		if c and c:GetAttribute("OnHorse") then
			local fn, idx = P.findHorseStamina()
			if fn then pcall(debug.setupvalue, fn, idx, 45) end
		end
	end
end)

P.lastParty = 0
function P.friend()
	local n = trim(Options.PartyFriend.Value):lower()
	if n == "" then return nil end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and (p.Name:lower() == n or p.DisplayName:lower() == n) then return p end
	end
	return nil
end
task.spawn(function()
	while alive do
		task.wait(2)
		if Options.AutoParty.Value then
			local fr = P.friend()
			local my = getChar() and getChar():GetAttribute("partyId")
			local theirs = fr and fr.Character and fr.Character:GetAttribute("partyId")
			if not fr then
				UI.partyNote.Text = "Friend isn't in this server."
			elseif my and theirs and my == theirs then
				UI.partyNote.Text = "In a party with " .. fr.DisplayName .. "."
			else
				UI.partyNote.Text = "Inviting " .. fr.DisplayName .. "…"
				if os.clock() - P.lastParty > 20 then
					P.lastParty = os.clock()
					if M.SignalEvent then pcall(M.SignalEvent.ToServer, "Invite To Party", fr.Name) end
				end
			end
			if fr then
				for _, g in ipairs(player.PlayerGui:GetDescendants()) do
					if g:IsA("TextLabel") and g.Visible and (g.Text:find(fr.DisplayName, 1, true) or g.Text:find(fr.Name, 1, true)) and g.Text:lower():find("party") then
						local root = g:FindFirstAncestorWhichIsA("GuiObject")
						local holder = root and root.Parent
						for _, b in ipairs(holder and holder:GetDescendants() or {}) do
							if b:IsA("GuiButton") and (b.Name:lower():find("accept") or b.Name:lower():find("yes")) then Q.click(b) end
						end
					end
				end
			end
		end
	end
end)

local V = {items = {}}
do
	local c = card(VisualTab, "Mob ESP", {side = 2})
	toggle(c, "MobESP", "Names, HP and distance", false)
	toggle(c, "MobChams", "Chams (see through walls)", false)
	toggle(c, "ESPBossOnly", "Bosses only", false)
end
function V.clear(m)
	local it = V.items[m]
	if not it then return end
	if it.bb then it.bb:Destroy() end
	if it.hl then it.hl:Destroy() end
	V.items[m] = nil
end
UI.cleanups = UI.cleanups or {}
table.insert(UI.cleanups, function() for m in pairs(V.items) do V.clear(m) end end)
task.spawn(function()
	while alive do
		local on = Options.MobESP.Value or Options.MobChams.Value
		local root = getRoot()
		local seen = {}
		if on and root then
			local hl = 0
			for _, e in ipairs(E.enemies()) do
				local d = (e.root.Position - root.Position).Magnitude
				local isBoss = e.group and e.group.boss
				if d <= Options.ESPRange.Value and (isBoss or not Options.ESPBossOnly.Value) then
					seen[e.model] = true
					local it = V.items[e.model] or {}
					V.items[e.model] = it
					local col = isBoss and Color3.fromRGB(255, 90, 90) or T.Accent
					if Options.MobESP.Value then
						if not it.bb or not it.bb.Parent then
							it.bb = make("BillboardGui", {Name = "AxiomESP", Adornee = e.root, Size = UDim2.fromOffset(160, 34), StudsOffset = Vector3.new(0, 3.5, 0), AlwaysOnTop = true, LightInfluence = 0, MaxDistance = 2000})
							it.lbl = label({Parent = it.bb, Size = UDim2.fromScale(1, 1), Font = FONT_B, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center, RichText = true, TextStrokeTransparency = 0.4})
							pcall(function() it.bb.Parent = gui end)
						end
						it.lbl.TextColor3 = col
						it.lbl.Text = string.format("%s\n<font size=\"11\">%d HP · %dm</font>", e.name, math.floor(e.hum.Health), math.floor(d))
					elseif it.bb then it.bb:Destroy() it.bb = nil end
					if Options.MobChams.Value and hl < 30 then
						hl += 1
						if not it.hl or not it.hl.Parent then
							it.hl = make("Highlight", {Name = "AxiomCham", Adornee = e.model, FillTransparency = 0.6, OutlineTransparency = 0.1, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop})
							pcall(function() it.hl.Parent = gui end)
						end
						it.hl.FillColor, it.hl.OutlineColor = col, col
					elseif it.hl then it.hl:Destroy() it.hl = nil end
				end
			end
		end
		for m in pairs(V.items) do if not seen[m] or not m.Parent then V.clear(m) end end
		task.wait(0.3)
	end
end)

local H = {gains = {}, lastStats = os.time()}
do
	local c = card(HookTab, "Discord", {side = 2})
	input(c, "WebhookURL", "URL", "https://discord.com/api/webhooks/...")
	toggle(c, "WebhookOn", "Send to Discord", false)
	toggle(c, "HookDrops", "Obtained items (only drops)", true)
	toggle(c, "HookStats", "Stats every 30 min", true)
	button(c, "Send a test message", nil, function()
		if trim(Options.WebhookURL.Value) == "" then notify("warn", "No URL", "Paste your Discord webhook URL first.") return end
		local ok = H.send("🧪  Webhook connected", "Ouwland farm is connected.", 0x8E9A4E)
		notify(ok and "success" or "error", ok and "Webhook connected" or "Webhook failed", ok and "Test message delivered." or "Discord rejected it. Check the URL.")
	end)
end
function H.request(opts)
	local req = (env.syn and env.syn.request) or (env.http and env.http.request) or env.http_request or env.request or request
	if not req then return nil end
	return req(opts)
end
function H.send(title, text, color, fields)
	local url = trim(Options.WebhookURL.Value)
	if url == "" then return false end
	local embed = {
		author = {name = APP_NAME .. " · Ouwland"}, title = title, description = text and ("> " .. text) or nil, color = color or 0x8E9A4E,
		fields = fields or {
			{name = "💰 Wen", value = "`" .. fmtNum(dbg.wen or 0) .. "`", inline = true},
			{name = "📈 Earned", value = "`+" .. fmtNum((dbg.wen or 0) - (dbg.startWen or dbg.wen or 0)) .. "`", inline = true},
			{name = "⏱️ Session", value = "`" .. UI.sessionTime() .. "`", inline = true},
		},
		footer = {text = player.Name .. "  •  " .. APP_NAME .. " by " .. AUTHOR}, timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
	}
	local ok, res = isolated(H.request, {Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode({username = APP_NAME, embeds = {embed}})})
	return ok and res ~= nil and (res.StatusCode == nil or (res.StatusCode >= 200 and res.StatusCode < 300))
end
do
	local SKIP = {["Coin Pouch"] = false}
	local counts = {}
	local pending, pendingAt = {}, 0
	local function amountOf(it) local a = it:FindFirstChild("Amount") return a and a.Value or 1 end
	task.spawn(function()
		local d
		repeat d = getData() task.wait(1) until d or not alive
		if not d then return end
		local inv = d.Inventory.Inventory
		local function snapshot()
			local t = {}
			for _, it in ipairs(inv:GetChildren()) do t[it.Name] = (t[it.Name] or 0) + amountOf(it) end
			return t
		end
		counts = snapshot()
		while alive do
			task.wait(3)
			local now = snapshot()
			for name, n in pairs(now) do
				local diff = n - (counts[name] or 0)
				if diff > 0 and SKIP[name] ~= true then
					pending[name] = (pending[name] or 0) + diff
					H.gains[name] = (H.gains[name] or 0) + diff
					if pendingAt == 0 then pendingAt = os.clock() end
				end
			end
			counts = now
			if pendingAt > 0 and os.clock() - pendingAt > 12 then
				local lines = {}
				for name, n in pairs(pending) do table.insert(lines, n .. "× " .. name) end
				pending, pendingAt = {}, 0
				if #lines > 0 then
					dlog("loot", "Got " .. table.concat(lines, ", "))
					if Options.WebhookOn.Value and Options.HookDrops.Value then task.spawn(H.send, "🎁  New items", table.concat(lines, "\n"), 0xE6C25A) end
				end
			end
			if Options.WebhookOn.Value and Options.HookStats.Value and os.time() - H.lastStats >= Options.HookEvery.Value * 60 then
				H.lastStats = os.time()
				local got = {}
				for name, n in pairs(H.gains) do table.insert(got, n .. "× " .. name) end
				table.sort(got)
				task.spawn(H.send, "📊  Session stats", #got > 0 and ("Obtained: " .. table.concat(got, ", ")) or "Nothing obtained yet.", 0x4F8FD6, {
					{name = "💰 Wen", value = "`" .. fmtNum(dbg.wen or 0) .. "`", inline = true},
					{name = "📈 Earned", value = "`+" .. fmtNum((dbg.wen or 0) - (dbg.startWen or dbg.wen or 0)) .. "`", inline = true},
					{name = "⏱️ Session", value = "`" .. UI.sessionTime() .. "`", inline = true},
					{name = "⚔️ Kills", value = "`" .. dbg.kills .. "`", inline = true},
					{name = "👹 Bosses", value = "`" .. dbg.bosses .. "`", inline = true},
					{name = "📜 Quests", value = "`" .. dbg.quests .. "`", inline = true},
				})
			end
		end
	end)
end
UI.hookEvent = function(kind, text)
	if kind == "quest" and Options.WebhookOn.Value and Options.HookDrops.Value and text:find("^Eliminate") then
		task.spawn(H.send, "👹  Boss down", text, 0xD65252)
	end
end

task.spawn(function()
	while alive do
		UI.potNote.Text = "Potions in bag: <b>" .. Wd.potionTotal() .. "</b>"
		UI.pouchNote.Text = "Coin Pouches: <b>" .. Wd.itemCount("Coin Pouch") .. "</b>"
		local vis = #Wd.sealedVisible()
		UI.sealedNote.Text = string.format("%d spots known · %d chest%s in view", #W.sealedSpots, vis, vis == 1 and "" or "s")
		local left = {}
		for _, s in ipairs(Wd.studyProps()) do table.insert(left, s.item) end
		UI.schemNote.Text = #left > 0 and ("Left: " .. table.concat(left, ", ")) or "You have every schematic that's open to study."
		task.wait(3)
	end
end)

local Gr = {retry = 0}
function Gr.hasHorse()
	local d = getData()
	return d ~= nil and d.Inventory.Inventory:FindFirstChild("Horse") ~= nil
end
function Gr.wen()
	local d = getData()
	return d and d.Wen.Value or 0
end
function Gr.wildHorse()
	local deb = workspace:FindFirstChild("Debree")
	local R = deb and deb:FindFirstChild("Regions")
	for _, reg in ipairs(R and R:GetChildren() or {}) do
		local an = reg:FindFirstChild("ActiveNpcs")
		for _, h in ipairs(an and an:GetChildren() or {}) do
			if h.Name == "Horse" then
				for _, p in ipairs(h:GetDescendants()) do
					if p:IsA("ProximityPrompt") and p.Enabled and tostring(p.ActionText):lower():find("tame") then return h, p end
				end
			end
		end
	end
	return nil
end

do
	local c = card(WorldTab, "Horse", {side = 1})
	toggleD(c, "AutoBuyHorse", "Auto Buy Horse", "Tames an escaped horse when you have 15k Wen", false)
	UI.horseNote = cardNote(c, "", 34)
end

Farms.add({name = "Buy horse", flag = "AutoBuyHorse", priority = 2,
	enabled = function() return Options.AutoBuyHorse.Value end,
	ready = function()
		return os.clock() > Gr.retry and not Gr.hasHorse() and Gr.wen() >= Options.HorseBudget.Value and Gr.wildHorse() ~= nil
	end,
	step = function()
		Gr.retry = os.clock() + 45
		local h, pr = Gr.wildHorse()
		if not (h and pr) then return end
		C.disengage()
		C.status = "taming the escaped horse"
		dlog("world", "Escaped horse spotted — going to tame it")
		local wen0 = Gr.wen()
		for _ = 1, 3 do
			if not pr.Parent then break end
			E.usePrompt(pr, 0.5)
			task.wait(1.2)
			local bh = Q.buttons()
			if bh then
				for _, b in ipairs(bh:GetChildren()) do
					local n = b.Name:lower()
					if n:find("buy") or n:find("yes") or n:find("tame") or n:find("purchase") or n:find("deal") then Q.click(b) task.wait(1) break end
				end
				if not Gr.hasHorse() and M.SignalEvent then pcall(M.SignalEvent.ToServer, "PurchaseFromShop", "Horse", 1) task.wait(1.2) end
				Q.closeDialogue()
			end
			if Gr.hasHorse() then break end
		end
		if Gr.hasHorse() then
			dlog("loot", "Got a Horse (" .. fmtNum(wen0 - Gr.wen()) .. " Wen)")
			notify("success", "Horse", "Tamed and yours now.")
		else
			dlog("warn", "Couldn't get the horse this time")
		end
	end})

local Eq = {cache = {}, last = 0}
Eq.Menum = tryRequire(function() return RS.CAM.Global.Menum end)
Eq.SLOTS = {"One", "Two", "Three", "Four", "Five"}
Eq.W = {
	HP = {["Max Health"] = 1, ["Max Health Factor"] = 2500, ["Health Regen Speed"] = 600, ["Damage Reduction"] = 15, ["Damage Reduction Factor"] = 1500,
		["Block Points"] = 4, ["Block Regen"] = 60, ["Max Stamina"] = 0.15, ["Stamina Regen Speed"] = 40, ["Additional Damage Factor"] = 200},
	Damage = {["Additional Damage"] = 22, ["Additional Damage Factor"] = 2000, ["Armor Penetration Factor"] = 2500, ["Max Health"] = 0.12,
		["Damage Reduction Factor"] = 300, ["Max Stamina"] = 0.1, ["Movement Speed Factor"] = 200},
	Speed = {["Movement Speed Factor"] = 2000, ["Max Stamina"] = 0.5, ["Stamina Regen Speed"] = 300, ["Max Health"] = 0.08, ["Additional Damage Factor"] = 200},
}
function Eq.info(name)
	if Eq.cache[name] ~= nil then return Eq.cache[name] or nil end
	local m = RS:FindFirstChild("Items") and RS.Items:FindFirstChild(name, true)
	local ok, t = false, nil
	if m and m:IsA("ModuleScript") then ok, t = pcall(require, m) end
	Eq.cache[name] = (ok and type(t) == "table") and t or false
	return Eq.cache[name] or nil
end
function Eq.isAccessory(info)
	if not info then return false end
	local acc = Eq.Menum and Eq.Menum.ItemEquipType and Eq.Menum.ItemEquipType.Accessory or 3
	return info.EquipType == acc
end
function Eq.score(info, build)
	local w = Eq.W[build] or Eq.W.HP
	local s = 0
	for k, v in pairs(type(info.Stats) == "table" and info.Stats or {}) do
		if type(v) == "number" and w[k] then s += v * w[k] end
	end
	local st = info.Stats or {}
	if Options.ColdLantern.Value and (st["Cold Immunity"] or tostring(info.ExclusiveGroup) == "ColdLantern") then s += st["Cold Immunity"] and 5000 or 800 end
	if Options.SunHat.Value and st["Sun Immunity"] and isDemonSide() and not Options.SunImmunity.Value then s += 5000 end
	return s
end
function Eq.owned(build)
	local d = getData()
	local out = {}
	if not d then return out end
	for _, it in ipairs(d.Inventory.Inventory:GetChildren()) do
		local id = it:FindFirstChild("Id")
		local info = Eq.info(it.Name)
		if id and Eq.isAccessory(info) then
			table.insert(out, {name = it.Name, id = id.Value, info = info, score = Eq.score(info, build)})
		end
	end
	table.sort(out, function(a, b) return a.score > b.score end)
	return out
end
function Eq.pick(build)
	local chosen, groups = {}, {}
	for _, it in ipairs(Eq.owned(build)) do
		if #chosen >= 5 then break end
		local g = it.info.ExclusiveGroup
		if it.score > 0 and not (g and groups[g]) then
			if g then groups[g] = true end
			table.insert(chosen, it)
		end
	end
	return chosen
end
function Eq.apply(build, quiet)
	local d = getData()
	if not (d and M.SignalEvent) then return 0 end
	local stats = d.Inventory.Accessories:FindFirstChild("Stats")
	if not stats then return 0 end
	local chosen = Eq.pick(build)
	local want = {}
	for i, it in ipairs(chosen) do want[i] = it.id end
	local changed = 0
	for i, slot in ipairs(Eq.SLOTS) do
		local v = stats:FindFirstChild(slot)
		local cur = v and v.Value or 0
		local target = want[i]
		if target and cur ~= target then
			for j, other in ipairs(Eq.SLOTS) do
				local ov = stats:FindFirstChild(other)
				if j ~= i and ov and ov.Value == target then
					pcall(M.SignalEvent.ToServer, "AccessoryEquip", other, 0, "Stats")
					task.wait(0.4)
				end
			end
			pcall(M.SignalEvent.ToServer, "AccessoryEquip", slot, target, "Stats")
			changed += 1
			task.wait(0.5)
		end
	end
	local names = {}
	for _, it in ipairs(chosen) do table.insert(names, it.name) end
	UI.equipNote.Text = #names > 0 and ("<b>" .. build .. "</b>: " .. table.concat(names, ", ")) or "No accessories with stats in your bag yet."
	if changed > 0 then
		dlog("world", "Equipped best " .. build .. " gear: " .. table.concat(names, ", "))
		if not quiet then notify("success", "Equip Best", build .. " build · " .. changed .. " change" .. (changed == 1 and "" or "s")) end
	end
	return changed
end

do
	local c = card(PlayerTab, "Auto Equip Best", {side = 1})
	dropdown(c, "EquipBuild", "Build", {"HP", "Damage", "Speed"}, false, "HP")
	toggleD(c, "AutoEquipBest", "Auto Equip Best", "Re-checks your bag every minute and after drops", false)
	button(c, "Equip best now", nil, function() task.spawn(Eq.apply, Options.EquipBuild.Value) end)
	UI.equipNote = cardNote(c, "", 44)
end

local ST = {fail = {}}
ST.LIST = {{"Max Health", 6}, {"Health Regen Speed", 6}, {"Additional Damage", 5}, {"Max Stamina", 8}, {"Stamina Regen Speed", 6}, {"Block Points", 6}, {"Block Regen", 4}}
do
	local cfg = tryRequire(function() return RS.CAM.Global.SkillService.SkillTreeholder.SkillTreeConfig end)
	local gs = tryRequire(function() return RS.CAM.Global.gameSettings end)
	if type(cfg) == "table" and type(gs) == "table" and gs.maxLevel then
		for _, row in ipairs(ST.LIST) do
			local c = cfg[row[1]]
			if c and c.Ratio then row[2] = math.floor(gs.maxLevel / c.Ratio) end
		end
	end
end
function ST.level(d, name)
	local v = d.SkillTreeUnlockedList:FindFirstChild(name)
	return v and v.Value or 0
end
function ST.flag(name) return "ST_" .. name:gsub("%s", "") end
do
	local c = card(PlayerTab, "Auto Skill Tree", {side = 2})
	toggleD(c, "AutoSkillTree", "Auto Skill Tree", "Spends points up to the levels below", false)
	for _, row in ipairs(ST.LIST) do
		slider(c, ST.flag(row[1]), row[1] .. " up to", 0, row[2], 1, 0)
	end
	UI.skillTreeNote = cardNote(c, "", 20)
end
function ST.step()
	local d = getData()
	if not (d and M.SignalFunction) then return end
	local points = d.SkillPoints.Value
	local bits = {}
	for _, row in ipairs(ST.LIST) do
		local want = Options[ST.flag(row[1])].Value
		local have = ST.level(d, row[1])
		if want > 0 then table.insert(bits, row[1]:gsub("%l", "") .. " " .. have .. "/" .. want) end
	end
	UI.skillTreeNote.Text = fmtNum(points) .. " points  ·  " .. table.concat(bits, "  ")
	if not Options.AutoSkillTree.Value or points <= 0 then return end
	local pick, low
	for _, row in ipairs(ST.LIST) do
		local want = Options[ST.flag(row[1])].Value
		local have = ST.level(d, row[1])
		if have < want and os.clock() > (ST.fail[row[1]] or 0) and (not low or have < low) then pick, low = row[1], have end
	end
	if not pick then return end
	local before = ST.level(d, pick)
	pcall(M.SignalFunction.ToServer, "UnlockSkillTreeNode", {pick})
	task.wait(0.8)
	if ST.level(d, pick) > before then
		dlog("world", string.format("Skill Tree: %s → %d", pick, before + 1))
	else
		ST.fail[pick] = os.clock() + 120
	end
end
task.spawn(function()
	while alive do
		pcall(ST.step)
		task.wait(3)
	end
end)

Options.EquipBuild.Callback =function(v) if Options.AutoEquipBest.Value then task.spawn(Eq.apply, v) end end
Options.AutoEquipBest.Callback = function(on) if on then task.spawn(Eq.apply, Options.EquipBuild.Value) end end
task.spawn(function()
	local lastCount = -1
	while alive do
		task.wait(5)
		local d = getData()
		local n = d and #d.Inventory.Inventory:GetChildren() or 0
		if Options.AutoEquipBest.Value and (n ~= lastCount or os.clock() - Eq.last > 60) and not E.moving and not E.hoverConn then
			lastCount = n
			Eq.last = os.clock()
			pcall(Eq.apply, Options.EquipBuild.Value, true)
		end
		local wild = Gr.wildHorse()
		UI.horseNote.Text = Gr.hasHorse() and "You own a Horse." or (wild and "An escaped horse is out right now!" or "No escaped horse right now.") .. "  ·  " .. fmtNum(Gr.wen()) .. " Wen"
	end
end)

for _, f in ipairs(Farms.list) do
	if f.name == "Buy horse" then
		f.priority = 2
		Options.AutoBuyHorse.Callback = function(on) dlog("farm", "Buy horse " .. (on and "on" or "off")) end
	end
end

local DM = {lastNote = "", tries = 0}
DM.LAIR_ATTR = "IsInMuzanLayor"
DM.HIGOSHIMA = Vector3.new(1451.5, 1245.5, -220)
do
	local s = tryRequire(function() return RS.CAM.Global.MuzanSettings end)
	if type(s) == "table" then
		DM.settings = s
		DM.LAIR_ATTR = s.LairAttribute or DM.LAIR_ATTR
		if typeof(s.HigoshimaSpawn) == "CFrame" then DM.HIGOSHIMA = s.HigoshimaSpawn.Position end
	end
end
DM.ROUTES = {
	Vector3.new(183, 905, 590), Vector3.new(230, 963, 260), Vector3.new(110, 830, 800),
	Vector3.new(1850, 599, -800), Vector3.new(1765, 599, -450), Vector3.new(1780, 599, -150),
	Vector3.new(-600, 1380, -2605), Vector3.new(-400, 1360, -2800), Vector3.new(-440, 1355, -3300), Vector3.new(-185, 1375, -3050), Vector3.new(-170, 1350, -2650),
}
function DM.nextRoute()
	local root = getRoot()
	DM.visited = DM.visited or {}
	local best, bestD
	for i, p in ipairs(DM.ROUTES) do
		if not DM.visited[i] then
			local d = root and (p - root.Position).Magnitude or 0
			if not bestD or d < bestD then best, bestD = i, d end
		end
	end
	if not best then DM.visited = {} return DM.nextRoute() end
	return best
end
DM.LILY_SPOTS = {Vector3.new(714, 1121, -808), Vector3.new(540, 1121, -1020), Vector3.new(667, 1121, -1100), Vector3.new(585, 1146, -1315), Vector3.new(657, 1019, 140)}
DM.SAFE = Vector3.new(-1159.6, 1195.1, -1008.9)
if DM.settings and typeof(DM.settings.HigoshimaSafeZone) == "CFrame" then DM.SAFE = DM.settings.HigoshimaSafeZone.Position end
function DM.doctor()
	local best, bestD
	for _, m in ipairs(workspace:GetDescendants()) do
		if m:IsA("Model") and m.Name:lower():find("higoshima") then
			local p = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
			if p then
				local d = (p.Position - DM.HIGOSHIMA).Magnitude
				local r = getRoot()
				if r then d = math.min(d, (p.Position - r.Position).Magnitude) end
				if not bestD or d < bestD then best, bestD = m, d end
			end
		end
	end
	return best
end
DM.ELIGIBLE = DM.settings and DM.settings.EligibleReputation or -40
DM.ENTRY = DM.settings and DM.settings.LairEntryReputation or -20

function DM.rep()
	local d = getData()
	return d and d.Reputation and d.Reputation.Value or 0
end
function DM.has(name)
	local d = getData()
	return d ~= nil and d.Inventory.Inventory:FindFirstChild(name) ~= nil
end
function DM.night()
	local t = game:GetService("Lighting").ClockTime
	return t >= 18.5 or t < 5.5
end
function DM.inLair()
	return player:GetAttribute(DM.LAIR_ATTR) == true
end
function DM.quest()
	return Q.state("Muzan Quest") == "Doing"
end
function DM.note(text)
	C.status = "become demon · " .. text
	if UI.demonStatus then UI.demonStatus.Text = text end
	if text ~= DM.lastNote then
		DM.lastNote = text
		dlog("world", "Become demon: " .. text)
	end
end
function DM.useItem(name, hold)
	local d = getData()
	local it = d and d.Inventory.Inventory:FindFirstChild(name)
	local id = it and it:FindFirstChild("Id")
	if not (id and M.SignalEvent) then return false end
	local key = ({"One", "Two", "Three", "Four", "Five"})[Options.PotionSlot.Value]
	local slot = d.Inventory.Toolbar:FindFirstChild(key)
	if slot and slot.Value ~= id.Value then
		pcall(M.SignalEvent.ToServer, "Toolbar_Equip", key, id.Value)
		task.wait(1)
	end
	local cfg = player:FindFirstChild("Items_Config")
	local eq = cfg and cfg:FindFirstChild("Equipped")
	if not eq then return false end
	eq.Value = Options.PotionSlot.Value
	task.wait(0.8)
	local root = getRoot()
	local pos = root and root.Position or Vector3.zero
	pcall(M.SignalEvent.ToServer, "Tool_Mouse", "Down", pos)
	task.wait(hold or 0.3)
	pcall(M.SignalEvent.ToServer, "Tool_Mouse", "Up", pos)
	task.wait(0.6)
	return true
end
function DM.findModel(name)
	local root = getRoot()
	local best, bestD
	for _, m in ipairs(workspace:GetDescendants()) do
		if m:IsA("Model") and m.Name == name and m:FindFirstChildOfClass("Humanoid") then
			local p = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
			if p then
				local d = root and (p.Position - root.Position).Magnitude or 0
				if not bestD or d < bestD then best, bestD = m, d end
			end
		end
	end
	return best
end
function DM.findMuzan()
	local deb = workspace:FindFirstChild("Debree")
	local misc = deb and deb:FindFirstChild("Regions") and deb.Regions:FindFirstChild("Misc")
	local an = misc and misc:FindFirstChild("ActiveNpcs")
	local m = an and an:FindFirstChild("Muzan")
	if m and (m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart) then return m end
	for _, reg in ipairs(deb and deb:FindFirstChild("Regions") and deb.Regions:GetChildren() or {}) do
		local a = reg:FindFirstChild("ActiveNpcs")
		local x = a and a:FindFirstChild("Muzan")
		if x then return x end
	end
	return nil
end
function DM.talkTo(m)
	local p = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
	local pr = Q.chatPrompt(m)
	if not (p and pr) then return false end
	local root = getRoot()
	if root and (root.Position - p.Position).Magnitude > math.max(pr.MaxActivationDistance - 3, 4) then
		E.travel(p.Position, math.max(pr.MaxActivationDistance - 4, 3))
	end
	E.fire(pr)
	local t0 = os.clock()
	repeat task.wait(0.2) until Q.buttons() or os.clock() - t0 > 4
	return Q.buttons() ~= nil
end
function DM.clickThrough(wanted)
	for _ = 1, 10 do
		local bh = Q.buttons()
		if not bh then return false end
		local pick, first
		for _, b in ipairs(bh:GetChildren()) do
			if b:IsA("GuiObject") and not b.Name:find("^ZZZZ") then
				first = first or b
				if b.Name:lower():find(wanted:lower(), 1, true) then pick = b end
			end
		end
		if pick then Q.click(pick) task.wait(1.2) return true end
		if not first then return false end
		Q.click(first)
		task.wait(1)
	end
	return false
end
function DM.lilyPrompts()
	local out = {}
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("ProximityPrompt") and d.Enabled then
			local txt = (d.ObjectText .. " " .. d.ActionText .. " " .. (d.Parent and d.Parent.Name or "") .. " " .. (d:FindFirstAncestorOfClass("Model") and d:FindFirstAncestorOfClass("Model").Name or "")):lower()
			if txt:find("lily") or txt:find("lilies") then table.insert(out, d) end
		end
	end
	local root = getRoot()
	if root then
		table.sort(out, function(a, b)
			local pa, pb = E.promptPos(a), E.promptPos(b)
			return (pa and (pa - root.Position).Magnitude or 1e9) < (pb and (pb - root.Position).Magnitude or 1e9)
		end)
	end
	return out
end
function DM.taskValue(name)
	local q = Q.activeByCategory("Muzan")
	for _, tk in ipairs(q and q.tasks or {}) do
		if tk.name == name then return tk.value, tk.max end
	end
	return 0, 1
end

do
	local c = card(FarmTab, "Become Demon", {side = 2})
	toggleD(c, "AutoDemon", "Auto Become Demon", "-Rep, Muzan's bell, lair quest, drink", false)
	UI.demonStatus = cardNote(c, "Humans only. Muzan walks at night.", 34)
end

Farms.add({name = "Become demon", flag = "AutoDemon", priority = 3,
	enabled = function() return Options.AutoDemon.Value and playerRace() == "Human" end,
	ready = function()
		if DM.has("Muzan's Blood") or DM.quest() or DM.inLair() then return true end
		local rep = DM.rep()
		if rep > DM.ELIGIBLE then return true end
		if DM.has("Biwa Bell") then return rep < DM.ENTRY and DM.night() end
		return DM.night()
	end,
	step = function()
		local rep = DM.rep()
		if DM.has("Muzan's Blood") then
			C.disengage()
			DM.note("drinking Muzan's Blood")
			DM.useItem("Muzan's Blood", 2.6)
			task.wait(10)
			if playerRace() == "Demon" then
				dlog("loot", "You are a Demon now")
				notify("success", "Become Demon", "Done. Welcome to the dark.")
				Options.AutoDemon:SetValue(false)
			end
			return
		end
		if DM.quest() then
			local lv, lmax = DM.taskValue("Spider Lilies")
			if lv < lmax then
				local list = DM.lilyPrompts()
				if #list == 0 then
					DM.lilyIdx = (DM.lilyIdx or 0) % #DM.LILY_SPOTS + 1
					DM.note(string.format("looking for Spider Lilies %d/%d · Bamboo Grove spot %d", lv, lmax, DM.lilyIdx))
					C.disengage()
					E.travel(DM.LILY_SPOTS[DM.lilyIdx], 20)
					task.wait(2)
					return
				end
				C.disengage()
				DM.note(string.format("picking Spider Lilies %d/%d", lv, lmax))
				E.usePrompt(list[1], 0.6)
				task.wait(0.6)
				return
			end
			C.disengage()
			local m = DM.doctor()
			local root = getRoot()
			local mp = m and (m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart)
			local carrying = mp and root and (mp.Position - root.Position).Magnitude < 7 and DM.carriedSince and os.clock() - DM.carriedSince > 1
			if carrying then
				DM.note("carrying Dr. Higoshima · staying in the air")
				E.WK.airTo(DM.SAFE, 8, 26)
				task.wait(2)
				return
			end
			if not m or not root or (mp.Position - root.Position).Magnitude > 25 then
				DM.note("going to Dr. Higoshima")
				E.travel(mp and mp.Position or DM.HIGOSHIMA, 10)
				return
			end
			DM.note("picking up Dr. Higoshima")
			local pr
			for _, d in ipairs(m:GetDescendants()) do
				if d:IsA("ProximityPrompt") and d.Enabled then pr = d break end
			end
			if pr then
				dlog("world", "Doctor prompt: " .. tostring(pr.ActionText) .. " / " .. tostring(pr.ObjectText))
				E.usePrompt(pr, 0.6)
				DM.carriedSince = os.clock()
				task.wait(1.5)
			else
				DM.talkTo(m)
				DM.clickThrough("carry")
				task.wait(1)
				Q.closeDialogue()
				DM.carriedSince = os.clock()
			end
			return
		end
		if DM.inLair() then
			C.disengage()
			DM.note("in Muzan's lair · taking his task")
			pcall(M.SignalEvent.ToServer, "MuzanLairAssign")
			task.wait(2)
			if not DM.quest() then
				local m = DM.findModel("MuzanLairModel") or DM.findModel("Muzan")
				if m and DM.talkTo(m) then DM.clickThrough("mission") task.wait(1) Q.closeDialogue() end
			end
			return
		end
		if DM.has("Biwa Bell") then
			if rep >= DM.ENTRY or not DM.night() then
				local g, filter = F.repTarget(true)
				DM.note(rep >= DM.ENTRY and string.format("Rep %d · need below %d to ring the bell", rep, DM.ENTRY) or "have the bell · waiting for night")
				if g then return C.fight(filter, g.center, math.max(g.despawn, 300), "-Rep · " .. g.name) end
				return
			end
			C.disengage()
			DM.note("ringing the Biwa Bell")
			local t0 = os.clock()
			while E.inCombat() and os.clock() - t0 < 20 do task.wait(0.5) end
			DM.useItem("Biwa Bell", 0.3)
			task.wait(6)
			return
		end
		if rep > DM.ELIGIBLE then
			local g, filter = F.repTarget(true)
			DM.note(string.format("Rep %d · lowering to %d", rep, DM.ELIGIBLE))
			if g then return C.fight(filter, g.center, math.max(g.despawn, 300), "-Rep · " .. g.name) end
			return
		end
		local m = DM.findMuzan()
		if not m then
			DM.routeIdx = DM.nextRoute()
			local spot = DM.ROUTES[DM.routeIdx]
			DM.note("night · looking for Muzan · spot " .. DM.routeIdx .. "/" .. #DM.ROUTES)
			C.disengage()
			local watching = true
			task.spawn(function()
				while watching do
					if DM.findMuzan() then E.stopMoving() break end
					task.wait(1)
				end
			end)
			E.travel(spot, 25)
			watching = false
			local t0 = os.clock()
			repeat task.wait(1) m = DM.findMuzan() until m or os.clock() - t0 > 8 or not DM.night()
			DM.visited[DM.routeIdx] = true
			if not m then return end
			dlog("world", "Found Muzan near spot " .. DM.routeIdx)
		end
		C.disengage()
		DM.note("talking to Muzan")
		if DM.talkTo(m) then
			DM.clickThrough("take the bell")
			task.wait(1)
			Q.closeDialogue()
			if DM.has("Biwa Bell") then
				dlog("loot", "Got the Biwa Bell")
				notify("success", "Become Demon", "Muzan gave you the Biwa Bell.")
			end
		end
	end})

local PR = {ROW_H = 28, rows = {}, built = false, moving = false}
PR.DEFAULT = {"Sell pouches", "Buy potions", "Buy horse", "Become demon", "Boss hunts", "Pick bosses", "Sealed chests", "Schematics",
	"Demon quests", "Slayer quests", "Wen farm", "Mastery farm", "Rep farm", "Level farm"}
PR.opt = register("FarmOrder", table.clone(PR.DEFAULT), function()
	if PR.built and not PR.moving then task.defer(function() PR.rebuild() end) end
end)
PR.opt.NoRefresh = true

function Farms.prio(f)
	return table.find(PR.opt.Value, f.name) or (50 + (f.priority or 5))
end

do
	local c = UI.prioCard
	cardNote(c, "Drag ⋮⋮ or type a number. Top runs first.", 18)
	PR.list = make("Frame", {Parent = c.container, LayoutOrder = nextOrder(c), Size = UDim2.new(1, 0, 0, #PR.DEFAULT * PR.ROW_H), BackgroundTransparency = 1})
	c.grow(#PR.DEFAULT * PR.ROW_H + 4)
	PR.card = c
end

function PR.layout(instant)
	local order = PR.opt.Value
	PR.list.Size = UDim2.new(1, 0, 0, #order * PR.ROW_H)
	for i, key in ipairs(order) do
		local r = PR.rows[key]
		if r then
			r.box.Text = tostring(i)
			local pos = UDim2.fromOffset(0, (i - 1) * PR.ROW_H)
			if r ~= PR.dragging then
				if instant then r.frame.Position = pos else tween(r.frame, {Position = pos}, 0.2) end
			end
		end
	end
end

function PR.move(key, newIndex)
	local order = table.clone(PR.opt.Value)
	local idx = table.find(order, key)
	if not idx then return end
	table.remove(order, idx)
	table.insert(order, math.clamp(newIndex, 1, #order + 1), key)
	PR.moving = true
	PR.opt:SetValue(order)
	PR.moving = false
	PR.layout()
end

function PR.makeRow(key)
	local f = make("Frame", {Parent = PR.list, Size = UDim2.new(1, 0, 0, PR.ROW_H - 4), BackgroundColor3 = T.Element, BackgroundTransparency = 0.15}, {corner(6)})
	local s = stroke(T.Stroke, 0.75); s.Parent = f
	local handle = make("TextButton", {Parent = f, Size = UDim2.fromOffset(22, PR.ROW_H - 4), BackgroundTransparency = 1, Text = "⋮⋮", Font = FONT_B, TextSize = 12, TextColor3 = T.SubText, AutoButtonColor = false})
	local box = textBox(f, {Position = UDim2.fromOffset(24, 3), Size = UDim2.fromOffset(30, PR.ROW_H - 10), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 12, TextTruncate = Enum.TextTruncate.None})
	local pad = box:FindFirstChildOfClass("UIPadding")
	if pad then pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 2), UDim.new(0, 2) end
	local name = label({Parent = f, Position = UDim2.fromOffset(62, 0), Size = UDim2.new(1, -124, 1, 0), Text = key, Font = FONT, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd})
	local state = label({Parent = f, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 0), Size = UDim2.fromOffset(56, PR.ROW_H - 4), Text = "", Font = FONT_B, TextSize = 10, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Right})
	PR.rows[key] = {frame = f, box = box, name = name, state = state, key = key}
	connect(f.MouseEnter, function() tween(s, {Color = T.Accent, Transparency = 0.5}) end)
	connect(f.MouseLeave, function() tween(s, {Color = T.Stroke, Transparency = 0.75}) end)
	connect(box.FocusLost, function()
		local n = tonumber(box.Text)
		if n then PR.move(key, math.floor(n)) else PR.layout() end
	end)
	connect(handle.InputBegan, function(i)
		if i.UserInputType == MB1 or i.UserInputType == TOUCH then
			PR.dragging = PR.rows[key]
			f.ZIndex = 5
			tween(f, {BackgroundColor3 = T.Hover}, 0.1)
		end
	end)
end

function PR.rebuild()
	for k, r in pairs(PR.rows) do r.frame:Destroy() PR.rows[k] = nil end
	local known, order = {}, {}
	for _, f in ipairs(Farms.list) do known[f.name] = true end
	for _, k in ipairs(type(PR.opt.Value) == "table" and PR.opt.Value or {}) do
		if known[k] and not table.find(order, k) then table.insert(order, k) end
	end
	for i, k in ipairs(PR.DEFAULT) do
		if known[k] and not table.find(order, k) then table.insert(order, math.min(i, #order + 1), k) end
	end
	for _, f in ipairs(Farms.list) do
		if not table.find(order, f.name) then table.insert(order, f.name) end
	end
	PR.opt.Value = order
	for _, k in ipairs(order) do PR.makeRow(k) end
	PR.layout(true)
	PR.built = true
end

connect(UIS.InputChanged, function(i)
	local d = PR.dragging
	if d and (i.UserInputType == MOVE or i.UserInputType == TOUCH) then
		local y = i.Position.Y - PR.list.AbsolutePosition.Y - PR.ROW_H / 2
		d.frame.Position = UDim2.fromOffset(0, math.clamp(y, 0, PR.list.AbsoluteSize.Y - PR.ROW_H))
	end
end)
connect(UIS.InputEnded, function(i)
	local d = PR.dragging
	if d and (i.UserInputType == MB1 or i.UserInputType == TOUCH) then
		PR.dragging = nil
		d.frame.ZIndex = 1
		tween(d.frame, {BackgroundColor3 = T.Element}, 0.15)
		PR.move(d.key, math.floor((d.frame.Position.Y.Offset + PR.ROW_H / 2) / PR.ROW_H) + 1)
	end
end)

button(PR.card, "Reset order", nil, function()
	PR.moving = true
	PR.opt:SetValue(table.clone(PR.DEFAULT))
	PR.moving = false
	PR.rebuild()
	notify("success", "Priority", "Recommended order back.")
end)

PR.rebuild()
task.spawn(function()
	while alive do
		for _, f in ipairs(Farms.list) do
			local r = PR.rows[f.name]
			if r then
				local ok, on = pcall(f.enabled)
				on = ok and on
				if Farms.active == f then
					r.state.Text, r.state.TextColor3 = "RUNNING", T.Accent
				elseif on then
					r.state.Text, r.state.TextColor3 = "ON", T.Text
				else
					r.state.Text, r.state.TextColor3 = "OFF", T.SubText
				end
				r.name.TextColor3 = on and T.Text or T.SubText
			end
		end
		task.wait(1)
	end
end)

do
	local c = card(SettingsTab, "Configs", {side = 1})
	local CFG_DIR = CONFIG_DIR .. "/ouwland-configs"
	local CFG_AUTO = CONFIG_DIR .. "/ouwland-autoload.txt"
	local cfgName = input(c, "ConfigName", "Name", "e.g. boss farm")
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
	local cfgSelect = dropdown(c, "ConfigSelect", "Saved", listConfigs(), false, "")
	cfgSelect.NoSave = true
	local autoNote = cardNote(c, "", 20)
	local function getAutoload()
		if not canFiles then return nil end
		local ok, n = pcall(function() return isfile(CFG_AUTO) and readfile(CFG_AUTO) or nil end)
		n = ok and n and trim(n) or nil
		return (n ~= "" and n) or nil
	end
	local function refreshCfg()
		cfgSelect.SetValues(listConfigs())
		local a = getAutoload()
		autoNote.Text = a and ("Autoload: <b>" .. a .. "</b>") or "Autoload: off (last session restored)"
	end
	UI.getAutoload, UI.CFG_DIR = getAutoload, CFG_DIR
	button(c, "Save config", nil, function()
		local n = trim(cfgName.Value)
		if n == "" then n = cfgSelect.Value or "" end
		if n == "" then notify("warn", "No name", "Type a config name first.") return end
		ensureDirs()
		pcall(function() if not isfolder(CFG_DIR) then makefolder(CFG_DIR) end end)
		local ok = pcall(writefile, CFG_DIR .. "/" .. n .. ".json", HttpService:JSONEncode(collect()))
		refreshCfg()
		cfgSelect:SetValue(n, true)
		notify(ok and "success" or "error", ok and "Config saved" or "Save failed", n)
	end)
	button(c, "Load selected", nil, function()
		local n = cfgSelect.Value
		if not n or n == "" then notify("warn", "Nothing selected", "Pick a config first.") return end
		local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CFG_DIR .. "/" .. n .. ".json")) end)
		if ok and type(data) == "table" then applyData(data) notify("success", "Config loaded", n) else notify("error", "Load failed", n) end
	end)
	button(c, "Delete selected", nil, function()
		local n = cfgSelect.Value
		if not n or n == "" then return end
		pcall(delfile, CFG_DIR .. "/" .. n .. ".json")
		if getAutoload() == n then pcall(delfile, CFG_AUTO) end
		cfgSelect:SetValue("", true)
		refreshCfg()
		notify("info", "Config deleted", n)
	end)
	button(c, "Autoload selected", nil, function()
		local n = cfgSelect.Value
		if not n or n == "" then notify("warn", "Nothing selected", "Pick a config first.") return end
		ensureDirs()
		pcall(writefile, CFG_AUTO, n)
		refreshCfg()
		notify("success", "Autoload set", n)
	end)
	button(c, "Turn off autoload", nil, function() pcall(delfile, CFG_AUTO) refreshCfg() end)
	refreshCfg()
end
do
	local c = card(SettingsTab, "Script", {side = 2})
	cardNote(c, "End key or the round button hides the window. Anti-AFK is always on.", 30)
	button(c, "Unload", nil, function() app.Destroy() end)
end

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
function UI.buildAvatar()
	for _, c in ipairs(UI.viewport:GetChildren()) do
		if c:IsA("WorldModel") or c:IsA("Camera") then c:Destroy() end
	end
	local model = cloneCharacter()
	if not model or not model:FindFirstChild("HumanoidRootPart") then UI.avatarLoading.Text = "Avatar unavailable" return end
	local world = Instance.new("WorldModel")
	world.Parent = UI.viewport
	model.Parent = world
	local root = model.HumanoidRootPart
	root.Anchored = true
	model:PivotTo(CFrame.new(0, 0, 0))
	for _, p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		pcall(function()
			local d = getData()
			local anims = RS.Assets.Animations.mainPlace
			local idle = (d and d.Race.Value == "Demon") and anims.demonIdle or anims.humanIdle
			local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
			animator:LoadAnimation(idle):Play(0)
		end)
	end
	local cam = Instance.new("Camera")
	cam.Parent = UI.viewport
	UI.viewport.CurrentCamera = cam
	cam.FieldOfView = 30
	local focus = root.Position + Vector3.new(0, 1.1, 0)
	cam.CFrame = CFrame.lookAt(focus + Vector3.new(-2.2, 0.6, -7.5), focus)
	UI.avatarModel, UI.avatarBase = model, model:GetPivot()
	UI.avatarLoading.Text = ""
	tween(UI.viewport, {ImageTransparency = 0}, 0.6)
end
connect(RunService.RenderStepped, function()
	if UI.avatarModel and UI.avatarModel.Parent and main.Visible and HomeTab.page.Visible then
		UI.avatarModel:PivotTo(UI.avatarBase * CFrame.Angles(0, math.sin(os.clock() * 0.8) * 0.45, 0))
	end
end)

UI.ART_COLORS = {Shockwave = "#3FA9FF", Tamari = "#FF8C1A", ["Blood Manipulation"] = "#FF2E3B", Pyrokenesis = "#FF6EC7", Arrow = "#3EDB5A",
	Cryokinesis = "#8FEAFF", Dream = "#B38CFF", ["Obi Manipulation"] = "#FFD23F", Reaper = "#8E5CFF", Thread = "#F2F2F2",
	Water = "#3FA9FF", Flame = "#FF7A1A", Thunder = "#FFE14A", Wind = "#6FE39A", Stone = "#B4B4B4", Flower = "#FF8FC8", Insect = "#B98CFF",
	Serpent = "#E05CC4", Sound = "#FFB347", Beast = "#C08A5A"}
function UI.refreshProfile()
	local d = getData(true)
	if not d then return end
	pcall(function()
		local lvl = playerLevel()
		UI.levelValue.Text = tostring(lvl)
		UI.wenValue.Text = fmtNum(d.Wen.Value)
		UI.wenValue.TextColor3 = Color3.fromRGB(245, 196, 81)
		local race = d.Race.Value
		UI.raceValue.Text = race
		local art, br = d.Powers.DemonArt.Value, d.Powers.Breathing.Value
		if race == "Human" or race == "Slayer" or (art == "" and br ~= "") then
			UI.pills[4].t.Text = "Breathing"
			UI.artValue.Text = br ~= "" and br or "None"
			UI.artValue.TextColor3 = fromHex(UI.ART_COLORS[br] or "#EAECE2") or T.Text
		else
			UI.pills[4].t.Text = "Demon Art"
			UI.artValue.Text = art ~= "" and art or "None"
			UI.artValue.TextColor3 = fromHex(UI.ART_COLORS[art] or "#EAECE2") or T.Text
		end
		local clan = d.Clan.Value
		UI.clanValue.Text = clan ~= "" and clan or "None"
		local tier = M.Clans and M.Clans.TierOf and select(2, isolated(M.Clans.TierOf, clan))
		UI.clanValue.TextColor3 = (type(tier) == "table" and typeof(tier.color) == "Color3") and tier.color or T.Text
		local rankV = (race == "Demon") and d:FindFirstChild("DemonRank") or d:FindFirstChild("SlayerRank")
		UI.rankValue.Text = rankV and rankV.Value ~= "" and rankV.Value or "-"
		local rep = d.Reputation.Value
		dbg.startRep = dbg.startRep or rep
		dbg.startWen = dbg.startWen or d.Wen.Value
		dbg.rep, dbg.wen, dbg.level = rep, d.Wen.Value, lvl
		local repText = (rep > 0 and "+" or "") .. fmtNum(rep)
		local repCol = rep < 0 and Color3.fromRGB(255, 110, 100) or (rep > 0 and Color3.fromRGB(110, 200, 255) or T.Text)
		UI.repValue.Text, UI.repValue.TextColor3 = repText, repCol
		UI.repBig.Text, UI.repBig.TextColor3 = repText, repCol
		local delta = rep - dbg.startRep
		UI.repDelta.Text = delta ~= 0 and ((delta > 0 and "+" or "") .. fmtNum(delta) .. " now") or ""
		local ore = d.Inventory.Inventory:FindFirstChild("Ore")
		local oa = ore and ore:FindFirstChild("Amount")
		dbg.ore = oa and oa.Value or 0
	end)
end

function UI.sessionTime()
	local s = os.time() - dbg.started
	if s >= 3600 then return string.format("%dh %02dm", s // 3600, (s % 3600) // 60) end
	return string.format("%dm %02ds", s // 60, s % 60)
end

Overlay.build({"Ore", "Wen", "Level", "Kills", "Rep", "Session"})

task.spawn(function()
	UI.refreshProfile()
	UI.buildAvatar()
	while alive do
		task.wait(3)
		UI.refreshProfile()
	end
end)
connect(player.CharacterAdded, function()
	task.delay(3, function() if alive then UI.buildAvatar() end end)
	if Farms.active then
		dbg.deaths += 1
		dlog("warn", "Died — respawning, the farm carries on")
		if Farms.active.name == "Level farm" then pcall(F.noteDeath) end
		E.stopMoving()
		C.disengage()
		C.healing = false
	end
end)

task.spawn(function()
	while alive do
		task.wait(8)
		local ok, list = isolated(E.availableSkills)
		if ok and type(list) == "table" and table.concat(list, "|") ~= table.concat(E.skillList, "|") then
			E.skillList = list
			UI.skillDrop.SetValues(list)
		end
	end
end)

do
	local watched = setmetatable({}, {__mode = "k"})
	task.spawn(function()
		while alive do
			local root = getRoot()
			for _, e in ipairs(E.enemies()) do
				if not watched[e.hum] and root and (e.root.Position - root.Position).Magnitude < 300 then
					watched[e.hum] = true
					local name, model, grp = e.name, e.model, e.group
					connect(e.hum.Died, function()
						local r = getRoot()
						local mine = E.target and E.target.model == model
						if mine or (Farms.active and r and model.PrimaryPart and (model.PrimaryPart.Position - r.Position).Magnitude < 40) then
							dbg.kills += 1
							C.lastKillAt = os.clock()
							if grp and grp.boss then dbg.bosses += 1 dlog("boss", name .. " defeated") end
						end
					end)
				end
			end
			task.wait(1)
		end
	end)
end

do
	local STUN = {CombatStun = true, Stun = true, Strict_Stun = true, novelocity = true}
	task.spawn(function()
		local v = RS:FindFirstChild("Player_Service") and RS.Player_Service:FindFirstChild("Values")
		v = v and v:WaitForChild(player.Name, 10)
		if not v then return end
		connect(v.ChildAdded, function(c)
			if STUN[c.Name] then
				if os.clock() - dbg.lastStunAt > 0.5 then dbg.stuns += 1 end
				dbg.lastStunAt = os.clock()
				if Options.AntiStun.Value then task.defer(function() pcall(function() c:Destroy() end) end) end
			end
		end)
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
			if not Options.AntiRagdoll.Value then return end
			if new == Enum.HumanoidStateType.Physics or new == Enum.HumanoidStateType.FallingDown or new == Enum.HumanoidStateType.Ragdoll then
				restoreJoints(char)
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end)
	end
	if getChar() then task.spawn(watchRagdoll, getChar()) end
	connect(player.CharacterAdded, function(ch) task.spawn(watchRagdoll, ch) end)
	pcall(function()
		connect(CS:GetInstanceAddedSignal("Ragdoll"), function(inst)
			local char = getChar()
			if char and inst:IsDescendantOf(char) and Options.AntiRagdoll.Value then
				task.defer(function()
					pcall(function() CS:RemoveTag(inst, "Ragdoll") end)
					restoreJoints(char)
					local hum = getHum()
					if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
				end)
			end
		end)
	end)
end

do
	local LOCO = {walkanim = true, run = true, jump = true, fall = true, idle = true, climb = true, swim = true, sit = true, landed = true, toolnone = true, walk = true}
	local watched = setmetatable({}, {__mode = "k"})
	local learnedIgnore = {}
	local hitDelay = {}
	local aggro = setmetatable({}, {__mode = "k"})
	local lastAnim
	local lastPress = 0
	local function busy()
		return C.healing or E.moving or (E.WK and E.WK.walking)
	end
	local function comboing(e)
		local t = E.target
		if not (t and e and t.model == e.model) then return false end
		if os.clock() - (E.lastPunchAt or 0) > 0.9 then return false end
		local root = getRoot()
		return root ~= nil and (t.root.Position - root.Position).Magnitude < 14
	end
	local function pressBlockFresh(duration)
		if os.clock() - lastPress < 0.2 then
			E.blockUntil = math.max(E.blockUntil, os.clock() + duration)
			return
		end
		lastPress = os.clock()
		if E.blocking then E.stopBlock() task.wait(0.04) end
		E.lastBlockTry = 0
		E.startBlock(duration)
	end
	local function watchEnemy(e)
		local animator = e.hum:FindFirstChildOfClass("Animator")
		if not animator or watched[animator] then return end
		watched[animator] = true
		connect(animator.AnimationPlayed, function(track)
			local bossBlock = e.group and e.group.boss and Options.BossBlock.Value
			if not (bossBlock or Options.AutoBlock.Value or Options.AutoParry.Value) then return end
			if busy() or comboing(e) then return end
			local anim = track.Animation
			local root = getRoot()
			if not (anim and root and e.root.Parent) then return end
			local id = anim.AnimationId
			local dist = (e.root.Position - root.Position).Magnitude
			if dist > 35 then learnedIgnore[id] = true return end
			local name = anim.Name:lower()
			if learnedIgnore[id] or LOCO[name] or name:find("walk") or name:find("idle") or name:find("run") then return end
			for _, w in ipairs({"stun", "knock", "ragdoll", "death", "block", "getup", "spawn"}) do
				if name:find(w, 1, true) then return end
			end
			if track.Looped and track.Priority.Value < Enum.AnimationPriority.Action.Value then return end
			if dist > Options.ParryRange.Value then return end
			lastAnim = {t = os.clock(), id = id}
			if Options.AutoParry.Value then
				local lead = Options.PerfectLead.Value
				task.delay(math.max(0, (hitDelay[id] or 0.27) - lead), function()
					if not busy() then pressBlockFresh(lead + 0.25) end
				end)
			else
				if track.Looped then return end
				aggro[e.model] = {t = os.clock(), start = os.clock(), track = track, e = e}
				if os.clock() >= (E.attackWindow or 0) then E.startBlock(0.3) end
			end
		end)
	end
	task.spawn(function()
		while alive do
			local root = getRoot()
			for _, e in ipairs(E.enemies()) do
				if root and (e.root.Position - root.Position).Magnitude < 60 then watchEnemy(e) end
			end
			task.wait(1)
		end
	end)
	local function watchHealth(char)
		local hum = char:WaitForChild("Humanoid", 10)
		if not hum then return end
		local last = hum.Health
		connect(hum.HealthChanged, function(h)
			if h < last - 0.5 then
				dbg.hits += 1
				C.lastHit = os.clock()
				if lastAnim and os.clock() - lastAnim.t < 0.8 then
					local d = os.clock() - lastAnim.t
					local old = hitDelay[lastAnim.id]
					hitDelay[lastAnim.id] = old and (old * 0.5 + d * 0.5) or d
					lastAnim = nil
				end
			end
			last = h
		end)
	end
	if getChar() then task.spawn(watchHealth, getChar()) end
	connect(player.CharacterAdded, function(ch) task.spawn(watchHealth, ch) end)
	connect(RunService.Heartbeat, function()
		if not Options.AutoParry.Value and next(aggro) then
			local root = getRoot()
			local hold = false
			for model, a in pairs(aggro) do
				local okE = root and model.Parent and a.e.hum.Health > 0 and a.e.root.Parent
				if okE and a.track.IsPlaying and os.clock() - a.start < 1.2 then a.t = os.clock() end
				if okE and not busy() and not comboing(a.e) and os.clock() - a.t < Options.BlockHold.Value and (a.e.root.Position - root.Position).Magnitude <= Options.ParryRange.Value + 4 then
					hold = true
				elseif not okE or os.clock() - a.t > Options.BlockHold.Value then
					aggro[model] = nil
				end
			end
			if hold and os.clock() < (E.attackWindow or 0) then hold = false end
			if hold then
				E.blockStreak = E.blockStreak or os.clock()
				if os.clock() - E.blockStreak > 0.8 then
					E.attackWindow = os.clock() + 0.9
					E.blockStreak = nil
					E.stopBlock()
				else
					E.startBlock(0.25)
				end
			else
				E.blockStreak = nil
			end
		end
		if not E.blocking and E.blockWanted then E.blockWanted = false end
		if E.blocking then E.lastOwnBlock = os.clock() end
		if not E.blocking and os.clock() - (E.lastOwnBlock or 0) < 10 and os.clock() - (E.lastWatchStop or 0) > 0.4 then
			local shc = E.getSHC()
			if shc and shc.Value == "Blocking" and not UIS:IsKeyDown(Enum.KeyCode.F) and M.SkillCtl then
				E.lastWatchStop = os.clock()
				task.spawn(pcall, M.SkillCtl.StopHold, "Blocking")
			end
		end
		if E.blocking then
			if busy() or os.clock() > E.blockUntil then E.stopBlock()
			elseif not E.blockActive() and os.clock() - E.lastBlockTry > 0.2 and M.SkillCtl then
				E.lastBlockTry = os.clock()
				task.spawn(pcall, M.SkillCtl.Attempt_Hold, "Blocking", "F")
			end
		end
	end)
end

connect(RunService.Heartbeat, function()
	local t = E.target
	if t and (t.hum.Health <= 0 or not t.model.Parent) then C.countKill(t) end
end)
do
	local MOVERS = {BodyVelocity = true, BodyPosition = true, BodyThrust = true, BodyForce = true, BodyGyro = false, LinearVelocity = true, VectorForce = true}
	local function hookChar(char)
		connect(char.DescendantAdded, function(d)
			if not (MOVERS[d.ClassName] and Options.AntiKnockback.Value and Farms.active) then return end
			local p = d.Parent
			if p and (p.Name == "HorseMover" or (p.Parent and p.Parent.Name == "HorseMover")) then return end
			task.delay(0.05, function()
				if d.Parent and os.clock() - C.lastHit < 0.6 and os.clock() - (E.WK.lastDash or 0) > 0.5 and os.clock() - (E.WK.lastJump or 0) > 0.5 then pcall(function() d:Destroy() end) end
			end)
		end)
	end
	if getChar() then hookChar(getChar()) end
	connect(player.CharacterAdded, hookChar)
	connect(RunService.Heartbeat, function()
		if not (Options.AntiKnockback.Value and Farms.active) or C.healing or E.hoverConn then return end
		if os.clock() - C.lastHit > 0.8 or os.clock() - (E.WK.lastDash or 0) < 0.6 then return end
		local root = getRoot()
		if not root then return end
		local v = root.AssemblyLinearVelocity
		if Vector3.new(v.X, 0, v.Z).Magnitude > 30 or v.Y > 35 then
			root.AssemblyLinearVelocity = Vector3.new(0, math.min(v.Y, 0), 0)
		end
	end)
end
do
	local known = {}
	task.spawn(function()
		while alive do
			local now = {}
			for _, q in ipairs(Q.active()) do now[q.name] = q end
			for name, q in pairs(known) do
				if not now[name] then
					local allDone = true
					for _, tk in ipairs(q.tasks) do if not tk.done then allDone = false end end
					if allDone or os.clock() - C.lastKillAt < 15 then
						dbg.quests += 1
						dlog("quest", "Quest done: " .. name)
						if UI.hookEvent then UI.hookEvent("quest", name) end
					end
				end
			end
			known = now
			task.wait(0.5)
		end
	end)
end

task.spawn(function()
	while alive do
		local f = Farms.pick()
		if f ~= Farms.active then
			local old = Farms.active
			if old then
				if old.stop then pcall(old.stop) end
				C.disengage()
				E.stopMoving()
			end
			Farms.active = f
			if f then
				dlog("farm", "Now running: " .. f.name)
				if f.start then pcall(f.start) end
			else
				C.status = ""
			end
		end
		if f then
			local ok, err = pcall(f.step)
			if not ok then
				dlog("warn", f.name .. " error: " .. tostring(err):sub(1, 140))
				C.disengage()
				task.wait(1)
			end
		end
		task.wait(f and 0.08 or 0.4)
	end
end)

do
	local frames, fpsAt = 0, os.clock()
	connect(RunService.RenderStepped, function()
		frames += 1
		if os.clock() - fpsAt >= 1 then dbg.fps, frames, fpsAt = frames / (os.clock() - fpsAt), 0, os.clock() end
	end)
end
local U = {}
function U.C(hex, text) return '<font color="' .. hex .. '">' .. text .. '</font>' end
function U.pctColor(p) return p >= 60 and "#6ee39a" or p >= 30 and "#ffd75c" or "#ff7a6e" end
function U.regionName()
	local root = getRoot()
	if not root then return "-" end
	local best, bestD
	for _, n in pairs(W.npcs) do
		local d = (n.pos - root.Position).Magnitude
		if not bestD or d < bestD then best, bestD = n.region, d end
	end
	return best or "-"
end
function U.snapshot()
	local lines = {"farm: " .. (Farms.active and Farms.active.name or "none") .. " — " .. tostring(C.status)}
	for k, v in pairs(UI.tiles) do table.insert(lines, k .. ": " .. (v.Text:gsub("<[^>]+>", ""))) end
	table.insert(lines, "--- log ---")
	for _, e in ipairs(dbg.history) do table.insert(lines, e.t .. " [" .. e.kind .. "] " .. tostring(e.text)) end
	return table.concat(lines, "\n")
end
connect(UI.logBtns.Copy.MouseButton1Click, function()
	local cb = setclipboard or toclipboard
	if cb and pcall(cb, U.snapshot()) then notify("success", "Copied", "Debug info is in your clipboard.") else notify("warn", "Copy", "See AxiomHUB/ouwland_log.txt") end
end)
connect(UI.logBtns.Clear.MouseButton1Click, function()
	for _, c in ipairs(UI.logScroll:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
end)

task.spawn(function()
	local lastStatus = ""
	local slow = 0
	while alive do
		local f = Farms.active
		local farming = f ~= nil
		local stText = farming and (C.status ~= "" and C.status or "…") or "Nothing is on — pick a farm"
		if E.flyStatus and E.moving then stText = stText .. "  ·  " .. E.flyStatus end
		status.Text = (farming and '<font color="#6ee39a">●</font>' or '<font color="#7c8070">●</font>') .. "  " .. (farming and f.name or "Idle") .. "   " .. U.regionName()
		tween(UI.logDot, {BackgroundColor3 = farming and Color3.fromRGB(110, 227, 154) or T.Accent}, 0.3)
		UI.badge.Text = farming and U.C("#6ee39a", f.name) or U.C("#7c8070", "Idle")
		UI.note.Text = stText
		local V = UI.tiles
		V.farm.Text = farming and f.name or "-"
		local t = E.target
		if t and t.root.Parent and t.hum.Health > 0 then
			local thp = t.hum.Health / math.max(t.hum.MaxHealth, 1) * 100
			V.target.Text = U.C(U.pctColor(thp), string.format("%d%%", thp)) .. " " .. t.name
		else V.target.Text = U.C("#7c8070", "none") end
		local hum = getHum()
		local hp = hum and hum.Health / math.max(hum.MaxHealth, 1) * 100 or 0
		V.hp.Text = U.C(U.pctColor(hp), string.format("%d%%", hp))
		V.region.Text = U.regionName()
		local q = Q.activeByCategory("BossHunt") or Q.activeByCategory("Combat")
		if q then
			local tk = q.tasks[1]
			V.quest.Text = tk and (tk.value .. "/" .. tk.max .. " " .. q.name) or q.name
		else V.quest.Text = U.C("#7c8070", "none") end
		V.time.Text = UI.sessionTime()
		local wenGain = (dbg.wen or 0) - (dbg.startWen or dbg.wen or 0)
		V.wen.Text = (wenGain >= 0 and "+" or "") .. fmtNum(wenGain)
		local repGain = (dbg.rep or 0) - (dbg.startRep or dbg.rep or 0)
		V.rep.Text = (repGain > 0 and "+" or "") .. fmtNum(repGain)
		V.kills.Text = tostring(dbg.kills)
		V.bosses.Text = tostring(dbg.bosses)
		V.quests.Text = tostring(dbg.quests)
		V.loot.Text = tostring(dbg.loot)
		V.deaths.Text = dbg.deaths > 0 and U.C("#ff7a6e", tostring(dbg.deaths)) or "0"
		local ping = math.floor((select(2, pcall(function() return player:GetNetworkPing() end)) or 0) * 1000)
		V.ping.Text = U.C(ping < 150 and "#6ee39a" or ping < 300 and "#ffd75c" or "#ff7a6e", ping .. " ms")
		V.fps.Text = tostring(math.floor(dbg.fps))
		Overlay.update({Ore = fmtNum(dbg.ore or 0), Wen = fmtNum(dbg.wen or 0), Level = tostring(dbg.level or "-"), Kills = tostring(dbg.kills), Rep = fmtNum(dbg.rep or 0), Session = UI.sessionTime()})
		if Overlay.sub then Overlay.sub.Text = "RENDERING PAUSED  ·  " .. string.upper(farming and f.name or "IDLE") end
		if farming and C.status ~= lastStatus then
			lastStatus = C.status
			if not (C.status:find("^fighting") or C.status:find("· ") and C.status:find("/")) and C.status ~= "" and not C.status:find("^healing") then
				dlog(C.status:find("flying") and "move" or "info", C.status)
			end
		end
		slow += 1
		if slow % 3 == 1 then
			local lines = {}
			for _, h in ipairs(B.hunts()) do
				if h.boss then
					local col = h.eligible and (Q.state(h.quest) == "Doing" and "#6ee39a" or "#eaece2") or "#7c8070"
					table.insert(lines, U.C(col, string.format("%s · %s · %dm", h.boss, tostring(h.tier), math.max(0, h.left) // 60)))
				end
			end
			UI.huntList.Text = #lines > 0 and table.concat(lines, "\n") or "No hunts posted right now."
			local cands = Q.candidates()
			local wl, names = {}, {"Auto (best Wen/hour)"}
			for i, cnd in ipairs(cands) do
				if i <= 5 then table.insert(wl, string.format("%s  ·  <b>%s</b>/h", cnd.name, fmtNum(cnd.rate))) end
				table.insert(names, cnd.name .. " · " .. fmtNum(cnd.wen) .. " Wen")
			end
			UI.wenList.Text = #wl > 0 and table.concat(wl, "\n") or "No kill quests for your level/race."
			local dq, sq = Q.candidates("Demon")[1], Q.candidates("Slayer")[1]
			UI.demonNote.Text = isDemonSide() and (dq and ("Best: " .. dq.name .. " · " .. fmtNum(dq.wen) .. " Wen") or "No demon quests fit.") or "You are not a demon."
			UI.slayerNote.Text = isSlayerSide() and (sq and ("Best: " .. sq.name .. " · " .. fmtNum(sq.wen) .. " Wen") or "No slayer quests fit.") or "You are not a slayer."
			local aq = {}
			for _, x in ipairs(Q.active()) do
				local tk = x.tasks[1]
				table.insert(aq, string.format("<b>%s</b> · %s%s", x.name, x.category, tk and (" · " .. tk.value .. "/" .. tk.max) or ""))
			end
			UI.activeQuests.Text = #aq > 0 and table.concat(aq, "\n") or "No quests right now."
			local g = F.levelGroup()
			UI.levelNote.Text = g and ("Level " .. tostring(dbg.level or "?") .. " → <b>" .. g.name .. "</b> (" .. g.region .. ")") or "No mobs for your level."
			local rg, _, dir = F.repTarget()
			UI.repNote.Text = rg and (dir .. " on <b>" .. rg.name .. "</b> (" .. rg.region .. ")") or ""
			local wb = {}
			for name, st in pairs(B.worldState) do
				if os.clock() < st then table.insert(wb, name .. " back in " .. math.floor(st - os.clock()) .. "s") end
			end
			UI.worldBossNote.Text = #wb > 0 and table.concat(wb, "\n") or "Pick bosses above; respawn timers show here."
			local d = getData()
			local item = Options.MasteryItem.Value
			local nm = type(item) == "string" and item:match("^%d · (.+)$")
			local mp = d and nm and d.MasteryProgressionList:FindFirstChild(nm)
			UI.masteryNote.Text = mp and string.format("%s mastery: <b>%s / %s</b>", nm, fmtNum(mp.Current.Value), fmtNum(mp.Goal.Value)) or "Pick a weapon from your toolbar."
		end
		while #logQueue > 0 do UI.drawLog(table.remove(logQueue, 1)) end
		task.wait(0.5)
	end
end)

do
	local saved = {}
	Options.LowGfx.Callback = function(on)
		local L = game:GetService("Lighting")
		if on then
			saved.shadows = L.GlobalShadows
			pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
			L.GlobalShadows = false
			for _, d in ipairs(workspace:GetDescendants()) do
				if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") then d.Enabled = false end
			end
			for _, e in ipairs(L:GetChildren()) do
				if e:IsA("PostEffect") then e.Enabled = false end
			end
		else
			if saved.shadows ~= nil then L.GlobalShadows = saved.shadows end
			pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
			for _, e in ipairs(L:GetChildren()) do
				if e:IsA("PostEffect") then e.Enabled = true end
			end
		end
	end
end

local visible = true
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
topButton(top, "–", -42, function() setVisible(false) notify("info", "Window hidden", "Press End to bring it back.") end)
topButton(top, "×", -12, function() app.Destroy() end)
connect(UIS.InputBegan, function(i, gpe)
	if not gpe and i.KeyCode == Enum.KeyCode.End then setVisible(not visible) end
end)
do
	local fb = make("TextButton", {
		Parent = gui, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 18, 0.5, 0), Size = UDim2.fromOffset(52, 52),
		BackgroundColor3 = Color3.fromRGB(22, 24, 18), BackgroundTransparency = 0.02, AutoButtonColor = false, Text = "", ZIndex = 20,
	}, {corner(12)})
	UI.floatButton = fb
	local fs = make("UIStroke", {Parent = fb, Thickness = 1.5, Transparency = 0.45, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
	accent(fs, "Color")
	app.drawMark(fb, 40, 21)
	local sc = make("UIScale", {Parent = fb})
	connect(fb.MouseEnter, function() tween(sc, {Scale = 1.08}, 0.2, Enum.EasingStyle.Back) end)
	connect(fb.MouseLeave, function() tween(sc, {Scale = 1}, 0.2) end)
	local downPos, startPos, dragging
	connect(fb.InputBegan, function(i)
		if i.UserInputType == MB1 or i.UserInputType == TOUCH then downPos, startPos, dragging = i.Position, fb.Position, false end
	end)
	connect(UIS.InputChanged, function(i)
		if downPos and (i.UserInputType == MOVE or i.UserInputType == TOUCH) then
			local d = i.Position - downPos
			if d.Magnitude > 6 then dragging = true end
			if dragging then fb.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y) end
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
	alive = false
	E.aimOn = false
	E.restoreAim()
	E.blockWanted = false
	if M.InputHandler and env.__AxiomOwOrigIsDown then M.InputHandler.IsDown = env.__AxiomOwOrigIsDown end
	if M.RunHandler and env.__AxiomOwOrigShiftLock then M.RunHandler.SetShiftLock = env.__AxiomOwOrigShiftLock end
	if M.SignalFunction and env.__AxiomOwOrigSF then M.SignalFunction.ToServer = env.__AxiomOwOrigSF end
	pcall(function() for _, f in ipairs(Farms.list) do if f.cleanup then f.cleanup() end end end)
	E.stopMoving()
	Overlay.set(false)
	if UI.cleanups then for _, fn in ipairs(UI.cleanups) do pcall(fn) end end
	for _, c in ipairs(app.connections) do pcall(function() c:Disconnect() end) end
	if gui.Parent then
		tween(mainScale, {Scale = 0.9}, 0.15)
		task.delay(0.15, function() gui:Destroy() end)
	end
	if env.__AxiomOuwland == app then env.__AxiomOuwland = nil end
end

do
	local loadedAuto = false
	pcall(function()
		local auto = UI.getAutoload and UI.getAutoload() or nil
		local file = auto and (UI.CFG_DIR .. "/" .. auto .. ".json")
		if file and isfile(file) then
			local data = HttpService:JSONDecode(readfile(file))
			if type(data) == "table" then applyData(data) loadedAuto = true end
		end
	end)
	if not loadedAuto and canFiles and isfile(LAST_FILE) then
		local ok, data = pcall(function() return HttpService:JSONDecode(readfile(LAST_FILE)) end)
		if ok and type(data) == "table" then applyData(data) end
	end
	loading = false
	if (tonumber(Options.CfgVer.Value) or 0) < 2 then
		Options.FlySpeed:SetValue(34, true)
		Options.HorseSpeed:SetValue(50, true)
		Options.HorseMinDist:SetValue(80, true)
		Options.UseHorse:SetValue(true, true)
		Options.CfgVer:SetValue(2, true)
	end
	if (tonumber(Options.CfgVer.Value) or 0) < 3 then
		Options.HoverSpeed:SetValue(16, true)
		Options.EngageDist:SetValue(14, true)
		Options.CfgVer:SetValue(3, true)
	end
	if (tonumber(Options.CfgVer.Value) or 0) < 4 then
		Options.HoverSpeed:SetValue(22, true)
		Options.WalkDashGap:SetValue(1, true)
		Options.WalkRun:SetValue(true, true)
		Options.CfgVer:SetValue(4, true)
	end
	if (tonumber(Options.CfgVer.Value) or 0) < 5 then
		Options.BlockHold:SetValue(0.6, true)
		Options.CfgVer:SetValue(5, true)
	end
	for k, v in pairs(AXIOM_CONFIG or {}) do
		if Options[k] and type(v) == type(Options[k].Value) then pcall(Options[k].SetValue, Options[k], v, true) end
	end
	UI.floatButton.Visible = Options.ShowFloatButton.Value
	if Options.SunImmunity.Value then E.setSunImmunity(true) end
	if Options.NoRender.Value then Overlay.set(true) end
	if Options.FPSCapOn.Value and setfpscap then pcall(setfpscap, Options.FPSCap.Value) end
	if Options.LowGfx.Value then task.spawn(Options.LowGfx.Callback, true) end
	for _, f in ipairs(Farms.list) do
		if f.flag and Options[f.flag] and Options[f.flag].Value then dlog("farm", f.name .. " is on from your config") end
	end
end

app.Options = Options
app.Debug = {E = E, C = C, Q = Q, B = B, W = W, F = F, M = M, UI = UI, Farms = Farms, dbg = dbg, snapshot = U.snapshot, log = dlog}
dlog("info", APP_NAME .. " Ouwland loaded · level " .. tostring(playerLevel()) .. " " .. playerRace())
selectTab(tabs[1])

main.Visible = false
UI.floatButton.Visible = false
local function showMain()
	main.Visible = true
	mainScale.Scale = 0.85
	tween(mainScale, {Scale = 1}, 0.45, Enum.EasingStyle.Back)
	UI.floatButton.Visible = Options.ShowFloatButton.Value
	UI.homeCard.Position = UDim2.fromOffset(0, 14)
	tween(UI.homeCard, {Position = UDim2.fromOffset(0, 0)}, 0.5, Enum.EasingStyle.Back)
end
if Options.SkipIntro.Value then
	showMain()
else
	task.spawn(function()
		local Lighting = game:GetService("Lighting")
		local blur = Instance.new("BlurEffect")
		blur.Size = 0
		blur.Parent = Lighting
		local dim = make("Frame", {Parent = gui, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, ZIndex = 29})
		local cardF = make("Frame", {Parent = gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(640, 360),
			BackgroundColor3 = Color3.fromRGB(18, 19, 16), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 30}, {corner(16)})
		local cScale = make("UIScale", {Parent = cardF, Scale = 0.9})
		local cStroke = make("UIStroke", {Parent = cardF, Thickness = 1.5, Transparency = 1})
		accent(cStroke, "Color")
		local fades = {}
		local lattice = make("Frame", {Parent = cardF, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromScale(0.62, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 30}, {
			make("UIGradient", {Transparency = NumberSequence.new(1, 0)}),
		})
		for i = -3, 12 do
			for _, rot in ipairs({35, -35}) do
				table.insert(fades, {accent(make("Frame", {Parent = lattice, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, i * 40, 0.5, 0), Size = UDim2.fromOffset(1, 520),
					Rotation = rot, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 30}), "BackgroundColor3"), "BackgroundTransparency", 0.9})
			end
		end
		for _, cc in ipairs({{0, 0}, {1, 0}, {0, 1}, {1, 1}}) do
			local ax, ay = cc[1], cc[2]
			local sx, sy = ax == 0 and 1 or -1, ay == 0 and 1 or -1
			table.insert(fades, {accent(make("Frame", {Parent = cardF, AnchorPoint = Vector2.new(ax, ay), Position = UDim2.new(ax, sx * 16, ay, sy * 16), Size = UDim2.fromOffset(24, 2), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 31}), "BackgroundColor3"), "BackgroundTransparency", 0.1})
			table.insert(fades, {accent(make("Frame", {Parent = cardF, AnchorPoint = Vector2.new(ax, ay), Position = UDim2.new(ax, sx * 16, ay, sy * 16), Size = UDim2.fromOffset(2, 24), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 31}), "BackgroundColor3"), "BackgroundTransparency", 0.1})
		end
		local markBox = make("Frame", {Parent = cardF, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.47), Size = UDim2.fromOffset(150, 150), BackgroundTransparency = 1, ZIndex = 31})
		local mk = app.drawMark(markBox, 150, 32)
		mk.scale.Scale = 0.3
		mk.outerStroke.Transparency, mk.innerStroke.Transparency = 1, 1
		for _, f in ipairs(mk.fills) do f.BackgroundTransparency = 1 end
		local pulse = make("Frame", {Parent = markBox, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(60, 60), Rotation = 45, BackgroundTransparency = 1, ZIndex = 31})
		local pulseStroke = make("UIStroke", {Parent = pulse, Thickness = 2, Transparency = 1})
		accent(pulseStroke, "Color")
		local tbox = make("Frame", {Parent = cardF, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 262, 0.47, 0), Size = UDim2.fromOffset(340, 110), BackgroundTransparency = 1, ZIndex = 31})
		local title = label({Parent = tbox, Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 58), Text = "", RichText = true, Font = FONT_B, TextSize = 54, ZIndex = 32})
		local line = make("Frame", {Parent = tbox, Position = UDim2.fromOffset(2, 80), Size = UDim2.fromOffset(0, 2), BorderSizePixel = 0, ZIndex = 32})
		accent(line, "BackgroundColor3")
		local tag = label({Parent = tbox, Position = UDim2.fromOffset(52, 72), Size = UDim2.new(1, -52, 0, 18), Text = "", Font = Enum.Font.Code, TextSize = 13, TextColor3 = Color3.fromRGB(169, 173, 156), ZIndex = 32})
		local bar = make("Frame", {Parent = cardF, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -34), Size = UDim2.fromOffset(220, 3), BackgroundColor3 = T.Off, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 31}, {corner(2)})
		local fill = make("Frame", {Parent = bar, Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, ZIndex = 32}, {corner(2)})
		accent(fill, "BackgroundColor3")
		local step = label({Parent = cardF, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.fromOffset(300, 14), Text = "", Font = FONT, TextSize = 11, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 31})
		local spin = RunService.RenderStepped:Connect(function(dt)
			mk.outer.Rotation = (mk.outer.Rotation + dt * 40) % 360
			mk.inner.Rotation = (mk.inner.Rotation - dt * 28) % 360
		end)
		tween(blur, {Size = 14}, 0.5)
		tween(dim, {BackgroundTransparency = 0.45}, 0.5)
		tween(cardF, {BackgroundTransparency = 0.02}, 0.4)
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
		local tagline = "OUWLAND  ·  BY " .. string.upper(AUTHOR)
		for i = 1, #tagline do
			tag.Text = tagline:sub(1, i)
			task.wait(0.018)
		end
		tween(bar, {BackgroundTransparency = 0.3}, 0.3)
		local steps = {"Reading the world…", "Hooking silent aim…", "Loading quests & bosses…", "Ready"}
		for i, txt in ipairs(steps) do
			step.Text = txt
			tween(fill, {Size = UDim2.fromScale(i / #steps, 1)}, 0.28)
			task.wait(0.3)
		end
		task.wait(0.35)
		tween(cScale, {Scale = 1.06}, 0.35)
		for _, o in ipairs(cardF:GetDescendants()) do
			if o:IsA("TextLabel") then tween(o, {TextTransparency = 1}, 0.3)
			elseif o:IsA("Frame") then tween(o, {BackgroundTransparency = 1}, 0.3)
			elseif o:IsA("UIStroke") then tween(o, {Transparency = 1}, 0.3) end
		end
		tween(cardF, {BackgroundTransparency = 1}, 0.35)
		tween(dim, {BackgroundTransparency = 1}, 0.45)
		tween(blur, {Size = 0}, 0.45)
		task.wait(0.15)
		showMain()
		task.wait(0.35)
		spin:Disconnect()
		cardF:Destroy()
		dim:Destroy()
		blur:Destroy()
	end)
end
notify("success", APP_NAME .. " · Ouwland", "Welcome, " .. player.DisplayName .. ". Press End to toggle.")

end
runHub()

end

if game.PlaceId == OUWIGAHARA_PLACE then AxiomOuwigahara()
elseif game.PlaceId == MM2_PLACE then AxiomMM2()
elseif game.PlaceId == OUWLAND_PLACE then AxiomOuwland()
else AxiomMenu() end
