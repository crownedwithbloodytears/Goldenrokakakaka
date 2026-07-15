--[[
    CustomLib_TopTabs (v4) - Palantir X Style
    Стиль: компактный, утилитарный, минимальные скругления
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

local Themes = {
    Monochrome = {
        Background = Color3.fromRGB(8, 8, 10),
        TopBar     = Color3.fromRGB(12, 12, 14),
        Section    = Color3.fromRGB(15, 15, 17),
        Element    = Color3.fromRGB(25, 25, 28),
        Accent     = Color3.fromRGB(180, 180, 180),
        Stroke     = Color3.fromRGB(35, 35, 38),
    },
    Crimson = {
        Background = Color3.fromRGB(16, 12, 13),
        TopBar     = Color3.fromRGB(22, 16, 17),
        Section    = Color3.fromRGB(24, 17, 18),
        Element    = Color3.fromRGB(36, 24, 25),
        Accent     = Color3.fromRGB(200, 60, 60),
        Stroke     = Color3.fromRGB(50, 32, 33),
    },
    Ocean = {
        Background = Color3.fromRGB(11, 14, 17),
        TopBar     = Color3.fromRGB(15, 19, 23),
        Section    = Color3.fromRGB(17, 21, 26),
        Element    = Color3.fromRGB(26, 32, 39),
        Accent     = Color3.fromRGB(80, 160, 255),
        Stroke     = Color3.fromRGB(35, 44, 53),
    },
    Violet = {
        Background = Color3.fromRGB(15, 13, 17),
        TopBar     = Color3.fromRGB(20, 17, 23),
        Section    = Color3.fromRGB(22, 19, 25),
        Element    = Color3.fromRGB(33, 28, 38),
        Accent     = Color3.fromRGB(170, 110, 255),
        Stroke     = Color3.fromRGB(47, 40, 54),
    },
    Emerald = {
        Background = Color3.fromRGB(12, 15, 13),
        TopBar     = Color3.fromRGB(17, 21, 18),
        Section    = Color3.fromRGB(19, 23, 20),
        Element    = Color3.fromRGB(28, 34, 29),
        Accent     = Color3.fromRGB(80, 210, 120),
        Stroke     = Color3.fromRGB(40, 49, 42),
    },
}

local Theme = {}
for k, v in pairs(FixedColors) do Theme[k] = v end
for k, v in pairs(Themes.Monochrome) do Theme[k] = v end

-- ====================== СИСТЕМА КОНФИГОВ ======================
local Library = {}

Library.Themes = Themes
Library.ThemeNames = {}
for name in pairs(Themes) do
    table.insert(Library.ThemeNames, name)
end

Library.ConfigFolder = "CustomLib_Configs"
Library.ThemeFolder = "CustomLib_Themes"
Library.Flags = {}
Library.CurrentWindow = nil

function Library:EnsureFolders()
    if not isfolder(self.ConfigFolder) then
        makefolder(self.ConfigFolder)
    end
    if not isfolder(self.ThemeFolder) then
        makefolder(self.ThemeFolder)
    end
end

function Library:SaveConfig(name, data)
    self:EnsureFolders()
    local json = HttpService:JSONEncode(data)
    writefile(self.ConfigFolder .. "/" .. name .. ".json", json)
end

function Library:LoadConfig(name)
    local path = self.ConfigFolder .. "/" .. name .. ".json"
    if not isfile(path) then return nil end
    local data = readfile(path)
    return HttpService:JSONDecode(data)
end

function Library:GetConfigs()
    local result = {}
    self:EnsureFolders()
    if isfolder(self.ConfigFolder) then
        for _, file in ipairs(listfiles(self.ConfigFolder)) do
            local name = file:match("([^/]+)%.json$")
            if name then
                table.insert(result, name)
            end
        end
    end
    return result
end

function Library:DeleteConfig(name)
    local path = self.ConfigFolder .. "/" .. name .. ".json"
    if isfile(path) then
        delfile(path)
        return true
    end
    return false
end

function Library:SaveCurrentConfig(name)
    local data = {}
    for flag, obj in pairs(self.Flags) do
        if obj and obj.Get then
            data[flag] = obj.Get()
        end
    end
    data._Theme = self.CurrentTheme or "Monochrome"
    data._ConfigName = name
    self:SaveConfig(name, data)
    return true
end

function Library:LoadCurrentConfig(name)
    local data = self:LoadConfig(name)
    if not data then return false end
    
    for flag, value in pairs(data) do
        if flag ~= "_Theme" and flag ~= "_ConfigName" then
            if self.Flags[flag] and self.Flags[flag].Set then
                self.Flags[flag].Set(value)
            end
        end
    end
    
    if data._Theme and self.CurrentWindow then
        self.CurrentWindow:SetTheme(data._Theme)
    end
    return true
end

function Library:AddTheme(name, data)
    Themes[name] = data
    if not table.find(self.ThemeNames, name) then
        table.insert(self.ThemeNames, name)
    end
    return true
end

function Library:SaveTheme(name, themeData)
    self:EnsureFolders()
    local json = HttpService:JSONEncode(themeData)
    writefile(self.ThemeFolder .. "/" .. name .. ".json", json)
    self:AddTheme(name, themeData)
    return true
end

function Library:GetUserThemes()
    local result = {}
    self:EnsureFolders()
    if isfolder(self.ThemeFolder) then
        for _, file in ipairs(listfiles(self.ThemeFolder)) do
            local name = file:match("([^/]+)%.json$")
            if name then
                table.insert(result, name)
            end
        end
    end
    return result
end

-- ====================== ХЕЛПЕРЫ ======================
local function tween(obj, info, props)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 2)
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

local function reg(list, instance, prop, getter)
    instance[prop] = getter()
    if list then
        table.insert(list, {Instance = instance, Prop = prop, Getter = getter})
    end
    return instance
end

-- ====================== МЕТАТАБЛИЦЫ КЛАССОВ ======================
local Window   = {}; Window.__index = Window
local MainTab  = {}; MainTab.__index = MainTab
local SubTab   = {}; SubTab.__index = SubTab
local Section  = {}; Section.__index = Section

-- ====================== ОКНО ======================
function Library:CreateWindow(config)
    config = config or {}
    local title    = config.Title or "Menu"
    local subtitle = config.Subtitle or ""
    local size     = config.Size or UDim2.fromOffset(720, 430)

    local themedList = {}

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "CustomLibGui"
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
    corner(Main, 2)
    reg(themedList, Main, "BackgroundColor3", function() return Theme.Background end)
    reg(themedList, stroke(Main, Theme.Stroke, 1), "Color", function() return Theme.Stroke end)

    local UIScale = Instance.new("UIScale")
    UIScale.Scale = 1
    UIScale.Parent = Main

    -- ---- Верхняя шапка ----
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 32)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = Main
    corner(TopBar, 2)
    reg(themedList, TopBar, "BackgroundColor3", function() return Theme.TopBar end)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Position = UDim2.new(0, 12, 0, 0)
    TitleLabel.Size = UDim2.new(0, 200, 1, 0)
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 14
    TitleLabel.TextColor3 = Theme.Text
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Text = title
    TitleLabel.Parent = TopBar

    local SubtitleLabel = Instance.new("TextLabel")
    SubtitleLabel.BackgroundTransparency = 1
    SubtitleLabel.Position = UDim2.new(0, 12, 0, 0)
    SubtitleLabel.Size = UDim2.new(0, 260, 1, 0)
    SubtitleLabel.Font = Enum.Font.Gotham
    SubtitleLabel.TextSize = 11
    SubtitleLabel.TextColor3 = Theme.SubText
    SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubtitleLabel.Text = subtitle
    SubtitleLabel.Parent = TopBar
    task.defer(function()
        SubtitleLabel.Position = UDim2.new(0, 12 + TitleLabel.TextBounds.X + 10, 0, 0)
    end)

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Text = "×"
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 16
    CloseBtn.TextColor3 = Theme.SubText
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.AutoButtonColor = false
    CloseBtn.Size = UDim2.fromOffset(28, 28)
    CloseBtn.Position = UDim2.new(1, -34, 0, 2)
    CloseBtn.Parent = TopBar

    local connections = {}

    track(connections, CloseBtn.MouseEnter:Connect(function()
        tween(CloseBtn, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(230, 90, 90)})
    end))
    track(connections, CloseBtn.MouseLeave:Connect(function()
        tween(CloseBtn, TweenInfo.new(0.15), {TextColor3 = Theme.SubText})
    end))

    -- Перетаскивание
    do
        local dragging, dragStart, startPos
        track(connections, TopBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = Main.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
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
    MainTabBar.Position = UDim2.new(0, 0, 0, 32)
    MainTabBar.Size = UDim2.new(1, 0, 0, 32)
    MainTabBar.BorderSizePixel = 0
    MainTabBar.Parent = Main
    reg(themedList, MainTabBar, "BackgroundColor3", function() return Theme.TopBar end)

    local mainTabList = listLayout(MainTabBar, 20, true)
    mainTabList.HorizontalAlignment = Enum.HorizontalAlignment.Center

    -- ---- Контейнер контента ----
    local ContentHost = Instance.new("Frame")
    ContentHost.Position = UDim2.new(0, 0, 0, 64)
    ContentHost.Size = UDim2.new(1, 0, 1, -64)
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
        CurrentThemeName = "Monochrome",
        ToggleKey = config.ToggleKey or Enum.KeyCode.RightControl,
        KeybindListFrame = nil,
        KeybindRows = {},
    }, Window)

    Library.CurrentWindow = self

    CloseBtn.MouseButton1Click:Connect(function() self:SetVisible(false) end)
    track(self.Connections, UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == self.ToggleKey then self:SetVisible(not self.Visible) end
    end))

    -- Анимация появления
    Main.Size = UDim2.new(size.X.Scale, size.X.Offset, size.Y.Scale, math.floor(size.Y.Offset * 0.85))
    Main.BackgroundTransparency = 1
    tween(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
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
        tween(self.Main, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = size, BackgroundTransparency = 0,
        })
    else
        local t = tween(self.Main, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
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
    for k, v in pairs(preset) do
        Theme[k] = v
    end
    for _, entry in ipairs(self.ThemedInstances) do
        pcall(function()
            tween(entry.Instance, TweenInfo.new(0.2), {[entry.Prop] = entry.Getter()})
        end)
    end
    self.CurrentThemeName = name
    Library.CurrentTheme = name
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
            if callback then callback(input.KeyCode) end
        end
    end)
    track(self.Connections, conn)
end

function Window:SetUIScale(percent)
    tween(self.UIScale, TweenInfo.new(0.15), {Scale = percent / 100})
end

function Window:ResetPosition()
    tween(self.Main, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.fromScale(0.5, 0.5),
    })
end

function Window:Destroy()
    for _, conn in ipairs(self.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    local t = tween(self.Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        BackgroundTransparency = 1,
    })
    t.Completed:Connect(function()
        self.ScreenGui:Destroy()
    end)
end

-- ---- Кейбинды ----
function Window:_ensureKeybindList()
    if self.KeybindListFrame then return end

    local Frame = Instance.new("Frame")
    Frame.Name = "KeybindList"
    Frame.Position = UDim2.new(0, 16, 0, 16)
    Frame.Size = UDim2.new(0, 160, 0, 0)
    Frame.AutomaticSize = Enum.AutomaticSize.Y
    Frame.BorderSizePixel = 0
    Frame.Visible = false
    Frame.Parent = self.ScreenGui
    corner(Frame, 2)
    reg(self.ThemedInstances, Frame, "BackgroundColor3", function() return Theme.Section end)
    reg(self.ThemedInstances, stroke(Frame, Theme.Stroke, 1), "Color", function() return Theme.Stroke end)

    listLayout(Frame, 2)
    padUniform(Frame, 6)

    local Title = Instance.new("TextLabel")
    Title.BackgroundTransparency = 1
    Title.Size = UDim2.new(1, 0, 0, 14)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 11
    Title.TextColor3 = Theme.SubText
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Text = "Keybinds"
    Title.LayoutOrder = 0
    Title.Parent = Frame

    do
        local dragging, dragStart, startPos
        track(self.Connections, Frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = Frame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
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
    Row.Size = UDim2.new(1, 0, 0, 13)
    Row.Font = Enum.Font.Gotham
    Row.TextSize = 11
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
    local Btn = Instance.new("TextButton")
    Btn.BackgroundTransparency = 1
    Btn.Size = UDim2.fromOffset(0, 30)
    Btn.AutomaticSize = Enum.AutomaticSize.X
    Btn.Font = Enum.Font.GothamMedium
    Btn.TextSize = 13
    Btn.TextColor3 = Theme.SubText
    Btn.Text = name
    Btn.Parent = self.MainTabBar

    local UnderlineBar = Instance.new("Frame")
    UnderlineBar.AnchorPoint = Vector2.new(0.5, 0)
    UnderlineBar.Position = UDim2.new(0.5, 0, 1, 0)
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
    SubTabBar.Size = UDim2.new(1, -16, 0, 28)
    SubTabBar.Position = UDim2.new(0, 8, 0, 4)
    SubTabBar.BackgroundTransparency = 1
    SubTabBar.Parent = Host
    listLayout(SubTabBar, 6, true)

    local SubContentHost = Instance.new("Frame")
    SubContentHost.Position = UDim2.new(0, 8, 0, 36)
    SubContentHost.Size = UDim2.new(1, -16, 1, -44)
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
            tween(Btn, TweenInfo.new(0.1), {TextColor3 = Theme.Text})
        end
    end))
    track(self.Connections, Btn.MouseLeave:Connect(function()
        if windowRef.CurrentMainTab ~= tabObj then
            tween(Btn, TweenInfo.new(0.1), {TextColor3 = Theme.SubText})
        end
    end))

    if not self.CurrentMainTab then
        self:SelectMainTab(tabObj)
    end

    return tabObj
end

function Window:SelectMainTab(tab)
    if self.CurrentMainTab == tab then return end
    local old = self.CurrentMainTab
    self.CurrentMainTab = tab

    if old then
        tween(old.Button, TweenInfo.new(0.1), {TextColor3 = Theme.SubText})
        old.Host.Visible = false
        tween(old.Underline, TweenInfo.new(0.1), {
            Size = UDim2.new(0, 0, 0, 2),
            BackgroundTransparency = 1,
        })
    end

    tween(tab.Button, TweenInfo.new(0.1), {TextColor3 = Theme.Accent})
    tab.Host.Visible = true
    tween(tab.Underline, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundTransparency = 0,
    })
end

-- ====================== ПОД-ВКЛАДКИ ======================
function MainTab:AddSubTab(name)
    local window = self.Window

    local Btn = Instance.new("TextButton")
    Btn.AutomaticSize = Enum.AutomaticSize.X
    Btn.Size = UDim2.fromOffset(0, 24)
    Btn.AutoButtonColor = false
    Btn.Font = Enum.Font.Gotham
    Btn.TextSize = 12
    Btn.TextColor3 = Theme.SubText
    Btn.Text = name
    Btn.Parent = self.SubTabBar
    corner(Btn, 2)

    local Page = Instance.new("Frame")
    Page.Size = UDim2.fromScale(1, 1)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.Parent = self.SubContentHost

    local Left = Instance.new("ScrollingFrame")
    Left.Size = UDim2.new(0.5, -4, 1, 0)
    Left.Position = UDim2.new(0, 0, 0, 0)
    Left.BackgroundTransparency = 1
    Left.BorderSizePixel = 0
    Left.ScrollBarThickness = 2
    Left.CanvasSize = UDim2.new(0, 0, 0, 0)
    Left.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Left.Parent = Page
    listLayout(Left, 6)
    reg(window.ThemedInstances, Left, "ScrollBarImageColor3", function() return Theme.Accent end)

    local Right = Instance.new("ScrollingFrame")
    Right.Size = UDim2.new(0.5, -4, 1, 0)
    Right.Position = UDim2.new(0.5, 4, 0, 0)
    Right.BackgroundTransparency = 1
    Right.BorderSizePixel = 0
    Right.ScrollBarThickness = 2
    Right.CanvasSize = UDim2.new(0, 0, 0, 0)
    Right.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Right.Parent = Page
    listLayout(Right, 6)
    reg(window.ThemedInstances, Right, "ScrollBarImageColor3", function() return Theme.Accent end)

    local mainTabRef = self
    local subTab = setmetatable({
        MainTab = mainTabRef,
        Window = window,
        Button = Btn,
        Page = Page,
        Left = Left,
        Right = Right,
    }, SubTab)

    table.insert(self.SubTabs, subTab)

    reg(window.ThemedInstances, Btn, "BackgroundColor3", function()
        return (mainTabRef.CurrentSubTab == subTab) and Theme.Accent or Theme.Element
    end)
    reg(window.ThemedInstances, Btn, "TextColor3", function()
        return (mainTabRef.CurrentSubTab == subTab) and Color3.fromRGB(20, 20, 20) or Theme.Text
    end)

    track(window.Connections, Btn.MouseButton1Click:Connect(function()
        mainTabRef:SelectSubTab(subTab)
    end))
    track(window.Connections, Btn.MouseEnter:Connect(function()
        if mainTabRef.CurrentSubTab ~= subTab then
            tween(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Stroke})
        end
    end))
    track(window.Connections, Btn.MouseLeave:Connect(function()
        if mainTabRef.CurrentSubTab ~= subTab then
            tween(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Element})
        end
    end))

    if not self.CurrentSubTab then
        self:SelectSubTab(subTab)
    end

    return subTab
end

function MainTab:SelectSubTab(subTab)
    if self.CurrentSubTab == subTab then return end
    local old = self.CurrentSubTab
    self.CurrentSubTab = subTab

    if old then
        tween(old.Button, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Element, TextColor3 = Theme.Text})
        old.Page.Visible = false
    end

    tween(subTab.Button, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Accent, TextColor3 = Color3.fromRGB(20, 20, 20)})
    local page = subTab.Page
    page.Visible = true
    page.Position = UDim2.new(0, 8, 0, 0)
    tween(page, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
    })
end

-- ====================== СЕКЦИИ ======================
local function buildSection(parent, name, window)
    local Frame = Instance.new("Frame")
    Frame.BorderSizePixel = 0
    Frame.Size = UDim2.new(1, 0, 0, 0)
    Frame.AutomaticSize = Enum.AutomaticSize.Y
    Frame.Parent = parent
    corner(Frame, 2)
    reg(window.ThemedInstances, Frame, "BackgroundColor3", function() return Theme.Section end)
    reg(window.ThemedInstances, stroke(Frame, Theme.Stroke, 1), "Color", function() return Theme.Stroke end)

    listLayout(Frame, 4)
    padUniform(Frame, 8)

    local Title = Instance.new("TextLabel")
    Title.BackgroundTransparency = 1
    Title.Size = UDim2.new(1, 0, 0, 14)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 11
    Title.TextColor3 = Theme.SubText
    Title.Text = name
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.LayoutOrder = 0
    Title.Parent = Frame

    -- Разделитель
    local Line = Instance.new("Frame")
    Line.Size = UDim2.new(1, 0, 0, 1)
    Line.BorderSizePixel = 0
    Line.LayoutOrder = 1
    Line.Parent = Frame
    reg(window.ThemedInstances, Line, "BackgroundColor3", function() return Theme.Stroke end)

    return setmetatable({ Frame = Frame, Order = 2, Window = window }, Section)
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

-- ---- Toggle с keybind ----
function Section:AddToggle(text, default, callback, keybind, flag)
    default = default or false
    local window = self.Window

    local Row = Instance.new("TextButton")
    Row.Size = UDim2.new(1, 0, 0, 22)
    Row.BackgroundTransparency = 1
    Row.AutoButtonColor = false
    Row.Text = ""
    Row.LayoutOrder = self:_order()
    Row.Parent = self.Frame

    local Track = Instance.new("Frame")
    Track.Size = UDim2.fromOffset(26, 14)
    Track.Position = UDim2.new(0, 0, 0.5, -7)
    Track.Parent = Row
    corner(Track, 7)
    reg(window.ThemedInstances, stroke(Track, Theme.Stroke, 1), "Color", function() return Theme.Stroke end)

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.fromOffset(10, 10)
    Knob.Parent = Track
    corner(Knob, 5)

    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 32, 0, 0)
    Label.Size = UDim2.new(0, 0, 1, 0)
    Label.AutomaticSize = Enum.AutomaticSize.X
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Text = text
    Label.Parent = Row
    reg(window.ThemedInstances, Label, "TextColor3", function() return Theme.Text end)

    -- Keybind справа
    local KeyLabel = nil
    if keybind then
        KeyLabel = Instance.new("TextLabel")
        KeyLabel.BackgroundTransparency = 1
        KeyLabel.Position = UDim2.new(1, -4, 0, 0)
        KeyLabel.Size = UDim2.new(0, 0, 1, 0)
        KeyLabel.AutomaticSize = Enum.AutomaticSize.X
        KeyLabel.Font = Enum.Font.Gotham
        KeyLabel.TextSize = 11
        KeyLabel.TextXAlignment = Enum.TextXAlignment.Right
        KeyLabel.TextColor3 = Theme.SubText
        KeyLabel.Text = keybind
        KeyLabel.Parent = Row
        reg(window.ThemedInstances, KeyLabel, "TextColor3", function() return Theme.SubText end)
        
        -- Сдвигаем label влево
        Label.Size = UDim2.new(1, -36, 1, 0)
    end

    local state = default

    reg(window.ThemedInstances, Track, "BackgroundColor3", function()
        return state and Theme.Accent or Theme.Element
    end)
    reg(window.ThemedInstances, Knob, "BackgroundColor3", function()
        return state and Color3.fromRGB(20, 20, 20) or Theme.White
    end)

    local function applyPositions(animate)
        local trackColor = state and Theme.Accent or Theme.Element
        local knobColor = state and Color3.fromRGB(20, 20, 20) or Theme.White
        local knobPos = state and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)

        if animate then
            tween(Track, TweenInfo.new(0.1), {BackgroundColor3 = trackColor})
            tween(Knob, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {Position = knobPos, BackgroundColor3 = knobColor})
        else
            Track.BackgroundColor3 = trackColor
            Knob.Position = knobPos
            Knob.BackgroundColor3 = knobColor
        end
    end
    applyPositions(false)

    local function set(v, fire)
        state = v
        applyPositions(true)
        if fire ~= false and callback then callback(state) end
    end

    Row.MouseButton1Click:Connect(function() set(not state) end)

    if flag then
        Library.Flags[flag] = {
            Set = function(v) set(v, false) end,
            Get = function() return state end,
            Type = "Toggle"
        }
    end

    return { 
        Set = function(_, v) set(v, false) end, 
        Get = function() return state end
    }
end

-- ---- Placeholder ----
function Section:AddPlaceholder(text)
    local window = self.Window

    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 22)
    Row.BackgroundTransparency = 1
    Row.LayoutOrder = self:_order()
    Row.Parent = self.Frame

    local Track = Instance.new("Frame")
    Track.Size = UDim2.fromOffset(26, 14)
    Track.Position = UDim2.new(0, 0, 0.5, -7)
    Track.BackgroundTransparency = 0.4
    Track.Parent = Row
    corner(Track, 7)
    reg(window.ThemedInstances, Track, "BackgroundColor3", function() return Theme.Element end)

    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 32, 0, 0)
    Label.Size = UDim2.new(1, -56, 1, 0)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 12
    Label.TextColor3 = Theme.Disabled
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Text = text
    Label.Parent = Row

    local NA = Instance.new("TextLabel")
    NA.BackgroundTransparency = 1
    NA.Position = UDim2.new(1, -4, 0, 0)
    NA.Size = UDim2.new(0, 40, 1, 0)
    NA.Font = Enum.Font.Gotham
    NA.TextSize = 11
    NA.TextColor3 = Theme.Disabled
    NA.TextXAlignment = Enum.TextXAlignment.Right
    NA.Text = "N/A"
    NA.Parent = Row

    return Row
end

-- ---- Slider ----
function Section:AddSlider(text, min, max, default, unit, callback, flag)
    min = min or 0
    max = max or 100
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
    Label.Size = UDim2.new(1, 0, 0, 14)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 11
    Label.TextColor3 = Theme.SubText
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Text = text
    Label.Parent = Container
    reg(window.ThemedInstances, Label, "TextColor3", function() return Theme.SubText end)

    local Bar = Instance.new("Frame")
    Bar.Position = UDim2.new(0, 0, 0, 18)
    Bar.Size = UDim2.new(1, 0, 0, 16)
    Bar.Parent = Container
    corner(Bar, 2)
    reg(window.ThemedInstances, Bar, "BackgroundColor3", function() return Theme.Element end)

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.fromScale((default - min) / (max - min), 1)
    Fill.Parent = Bar
    corner(Fill, 2)
    reg(window.ThemedInstances, Fill, "BackgroundColor3", function() return Theme.Accent end)

    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Size = UDim2.fromScale(1, 1)
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.TextSize = 10
    ValueLabel.TextColor3 = Color3.fromRGB(20, 20, 20)
    ValueLabel.Text = tostring(default) .. unit .. "/" .. tostring(max) .. unit
    ValueLabel.ZIndex = 2
    ValueLabel.Parent = Bar

    local dragging = false
    local currentValue = default
    
    local function update(inputPos)
        local rel = math.clamp((inputPos.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (max - min) * rel + 0.5)
        currentValue = value

        tween(Fill, TweenInfo.new(0.05), {Size = UDim2.fromScale(rel, 1)})
        ValueLabel.Text = tostring(value) .. unit .. "/" .. tostring(max) .. unit
        ValueLabel.TextColor3 = (rel > 0.15) and Color3.fromRGB(20, 20, 20) or Theme.Text

        if callback then callback(value) end
    end

    Bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input.Position)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position)
        end
    end)

    if flag then
        Library.Flags[flag] = {
            Set = function(v) 
                local rel = math.clamp((v - min) / (max - min), 0, 1)
                currentValue = v
                tween(Fill, TweenInfo.new(0.05), {Size = UDim2.fromScale(rel, 1)})
                ValueLabel.Text = tostring(v) .. unit .. "/" .. tostring(max) .. unit
                ValueLabel.TextColor3 = (rel > 0.15) and Color3.fromRGB(20, 20, 20) or Theme.Text
                if callback then callback(v) end
            end,
            Get = function() return currentValue end,
            Type = "Slider"
        }
    end

    return Container
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
    Label.Size = UDim2.new(1, 0, 0, 14)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 11
    Label.TextColor3 = Theme.SubText
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Text = text
    Label.Parent = Container
    reg(window.ThemedInstances, Label, "TextColor3", function() return Theme.SubText end)

    local Head = Instance.new("TextButton")
    Head.Position = UDim2.new(0, 0, 0, 18)
    Head.Size = UDim2.new(1, 0, 0, 18)
    Head.AutoButtonColor = false
    Head.Text = ""
    Head.Parent = Container
    corner(Head, 2)
    reg(window.ThemedInstances, Head, "BackgroundColor3", function() return Theme.Element end)

    local SelectedLabel = Instance.new("TextLabel")
    SelectedLabel.BackgroundTransparency = 1
    SelectedLabel.Position = UDim2.new(0, 6, 0, 0)
    SelectedLabel.Size = UDim2.new(1, -24, 1, 0)
    SelectedLabel.Font = Enum.Font.Gotham
    SelectedLabel.TextSize = 11
    SelectedLabel.TextColor3 = Theme.Text
    SelectedLabel.TextXAlignment = Enum.TextXAlignment.Left
    SelectedLabel.Text = tostring(default)
    SelectedLabel.Parent = Head
    reg(window.ThemedInstances, SelectedLabel, "TextColor3", function() return Theme.Text end)

    local Arrow = Instance.new("TextLabel")
    Arrow.BackgroundTransparency = 1
    Arrow.Position = UDim2.new(1, -18, 0, 0)
    Arrow.Size = UDim2.fromOffset(18, 18)
    Arrow.Font = Enum.Font.GothamBold
    Arrow.TextSize = 10
    Arrow.TextColor3 = Theme.SubText
    Arrow.Text = "▾"
    Arrow.Parent = Head

    local List = Instance.new("Frame")
    List.Position = UDim2.new(0, 0, 0, 38)
    List.Size = UDim2.new(1, 0, 0, 0)
    List.ClipsDescendants = true
    List.Visible = false
    List.ZIndex = 5
    List.Parent = Container
    corner(List, 2)
    reg(window.ThemedInstances, List, "BackgroundColor3", function() return Theme.Element end)
    reg(window.ThemedInstances, stroke(List, Theme.Stroke, 1), "Color", function() return Theme.Stroke end)
    listLayout(List, 0)

    local open = false
    local listHeight = #options * 20
    local currentOption = default

    local function close()
        open = false
        tween(Arrow, TweenInfo.new(0.1), {Rotation = 0})
        tween(Container, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 40)})
        local t = tween(List, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 0)})
        t.Completed:Connect(function()
            if not open then List.Visible = false end
        end)
    end

    local function selectOption(opt)
        currentOption = opt
        SelectedLabel.Text = tostring(opt)
        close()
        if callback then callback(opt) end
    end

    for i, opt in ipairs(options) do
        local OptBtn = Instance.new("TextButton")
        OptBtn.Size = UDim2.new(1, 0, 0, 20)
        OptBtn.LayoutOrder = i
        OptBtn.BackgroundTransparency = 1
        OptBtn.Font = Enum.Font.Gotham
        OptBtn.TextSize = 11
        OptBtn.TextColor3 = Theme.Text
        OptBtn.Text = tostring(opt)
        OptBtn.Parent = List
        OptBtn.MouseEnter:Connect(function() tween(OptBtn, TweenInfo.new(0.1), {TextColor3 = Theme.Accent}) end)
        OptBtn.MouseLeave:Connect(function() tween(OptBtn, TweenInfo.new(0.1), {TextColor3 = Theme.Text}) end)
        OptBtn.MouseButton1Click:Connect(function() selectOption(opt) end)
    end

    Head.MouseButton1Click:Connect(function()
        open = not open
        if open then
            List.Visible = true
            tween(Arrow, TweenInfo.new(0.1), {Rotation = 180})
            tween(List, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, listHeight)})
            tween(Container, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 40 + listHeight)})
        else
            close()
        end
    end)

    if flag then
        Library.Flags[flag] = {
            Set = function(v) selectOption(v) end,
            Get = function() return currentOption end,
            Type = "Dropdown"
        }
    end

    return {
        Set = function(_, v) selectOption(v) end,
        Close = close,
        Get = function() return currentOption end,
    }
end

-- ---- Button ----
function Section:AddButton(text, callback)
    local window = self.Window

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 24)
    Btn.AutoButtonColor = false
    Btn.Font = Enum.Font.Gotham
    Btn.TextSize = 12
    Btn.TextColor3 = Theme.Text
    Btn.Text = text
    Btn.LayoutOrder = self:_order()
    Btn.Parent = self.Frame
    corner(Btn, 2)
    reg(window.ThemedInstances, Btn, "BackgroundColor3", function() return Theme.Element end)

    Btn.MouseEnter:Connect(function() tween(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Accent, TextColor3 = Color3.fromRGB(20,20,20)}) end)
    Btn.MouseLeave:Connect(function() tween(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Element, TextColor3 = Theme.Text}) end)
    Btn.MouseButton1Click:Connect(function() if callback then callback() end end)

    return Btn
end

-- ---- Label ----
function Section:AddLabel(text)
    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Size = UDim2.new(1, 0, 0, 14)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 11
    Label.TextColor3 = Theme.SubText
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Text = text
    Label.LayoutOrder = self:_order()
    Label.Parent = self.Frame
    reg(self.Window.ThemedInstances, Label, "TextColor3", function() return Theme.SubText end)
    return Label
end

-- ---- Keybind ----
function Section:AddKeybind(text, window, default, callback, flag)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 22)
    Container.BackgroundTransparency = 1
    Container.LayoutOrder = self:_order()
    Container.Parent = self.Frame

    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Size = UDim2.new(1, -72, 1, 0)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 12
    Label.TextColor3 = Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Text = text
    Label.Parent = Container
    reg(self.Window.ThemedInstances, Label, "TextColor3", function() return Theme.Text end)

    local KeyBtn = Instance.new("TextButton")
    KeyBtn.Position = UDim2.new(1, -68, 0.5, -9)
    KeyBtn.Size = UDim2.fromOffset(68, 18)
    KeyBtn.AutoButtonColor = false
    KeyBtn.Font = Enum.Font.Gotham
    KeyBtn.TextSize = 11
    KeyBtn.TextColor3 = Theme.Text
    KeyBtn.Text = default and default.Name or "..."
    KeyBtn.Parent = Container
    corner(KeyBtn, 2)
    reg(self.Window.ThemedInstances, KeyBtn, "BackgroundColor3", function() return Theme.Element end)

    local updateListRow = window:_addKeybindRow(text, KeyBtn.Text)
    local currentKey = default

    KeyBtn.MouseButton1Click:Connect(function()
        KeyBtn.Text = "..."
        window:CaptureNextKey(function(keyCode)
            currentKey = keyCode
            KeyBtn.Text = keyCode.Name
            updateListRow(keyCode.Name)
            if callback then callback(keyCode) end
        end)
    end)

    if flag then
        Library.Flags[flag] = {
            Set = function(v) 
                currentKey = v
                KeyBtn.Text = v.Name
                updateListRow(v.Name)
                if callback then callback(v) end
            end,
            Get = function() return currentKey end,
            Type = "Keybind"
        }
    end

    return KeyBtn
end

-- ====================== ВСТРОЕННОЕ МЕНЮ ======================
function Library:AddSettingsMenu(window)
    if not window then
        window = self.CurrentWindow
        if not window then return end
    end
    
    local SettingsTab = window:AddMainTab("Settings")
    local MenuSub = SettingsTab:AddSubTab("Menu")
    local ThemeSub = SettingsTab:AddSubTab("Themes")
    local ConfigSub = SettingsTab:AddSubTab("Configs")
    
    -- Menu
    local AppearanceSection = MenuSub:AddLeftSection("Appearance")
    
    local themeOptions = {}
    for _, name in ipairs(self.ThemeNames) do
        table.insert(themeOptions, name)
    end
    
    AppearanceSection:AddDropdown("Theme", themeOptions, window.CurrentThemeName or "Monochrome", function(theme)
        window:SetTheme(theme)
    end, "_UI_Theme")
    
    AppearanceSection:AddSlider("UI Scale", 50, 150, 100, "%", function(value)
        window:SetUIScale(value)
    end, "_UI_Scale")
    
    -- Themes
    local ThemeManagerSection = ThemeSub:AddLeftSection("Theme Manager")
    
    local savedThemes = self:GetUserThemes()
    local themeList = {}
    for _, name in ipairs(savedThemes) do
        table.insert(themeList, name)
    end
    
    local themeDropdown = ThemeManagerSection:AddDropdown("Load Theme", themeList, themeList[1] or "", function(theme)
        self:LoadTheme(theme)
        window:SetTheme(theme)
    end, "_UI_LoadTheme")
    
    ThemeManagerSection:AddButton("Save Current Theme", function()
        local name = "Theme_" .. os.time()
        local themeData = {
            Background = Theme.Background,
            TopBar = Theme.TopBar,
            Section = Theme.Section,
            Element = Theme.Element,
            Accent = Theme.Accent,
            Stroke = Theme.Stroke,
        }
        self:SaveTheme(name, themeData)
        
        local newThemes = self:GetUserThemes()
        local newList = {}
        for _, n in ipairs(newThemes) do
            table.insert(newList, n)
        end
        themeDropdown.Set(nil, newList[1] or "")
        themeDropdown.Close()
    end)
    
    ThemeManagerSection:AddButton("Delete Selected Theme", function()
        local current = themeDropdown.Get()
        if current and self:DeleteTheme(current) then
            local newThemes = self:GetUserThemes()
            local newList = {}
            for _, n in ipairs(newThemes) do
                table.insert(newList, n)
            end
            themeDropdown.Set(nil, newList[1] or "")
            themeDropdown.Close()
        end
    end)
    
    -- Configs
    local ConfigSection = ConfigSub:AddLeftSection("Config Manager")
    
    local configs = self:GetConfigs()
    local configList = {}
    for _, name in ipairs(configs) do
        table.insert(configList, name)
    end
    
    local configDropdown = ConfigSection:AddDropdown("Config", configList, configList[1] or "", function(config)
        self:LoadCurrentConfig(config)
    end, "_UI_Config")
    
    ConfigSection:AddButton("Save Current Config", function()
        local name = "Config_" .. os.time()
        self:SaveCurrentConfig(name)
        
        local newConfigs = self:GetConfigs()
        local newList = {}
        for _, n in ipairs(newConfigs) do
            table.insert(newList, n)
        end
        configDropdown.Set(nil, newList[1] or "")
        configDropdown.Close()
    end)
    
    ConfigSection:AddButton("Delete Selected Config", function()
        local current = configDropdown.Get()
        if current and self:DeleteConfig(current) then
            local newConfigs = self:GetConfigs()
            local newList = {}
            for _, n in ipairs(newConfigs) do
                table.insert(newList, n)
            end
            configDropdown.Set(nil, newList[1] or "")
            configDropdown.Close()
        end
    end)
    
    ConfigSection:AddButton("Reset All", function()
        for flag, obj in pairs(self.Flags) do
            if flag:sub(1, 1) ~= "_" then
                if obj.Type == "Toggle" then
                    obj.Set(false)
                elseif obj.Type == "Slider" then
                    obj.Set(50)
                end
            end
        end
        window:SetTheme("Monochrome")
        window:SetUIScale(100)
    end)
    
    return SettingsTab
end

return Library
