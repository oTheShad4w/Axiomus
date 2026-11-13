local DATA_URL = "https://raw.githubusercontent.com/oTheShad4w/Axiomus/main/AxiomHUB.dat"
local KEY_FILE = "AxiomHUB/key.txt"
local E = {{3736738291,3525837038,1923790262,3181152228,3782252785},{421195296,2075637157,3744794577,335752371,1290734122},{2073533308,3115072913,489590557,3524834663,2465506958},{2966045332,1119845657,3829256069,755758303,2078795062},{3515627358,2514098915,895014235,4201571109,2793587200},{1906366003,4196028462,1519969398,2511263524,3376605361},{2034502785,894494452,2480035208,1524918070,67649871},{4256498710,1182985739,3825228067,758542205,2010797608},{1191067307,1644404022,3263242910,230102076,1364931993},{159267697,3422273732,2440658840,1481591238,44264287},{2513033315,2211869118,626312710,3965907124,2995702017},{3215653163,1656852406,3259184158,225773244,1368991513},{2573179016,2259238141,539725481,3911039995,2951844322},{38989329,1964696868,3549975352,447637094,1145192511},{2046172210,212005495,2854243823,1662417585,905598588},{3433659580,3941666769,1282650589,2235926183,3819550542},{2319553488,3370422197,1785082337,2739930947,4189856826},{358077064,271623933,2998069417,2072305147,560528354},{975365970,2068340823,3284851471,150792529,1276167260},{539864606,3405882019,2474843803,1488268261,72944192},{1416805852,2558108849,989533949,4090354759,2971733422},{1284168829,603433184,2306147956,1078145322,313458883},{1875599156,2532751609,812911269,4181868543,2813206550},{1040121610,1094777983,3921835991,787774633,1914196068},{378911894,1519435403,3759278755,690241533,1942497192}}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local function fnv(s)
	local h = 2166136261
	for i = 1, #s do
		h = bit32.bxor(h, string.byte(s, i))
		h = (bit32.lshift(h, 24) + h * 403) % 4294967296
	end
	return h
end

local function unwrap(key)
	key = (key or ""):upper():gsub("%s", "")
	local c = fnv(key .. "|check")
	for _, e in ipairs(E) do
		if e[1] == c then
			local m = {}
			for i = 1, 4 do m[i] = bit32.bxor(e[i + 1], fnv(key .. "|" .. i)) end
			return m, key
		end
	end
	return nil
end

local function decrypt(hex, m, progress)
	local n = #hex // 2
	local hb = buffer.fromstring(hex)
	local out = buffer.create(n)
	local lut = {}
	for i = 0, 9 do lut[48 + i] = i end
	for i = 0, 5 do lut[65 + i] = 10 + i lut[97 + i] = 10 + i end
	local x, y, z, w = m[1], m[2], m[3], m[4]
	for i = 0, n - 1 do
		local t = bit32.bxor(x, bit32.lshift(x, 11))
		x, y, z = y, z, w
		w = bit32.bxor(bit32.bxor(w, bit32.rshift(w, 19)), bit32.bxor(t, bit32.rshift(t, 8)))
		local b = lut[buffer.readu8(hb, i * 2)] * 16 + lut[buffer.readu8(hb, i * 2 + 1)]
		buffer.writeu8(out, i, bit32.bxor(b, bit32.band(w, 255)))
		if i % 60000 == 0 then
			if progress then progress(i / n) end
			task.wait()
		end
	end
	return buffer.tostring(out)
end

local function readSaved()
	local ok, v = pcall(function() return isfile and isfile(KEY_FILE) and readfile(KEY_FILE) end)
	return ok and type(v) == "string" and v or nil
end
local function save(key)
	pcall(function()
		if makefolder and not isfolder("AxiomHUB") then makefolder("AxiomHUB") end
		writefile(KEY_FILE, key)
	end)
end

local ACCENT = Color3.fromRGB(142, 154, 78)
local BG = Color3.fromRGB(16, 17, 14)
local EL = Color3.fromRGB(28, 30, 24)
local TXT = Color3.fromRGB(232, 234, 224)
local SUB = Color3.fromRGB(150, 155, 135)
local FONT = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
local FONT_B = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)

local function make(class, props, kids)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do if k ~= "Parent" then o[k] = v end end
	for _, k in ipairs(kids or {}) do k.Parent = o end
	if props and props.Parent then o.Parent = props.Parent end
	return o
end
local function corner(r) return make("UICorner", {CornerRadius = UDim.new(0, r)}) end
local function tw(o, p, t, s) local x = TweenService:Create(o, TweenInfo.new(t or 0.35, s or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), p) x:Play() return x end

local function run(m)
	local okH, hex = pcall(function() return game:HttpGet(DATA_URL .. "?t=" .. tostring(os.time()) .. tostring(math.random(1000, 9999))) end)
	if not okH or type(hex) ~= "string" or #hex < 100 then return false, "Couldn't download the script" end
	return true, hex
end

local function start(m, ui)
	if ui then ui.status.Text = "Downloading…" end
	local ok, hex = run(m)
	if not ok then if ui then ui.status.Text = hex ui.status.TextColor3 = Color3.fromRGB(255, 110, 100) end return false end
	if ui then ui.status.Text = "Unlocking…" end
	local src = decrypt(hex, m, function(p) if ui then ui.bar.Size = UDim2.fromScale(p, 1) end end)
	local fn, err = loadstring(src)
	if not fn then if ui then ui.status.Text = "Bad build: " .. tostring(err):sub(1, 60) end return false end
	if ui then
		ui.bar.Size = UDim2.fromScale(1, 1)
		tw(ui.card, {Position = UDim2.fromScale(0.5, 0.42)}, 0.35)
		tw(ui.fade, {BackgroundTransparency = 1}, 0.35)
		for _, d in ipairs(ui.gui:GetDescendants()) do
			if d:IsA("TextLabel") or d:IsA("TextBox") or d:IsA("TextButton") then tw(d, {TextTransparency = 1}, 0.3) end
			if d:IsA("Frame") or d:IsA("TextBox") or d:IsA("TextButton") then tw(d, {BackgroundTransparency = 1}, 0.3) end
			if d:IsA("UIStroke") then tw(d, {Transparency = 1}, 0.3) end
		end
		task.delay(0.4, function() ui.gui:Destroy() end)
	end
	task.spawn(fn)
	return true
end

local saved = readSaved()
local sm = saved and unwrap(saved)

local parent = (gethui and gethui()) or game:GetService("CoreGui")
local gui = make("ScreenGui", {Name = "AxiomKey", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999, Parent = parent})
local fade = make("Frame", {Parent = gui, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0})
tw(fade, {BackgroundTransparency = 0.45}, 0.5)
local card = make("Frame", {Parent = gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.56), Size = UDim2.fromOffset(380, 250), BackgroundColor3 = BG, BackgroundTransparency = 1}, {corner(14)})
local stroke = make("UIStroke", {Parent = card, Color = ACCENT, Transparency = 1, Thickness = 1.2})
local grad = make("UIGradient", {Parent = stroke, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 120, 120)), ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))})})
task.spawn(function() while gui.Parent do grad.Rotation = (grad.Rotation + 2) % 360 task.wait() end end)
tw(card, {Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 0}, 0.6, Enum.EasingStyle.Back)
tw(stroke, {Transparency = 0.25}, 0.6)

local mark = make("Frame", {Parent = card, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 22), Size = UDim2.fromOffset(34, 34), Rotation = 45, BackgroundColor3 = ACCENT}, {corner(6)})
make("Frame", {Parent = mark, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = BG}, {corner(3)})
task.spawn(function() while gui.Parent do tw(mark, {Rotation = mark.Rotation + 90}, 1.2) task.wait(2.4) end end)
make("TextLabel", {Parent = card, Position = UDim2.new(0, 0, 0, 66), Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, RichText = true, Text = 'Axiom<font color="#8E9A4E">HUB</font>', FontFace = FONT_B, TextSize = 24, TextColor3 = TXT})
make("TextLabel", {Parent = card, Position = UDim2.new(0, 0, 0, 94), Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = "Enter your key", FontFace = FONT, TextSize = 12, TextColor3 = SUB})
local box = make("TextBox", {Parent = card, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 122), Size = UDim2.new(1, -48, 0, 38), BackgroundColor3 = EL, Text = "", PlaceholderText = "AXM-XXXX-XXXX-XXXX", PlaceholderColor3 = SUB, TextColor3 = TXT, FontFace = FONT_B, TextSize = 14, ClearTextOnFocus = false}, {corner(8)})
local bs = make("UIStroke", {Parent = box, Color = Color3.fromRGB(60, 63, 52), Thickness = 1})
box.Focused:Connect(function() tw(bs, {Color = ACCENT}, 0.2) end)
box.FocusLost:Connect(function() tw(bs, {Color = Color3.fromRGB(60, 63, 52)}, 0.2) end)
local btn = make("TextButton", {Parent = card, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 170), Size = UDim2.new(1, -48, 0, 36), BackgroundColor3 = ACCENT, Text = "Unlock", FontFace = FONT_B, TextSize = 14, TextColor3 = BG, AutoButtonColor = false}, {corner(8)})
local barBg = make("Frame", {Parent = card, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 214), Size = UDim2.new(1, -48, 0, 3), BackgroundColor3 = EL, BorderSizePixel = 0}, {corner(2)})
local bar = make("Frame", {Parent = barBg, Size = UDim2.fromScale(0, 1), BackgroundColor3 = ACCENT, BorderSizePixel = 0}, {corner(2)})
local status = make("TextLabel", {Parent = card, Position = UDim2.new(0, 0, 0, 222), Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = "", FontFace = FONT, TextSize = 11, TextColor3 = SUB})
btn.MouseEnter:Connect(function() tw(btn, {BackgroundColor3 = ACCENT:Lerp(Color3.new(1, 1, 1), 0.15)}, 0.15) end)
btn.MouseLeave:Connect(function() tw(btn, {BackgroundColor3 = ACCENT}, 0.15) end)

local ui = {gui = gui, card = card, fade = fade, bar = bar, status = status}
local subtitle = card:FindFirstChildWhichIsA("TextLabel")
local DIRECT = {[4588604953] = true, [8343259840] = true, [142823291] = true}
local function choose(m)
	if DIRECT[game.PlaceId] then
		box.Visible, btn.Visible = false, false
		status.TextColor3 = ACCENT
		start(m, ui)
		return
	end
	tw(box, {BackgroundTransparency = 1, TextTransparency = 1}, 0.25)
	tw(bs, {Transparency = 1}, 0.25)
	tw(btn, {BackgroundTransparency = 1, TextTransparency = 1}, 0.25)
	task.wait(0.25)
	box.Visible, btn.Visible = false, false
	for _, l in ipairs(card:GetChildren()) do if l:IsA("TextLabel") and l.Text == "Enter your key" then l.Text = "Pick your version" end end
	local picked = false
	local function option(i, title, desc, mode)
		local b = make("TextButton", {Parent = card, Position = UDim2.new(0, 24 + (i - 1) * 172, 0, 122), Size = UDim2.fromOffset(160, 84), BackgroundColor3 = EL, Text = "", AutoButtonColor = false, BackgroundTransparency = 1}, {corner(10)})
		local st = make("UIStroke", {Parent = b, Color = Color3.fromRGB(60, 63, 52), Thickness = 1, Transparency = 1})
		local t1 = make("TextLabel", {Parent = b, Position = UDim2.fromOffset(12, 12), Size = UDim2.new(1, -24, 0, 20), BackgroundTransparency = 1, Text = title, FontFace = FONT_B, TextSize = 15, TextColor3 = TXT, TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1})
		local t2 = make("TextLabel", {Parent = b, Position = UDim2.fromOffset(12, 36), Size = UDim2.new(1, -24, 0, 40), BackgroundTransparency = 1, Text = desc, FontFace = FONT, TextSize = 11, TextColor3 = SUB, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextTransparency = 1})
		task.delay(0.05 * i, function()
			tw(b, {BackgroundTransparency = 0}, 0.35) tw(st, {Transparency = 0}, 0.35) tw(t1, {TextTransparency = 0}, 0.35) tw(t2, {TextTransparency = 0}, 0.35)
		end)
		b.MouseEnter:Connect(function() tw(st, {Color = ACCENT}, 0.15) end)
		b.MouseLeave:Connect(function() tw(st, {Color = Color3.fromRGB(60, 63, 52)}, 0.15) end)
		b.MouseButton1Click:Connect(function()
			if picked then return end
			picked = true
			getgenv().AxiomUIMode = mode
			pcall(writefile, "AxiomHUB/version.txt", mode)
			status.TextColor3 = ACCENT
			start(m, ui)
		end)
	end
	option(1, "Simple", "Turn it on and go. Best settings already set.", "Simple")
	option(2, "Advanced", "Every slider: cooldowns, priority, heal, block.", "Pro")
end
local busy = false
local function try()
	if busy then return end
	local m, key = unwrap(box.Text)
	if not m then
		status.TextColor3 = Color3.fromRGB(255, 110, 100)
		status.Text = "Wrong key"
		local p = card.Position
		for _, dx in ipairs({-10, 10, -6, 6, 0}) do tw(card, {Position = p + UDim2.fromOffset(dx, 0)}, 0.05) task.wait(0.05) end
		return
	end
	busy = true
	save(key)
	choose(m)
end
btn.MouseButton1Click:Connect(try)
box.FocusLost:Connect(function(enter) if enter then try() end end)
if sm then task.delay(0.5, function() busy = true choose(sm) end) end
