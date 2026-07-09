--[[
    CustomLib
    Лёгкая анимированная UI-библиотека для Roblox.

    Особенности:
      - Плавное появление/скрытие окна (fade + scale)
      - Реальные (рабочие) анимированные переходы между вкладками (slide + порядок)
      - Анимированные Toggle (переключатель с бегающим кружком), Slider, Button (hover/press)
      - Тёмная тема со скруглёнными углами "из коробки"
      - Перетаскивание окна за шапку
      - Простая, предсказуемая структура: Window -> Tab -> Section -> элементы

    Использование смотри в CustomLib_Example.lua
]]

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local Library = {}
Library.__index = Library

-- ====================== ТЕМА ======================
Library.Theme = {
    Background = Color3.fromRGB(22, 22, 26),
    Section    = Color3.fromRGB(29, 29, 34),
    Element    = Color3.fromRGB(38, 38, 45),
    Accent     = Color3.fromRGB(114, 137, 255),
    Text       = Color3.fromRGB(235, 235, 240),
    SubText    = Color3.fromRGB(150, 150, 160),
    Stroke     = Color3.fromRGB(48, 48, 56),
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
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Library.Theme.Stroke
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

-- ====================== ОКНО ======================
function Library:CreateWindow(config)
    config = config or {}
    local title      = config.Title or "Menu"
    local size       = config.Size or UDim2.fromOffset(560, 380)
    local toggleKey  = config.ToggleKey or Enum.KeyCode.RightControl

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "CustomLibGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999
    local okParent = pcall(function() ScreenGui.Parent = CoreGui end)
    if not okParent or not ScreenGui.Parent then
        ScreenGui.Parent = PlayerGui
    end

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.Position = UDim2.fromScale(0.5, 0.5)
    Main.Size = size
    Main.BackgroundColor3 = Library.Theme.Background
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Main.Parent = ScreenGui
    corner(Main, 10)
    stroke(Main, Library.Theme.Stroke, 1)

    -- Шапка
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.BackgroundColor3 = Library.Theme.Section
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = Main
    corner(TitleBar, 10)

    -- Заглушка, чтобы низ шапки не был скруглён (перекрывает скругление снизу)
    local TitleBarFix = Instance.new("Frame")
    TitleBarFix.BackgroundColor3 = Library.Theme.Section
    TitleBarFix.BorderSizePixel = 0
    TitleBarFix.Position = UDim2.new(0, 0, 1, -10)
    TitleBarFix.Size = UDim2.new(1, 0, 0, 10)
    TitleBarFix.ZIndex = TitleBar.ZIndex
    TitleBarFix.Parent = TitleBar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Position = UDim2.new(0, 16, 0, 0)
    TitleLabel.Size = UDim2.new(1, -80, 1, 0)
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = title
    TitleLabel.TextColor3 = Library.Theme.Text
    TitleLabel.TextSize = 16
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TitleBar

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Text = "×"
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 20
    CloseBtn.TextColor3 = Library.Theme.SubText
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.AutoButtonColor = false
    CloseBtn.Size = UDim2.fromOffset(32, 32)
    CloseBtn.Position = UDim2.new(1, -38, 0, 4)
    CloseBtn.Parent = TitleBar

    CloseBtn.MouseEnter:Connect(function()
        tween(CloseBtn, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(255, 90, 90)})
    end)
    CloseBtn.MouseLeave:Connect(function()
        tween(CloseBtn, TweenInfo.new(0.15), {TextColor3 = Library.Theme.SubText})
    end)

    -- Перетаскивание окна
    do
        local dragging, dragStart, startPos
        TitleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = Main.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                Main.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end)
    end

    -- Боковая панель с табами
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Position = UDim2.new(0, 0, 0, 40)
    Sidebar.Size = UDim2.new(0, 130, 1, -40)
    Sidebar.BackgroundColor3 = Library.Theme.Section
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = Main

    local SidebarList = Instance.new("UIListLayout")
    SidebarList.Padding = UDim.new(0, 4)
    SidebarList.Parent = Sidebar
    padUniform(Sidebar, 8)

    -- Область контента
    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Position = UDim2.new(0, 130, 0, 40)
    Content.Size = UDim2.new(1, -130, 1, -40)
    Content.BackgroundTransparency = 1
    Content.ClipsDescendants = true
    Content.Parent = Main

    local Window = setmetatable({
        ScreenGui    = ScreenGui,
        Main         = Main,
        Sidebar      = Sidebar,
        Content      = Content,
        Tabs         = {},
        CurrentTab   = nil,
        Visible      = true,
        OriginalSize = size,
    }, Library)

    -- Анимация появления окна
    Main.Size = UDim2.new(size.X.Scale, size.X.Offset, size.Y.Scale, math.floor(size.Y.Offset * 0.85))
    Main.BackgroundTransparency = 1
    tween(Main, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = size,
        BackgroundTransparency = 0,
    })

    CloseBtn.MouseButton1Click:Connect(function()
        Window:SetVisible(false)
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == toggleKey then
            Window:SetVisible(not Window.Visible)
        end
    end)

    return Window
end

function Library:SetVisible(state)
    self.Visible = state
    local size = self.OriginalSize

    if state then
        self.ScreenGui.Enabled = true
        self.Main.Size = UDim2.new(size.X.Scale, size.X.Offset, size.Y.Scale, math.floor(size.Y.Offset * 0.9))
        self.Main.BackgroundTransparency = 1
        tween(self.Main, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = size,
            BackgroundTransparency = 0,
        })
    else
        local t = tween(self.Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
        })
        t.Completed:Connect(function()
            if not self.Visible then
                self.ScreenGui.Enabled = false
            end
        end)
    end
end

-- ====================== ТАБЫ ======================
function Library:AddTab(name)
    local TabButton = Instance.new("TextButton")
    TabButton.Size = UDim2.new(1, 0, 0, 32)
    TabButton.BackgroundColor3 = Library.Theme.Element
    TabButton.AutoButtonColor = false
    TabButton.Text = ""
    TabButton.Parent = self.Sidebar
    corner(TabButton, 6)

    local TabLabel = Instance.new("TextLabel")
    TabLabel.BackgroundTransparency = 1
    TabLabel.Size = UDim2.new(1, -16, 1, 0)
    TabLabel.Position = UDim2.new(0, 12, 0, 0)
    TabLabel.Text = name
    TabLabel.Font = Enum.Font.Gotham
    TabLabel.TextSize = 14
    TabLabel.TextColor3 = Library.Theme.SubText
    TabLabel.TextXAlignment = Enum.TextXAlignment.Left
    TabLabel.Parent = TabButton

    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.fromScale(1, 1)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 3
    Page.ScrollBarImageColor3 = Library.Theme.Accent
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.Visible = false
    Page.Parent = self.Content

    local PageList = Instance.new("UIListLayout")
    PageList.Padding = UDim.new(0, 8)
    PageList.Parent = Page
    padUniform(Page, 12)

    local windowRef = self
    local Tab = setmetatable({
        Button = TabButton,
        Label  = TabLabel,
        Page   = Page,
        Window = windowRef,
    }, Library)

    table.insert(self.Tabs, Tab)

    TabButton.MouseButton1Click:Connect(function()
        windowRef:SelectTab(Tab)
    end)

    TabButton.MouseEnter:Connect(function()
        if windowRef.CurrentTab ~= Tab then
            tween(TabButton, TweenInfo.new(0.15), {BackgroundColor3 = Library.Theme.Stroke})
        end
    end)
    TabButton.MouseLeave:Connect(function()
        if windowRef.CurrentTab ~= Tab then
            tween(TabButton, TweenInfo.new(0.15), {BackgroundColor3 = Library.Theme.Element})
        end
    end)

    if not self.CurrentTab then
        self:SelectTab(Tab)
    end

    return Tab
end

-- Реальный, подключенный переход между вкладками (slide)
function Library:SelectTab(tab)
    if self.CurrentTab == tab then return end
    local old = self.CurrentTab
    self.CurrentTab = tab

    if old then
        tween(old.Button, TweenInfo.new(0.15), {BackgroundColor3 = Library.Theme.Element})
        tween(old.Label, TweenInfo.new(0.15), {TextColor3 = Library.Theme.SubText})

        local oldPage = old.Page
        tween(oldPage, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0, -24, 0, 0),
        })
        task.delay(0.18, function()
            oldPage.Visible = false
            oldPage.Position = UDim2.new(0, 0, 0, 0)
        end)
    end

    tween(tab.Button, TweenInfo.new(0.15), {BackgroundColor3 = Library.Theme.Accent})
    tween(tab.Label, TweenInfo.new(0.15), {TextColor3 = Library.Theme.White})

    local page = tab.Page
    page.Visible = true
    page.Position = UDim2.new(0, 24, 0, 0)
    tween(page, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
    })
end

-- ====================== СЕКЦИИ (группы элементов) ======================
function Library:AddSection(name)
    local Section = Instance.new("Frame")
    Section.BackgroundColor3 = Library.Theme.Section
    Section.BorderSizePixel = 0
    Section.Size = UDim2.new(1, 0, 0, 0)
    Section.AutomaticSize = Enum.AutomaticSize.Y
    Section.Parent = self.Page
    corner(Section, 8)
    stroke(Section, Library.Theme.Stroke, 1)

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 8)
    Layout.Parent = Section
    padUniform(Section, 12)

    local Title = Instance.new("TextLabel")
    Title.BackgroundTransparency = 1
    Title.Size = UDim2.new(1, 0, 0, 18)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 13
    Title.TextColor3 = Library.Theme.SubText
    Title.Text = name
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.LayoutOrder = 0
    Title.Parent = Section

    return setmetatable({ Frame = Section, Order = 1 }, Library)
end

function Library:_newOrder()
    self.Order = (self.Order or 1) + 1
    return self.Order
end

-- ====================== ЭЛЕМЕНТЫ ======================
function Library:AddButton(text, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 32)
    Btn.BackgroundColor3 = Library.Theme.Element
    Btn.AutoButtonColor = false
    Btn.Font = Enum.Font.Gotham
    Btn.TextSize = 14
    Btn.TextColor3 = Library.Theme.Text
    Btn.Text = text
    Btn.LayoutOrder = self:_newOrder()
    Btn.Parent = self.Frame
    corner(Btn, 6)

    local originalColor = Library.Theme.Element
    Btn.MouseEnter:Connect(function()
        tween(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Library.Theme.Accent})
    end)
    Btn.MouseLeave:Connect(function()
        tween(Btn, TweenInfo.new(0.15), {BackgroundColor3 = originalColor})
    end)
    Btn.MouseButton1Down:Connect(function()
        tween(Btn, TweenInfo.new(0.08), {Size = UDim2.new(1, 0, 0, 29)})
    end)
    Btn.MouseButton1Up:Connect(function()
        tween(Btn, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 32)})
    end)
    Btn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)

    return Btn
end

function Library:AddToggle(text, default, callback)
    default = default or false

    local Container = Instance.new("TextButton")
    Container.Size = UDim2.new(1, 0, 0, 32)
    Container.BackgroundColor3 = Library.Theme.Element
    Container.AutoButtonColor = false
    Container.Text = ""
    Container.LayoutOrder = self:_newOrder()
    Container.Parent = self.Frame
    corner(Container, 6)

    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.Size = UDim2.new(1, -70, 1, 0)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 14
    Label.TextColor3 = Library.Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Text = text
    Label.Parent = Container

    local Track = Instance.new("Frame")
    Track.Size = UDim2.fromOffset(38, 20)
    Track.Position = UDim2.new(1, -50, 0.5, -10)
    Track.BackgroundColor3 = default and Library.Theme.Accent or Library.Theme.Stroke
    Track.Parent = Container
    corner(Track, 10)

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.fromOffset(16, 16)
    Knob.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    Knob.BackgroundColor3 = Library.Theme.White
    Knob.Parent = Track
    corner(Knob, 8)

    local state = default

    local function set(v, fire)
        state = v
        tween(Track, TweenInfo.new(0.18), {
            BackgroundColor3 = state and Library.Theme.Accent or Library.Theme.Stroke
        })
        tween(Knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
            Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        })
        if fire ~= false and callback then callback(state) end
    end

    Container.MouseButton1Click:Connect(function()
        set(not state)
    end)

    return {
        Set = function(_, v) set(v, false) end,
        Get = function() return state end,
    }
end

function Library:AddSlider(text, min, max, default, callback)
    min = min or 0
    max = max or 100
    default = math.clamp(default or min, min, max)

    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 46)
    Container.BackgroundColor3 = Library.Theme.Element
    Container.LayoutOrder = self:_newOrder()
    Container.Parent = self.Frame
    corner(Container, 6)

    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 12, 0, 4)
    Label.Size = UDim2.new(1, -80, 0, 16)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 13
    Label.TextColor3 = Library.Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Text = text
    Label.Parent = Container

    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Position = UDim2.new(1, -68, 0, 4)
    ValueLabel.Size = UDim2.new(0, 56, 0, 16)
    ValueLabel.Font = Enum.Font.Gotham
    ValueLabel.TextSize = 13
    ValueLabel.TextColor3 = Library.Theme.SubText
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.Text = tostring(default)
    ValueLabel.Parent = Container

    local Bar = Instance.new("Frame")
    Bar.Position = UDim2.new(0, 12, 0, 28)
    Bar.Size = UDim2.new(1, -24, 0, 6)
    Bar.BackgroundColor3 = Library.Theme.Stroke
    Bar.Parent = Container
    corner(Bar, 3)

    local Fill = Instance.new("Frame")
    Fill.BackgroundColor3 = Library.Theme.Accent
    Fill.Size = UDim2.fromScale((default - min) / (max - min), 1)
    Fill.Parent = Bar
    corner(Fill, 3)

    local dragging = false
    local function update(inputPos)
        local rel = math.clamp((inputPos.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (max - min) * rel + 0.5)
        tween(Fill, TweenInfo.new(0.05), {Size = UDim2.fromScale(rel, 1)})
        ValueLabel.Text = tostring(value)
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

function Library:AddLabel(text)
    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Size = UDim2.new(1, 0, 0, 18)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 13
    Label.TextColor3 = Library.Theme.SubText
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Text = text
    Label.LayoutOrder = self:_newOrder()
    Label.Parent = self.Frame
    return Label
end

return Library
