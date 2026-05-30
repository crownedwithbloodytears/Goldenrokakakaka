-- Universal Hub - Movement + Player ESP + Anti Fall Damage
-- Works on any Roblox game

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Camera = workspace.CurrentCamera or workspace:WaitForChild("CurrentCamera")

-- Check Drawing API
local hasDrawing = pcall(Drawing.new, "Text")
if not hasDrawing then
    warn("Drawing API not supported – ESP disabled")
end

print("========================================")
print("[Universal Hub] Loading...")
print("========================================")

local player = Players.LocalPlayer

-- ==================== SETTINGS ====================
local DEFAULT_SPEEDHACK_ENABLED = false
local DEFAULT_INFINITE_JUMP_ENABLED = false
local DEFAULT_NOCLIP_ENABLED = false
local DEFAULT_ANTI_FALL_DAMAGE_ENABLED = false

local DEFAULT_SPEED = 200
local DEFAULT_INFINITE_JUMP_BOOST = 150

local MIN_SPEED = 50
local MAX_SPEED = 750

-- ==================== GLOBAL VARIABLES ====================
local speedhackEnabled = DEFAULT_SPEEDHACK_ENABLED
local infiniteJumpEnabled = DEFAULT_INFINITE_JUMP_ENABLED
local noclipEnabled = DEFAULT_NOCLIP_ENABLED
local antiFallDamageEnabled = DEFAULT_ANTI_FALL_DAMAGE_ENABLED

local currentSpeed = DEFAULT_SPEED
local currentInfiniteJumpBoost = DEFAULT_INFINITE_JUMP_BOOST

-- Player ESP settings
local playerEspEnabled = false
local playerNameEnabled = true
local playerDistanceEnabled = true
local playerBoxEnabled = true
local playerHealthEnabled = true
local espColor = Color3.fromRGB(0, 255, 255)
local maxDistance = 1000

-- ESP objects storage
local playerEspObjects = {}

-- Noclip connection
local noclipConnection = nil

-- FallDamage connection
local fallDamageConnection = nil
local currentFallDamageObject = nil

-- ==================== UTILITY ====================
local function safeNotify(title, content, duration)
    pcall(function()
        if Rayfield then
            Rayfield:Notify({
                Title = title,
                Content = content,
                Duration = duration or 3
            })
        end
    end)
    print("[Simforea Universal] " .. title .. ": " .. content)
end

-- ==================== ANTI FALL DAMAGE ====================
-- Функция поиска FallDamage объекта у текущего персонажа
local function findFallDamageForCharacter(character)
    if not character or not character.Parent then return nil end
    
    -- Ищем в workspace папку с именем персонажа
    local characterFolder = Workspace:FindFirstChild(character.Name)
    if characterFolder then
        -- Ищем FallDamage внутри папки персонажа
        local fallDamage = characterFolder:FindFirstChild("FallDamage")
        if fallDamage then
            return fallDamage
        end
    end
    
    -- Альтернативный поиск: ищем любой FallDamage в workspace, который связан с этим персонажем
    for _, child in ipairs(Workspace:GetChildren()) do
        local fallDamage = child:FindFirstChild("FallDamage")
        if fallDamage and child.Name == character.Name then
            return fallDamage
        end
    end
    
    return nil
end

-- Функция применения Anti Fall Damage
local function applyAntiFallDamage()
    local character = player.Character
    if not character then return end
    
    -- Ищем FallDamage для текущего персонажа
    local fallDamage = findFallDamageForCharacter(character)
    
    if fallDamage then
        currentFallDamageObject = fallDamage
        -- Отключаем урон от падения
        fallDamage.Disabled = antiFallDamageEnabled
        if antiFallDamageEnabled then
            safeNotify("Anti Fall Damage", "Disabled! (No fall damage)", 2)
        else
            safeNotify("Anti Fall Damage", "Enabled (Normal fall damage)", 2)
        end
    else
        -- Если не нашли, пробуем поискать позже
        task.wait(1)
        local retryFallDamage = findFallDamageForCharacter(character)
        if retryFallDamage then
            currentFallDamageObject = retryFallDamage
            retryFallDamage.Disabled = antiFallDamageEnabled
        end
    end
end

-- Следим за появлением персонажа и обновляем FallDamage
local function setupAntiFallDamage()
    if fallDamageConnection then
        fallDamageConnection:Disconnect()
        fallDamageConnection = nil
    end
    
    -- Применяем сразу если персонаж есть
    if player.Character then
        applyAntiFallDamage()
    end
    
    -- Следим за появлением новой папки в workspace (когда персонаж заспавнится)
    fallDamageConnection = Workspace.ChildAdded:Connect(function(child)
        if player.Character and child.Name == player.Character.Name then
            task.wait(0.5) -- Даём время на создание всех объектов
            applyAntiFallDamage()
        end
    end)
    
    -- Также следим за добавлением FallDamage внутрь существующей папки
    local characterFolder = Workspace:FindFirstChild(player.Character and player.Character.Name)
    if characterFolder then
        characterFolder.ChildAdded:Connect(function(child)
            if child.Name == "FallDamage" then
                currentFallDamageObject = child
                child.Disabled = antiFallDamageEnabled
            end
        end)
    end
end

-- Функция обновления состояния Anti Fall Damage при переключении тогла
local function updateAntiFallDamageState()
    if currentFallDamageObject and currentFallDamageObject.Parent then
        currentFallDamageObject.Disabled = antiFallDamageEnabled
        if antiFallDamageEnabled then
            safeNotify("Anti Fall Damage", "Disabled! (No fall damage)", 2)
        else
            safeNotify("Anti Fall Damage", "Enabled (Normal fall damage)", 2)
        end
    else
        -- Если объект потерян, пробуем найти заново
        applyAntiFallDamage()
    end
end

-- ==================== PLAYER ESP ====================
if hasDrawing then
    function createPlayerESPObject(plr)
        if playerEspObjects[plr] then return end
        
        local nameLabel = Drawing.new("Text")
        nameLabel.Size = 14
        nameLabel.Center = true
        nameLabel.Outline = true
        nameLabel.Color = espColor
        nameLabel.Text = plr.Name
        nameLabel.Visible = false
        
        local distanceLabel = Drawing.new("Text")
        distanceLabel.Size = 11
        distanceLabel.Center = true
        distanceLabel.Outline = true
        distanceLabel.Color = Color3.fromRGB(200, 200, 200)
        distanceLabel.Visible = false
        
        local healthLabel = Drawing.new("Text")
        healthLabel.Size = 11
        healthLabel.Center = true
        healthLabel.Outline = true
        healthLabel.Color = Color3.fromRGB(0, 255, 0)
        healthLabel.Visible = false
        
        local box = Drawing.new("Square")
        box.Thickness = 1
        box.Filled = false
        box.Color = espColor
        box.Visible = false
        
        playerEspObjects[plr] = {
            nameLabel = nameLabel,
            distanceLabel = distanceLabel,
            healthLabel = healthLabel,
            box = box,
            player = plr
        }
    end

    function removePlayerESP(plr)
        local obj = playerEspObjects[plr]
        if not obj then return end
        if obj.nameLabel then obj.nameLabel:Remove() end
        if obj.distanceLabel then obj.distanceLabel:Remove() end
        if obj.healthLabel then obj.healthLabel:Remove() end
        if obj.box then obj.box:Remove() end
        playerEspObjects[plr] = nil
    end

    function updatePlayerESP()
        if not playerEspEnabled then
            for plr, _ in pairs(playerEspObjects) do
                removePlayerESP(plr)
            end
            return
        end

        local localPlayer = Players.LocalPlayer
        if not localPlayer or not localPlayer.Character then return end
        local localRoot = localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not localRoot then return end

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= localPlayer then
                local character = plr.Character
                if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid") then
                    local rootPart = character.HumanoidRootPart
                    local humanoid = character.Humanoid
                    local position = rootPart.Position
                    local distance = (localRoot.Position - position).Magnitude
                    
                    if distance <= maxDistance then
                        if not playerEspObjects[plr] then
                            createPlayerESPObject(plr)
                        end
                        
                        local obj = playerEspObjects[plr]
                        if obj then
                            local pos, onScreen = Camera:WorldToViewportPoint(position + Vector3.new(0, 2.5, 0))
                            
                            if onScreen then
                                local screenSize = Camera.ViewportSize
                                local headPos, headOnScreen = Camera:WorldToViewportPoint(position + Vector3.new(0, 2.5, 0))
                                local feetPos, feetOnScreen = Camera:WorldToViewportPoint(position - Vector3.new(0, 2, 0))
                                
                                if headOnScreen and feetOnScreen then
                                    local height = math.abs(headPos.Y - feetPos.Y)
                                    local width = height * 0.5
                                    local left = headPos.X - width / 2
                                    local top = headPos.Y - height
                                    
                                    if playerBoxEnabled then
                                        obj.box.Position = Vector2.new(left, top)
                                        obj.box.Size = Vector2.new(width, height)
                                        obj.box.Visible = true
                                        obj.box.Color = espColor
                                    else
                                        obj.box.Visible = false
                                    end
                                else
                                    obj.box.Visible = false
                                end
                                
                                if playerNameEnabled then
                                    obj.nameLabel.Position = Vector2.new(pos.X, pos.Y - 35)
                                    obj.nameLabel.Text = plr.Name
                                    obj.nameLabel.Visible = true
                                else
                                    obj.nameLabel.Visible = false
                                end
                                
                                if playerDistanceEnabled then
                                    obj.distanceLabel.Text = string.format("%.0f", distance)
                                    obj.distanceLabel.Position = Vector2.new(pos.X, pos.Y - 20)
                                    obj.distanceLabel.Visible = true
                                else
                                    obj.distanceLabel.Visible = false
                                end
                                
                                if playerHealthEnabled and humanoid then
                                    local healthPercent = humanoid.Health / humanoid.MaxHealth
                                    local healthColor = Color3.fromRGB(
                                        255 * (1 - healthPercent),
                                        255 * healthPercent,
                                        0
                                    )
                                    obj.healthLabel.Text = string.format("%.0f%%", healthPercent * 100)
                                    obj.healthLabel.Position = Vector2.new(pos.X, pos.Y - 5)
                                    obj.healthLabel.Color = healthColor
                                    obj.healthLabel.Visible = true
                                else
                                    obj.healthLabel.Visible = false
                                end
                            else
                                obj.nameLabel.Visible = false
                                obj.distanceLabel.Visible = false
                                obj.healthLabel.Visible = false
                                obj.box.Visible = false
                            end
                        end
                    else
                        if playerEspObjects[plr] then
                            local obj = playerEspObjects[plr]
                            if obj then
                                obj.nameLabel.Visible = false
                                obj.distanceLabel.Visible = false
                                obj.healthLabel.Visible = false
                                obj.box.Visible = false
                            end
                        end
                    end
                else
                    if playerEspObjects[plr] then
                        removePlayerESP(plr)
                    end
                end
            end
        end
    end
else
    createPlayerESPObject = function() end
    removePlayerESP = function() end
    updatePlayerESP = function() end
end

-- ==================== NOCLIP ====================
local function startNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    
    noclipConnection = RunService.Heartbeat:Connect(function()
        if noclipEnabled then
            local character = Players.LocalPlayer.Character
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        pcall(function()
                            part.CanCollide = false
                        end)
                    end
                end
            end
        end
    end)
end

local function stopNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    
    local character = Players.LocalPlayer.Character
    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function()
                    part.CanCollide = true
                end)
            end
        end
    end
end

-- ==================== SPEEDHACK ====================
local lastSpeedUpdate = 0
local function updateSpeedhack()
    if not speedhackEnabled then return end
    if tick() - lastSpeedUpdate < 0.05 then return end
    lastSpeedUpdate = tick()

    local localPlayer = Players.LocalPlayer
    if not localPlayer or not localPlayer.Character then return end
    local humanoid = localPlayer.Character:FindFirstChild("Humanoid")
    local rootPart = localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end

    local moveDirection = humanoid.MoveDirection
    if moveDirection.Magnitude <= 0.001 then return end

    local newVelocity = (moveDirection.Unit * currentSpeed) + Vector3.new(0, rootPart.AssemblyLinearVelocity.Y, 0)
    rootPart.AssemblyLinearVelocity = newVelocity
end

-- ==================== INFINITE JUMP ====================
local lastJumpTime = 0
local function updateInfiniteJump()
    if not infiniteJumpEnabled then return end
    if tick() - lastJumpTime < 0.2 then return end

    local localPlayer = Players.LocalPlayer
    if not localPlayer or not localPlayer.Character then return end
    local rootPart = localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        lastJumpTime = tick()
        rootPart.AssemblyLinearVelocity = Vector3.new(
            rootPart.AssemblyLinearVelocity.X,
            currentInfiniteJumpBoost,
            rootPart.AssemblyLinearVelocity.Z
        )
    end
end

-- ==================== RAYFIELD UI ====================
print("[Universal Hub] Loading Rayfield...")

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Simforea Hub",
    Icon = 0,
    LoadingTitle = "K2 Climbing",
    LoadingSubtitle = "there's no ac?",
    Theme = "Default",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "SimforeaHub",
        FileName = "Settings"
    },
    KeySystem = false
})

print("Hello")

-- ==================== TABS ====================
local MovementTab = Window:CreateTab("Movement", 0)
local ESPTab = Window:CreateTab("Player ESP", 0)
local InfoTab = Window:CreateTab("Info", 0)

-- ==================== MOVEMENT TAB ====================
MovementTab:CreateToggle({
    Name = "Speedhack",
    CurrentValue = speedhackEnabled,
    Callback = function(v) speedhackEnabled = v end
})

MovementTab:CreateSlider({
    Name = "Speed Value",
    Range = {MIN_SPEED, MAX_SPEED},
    Increment = 1,
    Suffix = "studs/s",
    CurrentValue = currentSpeed,
    Callback = function(v) currentSpeed = v end
})

MovementTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = infiniteJumpEnabled,
    Callback = function(v) infiniteJumpEnabled = v end
})

MovementTab:CreateSlider({
    Name = "Jump Boost Power",
    Range = {10, 200},
    Increment = 5,
    Suffix = "studs/s",
    CurrentValue = currentInfiniteJumpBoost,
    Callback = function(v) currentInfiniteJumpBoost = v end
})

MovementTab:CreateToggle({
    Name = "NoClip (Walk through walls)",
    CurrentValue = noclipEnabled,
    Callback = function(v)
        noclipEnabled = v
        if v then
            startNoclip()
            safeNotify("NoClip", "Enabled!", 2)
        else
            stopNoclip()
            safeNotify("NoClip", "Disabled!", 2)
        end
    end
})

-- ==================== ANTI FALL DAMAGE TOGGLE ====================
MovementTab:CreateToggle({
    Name = "Anti Fall Damage (No fall damage)",
    CurrentValue = antiFallDamageEnabled,
    Callback = function(v)
        antiFallDamageEnabled = v
        updateAntiFallDamageState()
    end
})

-- ==================== PLAYER ESP TAB ====================
ESPTab:CreateToggle({
    Name = "Enable Player ESP",
    CurrentValue = playerEspEnabled,
    Callback = function(v)
        playerEspEnabled = v
        if not v then
            for plr, _ in pairs(playerEspObjects) do
                removePlayerESP(plr)
            end
        end
    end
})

ESPTab:CreateColorPicker({
    Name = "ESP Color",
    Color = espColor,
    Callback = function(c)
        espColor = c
        for _, obj in pairs(playerEspObjects) do
            if obj.nameLabel then obj.nameLabel.Color = c end
            if obj.box then obj.box.Color = c end
        end
    end
})

ESPTab:CreateToggle({
    Name = "Show Player Name",
    CurrentValue = playerNameEnabled,
    Callback = function(v) playerNameEnabled = v end
})

ESPTab:CreateToggle({
    Name = "Show Distance",
    CurrentValue = playerDistanceEnabled,
    Callback = function(v) playerDistanceEnabled = v end
})

ESPTab:CreateToggle({
    Name = "Show Health (%)",
    CurrentValue = playerHealthEnabled,
    Callback = function(v) playerHealthEnabled = v end
})

ESPTab:CreateToggle({
    Name = "Show Box (2D)",
    CurrentValue = playerBoxEnabled,
    Callback = function(v) playerBoxEnabled = v end
})

ESPTab:CreateSlider({
    Name = "Max ESP Distance",
    Range = {100, 5000},
    Increment = 50,
    Suffix = "studs",
    CurrentValue = maxDistance,
    Callback = function(v) maxDistance = v end
})

-- ==================== INFO TAB ====================
InfoTab:CreateParagraph({
    Title = "Universal Hub",
    Content = "nothing special here"
})

-- ==================== MAIN LOOP ====================
RunService.RenderStepped:Connect(function()
    pcall(updatePlayerESP)
    pcall(updateSpeedhack)
    pcall(updateInfiniteJump)
end)

-- Handle player added/removed for ESP
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.5)
        if playerEspObjects[plr] then
            removePlayerESP(plr)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(plr)
    if playerEspObjects[plr] then
        removePlayerESP(plr)
    end
end)

-- Reconnect noclip and anti fall damage on character respawn
Players.LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if noclipEnabled then
        startNoclip()
    end
    applyAntiFallDamage()
end)

if noclipEnabled then
    startNoclip()
end

-- Запускаем Anti Fall Damage систему
setupAntiFallDamage()

safeNotify("Simforea Universal", 3)
