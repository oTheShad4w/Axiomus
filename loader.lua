local DATA_URL = "https://raw.githubusercontent.com/oTheShad4w/Axiomus/main/AxiomHUB.dat"
local ASSET_URL = "https://raw.githubusercontent.com/oTheShad4w/Axiomus/main/assets/"
local DISCORD = ""
local KEY_FILE = "AxiomHUB/key.txt"

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer

local E = {{3736738291,3525837038,1923790262,3181152228,3782252785},{421195296,2075637157,3744794577,335752371,1290734122},{2073533308,3115072913,489590557,3524834663,2465506958},{2966045332,1119845657,3829256069,755758303,2078795062},{3515627358,2514098915,895014235,4201571109,2793587200},{1906366003,4196028462,1519969398,2511263524,3376605361},{2034502785,894494452,2480035208,1524918070,67649871},{4256498710,1182985739,3825228067,758542205,2010797608},{1191067307,1644404022,3263242910,230102076,1364931993},{159267697,3422273732,2440658840,1481591238,44264287},{2513033315,2211869118,626312710,3965907124,2995702017},{3215653163,1656852406,3259184158,225773244,1368991513},{2573179016,2259238141,539725481,3911039995,2951844322},{38989329,1964696868,3549975352,447637094,1145192511},{2046172210,212005495,2854243823,1662417585,905598588},{3433659580,3941666769,1282650589,2235926183,3819550542},{2319553488,3370422197,1785082337,2739930947,4189856826},{358077064,271623933,2998069417,2072305147,560528354},{975365970,2068340823,3284851471,150792529,1276167260},{539864606,3405882019,2474843803,1488268261,72944192},{1416805852,2558108849,989533949,4090354759,2971733422},{1284168829,603433184,2306147956,1078145322,313458883},{1875599156,2532751609,812911269,4181868543,2813206550},{1040121610,1094777983,3921835991,787774633,1914196068},{378911894,1519435403,3759278755,690241533,1942497192}}

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
	return ok and type(v) == "string" and v:gsub("%s", "") ~= "" and v:gsub("%s", "") or nil
end
local function save(key)
	pcall(function()
		if makefolder and not isfolder("AxiomHUB") then makefolder("AxiomHUB") end
		writefile(KEY_FILE, key)
	end)
end
local function forget()
	pcall(function() if isfile(KEY_FILE) then delfile(KEY_FILE) end end)
end

local function hwid()
	local ok, h = pcall(function() return gethwid and gethwid() end)
	if ok and type(h) == "string" and #h > 4 then return h end
	local ok2, c = pcall(function() return game:GetService("RbxAnalyticsService"):GetClientId() end)
	if ok2 and type(c) == "string" and #c > 4 then return c end
	return "uid-" .. tostring(player.UserId)
end

local function check(key)
	local m = unwrap(key)
	if not m then return nil, "Invalid key", "invalid" end
	return {ok = true, plan = "life", planName = "Lifetime", exp = 0, now = os.time(), m = m}
end

local ACCENT = Color3.fromRGB(124, 92, 255)
local ACCENT2 = Color3.fromRGB(190, 120, 255)
local BG = Color3.fromRGB(13, 12, 18)
local PANEL = Color3.fromRGB(20, 18, 28)
local EL = Color3.fromRGB(26, 24, 36)
local LINE = Color3.fromRGB(52, 48, 70)
local TXT = Color3.fromRGB(236, 234, 245)
local SUB = Color3.fromRGB(150, 145, 170)
local RED = Color3.fromRGB(255, 105, 115)
local GREEN = Color3.fromRGB(110, 230, 160)
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
local function asset(name)
	if not (getcustomasset and writefile and isfile) then return nil end
	local path = "AxiomHUB/" .. name
	if not isfile(path) then
		local ok, data = pcall(function() return game:HttpGet(ASSET_URL .. name) end)
		if not ok or type(data) ~= "string" or #data < 1000 then return nil end
		pcall(makefolder, "AxiomHUB")
		pcall(writefile, path, data)
	end
	local ok, id = pcall(getcustomasset, path)
	return ok and id or nil
end

local parent = (gethui and gethui()) or game:GetService("CoreGui")
pcall(function() local old = parent:FindFirstChild("AxiomKey") if old then old:Destroy() end end)
pcall(function() for _, b in ipairs(Lighting:GetChildren()) do if b.Name == "AxiomKeyBlur" then b:Destroy() end end end)
local gui = make("ScreenGui", {Name = "AxiomKey", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999, Parent = parent})
local blur = make("BlurEffect", {Name = "AxiomKeyBlur", Size = 0, Parent = Lighting})
tw(blur, {Size = 14}, 0.6)
local fade = make("Frame", {Parent = gui, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0})
tw(fade, {BackgroundTransparency = 0.5}, 0.5)

local W, H = 400, 330
local card = make("CanvasGroup", {Parent = gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromOffset(W, H), BackgroundColor3 = BG, GroupTransparency = 1, BorderSizePixel = 0}, {corner(16)})
local scale = make("UIScale", {Parent = card, Scale = 0.94})
local outline = make("Frame", {Parent = gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = card.Position, Size = card.Size, BackgroundTransparency = 1}, {corner(16)})
local ostroke = make("UIStroke", {Parent = outline, Color = Color3.new(1, 1, 1), Thickness = 1.4, Transparency = 1})
local ograd = make("UIGradient", {Parent = ostroke, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, ACCENT), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 36, 60)), ColorSequenceKeypoint.new(1, ACCENT2)})})
local oscale = make("UIScale", {Parent = outline, Scale = 0.94})
task.spawn(function() while gui.Parent do ograd.Rotation = (ograd.Rotation + 1.5) % 360 task.wait() end end)
tw(card, {Position = UDim2.fromScale(0.5, 0.5), GroupTransparency = 0}, 0.6, Enum.EasingStyle.Quint)
tw(outline, {Position = UDim2.fromScale(0.5, 0.5)}, 0.6, Enum.EasingStyle.Quint)
tw(scale, {Scale = 1}, 0.6, Enum.EasingStyle.Back)
tw(oscale, {Scale = 1}, 0.6, Enum.EasingStyle.Back)
tw(ostroke, {Transparency = 0.15}, 0.6)

local X = 26
local mark = make("Frame", {Parent = card, Position = UDim2.fromOffset(X + 4, 34), Size = UDim2.fromOffset(22, 22), Rotation = 45, BackgroundColor3 = ACCENT}, {corner(5)})
make("Frame", {Parent = mark, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(8, 8), BackgroundColor3 = BG}, {corner(2)})
make("TextLabel", {Parent = card, Position = UDim2.fromOffset(X + 38, 30), Size = UDim2.fromOffset(240, 30), BackgroundTransparency = 1, RichText = true, Text = 'Axiom<font color="#9C7CFF">HUB</font>', FontFace = FONT_B, TextSize = 24, TextColor3 = TXT, TextXAlignment = Enum.TextXAlignment.Left})
local subtitle = make("TextLabel", {Parent = card, Position = UDim2.fromOffset(X, 72), Size = UDim2.fromOffset(W - X - 26, 18), BackgroundTransparency = 1, Text = "Enter your key to continue", FontFace = FONT, TextSize = 13, TextColor3 = SUB, TextXAlignment = Enum.TextXAlignment.Left})

local field = make("Frame", {Parent = card, Position = UDim2.fromOffset(X, 104), Size = UDim2.fromOffset(W - X - 26, 46), BackgroundColor3 = EL, BorderSizePixel = 0}, {corner(10)})
local fstroke = make("UIStroke", {Parent = field, Color = LINE, Thickness = 1.2})
local kr = make("Frame", {Parent = field, Position = UDim2.fromOffset(15, 17), Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1}, {make("UICorner", {CornerRadius = UDim.new(1, 0)})})
local krs = make("UIStroke", {Parent = kr, Color = SUB, Thickness = 2})
local kb = make("Frame", {Parent = field, Position = UDim2.fromOffset(24, 21), Size = UDim2.fromOffset(10, 2), BackgroundColor3 = SUB, BorderSizePixel = 0})
local kt = make("Frame", {Parent = field, Position = UDim2.fromOffset(31, 21), Size = UDim2.fromOffset(2, 6), BackgroundColor3 = SUB, BorderSizePixel = 0})
local box = make("TextBox", {Parent = field, Position = UDim2.fromOffset(44, 0), Size = UDim2.new(1, -54, 1, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = "AXM-XXXX-XXXX-XXXX", PlaceholderColor3 = Color3.fromRGB(95, 90, 115), TextColor3 = TXT, FontFace = FONT_B, TextSize = 15, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left})
local function fieldColor(c)
	tw(fstroke, {Color = c}, 0.2) tw(krs, {Color = c}, 0.2) tw(kb, {BackgroundColor3 = c}, 0.2) tw(kt, {BackgroundColor3 = c}, 0.2)
end
box.Focused:Connect(function() fieldColor(ACCENT) end)
box.FocusLost:Connect(function() fieldColor(LINE) krs.Color = SUB kb.BackgroundColor3 = SUB kt.BackgroundColor3 = SUB end)

local btn = make("TextButton", {Parent = card, Position = UDim2.fromOffset(X, 162), Size = UDim2.fromOffset(W - X - 26, 44), BackgroundColor3 = Color3.new(1, 1, 1), Text = "", AutoButtonColor = false, BorderSizePixel = 0, ClipsDescendants = true}, {corner(10)})
make("UIGradient", {Parent = btn, Color = ColorSequence.new(ACCENT, ACCENT2)})
local btnText = make("TextLabel", {Parent = btn, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "Unlock", FontFace = FONT_B, TextSize = 15, TextColor3 = Color3.new(1, 1, 1), ZIndex = 3})
local shine = make("Frame", {Parent = btn, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 2})
local sg = make("UIGradient", {Parent = shine, Rotation = 20, Offset = Vector2.new(-1, 0), Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.42, 1), NumberSequenceKeypoint.new(0.5, 0.55), NumberSequenceKeypoint.new(0.58, 1), NumberSequenceKeypoint.new(1, 1)})})
task.spawn(function()
	while gui.Parent do
		sg.Offset = Vector2.new(-1, 0)
		tw(sg, {Offset = Vector2.new(1, 0)}, 1.2, Enum.EasingStyle.Sine)
		task.wait(3.2)
	end
end)
local bscale = make("UIScale", {Parent = btn})
btn.MouseEnter:Connect(function() tw(bscale, {Scale = 1.02}, 0.2) end)
btn.MouseLeave:Connect(function() tw(bscale, {Scale = 1}, 0.2) end)

local getBtn = make("TextButton", {Parent = card, Position = UDim2.fromOffset(X, 216), Size = UDim2.fromOffset(W - X - 26, 36), BackgroundColor3 = EL, BackgroundTransparency = 0.4, Text = "Get a key on Discord", FontFace = FONT_B, TextSize = 13, TextColor3 = SUB, AutoButtonColor = false, BorderSizePixel = 0}, {corner(10)})
local gstroke = make("UIStroke", {Parent = getBtn, Color = LINE, Thickness = 1})
if DISCORD == "" then getBtn.Visible = false end
getBtn.MouseEnter:Connect(function() tw(gstroke, {Color = ACCENT}, 0.2) tw(getBtn, {TextColor3 = TXT}, 0.2) end)
getBtn.MouseLeave:Connect(function() tw(gstroke, {Color = LINE}, 0.2) tw(getBtn, {TextColor3 = SUB}, 0.2) end)

local barBg = make("Frame", {Parent = card, Position = UDim2.fromOffset(X, 268), Size = UDim2.fromOffset(W - X - 26, 3), BackgroundColor3 = EL, BorderSizePixel = 0}, {corner(2)})
local bar = make("Frame", {Parent = barBg, Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, {corner(2)})
make("UIGradient", {Parent = bar, Color = ColorSequence.new(ACCENT, ACCENT2)})
local status = make("TextLabel", {Parent = card, Position = UDim2.fromOffset(X, 278), Size = UDim2.fromOffset(W - X - 26, 18), BackgroundTransparency = 1, Text = "", FontFace = FONT, TextSize = 12, TextColor3 = SUB, TextXAlignment = Enum.TextXAlignment.Left})
make("TextLabel", {Parent = card, Position = UDim2.new(0, X, 1, -30), Size = UDim2.fromOffset(W - X - 26, 16), BackgroundTransparency = 1, Text = "by kingping77", FontFace = FONT, TextSize = 11, TextColor3 = Color3.fromRGB(80, 76, 100), TextXAlignment = Enum.TextXAlignment.Right})

if DISCORD == "" then
	barBg.Position = UDim2.fromOffset(X, 224)
	status.Position = UDim2.fromOffset(X, 234)
	card.Size = UDim2.fromOffset(W, 290)
	outline.Size = card.Size
end
local closeBtn = make("TextButton", {Parent = card, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromOffset(W - 8, 8), Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1, Text = "×", FontFace = FONT_B, TextSize = 18, TextColor3 = SUB})

local function say(text, color)
	status.Text = text
	status.TextColor3 = color or SUB
end
local function shake()
	fieldColor(RED)
	local p = card.Position
	for _, dx in ipairs({-10, 10, -6, 6, -2, 0}) do
		card.Position = p + UDim2.fromOffset(dx, 0)
		outline.Position = card.Position
		task.wait(0.04)
	end
	task.delay(0.8, function() if not box:IsFocused() then fieldColor(LINE) end end)
end

local function closeUI(instant)
	tw(blur, {Size = 0}, 0.35)
	tw(fade, {BackgroundTransparency = 1}, 0.35)
	tw(card, {GroupTransparency = 1, Position = UDim2.fromScale(0.5, 0.46)}, 0.35)
	tw(ostroke, {Transparency = 1}, 0.3)
	task.delay(instant and 0 or 0.4, function() gui:Destroy() blur:Destroy() end)
end
closeBtn.MouseButton1Click:Connect(function() closeUI() end)

getBtn.MouseButton1Click:Connect(function()
	if setclipboard then pcall(setclipboard, DISCORD) say("Discord invite copied, paste it in your browser", GREEN)
	else say(DISCORD, TXT) end
end)

local function start(m)
	say("Downloading…")
	local okH, hex = pcall(function() return game:HttpGet(DATA_URL .. "?t=" .. tostring(os.time()) .. tostring(math.random(1000, 9999))) end)
	if not okH or type(hex) ~= "string" or #hex < 100 then say("Couldn't download the script", RED) return false end
	say("Unlocking…")
	local src = decrypt(hex, m, function(p) bar.Size = UDim2.fromScale(p, 1) end)
	local fn, err = loadstring(src)
	if not fn then say("Bad build: " .. tostring(err):sub(1, 60), RED) return false end
	bar.Size = UDim2.fromScale(1, 1)
	say("Welcome back", GREEN)
	task.wait(0.35)
	closeUI()
	task.spawn(fn)
	return true
end

local DIRECT = {[4588604953] = true, [8343259840] = true, [15169303036] = true, [15169306359] = true, [15169310267] = true, [15169316384] = true, [142823291] = true}
local DIRECT_GAMES = {[1494262959] = true}
local function choose(m)
	if DIRECT[game.PlaceId] or DIRECT_GAMES[game.GameId] then start(m) return end
	for _, o in ipairs({field, btn, getBtn}) do o.Visible = false end
	subtitle.Text = "Pick your version"
	local picked = false
	local function option(i, title, desc, mode)
		local bw = (W - X - 26 - 12) / 2
		local b = make("TextButton", {Parent = card, Position = UDim2.fromOffset(X + (i - 1) * (bw + 12), 104), Size = UDim2.fromOffset(bw, 148), BackgroundColor3 = EL, Text = "", AutoButtonColor = false}, {corner(12)})
		local st = make("UIStroke", {Parent = b, Color = LINE, Thickness = 1.2})
		make("TextLabel", {Parent = b, Position = UDim2.fromOffset(14, 16), Size = UDim2.new(1, -28, 0, 20), BackgroundTransparency = 1, Text = title, FontFace = FONT_B, TextSize = 16, TextColor3 = TXT, TextXAlignment = Enum.TextXAlignment.Left})
		make("TextLabel", {Parent = b, Position = UDim2.fromOffset(14, 44), Size = UDim2.new(1, -28, 0, 90), BackgroundTransparency = 1, Text = desc, FontFace = FONT, TextSize = 12, TextColor3 = SUB, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top})
		b.MouseEnter:Connect(function() tw(st, {Color = ACCENT}, 0.15) end)
		b.MouseLeave:Connect(function() tw(st, {Color = LINE}, 0.15) end)
		b.MouseButton1Click:Connect(function()
			if picked then return end
			picked = true
			getgenv().AxiomUIMode = mode
			pcall(writefile, "AxiomHUB/version.txt", mode)
			start(m)
		end)
	end
	option(1, "Simple", "Turn it on and go. Best settings already set.", "Simple")
	option(2, "Advanced", "Every slider: cooldowns, priority, heal, block.", "Pro")
end

local busy = false
local function try(key, silent)
	if busy then return end
	key = tostring(key or ""):upper():gsub("%s", "")
	if key == "" then say("Paste your key first", RED) shake() return end
	busy = true
	btnText.Text = "Checking…"
	say("Checking your key…")
	local res, err, code = check(key)
	btnText.Text = "Unlock"
	if not res then
		busy = false
		if code then forget() end
		say(err, RED)
		if not silent then shake() end
		return
	end
	save(key)
	getgenv().AxiomKeyInfo = {key = key, plan = res.plan, planName = res.planName, exp = tonumber(res.exp) or 0, serverNow = tonumber(res.now) or os.time(), localNow = os.time()}
	fieldColor(GREEN)
	choose(res.m)
end
btn.MouseButton1Click:Connect(function() try(box.Text) end)
box.FocusLost:Connect(function(enter) if enter then try(box.Text) end end)

local saved = readSaved()
if saved then
	box.Text = saved
	task.delay(0.5, function() try(saved, true) end)
end
