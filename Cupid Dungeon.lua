-- Dungeon AutoFarm with Rayfield UI (Pure CFrame Flight - No Physics)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

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

-- ==================== НАСТРОЙКИ ====================
MOVE_SPEED = 45
FLY_HEIGHT_OFFSET = 12
WAYPOINT_ARRIVAL_DISTANCE = 5
NPC_ARRIVAL_DISTANCE = 12
AUTO_FARM_UPDATE_INTERVAL = 0.016 -- 60 FPS
WAIT_FOR_NPC_INTERVAL = 0.1
SPAWN_WAIT_TIMEOUT = 10
TIMEOUT_DURATION = 30
DAMAGE_PER_ATTACK = 80
TIME_BETWEEN_ATTACKS = 1 / 6

-- Состояние
local autoFarmEnabled = false
local currentStage = 1
local damageDealtToStatues = {0, 0, 0}
local isFarming = false
local lastAttackTime = 0
local farmCoroutine = nil
local skyWalkCoroutine = nil

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
        npcsToKill = {}
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
    Name = "Simforea Hub | Dungeon AutoFarm",
    Icon = 0,
    LoadingTitle = "Simforea Hub",
    LoadingSubtitle = "Dungeon AutoFarm | " .. gameName,
    Theme = "Default",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "SimforeaHub",
        FileName = "DungeonSettings"
    },
    KeySystem = false
})

-- ==================== sendNotification ====================
local function sendNotification(title, content)
    pcall(function()
        Rayfield:Notify({
            Title = title,
            Content = content,
            Duration = 2
        })
    end)
end

local AutoFarmTab = Window:CreateTab("Dungeon AutoFarm", 0)
local InfoTab = Window:CreateTab("Info", 0)

local startDungeonFarm

-- ==================== ПОДГОТОВКА ПЕРСОНАЖА ====================
local function prepareCharacterForFlight()
    local character = Players.LocalPlayer.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    rootPart.CanCollide = false
    
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
        rootPart.CanCollide = true
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
    end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
        humanoid.AutoRotate = true
    end
end

-- ==================== ЧИСТЫЙ CFrame ПОЛЁТ ====================
local function moveToPosition(targetPosition)
    local character = Players.LocalPlayer.Character
    if not character then return false end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    
    local currentPosition = rootPart.Position
    local distance = (currentPosition - targetPosition).Magnitude
    
    if distance <= WAYPOINT_ARRIVAL_DISTANCE then
        rootPart.CFrame = CFrame.new(targetPosition)
        return true
    end
    
    local step = math.min(MOVE_SPEED * AUTO_FARM_UPDATE_INTERVAL, distance)
    local direction = (targetPosition - currentPosition).Unit
    local newPosition = currentPosition + direction * step
    
    rootPart.CFrame = CFrame.new(newPosition, targetPosition)
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero
    
    return false
end

-- ХАРД-ЛОК НАД NPC
local function lockAboveNPC(npc)
    local character = Players.LocalPlayer.Character
    if not character then return false end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    
    local npcRoot = npc:FindFirstChild("HumanoidRootPart")
    if not npcRoot then return false end
    
    local targetPosition = npcRoot.Position + Vector3.new(0, FLY_HEIGHT_OFFSET, 0)
    
    rootPart.CFrame = CFrame.new(targetPosition, npcRoot.Position)
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero
    
    return true
end

-- ==================== NPC ПОИСК ====================
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

-- ==================== ОЖИДАНИЕ СПАВНА NPC ====================
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

-- ==================== АТАКА ====================
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

-- ==================== ОЧИСТКА ЗОНЫ ====================
local function clearNPCs(npcNamesList)
    sendNotification("Dungeon AutoFarm", "Waiting for NPCs to spawn...")
    
    if not waitForNPCSpawn(npcNamesList, SPAWN_WAIT_TIMEOUT) then
        sendNotification("Dungeon AutoFarm", "No NPCs spawned, skipping...")
        return true
    end
    
    sendNotification("Dungeon AutoFarm", "NPCs spawned, clearing...")
    
    local startTime = tick()
    
    while autoFarmEnabled and tick() - startTime < TIMEOUT_DURATION do
        local aliveNPCs = {}
        for _, npcName in ipairs(npcNamesList) do
            local npcs = getAllNPCsByName(npcName)
            for _, npc in ipairs(npcs) do
                table.insert(aliveNPCs, npc)
            end
        end
        
        if #aliveNPCs == 0 then
            aliveNPCs = getAllAliveNPCs()
        end
        
        if #aliveNPCs == 0 then
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
                            lockAboveNPC(nearestNPC)
                            attack()
                        else
                            local targetPos = npcRoot.Position + Vector3.new(0, FLY_HEIGHT_OFFSET, 0)
                            moveToPosition(targetPos)
                        end
                    end
                end
            end
        end
        
        task.wait(AUTO_FARM_UPDATE_INTERVAL)
    end
    
    return false
end

-- ==================== БОСС ДО СМЕРТИ ====================
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
                    lockAboveNPC(boss)
                    attack()
                else
                    local targetPos = bossRoot.Position + Vector3.new(0, FLY_HEIGHT_OFFSET, 0)
                    moveToPosition(targetPos)
                end
            end
        end
        
        task.wait(TIME_BETWEEN_ATTACKS)
    end
    
    return false
end

-- ==================== СТАТУИ ====================
local function breakStatues()
    local statuesFolder = Workspace:FindFirstChild("Env")
    if not statuesFolder then
        return false
    end
    
    local statues = statuesFolder:FindFirstChild("Statues")
    if not statues then
        statues = statuesFolder
    end
    
    local statuesToBreak = {}
    
    local statueByName = statues:FindFirstChild("Statue3")
    if statueByName then table.insert(statuesToBreak, statueByName) end
    
    local statueMain = statues:FindFirstChild("Statue")
    if statueMain then table.insert(statuesToBreak, statueMain) end
    
    local statue2 = statues:FindFirstChild("Statue2")
    if statue2 then table.insert(statuesToBreak, statue2) end
    
    if #statuesToBreak == 0 then
        local children = statues:GetChildren()
        if children[3] then table.insert(statuesToBreak, children[3]) end
        if children[2] then table.insert(statuesToBreak, children[2]) end
    end
    
    for statueIndex, statue in ipairs(statuesToBreak) do
        if not autoFarmEnabled then return false end
        
        local statuePos = statue:GetPivot().Position
        local targetPos = statuePos + Vector3.new(0, FLY_HEIGHT_OFFSET, 0)
        
        local moveResult = false
        repeat
            if not autoFarmEnabled then break end
            moveResult = moveToPosition(targetPos)
            task.wait(AUTO_FARM_UPDATE_INTERVAL)
        until moveResult == true
        
        if not autoFarmEnabled then return false end
        
        local damageNeeded = 1000 - (damageDealtToStatues[statueIndex] or 0)
        local attacksNeeded = math.ceil(damageNeeded / DAMAGE_PER_ATTACK)
        
        for i = 1, attacksNeeded do
            if not autoFarmEnabled then return false end
            
            local character = Players.LocalPlayer.Character
            if character then
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    rootPart.CFrame = CFrame.new(targetPos, statuePos)
                end
            end
            
            attack()
            damageDealtToStatues[statueIndex] = (damageDealtToStatues[statueIndex] or 0) + DAMAGE_PER_ATTACK
            task.wait(TIME_BETWEEN_ATTACKS)
        end
    end
    
    return true
end

-- ==================== CUPID QUEEN ====================
local function getCupidQueen()
    local npcsFolder = Workspace:FindFirstChild("NPCs")
    if not npcsFolder then
        return nil
    end
    return npcsFolder:FindFirstChild("Cupid Queen")
end

local function fightCupidQueen(requiredDamage)
    local startTime = tick()
    local damageDealt = 0
    
    while autoFarmEnabled and tick() - startTime < TIMEOUT_DURATION and damageDealt < requiredDamage do
        local cupidQueen = getCupidQueen()
        if not cupidQueen then 
            task.wait(WAIT_FOR_NPC_INTERVAL)
        else
            local humanoid = cupidQueen:FindFirstChild("Humanoid")
            if not humanoid then return true end
            
            local character = Players.LocalPlayer.Character
            if not character then
                task.wait(WAIT_FOR_NPC_INTERVAL)
            else
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if not rootPart then
                    task.wait(WAIT_FOR_NPC_INTERVAL)
                else
                    local queenRoot = cupidQueen:FindFirstChild("HumanoidRootPart")
                    if queenRoot then
                        local horizontalDistance = Vector2.new(
                            rootPart.Position.X - queenRoot.Position.X,
                            rootPart.Position.Z - queenRoot.Position.Z
                        ).Magnitude
                        
                        if horizontalDistance <= NPC_ARRIVAL_DISTANCE then
                            lockAboveNPC(cupidQueen)
                            attack()
                            damageDealt = damageDealt + DAMAGE_PER_ATTACK
                        else
                            local targetPos = queenRoot.Position + Vector3.new(0, FLY_HEIGHT_OFFSET, 0)
                            moveToPosition(targetPos)
                        end
                    end
                end
            end
        end
        
        task.wait(TIME_BETWEEN_ATTACKS)
    end
    
    return damageDealt >= requiredDamage
end

-- ==================== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ====================
local function equipIcebornBlade()
    local localPlayer = Players.LocalPlayer
    local backpack = localPlayer:FindFirstChild("Backpack")
    
    if backpack then
        local icebornBlade = backpack:FindFirstChild("Iceborn Blade")
        if icebornBlade and icebornBlade:IsA("Tool") then
            icebornBlade.Parent = localPlayer.Character
            task.wait(0.5)
            return true
        end
    end
    
    local character = localPlayer.Character
    if character then
        local heldBlade = character:FindFirstChild("Iceborn Blade")
        if heldBlade then
            return true
        end
    end
    
    return false
end

local function activateBusoHaki()
    pcall(function()
        ReplicatedStorage.Events.Haki:FireServer("Buso")
    end)
end

-- ==================== ОЖИДАНИЕ СТАРТОВОЙ ТОЧКИ ====================
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

-- ==================== ОСНОВНАЯ ФУНКЦИЯ АВТОФАРМА ====================
startDungeonFarm = function()
    if isFarming then return end
    isFarming = true
    
    sendNotification("Dungeon AutoFarm", "Waiting for dungeon start...")
    
    local reachedStart = waitUntilAtStart()
    
    if not reachedStart then
        isFarming = false
        return
    end
    
    prepareCharacterForFlight()
    
    sendNotification("Dungeon AutoFarm", "Starting (Pure CFrame Flight)...")
    
    local startWaypoint = waypoints[1]
    local moveResult = false
    repeat
        if not autoFarmEnabled then break end
        moveResult = moveToPosition(startWaypoint.position + Vector3.new(0, FLY_HEIGHT_OFFSET, 0))
        task.wait(AUTO_FARM_UPDATE_INTERVAL)
    until moveResult == true
    
    if not autoFarmEnabled then
        restoreCharacterPhysics()
        isFarming = false
        return
    end
    
    sendNotification("Dungeon AutoFarm", "Equipping Iceborn Blade...")
    equipIcebornBlade()
    task.wait(0.5)
    
    sendNotification("Dungeon AutoFarm", "Activating Buso Haki...")
    activateBusoHaki()
    task.wait(1)
    
    for stageIndex = 2, #waypoints do
        if not autoFarmEnabled then break end
        
        local waypoint = waypoints[stageIndex]
        currentStage = waypoint.index
        
        sendNotification("Dungeon AutoFarm", "Stage " .. (stageIndex - 1) .. ": Moving...")
        
        repeat
            if not autoFarmEnabled then break end
            moveResult = moveToPosition(waypoint.position + Vector3.new(0, FLY_HEIGHT_OFFSET, 0))
            task.wait(AUTO_FARM_UPDATE_INTERVAL)
        until moveResult == true
        
        if not autoFarmEnabled then break end
        
        if waypoint.action == "fight" then
            sendNotification("Dungeon AutoFarm", "Stage " .. (stageIndex - 1) .. ": Clearing...")
            clearNPCs(waypoint.npcsToKill)
            
        elseif waypoint.action == "boss" then
            sendNotification("Dungeon AutoFarm", "Stage " .. (stageIndex - 1) .. ": Fighting boss...")
            killBossUntilDead(waypoint.npcsToKill[1])
            
        elseif waypoint.action == "cupid_queen" then
            sendNotification("Dungeon AutoFarm", "Breaking statues...")
            breakStatues()
            
            sendNotification("Dungeon AutoFarm", "Fighting Cupid Queen (first phase)...")
            fightCupidQueen(2500)
            
            sendNotification("Dungeon AutoFarm", "Finishing Cupid Queen...")
            fightCupidQueen(999999)
        end
    end
    
    restoreCharacterPhysics()
    
    sendNotification("Dungeon AutoFarm", "Dungeon complete!")
    isFarming = false
end

-- ==================== UI ЭЛЕМЕНТЫ ====================
local AutoFarmToggle = AutoFarmTab:CreateToggle({
    Name = "Enable Dungeon AutoFarm | " .. gameName,
    CurrentValue = autoFarmEnabled,
    Flag = "DungeonAutoFarm",
    Callback = function(Value)
        autoFarmEnabled = Value
        if Value then
            currentStage = 1
            damageDealtToStatues = {0, 0, 0}
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
                if startDungeonFarm then
                    startDungeonFarm()
                end
            end)
            -- Запускаем Sky Walk
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
            -- Останавливаем Sky Walk
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
    Title = "Dungeon AutoFarm Info - " .. gameName,
    Content = "✓ PURE CFrame FLIGHT (no physics)\n" ..
              "✓ HARD LOCK above NPCs (no circling)\n" ..
              "✓ Waits for NPC spawn\n" ..
              "✓ No BodyVelocity, no PlatformStand\n" ..
              "✓ 60 FPS movement\n" ..
              "✓ Auto-equip Iceborn Blade\n" ..
              "✓ Auto-activate Buso Haki\n" ..
              "✓ Auto Sky Walk every 2 seconds\n" ..
              "✓ Full dungeon clear\n\n" ..
              "Stages: 1→2→3→4→5→6→7→8(Leo)→9→10(Cupid Queen)\n\n" ..
              "⚠️ Keep speed at 45-60 for best results!\n" ..
              "⚠️ Have Iceborn Blade in backpack!"
})

InfoTab:CreateSection("About")
InfoTab:CreateParagraph({
    Title = "Simforea Hub | Dungeon AutoFarm",
    Content = "Made for GPO\n\n" ..
              "Supported Place IDs:\n" ..
              "• 3978370137 - Grand Piece Online 1 Sea\n" ..
              "• 11424731604 - Grand Piece Online (New)\n\n" ..
              "Stages:\n" ..
              "1: Start (WAIT FOR PLAYER)\n" ..
              "2: First mobs\n" ..
              "3: Second mobs\n" ..
              "4: Third mobs\n" ..
              "5: Fourth mobs\n" ..
              "6: Fifth mobs (NEW!)\n" ..
              "7: Sixth mobs\n" ..
              "8: Leo (Boss - NO TIMEOUT)\n" ..
              "9: Move to Cupid Queen\n" ..
              "10: Cupid Queen + Statues\n\n" ..
              "Architecture: Pure CFrame | Hard Lock | No Physics\n" ..
              "✓ Leo теперь убивается до конца (без таймаута)\n" ..
              "✓ Автофарм ждёт у входа\n" ..
              "✓ Автоматический Sky Walk каждые 2 секунды"
})

sendNotification("Simforea Hub", "Dungeon AutoFarm loaded!\nPlace ID: " .. currentPlaceId .. " | " .. gameName)
