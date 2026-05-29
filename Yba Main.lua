-- Simforea Hub - Rayfield UI + AutoFarm + Item ESP (Fixed)
-- Designed for Place ID: 2809202155
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

-- Дожидаемся камеры
local Camera = workspace.CurrentCamera or workspace:WaitForChild("CurrentCamera")

-- Проверка Drawing API
local hasDrawing = pcall(Drawing.new, "Text")
if not hasDrawing then
    warn("Drawing API not supported – ESP disabled")
end

print("========================================")
print("[Simforea] Loading...")
print("========================================")

-- ==================== ИСПРАВЛЕННЫЕ БАЙПАСЫ ====================

-- 1. Anti-Kick - через pcall (без ошибки)
local player = Players.LocalPlayer
pcall(function()
    local originalKick = player.Kick
    if originalKick then
        player.Kick = function(self, message)
            warn("[Simforea] Blocked kick: " .. tostring(message))
            return nil
        end
    end
end)

-- 2. Magnitude Bypass
local function setupMagnitudeBypass()
    local char = player.Character
    if not char then return end
    
    local primaryPart = char:FindFirstChild("HumanoidRootPart")
    if not primaryPart then return end
    
    local OldIndexItem;
    OldIndexItem = hookmetamethod(primaryPart, "__index", newcclosure(function(self, Key)
        if not checkcaller() and Key:lower() == 'magnitude' and getcallingscript() and getcallingscript().Name == "ItemSpawn" then
            return 0;
        end
        return OldIndexItem(self, Key)
    end))
end

-- 3. Teleport Bypass
local OldNamecall;
OldNamecall = hookmetamethod(game, '__namecall', newcclosure(function(self, ...)
    local Method = getnamecallmethod()
    local Args = {...}
    
    if Method == "InvokeServer" and Args[1] == "idklolbrah2de" then
        return "  ___XP DE KEY"
    end
    
    return OldNamecall(self, ...)
end))

-- Запускаем байпасы
player.CharacterAdded:Connect(function()
    task.wait(1)
    setupMagnitudeBypass()
end)

if player.Character then
    task.spawn(function()
        task.wait(1)
        setupMagnitudeBypass()
    end)
end

print("[Simforea] Bypasses activated")

-- ==================== ПРОВЕРКА ПЛЕЙСА ====================
local currentPlaceId = game.PlaceId
local gameName = "YBA"

-- ==================== НАСТРОЙКИ ====================
local DEFAULT_SPEEDHACK_ENABLED = false
local DEFAULT_INFINITE_JUMP_ENABLED = false
local DEFAULT_AUTOFARM_ENABLED = false
local DEFAULT_AUTO_PICKUP_ENABLED = false
local DEFAULT_NOCLIP_ENABLED = false
local DEFAULT_ITEM_ESP_ENABLED = false

local DEFAULT_SPEED = 200
local DEFAULT_INFINITE_JUMP_BOOST = 50
local DEFAULT_FLIGHT_SPEED = 120

local MIN_SPEED = 50
local MAX_SPEED = 500

-- ==================== ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ====================
local speedhackEnabled = DEFAULT_SPEEDHACK_ENABLED
local infiniteJumpEnabled = DEFAULT_INFINITE_JUMP_ENABLED
local autoFarmEnabled = DEFAULT_AUTOFARM_ENABLED
local autoPickupEnabled = DEFAULT_AUTO_PICKUP_ENABLED
local noclipEnabled = DEFAULT_NOCLIP_ENABLED
local itemEspEnabled = DEFAULT_ITEM_ESP_ENABLED

local currentSpeed = DEFAULT_SPEED
local currentInfiniteJumpBoost = DEFAULT_INFINITE_JUMP_BOOST
local flightSpeed = DEFAULT_FLIGHT_SPEED

-- ESP настройки
local itemColor = Color3.fromRGB(0, 255, 255)
local itemMaxDistance = 1000
local nameEnabled = true
local distanceEnabled = true

-- AutoFarm переменные
local autoFarmThread = nil
local isMovingToItem = false
local currentMoveConnection = nil
local autoFarmNoclip = false
local noclipConnection = nil

-- Кеш предметов
local itemCache = {}
local lastCacheUpdate = 0
local CACHE_UPDATE_INTERVAL = 3

-- Item ESP объекты
local itemEspObjects = {}

-- ==================== СИСТЕМА ПОИСКА ПРЕДМЕТОВ ====================

local function updateItemCache()
    local items = {}
    
    local itemSpawns = workspace:FindFirstChild("Item_Spawns")
    if itemSpawns then
        local itemsFolder = itemSpawns:FindFirstChild("Items")
        if itemsFolder then
            for _, item in ipairs(itemsFolder:GetChildren()) do
                if item:IsA("Model") then
                    local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and prompt.ObjectText and prompt.ObjectText ~= "" then
                        table.insert(items, item)
                    end
                end
            end
        end
    end
    
    itemCache = items
    lastCacheUpdate = tick()
    
    if #items > 0 then
        print("[Simforea] Found " .. #items .. " items")
    end
    return items
end

local function getAllItemModels()
    if tick() - lastCacheUpdate > CACHE_UPDATE_INTERVAL then
        updateItemCache()
    end
    return itemCache
end

local function getItemPosition(itemModel)
    if not itemModel then return nil end
    
    if itemModel.PrimaryPart then
        return itemModel.PrimaryPart.Position
    end
    
    local handle = itemModel:FindFirstChild("Handle")
    if handle and handle:IsA("BasePart") then
        return handle.Position
    end
    
    for _, part in ipairs(itemModel:GetDescendants()) do
        if part:IsA("BasePart") then
            return part.Position
        end
    end
    
    return nil
end

local function getItemPrompt(itemModel)
    if not itemModel then return nil end
    return itemModel:FindFirstChildWhichIsA("ProximityPrompt", true)
end

local function getItemName(itemModel)
    local prompt = getItemPrompt(itemModel)
    if prompt and prompt.ObjectText and prompt.ObjectText ~= "" then
        return prompt.ObjectText
    end
    return itemModel.Name or "Unknown Item"
end

local function isItemValid(itemModel)
    if not itemModel or not itemModel.Parent then
        return false
    end
    local prompt = getItemPrompt(itemModel)
    if prompt and prompt.Enabled == false then
        return false
    end
    return true
end

local function getItemPart(itemModel)
    if not itemModel then return nil end
    
    if itemModel.PrimaryPart then
        return itemModel.PrimaryPart
    end
    
    local handle = itemModel:FindFirstChild("Handle")
    if handle and handle:IsA("BasePart") then
        return handle
    end
    
    for _, part in ipairs(itemModel:GetDescendants()) do
        if part:IsA("BasePart") then
            return part
        end
    end
    
    return nil
end

-- ==================== ITEM ESP ====================
if hasDrawing then
    function createItemESPObject(itemModel)
        if itemEspObjects[itemModel] then return end
        
        local name = getItemName(itemModel)
        
        local nameLabel = Drawing.new("Text")
        nameLabel.Size = 13
        nameLabel.Center = true
        nameLabel.Outline = true
        nameLabel.Color = itemColor
        nameLabel.Text = name
        nameLabel.Visible = false
        
        local distanceLabel = Drawing.new("Text")
        distanceLabel.Size = 11
        distanceLabel.Center = true
        distanceLabel.Outline = true
        distanceLabel.Color = Color3.fromRGB(200, 200, 200)
        distanceLabel.Visible = false
        
        itemEspObjects[itemModel] = {
            nameLabel = nameLabel,
            distanceLabel = distanceLabel,
            model = itemModel
        }
    end

    function removeItemESP(itemModel)
        local obj = itemEspObjects[itemModel]
        if not obj then return end
        if obj.nameLabel then obj.nameLabel:Remove() end
        if obj.distanceLabel then obj.distanceLabel:Remove() end
        itemEspObjects[itemModel] = nil
    end

    function updateItemESP()
        if not itemEspEnabled then
            for itemModel, _ in pairs(itemEspObjects) do
                removeItemESP(itemModel)
            end
            return
        end

        local player = Players.LocalPlayer
        if not player or not player.Character then return end
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local items = getAllItemModels()
        
        for _, itemModel in ipairs(items) do
            if isItemValid(itemModel) then
                local itemPos = getItemPosition(itemModel)
                if itemPos then
                    local distance = (root.Position - itemPos).Magnitude
                    
                    if distance <= itemMaxDistance then
                        if not itemEspObjects[itemModel] then
                            createItemESPObject(itemModel)
                        end

                        local obj = itemEspObjects[itemModel]
                        if obj then
                            local pos, onScreen = Camera:WorldToViewportPoint(itemPos)
                            
                            if onScreen then
                                if nameEnabled then
                                    obj.nameLabel.Position = Vector2.new(pos.X, pos.Y - 25)
                                    obj.nameLabel.Visible = true
                                else
                                    obj.nameLabel.Visible = false
                                end
                                
                                if distanceEnabled then
                                    obj.distanceLabel.Text = string.format("%.0f", distance)
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
                    else
                        if itemEspObjects[itemModel] then
                            local obj = itemEspObjects[itemModel]
                            if obj then
                                obj.nameLabel.Visible = false
                                obj.distanceLabel.Visible = false
                            end
                        end
                    end
                end
            else
                if itemEspObjects[itemModel] then
                    removeItemESP(itemModel)
                end
            end
        end
    end
else
    createItemESPObject = function() end
    removeItemESP = function() end
    updateItemESP = function() end
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
    print("[Simforea] " .. title .. ": " .. content)
end

local function stopCurrentMovement()
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
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
        end
    end
    
    isMovingToItem = false
end

-- ==================== АВТОФАРМ ====================

local function getClosestItem()
    local player = Players.LocalPlayer
    if not player or not player.Character then return nil, nil, nil end
    
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil, nil, nil end
    
    local closestItem = nil
    local closestDistance = math.huge
    local closestPrompt = nil
    
    local items = getAllItemModels()
    
    for _, item in ipairs(items) do
        if isItemValid(item) then
            local itemPos = getItemPosition(item)
            if itemPos then
                local distance = (root.Position - itemPos).Magnitude
                
                if distance < closestDistance then
                    closestItem = item
                    closestDistance = distance
                    closestPrompt = getItemPrompt(item)
                end
            end
        end
    end
    
    return closestItem, closestPrompt, closestDistance
end

local function moveToItem(itemPart)
    if isMovingToItem then 
        return false 
    end
    
    stopCurrentMovement()
    
    local character = Players.LocalPlayer.Character
    if not character then 
        return false 
    end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then 
        return false 
    end
    
    if not itemPart or not itemPart.Parent then
        return false
    end
    
    local finished = false
    local success = false
    
    isMovingToItem = true
    
    local oldSpeedhack = speedhackEnabled
    speedhackEnabled = false
    
    autoFarmNoclip = true
    
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.PlatformStand = true
    end
    
    local timeout = 15
    local startTime = tick()
    local lastTargetUpdate = 0
    local currentTargetPos = itemPart.Position
    
    currentMoveConnection = RunService.Heartbeat:Connect(function()
        if not isMovingToItem then
            finished = true
            success = false
            return
        end
        
        if not rootPart or not rootPart.Parent then
            finished = true
            success = false
            return
        end
        
        if tick() - startTime > timeout then
            finished = true
            success = false
            return
        end
        
        if tick() - lastTargetUpdate > 0.2 then
            if itemPart and itemPart.Parent then
                currentTargetPos = itemPart.Position
            else
                finished = true
                success = false
                return
            end
            lastTargetUpdate = tick()
        end
        
        local delta = currentTargetPos - rootPart.Position
        local distance = delta.Magnitude
        
        if distance < 15 then
            finished = true
            success = true
            return
        end
        
        local direction = delta.Unit
        rootPart.AssemblyLinearVelocity = direction * flightSpeed
    end)
    
    repeat
        task.wait()
    until finished
    
    if rootPart and rootPart.Parent then
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
    end
    
    if currentMoveConnection then
        pcall(function() currentMoveConnection:Disconnect() end)
        currentMoveConnection = nil
    end
    
    if humanoid then
        humanoid.PlatformStand = false
    end
    
    autoFarmNoclip = false
    speedhackEnabled = oldSpeedhack
    
    isMovingToItem = false
    
    return success
end

local function collectItem(itemModel, itemPart, itemPrompt)
    if not itemPart then return false end
    
    local success = moveToItem(itemPart)
    
    if success and itemPrompt then
        task.wait(0.1)
        pcall(function()
            fireproximityprompt(itemPrompt, 0.5)
        end)
        task.wait(0.15)
        pcall(function()
            fireproximityprompt(itemPrompt, 0.5)
        end)
        return true
    end
    
    return false
end

function startAutoFarm()
    if autoFarmThread then
        return
    end
    
    autoFarmEnabled = true
    
    safeNotify("Auto Farm", "Started! Speed: " .. flightSpeed .. " studs/s", 4)
    print("[AutoFarm] Started with speed: " .. flightSpeed)
    
    autoFarmThread = task.spawn(function()
        local lastItemCheck = 0
        local CHECK_INTERVAL = 2.5
        
        while autoFarmEnabled do
            local currentTime = tick()
            
            if currentTime - lastItemCheck >= CHECK_INTERVAL then
                local item, prompt, distance = getClosestItem()
                
                if item and prompt then
                    if not isMovingToItem then
                        local itemName = getItemName(item)
                        local itemPart = getItemPart(item)
                        
                        if itemPart and isItemValid(item) then
                            print(string.format("[AutoFarm] Found: %s (%.0f studs)", itemName, distance))
                            safeNotify("Auto Farm", "Moving to: " .. itemName, 2)
                            
                            local success = collectItem(item, itemPart, prompt)
                            
                            if success then
                                print("[AutoFarm] Collected: " .. itemName)
                                safeNotify("Auto Farm", "Collected: " .. itemName, 2)
                                updateItemCache()
                            end
                            
                            task.wait(0.5)
                        end
                    end
                end
                
                lastItemCheck = currentTime
            end
            
            task.wait(0.1)
        end
        
        print("[AutoFarm] Stopped")
        stopCurrentMovement()
        autoFarmThread = nil
    end)
end

function stopAutoFarm()
    autoFarmEnabled = false
    stopCurrentMovement()
    autoFarmThread = nil
    
    safeNotify("Auto Farm", "Stopped!", 3)
    print("[AutoFarm] Stopped")
end

-- Auto Pickup
task.spawn(function()
    while true do
        if autoPickupEnabled then
            local items = getAllItemModels()
            local player = Players.LocalPlayer
            if player and player.Character then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    for _, item in ipairs(items) do
                        if isItemValid(item) then
                            local itemPos = getItemPosition(item)
                            if itemPos and (root.Position - itemPos).Magnitude < 20 then
                                local prompt = getItemPrompt(item)
                                if prompt then
                                    pcall(function() fireproximityprompt(prompt, 0.5) end)
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.3)
    end
end)

-- ==================== NOCLIP ====================
local function startNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    
    noclipConnection = RunService.Heartbeat:Connect(function()
        if noclipEnabled or autoFarmNoclip then
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

-- ==================== RAYFIELD UI ====================
print("[Simforea] Loading Rayfield...")

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Simforea Hub | " .. gameName,
    Icon = 0,
    LoadingTitle = "Simforea Hub",
    LoadingSubtitle = "Fixed version",
    Theme = "Default",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "SimforeaHub",
        FileName = "Settings"
    },
    KeySystem = false
})

print("Simforea loaded!")

-- Вкладки
local MovementTab = Window:CreateTab("Movement", 0)
local AutoFarmTab = Window:CreateTab("AutoFarm", 0)
local ESPTab = Window:CreateTab("ESP", 0)
local ItemsTab = Window:CreateTab("Items", 0)
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
            if not autoFarmNoclip then
                stopNoclip()
            end
            safeNotify("NoClip", "Disabled!", 2)
        end
    end
})

-- AutoFarm Tab
AutoFarmTab:CreateToggle({
    Name = "Auto Pickup (20 studs range)",
    CurrentValue = autoPickupEnabled,
    Callback = function(v) autoPickupEnabled = v end
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

AutoFarmTab:CreateSlider({
    Name = "Flight Speed (studs/s)",
    Range = {50, 300},
    Increment = 5,
    Suffix = "studs/s",
    CurrentValue = flightSpeed,
    Callback = function(v) 
        flightSpeed = v
        safeNotify("Flight Speed", "Set to: " .. v .. " studs/s", 1)
    end
})

AutoFarmTab:CreateParagraph({
    Title = "⚙️ AutoFarm Info",
    Content = "hell nah"
})

-- ESP Tab (Item ESP)
ESPTab:CreateToggle({
    Name = "Enable Item ESP",
    CurrentValue = itemEspEnabled,
    Callback = function(v)
        itemEspEnabled = v
        if not v then
            for itemModel, _ in pairs(itemEspObjects) do
                removeItemESP(itemModel)
            end
        end
    end
})

ESPTab:CreateColorPicker({
    Name = "Item ESP Color",
    Color = itemColor,
    Callback = function(c)
        itemColor = c
        for _, obj in pairs(itemEspObjects) do
            if obj.nameLabel then
                obj.nameLabel.Color = c
            end
        end
    end
})

ESPTab:CreateToggle({
    Name = "Show Name",
    CurrentValue = nameEnabled,
    Callback = function(v) nameEnabled = v end
})

ESPTab:CreateToggle({
    Name = "Show Distance",
    CurrentValue = distanceEnabled,
    Callback = function(v) distanceEnabled = v end
})

-- Items Tab
ItemsTab:CreateSlider({
    Name = "Max ESP Distance",
    Range = {100, 5000},
    Increment = 50,
    Suffix = "studs",
    CurrentValue = itemMaxDistance,
    Callback = function(v) itemMaxDistance = v end
})

ItemsTab:CreateParagraph({
    Title = "📦 Item Info",
    Content = "no?"
})

-- Info Tab
InfoTab:CreateParagraph({
    Title = "Simforea Hub",
    Content = string.format("cry about it", gameName, currentPlaceId, flightSpeed)
})

-- ==================== ЗАПУСК ====================
updateItemCache()

-- Обновление ESP каждый кадр
RunService.RenderStepped:Connect(function()
    pcall(updateItemESP)
    pcall(updateSpeedhack)
    pcall(updateInfiniteJump)
end)

-- Обновляем кеш в фоне
task.spawn(function()
    while true do
        task.wait(CACHE_UPDATE_INTERVAL)
        if not autoFarmEnabled then
            updateItemCache()
        end
    end
end)

-- Следим за новыми предметами
local function watchForNewItems()
    local itemSpawns = workspace:FindFirstChild("Item_Spawns")
    if itemSpawns then
        local itemsFolder = itemSpawns:FindFirstChild("Items")
        if itemsFolder then
            itemsFolder.ChildAdded:Connect(function(newItem)
                if newItem:IsA("Model") then
                    updateItemCache()
                end
            end)
            
            itemsFolder.ChildRemoved:Connect(function(removedItem)
                if itemEspObjects[removedItem] then
                    removeItemESP(removedItem)
                end
            end)
        end
    end
end

task.spawn(watchForNewItems)

-- Переподключение байпасов при смене персонажа
Players.LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    setupMagnitudeBypass()
    if noclipEnabled then
        startNoclip()
    end
end)

if noclipEnabled then
    startNoclip()
end

safeNotify("Simforea Hub", 3)
