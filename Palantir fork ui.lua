--[[
    CustomLib_TopTabs (v4)

    Новое в этой версии:
      - Структура колонок как на скриншоте: у левой и правой половины
        главной вкладки — СВОИ, независимые ряды под-вкладок
        (MainTab:AddLeftTabs() / MainTab:AddRightTabs()), а не один общий
        ряд на обе колонки, как раньше.
      - Под-вкладки теперь в стиле "текст + подчёркивание", как основные —
        визуально ближе к скриншоту, чем прежние "таблетки".
      - Своя тема через UI: Section:AddColorPicker(...) + Window:RegisterCustomTheme(...).
      - Система конфигов: Window:SaveConfig(name) / LoadConfig(name) / ListConfigs()
        сохраняет значения тоглов/слайдеров/дропдаунов (по "флагу") и текущую
        тему в файл через writefile/readfile (стандартный подход для
        исполнителей; если этих функций нет в окружении — методы вернут
        false с понятной причиной вместо ошибки).
]]

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ====================== ТЕМЫ ======================
local FixedColors = {
    Text     = Color3.fromRGB(198, 198, 203),
    SubText  = Color3.fromRGB(126, 126, 134),
    Disabled = Color3.fromRGB(78, 78, 84),
    White    = Color3.fromRGB(255, 255, 255),
}

local BUILTIN_THEME_NAMES = { "Monochrome", "Crimson", "Ocean", "Violet", "Emerald" }

local Themes = {
    Monochrome = {
        Background = Color3.fromRGB(14, 14, 16), TopBar = Color3.fromRGB(19, 19, 22),
        Section = Color3.fromRGB(21, 21, 24), Element = Color3.fromRGB(31, 31, 35),
        Accent = Color3.fromRGB(255, 255, 255), Stroke = Color3.fromRGB(44, 44, 50),
    },
    Crimson = {
        Background = Color3.fromRGB(16, 12, 13), TopBar = Color3.fromRGB(22, 16, 17),
        Section = Color3.fromRGB(24, 17, 18), Element = Color3.fromRGB(36, 24, 25),
        Accent = Color3.fromRGB(230, 70, 70), Stroke = Color3.fromRGB(50, 32, 33),
    },
    Ocean = {
        Background = Color3.fromRGB(11, 14, 17), TopBar = Color3.fromRGB(15, 19, 23),
        Section = Color3.fromRGB(17, 21, 26), Element = Color3.fromRGB(26, 32, 39),
        Accent = Color3.fromRGB(80, 160, 255), Stroke = Color3.fromRGB(35, 44, 53),
    },
    Violet = {
        Background = Color3.fromRGB(15, 13, 17), TopBar = Color3.fromRGB(20, 17, 23),
        Section = Color3.fromRGB(22, 19, 25), Element = Color3.fromRGB(33, 28, 38),
        Accent = Color3.fromRGB(170, 110, 255), Stroke = Color3.fromRGB(47, 40, 54),
    },
    Emerald = {
        Background = Color3.fromRGB(12, 15, 13), TopBar = Color3.fromRGB(17, 21, 18),
        Section = Color3.fromRGB(19, 23, 20), Element = Color3.fromRGB(28, 34, 29),
        Accent = Color3.fromRGB(80, 210, 120), Stroke = Color3.fromRGB(40, 49, 42),
    },
}

local Theme = {}
for k, v in pairs(FixedColors) do Theme[k] = v end
for k, v in pairs(Themes.Monochrome) do Theme[k] = v end

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
    s.Color = color or Theme.Stroke
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
    if horizontal then l.FillDirection = Enum.FillDirection.Horizontal end
    l.Parent = parent
    return l
end

local function track(list, conn)
    table.insert(list, conn)
    return conn
end

local function reg(list, instance, prop, getter)
    instance[prop] = getter()
    if list then table.insert(list, {Instance = instance, Prop = prop, Getter = getter}) end
    return instance
end

-- Color3 <-> обычная таблица (для сохранения в JSON: HttpService:JSONEncode не умеет Color3)
local function encodeValue(v)
    if typeof(v) == "Color3" then
        return {__color = true, R = math.floor(v.R * 255 + 0.5), G = math.floor(v.G * 255 + 0.5), B = math.floor(v.B * 255 + 0.5)}
    end
    return v
end
local function decodeValue(v)
    if type(v) == "table" and v.__color then
        return Color3.fromRGB(v.R, v.G, v.B)
    end
    return v
end

-- ====================== МЕТАТАБЛИЦЫ КЛАССОВ ======================
local Window    = {}; Window.__index = Window
local MainTab   = {}; MainTab.__index = MainTab
local TabGroup  = {}; TabGroup.__index = TabGroup
local Page      = {}; Page.__index = Page
local Section   = {}; Section.__index = Section

local Library = {}
Library.Themes = Themes
Library.ThemeNames = { "Monochrome", "Crimson", "Ocean", "Violet", "Emerald" }

-- ====================== ОКНО ======================
function Library:CreateWindow(config)
    config = config or {}
    local title    = config.Title or "Menu"
    local subtitle = config.Subtitle or ""
    local size     = config.Size or UDim2.fromOffset(700, 520)

    local themedList = {}

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "CustomLibTopTabsGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999
    local ok = pcall(function() ScreenGui.Parent = CoreGui end)
    if not ok or not ScreenGui.Parent then ScreenGui.Parent = PlayerGui end

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

    -- ---- Шапка ----
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
    SubtitleLabel.Size = UDim2.new(0, 320, 1, 0)
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

    local connections = {}
    track(connections, CloseBtn.MouseEnter:Connect(function() tween(CloseBtn, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(230, 90, 90)}) end))
    track(connections, CloseBtn.MouseLeave:Connect(function() tween(CloseBtn, TweenInfo.new(0.15), {TextColor3 = Theme.SubText}) end))

    do
        local dragging, dragStart, startPos
        track(connections, TopBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true; dragStart = input.Position; startPos = Main.Position
                input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
            end
        end))
        track(connections, UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end))
    end

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
        ScreenGui = ScreenGui, Main = Main, UIScale = UIScale,
        MainTabBar = MainTabBar, ContentHost = ContentHost,
        MainTabs = {}, CurrentMainTab = nil, Visible = true, OriginalSize = size,
        Connections = connections, ThemedInstances = themedList,
        CurrentThemeName = "Monochrome",
        ToggleKey = config.ToggleKey or Enum.KeyCode.RightControl,
        KeybindListFrame = nil, KeybindRows = {},
        Flags = {},
        ConfigNamespace = config.ConfigFolder or title:gsub("%s+", ""),
    }, Window)

    CloseBtn.MouseButton1Click:Connect(function() self:SetVisible(false) end)
    track(self.Connections, UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == self.ToggleKey then self:SetVisible(not self.Visible) end
    end))

    Main.Size = UDim2.new(size.X.Scale, size.X.Offset, size.Y.Scale, math.floor(size.Y.Offset * 0.85))
    Main.BackgroundTransparency = 1
    tween(Main, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = size, BackgroundTransparency = 0})

    self:LoadCustomThemes()

    return self
end

function Window:SetVisible(state)
    self.Visible = state
    local size = self.OriginalSize
    if state then
        self.ScreenGui.Enabled = true
        self.Main.Size = UDim2.new(size.X.Scale, size.X.Offset, size.Y.Scale, math.floor(size.Y.Offset * 0.9))
        self.Main.BackgroundTransparency = 1
        tween(self.Main, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = size, BackgroundTransparency = 0})
    else
        local t = tween(self.Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1})
        t.Completed:Connect(function() if not self.Visible then self.ScreenGui.Enabled = false end end)
    end
end

-- ---- Темы ----
function Window:SetTheme(name)
    local preset = Themes[name]
    if not preset then return end
    for k, v in pairs(preset) do Theme[k] = v end
    for _, entry in ipairs(self.ThemedInstances) do
        pcall(function() tween(entry.Instance, TweenInfo.new(0.2), {[entry.Prop] = entry.Getter()}) end)
    end
    self.CurrentThemeName = name
end

function Window:RegisterCustomTheme(name, colors)
    Themes[name] = colors
    local exists = false
    for _, n in ipairs(Library.ThemeNames) do if n == name then exists = true break end end
    if not exists then table.insert(Library.ThemeNames, name) end
end

function Window:SaveCustomThemes()
    if not writefile then return false, "writefile недоступен в этом окружении" end
    local folder = self:GetConfigFolder()
    if not (isfolder and isfolder(folder)) then pcall(makefolder, folder) end
    local out = {}
    for _, name in ipairs(Library.ThemeNames) do
        local isBuiltin = false
        for _, b in ipairs(BUILTIN_THEME_NAMES) do if b == name then isBuiltin = true break end end
        if not isBuiltin then
            local p = {}
            for k, v in pairs(Themes[name]) do p[k] = encodeValue(v) end
            out[name] = p
        end
    end
    local ok, encoded = pcall(function() return HttpService:JSONEncode(out) end)
    if not ok then return false, "Ошибка кодирования" end
    pcall(writefile, folder .. "/CustomThemes.json", encoded)
    return true
end

function Window:LoadCustomThemes()
    if not readfile then return end
    local path = self:GetConfigFolder() .. "/CustomThemes.json"
    if not (isfile and isfile(path)) then return end
    local ok, raw = pcall(readfile, path)
    if not ok then return end
    local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 or type(data) ~= "table" then return end
    for name, palette in pairs(data) do
        local p = {}
        for k, v in pairs(palette) do p[k] = decodeValue(v) end
        self:RegisterCustomTheme(name, p)
    end
end

-- ---- Конфиги ----
function Window:GetConfigFolder()
    return "CustomLibConfigs/" .. self.ConfigNamespace
end

function Window:SaveConfig(name)
    if not writefile then return false, "writefile недоступен в этом окружении" end
    if not name or name == "" then return false, "Пустое имя конфига" end
    local folder = self:GetConfigFolder()
    if not (isfolder and isfolder(folder)) then pcall(makefolder, folder) end
    local data = { Theme = self.CurrentThemeName, Flags = {} }
    for flag, entry in pairs(self.Flags) do
        data.Flags[flag] = encodeValue(entry.Get())
    end
    local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
    if not ok then return false, "Ошибка кодирования" end
    pcall(writefile, folder .. "/" .. name .. ".json", encoded)
    return true
end

function Window:LoadConfig(name)
    if not readfile then return false, "readfile недоступен в этом окружении" end
    local path = self:GetConfigFolder() .. "/" .. name .. ".json"
    if not (isfile and isfile(path)) then return false, "Конфиг не найден" end
    local ok, raw = pcall(readfile, path)
    if not ok then return false, "Ошибка чтения файла" end
    local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 or type(data) ~= "table" then return false, "Ошибка декодирования" end
    if data.Theme and Themes[data.Theme] then self:SetTheme(data.Theme) end
    if data.Flags then
        for flag, value in pairs(data.Flags) do
            local entry = self.Flags[flag]
            if entry then entry.Set(decodeValue(value)) end
        end
    end
    return true
end

function Window:ListConfigs()
    if not (isfolder and listfiles) then return {} end
    local folder = self:GetConfigFolder()
    if not isfolder(folder) then return {} end
    local names = {}
    local ok, files = pcall(listfiles, folder)
    if ok then
        for _, path in ipairs(files) do
            local fname = path:match("([^/\\]+)%.json$")
            if fname and fname ~= "CustomThemes" then table.insert(names, fname) end
        end
    end
    return names
end

-- ---- Прочие настройки самого меню ----
function Window:SetToggleKey(keyCode) self.ToggleKey = keyCode end

function Window:CaptureNextKey(callback)
    local conn
    conn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            conn:Disconnect()
            if callback then callback(input.KeyCode) end
        end
    end)
    track(self.Connections, conn)
end

function Window:SetUIScale(percent) tween(self.UIScale, TweenInfo.new(0.15), {Scale = percent / 100}) end

function Window:ResetPosition()
    tween(self.Main, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.5)})
end

function Window:Destroy()
    for _, conn in ipairs(self.Connections) do pcall(function() conn:Disconnect() end) end
    local t = tween(self.Main, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1})
    t.Completed:Connect(function() self.ScreenGui:Destroy() end)
end

-- ---- Список кейбиндов ----
function Window:_ensureKeybindList()
    if self.KeybindListFrame then return end
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

    do
        local dragging, dragStart, startPos
        track(self.Connections, Frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true; dragStart = input.Position; startPos = Frame.Position
                input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
            end
        end))
        track(self.Connections, UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end))
    end
    self.KeybindListFrame = Frame
end

function Window:SetKeybindListVisible(state)
    self:_ensureKeybindList()
    self.KeybindListFrame.Visible = state
end

function Window:_addKeybindRow(label, initialKeyName)
    self:_ensureKeybindList()
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
    return function(newKeyName) Row.Text = label .. ": " .. newKeyName end
end

-- ====================== ГЛАВНЫЕ ВКЛАДКИ ======================
function Window:AddMainTab(name)
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

    -- Вертикальный разделитель между будущими левой/правой колонками
    local Divider = Instance.new("Frame")
    Divider.AnchorPoint = Vector2.new(0.5, 0)
    Divider.Position = UDim2.new(0.5, 0, 0, 4)
    Divider.Size = UDim2.new(0, 1, 1, -8)
    Divider.BorderSizePixel = 0
    Divider.Parent = Host
    reg(self.ThemedInstances, Divider, "BackgroundColor3", function() return Theme.Stroke end)

    local windowRef = self
    local tabObj = setmetatable({
        Window = windowRef, Button = Btn, Underline = UnderlineBar, Host = Host,
    }, MainTab)

    table.insert(self.MainTabs, tabObj)

    reg(self.ThemedInstances, Btn, "TextColor3", function()
        return (windowRef.CurrentMainTab == tabObj) and Theme.Accent or Theme.SubText
    end)

    track(self.Connections, Btn.MouseButton1Click:Connect(function() windowRef:SelectMainTab(tabObj) end))
    track(self.Connections, Btn.MouseEnter:Connect(function()
        if windowRef.CurrentMainTab ~= tabObj then tween(Btn, TweenInfo.new(0.15), {TextColor3 = Theme.Text}) end
    end))
    track(self.Connections, Btn.MouseLeave:Connect(function()
        if windowRef.CurrentMainTab ~= tabObj then tween(Btn, TweenInfo.new(0.15), {TextColor3 = Theme.SubText}) end
    end))

    if not self.CurrentMainTab then self:SelectMainTab(tabObj) end
    return tabObj
end

function Window:SelectMainTab(tab)
    if self.CurrentMainTab == tab then return end
    local old = self.CurrentMainTab
    self.CurrentMainTab = tab
    if old then
        tween(old.Button, TweenInfo.new(0.15), {TextColor3 = Theme.SubText})
        old.Host.Visible = false
        tween(old.Underline, TweenInfo.new(0.15), {Size = UDim2.new(0, 0, 0, 2), BackgroundTransparency = 1})
    end
    tween(tab.Button, TweenInfo.new(0.15), {TextColor3 = Theme.Accent})
    tab.Host.Visible = true
    tween(tab.Underline, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 2), BackgroundTransparency = 0})
end

-- ====================== НЕЗАВИСИМЫЕ ГРУППЫ ПОД-ВКЛАДОК (лево/право) ======================
function MainTab:AddLeftTabs()
    return self:_addTabGroup(0, 0)
end

function MainTab:AddRightTabs()
    return self:_addTabGroup(0.5, 6)
end

function MainTab:_addTabGroup(xScale, xOffset)
    local window = self.Window

    local Root = Instance.new("Frame")
    Root.Position = UDim2.new(xScale, xOffset, 0, 0)
    Root.Size = UDim2.new(0.5, -6, 1, 0) -- половина ширины минус зазор у центрального разделителя
    Root.BackgroundTransparency = 1
    Root.Parent = self.Host

    local TabBar = Instance.new("Frame")
    TabBar.Size = UDim2.new(1, 0, 0, 24)
    TabBar.BackgroundTransparency = 1
    TabBar.Parent = Root
    local tabBarList = listLayout(TabBar, 18, true)

    local Divider = Instance.new("Frame")
    Divider.Position = UDim2.new(0, 0, 0, 26)
    Divider.Size = UDim2.new(1, 0, 0, 1)
    Divider.BorderSizePixel = 0
    Divider.Parent = Root
    reg(window.ThemedInstances, Divider, "BackgroundColor3", function() return Theme.Stroke end)

    local ContentHost = Instance.new("Frame")
    ContentHost.Position = UDim2.new(0, 0, 0, 34)
    ContentHost.Size = UDim2.new(1, 0, 1, -34)
    ContentHost.BackgroundTransparency = 1
    ContentHost.ClipsDescendants = true
    ContentHost.Parent = Root

    local group = setmetatable({
        Window = window, TabBar = TabBar, ContentHost = ContentHost, Pages = {}, CurrentPage = nil,
    }, TabGroup)

    return group
end

function TabGroup:AddTab(name)
    local window = self.Window

    local Btn = Instance.new("TextButton")
    Btn.BackgroundTransparency = 1
    Btn.Size = UDim2.fromOffset(0, 24)
    Btn.AutomaticSize = Enum.AutomaticSize.X
    Btn.Font = Enum.Font.Gotham
    Btn.TextSize = 13
    Btn.TextColor3 = Theme.SubText
    Btn.Text = name
    Btn.Parent = self.TabBar

    local UnderlineBar = Instance.new("Frame")
    UnderlineBar.AnchorPoint = Vector2.new(0.5, 0)
    UnderlineBar.Position = UDim2.new(0.5, 0, 1, 3)
    UnderlineBar.Size = UDim2.new(0, 0, 0, 2)
    UnderlineBar.BackgroundTransparency = 1
    UnderlineBar.BorderSizePixel = 0
    UnderlineBar.Parent = Btn
    reg(window.ThemedInstances, UnderlineBar, "BackgroundColor3", function() return Theme.Accent end)

    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.fromScale(1, 1)
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.BorderSizePixel = 0
    ScrollFrame.ScrollBarThickness = 3
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ScrollFrame.Visible = false
    ScrollFrame.Parent = self.ContentHost
    listLayout(ScrollFrame, 10)
    reg(window.ThemedInstances, ScrollFrame, "ScrollBarImageColor3", function() return Theme.Accent end)

    local groupRef = self
    local pageObj = setmetatable({
        Window = window, TabGroup = groupRef, Button = Btn, Underline = UnderlineBar, ScrollFrame = ScrollFrame, Order = 0,
    }, Page)

    table.insert(self.Pages, pageObj)

    reg(window.ThemedInstances, Btn, "TextColor3", function()
        return (groupRef.CurrentPage == pageObj) and Theme.Accent or Theme.SubText
    end)

    track(window.Connections, Btn.MouseButton1Click:Connect(function() groupRef:SelectPage(pageObj) end))
    track(window.Connections, Btn.MouseEnter:Connect(function()
        if groupRef.CurrentPage ~= pageObj then tween(Btn, TweenInfo.new(0.15), {TextColor3 = Theme.Text}) end
    end))
    track(window.Connections, Btn.MouseLeave:Connect(function()
        if groupRef.CurrentPage ~= pageObj then tween(Btn, TweenInfo.new(0.15), {TextColor3 = Theme.SubText}) end
    end))

    if not self.CurrentPage then self:SelectPage(pageObj) end
    return pageObj
end

function TabGroup:SelectPage(page)
    if self.CurrentPage == page then return end
    local old = self.CurrentPage
    self.CurrentPage = page
    if old then
        tween(old.Button, TweenInfo.new(0.15), {TextColor3 = Theme.SubText})
        old.ScrollFrame.Visible = false
        tween(old.Underline, TweenInfo.new(0.12), {Size = UDim2.new(0, 0, 0, 2), BackgroundTransparency = 1})
    end
    tween(page.Button, TweenInfo.new(0.15), {TextColor3 = Theme.Accent})
    page.ScrollFrame.Visible = true
    tween(page.Underline, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 2), BackgroundTransparency = 0})
end

-- ====================== СЕКЦИИ ======================
local function buildSection(parent, name, window)
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

    local Title = Instance.new("TextLabel")
    Title.BackgroundTransparency = 1
    Title.Size = UDim2.new(1, 0, 0, 18)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 13
    Title.TextColor3 = Theme.SubText
    Title.Text = name
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.LayoutOrder = 0
    Title.Parent = Frame

    return setmetatable({ Frame = Frame, Order = 1, Window = window }, Section)
end

function Page:AddSection(name)
    return buildSection(self.ScrollFrame, name, self.Window)
end

function Section:_order()
    self.Order = self.Order + 1
    return self.Order
end

-- ---- Toggle (третий необязательный параметр flag регистрирует значение для конфигов) ----
function Section:AddToggle(text, default, callback, flag)
    default = default or false
    local window = self.Window

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
    reg(window.ThemedInstances, Knob, "BackgroundColor3", function() return state and Color3.fromRGB(20, 20, 20) or Theme.White end)
    reg(window.ThemedInstances, Label, "TextColor3", function() return state and Theme.Accent or Theme.Text end)

    local function applyVisual(animate)
        local trackColor = state and Theme.Accent or Theme.Element
        local knobColor = state and Color3.fromRGB(20, 20, 20) or Theme.White
        local knobPos = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
        local textColor = state and Theme.Accent or Theme.Text
        if animate then
            tween(Track, TweenInfo.new(0.15), {BackgroundColor3 = trackColor})
            tween(Knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Position = knobPos, BackgroundColor3 = knobColor})
            tween(Label, TweenInfo.new(0.15), {TextColor3 = textColor})
        else
            Track.BackgroundColor3 = trackColor; Knob.Position = knobPos
            Knob.BackgroundColor3 = knobColor; Label.TextColor3 = textColor
        end
    end
    applyVisual(false)

    local function set(v, fire)
        state = v
        applyVisual(true)
        if fire ~= false and callback then callback(state) end
    end

    Row.MouseButton1Click:Connect(function() set(not state) end)

    if flag then
        window.Flags[flag] = { Get = function() return state end, Set = function(v) set(v, true) end }
    end

    return { Set = function(_, v) set(v, false) end, Get = function() return state end }
end

-- ---- Placeholder ----
function Section:AddPlaceholder(text)
    local window = self.Window
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 26)
    Row.BackgroundTransparency = 1
    Row.LayoutOrder = self:_order()
    Row.Parent = self.Frame

    local Track = Instance.new("Frame")
    Track.Size = UDim2.fromOffset(32, 16)
    Track.Position = UDim2.new(0, 0, 0.5, -8)
    Track.BackgroundTransparency = 0.4
    Track.Parent = Row
    corner(Track, 8)
    reg(window.ThemedInstances, Track, "BackgroundColor3", function() return Theme.Element end)

    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 40, 0, 0)
    Label.Size = UDim2.new(1, -70, 1, 0)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 14
    Label.TextColor3 = Theme.Disabled
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Text = text
    Label.Parent = Row

    local NA = Instance.new("TextLabel")
    NA.BackgroundTransparency = 1
    NA.Position = UDim2.new(1, -40, 0, 0)
    NA.Size = UDim2.new(0, 40, 1, 0)
    NA.Font = Enum.Font.Gotham
    NA.TextSize = 12
    NA.TextColor3 = Theme.Disabled
    NA.TextXAlignment = Enum.TextXAlignment.Right
    NA.Text = "N/A"
    NA.Parent = Row
    return Row
end

-- ---- Slider ----
function Section:AddSlider(text, min, max, default, unit, callback, flag)
    min = min or 0; max = max or 100
    default = math.clamp(default or min, min, max)
    unit = unit or ""
    local window = self.Window

    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 40)
    Container.BackgroundTransparency = 1
    Container.LayoutOrder = self:_order()
    Container.Parent = self.Frame

    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Size = UDim2.new(1, 0, 0, 16)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 13
    Label.TextColor3 = Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Text = text
    Label.Parent = Container

    local Bar = Instance.new("Frame")
    Bar.Position = UDim2.new(0, 0, 0, 20)
    Bar.Size = UDim2.new(1, 0, 0, 18)
    Bar.Parent = Container
    corner(Bar, 4)
    reg(window.ThemedInstances, Bar, "BackgroundColor3", function() return Theme.Element end)

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.fromScale((default - min) / (max - min), 1)
    Fill.Parent = Bar
    corner(Fill, 4)
    reg(window.ThemedInstances, Fill, "BackgroundColor3", function() return Theme.Accent end)

    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Size = UDim2.fromScale(1, 1)
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.TextSize = 12
    ValueLabel.TextColor3 = Color3.fromRGB(20, 20, 20)
    ValueLabel.Text = tostring(default) .. unit .. "/" .. tostring(max) .. unit
    ValueLabel.ZIndex = 2
    ValueLabel.Parent = Bar

    local current = default
    local function apply(value, fire, animate)
        value = math.clamp(value, min, max)
        current = value
        local rel = (value - min) / (max - min)
        if animate then
            tween(Fill, TweenInfo.new(0.05), {Size = UDim2.fromScale(rel, 1)})
        else
            Fill.Size = UDim2.fromScale(rel, 1)
        end
        ValueLabel.Text = tostring(math.floor(value)) .. unit .. "/" .. tostring(max) .. unit
        ValueLabel.TextColor3 = (rel > 0.15) and Color3.fromRGB(20, 20, 20) or Theme.Text
        if fire ~= false and callback then callback(value) end
    end

    local dragging = false
    local function updateFromInput(inputPos)
        local rel = math.clamp((inputPos.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
        apply(min + (max - min) * rel, true, true)
    end

    Bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; updateFromInput(input.Position)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromInput(input.Position)
        end
    end)

    if flag then
        window.Flags[flag] = { Get = function() return current end, Set = function(v) apply(v, true, true) end }
    end

    return { Instance = Container, Set = function(_, v) apply(v, false, true) end, Get = function() return current end }
end

-- ---- Dropdown ----
function Section:AddDropdown(text, options, default, callback, flag)
    options = options or {}
    default = default or options[1] or ""
    local window = self.Window

    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 40)
    Container.BackgroundTransparency = 1
    Container.ClipsDescendants = false
    Container.LayoutOrder = self:_order()
    Container.Parent = self.Frame

    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Size = UDim2.new(1, 0, 0, 16)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 13
    Label.TextColor3 = Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Text = text
    Label.Parent = Container

    local Head = Instance.new("TextButton")
    Head.Position = UDim2.new(0, 0, 0, 20)
    Head.Size = UDim2.new(1, 0, 0, 20)
    Head.AutoButtonColor = false
    Head.Text = ""
    Head.Parent = Container
    corner(Head, 5)
    reg(window.ThemedInstances, Head, "BackgroundColor3", function() return Theme.Element end)

    local SelectedLabel = Instance.new("TextLabel")
    SelectedLabel.BackgroundTransparency = 1
    SelectedLabel.Position = UDim2.new(0, 8, 0, 0)
    SelectedLabel.Size = UDim2.new(1, -28, 1, 0)
    SelectedLabel.Font = Enum.Font.Gotham
    SelectedLabel.TextSize = 12
    SelectedLabel.TextColor3 = Theme.Text
    SelectedLabel.TextXAlignment = Enum.TextXAlignment.Left
    SelectedLabel.Text = tostring(default)
    SelectedLabel.Parent = Head

    local Arrow = Instance.new("TextLabel")
    Arrow.BackgroundTransparency = 1
    Arrow.Position = UDim2.new(1, -20, 0, 0)
    Arrow.Size = UDim2.fromOffset(20, 20)
    Arrow.Font = Enum.Font.GothamBold
    Arrow.TextSize = 12
    Arrow.TextColor3 = Theme.SubText
    Arrow.Text = "▾"
    Arrow.Parent = Head

    local List = Instance.new("Frame")
    List.Position = UDim2.new(0, 0, 0, 44)
    List.Size = UDim2.new(1, 0, 0, 0)
    List.ClipsDescendants = true
    List.Visible = false
    List.ZIndex = 5
    List.Parent = Container
    corner(List, 5)
    reg(window.ThemedInstances, List, "BackgroundColor3", function() return Theme.Element end)
    listLayout(List, 0)

    local open = false
    local listHeight = #options * 22
    local current = default

    local function close()
        open = false
        tween(Arrow, TweenInfo.new(0.15), {Rotation = 0})
        tween(Container, TweenInfo.new(0.15), {Size = UDim2.new(1, 0, 0, 40)})
        local t = tween(List, TweenInfo.new(0.15), {Size = UDim2.new(1, 0, 0, 0)})
        t.Completed:Connect(function() if not open then List.Visible = false end end)
    end

    local function selectOption(opt, fire)
        current = opt
        SelectedLabel.Text = tostring(opt)
        close()
        if fire ~= false and callback then callback(opt) end
    end

    for i, opt in ipairs(options) do
        local OptBtn = Instance.new("TextButton")
        OptBtn.Size = UDim2.new(1, 0, 0, 22)
        OptBtn.LayoutOrder = i
        OptBtn.BackgroundTransparency = 1
        OptBtn.Font = Enum.Font.Gotham
        OptBtn.TextSize = 12
        OptBtn.TextColor3 = Theme.SubText
        OptBtn.Text = tostring(opt)
        OptBtn.Parent = List
        OptBtn.MouseEnter:Connect(function() tween(OptBtn, TweenInfo.new(0.1), {TextColor3 = Theme.Accent}) end)
        OptBtn.MouseLeave:Connect(function() tween(OptBtn, TweenInfo.new(0.1), {TextColor3 = Theme.SubText}) end)
        OptBtn.MouseButton1Click:Connect(function() selectOption(opt, true) end)
    end

    Head.MouseButton1Click:Connect(function()
        open = not open
        if open then
            List.Visible = true
            tween(Arrow, TweenInfo.new(0.15), {Rotation = 180})
            tween(List, TweenInfo.new(0.15), {Size = UDim2.new(1, 0, 0, listHeight)})
            tween(Container, TweenInfo.new(0.15), {Size = UDim2.new(1, 0, 0, 40 + listHeight)})
        else
            close()
        end
    end)

    if flag then
        window.Flags[flag] = { Get = function() return current end, Set = function(v) selectOption(v, true) end }
    end

    return { Set = function(_, v) selectOption(v, false) end, Get = function() return current end, Close = close }
end

-- ---- Input (текстовое поле — для имён конфигов/тем и прочего) ----
function Section:AddInput(text, placeholder, default, callback)
    local window = self.Window
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 40)
    Container.BackgroundTransparency = 1
    Container.LayoutOrder = self:_order()
    Container.Parent = self.Frame

    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Size = UDim2.new(1, 0, 0, 16)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 13
    Label.TextColor3 = Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Text = text
    Label.Parent = Container

    local Box = Instance.new("TextBox")
    Box.Position = UDim2.new(0, 0, 0, 20)
    Box.Size = UDim2.new(1, 0, 0, 20)
    Box.ClearTextOnFocus = false
    Box.PlaceholderText = placeholder or ""
    Box.Text = default or ""
    Box.Font = Enum.Font.Gotham
    Box.TextSize = 12
    Box.TextColor3 = Theme.Text
    Box.PlaceholderColor3 = Theme.SubText
    Box.Parent = Container
    corner(Box, 5)
    reg(window.ThemedInstances, Box, "BackgroundColor3", function() return Theme.Element end)

    Box.FocusLost:Connect(function(enterPressed)
        if callback then callback(Box.Text, enterPressed) end
    end)

    return { Get = function() return Box.Text end, Set = function(_, v) Box.Text = v end }
end

-- ---- ColorPicker (3 мини-слайдера R/G/B + превью) — для создания своих тем ----
function Section:AddColorPicker(text, default, callback)
    default = default or Color3.fromRGB(255, 255, 255)
    local window = self.Window

    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 92)
    Container.BackgroundTransparency = 1
    Container.LayoutOrder = self:_order()
    Container.Parent = self.Frame

    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Size = UDim2.new(1, -24, 0, 16)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 13
    Label.TextColor3 = Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Text = text
    Label.Parent = Container

    local Swatch = Instance.new("Frame")
    Swatch.Position = UDim2.new(1, -18, 0, 0)
    Swatch.Size = UDim2.fromOffset(18, 16)
    Swatch.BackgroundColor3 = default
    Swatch.Parent = Container
    corner(Swatch, 4)
    reg(window.ThemedInstances, stroke(Swatch, Theme.Stroke, 1), "Color", function() return Theme.Stroke end)

    local r, g, b = default.R * 255, default.G * 255, default.B * 255

    local function makeChannel(labelText, yOffset, initial)
        local Row = Instance.new("Frame")
        Row.Position = UDim2.new(0, 0, 0, yOffset)
        Row.Size = UDim2.new(1, 0, 0, 20)
        Row.BackgroundTransparency = 1
        Row.Parent = Container

        local L = Instance.new("TextLabel")
        L.BackgroundTransparency = 1
        L.Size = UDim2.fromOffset(14, 20)
        L.Font = Enum.Font.GothamBold
        L.TextSize = 11
        L.TextColor3 = Theme.SubText
        L.Text = labelText
        L.Parent = Row

        local Bar = Instance.new("Frame")
        Bar.Position = UDim2.new(0, 18, 0, 3)
        Bar.Size = UDim2.new(1, -18, 0, 14)
        Bar.Parent = Row
        corner(Bar, 4)
        reg(window.ThemedInstances, Bar, "BackgroundColor3", function() return Theme.Element end)

        local Fill = Instance.new("Frame")
        Fill.Size = UDim2.fromScale(initial / 255, 1)
        Fill.BackgroundColor3 = Color3.fromRGB(200, 200, 205)
        Fill.Parent = Bar
        corner(Fill, 4)

        local value = initial
        local dragging = false
        local onChange

        local function set(v)
            value = math.clamp(v, 0, 255)
            Fill.Size = UDim2.fromScale(value / 255, 1)
            if onChange then onChange() end
        end

        Bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                set(((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X) * 255)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                set(((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X) * 255)
            end
        end)

        return {
            Get = function() return value end,
            Set = function(v) set(v) end,
            OnChange = function(fn) onChange = fn end,
        }
    end

    local rCh = makeChannel("R", 20, r)
    local gCh = makeChannel("G", 42, g)
    local bCh = makeChannel("B", 64, b)

    local current = default
    local function refresh()
        current = Color3.fromRGB(math.floor(rCh.Get()), math.floor(gCh.Get()), math.floor(bCh.Get()))
        Swatch.BackgroundColor3 = current
        if callback then callback(current) end
    end
    rCh.OnChange(refresh); gCh.OnChange(refresh); bCh.OnChange(refresh)

    return {
        Get = function() return current end,
        Set = function(_, color)
            rCh.Set(color.R * 255); gCh.Set(color.G * 255); bCh.Set(color.B * 255)
        end,
    }
end

-- ---- Button ----
function Section:AddButton(text, callback)
    local window = self.Window
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 28)
    Btn.AutoButtonColor = false
    Btn.Font = Enum.Font.Gotham
    Btn.TextSize = 13
    Btn.TextColor3 = Theme.Text
    Btn.Text = text
    Btn.LayoutOrder = self:_order()
    Btn.Parent = self.Frame
    corner(Btn, 6)
    reg(window.ThemedInstances, Btn, "BackgroundColor3", function() return Theme.Element end)

    Btn.MouseEnter:Connect(function() tween(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Accent, TextColor3 = Color3.fromRGB(20,20,20)}) end)
    Btn.MouseLeave:Connect(function() tween(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Element, TextColor3 = Theme.Text}) end)
    Btn.MouseButton1Click:Connect(function() if callback then callback() end end)
    return Btn
end

-- ---- Label ----
function Section:AddLabel(text)
    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Size = UDim2.new(1, 0, 0, 16)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 12
    Label.TextColor3 = Theme.SubText
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Text = text
    Label.LayoutOrder = self:_order()
    Label.Parent = self.Frame
    return Label
end

-- ---- Keybind ----
function Section:AddKeybind(text, window, default, callback)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 26)
    Container.BackgroundTransparency = 1
    Container.LayoutOrder = self:_order()
    Container.Parent = self.Frame

    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Size = UDim2.new(1, -80, 1, 0)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 14
    Label.TextColor3 = Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Text = text
    Label.Parent = Container

    local KeyBtn = Instance.new("TextButton")
    KeyBtn.Position = UDim2.new(1, -72, 0.5, -11)
    KeyBtn.Size = UDim2.fromOffset(72, 22)
    KeyBtn.AutoButtonColor = false
    KeyBtn.Font = Enum.Font.Gotham
    KeyBtn.TextSize = 12
    KeyBtn.TextColor3 = Theme.Text
    KeyBtn.Text = default and default.Name or "..."
    KeyBtn.Parent = Container
    corner(KeyBtn, 5)
    reg(window.ThemedInstances, KeyBtn, "BackgroundColor3", function() return Theme.Element end)

    local updateListRow = window:_addKeybindRow(text, KeyBtn.Text)

    KeyBtn.MouseButton1Click:Connect(function()
        KeyBtn.Text = "..."
        window:CaptureNextKey(function(keyCode)
            KeyBtn.Text = keyCode.Name
            updateListRow(keyCode.Name)
            if callback then callback(keyCode) end
        end)
    end)

    return KeyBtn
end

return Library
