-- ========== ПОЛУЧАЕМ КЛЮЧ ИЗ URL ==========
local args = {...}
local script_key = args[1]

-- Если ключ не передан через аргументы, пробуем получить из URL параметра
if not script_key or script_key == "" then
    local success, result = pcall(function()
        local http = game:GetService("HttpService")
        local url = "https://raw.githubusercontent.com/crownedwithbloodytears/SimforeaHub/main/loader_core.lua"
        -- Этот метод не работает напрямую, поэтому используем другой подход
    end)
end

-- АЛЬТЕРНАТИВНЫЙ СПОСОБ: просим пользователя ввести ключ
if not script_key or script_key == "" then
    local plr = game.Players.LocalPlayer
    
    -- Создаём GUI для ввода ключа
    local keyGui = Instance.new("ScreenGui")
    keyGui.Name = "KeyInput"
    keyGui.Parent = plr.PlayerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 350, 0, 180)
    frame.Position = UDim2.new(0.5, -175, 0.5, -90)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    frame.BorderSizePixel = 0
    frame.Parent = keyGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 45)
    title.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    title.Text = "ENTER LICENSE KEY"
    title.TextColor3 = Color3.fromRGB(200, 200, 210)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.Parent = frame
    
    local keyBox = Instance.new("TextBox")
    keyBox.Size = UDim2.new(0.8, 0, 0, 40)
    keyBox.Position = UDim2.new(0.1, 0, 0.35, 0)
    keyBox.BackgroundColor3 = Color3.fromRGB(22, 22, 27)
    keyBox.TextColor3 = Color3.fromRGB(210, 210, 220)
    keyBox.PlaceholderText = "XXXXX-XXXXX-XXXXX-XXXXX"
    keyBox.TextSize = 12
    keyBox.Font = Enum.Font.Gotham
    keyBox.ClearTextOnFocus = true
    keyBox.Parent = frame
    
    local keyBoxCorner = Instance.new("UICorner")
    keyBoxCorner.CornerRadius = UDim.new(0, 6)
    keyBoxCorner.Parent = keyBox
    
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(0.8, 0, 0, 25)
    status.Position = UDim2.new(0.1, 0, 0.6, 0)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = Color3.fromRGB(200, 60, 60)
    status.TextSize = 11
    status.Font = Enum.Font.Gotham
    status.Parent = frame
    
    local submit = Instance.new("TextButton")
    submit.Size = UDim2.new(0.8, 0, 0, 35)
    submit.Position = UDim2.new(0.1, 0, 0.8, 0)
    submit.Text = "ACTIVATE"
    submit.BackgroundColor3 = Color3.fromRGB(35, 75, 45)
    submit.TextColor3 = Color3.new(1, 1, 1)
    submit.TextSize = 13
    submit.Font = Enum.Font.GothamBold
    submit.Parent = frame
    
    local submitCorner = Instance.new("UICorner")
    submitCorner.CornerRadius = UDim.new(0, 6)
    submitCorner.Parent = submit
    
    -- Ждём ввода ключа
    local keyEntered = nil
    submit.MouseButton1Click:Connect(function()
        keyEntered = string.gsub(keyBox.Text, "^%s*(.-)%s*$", "%1")
        if keyEntered ~= "" then
            keyGui:Destroy()
            script_key = keyEntered
            -- Продолжаем выполнение скрипта
            checkAndRun()
        else
            status.Text = "Please enter a key"
            status.TextColor3 = Color3.fromRGB(200, 100, 100)
        end
    end)
    
    keyBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            keyEntered = string.gsub(keyBox.Text, "^%s*(.-)%s*$", "%1")
            if keyEntered ~= "" then
                keyGui:Destroy()
                script_key = keyEntered
                checkAndRun()
            else
                status.Text = "Please enter a key"
                status.TextColor3 = Color3.fromRGB(200, 100, 100)
            end
        end
    end)
    
    -- Функция, которая выполнится после ввода ключа
    function checkAndRun()
        -- ВАЛИДНЫЕ КЛЮЧИ
        local validKeys = {
            "MOG7X-9K2P4-1L8N5-3V6M2",
            "ROK4A-7C3E9-2W5Q8-6B1T7",
            "PAN3D-5F8H1-9J4L7-2K6N9",
            "KEYS8-4M2V6-1X9C3-7B5R0",
            "CODE2-6Q4W8-3Z7L1-9F5H4"
        }
        
        local function checkKey(k)
            for _, v in ipairs(validKeys) do
                if v == k then
                    return true
                end
            end
            return false
        end
        
        if not checkKey(script_key) then
            local errGui = Instance.new("ScreenGui")
            errGui.Parent = game.Players.LocalPlayer.PlayerGui
            
            local errFrame = Instance.new("Frame")
            errFrame.Size = UDim2.new(0, 300, 0, 100)
            errFrame.Position = UDim2.new(0.5, -150, 0.5, -50)
            errFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
            errFrame.Parent = errGui
            
            local errText = Instance.new("TextLabel")
            errText.Size = UDim2.new(1, 0, 1, 0)
            errText.Text = "INVALID KEY\nAccess Denied"
            errText.TextColor3 = Color3.fromRGB(255, 50, 50)
            errText.TextSize = 16
            errText.Font = Enum.Font.GothamBold
            errText.Parent = errFrame
            
            wait(2)
            errGui:Destroy()
            return
        end
        
        -- КЛЮЧ ВЕРНЫЙ - ЗАПУСКАЕМ ОСНОВНОЙ СКРИПТ
        startMainScript()
    end
    
    -- Останавливаем выполнение здесь, ждём ввода ключа
    return
else
    -- Если ключ уже передан, просто проверяем
    local validKeys = {
        "MOG7X-9K2P4-1L8N5-3V6M2",
        "ROK4A-7C3E9-2W5Q8-6B1T7",
        "PAN3D-5F8H1-9J4L7-2K6N9",
        "KEYS8-4M2V6-1X9C3-7B5R0",
        "CODE2-6Q4W8-3Z7L1-9F5H4"
    }
    
    local function checkKey(k)
        for _, v in ipairs(validKeys) do
            if v == k then
                return true
            end
        end
        return false
    end
    
    if not checkKey(script_key) then
        local plr = game.Players.LocalPlayer
        local gui = Instance.new("ScreenGui")
        gui.Parent = plr.PlayerGui
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 300, 0, 100)
        frame.Position = UDim2.new(0.5, -150, 0.5, -50)
        frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        frame.Parent = gui
        
        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, 0, 1, 0)
        text.Text = "INVALID KEY\nAccess Denied"
        text.TextColor3 = Color3.fromRGB(255, 50, 50)
        text.TextSize = 16
        text.Font = Enum.Font.GothamBold
        text.Parent = frame
        
        wait(2)
        gui:Destroy()
        return
    end
    
    startMainScript()
end

-- ========== ОСНОВНОЙ СКРИПТ ==========
function startMainScript()
    local plr = game.Players.LocalPlayer
    print("✅ Key accepted! Loading Mog Panel...")
    
    -- ЭКРАН ЗАГРУЗКИ
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
end
