local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ====================== ТЕМА ======================
local Theme = {
    Background = Color3.fromRGB(18, 18, 21),
    TopBar     = Color3.fromRGB(24, 24, 28),
    Section    = Color3.fromRGB(26, 26, 30),
    Element    = Color3.fromRGB(33, 33, 38),
    Accent     = Color3.fromRGB(80, 210, 120),   -- зелёный акцент, как на скрине
    Text       = Color3.fromRGB(230, 230, 235),
    SubText    = Color3.fromRGB(140, 140, 150),
    Disabled   = Color3.fromRGB(90, 90, 95),
    Stroke     = Color3.fromRGB(42, 42, 48),
    White      = Color3.fromRGB(255, 255, 255),
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

-- ====================== МЕТАТАБЛИЦЫ КЛАССОВ ======================
local Window   = {}; Window.__index = Window
local MainTab  = {}; MainTab.__index = MainTab
local SubTab   = {}; SubTab.__index = SubTab
local Section  = {}; Section.__index = Section

local Library = {}

-- ====================== ОКНО ======================
function Library:CreateWindow(config)
    config = config or {}
    local title    = config.Title or "Menu"
    local subtitle = config.Subtitle or ""
    local size     = config.Size or UDim2.fromOffset(700, 520)
    local toggleKey = config.ToggleKey or Enum.KeyCode.RightControl

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
    Main.BackgroundColor3 = Theme.Background
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Main.Parent = ScreenGui
    corner(Main, 10)
    stroke(Main, Theme.Stroke, 1)

    -- ---- Верхняя шапка (Title • Subtitle ... [x]) ----
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 36)
    TopBar.BackgroundColor3 = Theme.TopBar
    TopBar.BorderSizePixel = 0
    TopBar.Parent = Main
    corner(TopBar, 10)
    local TopBarFix = Instance.new("Frame")
    TopBarFix.BackgroundColor3 = Theme.TopBar
    TopBarFix.BorderSizePixel = 0
    TopBarFix.Position = UDim2.new(0, 0, 1, -10)
    TopBarFix.Size = UDim2.new(1, 0, 0, 10)
    TopBarFix.Parent = TopBar

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
    SubtitleLabel.Position = UDim2.new(0, 14 + 6, 0, 0)
    SubtitleLabel.AnchorPoint = Vector2.new(0, 0)
    SubtitleLabel.Size = UDim2.new(0, 260, 1, 0)
    SubtitleLabel.Font = Enum.Font.Gotham
    SubtitleLabel.TextSize = 13
    SubtitleLabel.TextColor3 = Theme.SubText
    SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubtitleLabel.Text = subtitle
    SubtitleLabel.Parent = TopBar
    -- сдвигаем сабтайтл правее заголовка динамически
    task.defer(function()
        SubtitleLabel.Position = UDim2.new(0, TitleLabel.TextBounds.X + 26, 0, 0)
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
    CloseBtn.MouseEnter:Connect(function()
        tween(CloseBtn, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(255, 90, 90)})
    end)
    CloseBtn.MouseLeave:Connect(function()
        tween(CloseBtn, TweenInfo.new(0.15), {TextColor3 = Theme.SubText})
    end)

    -- Перетаскивание за шапку
    do
        local dragging, dragStart, startPos
        TopBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = Main.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end

    -- ---- Ряд главных вкладок ----
    local MainTabBar = Instance.new("Frame")
    MainTabBar.Position = UDim2.new(0, 0, 0, 36)
    MainTabBar.Size = UDim2.new(1, 0, 0, 40)
    MainTabBar.BackgroundColor3 = Theme.TopBar
    MainTabBar.BorderSizePixel = 0
    MainTabBar.Parent = Main

    local MainTabList = Instance.new("UIListLayout")
    MainTabList.FillDirection = Enum.FillDirection.Horizontal
    MainTabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    MainTabList.Padding = UDim.new(0, 28)
    MainTabList.SortOrder = Enum.SortOrder.LayoutOrder
    MainTabList.Parent = MainTabBar

    local Underline = Instance.new("Frame")
    Underline.BackgroundColor3 = Theme.Accent
    Underline.BorderSizePixel = 0
    Underline.Size = UDim2.fromOffset(0, 2)
    Underline.Position = UDim2.new(0, 0, 1, -2)
    Underline.Parent = MainTabBar

    -- ---- Контейнер контента (под главными вкладками) ----
    local ContentHost = Instance.new("Frame")
    ContentHost.Position = UDim2.new(0, 0, 0, 76)
    ContentHost.Size = UDim2.new(1, 0, 1, -76)
    ContentHost.BackgroundTransparency = 1
    ContentHost.ClipsDescendants = true
    ContentHost.Parent = Main

    local self = setmetatable({
        ScreenGui = ScreenGui,
        Main = Main,
        MainTabBar = MainTabBar,
        Underline = Underline,
        ContentHost = ContentHost,
        MainTabs = {},
        CurrentMainTab = nil,
        Visible = true,
        OriginalSize = size,
    }, Window)

    -- Анимация появления
    Main.Size = UDim2.new(size.X.Scale, size.X.Offset, size.Y.Scale, math.floor(size.Y.Offset * 0.85))
    Main.BackgroundTransparency = 1
    tween(Main, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = size, BackgroundTransparency = 0,
    })

    CloseBtn.MouseButton1Click:Connect(function() self:SetVisible(false) end)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == toggleKey then self:SetVisible(not self.Visible) end
    end)

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

    local Host = Instance.new("Frame")
    Host.Size = UDim2.fromScale(1, 1)
    Host.BackgroundTransparency = 1
    Host.Visible = false
    Host.Parent = self.ContentHost

    -- Ряд под-вкладок
    local SubTabBar = Instance.new("Frame")
    SubTabBar.Size = UDim2.new(1, -24, 0, 32)
    SubTabBar.Position = UDim2.new(0, 12, 0, 8)
    SubTabBar.BackgroundTransparency = 1
    SubTabBar.Parent = Host

    local SubTabList = Instance.new("UIListLayout")
    SubTabList.FillDirection = Enum.FillDirection.Horizontal
    SubTabList.Padding = UDim.new(0, 8)
    SubTabList.Parent = SubTabBar

    -- Область под под-вкладками: два столбца
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
        Host = Host,
        SubTabBar = SubTabBar,
        SubContentHost = SubContentHost,
        SubTabs = {},
        CurrentSubTab = nil,
    }, MainTab)

    table.insert(self.MainTabs, tabObj)

    Btn.MouseButton1Click:Connect(function()
        windowRef:SelectMainTab(tabObj)
    end)
    Btn.MouseEnter:Connect(function()
        if windowRef.CurrentMainTab ~= tabObj then
            tween(Btn, TweenInfo.new(0.15), {TextColor3 = Theme.Text})
        end
    end)
    Btn.MouseLeave:Connect(function()
        if windowRef.CurrentMainTab ~= tabObj then
            tween(Btn, TweenInfo.new(0.15), {TextColor3 = Theme.SubText})
        end
    end)

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
        tween(old.Button, TweenInfo.new(0.15), {TextColor3 = Theme.SubText})
        old.Host.Visible = false
    end

    tween(tab.Button, TweenInfo.new(0.15), {TextColor3 = Theme.Accent})
    tab.Host.Visible = true

    -- Двигаем зелёную полоску-подчёркивание под активную вкладку
    tween(self.Underline, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, tab.Button.AbsolutePosition.X - self.MainTabBar.AbsolutePosition.X, 1, -2),
        Size = UDim2.fromOffset(tab.Button.AbsoluteSize.X, 2),
    })
end

-- ====================== ПОД-ВКЛАДКИ ======================
function MainTab:AddSubTab(name)
    local Btn = Instance.new("TextButton")
    Btn.AutomaticSize = Enum.AutomaticSize.X
    Btn.Size = UDim2.fromOffset(0, 30)
    Btn.BackgroundColor3 = Theme.Element
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
    Left.ScrollBarImageColor3 = Theme.Accent
    Left.CanvasSize = UDim2.new(0, 0, 0, 0)
    Left.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Left.Parent = Page
    local LeftList = Instance.new("UIListLayout")
    LeftList.Padding = UDim.new(0, 10)
    LeftList.Parent = Left

    local Right = Instance.new("ScrollingFrame")
    Right.Size = UDim2.new(0.5, -6, 1, 0)
    Right.Position = UDim2.new(0.5, 6, 0, 0)
    Right.BackgroundTransparency = 1
    Right.BorderSizePixel = 0
    Right.ScrollBarThickness = 3
    Right.ScrollBarImageColor3 = Theme.Accent
    Right.CanvasSize = UDim2.new(0, 0, 0, 0)
    Right.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Right.Parent = Page
    local RightList = Instance.new("UIListLayout")
    RightList.Padding = UDim.new(0, 10)
    RightList.Parent = Right

    local mainTabRef = self
    local subTab = setmetatable({
        MainTab = mainTabRef,
        Button = Btn,
        Page = Page,
        Left = Left,
        Right = Right,
    }, SubTab)

    table.insert(self.SubTabs, subTab)

    Btn.MouseButton1Click:Connect(function()
        mainTabRef:SelectSubTab(subTab)
    end)
    Btn.MouseEnter:Connect(function()
        if mainTabRef.CurrentSubTab ~= subTab then
            tween(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Stroke})
        end
    end)
    Btn.MouseLeave:Connect(function()
        if mainTabRef.CurrentSubTab ~= subTab then
            tween(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Element})
        end
    end)

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
        tween(old.Button, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Element, TextColor3 = Theme.SubText})
        local oldPage = old.Page
        tween(oldPage, TweenInfo.new(0.15), {}) -- no-op placeholder for symmetry
        oldPage.Visible = false
    end

    tween(subTab.Button, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Accent, TextColor3 = Theme.White})
    local page = subTab.Page
    page.Visible = true
    page.Position = UDim2.new(0, 16, 0, 0)
    tween(page, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
    })
end

-- ====================== СЕКЦИИ ======================
local function buildSection(parent, name)
    local Frame = Instance.new("Frame")
    Frame.BackgroundColor3 = Theme.Section
    Frame.BorderSizePixel = 0
    Frame.Size = UDim2.new(1, 0, 0, 0)
    Frame.AutomaticSize = Enum.AutomaticSize.Y
    Frame.Parent = parent
    corner(Frame, 8)
    stroke(Frame, Theme.Stroke, 1)

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 6)
    Layout.Parent = Frame
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

    return setmetatable({ Frame = Frame, Order = 1 }, Section)
end

function SubTab:AddLeftSection(name)
    return buildSection(self.Left, name)
end

function SubTab:AddRightSection(name)
    return buildSection(self.Right, name)
end

function Section:_order()
    self.Order = self.Order + 1
    return self.Order
end

-- ---- Toggle ----
function Section:AddToggle(text, default, callback)
    default = default or false

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
    Track.BackgroundColor3 = default and Theme.Accent or Theme.Element
    Track.Parent = Row
    corner(Track, 8)
    stroke(Track, Theme.Stroke, 1)

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.fromOffset(12, 12)
    Knob.Position = default and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
    Knob.BackgroundColor3 = Theme.White
    Knob.Parent = Track
    corner(Knob, 6)

    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 40, 0, 0)
    Label.Size = UDim2.new(1, -40, 1, 0)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 14
    Label.TextColor3 = default and Theme.Accent or Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Text = text
    Label.Parent = Row

    local state = default
    local function set(v, fire)
        state = v
        tween(Track, TweenInfo.new(0.15), {BackgroundColor3 = state and Theme.Accent or Theme.Element})
        tween(Knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
            Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
        })
        tween(Label, TweenInfo.new(0.15), {TextColor3 = state and Theme.Accent or Theme.Text})
        if fire ~= false and callback then callback(state) end
    end

    Row.MouseButton1Click:Connect(function() set(not state) end)

    return { Set = function(_, v) set(v, false) end, Get = function() return state end }
end

-- ---- Placeholder (неактивный пункт "N/A", просто для вида) ----
function Section:AddPlaceholder(text)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 26)
    Row.BackgroundTransparency = 1
    Row.LayoutOrder = self:_order()
    Row.Parent = self.Frame

    local Track = Instance.new("Frame")
    Track.Size = UDim2.fromOffset(32, 16)
    Track.Position = UDim2.new(0, 0, 0.5, -8)
    Track.BackgroundColor3 = Theme.Element
    Track.BackgroundTransparency = 0.4
    Track.Parent = Row
    corner(Track, 8)

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

-- ---- Slider (с подписью диапазона, как на скрине) ----
function Section:AddSlider(text, min, max, default, unit, callback)
    min = min or 0
    max = max or 100
    default = math.clamp(default or min, min, max)
    unit = unit or ""

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
    Bar.BackgroundColor3 = Theme.Element
    Bar.Parent = Container
    corner(Bar, 4)

    local Fill = Instance.new("Frame")
    Fill.BackgroundColor3 = Theme.Accent
    Fill.Size = UDim2.fromScale((default - min) / (max - min), 1)
    Fill.Parent = Bar
    corner(Fill, 4)

    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Size = UDim2.fromScale(1, 1)
    ValueLabel.Font = Enum.Font.Gotham
    ValueLabel.TextSize = 12
    ValueLabel.TextColor3 = Theme.Text
    ValueLabel.Text = tostring(default) .. unit .. "/" .. tostring(max) .. unit
    ValueLabel.ZIndex = 2
    ValueLabel.Parent = Bar

    local dragging = false
    local function update(inputPos)
        local rel = math.clamp((inputPos.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (max - min) * rel + 0.5)
        tween(Fill, TweenInfo.new(0.05), {Size = UDim2.fromScale(rel, 1)})
        ValueLabel.Text = tostring(value) .. unit .. "/" .. tostring(max) .. unit
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

    return Container
end

-- ---- Dropdown (раскрывается вниз с анимацией) ----
function Section:AddDropdown(text, options, default, callback)
    options = options or {}
    default = default or options[1] or ""

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
    Head.BackgroundColor3 = Theme.Element
    Head.AutoButtonColor = false
    Head.Text = ""
    Head.Parent = Container
    corner(Head, 5)

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
    List.BackgroundColor3 = Theme.Element
    List.ClipsDescendants = true
    List.Visible = false
    List.ZIndex = 5
    List.Parent = Container
    corner(List, 5)
    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Parent = List

    local open = false
    local function close()
        open = false
        tween(Arrow, TweenInfo.new(0.15), {Rotation = 0})
        local t = tween(List, TweenInfo.new(0.15), {Size = UDim2.new(1, 0, 0, 0)})
        t.Completed:Connect(function() if not open then List.Visible = false end end)
    end

    local function selectOption(opt)
        SelectedLabel.Text = tostring(opt)
        close()
        if callback then callback(opt) end
    end

    for _, opt in ipairs(options) do
        local OptBtn = Instance.new("TextButton")
        OptBtn.Size = UDim2.new(1, 0, 0, 22)
        OptBtn.BackgroundTransparency = 1
        OptBtn.Font = Enum.Font.Gotham
        OptBtn.TextSize = 12
        OptBtn.TextColor3 = Theme.SubText
        OptBtn.Text = tostring(opt)
        OptBtn.Parent = List
        OptBtn.MouseEnter:Connect(function() tween(OptBtn, TweenInfo.new(0.1), {TextColor3 = Theme.Accent}) end)
        OptBtn.MouseLeave:Connect(function() tween(OptBtn, TweenInfo.new(0.1), {TextColor3 = Theme.SubText}) end)
        OptBtn.MouseButton1Click:Connect(function() selectOption(opt) end)
    end

    Head.MouseButton1Click:Connect(function()
        open = not open
        if open then
            List.Visible = true
            tween(Arrow, TweenInfo.new(0.15), {Rotation = 180})
            tween(List, TweenInfo.new(0.15), {Size = UDim2.new(1, 0, 0, #options * 22)})
        else
            close()
        end
    end)

    return { Set = function(_, v) SelectedLabel.Text = tostring(v) end }
end

-- ---- Button ----
function Section:AddButton(text, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 28)
    Btn.BackgroundColor3 = Theme.Element
    Btn.AutoButtonColor = false
    Btn.Font = Enum.Font.Gotham
    Btn.TextSize = 13
    Btn.TextColor3 = Theme.Text
    Btn.Text = text
    Btn.LayoutOrder = self:_order()
    Btn.Parent = self.Frame
    corner(Btn, 6)

    Btn.MouseEnter:Connect(function() tween(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Accent}) end)
    Btn.MouseLeave:Connect(function() tween(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Element}) end)
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

return Library
