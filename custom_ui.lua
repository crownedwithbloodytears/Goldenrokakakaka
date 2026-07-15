--[[
    CustomLib_TopTabs (v3)

    Новое в этой версии:
      - Живая смена темы: Window:SetTheme("Ocean") и т.п. — меняет цвета
        уже существующих элементов без пересоздания меню (через реестр
        "themed"-инстансов и функции-геттеры, которые перечитывают Theme
        заново на каждое применение).
      - Список кейбиндов (Window:SetKeybindListVisible(true)) — отдельная
        перетаскиваемая панель, куда автоматически попадает любой Keybind,
        созданный через Section:AddKeybind(...).
      - Section:AddKeybind больше НЕ привязывает жёстко новую клавишу к
        открытию меню — теперь это просто "захват клавиши", а что с ней
        делать, решает callback (см. пример: там Menu Toggle Key явно
        вызывает Window:SetToggleKey(...) в своём собственном callback-е).
]]

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ====================== ТЕМЫ ======================
-- Между темами меняются только "структурные" цвета (фон/акцент/обводка).
-- Текст (Text/SubText/Disabled/White) везде одинаковый и не темизируется —
-- чтобы читаемость не зависела от выбранной темы.
local FixedColors = {
    Text     = Color3.fromRGB(198, 198, 203),
    SubText  = Color3.fromRGB(126, 126, 134),
    Disabled = Color3.fromRGB(78, 78, 84),
    White    = Color3.fromRGB(255, 255, 255),
}

local Themes = {
    Monochrome = {
        Background = Color3.fromRGB(14, 14, 16),
        TopBar     = Color3.fromRGB(19, 19, 22),
        Section    = Color3.fromRGB(21, 21, 24),
        Element    = Color3.fromRGB(31, 31, 35),
        Accent     = Color3.fromRGB(255, 255, 255),
        Stroke     = Color3.fromRGB(44, 44, 50),
    },
    Crimson = {
        Background = Color3.fromRGB(16, 12, 13),
        TopBar     = Color3.fromRGB(22, 16, 17),
        Section    = Color3.fromRGB(24, 17, 18),
        Element    = Color3.fromRGB(36, 24, 25),
        Accent     = Color3.fromRGB(230, 70, 70),
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
-- по имени инстанса, а не по порядку добавления.
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

-- Регистрирует свойство инстанса как "тематическое": сразу применяет цвет
-- из getter() и запоминает пару (инстанс, свойство, getter), чтобы при
-- смене темы можно было применить их заново. getter — функция, а не готовое
-- значение, потому что для динамических элементов (например, тоггл в
-- состоянии ON/OFF) правильный цвет зависит от текущего состояния, а не
-- только от темы.
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
    MainTabBar.BorderSizePixel = 0
    MainTabBar.Parent = Main
    reg(themedList, MainTabBar, "BackgroundColor3", function() return Theme.TopBar end)

    local mainTabList = listLayout(MainTabBar, 28, true)
    mainTabList.HorizontalAlignment = Enum.HorizontalAlignment.Center

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

-- ---- Темы ----
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
end

-- ---- Прочие настройки самого меню ----
function Window:SetToggleKey(keyCode)
    self.ToggleKey = keyCode
end

-- Ждём следующее нажатие клавиши и передаём её в callback.
-- Что делать с этой клавишей — решает вызывающий код (см. Section:AddKeybind).
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

-- ---- Список кейбиндов (отдельная перетаскиваемая панель) ----
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

    -- Перетаскивание панели
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

-- Добавляет строку в список и возвращает функцию для обновления текста клавиши
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

    return function(newKeyName)
        Row.Text = label .. ": " .. newKeyName
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

    -- Полоска-индикатор — ребёнок самой кнопки: её размер/позиция заданы в
    -- масштабе относительно родителя, поэтому она не может "уехать" не под
    -- свою вкладку независимо от таймингов пересчёта layout.
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

    -- Активная вкладка красится в акцент темы — регистрируем как "тематическую"
    -- с геттером, который проверяет, выбрана ли она СЕЙЧАС.
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
function MainTab:AddSubTab(name)
    local window = self.Window

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
    }, SubTab)

    table.insert(self.SubTabs, subTab)

    -- Фон кнопки таба зависит от состояния (активна/неактивна) — тематический геттер
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
function Section:AddToggle(text, default, callback)
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

    reg(window.ThemedInstances, Track, "BackgroundColor3", function()
        return state and Theme.Accent or Theme.Element
    end)
    reg(window.ThemedInstances, Knob, "BackgroundColor3", function()
        return state and Color3.fromRGB(20, 20, 20) or Theme.White
    end)
    reg(window.ThemedInstances, Label, "TextColor3", function()
        return state and Theme.Accent or Theme.Text
    end)

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
        if fire ~= false and callback then callback(state) end
    end

    Row.MouseButton1Click:Connect(function() set(not state) end)

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
function Section:AddSlider(text, min, max, default, unit, callback)
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

    local dragging = false
    local function update(inputPos)
        local rel = math.clamp((inputPos.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (max - min) * rel + 0.5)

        tween(Fill, TweenInfo.new(0.05), {Size = UDim2.fromScale(rel, 1)})
        ValueLabel.Text = tostring(value) .. unit .. "/" .. tostring(max) .. unit

        -- Автоматический контраст текста в зависимости от заполнения полосы
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

    return Container
end

-- ---- Dropdown ----
function Section:AddDropdown(text, options, default, callback)
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

    local function close()
        open = false
        tween(Arrow, TweenInfo.new(0.15), {Rotation = 0})
        tween(Container, TweenInfo.new(0.15), {Size = UDim2.new(1, 0, 0, 40)})
        local t = tween(List, TweenInfo.new(0.15), {Size = UDim2.new(1, 0, 0, 0)})
        t.Completed:Connect(function()
            if not open then List.Visible = false end
        end)
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
            tween(List, TweenInfo.new(0.15), {Size = UDim2.new(1, 0, 0, listHeight)})
            tween(Container, TweenInfo.new(0.15), {Size = UDim2.new(1, 0, 0, 40 + listHeight)})
        else
            close()
        end
    end)

    return {
        Set = function(_, v) SelectedLabel.Text = tostring(v) end,
        Close = close,
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

-- ---- Keybind: клик -> "..." -> следующая нажатая клавиша идёт в callback.
-- Автоматически появляется строкой в Window:SetKeybindListVisible(true) панели.
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
