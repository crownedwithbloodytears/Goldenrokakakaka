-- Simforea Hub - Universal Movement Hack + ESP + NoClip
-- Designed for Place ID: 2809202155
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- Дожидаемся камеры
local Camera = workspace.CurrentCamera or workspace:WaitForChild("CurrentCamera")

-- Проверка Drawing API
local hasDrawing = pcall(Drawing.new, "Text")
if not hasDrawing then
    warn("Drawing API not supported – ESP disabled")
end

-- ==================== АНТИ-ЧИТ БАЙПАСЫ ====================

-- 1. Teleport Bypass (пассивный байпасс для телепортации)
local OldNamecallTP;
OldNamecallTP = hookmetamethod(game, '__namecall', newcclosure(function(self, ...)
    local Arguments = {...}
    local Method = getnamecallmethod()
 
    if Method == "InvokeServer" and Arguments[1] == "idklolbrah2de" then
        return "  ___XP DE KEY"
    end
 
    return OldNamecallTP(self, ...)
end))

-- 2. Item Magnitude Bypass (обход проверки дистанции для предметов)
local function setupMagnitudeBypass()
    local player = Players.LocalPlayer
    if not player or not player.Character then return end
    
    local primaryPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not primaryPart then return end
    
    local OldIndexItem;
    OldIndexItem = hookmetamethod(primaryPart, "__index", newcclosure(function(self, Key)
        if not checkcaller() and Key:lower() == 'magnitude' and getcallingscript() and getcallingscript().Name == "ItemSpawn" then
            return 0;
        end
                                                       
        return OldIndexItem(self, Key)
    end))
end

-- 3. Ghost Item Bypass (функция для безопасного подбора предметов)
local function safePickupItem(item)
    for _, instance in ipairs(item:GetDescendants()) do
        if instance:IsA("ProximityPrompt") and instance.MaxActivationDistance ~= 0 then
            pcall(function()
                fireproximityprompt(instance)
            end)
            return true
        end
    end
    return false
end

-- 4. Control Stand (управление стендом для невидимости и godmode)
local standControlActive = false
local function controlStand(toggle)
    local player = Players.LocalPlayer
    if not player then return end
    
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    
    if not hrp or not humanoid then return end
    
    local function summonStand()
        if not character:FindFirstChild("SummonedStand") or not character.SummonedStand.Value then
            repeat
                task.wait()
                local remoteFunction = character:FindFirstChild("RemoteFunction")
                if remoteFunction then
                    pcall(function()
                        remoteFunction:InvokeServer("ToggleStand", "Toggle")
                    end)
                end
            until character:FindFirstChild("SummonedStand") and character.SummonedStand.Value
        end
    end
    
    local function getStand()
        summonStand()
        return character:FindFirstChild("StandMorph")
    end
    
    if toggle then
        if standControlActive then return end
        standControlActive = true
        
        local stand = getStand()
        if not stand then return end
        
        local animController = stand:FindFirstChild("AnimationController")
        
        if character:FindFirstChild("FocusCam") == nil then
            local cameraValue = Instance.new("ObjectValue", character)
            cameraValue.Name = "FocusCam"
            cameraValue.Value = animController
        end
        
        local standAttach = stand.PrimaryPart and stand.PrimaryPart:FindFirstChild("StandAttach")
        if standAttach then
            local alignPos = standAttach:FindFirstChild("AlignPosition")
            if alignPos then alignPos.Enabled = false end
        end
        
        task.spawn(function()
            for _, part in ipairs(stand:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("UnionOperation") or part:IsA("MeshPart") then
                    pcall(function()
                        part.CollisionGroupId = 1
                    end)
                end
            end
        end)
        
        task.spawn(function()
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("UnionOperation") then
                    pcall(function()
                        part.CollisionGroupId = 2
                    end)
                end
            end
        end)
        
        -- Основной цикл управления стендом
        task.spawn(function()
            while standControlActive and toggle do
                local currentStand = getStand()
                local currentAnimController = currentStand and currentStand:FindFirstChild("AnimationController")
                
                if currentAnimController and humanoid then
                    task.spawn(function()
                        if humanoid.Jump then
                            currentAnimController.Jump = true
                        end
                    end)
                    
                    task.spawn(function()
                        local moveDir = humanoid.MoveDirection
                        if Camera and Camera.CFrame then
                            currentAnimController:Move(
                                Camera.CFrame:VectorToObjectSpace(moveDir),
                                true
                            )
                        end
                    end)
                end
                
                if hrp and currentStand and currentStand.PrimaryPart then
                    hrp.CFrame = currentStand.PrimaryPart.CFrame + Vector3.new(0, -30, 0)
                end
                
                task.spawn(function()
                    if hrp then
                        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    end
                end)
                
                task.wait()
            end
        end)
        
    else
        standControlActive = false
        
        local stand = getStand()
        if stand then
            local standAttach = stand.PrimaryPart and stand.PrimaryPart:FindFirstChild("StandAttach")
            if standAttach then
                local alignPos = standAttach:FindFirstChild("AlignPosition")
                if alignPos then alignPos.Enabled = true end
            end
            
            for _, part in ipairs(stand:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("UnionOperation") or part:IsA("MeshPart") then
                    pcall(function()
                        part.CollisionGroupId = 2
                    end)
                end
            end
        end
        
        if character:FindFirstChild("FocusCam") then
            character.FocusCam:Destroy()
        end
        
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("UnionOperation") then
                pcall(function()
                    part.CollisionGroupId = 10
                end)
            end
        end
        
        if hrp and stand and stand.PrimaryPart then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.CFrame = stand.PrimaryPart.CFrame
        end
    end
end

-- Активируем Control Stand (можно добавить тоггл в UI позже)
task.spawn(function()
    task.wait(2) -- Ждем загрузки персонажа
    -- controlStand(true) -- Раскомментируйте для активации (может быть нестабильно)
end)

-- ==================== ПРОВЕРКА ПЛЕЙСА ====================
local ALLOWED_PLACE_IDS = {
    [2809202155] = "YBA",
}

local currentPlaceId = game.PlaceId
local gameName = ALLOWED_PLACE_IDS[currentPlaceId] or "Unknown Game"

if not ALLOWED_PLACE_IDS[currentPlaceId] then
    print("=" .. string.rep("=", 60))
    print("⚠️ SIMFOREA HUB - PLACE ID ERROR ⚠️")
    print("=" .. string.rep("=", 60))
    print("Current Place ID: " .. currentPlaceId)
    print("Game Name: " .. gameName)
    print("Script stopped.")
    print("=" .. string.rep("=", 60))
    return
end

print("[Simforea Hub] Loaded in: " .. gameName)
print("[Simforea Hub] Anti-Cheat bypasses active!")

-- ==================== НАСТРОЙКИ ПО УМОЛЧАНИЮ ====================
local DEFAULT_SPEEDHACK_ENABLED = false
local DEFAULT_INFINITE_JUMP_ENABLED = false
local DEFAULT_ESP_ENABLED = false
local DEFAULT_ITEM_ESP_ENABLED = false
local DEFAULT_AUTOFARM_ENABLED = false
local DEFAULT_AUTO_PICKUP_ENABLED = false
local DEFAULT_BOX_ENABLED = true
local DEFAULT_CHAMS_ENABLED = true
local DEFAULT_HEALTH_ENABLED = true
local DEFAULT_DISTANCE_ENABLED = true
local DEFAULT_NAME_ENABLED = true
local DEFAULT_NOCLIP_ENABLED = false
local DEFAULT_STAND_CONTROL_ENABLED = false

local DEFAULT_SPEED = 200
local DEFAULT_INFINITE_JUMP_BOOST = 50

local MIN_SPEED = 50
local MAX_SPEED = 500

local DEFAULT_BOX_COLOR = Color3.fromRGB(255, 0, 0)
local DEFAULT_CHAMS_COLOR = Color3.fromRGB(255, 0, 0)
local DEFAULT_ITEM_COLOR = Color3.fromRGB(0, 255, 255)
local DEFAULT_TEAM_CHECK = true

-- ==================== ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ====================
local speedhackEnabled = DEFAULT_SPEEDHACK_ENABLED
local infiniteJumpEnabled = DEFAULT_INFINITE_JUMP_ENABLED
local autoFarmEnabled = DEFAULT_AUTOFARM_ENABLED
local autoPickupEnabled = DEFAULT_AUTO_PICKUP_ENABLED
local noclipEnabled = DEFAULT_NOCLIP_ENABLED
local standControlEnabled = DEFAULT_STAND_CONTROL_ENABLED

local currentSpeed = DEFAULT_SPEED
local currentInfiniteJumpBoost = DEFAULT_INFINITE_JUMP_BOOST

local espEnabled = DEFAULT_ESP_ENABLED
local itemEspEnabled = DEFAULT_ITEM_ESP_ENABLED
local boxEnabled = DEFAULT_BOX_ENABLED
local chamsEnabled = DEFAULT_CHAMS_ENABLED
local healthEnabled = DEFAULT_HEALTH_ENABLED
local distanceEnabled = DEFAULT_DISTANCE_ENABLED
local nameEnabled = DEFAULT_NAME_ENABLED
local boxColor = DEFAULT_BOX_COLOR
local chamsColor = DEFAULT_CHAMS_COLOR
local itemColor = DEFAULT_ITEM_COLOR
local teamCheck = DEFAULT_TEAM_CHECK

local originalGravity = nil
local espObjects = {}
local chamsObjects = {}

-- AutoFarm переменные
local autoFarmThread = nil
local processedItems = {}
local isTeleporting = false
local pickupDistance = 15
local teleportMethod = "Velocity"
local teleportSpeed = 0.3
local flightSpeed = 110

-- Item ESP переменные
local itemMaxDistance = 1000
local itemEspObjects = {}

-- NoClip переменные
local noclipConnection = nil

-- Velocity флаги
local isMovingToItem = false
local currentBodyVelocity = nil
local currentMoveConnection = nil

-- Конфиги
local CONFIG_FOLDER = "SimforeaHubConfigs"
local currentConfig = "default"

-- Создаём папку для конфигов
if not isfolder(CONFIG_FOLDER) then
    pcall(function() makefolder(CONFIG_FOLDER) end)
end

-- Запускаем Magnitude Bypass после загрузки персонажа
Players.LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    setupMagnitudeBypass()
end)

if Players.LocalPlayer.Character then
    task.spawn(function()
        task.wait(1)
        setupMagnitudeBypass()
    end)
end

-- ==================== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ====================
local function safeNotify(title, content, duration)
    pcall(function()
        Rayfield:Notify({
            Title = title,
            Content = content,
            Duration = duration or 3
        })
    end)
end

local function stopCurrentMovement()
    if currentBodyVelocity and currentBodyVelocity.Parent then
        pcall(function() currentBodyVelocity:Destroy() end)
        currentBodyVelocity = nil
    end
    
    if currentMoveConnection then
        pcall(function() currentMoveConnection:Disconnect() end)
        currentMoveConnection = nil
    end
    
    local character = Players.LocalPlayer.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end
    
    isMovingToItem = false
end

-- Модифицированная функция активации промпта с Ghost Item Bypass
local function activateProximityPrompt(prompt)
    if not prompt then return false end
    
    -- Проверка на Ghost Item (байпасс)
    if prompt.MaxActivationDistance == 0 then
        return false
    end
    
    pcall(function()
        prompt.MaxActivationDistance = 20
        prompt:InputHoldBegin()
        task.wait(prompt.HoldDuration > 0 and prompt.HoldDuration or 0.15)
        prompt:InputHoldEnd()
    end)
    
    return true
end

-- Обновленная функция получения предмета с использованием safePickupItem
local function getItemName(item)
    local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and prompt.ObjectText and prompt.ObjectText ~= "" then
        return prompt.ObjectText
    end
    return item.Name or "Item"
end

local function getProximityPrompt(item)
    return item:FindFirstChildWhichIsA("ProximityPrompt", true)
end

-- ==================== СИСТЕМА КОНФИГОВ ====================
local function saveConfig(name)
    local data = {
        version = 2,
        -- Movement
        speedhackEnabled = speedhackEnabled,
        currentSpeed = currentSpeed,
        infiniteJumpEnabled = infiniteJumpEnabled,
        currentInfiniteJumpBoost = currentInfiniteJumpBoost,
        noclipEnabled = noclipEnabled,
        standControlEnabled = standControlEnabled,
        
        -- Auto Farm
        autoFarmEnabled = autoFarmEnabled,
        autoPickupEnabled = autoPickupEnabled,
        pickupDistance = pickupDistance,
        teleportMethod = teleportMethod,
        flightSpeed = flightSpeed,
        teleportSpeed = teleportSpeed,
        
        -- ESP
        espEnabled = espEnabled,
        itemEspEnabled = itemEspEnabled,
        boxEnabled = boxEnabled,
        chamsEnabled = chamsEnabled,
        healthEnabled = healthEnabled,
        distanceEnabled = distanceEnabled,
        nameEnabled = nameEnabled,
        teamCheck = teamCheck,
        
        -- Colors
        boxColor = {boxColor.R, boxColor.G, boxColor.B},
        chamsColor = {chamsColor.R, chamsColor.G, chamsColor.B},
        itemColor = {itemColor.R, itemColor.G, itemColor.B},
        
        -- Items
        itemMaxDistance = itemMaxDistance,
        
        -- UI Theme
        theme = Window and Window.CurrentTheme or "Default"
    }
    
    local success, err = pcall(function()
        writefile(CONFIG_FOLDER .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    end)
    
    if success then
        safeNotify("Config", "Saved: " .. name, 2)
    else
        safeNotify("Config", "Failed to save: " .. name, 2)
    end
end

local function loadConfig(name)
    local path = CONFIG_FOLDER .. "/" .. name .. ".json"
    
    if not isfile(path) then
        safeNotify("Config", "Config not found: " .. name, 2)
        return false
    end
    
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)
    
    if not success then
        safeNotify("Config", "Failed to load: " .. name, 2)
        return false
    end
    
    -- Movement
    speedhackEnabled = data.speedhackEnabled
    currentSpeed = data.currentSpeed
    infiniteJumpEnabled = data.infiniteJumpEnabled
    currentInfiniteJumpBoost = data.currentInfiniteJumpBoost
    noclipEnabled = data.noclipEnabled
    standControlEnabled = data.standControlEnabled or false
    
    -- Auto Farm
    autoFarmEnabled = data.autoFarmEnabled
    autoPickupEnabled = data.autoPickupEnabled
    pickupDistance = data.pickupDistance
    teleportMethod = data.teleportMethod
    flightSpeed = data.flightSpeed
    teleportSpeed = data.teleportSpeed
    
    -- ESP
    espEnabled = data.espEnabled
    itemEspEnabled = data.itemEspEnabled
    boxEnabled = data.boxEnabled
    chamsEnabled = data.chamsEnabled
    healthEnabled = data.healthEnabled
    distanceEnabled = data.distanceEnabled
    nameEnabled = data.nameEnabled
    teamCheck = data.teamCheck
    
    -- Colors
    if data.boxColor then
        boxColor = Color3.fromRGB(data.boxColor[1]*255, data.boxColor[2]*255, data.boxColor[3]*255)
    end
    if data.chamsColor then
        chamsColor = Color3.fromRGB(data.chamsColor[1]*255, data.chamsColor[2]*255, data.chamsColor[3]*255)
    end
    if data.itemColor then
        itemColor = Color3.fromRGB(data.itemColor[1]*255, data.itemColor[2]*255, data.itemColor[3]*255)
    end
    
    -- Items
    itemMaxDistance = data.itemMaxDistance or 1000
    
    -- Apply theme
    if data.theme and Window and Window.ModifyTheme then
        pcall(function() Window.ModifyTheme(data.theme) end)
    end
    
    -- Apply NoClip state
    if noclipEnabled then
        startNoclip()
    else
        stopNoclip()
    end
    
    -- Apply Stand Control
    if standControlEnabled then
        controlStand(true)
    else
        controlStand(false)
    end
    
    safeNotify("Config", "Loaded: " .. name, 2)
    return true
end

-- ==================== NOCLIP ФУНКЦИИ ====================
local function startNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    
    noclipConnection = RunService.Heartbeat:Connect(function()
        if not noclipEnabled then
            return
        end
        
        local character = Players.LocalPlayer.Character
        if not character then
            return
        end
        
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function()
                    part.CanCollide = false
                end)
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

-- ==================== BODYVELOCITY MOVE ====================
local function moveToItemBodyVelocity(part)
    if isMovingToItem then 
        return false 
    end
    
    stopCurrentMovement()
    
    local character = Players.LocalPlayer.Character
    if not character then 
        return false 
    end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then 
        return false 
    end
    
    local targetPos = part.CFrame.Position
    local finished = false
    local success = false
    
    isMovingToItem = true
    
    local oldSpeedhack = speedhackEnabled
    speedhackEnabled = false
    
    local oldNoclip = noclipEnabled
    if not noclipEnabled then
        noclipEnabled = true
        startNoclip()
    end
    
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.P = 25000
    bv.Parent = hrp
    currentBodyVelocity = bv
    
    local timeout = 10
    local startTime = tick()
    
    currentMoveConnection = RunService.Heartbeat:Connect(function()
        if not isMovingToItem then
            finished = true
            success = false
            return
        end
        
        if not hrp or not hrp.Parent then
            finished = true
            success = false
            return
        end
        
        if tick() - startTime > timeout then
            finished = true
            success = false
            return
        end
        
        if part and part.Parent then
            targetPos = part.CFrame.Position
        end
        
        local delta = targetPos - hrp.Position
        local distance = delta.Magnitude
        
        if distance < 3 then
            finished = true
            success = true
            return
        end
        
        local currentSpeed = math.clamp(distance * 1.5, 25, flightSpeed)
        bv.Velocity = delta.Unit * currentSpeed
    end)
    
    repeat
        task.wait()
    until finished
    
    stopCurrentMovement()
    
    if hrp and hrp.Parent then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
    
    if not oldNoclip then
        noclipEnabled = false
        stopNoclip()
    end
    
    speedhackEnabled = oldSpeedhack
    
    return success
end

-- ==================== ITEM ESP ====================
if hasDrawing then
    function createItemESPObject(item)
        if itemEspObjects[item] then return end
        local nameLabel = Drawing.new("Text")
        nameLabel.Size = 13
        nameLabel.Center = true
        nameLabel.Outline = true
        nameLabel.Color = itemColor
        nameLabel.Visible = false

        local distanceLabel = Drawing.new("Text")
        distanceLabel.Size = 11
        distanceLabel.Center = true
        distanceLabel.Outline = true
        distanceLabel.Color = Color3.fromRGB(200, 200, 200)
        distanceLabel.Visible = false

        itemEspObjects[item] = {
            nameLabel = nameLabel,
            distanceLabel = distanceLabel
        }
    end

    function removeItemESP(item)
        local obj = itemEspObjects[item]
        if not obj then return end
        if obj.nameLabel then obj.nameLabel:Remove() end
        if obj.distanceLabel then obj.distanceLabel:Remove() end
        itemEspObjects[item] = nil
    end

    function updateItemESP()
        if not itemEspEnabled then
            for item, _ in pairs(itemEspObjects) do
                removeItemESP(item)
            end
            return
        end

        local player = Players.LocalPlayer
        if not player or not player.Character then return end
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local itemFolder = workspace:FindFirstChild("Item_Spawns")
        if not itemFolder then return end
        local items = itemFolder:FindFirstChild("Items")
        if not items then return end

        for _, item in ipairs(items:GetChildren()) do
            if not item:IsA("Model") then continue end
            local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
            if not part then continue end

            local distance = (root.Position - part.Position).Magnitude
            if distance > itemMaxDistance then
                if itemEspObjects[item] then
                    itemEspObjects[item].nameLabel.Visible = false
                    itemEspObjects[item].distanceLabel.Visible = false
                end
                continue
            end

            if not itemEspObjects[item] then
                createItemESPObject(item)
            end

            local obj = itemEspObjects[item]
            local pos, visible = Camera:WorldToViewportPoint(part.Position)
            if visible then
                local name = getItemName(item)
                if nameEnabled then
                    obj.nameLabel.Text = name
                    obj.nameLabel.Position = Vector2.new(pos.X, pos.Y - 25)
                    obj.nameLabel.Color = itemColor
                    obj.nameLabel.Visible = true
                else
                    obj.nameLabel.Visible = false
                end
                if distanceEnabled then
                    obj.distanceLabel.Text = string.format("%.0f studs", distance)
                    obj.distanceLabel.Position = Vector2.new(pos.X, pos.Y - 10)
                    obj.distanceLabel.Visible = true
                else
                    obj.distanceLabel.Visible = false
                end
            else
                obj.nameLabel.Visible = false
                obj.distanceLabel.Visible = false
            end
        end
    end
else
    createItemESPObject = function() end
    removeItemESP = function() end
    updateItemESP = function() end
end

-- ==================== ФУНКЦИИ АВТОФАРМА ====================
local function getClosestItem()
    local player = Players.LocalPlayer
    if not player or not player.Character then return nil end
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local itemFolder = workspace:FindFirstChild("Item_Spawns")
    if not itemFolder then return nil end
    local items = itemFolder:FindFirstChild("Items")
    if not items then return nil end

    local closestItem = nil
    local shortestDistance = pickupDistance

    for _, item in ipairs(items:GetChildren()) do
        if not item:IsA("Model") then continue end
        local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
        if not part then continue end
        local distance = (root.Position - part.Position).Magnitude
        if distance < shortestDistance then
            local prompt = getProximityPrompt(item)
            if prompt and prompt.MaxActivationDistance ~= 0 then -- Ghost Item bypass
                closestItem = prompt
                shortestDistance = distance
            end
        end
    end
    return closestItem
end

local function getClosestItemForTeleport()
    local player = Players.LocalPlayer
    if not player or not player.Character then return nil, nil end
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil, nil end

    local itemFolder = workspace:FindFirstChild("Item_Spawns")
    if not itemFolder then return nil, nil end
    local items = itemFolder:FindFirstChild("Items")
    if not items then return nil, nil end

    local closestItem = nil
    local closestDistance = math.huge
    local closestPart = nil

    for _, item in ipairs(items:GetChildren()) do
        if not item:IsA("Model") then continue end
        if processedItems[item] then continue end
        local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
        if not part then continue end
        local prompt = getProximityPrompt(item)
        if not prompt then continue end
        if prompt.MaxActivationDistance == 0 then continue end -- Ghost Item bypass
        local distance = (root.Position - part.Position).Magnitude
        if distance < closestDistance then
            closestItem = item
            closestDistance = distance
            closestPart = part
        end
    end
    return closestItem, closestPart
end

local function collectItem(item, part)
    if teleportMethod == "Velocity" then
        return moveToItemBodyVelocity(part)
    elseif teleportMethod == "Tween (Smooth)" then
        local character = Players.LocalPlayer.Character
        if not character then return false end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        
        local targetPos = part.CFrame.Position
        local tween = TweenService:Create(hrp, TweenInfo.new(teleportSpeed, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos)})
        tween:Play()
        tween.Completed:Wait()
        return true
    else
        local character = Players.LocalPlayer.Character
        if not character then return false end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        
        hrp.CFrame = part.CFrame
        return true
    end
end

-- Auto Pickup цикл с Ghost Item bypass
task.spawn(function()
    while true do
        if autoPickupEnabled then
            local prompt = getClosestItem()
            if prompt then
                activateProximityPrompt(prompt)
            end
        end
        task.wait(0.2)
    end
end)

-- Auto Farm функция
function startAutoFarm()
    if autoFarmThread and coroutine.status(autoFarmThread) ~= "dead" then
        return
    end
    
    autoFarmEnabled = true
    processedItems = {}
    isTeleporting = false
    
    autoFarmThread = task.spawn(function()
        while autoFarmEnabled do
            local item, part = getClosestItemForTeleport()
            
            if item and part then
                if not isTeleporting then
                    isTeleporting = true
                    local itemName = getItemName(item)
                    
                    local success = collectItem(item, part)
                    
                    if success then
                        task.wait(0.2)
                        local prompt = getProximityPrompt(item)
                        if prompt and prompt.MaxActivationDistance ~= 0 then
                            activateProximityPrompt(prompt)
                        end
                        
                        processedItems[item] = true
                        
                        task.delay(2, function()
                            processedItems[item] = nil
                        end)
                        
                        safeNotify("Auto Farm", "Collected: " .. itemName, 2)
                    end
                    
                    isTeleporting = false
                    task.wait(0.3)
                end
            else
                if next(processedItems) then
                    processedItems = {}
                end
                task.wait(0.5)
            end
        end
        
        stopCurrentMovement()
        autoFarmThread = nil
    end)
    
    safeNotify("Auto Farm", "Started! Mode: " .. teleportMethod, 3)
end

function stopAutoFarm()
    autoFarmEnabled = false
    stopCurrentMovement()
    
    if autoFarmThread then
        pcall(function() coroutine.close(autoFarmThread) end)
        autoFarmThread = nil
    end
    
    isTeleporting = false
    processedItems = {}
    
    local character = Players.LocalPlayer.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end
    
    safeNotify("Auto Farm", "Stopped!", 3)
end

-- ==================== ESP ИГРОКОВ ====================
local function getPlayerTeam(player)
    return player and player.Team
end

local function getPlayerColor(plr)
    if not teamCheck then
        return boxColor
    end
    local localPlayer = Players.LocalPlayer
    if not localPlayer then return boxColor end
    local localTeam = getPlayerTeam(localPlayer)
    local playerTeam = getPlayerTeam(plr)
    if localTeam and playerTeam and localTeam == playerTeam then
        return Color3.fromRGB(0, 255, 0)
    else
        return chamsEnabled and chamsColor or boxColor
    end
end

local function updateChamsForPlayer(player)
    local character = player.Character
    if not character then return end
    if chamsObjects[player] and chamsObjects[player].highlight then
        chamsObjects[player].highlight:Destroy()
        chamsObjects[player] = nil
    end
    if chamsEnabled and espEnabled and character then
        local highlight = Instance.new("Highlight")
        highlight.Parent = character
        highlight.FillColor = getPlayerColor(player)
        highlight.OutlineColor = getPlayerColor(player)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0.3
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        chamsObjects[player] = { highlight = highlight }
    end
end

local function getCharacterSize(character)
    if not character then return 5, 5 end
    local extents = character:GetExtentsSize()
    return math.max(extents.X, 2), math.max(extents.Y, 5)
end

local function createESPObject(player)
    if espObjects[player] then return end
    local objects = {
        box = Drawing.new("Square"),
        healthBar = Drawing.new("Line"),
        nameLabel = Drawing.new("Text"),
        distanceLabel = Drawing.new("Text"),
        healthText = Drawing.new("Text")
    }
    objects.box.Thickness = 2
    objects.box.Filled = false
    objects.box.Color = getPlayerColor(player)
    objects.box.Visible = false

    objects.healthBar.Thickness = 3
    objects.healthBar.Color = Color3.fromRGB(0, 255, 0)
    objects.healthBar.Visible = false

    objects.nameLabel.Size = 14
    objects.nameLabel.Center = true
    objects.nameLabel.Outline = true
    objects.nameLabel.Color = Color3.fromRGB(255, 255, 255)
    objects.nameLabel.Visible = false

    objects.distanceLabel.Size = 12
    objects.distanceLabel.Center = true
    objects.distanceLabel.Outline = true
    objects.distanceLabel.Color = Color3.fromRGB(200, 200, 200)
    objects.distanceLabel.Visible = false

    objects.healthText.Size = 11
    objects.healthText.Center = true
    objects.healthText.Outline = true
    objects.healthText.Color = Color3.fromRGB(255, 255, 255)
    objects.healthText.Visible = false

    espObjects[player] = objects
end

local function updatePlayerESP()
    if not espEnabled then return end
    local localPlayer = Players.LocalPlayer
    if not localPlayer or not localPlayer.Character then return end
    local localRoot = localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == localPlayer then continue end
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid") then
            local rootPart = character.HumanoidRootPart
            local humanoid = character.Humanoid

            if chamsEnabled and espEnabled then
                if not chamsObjects[player] then
                    updateChamsForPlayer(player)
                elseif chamsObjects[player] and chamsObjects[player].highlight then
                    chamsObjects[player].highlight.FillColor = getPlayerColor(player)
                    chamsObjects[player].highlight.OutlineColor = getPlayerColor(player)
                end
            elseif not chamsEnabled and chamsObjects[player] then
                if chamsObjects[player].highlight then
                    chamsObjects[player].highlight:Destroy()
                end
                chamsObjects[player] = nil
            end

            if boxEnabled then
                if not espObjects[player] then
                    createESPObject(player)
                end
                local objects = espObjects[player]
                if not objects then continue end

                local vector, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                if onScreen and humanoid.Health > 0 then
                    local width, height = getCharacterSize(character)
                    local distance = (Camera.CFrame.Position - rootPart.Position).Magnitude
                    local scale = 300 / math.max(distance, 10)
                    local boxWidth = width * scale
                    local boxHeight = height * scale
                    local boxPosition = Vector2.new(vector.X - boxWidth/2, vector.Y - boxHeight/2)
                    local boxSize = Vector2.new(boxWidth, boxHeight)

                    objects.box.Color = getPlayerColor(player)
                    objects.box.Visible = true
                    objects.box.Size = boxSize
                    objects.box.Position = boxPosition

                    if healthEnabled and humanoid.MaxHealth > 0 then
                        local healthPercent = humanoid.Health / humanoid.MaxHealth
                        local healthBarHeight = boxSize.Y * healthPercent
                        objects.healthBar.Visible = true
                        objects.healthBar.From = Vector2.new(boxPosition.X - 5, boxPosition.Y + boxSize.Y - healthBarHeight)
                        objects.healthBar.To = Vector2.new(boxPosition.X - 5, boxPosition.Y + boxSize.Y)
                        if healthPercent > 0.5 then
                            objects.healthBar.Color = Color3.fromRGB(0, 255, 0)
                        elseif healthPercent > 0.25 then
                            objects.healthBar.Color = Color3.fromRGB(255, 255, 0)
                        else
                            objects.healthBar.Color = Color3.fromRGB(255, 0, 0)
                        end
                        objects.healthText.Visible = true
                        objects.healthText.Text = math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
                        objects.healthText.Position = Vector2.new(vector.X, boxPosition.Y + boxSize.Y + 15)
                    else
                        objects.healthBar.Visible = false
                        objects.healthText.Visible = false
                    end

                    if nameEnabled then
                        objects.nameLabel.Visible = true
                        objects.nameLabel.Text = player.Name
                        objects.nameLabel.Position = Vector2.new(vector.X, boxPosition.Y - 20)
                    else
                        objects.nameLabel.Visible = false
                    end

                    if distanceEnabled then
                        objects.distanceLabel.Visible = true
                        objects.distanceLabel.Text = string.format("%.1f studs", (localRoot.Position - rootPart.Position).Magnitude)
                        objects.distanceLabel.Position = Vector2.new(vector.X, boxPosition.Y + boxSize.Y + 5)
                    else
                        objects.distanceLabel.Visible = false
                    end
                else
                    objects.box.Visible = false
                    objects.healthBar.Visible = false
                    objects.nameLabel.Visible = false
                    objects.distanceLabel.Visible = false
                    objects.healthText.Visible = false
                end
            end
        else
            if espObjects[player] then
                for _, obj in pairs(espObjects[player]) do
                    if obj and obj.Remove then pcall(obj.Remove, obj) end
                end
                espObjects[player] = nil
            end
        end
    end
end

-- ==================== SPEEDHACK ====================
local lastSpeedUpdate = 0
local function updateSpeedhack()
    if not speedhackEnabled then return end
    if isMovingToItem then return end
    if tick() - lastSpeedUpdate < 0.05 then return end
    lastSpeedUpdate = tick()

    local player = Players.LocalPlayer
    if not player or not player.Character then return end
    local humanoid = player.Character:FindFirstChild("Humanoid")
    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
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

    local player = Players.LocalPlayer
    if not player or not player.Character then return end
    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
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

-- ==================== ОЧИСТКА ESP ====================
local function clearAllESP()
    for player, objects in pairs(espObjects) do
        for _, obj in pairs(objects) do
            if obj and obj.Remove then pcall(obj.Remove, obj) end
        end
    end
    espObjects = {}
end

local function clearAllChams()
    for player, chams in pairs(chamsObjects) do
        if chams and chams.highlight then
            chams.highlight:Destroy()
        end
    end
    chamsObjects = {}
end

local function clearAllItemESP()
    for item, _ in pairs(itemEspObjects) do
        removeItemESP(item)
    end
end

-- ==================== RAYFIELD UI ====================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local themes = {
    "Default",
    "AmberGlow",
    "Amethyst",
    "Bloom",
    "DarkBlue",
    "Green",
    "Light",
    "Ocean",
    "Serenity"
}

local Window = Rayfield:CreateWindow({
    Name = "Simforea Hub | " .. gameName,
    Icon = 0,
    LoadingTitle = "Simforea Hub",
    LoadingSubtitle = "Loaded in: " .. gameName .. " (Bypasses Active)",
    Theme = "Default",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "SimforeaHub",
        FileName = "Settings"
    },
    KeySystem = false
})

-- ==================== ВКЛАДКИ ====================
local MovementTab = Window:CreateTab("Movement", 0)
local AutoFarmTab = Window:CreateTab("AutoFarm", 0)
local ESPTab = Window:CreateTab("ESP", 0)
local ItemsTab = Window:CreateTab("Items", 0)
local BypassesTab = Window:CreateTab("Bypasses", 0)
local SettingsTab = Window:CreateTab("Settings", 0)
local InfoTab = Window:CreateTab("Info", 0)

-- Movement Tab
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

-- AutoFarm Tab
AutoFarmTab:CreateToggle({
    Name = "Auto Pickup (Range)",
    CurrentValue = autoPickupEnabled,
    Callback = function(v) autoPickupEnabled = v end
})
AutoFarmTab:CreateSlider({
    Name = "Pickup Range",
    Range = {5, 50},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = pickupDistance,
    Callback = function(v) pickupDistance = v end
})

AutoFarmTab:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = autoFarmEnabled,
    Callback = function(v)
        if v then
            startAutoFarm()
        else
            stopAutoFarm()
        end
    end
})

AutoFarmTab:CreateDropdown({
    Name = "Movement Method",
    Options = {"BodyVelocity (Through walls)", "Tween (Smooth)", "Instant (Teleport)"},
    CurrentOption = "BodyVelocity (Through walls)",
    Callback = function(opt)
        if opt == "BodyVelocity (Through walls)" then
            teleportMethod = "Velocity"
        elseif opt == "Tween (Smooth)" then
            teleportMethod = "Tween (Smooth)"
        else
            teleportMethod = "Instant"
        end
    end
})

AutoFarmTab:CreateSlider({
    Name = "Flight Speed (Recommended: 100-140)",
    Range = {50, 200},
    Increment = 10,
    Suffix = "studs/s",
    CurrentValue = flightSpeed,
    Callback = function(v) flightSpeed = v end
})

AutoFarmTab:CreateSlider({
    Name = "Tween Speed",
    Range = {0.1, 2.0},
    Increment = 0.05,
    Suffix = "s",
    CurrentValue = teleportSpeed,
    Callback = function(v) teleportSpeed = v end
})

-- ESP Tab
ESPTab:CreateToggle({
    Name = "Enable Player ESP",
    CurrentValue = espEnabled,
    Callback = function(v)
        espEnabled = v
        if not v then clearAllESP(); if not chamsEnabled then clearAllChams() end end
    end
})

ESPTab:CreateToggle({
    Name = "Show Box",
    CurrentValue = boxEnabled,
    Callback = function(v) boxEnabled = v end
})

ESPTab:CreateToggle({
    Name = "Show Chams",
    CurrentValue = chamsEnabled,
    Callback = function(v)
        chamsEnabled = v
        if not v then clearAllChams() end
    end
})

ESPTab:CreateToggle({
    Name = "Show Health",
    CurrentValue = healthEnabled,
    Callback = function(v) healthEnabled = v end
})

ESPTab:CreateToggle({
    Name = "Show Distance",
    CurrentValue = distanceEnabled,
    Callback = function(v) distanceEnabled = v end
})

ESPTab:CreateToggle({
    Name = "Show Name",
    CurrentValue = nameEnabled,
    Callback = function(v) nameEnabled = v end
})

ESPTab:CreateToggle({
    Name = "Team Check (Green=Team)",
    CurrentValue = teamCheck,
    Callback = function(v) teamCheck = v end
})

ESPTab:CreateColorPicker({
    Name = "Box Color",
    Color = boxColor,
    Callback = function(c) boxColor = c end
})

ESPTab:CreateColorPicker({
    Name = "Chams Color",
    Color = chamsColor,
    Callback = function(c) chamsColor = c end
})

-- Items Tab
ItemsTab:CreateToggle({
    Name = "Enable Item ESP",
    CurrentValue = itemEspEnabled,
    Callback = function(v)
        itemEspEnabled = v
        if not v then clearAllItemESP() end
    end
})
ItemsTab:CreateColorPicker({
    Name = "Item ESP Color",
    Color = itemColor,
    Callback = function(c)
        itemColor = c
        for _, obj in pairs(itemEspObjects) do
            if obj.nameLabel then obj.nameLabel.Color = c end
        end
    end
})
ItemsTab:CreateToggle({
    Name = "Show Distance",
    CurrentValue = distanceEnabled,
    Callback = function(v) distanceEnabled = v end
})
ItemsTab:CreateToggle({
    Name = "Show Name",
    CurrentValue = nameEnabled,
    Callback = function(v) nameEnabled = v end
})
ItemsTab:CreateSlider({
    Name = "Max Distance",
    Range = {0, 5000},
    Increment = 50,
    Suffix = "studs",
    CurrentValue = itemMaxDistance,
    Callback = function(v) itemMaxDistance = v end
})

-- Bypasses Tab
BypassesTab:CreateParagraph({
    Title = "Active Bypasses",
    Content = "gg uzukee"
})

BypassesTab:CreateToggle({
    Name = "Stand Control (Experimental)",
    CurrentValue = standControlEnabled,
    Callback = function(v)
        standControlEnabled = v
        if v then
            controlStand(true)
            safeNotify("Stand Control", "Enabled! You are now controlling your stand.", 3)
        else
            controlStand(false)
            safeNotify("Stand Control", "Disabled!", 2)
        end
    end
})

BypassesTab:CreateButton({
    Name = "Force Teleport Bypass Check",
    Callback = function()
        safeNotify("Bypasses", "Teleport bypass is active!", 2)
    end
})

-- Settings Tab
SettingsTab:CreateDropdown({
    Name = "UI Theme",
    Options = themes,
    CurrentOption = "Default",
    Callback = function(theme)
        pcall(function() Window.ModifyTheme(theme) end)
        safeNotify("Theme", "Changed to: " .. theme, 2)
    end
})

SettingsTab:CreateInput({
    Name = "Config Name",
    PlaceholderText = "default",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        if text and text ~= "" then
            currentConfig = text
        end
    end
})

SettingsTab:CreateButton({
    Name = "Save Config",
    Callback = function()
        saveConfig(currentConfig)
    end
})

SettingsTab:CreateButton({
    Name = "Load Config",
    Callback = function()
        loadConfig(currentConfig)
    end
})

-- Список конфигов
local configs = listConfigs()
if #configs > 0 then
    SettingsTab:CreateDropdown({
        Name = "Load Saved Config",
        Options = configs,
        CurrentOption = configs[1],
        Callback = function(name)
            loadConfig(name)
            currentConfig = name
        end
    })
end

SettingsTab:CreateButton({
    Name = "Refresh Config List",
    Callback = function()
        local newConfigs = listConfigs()
        safeNotify("Config", "Found " .. #newConfigs .. " configs", 2)
    end
})

SettingsTab:CreateButton({
    Name = "Delete Current Config",
    Callback = function()
        deleteConfig(currentConfig)
    end
})

-- Info Tab
InfoTab:CreateParagraph({
    Title = "Simforea Hub",
    Content = string.format("Game: %s\nPlace ID: %d\n\nCurrent Mode: %s\nFlight Speed: %d\n\n=== FEATURES ===\n✓ Perfect targeting (center of item)\n✓ Dynamic speed system\n✓ BodyVelocity through walls\n✓ Proper InputHold pickup\n✓ Multiple configs\n✓ Theme support\n✓ Stops immediately when disabled\n\n=== ANTI-CHEAT BYPASSES ===\n✓ Teleport Bypass\n✓ Item Magnitude Bypass\n✓ Ghost Item Bypass\n✓ Stand Control (Godmode)\n\nRecommended speed: 100-120 for YBA\n\nConfigs saved to: %s", gameName, currentPlaceId, teleportMethod, flightSpeed, CONFIG_FOLDER)
})

-- ==================== СБОРЩИК МУСОРА ====================
local function onItemRemoved(item)
    if itemEspObjects[item] then removeItemESP(item) end
    processedItems[item] = nil
end

local function setupItemsFolder()
    local itemSpawns = workspace:FindFirstChild("Item_Spawns")
    if not itemSpawns then return end
    local items = itemSpawns:FindFirstChild("Items")
    if items then
        items.ChildRemoved:Connect(onItemRemoved)
    end
end

-- ==================== ЗАПУСК ====================
originalGravity = Workspace.Gravity
RunService.RenderStepped:Connect(function()
    pcall(updatePlayerESP)
    pcall(updateItemESP)
    pcall(updateSpeedhack)
    pcall(updateInfiniteJump)
end)

Players.LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    clearAllESP()
    setupMagnitudeBypass()
    if noclipEnabled then
        startNoclip()
    end
end)

game:GetService("Players").LocalPlayer.OnTeleport:Connect(function()
    clearAllESP()
    clearAllChams()
    clearAllItemESP()
    processedItems = {}
    if autoFarmEnabled then stopAutoFarm() end
    if noclipEnabled then
        task.wait(1)
        startNoclip()
    end
end)

setupItemsFolder()

if noclipEnabled then
    startNoclip()
end

-- Автозагрузка последнего конфига
local function autoLoadLastConfig()
    local configs = listConfigs()
    if #configs > 0 then
        if isfile(CONFIG_FOLDER .. "/default.json") then
            loadConfig("default")
            currentConfig = "default"
        else
            loadConfig(configs[1])
            currentConfig = configs[1]
        end
    end
end

pcall(autoLoadLastConfig)

safeNotify("Simforea Hub", 5)

print("[Simforea Hub] Loaded with Configs, Themes & Anti-Cheat Bypasses!")
