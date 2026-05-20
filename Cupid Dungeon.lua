local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local PhysicsService = game:GetService("PhysicsService")

-- ==================== ПРОВЕРКА ПЛЕЙСА ====================
local ALLOWED_PLACE_IDS = {
    [11424731604] = "Cupid Dungeon",
}

local currentPlaceId = game.PlaceId
local gameName = ALLOWED_PLACE_IDS[currentPlaceId] or "Unknown Game"

if not ALLOWED_PLACE_IDS[currentPlaceId] then
    print("=" .. string.rep("=", 60))
    print("⚠️ SIMFOREA HUB - PLACE ID ERROR ⚠️")
    print("=" .. string.rep("=", 60))
    print("Current Place ID: " .. currentPlaceId)
    print("Game Name: " .. gameName)
    print("")
    print("This script only works in allowed games.")
    print("Allowed Place IDs:")
    for placeId, name in pairs(ALLOWED_PLACE_IDS) do
        print("  • " .. placeId .. " - " .. name)
    end
    print("=" .. string.rep("=", 60))
    
    local success, rayfield = pcall(function()
        return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    end)
    
    if success and rayfield then
        local tempWindow = rayfield:CreateWindow({
            Name = "Simforea Hub - Error",
            Icon = 0,
            LoadingTitle = "Place ID Error",
            LoadingSubtitle = "Script stopped",
            Theme = "Default",
            KeySystem = false
        })
        local tempTab = tempWindow:CreateTab("Error", 0)
        tempTab:CreateParagraph({
            Title = "⚠️ WRONG GAME ⚠️",
            Content = "Current Place ID: " .. currentPlaceId .. "\nGame Name: " .. gameName .. 
                      "\n\nThis script only works in allowed games.\n\nAllowed Place IDs:\n" ..
                      "• 3978370137 - Grand Piece Online 1 Sea\n" ..
                      "• 11424731604 - Grand Piece Online (New)"
        })
    end
    
    return
end

print("[Simforea Hub] Script loaded successfully in: " .. gameName .. " (Place ID: " .. currentPlaceId .. ")")
print("[Simforea Hub] Using HYBRID movement: Velocity + CFrame lock")
print("[Simforea Hub] Statue HP detection via barrelHP active")

-- ==================== ADVANCED NOCLIP (CollisionGroup) ====================
local NOCLIP_GROUP = "SimforeaNoClip"

pcall(function()
    PhysicsService:CreateCollisionGroup(NOCLIP_GROUP)
end)

pcall(function()
    PhysicsService:CollisionGroupSetCollidable(NOCLIP_GROUP, "Default", false)
end)

pcall(function()
    PhysicsService:CollisionGroupSetCollidable(NOCLIP_GROUP, "Character", false)
end)

local noclipEnabled = false
local noclipConnection = nil
local characterAddedConnection = nil

local function setPartCollisionGroup(part, group)
    pcall(function()
        if part:IsA("BasePart") then
            PhysicsService:SetPartCollisionGroup(part, group)
        end
    end)
end

local function setCharacterCollisionGroup(character, group)
    if not character then return end
    
    for _, obj in ipairs(character:GetDescendants()) do
        if obj:IsA("BasePart") then
            setPartCollisionGroup(obj, group)
        end
    end
end

local function setupNoclipForNewParts(character)
    if noclipConnection then
        noclipConnection:Disconnect()
    end
    
    noclipConnection = character.DescendantAdded:Connect(function(obj)
        if noclipEnabled and obj:IsA("BasePart") then
            setPartCollisionGroup(obj, NOCLIP_GROUP)
        end
    end)
end

local function setAdvancedNoclip(state)
    noclipEnabled = state
    
    local player = Players.LocalPlayer
    if not player then return end
    
    local character = player.Character
    if not character then return end
    
    if state then
        setCharacterCollisionGroup(character, NOCLIP_GROUP)
        setupNoclipForNewParts(character)
    else
        setCharacterCollisionGroup(character, "Default")
        
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
    end
end

local function onCharacterAdded(character)
    task.wait(0.5)
    
    if noclipEnabled then
        setCharacterCollisionGroup(character, NOCLIP_GROUP)
        setupNoclipForNewParts(character)
    end
end

if characterAddedConnection then
    characterAddedConnection:Disconnect()
end
characterAddedConnection = Players.LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

task.wait(0.5)
if Players.LocalPlayer.Character then
    onCharacterAdded(Players.LocalPlayer.Character)
end

-- ==================== УНИВЕРСАЛЬНАЯ ФУНКЦИЯ ЭКИПИРОВКИ ОРУЖИЯ ====================
local function equipBackWeapon()
    local localPlayer = Players.LocalPlayer
    
    local playerCharacters = workspace:FindFirstChild("PlayerCharacters")
    if not playerCharacters then
        return false
    end
    
    local characterModel = playerCharacters:FindFirstChild(localPlayer.Name)
    if not characterModel then
        return false
    end
    
    local weaponFound = false
    local weaponName = nil
    
    for _, obj in ipairs(characterModel:GetChildren()) do
        if obj:IsA("Model") and string.find(obj.Name, "Back") then
            weaponName = obj.Name:gsub("Back", ""):gsub("%s+", "")
            weaponFound = true
            break
        end
    end
    
    if not weaponFound or not weaponName then
        return false
    end
    
    local backpack = localPlayer:FindFirstChild("Backpack")
    if not backpack then
        return false
    end
    
    local cleanedWeaponName = weaponName:lower()
    
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local cleanedToolName = tool.Name:gsub("%s+", ""):lower()
            
            if string.find(cleanedToolName, cleanedWeaponName) or 
               string.find(cleanedWeaponName, cleanedToolName) then
                tool.Parent = localPlayer.Character
                task.wait(0.3)
                return true
            end
        end
    end
    
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            tool.Parent = localPlayer.Character
            task.wait(0.3)
            return true
        end
    end
    
    return false
end

-- ==================== НАСТРОЙКИ ====================
-- Movement settings
local speedhackEnabled = false
local flyhackEnabled = false
local infiniteJumpEnabled = false
local currentSpeed = 200
local currentFlySpeed = 60
local currentFlyUpSpeed = 40
local currentInfiniteJumpBoost = 50
local MIN_SPEED = 50
local MAX_SPEED = 500

-- AutoFarm settings
MOVE_SPEED = 75
FLY_HEIGHT_OFFSET = 9.5
WAYPOINT_ARRIVAL_DISTANCE = 5
HOVER_PRECISION_DISTANCE = 3
NPC_ARRIVAL_DISTANCE = 12
AUTO_FARM_UPDATE_INTERVAL = 0.016
WAIT_FOR_NPC_INTERVAL = 0.1
SPAWN_WAIT_TIMEOUT = 5
TIMEOUT_DURATION = 30
DAMAGE_PER_ATTACK = 80
TIME_BETWEEN_ATTACKS = 1 / 6
UPWARD_DRIFT_COMPENSATION = 35

-- Состояние
local autoFarmEnabled = false
local currentStage = 1
local isFarming = false
local lastAttackTime = 0
local farmCoroutine = nil
local skyWalkCoroutine = nil

-- Таймеры для Cupid Queen
local queenStatuePositionTimer = 0
local lastQueenCheckTime = 0

-- ==================== SKY WALK ФУНКЦИЯ ====================
local function startSkyWalkLoop()
    if skyWalkCoroutine then
        pcall(function()
            if coroutine.status(skyWalkCoroutine) ~= "dead" then
                task.cancel(skyWalkCoroutine)
            end
        end)
        skyWalkCoroutine = nil
    end
    
    skyWalkCoroutine = task.spawn(function()
        while autoFarmEnabled do
            pcall(function()
                local character = Players.LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    ReplicatedStorage.Events.Skill:InvokeServer(table.unpack({
                        [1] = "Sky Walk2",
                        [2] = {
                            ["char"] = workspace.PlayerCharacters[Players.LocalPlayer.Name],
                            ["cf"] = character.HumanoidRootPart.CFrame,
                        },
                    }))
                end
            end)
            task.wait(2)
        end
    end)
end

local function stopSkyWalkLoop()
    if skyWalkCoroutine then
        pcall(function()
            if coroutine.status(skyWalkCoroutine) ~= "dead" then
                task.cancel(skyWalkCoroutine)
            end
        end)
        skyWalkCoroutine = nil
    end
end

-- ==================== HYBRID MOVEMENT ФУНКЦИИ ====================

local function stabilizeCharacter()
    local character = Players.LocalPlayer.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    rootPart.AssemblyAngularVelocity = Vector3.zero
end

local function moveToPositionVelocity(targetPosition)
    local character = Players.LocalPlayer.Character
    if not character then return false end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    
    local currentPosition = rootPart.Position
    local offset = targetPosition - currentPosition
    local distance = offset.Magnitude
    
    if distance <= WAYPOINT_ARRIVAL_DISTANCE then
        rootPart.AssemblyLinearVelocity = Vector3.zero
        return true
    end
    
    local direction = offset.Unit
    
    rootPart.AssemblyLinearVelocity = direction * MOVE_SPEED + Vector3.new(0, UPWARD_DRIFT_COMPENSATION, 0)
    
    return false
end

local function lockAboveNPCVelocity(npc)
    local character = Players.LocalPlayer.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local npcRoot = npc:FindFirstChild("HumanoidRootPart")
    
    if not rootPart or not npcRoot then
        return
    end
    
    local targetPos = npcRoot.Position + Vector3.new(0, FLY_HEIGHT_OFFSET, 0)
    local offset = targetPos - rootPart.Position
    local distance = offset.Magnitude
    
    if distance > HOVER_PRECISION_DISTANCE then
        rootPart.AssemblyLinearVelocity = offset.Unit * (MOVE_SPEED * 0.8) + Vector3.new(0, UPWARD_DRIFT_COMPENSATION, 0)
    else
        rootPart.AssemblyLinearVelocity = Vector3.new(0, UPWARD_DRIFT_COMPENSATION, 0)
        
        if distance > 1 then
            rootPart.CFrame = CFrame.new(targetPos, npcRoot.Position)
        end
    end
    
    rootPart.CFrame = CFrame.lookAt(rootPart.Position, npcRoot.Position)
end

-- ==================== ТОЧКИ МАРШРУТА ====================
local waypoints = {
    {
        index = 1,
        position = Vector3.new(864.057068, 308.142731, -2281.37012),
        action = "start",
        npcsToKill = {}
    },
    {
        index = 2,
        position = Vector3.new(546.896729, 310.205231, -2282.3623),
        action = "fight",
        npcsToKill = {"Dungeon Attacker", "Dungeon Gun User", "Dungeon Sword User"}
    },
    {
        index = 3,
        position = Vector3.new(515.060791, 320.410309, -2690.81177),
        action = "fight",
        npcsToKill = {"Dungeon Attacker", "Dungeon Gun User", "Dungeon Sword User"}
    },
    {
        index = 4,
        position = Vector3.new(-247.289185, 376.455261, -2706.24731),
        action = "fight",
        npcsToKill = {"Cupid Queen's Guards", "Dungeon Attacker", "Dungeon Gun User", "Dungeon Kiribachi User", "Dungeon Sword User"}
    },
    {
        index = 5,
        position = Vector3.new(-837.030457, 472.725586, -2720.20947),
        action = "fight",
        npcsToKill = {"Cupid Queen's Guards", "Dungeon Attacker", "Dungeon Gun User", "Dungeon Sword User"}
    },
    {
        index = 6,
        position = Vector3.new(-1069.45752, 435.074432, -2754.95044),
        action = "fight",
        npcsToKill = {"Dungeon Attacker", "Dungeon Gun User", "Dungeon Sword User", "Cupid Queen's Guards"}
    },
    {
        index = 7,
        position = Vector3.new(-1091.58838, 491.023743, -3597.33374),
        action = "fight",
        npcsToKill = {"Cupid Queen's Guards", "Dungeon Attacker", "Dungeon Gun User", "Dungeon Sword User"}
    },
    {
        index = 8,
        position = Vector3.new(-1085.56848, 506.270844, -4221.59424),
        action = "boss",
        npcsToKill = {"Leo"}
    },
    {
        index = 9,
        position = Vector3.new(-1091.43799, 631.164368, -4618.78369),
        action = "move",
        npcsToKill = {}
    },
    {
        index = 10,
        position = Vector3.new(-1091.30518, 666.207336, -4994.50244),
        action = "cupid_queen",
        npcsToKill = {"Cupid Queen"}
    }
}

-- ==================== RAYFIELD UI ====================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Simforea Hub | " .. gameName,
    Icon = 0,
    LoadingTitle = "Simforea Hub",
    LoadingSubtitle = "HYBRID Movement + Dungeon AutoFarm | " .. gameName,
    Theme = "Default",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "SimforeaHub",
        FileName = "Settings"
    },
    KeySystem = false
})

-- ==================== ВКЛАДКИ UI ====================
local MovementTab = Window:CreateTab("Movement", 0)
local AutoFarmTab = Window:CreateTab("Dungeon AutoFarm", 0)
local InfoTab = Window:CreateTab("Info", 0)

-- ==================== MOVEMENT TAB ====================
local SpeedhackSection = MovementTab:CreateSection("Speedhack")
local SpeedhackToggle = MovementTab:CreateToggle({
    Name = "Speedhack", CurrentValue = speedhackEnabled, Flag = "SpeedhackToggle",
    Callback = function(Value) speedhackEnabled = Value end
})

local SpeedSlider = MovementTab:CreateSlider({
    Name = "Speed Value", Range = {MIN_SPEED, MAX_SPEED}, Increment = 1, Suffix = "studs/s",
    CurrentValue = currentSpeed, Flag = "SpeedSlider",
    Callback = function(Value) currentSpeed = Value end
})

local FlyhackSection = MovementTab:CreateSection("Flyhack")
local FlyhackToggle = MovementTab:CreateToggle({
    Name = "Flyhack", CurrentValue = flyhackEnabled, Flag = "FlyhackToggle",
    Callback = function(Value)
        flyhackEnabled = Value
        local character = Players.LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            if Value then
                character.Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
            end
        end
    end
})

local FlySpeedSlider = MovementTab:CreateSlider({
    Name = "Fly Speed (Horizontal)", Range = {MIN_SPEED, MAX_SPEED}, Increment = 1, Suffix = "studs/s",
    CurrentValue = currentFlySpeed, Flag = "FlySpeedSlider",
    Callback = function(Value) currentFlySpeed = Value end
})

local FlyUpSpeedSlider = MovementTab:CreateSlider({
    Name = "Fly Speed (Vertical)", Range = {MIN_SPEED, MAX_SPEED}, Increment = 1, Suffix = "studs/s",
    CurrentValue = currentFlyUpSpeed, Flag = "FlyUpSpeedSlider",
    Callback = function(Value) currentFlyUpSpeed = Value end
})

local InfiniteJumpSection = MovementTab:CreateSection("Infinite Jump")
local InfiniteJumpToggle = MovementTab:CreateToggle({
    Name = "Infinite Jump", CurrentValue = infiniteJumpEnabled, Flag = "InfiniteJumpToggle",
    Callback = function(Value) infiniteJumpEnabled = Value end
})

local InfiniteJumpSlider = MovementTab:CreateSlider({
    Name = "Jump Boost Power", Range = {10, 200}, Increment = 5, Suffix = "studs/s",
    CurrentValue = currentInfiniteJumpBoost, Flag = "InfiniteJumpBoost",
    Callback = function(Value) currentInfiniteJumpBoost = Value end
})

local NoclipSection = MovementTab:CreateSection("Advanced Noclip (CollisionGroup)")
local NoclipToggle = MovementTab:CreateToggle({
    Name = "Advanced Noclip (No Collision with Walls)", 
    CurrentValue = noclipEnabled, 
    Flag = "NoclipToggle",
    Callback = function(Value)
        setAdvancedNoclip(Value)
    end
})

MovementTab:CreateParagraph({
    Title = "⚠️ Movement & Anti-Cheat Info",
    Content = "Movement System:\n" ..
              "✓ Speedhack - Velocity based\n" ..
              "✓ Flyhack - WASD + Space/Ctrl\n" ..
              "✓ Infinite Jump - Boost based\n" ..
              "✓ Advanced Noclip - CollisionGroup\n\n" ..
              "AutoFarm Movement (HYBRID):\n" ..
              "✓ Long distance: AssemblyLinearVelocity\n" ..
              "✓ Close to NPC: Velocity + CFrame lock\n" ..
              "✓ Gravity compensation (+35 Y velocity)\n" ..
              "✓ Angular velocity always zero\n" ..
              "✓ Much harder to detect than pure CFrame!\n\n" ..
              "Hotkeys:\n" ..
              "Insert - Speedhack | Home - Flyhack\n" ..
              "PageUp - Infinite Jump | End - Noclip"
})

-- ==================== ФУНКЦИИ SPEEDHACK, FLYHACK И INFINITE JUMP ====================
local function updateSpeedhack()
    if autoFarmEnabled then return end
    
    if speedhackEnabled and not flyhackEnabled then
        local player = Players.LocalPlayer
        if not player then return end
        
        local character = player.Character
        if not character then return end
        
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return end
        
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        local moveDirection = humanoid.MoveDirection
        if moveDirection.Magnitude > 0.001 then
            local currentVelocity = rootPart.AssemblyLinearVelocity
            local newVelocity = (moveDirection.Unit * currentSpeed) + Vector3.new(0, currentVelocity.Y, 0)
            rootPart.AssemblyLinearVelocity = newVelocity
        end
    end
end

local function updateFlyhack()
    if autoFarmEnabled then return end
    
    if flyhackEnabled then
        local player = Players.LocalPlayer
        if not player then return end
        
        local character = player.Character
        if not character then return end
        
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        local camera = Workspace.CurrentCamera
        if not camera then return end
        
        local moveVector = Vector3.zero
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveVector = moveVector + Vector3.new(0, 0, -1)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveVector = moveVector + Vector3.new(0, 0, 1)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveVector = moveVector + Vector3.new(-1, 0, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveVector = moveVector + Vector3.new(1, 0, 0)
        end
        
        if moveVector.Magnitude > 0 then
            moveVector = moveVector.Unit
        end
        
        local flyVelocity = camera.CFrame:VectorToWorldSpace(moveVector * currentFlySpeed)
        
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            flyVelocity = flyVelocity + Vector3.new(0, currentFlyUpSpeed, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            flyVelocity = flyVelocity + Vector3.new(0, -currentFlyUpSpeed, 0)
        end
        
        rootPart.AssemblyLinearVelocity = flyVelocity
    end
end

local function updateInfiniteJump()
    if autoFarmEnabled then return end
    
    if infiniteJumpEnabled and not flyhackEnabled then
        local player = Players.LocalPlayer
        if not player then return end
        
        local character = player.Character
        if not character then return end
        
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            local currentVel = rootPart.AssemblyLinearVelocity
            if currentVel.Y < 10 then
                rootPart.AssemblyLinearVelocity = Vector3.new(currentVel.X, currentInfiniteJumpBoost, currentVel.Z)
            end
        end
    end
end

-- ==================== ФУНКЦИИ ДЛЯ СТАТУЙ С BARRELHP ====================

local function getStatueHealth(statue)
    local barrelHP = statue:FindFirstChild("barrelHP")
    if barrelHP then
        if barrelHP:IsA("NumberValue") or barrelHP:IsA("IntValue") then
            return barrelHP.Value
        end
    end
    return nil
end

local function isStatueDestroyed(statue)
    local health = getStatueHealth(statue)
    if health ~= nil then
        return health <= 0
    end
    return true
end

local function areAllStatuesDestroyed()
    local statuesFolder = Workspace:FindFirstChild("Env")
    if not statuesFolder then
        return true
    end
    
    local statues = statuesFolder:FindFirstChild("Statues")
    if not statues then
        statues = statuesFolder
    end
    
    local statueNames = {"Statue", "Statue2", "Statue3"}
    
    for _, name in ipairs(statueNames) do
        local statue = statues:FindFirstChild(name)
        if statue then
            local health = getStatueHealth(statue)
            if health ~= nil and health > 0 then
                return false
            end
        end
    end
    
    for _, child in ipairs(statues:GetChildren()) do
        if child.Name:lower():find("statue") then
            local health = getStatueHealth(child)
            if health ~= nil and health > 0 then
                return false
            end
        end
    end
    
    return true
end

local function breakStatues()
    sendNotification("Dungeon AutoFarm", "Checking statues...")
    
    local statuesFolder = Workspace:FindFirstChild("Env")
    if not statuesFolder then
        sendNotification("Dungeon AutoFarm", "Statues folder not found!")
        return false
    end
    
    local statues = statuesFolder:FindFirstChild("Statues")
    if not statues then
        statues = statuesFolder
    end
    
    local statuesToBreak = {}
    
    local possibleStatues = {
        statues:FindFirstChild("Statue3"),
        statues:FindFirstChild("Statue"),
        statues:FindFirstChild("Statue2"),
    }
    
    for _, child in ipairs(statues:GetChildren()) do
        if child.Name:lower():find("statue") then
            table.insert(possibleStatues, child)
        end
    end
    
    for _, statue in ipairs(possibleStatues) do
        if statue then
            local health = getStatueHealth(statue)
            if health ~= nil and health > 0 then
                table.insert(statuesToBreak, {
                    object = statue,
                    health = health,
                    name = statue.Name
                })
                sendNotification("Dungeon AutoFarm", string.format("Found statue: %s (HP: %d)", statue.Name, health))
            elseif health ~= nil and health <= 0 then
                sendNotification("Dungeon AutoFarm", string.format("Statue %s already destroyed (HP: %d)", statue.Name, health))
            end
        end
    end
    
    if #statuesToBreak == 0 then
        sendNotification("Dungeon AutoFarm", "No statues need to be broken!")
        return true
    end
    
    sendNotification("Dungeon AutoFarm", string.format("Breaking %d statues...", #statuesToBreak))
    
    for _, statueInfo in ipairs(statuesToBreak) do
        if not autoFarmEnabled then return false end
        
        local statue = statueInfo.object
        local statueName = statueInfo.name
        
        local statuePos = statue:GetPivot().Position
        local targetPos = statuePos + Vector3.new(0, FLY_HEIGHT_OFFSET, 0)
        
        sendNotification("Dungeon AutoFarm", string.format("Moving to statue: %s (HP: %d)", statueName, statueInfo.health))
        
        local moveResult = false
        repeat
            if not autoFarmEnabled then break end
            moveResult = moveToPositionVelocity(targetPos)
            task.wait(AUTO_FARM_UPDATE_INTERVAL)
        until moveResult == true
        
        if not autoFarmEnabled then return false end
        
        local lastHealth = statueInfo.health
        local noDamageCount = 0
        
        while autoFarmEnabled do
            local currentHealth = getStatueHealth(statue)
            
            if currentHealth == nil then
                sendNotification("Dungeon AutoFarm", string.format("Statue %s destroyed!", statueName))
                break
            end
            
            if currentHealth <= 0 then
                sendNotification("Dungeon AutoFarm", string.format("Statue %s destroyed! (HP: %d)", statueName, currentHealth))
                break
            end
            
            if lastHealth ~= currentHealth and math.floor(currentHealth) % 100 < 20 then
                sendNotification("Dungeon AutoFarm", string.format("Statue %s HP: %d", statueName, currentHealth))
                lastHealth = currentHealth
                noDamageCount = 0
            elseif lastHealth == currentHealth then
                noDamageCount = noDamageCount + 1
                if noDamageCount > 30 then
                    sendNotification("Dungeon AutoFarm", string.format("No damage to %s, retrying position...", statueName))
                    local character = Players.LocalPlayer.Character
                    if character then
                        local rootPart = character:FindFirstChild("HumanoidRootPart")
                        if rootPart then
                            rootPart.CFrame = CFrame.new(targetPos + Vector3.new(0, 5, 0), statuePos)
                            task.wait(0.5)
                            rootPart.CFrame = CFrame.new(targetPos, statuePos)
                        end
                    end
                    noDamageCount = 0
                end
            end
            
            local character = Players.LocalPlayer.Character
            if character then
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    rootPart.AssemblyLinearVelocity = Vector3.new(0, UPWARD_DRIFT_COMPENSATION, 0)
                    rootPart.CFrame = CFrame.new(targetPos, statuePos)
                end
            end
            
            attack()
            task.wait(TIME_BETWEEN_ATTACKS)
        end
    end
    
    sendNotification("Dungeon AutoFarm", "All statues destroyed!")
    return true
end

-- ==================== ФУНКЦИИ ДЛЯ CUPID QUEEN (ИСПРАВЛЕНЫ) ====================

local QUEEN_STATUE_POSITION = CFrame.new(
    -1096.70984, 674.258972, -5201.3999,
    -1, 0, 0,
    0, 1, 0,
    0, 0, -1
)

local function getCupidQueen()
    local npcsFolder = Workspace:FindFirstChild("NPCs")
    if not npcsFolder then
        return nil
    end
    return npcsFolder:FindFirstChild("Cupid Queen")
end

local function getCupidQueenRealPos()
    local cupidQueen = getCupidQueen()
    if not cupidQueen then
        return nil
    end
    
    local realpos = cupidQueen:FindFirstChild("realpos")
    if realpos then
        if realpos:IsA("CFrameValue") then
            return realpos.Value
        elseif realpos:IsA("ObjectValue") and realpos.Value then
            if realpos.Value:IsA("CFrame") then
                return realpos.Value
            end
        end
    end
    
    local rootPart = cupidQueen:FindFirstChild("HumanoidRootPart")
    if rootPart then
        return rootPart.CFrame
    end
    
    return nil
end

local function isCupidQueenAlive()
    local cupidQueen = getCupidQueen()
    if not cupidQueen then
        return false
    end
    
    local humanoid = cupidQueen:FindFirstChild("Humanoid")
    if not humanoid then
        return false
    end
    
    return humanoid.Health > 0
end

local function isCupidQueenAtStatuePosition()
    local queenPos = getCupidQueenRealPos()
    if not queenPos then
        return false
    end
    
    local pos1 = queenPos.Position
    local pos2 = QUEEN_STATUE_POSITION.Position
    
    local distance = (pos1 - pos2).Magnitude
    
    return distance < 15
end

local function updateQueenPositionTimer()
    local currentTime = tick()
    local deltaTime = currentTime - lastQueenCheckTime
    if lastQueenCheckTime == 0 then
        lastQueenCheckTime = currentTime
        return 0
    end
    lastQueenCheckTime = currentTime
    
    if isCupidQueenAtStatuePosition() then
        queenStatuePositionTimer = queenStatuePositionTimer + deltaTime
    else
        queenStatuePositionTimer = 0
    end
    
    return queenStatuePositionTimer
end

local function isQueenReadyForStatuePhase()
    updateQueenPositionTimer()
    return queenStatuePositionTimer >= 2
end

-- Исправленная основная функция боя с Cupid Queen
local function fightCupidQueenWithPhases()
    sendNotification("Dungeon AutoFarm", "Cupid Queen - Waiting for spawn...")
    
    local noDamageTime = 0
    local lastHealth = nil
    local phase = 1
    local noQueenTime = 0
    local lastQueenCheck = tick()
    
    -- Сбрасываем таймеры
    queenStatuePositionTimer = 0
    lastQueenCheckTime = tick()
    
    -- Ждём появления королевы
    local waitStart = tick()
    while autoFarmEnabled and tick() - waitStart < 30 do
        local cupidQueen = getCupidQueen()
        if cupidQueen then
            local humanoid = cupidQueen:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                sendNotification("Dungeon AutoFarm", "Cupid Queen spawned! Starting fight...")
                break
            end
        end
        task.wait(1)
    end
    
    while autoFarmEnabled do
        local cupidQueen = getCupidQueen()
        
        -- Проверяем, не зависла ли королева на позиции статуй
        if cupidQueen and isQueenReadyForStatuePhase() then
            sendNotification("Dungeon AutoFarm", "Queen at statue position for 2+ seconds - Checking statues...")
            
            if not areAllStatuesDestroyed() then
                sendNotification("Dungeon AutoFarm", "Statues need to be broken!")
                breakStatues()
            else
                sendNotification("Dungeon AutoFarm", "All statues already destroyed!")
            end
            
            queenStatuePositionTimer = 0
            task.wait(1)
            continue
        end
        
        if not cupidQueen then
            -- Королевы нет на сцене
            local currentTime = tick()
            if lastQueenCheck == 0 then
                lastQueenCheck = currentTime
            end
            
            noQueenTime = currentTime - lastQueenCheck
            
            if noQueenTime > 5 then
                -- Королевы нет больше 5 секунд, проверяем статуи
                if not areAllStatuesDestroyed() then
                    sendNotification("Dungeon AutoFarm", "Queen missing for 5s - Breaking statues...")
                    breakStatues()
                    lastQueenCheck = tick()
                    noQueenTime = 0
                else
                    -- Статуи уничтожены, но королевы нет - возможно, она переспавнивается
                    sendNotification("Dungeon AutoFarm", "Waiting for Cupid Queen to respawn...")
                    task.wait(2)
                    lastQueenCheck = tick()
                end
            else
                task.wait(0.5)
            end
        else
            -- Королева найдена, сбрасываем таймер отсутствия
            lastQueenCheck = tick()
            noQueenTime = 0
            
            local humanoid = cupidQueen:FindFirstChild("Humanoid")
            if not humanoid then
                task.wait(WAIT_FOR_NPC_INTERVAL)
                continue
            end
            
            if humanoid.Health <= 0 then
                sendNotification("Dungeon AutoFarm", "Cupid Queen defeated!")
                return true
            end
            
            local currentHealth = humanoid.Health
            
            -- Проверка застревания (нет урона)
            if lastHealth and currentHealth >= lastHealth then
                noDamageTime = noDamageTime + AUTO_FARM_UPDATE_INTERVAL
                if noDamageTime > 10 then
                    sendNotification("Dungeon AutoFarm", "No damage for 10s - Checking statues...")
                    if not areAllStatuesDestroyed() then
                        breakStatues()
                    end
                    noDamageTime = 0
                end
            else
                noDamageTime = 0
            end
            lastHealth = currentHealth
            
            -- Показываем прогресс
            if currentHealth < 2000 then
                if phase ~= 3 then
                    phase = 3
                    sendNotification("Dungeon AutoFarm", string.format("Queen HP: %.0f - Almost there!", currentHealth))
                end
            elseif currentHealth < 5000 and phase ~= 2 then
                phase = 2
                sendNotification("Dungeon AutoFarm", string.format("Queen HP: %.0f - Phase 2", currentHealth))
            elseif phase == 1 and currentHealth < 8000 then
                phase = 1
                sendNotification("Dungeon AutoFarm", string.format("Queen HP: %.0f remaining", currentHealth))
            end
            
            -- Если королева на позиции статуй, не атакуем
            if isCupidQueenAtStatuePosition() then
                if not areAllStatuesDestroyed() then
                    sendNotification("Dungeon AutoFarm", "Queen at statue position - Breaking statues...")
                    breakStatues()
                end
                task.wait(WAIT_FOR_NPC_INTERVAL)
            else
                -- Атакуем королеву
                local character = Players.LocalPlayer.Character
                if not character then
                    task.wait(WAIT_FOR_NPC_INTERVAL)
                    continue
                end
                
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                local queenRoot = cupidQueen:FindFirstChild("HumanoidRootPart")
                
                if not rootPart or not queenRoot then
                    task.wait(WAIT_FOR_NPC_INTERVAL)
                    continue
                end
                
                local horizontalDistance = Vector2.new(
                    rootPart.Position.X - queenRoot.Position.X,
                    rootPart.Position.Z - queenRoot.Position.Z
                ).Magnitude
                
                if horizontalDistance <= NPC_ARRIVAL_DISTANCE then
                    lockAboveNPCVelocity(cupidQueen)
                    attack()
                else
                    local targetPos = queenRoot.Position + Vector3.new(0, FLY_HEIGHT_OFFSET, 0)
                    moveToPositionVelocity(targetPos)
                end
            end
        end
        
        task.wait(TIME_BETWEEN_ATTACKS)
    end
    
    return false
end

local function finishCupidQueen()
    sendNotification("Dungeon AutoFarm", "Finishing Cupid Queen...")
    
    local startTime = tick()
    local lastHealth = nil
    local stuckTime = 0
    local lastPosition = nil
    
    while autoFarmEnabled and tick() - startTime < 120 do
        local cupidQueen = getCupidQueen()
        
        if not cupidQueen then
            task.wait(0.5)
            cupidQueen = getCupidQueen()
            if not cupidQueen then
                -- Проверяем статуи перед завершением
                if not areAllStatuesDestroyed() then
                    sendNotification("Dungeon AutoFarm", "Queen missing, breaking statues...")
                    breakStatues()
                else
                    sendNotification("Dungeon AutoFarm", "Cupid Queen defeated!")
                    return true
                end
            end
            continue
        end
        
        local humanoid = cupidQueen:FindFirstChild("Humanoid")
        if not humanoid then
            task.wait(WAIT_FOR_NPC_INTERVAL)
            continue
        end
        
        if humanoid.Health <= 0 then
            sendNotification("Dungeon AutoFarm", "Cupid Queen defeated!")
            return true
        end
        
        -- Проверка на застревание (позиция не меняется)
        local queenRoot = cupidQueen:FindFirstChild("HumanoidRootPart")
        if queenRoot then
            local currentPos = queenRoot.Position
            if lastPosition and (currentPos - lastPosition).Magnitude < 1 then
                stuckTime = stuckTime + AUTO_FARM_UPDATE_INTERVAL
                if stuckTime > 15 then
                    sendNotification("Dungeon AutoFarm", "Queen stuck! Checking statues...")
                    if not areAllStatuesDestroyed() then
                        breakStatues()
                    end
                    stuckTime = 0
                end
            else
                stuckTime = 0
            end
            lastPosition = currentPos
        end
        
        if lastHealth ~= humanoid.Health and math.floor(tick() - startTime) % 10 < 1 then
            sendNotification("Dungeon AutoFarm", string.format("Cupid Queen: %.0f HP left", humanoid.Health))
            lastHealth = humanoid.Health
        end
        
        -- Если королева на позиции статуй
        if isCupidQueenAtStatuePosition() then
            if not areAllStatuesDestroyed() then
                sendNotification("Dungeon AutoFarm", "Queen at statue position - Breaking statues...")
                breakStatues()
            else
                sendNotification("Dungeon AutoFarm", "Queen at statue position, waiting for return...")
                task.wait(2)
            end
            continue
        end
        
        local character = Players.LocalPlayer.Character
        if not character then
            task.wait(WAIT_FOR_NPC_INTERVAL)
            continue
        end
        
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart or not queenRoot then
            task.wait(WAIT_FOR_NPC_INTERVAL)
            continue
        end
        
        local horizontalDistance = Vector2.new(
            rootPart.Position.X - queenRoot.Position.X,
            rootPart.Position.Z - queenRoot.Position.Z
        ).Magnitude
        
        if horizontalDistance <= NPC_ARRIVAL_DISTANCE then
            lockAboveNPCVelocity(cupidQueen)
            attack()
        else
            local targetPos = queenRoot.Position + Vector3.new(0, FLY_HEIGHT_OFFSET, 0)
            moveToPositionVelocity(targetPos)
        end
        
        task.wait(TIME_BETWEEN_ATTACKS)
    end
    
    if isCupidQueenAlive() then
        sendNotification("Dungeon AutoFarm", "Cupid Queen still alive, continuing...")
        return fightCupidQueenWithPhases()
    end
    
    return true
end

-- ==================== ОСТАЛЬНЫЕ ФУНКЦИИ АВТОФАРМА ====================
local function sendNotification(title, content)
    pcall(function()
        Rayfield:Notify({
            Title = title,
            Content = content,
            Duration = 2
        })
    end)
end

local function prepareCharacterForFlight()
    local character = Players.LocalPlayer.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    if not noclipEnabled then
        pcall(function()
            PhysicsService:SetPartCollisionGroup(rootPart, NOCLIP_GROUP)
        end)
    end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        humanoid.AutoRotate = false
    end
end

local function restoreCharacterPhysics()
    local character = Players.LocalPlayer.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
        if not noclipEnabled then
            pcall(function()
                PhysicsService:SetPartCollisionGroup(rootPart, "Default")
            end)
        end
    end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
        humanoid.AutoRotate = true
    end
end

local function getAllNPCsByName(npcName)
    local result = {}
    local npcsFolder = Workspace:FindFirstChild("NPCs")
    
    if not npcsFolder then
        return result
    end
    
    for _, child in ipairs(npcsFolder:GetChildren()) do
        if child.Name == npcName then
            local humanoid = child:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                table.insert(result, child)
            end
        end
    end
    
    return result
end

local function getAllAliveNPCs()
    local result = {}
    local npcsFolder = Workspace:FindFirstChild("NPCs")
    
    if not npcsFolder then
        return result
    end
    
    for _, child in ipairs(npcsFolder:GetChildren()) do
        local humanoid = child:FindFirstChild("Humanoid")
        if humanoid and humanoid.Health > 0 then
            table.insert(result, child)
        end
    end
    
    return result
end

local function hasAliveNPCsInRadius(centerPosition, radius)
    local npcsFolder = Workspace:FindFirstChild("NPCs")
    if not npcsFolder then
        return false
    end
    
    for _, child in ipairs(npcsFolder:GetChildren()) do
        local humanoid = child:FindFirstChild("Humanoid")
        if humanoid and humanoid.Health > 0 then
            local npcRoot = child:FindFirstChild("HumanoidRootPart")
            if npcRoot then
                local distance = (centerPosition - npcRoot.Position).Magnitude
                if distance <= radius then
                    return true
                end
            end
        end
    end
    
    return false
end

local function waitForNPCSpawn(npcNamesList, timeout)
    local startTime = tick()
    
    while autoFarmEnabled and tick() - startTime < timeout do
        for _, npcName in ipairs(npcNamesList) do
            local npcs = getAllNPCsByName(npcName)
            if #npcs > 0 then
                return true
            end
        end
        
        task.wait(WAIT_FOR_NPC_INTERVAL)
    end
    
    return false
end

local function attack()
    local currentTime = tick()
    if currentTime - lastAttackTime >= TIME_BETWEEN_ATTACKS then
        lastAttackTime = currentTime
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end)
        return true
    end
    return false
end

local function clearNPCs(npcNamesList, waypointPosition)
    local shouldClearAnyNPCs = false
    
    if #npcNamesList == 0 then
        if waypointPosition and hasAliveNPCsInRadius(waypointPosition, 50) then
            sendNotification("Dungeon AutoFarm", "Found enemies nearby! Clearing all...")
            shouldClearAnyNPCs = true
        else
            return true
        end
    else
        if not waitForNPCSpawn(npcNamesList, SPAWN_WAIT_TIMEOUT) then
            if hasAliveNPCsInRadius(waypointPosition or Vector3.zero, 50) then
                sendNotification("Dungeon AutoFarm", "Target NPCs not found, clearing all nearby enemies...")
                shouldClearAnyNPCs = true
            else
                sendNotification("Dungeon AutoFarm", "No NPCs spawned, skipping...")
                return true
            end
        end
    end
    
    sendNotification("Dungeon AutoFarm", "Clearing zone...")
    
    local startTime = tick()
    
    while autoFarmEnabled and tick() - startTime < TIMEOUT_DURATION do
        local aliveNPCs = {}
        
        if shouldClearAnyNPCs or #npcNamesList == 0 then
            local npcsFolder = Workspace:FindFirstChild("NPCs")
            if npcsFolder then
                for _, child in ipairs(npcsFolder:GetChildren()) do
                    local humanoid = child:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        local npcRoot = child:FindFirstChild("HumanoidRootPart")
                        if npcRoot and waypointPosition then
                            local distance = (waypointPosition - npcRoot.Position).Magnitude
                            if distance <= 60 then
                                table.insert(aliveNPCs, child)
                            end
                        elseif npcRoot then
                            table.insert(aliveNPCs, child)
                        end
                    end
                end
            end
        else
            for _, npcName in ipairs(npcNamesList) do
                local npcs = getAllNPCsByName(npcName)
                for _, npc in ipairs(npcs) do
                    table.insert(aliveNPCs, npc)
                end
            end
        end
        
        if #aliveNPCs == 0 then
            sendNotification("Dungeon AutoFarm", "Zone cleared!")
            return true
        end
        
        local character = Players.LocalPlayer.Character
        if not character then
            task.wait(WAIT_FOR_NPC_INTERVAL)
        else
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if not rootPart then
                task.wait(WAIT_FOR_NPC_INTERVAL)
            else
                local nearestNPC = nil
                local nearestDistance = math.huge
                
                for _, npc in ipairs(aliveNPCs) do
                    local npcRoot = npc:FindFirstChild("HumanoidRootPart")
                    if npcRoot then
                        local distance = (rootPart.Position - npcRoot.Position).Magnitude
                        if distance < nearestDistance then
                            nearestDistance = distance
                            nearestNPC = npc
                        end
                    end
                end
                
                if nearestNPC then
                    local npcRoot = nearestNPC:FindFirstChild("HumanoidRootPart")
                    if npcRoot then
                        local horizontalDistance = Vector2.new(
                            rootPart.Position.X - npcRoot.Position.X,
                            rootPart.Position.Z - npcRoot.Position.Z
                        ).Magnitude
                        
                        if horizontalDistance <= NPC_ARRIVAL_DISTANCE then
                            lockAboveNPCVelocity(nearestNPC)
                            attack()
                        else
                            local targetPos = npcRoot.Position + Vector3.new(0, FLY_HEIGHT_OFFSET, 0)
                            moveToPositionVelocity(targetPos)
                        end
                    end
                end
            end
        end
        
        task.wait(AUTO_FARM_UPDATE_INTERVAL)
    end
    
    sendNotification("Dungeon AutoFarm", "Zone clear timeout, moving on...")
    return false
end

local function killBossUntilDead(bossName)
    sendNotification("Dungeon AutoFarm", "Fighting " .. bossName .. " until death...")
    
    while autoFarmEnabled do
        local bosses = getAllNPCsByName(bossName)
        
        if #bosses == 0 then
            sendNotification("Dungeon AutoFarm", bossName .. " defeated!")
            return true
        end
        
        local boss = bosses[1]
        local humanoid = boss:FindFirstChild("Humanoid")
        
        if not humanoid or humanoid.Health <= 0 then
            sendNotification("Dungeon AutoFarm", bossName .. " defeated!")
            return true
        end
        
        local character = Players.LocalPlayer.Character
        if not character then
            task.wait(WAIT_FOR_NPC_INTERVAL)
        else
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            local bossRoot = boss:FindFirstChild("HumanoidRootPart")
            
            if rootPart and bossRoot then
                local horizontalDistance = Vector2.new(
                    rootPart.Position.X - bossRoot.Position.X,
                    rootPart.Position.Z - bossRoot.Position.Z
                ).Magnitude
                
                if horizontalDistance <= NPC_ARRIVAL_DISTANCE then
                    lockAboveNPCVelocity(boss)
                    attack()
                else
                    local targetPos = bossRoot.Position + Vector3.new(0, FLY_HEIGHT_OFFSET, 0)
                    moveToPositionVelocity(targetPos)
                end
            end
        end
        
        task.wait(TIME_BETWEEN_ATTACKS)
    end
    
    return false
end

local function equipWeaponForFarm()
    if equipBackWeapon() then
        sendNotification("Dungeon AutoFarm", "Weapon equipped successfully!")
        return true
    end
    
    local localPlayer = Players.LocalPlayer
    local backpack = localPlayer:FindFirstChild("Backpack")
    
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                tool.Parent = localPlayer.Character
                sendNotification("Dungeon AutoFarm", "Equipped: " .. tool.Name)
                return true
            end
        end
    end
    
    sendNotification("Dungeon AutoFarm", "No weapon found in backpack!")
    return false
end

local function activateBusoHaki()
    pcall(function()
        ReplicatedStorage.Events.Haki:FireServer("Buso")
    end)
end

local function waitUntilAtStart()
    local startPos = waypoints[1].position
    
    sendNotification("Dungeon AutoFarm", "Waiting at start point...")
    
    while autoFarmEnabled do
        local character = Players.LocalPlayer.Character
        
        if character then
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            
            if rootPart then
                local distance = (rootPart.Position - startPos).Magnitude
                
                if distance <= 25 then
                    sendNotification("Dungeon AutoFarm", "Start point reached!")
                    return true
                end
            end
        end
        
        task.wait(1)
    end
    
    return false
end

local function startDungeonFarm()
    if isFarming then return end
    isFarming = true
    
    sendNotification("Dungeon AutoFarm", "Waiting for dungeon start...")
    
    local reachedStart = waitUntilAtStart()
    
    if not reachedStart then
        isFarming = false
        return
    end
    
    prepareCharacterForFlight()
    
    sendNotification("Dungeon AutoFarm", "Starting (HYBRID Velocity + CFrame)...")
    
    local startWaypoint = waypoints[1]
    local moveResult = false
    repeat
        if not autoFarmEnabled then break end
        moveResult = moveToPositionVelocity(startWaypoint.position + Vector3.new(0, FLY_HEIGHT_OFFSET, 0))
        task.wait(AUTO_FARM_UPDATE_INTERVAL)
    until moveResult == true
    
    if not autoFarmEnabled then
        restoreCharacterPhysics()
        isFarming = false
        return
    end
    
    sendNotification("Dungeon AutoFarm", "Equipping weapon...")
    equipWeaponForFarm()
    task.wait(0.5)
    
    sendNotification("Dungeon AutoFarm", "Activating Buso Haki...")
    activateBusoHaki()
    task.wait(1)
    
    for stageIndex = 2, #waypoints do
        if not autoFarmEnabled then break end
        
        local waypoint = waypoints[stageIndex]
        currentStage = waypoint.index
        
        sendNotification("Dungeon AutoFarm", "Stage " .. (stageIndex - 1) .. ": Moving to waypoint...")
        
        repeat
            if not autoFarmEnabled then break end
            moveResult = moveToPositionVelocity(waypoint.position + Vector3.new(0, FLY_HEIGHT_OFFSET, 0))
            task.wait(AUTO_FARM_UPDATE_INTERVAL)
        until moveResult == true
        
        if not autoFarmEnabled then break end
        
        if waypoint.action == "fight" then
            sendNotification("Dungeon AutoFarm", "Stage " .. (stageIndex - 1) .. ": Clearing zone...")
            clearNPCs(waypoint.npcsToKill, waypoint.position)
            
        elseif waypoint.action == "boss" then
            sendNotification("Dungeon AutoFarm", "Stage " .. (stageIndex - 1) .. ": Fighting boss...")
            killBossUntilDead(waypoint.npcsToKill[1])
            
        elseif waypoint.action == "cupid_queen" then
            sendNotification("Dungeon AutoFarm", "Starting Cupid Queen fight...")
            
            local queenDefeated = fightCupidQueenWithPhases()
            
            if queenDefeated then
                sendNotification("Dungeon AutoFarm", "Cupid Queen has been defeated!")
            else
                sendNotification("Dungeon AutoFarm", "Finishing Cupid Queen...")
                finishCupidQueen()
            end
        end
    end
    
    restoreCharacterPhysics()
    
    sendNotification("Dungeon AutoFarm", "Dungeon complete!")
    isFarming = false
end

-- ==================== UI ЭЛЕМЕНТЫ AUTOFARM TAB ====================
local AutoFarmToggle = AutoFarmTab:CreateToggle({
    Name = "Enable Dungeon AutoFarm | HYBRID Movement",
    CurrentValue = autoFarmEnabled,
    Flag = "DungeonAutoFarm",
    Callback = function(Value)
        autoFarmEnabled = Value
        if Value then
            currentStage = 1
            isFarming = false
            if farmCoroutine then
                pcall(function()
                    if coroutine.status(farmCoroutine) ~= "dead" then
                        task.cancel(farmCoroutine)
                    end
                end)
                farmCoroutine = nil
            end
            farmCoroutine = task.spawn(function()
                startDungeonFarm()
            end)
            startSkyWalkLoop()
        else
            restoreCharacterPhysics()
            if farmCoroutine then
                pcall(function()
                    if coroutine.status(farmCoroutine) ~= "dead" then
                        task.cancel(farmCoroutine)
                    end
                end)
                farmCoroutine = nil
            end
            stopSkyWalkLoop()
        end
    end
})

local MoveSpeedSlider = AutoFarmTab:CreateSlider({
    Name = "Movement Speed (45-60 recommended)", 
    Range = {30, 80}, 
    Increment = 5, 
    Suffix = "studs/s",
    CurrentValue = MOVE_SPEED, 
    Flag = "MoveSpeed",
    Callback = function(Value) 
        MOVE_SPEED = Value 
    end
})

local FlyHeightSlider = AutoFarmTab:CreateSlider({
    Name = "Fly Height Above NPC", 
    Range = {5, 25}, 
    Increment = 1, 
    Suffix = "studs",
    CurrentValue = FLY_HEIGHT_OFFSET, 
    Flag = "FlyHeight",
    Callback = function(Value) 
        FLY_HEIGHT_OFFSET = Value 
    end
})

local GravityCompSlider = AutoFarmTab:CreateSlider({
    Name = "Gravity Compensation (Upward Force)", 
    Range = {20, 60}, 
    Increment = 5, 
    Suffix = "studs/s",
    CurrentValue = UPWARD_DRIFT_COMPENSATION, 
    Flag = "GravityComp",
    Callback = function(Value) 
        UPWARD_DRIFT_COMPENSATION = Value 
    end
})

local SpawnTimeoutSlider = AutoFarmTab:CreateSlider({
    Name = "Spawn Wait Timeout", 
    Range = {3, 15}, 
    Increment = 1, 
    Suffix = "seconds",
    CurrentValue = SPAWN_WAIT_TIMEOUT, 
    Flag = "SpawnTimeout",
    Callback = function(Value) 
        SPAWN_WAIT_TIMEOUT = Value 
    end
})

AutoFarmTab:CreateParagraph({
    Title = "Dungeon AutoFarm Info - FIXED CUPID QUEEN",
    Content = "✓ HYBRID Movement (umm)\n" ..

})

-- ==================== INFO TAB ====================
InfoTab:CreateSection("About")
InfoTab:CreateParagraph({
    Title = "Simforea Hub | HYBRID Movement + Dungeon AutoFarm",
    Content = "Made for GPO\n\n" ..
})

-- ==================== ГОРЯЧИЕ КЛАВИШИ ====================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Insert then
        SpeedhackToggle:Set(not speedhackEnabled)
    elseif input.KeyCode == Enum.KeyCode.Home then
        if not autoFarmEnabled then
            FlyhackToggle:Set(not flyhackEnabled)
        end
    elseif input.KeyCode == Enum.KeyCode.PageUp then
        InfiniteJumpToggle:Set(not infiniteJumpEnabled)
    elseif input.KeyCode == Enum.KeyCode.End then
        NoclipToggle:Set(not noclipEnabled)
    end
end)

-- ==================== ЗАПУСК ====================
RunService.Heartbeat:Connect(function()
    if autoFarmEnabled then
        pcall(stabilizeCharacter)
    end
    
    pcall(updateSpeedhack)
    pcall(updateFlyhack)
    pcall(updateInfiniteJump)
end)

sendNotification("Simforea Hub", "Loaded in: " .. gameName .. "!\n" ..)
