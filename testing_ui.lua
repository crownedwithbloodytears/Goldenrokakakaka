--[[
CustomLib_TopTabs (v4.0)

Новое в v4.0 (сверх v3.1):
- Flags + SaveConfig/LoadConfig/ListConfigs (JSON через writefile, если доступно).
- safeCall: все callback'и защищены pcall.
- Поиск по элементам (строка в шапке).
- Window:Notify — всплывающие уведомления.
- Ленивая отрисовка под-вкладок: Tab:AddSubTab(name, builder).
- Сворачиваемые секции (клик по заголовку).
- Новые компоненты: AddColorpicker, AddInput.
- opts.Flag доступен у Toggle/Slider/Dropdown/Keybind/Input/Colorpicker.
]]

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- Доступен ли файловый API исполнителя (для конфигов).
local hasFileIO = (typeof(writefile) == "function")
	and (typeof(readfile) == "function")
	and (typeof(isfile) == "function")

-- ====================== ТЕМЫ ======================
local FixedColors = {
	Text     = Color3.fromRGB(198, 198, 203),
	SubText  = Color3.fromRGB(126, 126, 134),
	Disabled = Color3.fromRGB(78, 78, 84),
	White    = Color3.fromRGB(255, 255, 255),
}

local Themes = {
	Monochrome = { Background = Color3.fromRGB(14,14,16), TopBar = Color3.fromRGB(19,19,22), Section = Color3.fromRGB(21,21,24), Element = Color3.fromRGB(31,31,35), Accent = Color3.fromRGB(255,255,255), Stroke = Color3.fromRGB(44,44,50) },
	Crimson    = { Background = Color3.fromRGB(16,12,13), TopBar = Color3.fromRGB(22,16,17), Section = Color3.fromRGB(24,17,18), Element = Color3.fromRGB(36,24,25), Accent = Color3.fromRGB(230,70,70),   Stroke = Color3.fromRGB(50,32,33) },
	Ocean      = { Background = Color3.fromRGB(11,14,17), TopBar = Color3.fromRGB(15,19,23), Section = Color3.fromRGB(17,21,26), Element = Color3.fromRGB(26,32,39), Accent = Color3.fromRGB(80,160,255), Stroke = Color3.fromRGB(35,44,53) },
	Violet     = { Background = Color3.fromRGB(15,13,17), TopBar = Color3.fromRGB(20,17,23), Section = Color3.fromRGB(22,19,25), Element = Color3.fromRGB(33,28,38), Accent = Color3.fromRGB(170,110,255), Stroke = Color3.fromRGB(47,40,54) },
	Emerald    = { Background = Color3.fromRGB(12,15,13), TopBar = Color3.fromRGB(17,21,18), Section = Color3.fromRGB(19,23,20), Element = Color3.fromRGB(28,34,29), Accent = Color3.fromRGB(80,210,120), Stroke = Color3.fromRGB(40,49,42) },
}

-- ====================== ХЕЛПЕРЫ ======================
local function tween(obj, info, props)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 6)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(44, 44, 50)
	s.Thickness = thickness or 1
	s.Parent = parent
	return s
end

local function padUniform(parent, all)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, all)
	p.PaddingBottom = UDim.new(0, all)
	p.PaddingLeft = UDim.new(0, all)
	p.PaddingRight = UDim.new(0, all)
	p.Parent = parent
	return p
end

local function listLayout(parent, padding, horizontal)
	local l = Instance.new("UIListLayout")
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Padding = UDim.new(0, padding or 0)
	if horizontal then
		l.FillDirection = Enum.FillDirection.Horizontal
	end
	l.Parent = parent
	return l
end

local function track(list, conn)
	table.insert(list, conn)
	return conn
end

-- Защищённый вызов пользовательского callback: ошибка не роняет меню.
local function safeCall(fn, ...)
	if type(fn) ~= "function" then return end
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[CustomLib] Ошибка в callback: " .. tostring(err))
	end
end

local function reg(list, instance, prop, getter)
	instance[prop] = getter()
	if list then
		table.insert(list, { Instance = instance, Prop = prop, Getter = getter })
	end
	return instance
end

-- Универсальный, безопасно-отключаемый drag. Коннекты трекаются в connList.
local function makeDraggable(frame, handle, connList)
	local dragging, dragStart, startPos
	track(connList, handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
		end
	end))
	track(connList, handle.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
	track(connList, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end))
end

-- ====================== МЕТАТАБЛИЦЫ КЛАССОВ ======================
local Window   = {}; Window.__index = Window
local MainTab  = {}; MainTab.__index = MainTab
local SubTab   = {}; SubTab.__index = SubTab
local Section  = {}; Section.__index = Section

local Library = {}
Library.Themes = Themes
Library.ThemeNames = { "Monochrome", "Crimson", "Ocean", "Violet", "Emerald" }

-- ====================== ОКНО ======================
function Library:CreateWindow(config)
	config = config or {}
	local title    = config.Title or "Menu"
	local subtitle = config.Subtitle or ""
	local size     = config.Size or UDim2.fromOffset(700, 520)

	local Theme = {}
	for k, v in pairs(FixedColors) do Theme[k] = v end
	for k, v in pairs(Themes.Monochrome) do Theme[k] = v end

	local themedList = {}
	local connections = {}

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "CustomLibTopTabsGui"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.DisplayOrder = 999
	local ok = pcall(function() ScreenGui.Parent = CoreGui end)
	if not ok or not ScreenGui.Parent then
		ScreenGui.Parent = PlayerGui
	end

	local Main = Instance.new("Frame")
	Main.Name = "Main"
	Main.AnchorPoint = Vector2.new(0.5, 0.5)
	Main.Position = UDim2.fromScale(0.5, 0.5)
	Main.Size = size
	Main.BorderSizePixel = 0
	Main.ClipsDescendants = true
	Main.Parent = ScreenGui
	corner(Main, 10)
	reg(themedList, Main, "BackgroundColor3", function() return Theme.Background end)
	reg(themedList, stroke(Main, Theme.Stroke, 1), "Color", function() return Theme.Stroke end)

	local UIScale = Instance.new("UIScale")
	UIScale.Scale = 1
	UIScale.Parent = Main

	-- ---- Верхняя шапка ----
	local TopBar = Instance.new("Frame")
	TopBar.Size = UDim2.new(1, 0, 0, 36)
	TopBar.BorderSizePixel = 0
	TopBar.Parent = Main
	corner(TopBar, 10)
	reg(themedList, TopBar, "BackgroundColor3", function() return Theme.TopBar end)

	local TopBarFix = Instance.new("Frame")
	TopBarFix.BorderSizePixel = 0
	TopBarFix.Position = UDim2.new(0, 0, 1, -10)
	TopBarFix.Size = UDim2.new(1, 0, 0, 10)
	TopBarFix.Parent = TopBar
	reg(themedList, TopBarFix, "BackgroundColor3", function() return Theme.TopBar end)

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Position = UDim2.new(0, 14, 0, 0)
	TitleLabel.Size = UDim2.new(0, 200, 1, 0)
	TitleLabel.Font = Enum.Font.GothamBold
	TitleLabel.TextSize = 15
	TitleLabel.TextColor3 = Theme.Text
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.Text = title
	TitleLabel.Parent = TopBar

	local SubtitleLabel = Instance.new("TextLabel")
	SubtitleLabel.BackgroundTransparency = 1
	SubtitleLabel.Position = UDim2.new(0, 14, 0, 0)
	SubtitleLabel.Size = UDim2.new(0, 160, 1, 0)
	SubtitleLabel.Font = Enum.Font.Gotham
	SubtitleLabel.TextSize = 13
	SubtitleLabel.TextColor3 = Theme.SubText
	SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	SubtitleLabel.Text = subtitle
	SubtitleLabel.Parent = TopBar
	task.defer(function()
		SubtitleLabel.Position = UDim2.new(0, 14 + TitleLabel.TextBounds.X + 12, 0, 0)
	end)

	local CloseBtn = Instance.new("TextButton")
	CloseBtn.Text = "×"
	CloseBtn.Font = Enum.Font.GothamBold
	CloseBtn.TextSize = 18
	CloseBtn.TextColor3 = Theme.SubText
	CloseBtn.BackgroundTransparency = 1
	CloseBtn.AutoButtonColor = false
	CloseBtn.Size = UDim2.fromOffset(30, 30)
	CloseBtn.Position = UDim2.new(1, -36, 0, 3)
	CloseBtn.Parent = TopBar

	track(connections, CloseBtn.MouseEnter:Connect(function()
		tween(CloseBtn, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(230, 90, 90)})
	end))
	track(connections, CloseBtn.MouseLeave:Connect(function()
		tween(CloseBtn, TweenInfo.new(0.15), {TextColor3 = Theme.SubText})
	end))

	-- ---- Поиск ----
	local SearchBox = Instance.new("TextBox")
	SearchBox.Size = UDim2.fromOffset(150, 22)
	SearchBox.Position = UDim2.new(1, -196, 0.5, -11)
	SearchBox.Font = Enum.Font.Gotham
	SearchBox.TextSize = 12
	SearchBox.TextColor3 = Theme.Text
	SearchBox.PlaceholderText = "Поиск..."
	SearchBox.PlaceholderColor3 = Theme.SubText
	SearchBox.Text = ""
	SearchBox.ClearTextOnFocus = false
	SearchBox.TextXAlignment = Enum.TextXAlignment.Left
	SearchBox.Parent = TopBar
	corner(SearchBox, 5)
	reg(themedList, SearchBox, "BackgroundColor3", function() return Theme.Element end)
	local sp = Instance.new("UIPadding"); sp.PaddingLeft = UDim.new(0, 8); sp.Parent = SearchBox

	makeDraggable(Main, TopBar, connections)

	-- ---- Ряд главных вкладок ----
	local MainTabBar = Instance.new("Frame")
	MainTabBar.Position = UDim2.new(0, 0, 0, 36)
	MainTabBar.Size = UDim2.new(1, 0, 0, 40)
	MainTabBar.BorderSizePixel = 0
	MainTabBar.Parent = Main
	reg(themedList, MainTabBar, "BackgroundColor3", function() return Theme.TopBar end)

	local mainTabList = listLayout(MainTabBar, 28, true)
	mainTabList.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local ContentHost = Instance.new("Frame")
	ContentHost.Position = UDim2.new(0, 0, 0, 76)
	ContentHost.Size = UDim2.new(1, 0, 1, -76)
	ContentHost.BackgroundTransparency = 1
	ContentHost.ClipsDescendants = true
	ContentHost.Parent = Main

	local self = setmetatable({
		ScreenGui = ScreenGui,
		Main = Main,
		UIScale = UIScale,
		MainTabBar = MainTabBar,
		ContentHost = ContentHost,
		MainTabs = {},
		CurrentMainTab = nil,
		Visible = true,
		OriginalSize = size,
		Connections = connections,
		ThemedInstances = themedList,
		Theme = Theme,
		CurrentThemeName = "Monochrome",
		ToggleKey = config.ToggleKey or Enum.KeyCode.RightControl,
		KeybindListFrame = nil,
		KeybindRows = {},
		-- v4.0:
		Flags = {},
		FlagSetters = {},
		Registry = {},
		Sections = {},
		ConfigFolder = config.ConfigFolder or "CustomLibConfigs",
		NotifHolder = nil,
	}, Window)

	track(self.Connections, CloseBtn.MouseButton1Click:Connect(function() self:SetVisible(false) end))
	track(self.Connections, SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		self:_applySearch(SearchBox.Text)
	end))
	track(self.Connections, UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == self.ToggleKey then self:SetVisible(not self.Visible) end
	end))

	Main.Size = UDim2.new(size.X.Scale, size.X.Offset, size.Y.Scale, math.floor(size.Y.Offset * 0.85))
	Main.BackgroundTransparency = 1
	tween(Main, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = size, BackgroundTransparency = 0,
	})

	return self
end

function Window:SetVisible(state)
	self.Visible = state
	local size = self.OriginalSize
	if state then
		self.ScreenGui.Enabled = true
		self.Main.Size = UDim2.new(size.X.Scale, size.X.Offset, size.Y.Scale, math.floor(size.Y.Offset * 0.9))
		self.Main.BackgroundTransparency = 1
		tween(self.Main, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = size, BackgroundTransparency = 0,
		})
	else
		local t = tween(self.Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
		})
		t.Completed:Connect(function()
			if not self.Visible then self.ScreenGui.Enabled = false end
		end)
	end
end

function Window:SetTheme(name)
	local preset = Themes[name]
	if not preset then return end
	local Theme = self.Theme
	for k, v in pairs(preset) do Theme[k] = v end
	for _, entry in ipairs(self.ThemedInstances) do
		pcall(function()
			tween(entry.Instance, TweenInfo.new(0.2), {[entry.Prop] = entry.Getter()})
		end)
	end
	self.CurrentThemeName = name
end

function Window:SetToggleKey(keyCode)
	self.ToggleKey = keyCode
end

function Window:CaptureNextKey(callback)
	local conn
	conn = UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			conn:Disconnect()
			safeCall(callback, input.KeyCode)
		end
	end)
	track(self.Connections, conn)
end

function Window:SetUIScale(percent)
	tween(self.UIScale, TweenInfo.new(0.15), {Scale = percent / 100})
end

function Window:ResetPosition()
	tween(self.Main, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.5, 0.5),
	})
end

function Window:Destroy()
	for _, conn in ipairs(self.Connections) do
		pcall(function() conn:Disconnect() end)
	end
	local t = tween(self.Main, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 1,
	})
	t.Completed:Connect(function()
		self.ScreenGui:Destroy()
	end)
end

-- ---- Поиск: фильтрация зарегистрированных элементов ----
function Window:_registerElement(name, frame, sectionFrame)
	table.insert(self.Registry, { Name = string.lower(tostring(name or "")), Frame = frame, Section = sectionFrame })
end

function Window:_applySearch(query)
	local q = string.lower(query or "")
	for _, e in ipairs(self.Registry) do
		e.Frame.Visible = (q == "") or (string.find(e.Name, q, 1, true) ~= nil)
	end
	for _, secFrame in ipairs(self.Sections) do
		if q == "" then
			secFrame.Visible = true
		else
			local any = false
			for _, ch in ipairs(secFrame:GetChildren()) do
				if ch:IsA("GuiObject") and ch.LayoutOrder > 0 and ch.Visible then
					any = true
					break
				end
			end
			secFrame.Visible = any
		end
	end
end

-- ---- Уведомления ----
function Window:_ensureNotifHolder()
	if self.NotifHolder then return end
	local Holder = Instance.new("Frame")
	Holder.Name = "Notifications"
	Holder.AnchorPoint = Vector2.new(1, 1)
	Holder.Position = UDim2.new(1, -16, 1, -16)
	Holder.Size = UDim2.new(0, 240, 1, -32)
	Holder.BackgroundTransparency = 1
	Holder.Parent = self.ScreenGui
	local l = listLayout(Holder, 6)
	l.VerticalAlignment = Enum.VerticalAlignment.Bottom
	l.HorizontalAlignment = Enum.HorizontalAlignment.Right
	self.NotifHolder = Holder
end

function Window:Notify(opts)
	opts = opts or {}
	local Theme = self.Theme
	self:_ensureNotifHolder()

	local kind = opts.Type or "info"
	local accent = (kind == "success" and Color3.fromRGB(80, 210, 120))
		or (kind == "error" and Color3.fromRGB(230, 70, 70))
		or Theme.Accent

	local Card = Instance.new("Frame")
	Card.Size = UDim2.new(1, 0, 0, 0)
	Card.AutomaticSize = Enum.AutomaticSize.Y
	Card.BackgroundColor3 = Theme.Section
	Card.BackgroundTransparency = 1
	Card.BorderSizePixel = 0
	Card.Parent = self.NotifHolder
	corner(Card, 6)
	stroke(Card, Theme.Stroke, 1)
	padUniform(Card, 8)
	listLayout(Card, 2)

	local Title = Instance.new("TextLabel")
	Title.BackgroundTransparency = 1
	Title.Size = UDim2.new(1, 0, 0, 15)
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 13
	Title.TextColor3 = accent
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Text = opts.Title or "Notice"
	Title.LayoutOrder = 0
	Title.Parent = Card

	local Body = Instance.new("TextLabel")
	Body.BackgroundTransparency = 1
	Body.Size = UDim2.new(1, 0, 0, 0)
	Body.AutomaticSize = Enum.AutomaticSize.Y
	Body.Font = Enum.Font.Gotham
	Body.TextSize = 12
	Body.TextColor3 = Theme.Text
	Body.TextXAlignment = Enum.TextXAlignment.Left
	Body.TextWrapped = true
	Body.Text = opts.Text or ""
	Body.LayoutOrder = 1
	Body.Parent = Card

	tween(Card, TweenInfo.new(0.2), {BackgroundTransparency = 0.05})
	task.delay(opts.Duration or 3, function()
		if not Card.Parent then return end
		local out = tween(Card, TweenInfo.new(0.25), {BackgroundTransparency = 1})
		out.Completed:Connect(function() Card:Destroy() end)
	end)
end

-- ---- Конфиги (Flags -> JSON) ----
function Window:SaveConfig(name)
	if not hasFileIO then
		self:Notify({ Title = "Config", Text = "Файловый API недоступен", Type = "error" })
		return false
	end
	name = name or "default"
	local folder = self.ConfigFolder
	if typeof(makefolder) == "function" and typeof(isfolder) == "function" and not isfolder(folder) then
		pcall(makefolder, folder)
	end
	local data = {}
	for flag, val in pairs(self.Flags) do
		if typeof(val) == "Color3" then
			data[flag] = { __c3 = { val.R, val.G, val.B } }
		elseif typeof(val) == "EnumItem" then
			data[flag] = { __enum = tostring(val) }
		else
			data[flag] = val
		end
	end
	local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
	if not ok then return false end
	local wok = pcall(writefile, folder .. "/" .. name .. ".json", encoded)
	if wok then
		self:Notify({ Title = "Config", Text = "Сохранён: " .. name, Type = "success" })
	end
	return wok
end

function Window:LoadConfig(name)
	if not hasFileIO then return false end
	name = name or "default"
	local path = self.ConfigFolder .. "/" .. name .. ".json"
	if not isfile(path) then
		self:Notify({ Title = "Config", Text = "Не найден: " .. name, Type = "error" })
		return false
	end
	local ok, content = pcall(readfile, path)
	if not ok then return false end
	local dok, data = pcall(function() return HttpService:JSONDecode(content) end)
	if not dok or type(data) ~= "table" then return false end
	for flag, raw in pairs(data) do
		local val = raw
		if type(raw) == "table" then
			if raw.__c3 then
				val = Color3.new(raw.__c3[1], raw.__c3[2], raw.__c3[3])
			elseif raw.__enum then
				local parts = string.split(raw.__enum, ".")
				local eok, e = pcall(function() return Enum[parts[2]][parts[3]] end)
				val = eok and e or nil
			end
		end
		local setter = self.FlagSetters[flag]
		if setter and val ~= nil then safeCall(setter, val) end
	end
	self:Notify({ Title = "Config", Text = "Загружен: " .. name, Type = "success" })
	return true
end

function Window:ListConfigs()
	local out = {}
	if not (hasFileIO and typeof(listfiles) == "function") then return out end
	local folder = self.ConfigFolder
	if typeof(isfolder) == "function" and not isfolder(folder) then return out end
	local ok, files = pcall(listfiles, folder)
	if not ok then return out end
	for _, f in ipairs(files) do
		local nm = string.match(f, "([^/\\]+)%.json$")
		if nm then table.insert(out, nm) end
	end
	return out
end

-- ---- Список кейбиндов ----
function Window:_ensureKeybindList()
	if self.KeybindListFrame then return end
	local Theme = self.Theme

	local Frame = Instance.new("Frame")
	Frame.Name = "KeybindList"
	Frame.Position = UDim2.new(0, 16, 0, 16)
	Frame.Size = UDim2.new(0, 170, 0, 0)
	Frame.AutomaticSize = Enum.AutomaticSize.Y
	Frame.BorderSizePixel = 0
	Frame.Visible = false
	Frame.Parent = self.ScreenGui
	corner(Frame, 6)
	reg(self.ThemedInstances, Frame, "BackgroundColor3", function() return Theme.Section end)
	reg(self.ThemedInstances, stroke(Frame, Theme.Stroke, 1), "Color", function() return Theme.Stroke end)

	listLayout(Frame, 4)
	padUniform(Frame, 8)

	local Title = Instance.new("TextLabel")
	Title.BackgroundTransparency = 1
	Title.Size = UDim2.new(1, 0, 0, 14)
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 12
	Title.TextColor3 = Theme.SubText
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Text = "Keybinds"
	Title.LayoutOrder = 0
	Title.Parent = Frame

	makeDraggable(Frame, Frame, self.Connections)
	self.KeybindListFrame = Frame
end

function Window:SetKeybindListVisible(state)
	self:_ensureKeybindList()
	self.KeybindListFrame.Visible = state
end

function Window:_addKeybindRow(label, initialKeyName)
	self:_ensureKeybindList()
	local Theme = self.Theme

	local Row = Instance.new("TextLabel")
	Row.BackgroundTransparency = 1
	Row.Size = UDim2.new(1, 0, 0, 14)
	Row.Font = Enum.Font.Gotham
	Row.TextSize = 12
	Row.TextXAlignment = Enum.TextXAlignment.Left
	Row.Text = label .. ": " .. initialKeyName
	Row.Parent = self.KeybindListFrame
	reg(self.ThemedInstances, Row, "TextColor3", function() return Theme.Text end)

	table.insert(self.KeybindRows, Row)
	return function(newKeyName)
		Row.Text = label .. ": " .. newKeyName
	end
end

-- ====================== ГЛАВНЫЕ ВКЛАДКИ ======================
function Window:AddMainTab(name)
	local Theme = self.Theme

	local Btn = Instance.new("TextButton")
	Btn.BackgroundTransparency = 1
	Btn.Size = UDim2.fromOffset(0, 40)
	Btn.AutomaticSize = Enum.AutomaticSize.X
	Btn.Font = Enum.Font.GothamMedium
	Btn.TextSize = 15
	Btn.TextColor3 = Theme.SubText
	Btn.Text = name
	Btn.Parent = self.MainTabBar

	local UnderlineBar = Instance.new("Frame")
	UnderlineBar.AnchorPoint = Vector2.new(0.5, 0)
	UnderlineBar.Position = UDim2.new(0.5, 0, 1, 6)
	UnderlineBar.Size = UDim2.new(0, 0, 0, 2)
	UnderlineBar.BackgroundTransparency = 1
	UnderlineBar.BorderSizePixel = 0
	UnderlineBar.Parent = Btn
	reg(self.ThemedInstances, UnderlineBar, "BackgroundColor3", function() return Theme.Accent end)

	local Host = Instance.new("Frame")
	Host.Size = UDim2.fromScale(1, 1)
	Host.BackgroundTransparency = 1
	Host.Visible = false
	Host.Parent = self.ContentHost

	local SubTabBar = Instance.new("Frame")
	SubTabBar.Size = UDim2.new(1, -24, 0, 32)
	SubTabBar.Position = UDim2.new(0, 12, 0, 8)
	SubTabBar.BackgroundTransparency = 1
	SubTabBar.Parent = Host
	listLayout(SubTabBar, 8, true)

	local SubContentHost = Instance.new("Frame")
	SubContentHost.Position = UDim2.new(0, 12, 0, 48)
	SubContentHost.Size = UDim2.new(1, -24, 1, -56)
	SubContentHost.BackgroundTransparency = 1
	SubContentHost.ClipsDescendants = true
	SubContentHost.Parent = Host

	local windowRef = self
	local tabObj = setmetatable({
		Window = windowRef,
		Button = Btn,
		Underline = UnderlineBar,
		Host = Host,
		SubTabBar = SubTabBar,
		SubContentHost = SubContentHost,
		SubTabs = {},
		CurrentSubTab = nil,
	}, MainTab)

	table.insert(self.MainTabs, tabObj)

	reg(self.ThemedInstances, Btn, "TextColor3", function()
		return (windowRef.CurrentMainTab == tabObj) and Theme.Accent or Theme.SubText
	end)

	track(self.Connections, Btn.MouseButton1Click:Connect(function()
		windowRef:SelectMainTab(tabObj)
	end))
	track(self.Connections, Btn.MouseEnter:Connect(function()
		if windowRef.CurrentMainTab ~= tabObj then
			tween(Btn, TweenInfo.new(0.15), {TextColor3 = Theme.Text})
		end
	end))
	track(self.Connections, Btn.MouseLeave:Connect(function()
		if windowRef.CurrentMainTab ~= tabObj then
			tween(Btn, TweenInfo.new(0.15), {TextColor3 = Theme.SubText})
		end
	end))

	if not self.CurrentMainTab then
		self:SelectMainTab(tabObj)
	end

	return tabObj
end

function Window:SelectMainTab(tab)
	if self.CurrentMainTab == tab then return end
	local Theme = self.Theme
	local old = self.CurrentMainTab
	self.CurrentMainTab = tab

	if old then
		tween(old.Button, TweenInfo.new(0.15), {TextColor3 = Theme.SubText})
		old.Host.Visible = false
		tween(old.Underline, TweenInfo.new(0.15), {
			Size = UDim2.new(0, 0, 0, 2),
			BackgroundTransparency = 1,
		})
	end

	tween(tab.Button, TweenInfo.new(0.15), {TextColor3 = Theme.Accent})
	tab.Host.Visible = true
	tween(tab.Underline, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundTransparency = 0,
	})
end

-- ====================== ПОД-ВКЛАДКИ ======================
-- builder (опционально): function(subTab) — выполнится при ПЕРВОМ открытии вкладки (lazy).
function MainTab:AddSubTab(name, builder)
	local window = self.Window
	local Theme = window.Theme

	local Btn = Instance.new("TextButton")
	Btn.AutomaticSize = Enum.AutomaticSize.X
	Btn.Size = UDim2.fromOffset(0, 30)
	Btn.AutoButtonColor = false
	Btn.Font = Enum.Font.Gotham
	Btn.TextSize = 13
	Btn.TextColor3 = Theme.SubText
	Btn.Text = "  " .. name .. "  "
	Btn.Parent = self.SubTabBar
	corner(Btn, 6)

	local Page = Instance.new("Frame")
	Page.Size = UDim2.fromScale(1, 1)
	Page.BackgroundTransparency = 1
	Page.Visible = false
	Page.Parent = self.SubContentHost

	local Left = Instance.new("ScrollingFrame")
	Left.Size = UDim2.new(0.5, -6, 1, 0)
	Left.Position = UDim2.new(0, 0, 0, 0)
	Left.BackgroundTransparency = 1
	Left.BorderSizePixel = 0
	Left.ScrollBarThickness = 3
	Left.CanvasSize = UDim2.new(0, 0, 0, 0)
	Left.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Left.Parent = Page
	listLayout(Left, 10)
	reg(window.ThemedInstances, Left, "ScrollBarImageColor3", function() return Theme.Accent end)

	local Right = Instance.new("ScrollingFrame")
	Right.Size = UDim2.new(0.5, -6, 1, 0)
	Right.Position = UDim2.new(0.5, 6, 0, 0)
	Right.BackgroundTransparency = 1
	Right.BorderSizePixel = 0
	Right.ScrollBarThickness = 3
	Right.CanvasSize = UDim2.new(0, 0, 0, 0)
	Right.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Right.Parent = Page
	listLayout(Right, 10)
	reg(window.ThemedInstances, Right, "ScrollBarImageColor3", function() return Theme.Accent end)

	local mainTabRef = self
	local subTab = setmetatable({
		MainTab = mainTabRef,
		Window = window,
		Button = Btn,
		Page = Page,
		Left = Left,
		Right = Right,
		_builder = builder,
		_built = false,
	}, SubTab)

	table.insert(self.SubTabs, subTab)

	reg(window.ThemedInstances, Btn, "BackgroundColor3", function()
		return (mainTabRef.CurrentSubTab == subTab) and Theme.Accent or Theme.Element
	end)

	track(window.Connections, Btn.MouseButton1Click:Connect(function()
		mainTabRef:SelectSubTab(subTab)
	end))
	track(window.Connections, Btn.MouseEnter:Connect(function()
		if mainTabRef.CurrentSubTab ~= subTab then
			tween(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Stroke})
		end
	end))
	track(window.Connections, Btn.MouseLeave:Connect(function()
		if mainTabRef.CurrentSubTab ~= subTab then
			tween(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Element})
		end
	end))

	if not self.CurrentSubTab then
		self:SelectSubTab(subTab)
	end

	return subTab
end

function MainTab:SelectSubTab(subTab)
	if self.CurrentSubTab == subTab then return end
	local Theme = self.Window.Theme

	-- Ленивая отрисовка: строим содержимое при первом открытии.
	if not subTab._built then
		subTab._built = true
		if subTab._builder then safeCall(subTab._builder, subTab) end
	end

	local old = self.CurrentSubTab
	self.CurrentSubTab = subTab

	if old then
		tween(old.Button, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Element, TextColor3 = Theme.SubText})
		old.Page.Visible = false
	end

	tween(subTab.Button, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Accent, TextColor3 = Color3.fromRGB(20, 20, 20)})
	local page = subTab.Page
	page.Visible = true
	page.Position = UDim2.new(0, 16, 0, 0)
	tween(page, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, 0),
	})
end

-- ====================== СЕКЦИИ ======================
-- Заголовок секции кликабельный — сворачивает/разворачивает тело.
local function buildSection(parent, name, window)
	local Theme = window.Theme

	local Frame = Instance.new("Frame")
	Frame.BorderSizePixel = 0
	Frame.Size = UDim2.new(1, 0, 0, 0)
	Frame.AutomaticSize = Enum.AutomaticSize.Y
	Frame.Parent = parent
	corner(Frame, 8)
	reg(window.ThemedInstances, Frame, "BackgroundColor3", function() return Theme.Section end)
	reg(window.ThemedInstances, stroke(Frame, Theme.Stroke, 1), "Color", function() return Theme.Stroke end)
	listLayout(Frame, 6)
	padUniform(Frame, 10)

	table.insert(window.Sections, Frame)

	local Title = Instance.new("TextButton")
	Title.BackgroundTransparency = 1
	Title.AutoButtonColor = false
	Title.Size = UDim2.new(1, 0, 0, 18)
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 13
	Title.TextColor3 = Theme.SubText
	Title.Text = name
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.LayoutOrder = 0
	Title.Parent = Frame

	local collapsed = false
	track(window.Connections, Title.MouseButton1Click:Connect(function()
		collapsed = not collapsed
		for _, ch in ipairs(Frame:GetChildren()) do
			if ch:IsA("GuiObject") and ch ~= Title then
				ch.Visible = not collapsed
			end
		end
	end))

	return setmetatable({ Frame = Frame, Order = 1, Window = window }, Section)
end

function SubTab:AddLeftSection(name)
	return buildSection(self.Left, name, self.Window)
end

function SubTab:AddRightSection(name)
	return buildSection(self.Right, name, self.Window)
end

function Section:_order()
	self.Order = self.Order + 1
	return self.Order
end

-- ---- Toggle ----
function Section:AddToggle(text, default, callback, opts)
	opts = opts or {}
	local flag = opts.Flag
	default = default or false
	local window = self.Window
	local Theme = window.Theme

	local Row = Instance.new("TextButton")
	Row.Size = UDim2.new(1, 0, 0, 26)
	Row.BackgroundTransparency = 1
	Row.AutoButtonColor = false
	Row.Text = ""
	Row.LayoutOrder = self:_order()
	Row.Parent = self.Frame

	local Track = Instance.new("Frame")
	Track.Size = UDim2.fromOffset(32, 16)
	Track.Position = UDim2.new(0, 0, 0.5, -8)
	Track.Parent = Row
	corner(Track, 8)
	reg(window.ThemedInstances, stroke(Track, Theme.Stroke, 1), "Color", function() return Theme.Stroke end)

	local Knob = Instance.new("Frame")
	Knob.Size = UDim2.fromOffset(12, 12)
	Knob.Parent = Track
	corner(Knob, 6)

	local Label = Instance.new("TextLabel")
	Label.BackgroundTransparency = 1
	Label.Position = UDim2.new(0, 40, 0, 0)
	Label.Size = UDim2.new(1, -40, 1, 0)
	Label.Font = Enum.Font.Gotham
	Label.TextSize = 14
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Text = text
	Label.Parent = Row

	local state = default

	reg(window.ThemedInstances, Track, "BackgroundColor3", function() return state and Theme.Accent or Theme.Element end)
	reg(window.ThemedInstances, Knob, "BackgroundColor3", function() return state and Color3.fromRGB(20,20,20) or Theme.White end)
	reg(window.ThemedInstances, Label, "TextColor3", function() return state and Theme.Accent or Theme.Text end)

	local function applyPositions(animate)
		local trackColor = state and Theme.Accent or Theme.Element
		local knobColor = state and Color3.fromRGB(20, 20, 20) or Theme.White
		local knobPos = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
		local textColor = state and Theme.Accent or Theme.Text
		if animate then
			tween(Track, TweenInfo.new(0.15), {BackgroundColor3 = trackColor})
			tween(Knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Position = knobPos, BackgroundColor3 = knobColor})
			tween(Label, TweenInfo.new(0.15), {TextColor3 = textColor})
		else
			Track.BackgroundColor3 = trackColor
			Knob.Position = knobPos
			Knob.BackgroundColor3 = knobColor
			Label.TextColor3 = textColor
		end
	end
	applyPositions(false)

	local function set(v, fire)
		state = v
		applyPositions(true)
		if flag then window.Flags[flag] = state end
		if fire ~= false then safeCall(callback, state) end
	end

	track(window.Connections, Row.MouseButton1Click:Connect(function() set(not state) end))

	if flag then
		window.Flags[flag] = state
		window.FlagSetters[flag] = function(v) set(v, true) end
	end
	window:_registerElement(text, Row, self.Frame)

	return {
		Set = function(_, v) set(v, false) end,
		Get = function() return state end,
	}
end

-- ---- Slider ----
function Section:AddSlider(text, min, max, default, unit, callback, opts)
	opts = opts or {}
	local flag = opts.Flag
	min = min or 0
	max = max or 100
	default = math.clamp(default or min, min, max)
	unit = unit or ""
	local window = self.Window
	local Theme = window.Theme

	local Container = Instance.new("Frame")
	Container.Size = UDim2.new(1, 0, 0, 40)
	Container.BackgroundTransparency = 1
	Container.LayoutOrder = self:_order()
	Container.Parent = self.Frame

	local Label = Instance.new("TextLabel")
	Label.BackgroundTransparency = 1
	Label.Position = UDim2.new(0, 0, 0, 0)
	Label.Size = UDim2.new(1, -60, 0, 16)
	Label.Font = Enum.Font.Gotham
	Label.TextSize = 14
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Text = text
	Label.Parent = Container
	reg(window.ThemedInstances, Label, "TextColor3", function() return Theme.Text end)

	local ValueLabel = Instance.new("TextLabel")
	ValueLabel.BackgroundTransparency = 1
	ValueLabel.Position = UDim2.new(1, -60, 0, 0)
	ValueLabel.Size = UDim2.new(0, 60, 0, 16)
	ValueLabel.Font = Enum.Font.GothamBold
	ValueLabel.TextSize = 13
	ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
	ValueLabel.Parent = Container
	reg(window.ThemedInstances, ValueLabel, "TextColor3", function() return Theme.Accent end)

	local Bar = Instance.new("TextButton")
	Bar.AutoButtonColor = false
	Bar.Text = ""
	Bar.Position = UDim2.new(0, 0, 0, 26)
	Bar.Size = UDim2.new(1, 0, 0, 6)
	Bar.Parent = Container
	corner(Bar, 3)
	reg(window.ThemedInstances, Bar, "BackgroundColor3", function() return Theme.Element end)

	local Fill = Instance.new("Frame")
	Fill.Size = UDim2.new(0, 0, 1, 0)
	Fill.BorderSizePixel = 0
	Fill.Parent = Bar
	corner(Fill, 3)
	reg(window.ThemedInstances, Fill, "BackgroundColor3", function() return Theme.Accent end)

	local decimals = opts.Decimals or 0
	local mult = 10 ^ decimals
	local value = default

	local function render()
		local rel = (max > min) and (value - min) / (max - min) or 0
		Fill.Size = UDim2.new(rel, 0, 1, 0)
		local shown = (decimals > 0) and string.format("%." .. decimals .. "f", value) or tostring(math.floor(value + 0.5))
		ValueLabel.Text = shown .. unit
	end
	render()

	local function set(v, fire)
		v = math.clamp(v, min, max)
		v = math.floor(v * mult + 0.5) / mult
		value = v
		render()
		if flag then window.Flags[flag] = value end
		if fire ~= false then safeCall(callback, value) end
	end

	local dragging = false
	local function updateFromX(x)
		local rel = math.clamp((x - Bar.AbsolutePosition.X) / math.max(Bar.AbsoluteSize.X, 1), 0, 1)
		set(min + (max - min) * rel, true)
	end

	track(window.Connections, Bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromX(input.Position.X)
		end
	end))
	track(window.Connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
	track(window.Connections, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromX(input.Position.X)
		end
	end))

	if flag then
		window.Flags[flag] = value
		window.FlagSetters[flag] = function(v) set(v, true) end
	end
	window:_registerElement(text, Container, self.Frame)

	return {
		Set = function(_, v) set(v, false) end,
		Get = function() return value end,
	}
end

-- ---- Dropdown ----
function Section:AddDropdown(text, options, default, callback, opts)
	opts = opts or {}
	local flag = opts.Flag
	options = options or {}
	local window = self.Window
	local Theme = window.Theme

	local Container = Instance.new("Frame")
	Container.Size = UDim2.new(1, 0, 0, 44)
	Container.BackgroundTransparency = 1
	Container.ClipsDescendants = false
	Container.LayoutOrder = self:_order()
	Container.Parent = self.Frame

	local Label = Instance.new("TextLabel")
	Label.BackgroundTransparency = 1
	Label.Size = UDim2.new(1, 0, 0, 16)
	Label.Font = Enum.Font.Gotham
	Label.TextSize = 14
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Text = text
	Label.Parent = Container
	reg(window.ThemedInstances, Label, "TextColor3", function() return Theme.Text end)

	local Head = Instance.new("TextButton")
	Head.AutoButtonColor = false
	Head.Position = UDim2.new(0, 0, 0, 20)
	Head.Size = UDim2.new(1, 0, 0, 24)
	Head.Font = Enum.Font.Gotham
	Head.TextSize = 13
	Head.TextXAlignment = Enum.TextXAlignment.Left
	Head.Text = "  " .. tostring(default or (options[1] or "..."))
	Head.Parent = Container
	corner(Head, 5)
	reg(window.ThemedInstances, Head, "BackgroundColor3", function() return Theme.Element end)
	reg(window.ThemedInstances, Head, "TextColor3", function() return Theme.Text end)

	local Arrow = Instance.new("TextLabel")
	Arrow.BackgroundTransparency = 1
	Arrow.Position = UDim2.new(1, -24, 0, 0)
	Arrow.Size = UDim2.new(0, 24, 1, 0)
	Arrow.Font = Enum.Font.GothamBold
	Arrow.TextSize = 12
	Arrow.Text = "▾"
	Arrow.Parent = Head
	reg(window.ThemedInstances, Arrow, "TextColor3", function() return Theme.SubText end)

	local ListFrame = Instance.new("Frame")
	ListFrame.Position = UDim2.new(0, 0, 0, 46)
	ListFrame.Size = UDim2.new(1, 0, 0, 0)
	ListFrame.BorderSizePixel = 0
	ListFrame.ClipsDescendants = true
	ListFrame.Visible = false
	ListFrame.ZIndex = 5
	ListFrame.Parent = Container
	corner(ListFrame, 5)
	reg(window.ThemedInstances, ListFrame, "BackgroundColor3", function() return Theme.Element end)
	local listInner = listLayout(ListFrame, 0)

	local selected = default or options[1]
	local open = false

	local function setSelection(opt, fire)
		if not table.find(options, opt) then return end
		selected = opt
		Head.Text = "  " .. tostring(opt)
		if flag then window.Flags[flag] = selected end
		if fire ~= false then safeCall(callback, selected) end
	end

	local function setOpen(o)
		open = o
		Arrow.Text = o and "▴" or "▾"
		local h = o and (#options * 24) or 0
		if o then ListFrame.Visible = true end
		tween(ListFrame, TweenInfo.new(0.15), {Size = UDim2.new(1, 0, 0, h)})
		tween(Container, TweenInfo.new(0.15), {Size = UDim2.new(1, 0, 0, 44 + (o and (h + 4) or 0))})
		if not o then
			task.delay(0.15, function() if not open then ListFrame.Visible = false end end)
		end
	end

	for i, opt in ipairs(options) do
		local OptBtn = Instance.new("TextButton")
		OptBtn.AutoButtonColor = false
		OptBtn.BackgroundTransparency = 1
		OptBtn.Size = UDim2.new(1, 0, 0, 24)
		OptBtn.Font = Enum.Font.Gotham
		OptBtn.TextSize = 13
		OptBtn.TextXAlignment = Enum.TextXAlignment.Left
		OptBtn.Text = "  " .. tostring(opt)
		OptBtn.LayoutOrder = i
		OptBtn.ZIndex = 6
		OptBtn.Parent = ListFrame
		reg(window.ThemedInstances, OptBtn, "TextColor3", function() return Theme.SubText end)
		track(window.Connections, OptBtn.MouseEnter:Connect(function()
			tween(OptBtn, TweenInfo.new(0.1), {TextColor3 = Theme.Text})
		end))
		track(window.Connections, OptBtn.MouseLeave:Connect(function()
			tween(OptBtn, TweenInfo.new(0.1), {TextColor3 = Theme.SubText})
		end))
		track(window.Connections, OptBtn.MouseButton1Click:Connect(function()
			setSelection(opt, true)
			setOpen(false)
		end))
	end

	track(window.Connections, Head.MouseButton1Click:Connect(function() setOpen(not open) end))

	if flag then
		window.Flags[flag] = selected
		window.FlagSetters[flag] = function(v) setSelection(v, true) end
	end
	window:_registerElement(text, Container, self.Frame)

	return {
		Set = function(_, v) setSelection(v, false) end,
		Get = function() return selected end,
		Close = function() setOpen(false) end,
	}
end

-- ---- Button ----
function Section:AddButton(text, callback)
	local window = self.Window
	local Theme = window.Theme

	local Btn = Instance.new("TextButton")
	Btn.AutoButtonColor = false
	Btn.Size = UDim2.new(1, 0, 0, 30)
	Btn.Font = Enum.Font.GothamMedium
	Btn.TextSize = 14
	Btn.Text = text
	Btn.LayoutOrder = self:_order()
	Btn.Parent = self.Frame
	corner(Btn, 6)
	reg(window.ThemedInstances, Btn, "BackgroundColor3", function() return Theme.Element end)
	reg(window.ThemedInstances, Btn, "TextColor3", function() return Theme.Text end)

	track(window.Connections, Btn.MouseEnter:Connect(function()
		tween(Btn, TweenInfo.new(0.12), {BackgroundColor3 = Theme.Stroke})
	end))
	track(window.Connections, Btn.MouseLeave:Connect(function()
		tween(Btn, TweenInfo.new(0.12), {BackgroundColor3 = Theme.Element})
	end))
	track(window.Connections, Btn.MouseButton1Click:Connect(function()
		tween(Btn, TweenInfo.new(0.08), {BackgroundColor3 = Theme.Accent})
		task.delay(0.12, function()
			tween(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Element})
		end)
		safeCall(callback)
	end))

	window:_registerElement(text, Btn, self.Frame)
	return { Fire = function() safeCall(callback) end }
end

-- ---- Label ----
function Section:AddLabel(text)
	local window = self.Window
	local Theme = window.Theme

	local Lbl = Instance.new("TextLabel")
	Lbl.BackgroundTransparency = 1
	Lbl.Size = UDim2.new(1, 0, 0, 18)
	Lbl.AutomaticSize = Enum.AutomaticSize.Y
	Lbl.Font = Enum.Font.Gotham
	Lbl.TextSize = 13
	Lbl.TextXAlignment = Enum.TextXAlignment.Left
	Lbl.TextWrapped = true
	Lbl.Text = text
	Lbl.LayoutOrder = self:_order()
	Lbl.Parent = self.Frame
	reg(window.ThemedInstances, Lbl, "TextColor3", function() return Theme.SubText end)

	window:_registerElement(text, Lbl, self.Frame)
	return { Set = function(_, v) Lbl.Text = v end }
end

-- ---- Placeholder ----
function Section:AddPlaceholder(height)
	local Space = Instance.new("Frame")
	Space.BackgroundTransparency = 1
	Space.Size = UDim2.new(1, 0, 0, height or 4)
	Space.LayoutOrder = self:_order()
	Space.Parent = self.Frame
	return Space
end

-- ---- TextInput ----
function Section:AddInput(text, placeholder, default, callback, opts)
	opts = opts or {}
	local flag = opts.Flag
	local window = self.Window
	local Theme = window.Theme

	local Container = Instance.new("Frame")
	Container.Size = UDim2.new(1, 0, 0, 44)
	Container.BackgroundTransparency = 1
	Container.LayoutOrder = self:_order()
	Container.Parent = self.Frame

	local Label = Instance.new("TextLabel")
	Label.BackgroundTransparency = 1
	Label.Size = UDim2.new(1, 0, 0, 16)
	Label.Font = Enum.Font.Gotham
	Label.TextSize = 14
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Text = text
	Label.Parent = Container
	reg(window.ThemedInstances, Label, "TextColor3", function() return Theme.Text end)

	local Box = Instance.new("TextBox")
	Box.Position = UDim2.new(0, 0, 0, 20)
	Box.Size = UDim2.new(1, 0, 0, 24)
	Box.Font = Enum.Font.Gotham
	Box.TextSize = 13
	Box.TextXAlignment = Enum.TextXAlignment.Left
	Box.PlaceholderText = placeholder or ""
	Box.Text = default or ""
	Box.ClearTextOnFocus = false
	Box.Parent = Container
	corner(Box, 5)
	local bp = Instance.new("UIPadding"); bp.PaddingLeft = UDim.new(0, 8); bp.Parent = Box
	reg(window.ThemedInstances, Box, "BackgroundColor3", function() return Theme.Element end)
	reg(window.ThemedInstances, Box, "TextColor3", function() return Theme.Text end)
	reg(window.ThemedInstances, Box, "PlaceholderColor3", function() return Theme.SubText end)

	local function set(v, fire)
		Box.Text = tostring(v)
		if flag then window.Flags[flag] = Box.Text end
		if fire ~= false then safeCall(callback, Box.Text) end
	end

	track(window.Connections, Box.FocusLost:Connect(function(enterPressed)
		if flag then window.Flags[flag] = Box.Text end
		safeCall(callback, Box.Text, enterPressed)
	end))

	if flag then
		window.Flags[flag] = Box.Text
		window.FlagSetters[flag] = function(v) set(v, true) end
	end
	window:_registerElement(text, Container, self.Frame)

	return {
		Set = function(_, v) set(v, false) end,
		Get = function() return Box.Text end,
	}
end

-- ---- Colorpicker (HSV) ----
function Section:AddColorpicker(text, default, callback, opts)
	opts = opts or {}
	local flag = opts.Flag
	default = default or Color3.fromRGB(255, 255, 255)
	local window = self.Window
	local Theme = window.Theme

	local h, s, v = Color3.toHSV(default)

	local Container = Instance.new("Frame")
	Container.Size = UDim2.new(1, 0, 0, 26)
	Container.BackgroundTransparency = 1
	Container.ClipsDescendants = false
	Container.LayoutOrder = self:_order()
	Container.Parent = self.Frame

	local Label = Instance.new("TextLabel")
	Label.BackgroundTransparency = 1
	Label.Size = UDim2.new(1, -40, 0, 26)
	Label.Font = Enum.Font.Gotham
	Label.TextSize = 14
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Text = text
	Label.Parent = Container
	reg(window.ThemedInstances, Label, "TextColor3", function() return Theme.Text end)

	local Swatch = Instance.new("TextButton")
	Swatch.AutoButtonColor = false
	Swatch.Text = ""
	Swatch.Size = UDim2.fromOffset(28, 16)
	Swatch.Position = UDim2.new(1, -28, 0, 5)
	Swatch.BackgroundColor3 = default
	Swatch.Parent = Container
	corner(Swatch, 4)
	reg(window.ThemedInstances, stroke(Swatch, Theme.Stroke, 1), "Color", function() return Theme.Stroke end)

	local Popup = Instance.new("Frame")
	Popup.Position = UDim2.new(0, 0, 0, 30)
	Popup.Size = UDim2.new(1, 0, 0, 0)
	Popup.BackgroundTransparency = 1
	Popup.ClipsDescendants = true
	Popup.Visible = false
	Popup.ZIndex = 5
	Popup.Parent = Container

	local SV = Instance.new("Frame")
	SV.Size = UDim2.new(1, -24, 0, 100)
	SV.Position = UDim2.new(0, 0, 0, 0)
	SV.ZIndex = 6
	SV.Parent = Popup
	corner(SV, 4)

	local whiteOv = Instance.new("Frame")
	whiteOv.Size = UDim2.fromScale(1, 1)
	whiteOv.BackgroundColor3 = Color3.new(1, 1, 1)
	whiteOv.BorderSizePixel = 0
	whiteOv.ZIndex = 6
	whiteOv.Parent = SV
	corner(whiteOv, 4)
	local wg = Instance.new("UIGradient")
	wg.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	wg.Parent = whiteOv

	local blackOv = Instance.new("Frame")
	blackOv.Size = UDim2.fromScale(1, 1)
	blackOv.BackgroundColor3 = Color3.new(0, 0, 0)
	blackOv.BorderSizePixel = 0
	blackOv.ZIndex = 6
	blackOv.Parent = SV
	corner(blackOv, 4)
	local bg = Instance.new("UIGradient")
	bg.Rotation = 90
	bg.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
	bg.Parent = blackOv

	local svCursor = Instance.new("Frame")
	svCursor.Size = UDim2.fromOffset(6, 6)
	svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
	svCursor.BackgroundColor3 = Color3.new(1, 1, 1)
	svCursor.BorderSizePixel = 0
	svCursor.ZIndex = 7
	svCursor.Parent = SV
	corner(svCursor, 3)
	stroke(svCursor, Color3.new(0, 0, 0), 1)

	local svCatcher = Instance.new("TextButton")
	svCatcher.AutoButtonColor = false
	svCatcher.Text = ""
	svCatcher.BackgroundTransparency = 1
	svCatcher.Size = UDim2.fromScale(1, 1)
	svCatcher.ZIndex = 8
	svCatcher.Parent = SV

	local Hue = Instance.new("Frame")
	Hue.Size = UDim2.new(0, 16, 0, 100)
	Hue.Position = UDim2.new(1, -16, 0, 0)
	Hue.BorderSizePixel = 0
	Hue.ZIndex = 6
	Hue.Parent = Popup
	corner(Hue, 4)
	local hg = Instance.new("UIGradient")
	hg.Rotation = 90
	hg.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
		ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
		ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
	})
	hg.Parent = Hue

	local hueCursor = Instance.new("Frame")
	hueCursor.Size = UDim2.new(1, 2, 0, 3)
	hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
	hueCursor.Position = UDim2.new(0.5, 0, 0, 0)
	hueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
	hueCursor.BorderSizePixel = 0
	hueCursor.ZIndex = 7
	hueCursor.Parent = Hue
	stroke(hueCursor, Color3.new(0, 0, 0), 1)

	local hueCatcher = Instance.new("TextButton")
	hueCatcher.AutoButtonColor = false
	hueCatcher.Text = ""
	hueCatcher.BackgroundTransparency = 1
	hueCatcher.Size = UDim2.fromScale(1, 1)
	hueCatcher.ZIndex = 8
	hueCatcher.Parent = Hue

	local function getColor() return Color3.fromHSV(h, s, v) end
	local function refresh()
		SV.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svCursor.Position = UDim2.fromScale(s, 1 - v)
		hueCursor.Position = UDim2.new(0.5, 0, h, 0)
		Swatch.BackgroundColor3 = getColor()
	end
	refresh()

	local function fireColor()
		if flag then window.Flags[flag] = getColor() end
		safeCall(callback, getColor())
	end

	local function set(color, fire)
		h, s, v = Color3.toHSV(color)
		refresh()
		if flag then window.Flags[flag] = getColor() end
		if fire ~= false then safeCall(callback, getColor()) end
	end

	local function updateSV(pos)
		s = math.clamp((pos.X - SV.AbsolutePosition.X) / math.max(SV.AbsoluteSize.X, 1), 0, 1)
		v = 1 - math.clamp((pos.Y - SV.AbsolutePosition.Y) / math.max(SV.AbsoluteSize.Y, 1), 0, 1)
		refresh()
		fireColor()
	end
	local function updateHue(pos)
		h = math.clamp((pos.Y - Hue.AbsolutePosition.Y) / math.max(Hue.AbsoluteSize.Y, 1), 0, 1)
		refresh()
		fireColor()
	end

	local svDrag, hueDrag = false, false
	track(window.Connections, svCatcher.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			svDrag = true
			updateSV(input.Position)
		end
	end))
	track(window.Connections, hueCatcher.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			hueDrag = true
			updateHue(input.Position)
		end
	end))
	track(window.Connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			svDrag = false
			hueDrag = false
		end
	end))
	track(window.Connections, UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			if svDrag then updateSV(input.Position)
			elseif hueDrag then updateHue(input.Position) end
		end
	end))

	local open = false
	local popupHeight = 108
	local function setOpen(o)
		open = o
		if o then Popup.Visible = true end
		tween(Popup, TweenInfo.new(0.15), {Size = UDim2.new(1, 0, 0, o and popupHeight or 0)})
		tween(Container, TweenInfo.new(0.15), {Size = UDim2.new(1, 0, 0, 26 + (o and (popupHeight + 6) or 0))})
		if not o then
			task.delay(0.15, function() if not open then Popup.Visible = false end end)
		end
	end
	track(window.Connections, Swatch.MouseButton1Click:Connect(function() setOpen(not open) end))

	if flag then
		window.Flags[flag] = getColor()
		window.FlagSetters[flag] = function(c) set(c, true) end
	end
	window:_registerElement(text, Container, self.Frame)

	return {
		Set = function(_, c) set(c, false) end,
		Get = function() return getColor() end,
		Close = function() setOpen(false) end,
	}
end

-- ---- Keybind ----
function Section:AddKeybind(text, default, callback, opts)
	opts = opts or {}
	local flag = opts.Flag
	local window = self.Window
	local Theme = window.Theme

	local Row = Instance.new("Frame")
	Row.Size = UDim2.new(1, 0, 0, 26)
	Row.BackgroundTransparency = 1
	Row.LayoutOrder = self:_order()
	Row.Parent = self.Frame

	local Label = Instance.new("TextLabel")
	Label.BackgroundTransparency = 1
	Label.Size = UDim2.new(1, -80, 1, 0)
	Label.Font = Enum.Font.Gotham
	Label.TextSize = 14
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Text = text
	Label.Parent = Row
	reg(window.ThemedInstances, Label, "TextColor3", function() return Theme.Text end)

	local KeyBtn = Instance.new("TextButton")
	KeyBtn.AutoButtonColor = false
	KeyBtn.Position = UDim2.new(1, -76, 0.5, -11)
	KeyBtn.Size = UDim2.fromOffset(76, 22)
	KeyBtn.Font = Enum.Font.GothamMedium
	KeyBtn.TextSize = 12
	KeyBtn.Text = default and default.Name or "..."
	KeyBtn.Parent = Row
	corner(KeyBtn, 5)
	reg(window.ThemedInstances, KeyBtn, "BackgroundColor3", function() return Theme.Element end)
	reg(window.ThemedInstances, KeyBtn, "TextColor3", function() return Theme.Text end)

	local current = default
	local updateListRow = window:_addKeybindRow(text, current and current.Name or "...")

	local function applyKey(keyCode, fire)
		current = keyCode
		KeyBtn.Text = keyCode and keyCode.Name or "..."
		updateListRow(KeyBtn.Text)
		if flag then window.Flags[flag] = keyCode end
		if fire ~= false then safeCall(callback, keyCode) end
	end

	track(window.Connections, KeyBtn.MouseButton1Click:Connect(function()
		KeyBtn.Text = "..."
		window:CaptureNextKey(function(kc) applyKey(kc, true) end)
	end))

	if flag then
		window.Flags[flag] = current
		window.FlagSetters[flag] = function(k) applyKey(k, true) end
	end
	window:_registerElement(text, Row, self.Frame)

	return {
		Set = function(_, k) applyKey(k, false) end,
		Get = function() return current end,
	}
end

return Library
