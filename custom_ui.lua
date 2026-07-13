--[[
    CustomLib_TopTabs (v2)
    Изменения по фидбеку:
      - ИСПРАВЛЕН баг с порядком элементов в секциях (заголовок уезжал вниз) —
        причина: у UIListLayout не был явно проставлен SortOrder = LayoutOrder,
        из-за чего Roblox сортировал детей по имени инстанса (Frame/TextButton/TextLabel),
        а не по порядку добавления. Теперь SortOrder указан явно везде.
      - Полоска активной вкладки теперь ДЕЙСТВИТЕЛЬНО следит за позицией кнопки
        (подписана на AbsolutePosition/AbsoluteSize), поэтому больше не "уезжает",
        когда рядом появляются другие вкладки.
      - Чёрно-белая (монохромная) тема вместо зелёной.
      - Добавлены настройки самого меню: полная выгрузка (Destroy), смена
        клавиши открытия/закрытия, масштаб интерфейса, сброс позиции окна.
]]

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ====================== ТЕМА (чёрно-белая) ======================
local Theme = {
    Background = Color3.fromRGB(14, 14, 16),
    TopBar     = Color3.fromRGB(19, 19, 22),
    Section    = Color3.fromRGB(21, 21, 24),
    Element    = Color3.fromRGB(31, 31, 35),
    Accent     = Color3.fromRGB(255, 255, 255), -- белый акцент вместо зелёного
    Text       = Color3.fromRGB(198, 198, 203),
    SubText    = Color3.fromRGB(126, 126, 134),
    Disabled   = Color3.fromRGB(78, 78, 84),
    Stroke     = Color3.fromRGB(44, 44, 50),
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

-- Всегда явно задаём SortOrder, иначе Roblox может сортировать детей
-- по имени инстанса, а не по порядку добавления (это и было причиной бага).
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

    local UIScale = Instance.new("UIScale")
    UIScale.Scale = 1
    UIScale.Parent = Main

    -- ---- Верхняя шапка ----
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
    SubtitleLabel.Position = UDim2.new(0, 14, 0, 0)
    SubtitleLabel.Size = UDim2.new(0, 260, 1, 0)
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

    track(connections, CloseBtn.MouseEnter:Connect(function()
        tween(CloseBtn, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(230, 90, 90)})
    end))
    track(connections, CloseBtn.MouseLeave:Connect(function()
        tween(CloseBtn, TweenInfo.new(0.15), {TextColor3 = Theme.SubText})
    end))

    -- Перетаскивание за шапку
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
    MainTabBar.Position = UDim2.new(0, 0, 0, 36)
    MainTabBar.Size = UDim2.new(1, 0, 0, 40)
    MainTabBar.BackgroundColor3 = Theme.TopBar
    MainTabBar.BorderSizePixel = 0
    MainTabBar.Parent = Main

    local mainTabList = listLayout(MainTabBar, 28, true)
    mainTabList.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local Underline = Instance.new("Frame")
    Underline.BackgroundColor3 = Theme.Accent
    Underline.BorderSizePixel = 0
    Underline.Size = UDim2.fromOffset(0, 2)
    Underline.Position = UDim2.new(0, 0, 1, -2)
    Underline.Parent = MainTabBar

    -- ---- Контейнер контента ----
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
        Underline = Underline,
        ContentHost = ContentHost,
        MainTabs = {},
        CurrentMainTab = nil,
        Visible = true,
        OriginalSize = size,
        Connections = connections,
        ToggleKey = config.ToggleKey or Enum.KeyCode.RightControl,
    }, Window)

    CloseBtn.MouseButton1Click:Connect(function() self:SetVisible(false) end)
    track(self.Connections, UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == self.ToggleKey then self:SetVisible(not self.Visible) end
    end))

    -- Анимация появления
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

-- ---- Настройки самого меню ----
function Window:SetToggleKey(keyCode)
    self.ToggleKey = keyCode
end

-- Ждём следующее нажатие клавиши и передаём её в callback (для UI ребиндинга)
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
    tween(self.Main, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.fromScale(0.5, 0.5),
    })
end

-- Полная выгрузка: отключает все коннекшены и уничтожает интерфейс
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

-- ====================== ГЛАВНЫЕ ВКЛАДКИ ======================
local function updateUnderline(window, tab)
    tween(window.Underline, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, tab.Button.AbsolutePosition.X - window.MainTabBar.AbsolutePosition.X, 1, -2),
        Size = UDim2.fromOffset(tab.Button.AbsoluteSize.X, 2),
    })
end

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
        Host = Host,
        SubTabBar = SubTabBar,
        SubContentHost = SubContentHost,
        SubTabs = {},
        CurrentSubTab = nil,
    }, MainTab)

    table.insert(self.MainTabs, tabObj)

    -- Полоска-индикатор реагирует на реальное движение кнопки (когда рядом
    -- добавляются другие вкладки и раскладка пересчитывается), а не только
    -- на момент выбора вкладки.
    track(self.Connections, Btn:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
        if windowRef.CurrentMainTab == tabObj then updateUnderline(windowRef, tabObj) end
    end))
    track(self.Connections, Btn:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if windowRef.CurrentMainTab == tabObj then updateUnderline(windowRef, tabObj) end
    end))

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
    local old = self.CurrentMainTab
    self.CurrentMainTab = tab

    if old then
        tween(old.Button, TweenInfo.new(0.15), {TextColor3 = Theme.SubText})
        old.Host.Visible = false
    end

    tween(tab.Button, TweenInfo.new(0.15), {TextColor3 = Theme.Accent})
    tab.Host.Visible = true
    updateUnderline(self, tab)
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
    listLayout(Left, 10)

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
    listLayout(Right, 10)

    local mainTabRef = self
    local subTab = setmetatable({
        MainTab = mainTabRef,
        Button = Btn,
        Page = Page,
        Left = Left,
        Right = Right,
    }, SubTab)

    table.insert(self.SubTabs, subTab)

    local conns = self.Window.Connections
    track(conns, Btn.MouseButton1Click:Connect(function()
        mainTabRef:SelectSubTab(subTab)
    end))
    track(conns, Btn.MouseEnter:Connect(function()
        if mainTabRef.CurrentSubTab ~= subTab then
            tween(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Stroke})
        end
    end))
    track(conns, Btn.MouseLeave:Connect(function()
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
local function buildSection(parent, name)
    local Frame = Instance.new("Frame")
    Frame.BackgroundColor3 = Theme.Section
    Frame.BorderSizePixel = 0
    Frame.Size = UDim2.new(1, 0, 0, 0)
    Frame.AutomaticSize = Enum.AutomaticSize.Y
    Frame.Parent = parent
    corner(Frame, 8)
    stroke(Frame, Theme.Stroke, 1)

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
    Knob.BackgroundColor3 = default and Color3.fromRGB(20, 20, 20) or Theme.White
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
            Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
            BackgroundColor3 = state and Color3.fromRGB(20, 20, 20) or Theme.White,
        })
        tween(Label, TweenInfo.new(0.15), {TextColor3 = state and Theme.Accent or Theme.Text})
        if fire ~= false and callback then callback(state) end
    end

    Row.MouseButton1Click:Connect(function() set(not state) end)

    return { Set = function(_, v) set(v, false) end, Get = function() return state end }
end

-- ---- Placeholder ----
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

-- ---- Slider ----
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

-- ---- Dropdown ----
function Section:AddDropdown(text, options, default, callback)
    options = options or {}
    default = default or options[1] or ""

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
    listLayout(List, 0)

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

-- ---- Keybind-кнопка: клик -> "Press a key..." -> следующая нажатая клавиша ----
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
    KeyBtn.BackgroundColor3 = Theme.Element
    KeyBtn.AutoButtonColor = false
    KeyBtn.Font = Enum.Font.Gotham
    KeyBtn.TextSize = 12
    KeyBtn.TextColor3 = Theme.Text
    KeyBtn.Text = default and default.Name or "..."
    KeyBtn.Parent = Container
    corner(KeyBtn, 5)

    KeyBtn.MouseButton1Click:Connect(function()
        KeyBtn.Text = "..."
        window:CaptureNextKey(function(keyCode)
            KeyBtn.Text = keyCode.Name
            window:SetToggleKey(keyCode)
            if callback then callback(keyCode) end
        end)
    end)

    return KeyBtn
end

return Library
