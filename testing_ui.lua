local Library = loadstring(game:HttpGet("..."))()

-- Создаём окно в стиле Palantir X
local Window = Library:CreateWindow({
    Title = "Palantir X",
    Subtitle = "Eastern Luminant",
    Size = UDim2.fromOffset(720, 430),
    ToggleKey = Enum.KeyCode.RightControl
})

-- Вкладки
local Combat = Window:AddMainTab("Combat")
local Game = Window:AddMainTab("Game")
local Visuals = Window:AddMainTab("Visuals")
local Settings = Window:AddMainTab("Settings")

-- Подвкладки Combat
local Movement = Combat:AddSubTab("Movement")
local CombatTab = Combat:AddSubTab("Combat")
local Misc = Combat:AddSubTab("Misc")

-- Секции
local MovementSection = Movement:AddLeftSection("Movement")
local MiscSection = Movement:AddRightSection("Misc")

-- Элементы с keybind справа
MovementSection:AddToggle("Auto Parry Breaker", false, function(v) end, "F6", "AutoParry")
MovementSection:AddToggle("Mod Notifier", false, function(v) end, nil, "ModNotifier")
MovementSection:AddToggle("Extended Range", false, function(v) end, nil, "ExtendedRange")

-- Slider
local SliderSection = CombatTab:AddLeftSection("AP Breaker Intensity")
SliderSection:AddSlider("", 0, 1000000, 1000000, " anims", function(v) end, "APIntensity")

-- Добавляем меню настроек
Library:AddSettingsMenu(Window)

-- Показываем список кейбиндов
Window:SetKeybindListVisible(true)
