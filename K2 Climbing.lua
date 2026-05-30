-- Simforea Hub

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Camera = workspace.CurrentCamera or workspace:WaitForChild("CurrentCamera")

local hasDrawing = pcall(Drawing.new, "Text")
if not hasDrawing then
    warn("Drawing API not supported – ESP disabled")
end

print("========================================")
print("[Simforea Hub] Loading...")
print("========================================")

local player = Players.LocalPlayer

-- ==================== TELEPORT LOCATIONS ====================
local teleportLocations = {
    { Name = "Basecamp", CFrame = CFrame.new(11406.9326, 3229.25928, 639.67572) * CFrame.Angles(0, math.rad(-171.5), 0) },
    { Name = "Camp 1", CFrame = CFrame.new(12152.8516, 5755.06885, -6038.89941) * CFrame.Angles(0, math.rad(-133), 0) },
    { Name = "Camp 2", CFrame = CFrame.new(3613.8606, 8983.26953, -3872.78418) * CFrame.Angles(0, math.rad(-121.5), 0) },
    { Name = "Camp 3", CFrame = CFrame.new(2543.38843, 10734.3398, -2307.05444) * CFrame.Angles(0, math.rad(47.5), 0) },
    { Name = "Peak (End)", CFrame = CFrame.new(304.379852, 14055.0664, -677.202637) * CFrame.Angles(0, math.rad(77.8), 0) }
}

-- ==================== ITEM TO GIVE ====================
local ITEM_PATH = ReplicatedStorage:FindFirstChild("iceaxeshop")
local ITEM_NAME = "Carbon Ice Axe"
local ITEM = ITEM_PATH and ITEM_PATH:FindFirstChild(ITEM_NAME)

-- ==================== SETTINGS ====================
local DEFAULT_SPEEDHACK_ENABLED = false
local DEFAULT_INFINITE_JUMP_ENABLED = false
local DEFAULT_NOCLIP_ENABLED = false

local DEFAULT_ANTI_FALL_DAMAGE_ENABLED = false
local DEFAULT_ANTI_SLIP_ENABLED = false
local DEFAULT_ANTI_OXYGEN_ENABLED = false
local DEFAULT_ANTI_RAGDOLL_ENABLED = false

local DEFAULT_SPEED = 200
local DEFAULT_INFINITE_JUMP_BOOST = 50

local MIN_SPEED = 50
local MAX_SPEED = 500

-- ==================== GLOBAL VARIABLES ====================
local speedhackEnabled = DEFAULT_SPEEDHACK_ENABLED
local infiniteJumpEnabled = DEFAULT_INFINITE_JUMP_ENABLED
local noclipEnabled = DEFAULT_NOCLIP_ENABLED

local currentSpeed = DEFAULT_SPEED
local currentInfiniteJumpBoost = DEFAULT_INFINITE_JUMP_BOOST

local antiFallDamageEnabled = DEFAULT_ANTI_FALL_DAMAGE_ENABLED
local antiSlipEnabled = DEFAULT_ANTI_SLIP_ENABLED
local antiOxygenEnabled = DEFAULT_ANTI_OXYGEN_ENABLED
local antiRagdollEnabled = DEFAULT_ANTI_RAGDOLL_ENABLED

-- Player ESP settings
local playerEspEnabled = true
local playerNameEnabled = true
local playerDistanceEnabled = true
local playerBoxEnabled = true
local playerHealthEnabled = true
local espColor = Color3.fromRGB(0, 255, 255)
local maxDistance = 1000

local playerEspObjects = {}
local noclipConnection = nil

-- Anti-stuff objects storage
local currentFallDamageObject = nil
local currentSlipScriptObject = nil
local currentOxygenObject = nil
local currentRagdollObject = nil

-- Teleport variables
local lastTeleportTime = 0
local TELEPORT_COOLDOWN = 2
local selectedTeleportName = "Basecamp"

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
    print("[Simforea Hub] " .. title .. ": " .. content)
end

-- ==================== GIVE ITEM FUNCTION ====================
local function clearBackpack()
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then return end
    
    local itemsToRemove = {}
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") or item:IsA("HopperBin") then
            table.insert(itemsToRemove, item)
        end
    end
    
    for _, item in ipairs(itemsToRemove) do
        pcall(function()
            item:Destroy()
        end)
        print("[Simforea Hub] Removed from backpack: " .. tostring(item.Name))
    end
    
    if #itemsToRemove > 0 then
        safeNotify("Backpack", "Cleared " .. #itemsToRemove .. " items", 2)
    end
end

local function giveItem()
    -- Check if item exists
    if not ITEM then
        print("[Simforea Hub] ERROR: Item not found in ReplicatedStorage.iceaxeshop")
        safeNotify("Give Item", "Item not found! Check path.", 3)
        return false
    end
    
    -- Clear backpack first
    clearBackpack()
    
    task.wait(0.3)
    
    -- Clone and give the item
    local success, newItem = pcall(function()
        local clonedItem = ITEM:Clone()
        clonedItem.Parent = player.Backpack
        return clonedItem
    end)
    
    if success and newItem and newItem.Parent then
        print("[Simforea Hub] Successfully gave: " .. ITEM_NAME)
        safeNotify("Give Item", "✓ " .. ITEM_NAME .. " added to backpack!", 3)
        
        -- Auto-equip if character exists
        task.wait(0.2)
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                pcall(function()
                    humanoid:EquipTool(newItem)
                end)
                print("[Simforea Hub] Auto-equipped: " .. ITEM_NAME)
            end
        end
        return true
    else
        print("[Simforea Hub] ERROR: Failed to give item!")
        safeNotify("Give Item", "✗ Failed to give item!", 3)
        return false
    end
end

-- ==================== FIX CHARACTER AFTER TELEPORT ====================
local function fixCharacterAfterTeleport()
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if humanoid then
        humanoid.AutoRotate = true
        humanoid.PlatformStand = false
        humanoid.Sit = false
        
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
        
        humanoid.JumpPower = 50
    end
    
    if rootPart then
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
        local currentPos = rootPart.Position
        rootPart.CFrame = CFrame.new(currentPos, currentPos + Vector3.new(0, 0, -1))
        task.wait(0.1)
        rootPart.Anchored = false
    end
    
    pcall(function()
        local camera = workspace.CurrentCamera
        if camera and camera.Focus then
            camera.CameraType = Enum.CameraType.Custom
        end
    end)
    
    print("[Simforea Hub] Character orientation fixed!")
end

-- ==================== ANTI-STUFF SYSTEM ====================
local function findObjectInCharacterFolder(character, objectName)
    if not character or not character.Parent then return nil end
    
    local characterFolder = Workspace:FindFirstChild(character.Name)
    if characterFolder then
        local obj = characterFolder:FindFirstChild(objectName)
        if obj then return obj end
    end
    
    for _, child in ipairs(Workspace:GetChildren()) do
        local obj = child:FindFirstChild(objectName)
        if obj and child.Name == character.Name then
            return obj
        end
    end
    
    return nil
end

local function applyAntiStuff(objectName, enabled, storageVarName)
    local character = player.Character
    if not character then return end
    
    local obj = findObjectInCharacterFolder(character, objectName)
    if obj then
        if storageVarName == "FallDamage" then
            currentFallDamageObject = obj
        elseif storageVarName == "SlipScript" then
            currentSlipScriptObject = obj
        elseif storageVarName == "oxygen" then
            currentOxygenObject = obj
        elseif storageVarName == "Ragdoll" then
            currentRagdollObject = obj
        end
        
        obj.Disabled = enabled
        print("[Simforea Hub] " .. objectName .. ".Disabled = " .. tostring(enabled))
    end
end

local function updateAntiFallDamageState()
    if currentFallDamageObject and currentFallDamageObject.Parent then
        currentFallDamageObject.Disabled = antiFallDamageEnabled
    else
        applyAntiStuff("FallDamage", antiFallDamageEnabled, "FallDamage")
    end
end

local function updateAntiSlipState()
    if currentSlipScriptObject and currentSlipScriptObject.Parent then
        currentSlipScriptObject.Disabled = antiSlipEnabled
    else
        applyAntiStuff("SlipScript", antiSlipEnabled, "SlipScript")
    end
end

local function updateAntiOxygenState()
    if currentOxygenObject and currentOxygenObject.Parent then
        currentOxygenObject.Disabled = antiOxygenEnabled
    else
        applyAntiStuff("oxygen", antiOxygenEnabled, "oxygen")
    end
end

local function updateAntiRagdollState()
    if currentRagdollObject and currentRagdollObject.Parent then
        currentRagdollObject.Disabled = antiRagdollEnabled
    else
        applyAntiStuff("Ragdoll", antiRagdollEnabled, "Ragdoll")
    end
end

-- ==================== TELEPORT FUNCTIONS ====================
local function getCharacterRoot()
    local character = player.Character
    if not character then return nil end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        rootPart = character:FindFirstChild("Torso")
    end
    if not rootPart then
        rootPart = character:FindFirstChild("UpperTorso")
    end
    return rootPart
end

local function directTeleport(cframe)
    local character = player.Character
    if not character then return false end
    
    local rootPart = getCharacterRoot()
    if not rootPart then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    
    local originalAutoRotate = humanoid and humanoid.AutoRotate or true
    
    if humanoid then
        humanoid.AutoRotate = false
        humanoid.PlatformStand = true
    end
    
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero
    
    rootPart.CFrame = cframe
    
    for i = 1, 3 do
        task.wait(0.05)
        rootPart.CFrame = cframe
        rootPart.AssemblyLinearVelocity = Vector3.zero
    end
    
    task.wait(0.15)
    
    if humanoid then
        humanoid.AutoRotate = originalAutoRotate
        humanoid.PlatformStand = false
    end
    
    fixCharacterAfterTeleport()
    
    local distance = (rootPart.Position - cframe.Position).Magnitude
    return distance < 100
end

local function gradualTeleport(cframe, steps)
    steps = steps or 8
    local character = player.Character
    if not character then return false end
    
    local rootPart = getCharacterRoot()
    if not rootPart then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    
    if humanoid then
        humanoid.AutoRotate = false
        humanoid.PlatformStand = true
    end
    
    local startCF = rootPart.CFrame
    
    for i = 1, steps do
        local alpha = i / steps
        local newCF = startCF:Lerp(cframe, alpha)
        
        pcall(function()
            rootPart.CFrame = newCF
            rootPart.AssemblyLinearVelocity = Vector3.zero
        end)
        
        task.wait(0.08)
    end
    
    pcall(function()
        rootPart.CFrame = cframe
        rootPart.AssemblyLinearVelocity = Vector3.zero
    end)
    
    task.wait(0.15)
    
    if humanoid then
        humanoid.AutoRotate = true
        humanoid.PlatformStand = false
    end
    
    fixCharacterAfterTeleport()
    
    local distance = (rootPart.Position - cframe.Position).Magnitude
    return distance < 100
end

local function teleportToLocation(locationName)
    if tick() - lastTeleportTime < TELEPORT_COOLDOWN then
        safeNotify("Teleport", "Please wait " .. TELEPORT_COOLDOWN .. " seconds!", 2)
        return false
    end
    
    if type(locationName) == "table" then
        locationName = locationName[1]
    end
    
    local cframe = nil
    for _, loc in ipairs(teleportLocations) do
        if loc.Name == locationName then
            cframe = loc.CFrame
            break
        end
    end
    
    if not cframe then
        safeNotify("Teleport", "Location not found!", 2)
        return false
    end
    
    print("[Teleport] Teleporting to: " .. locationName)
    safeNotify("Teleport", "Teleporting to " .. locationName .. "...", 2)
    
    local character = player.Character
    if not character then
        safeNotify("Teleport", "Character not found!", 2)
        return false
    end
    
    local success = directTeleport(cframe)
    
    if not success then
        print("[Teleport] Direct failed, trying gradual...")
        success = gradualTeleport(cframe, 10)
    end
    
    if success then
        lastTeleportTime = tick()
        print("[Teleport] Success!")
        safeNotify("Teleport", "✓ Teleported to " .. locationName .. "!", 2)
        return true
    else
        print("[Teleport] Failed!")
        safeNotify("Teleport", "✗ Teleport failed!", 2)
        return false
    end
end

local function emergencyRespawn()
    print("[Teleport] Emergency respawn!")
    safeNotify("Teleport", "Emergency respawn...", 2)
    
    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.Health = 0
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
                if character then
                    local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
                    local humanoid = character:FindFirstChild("Humanoid")
                    if rootPart and humanoid then
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
                                        local healthColor = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
                                        obj.healthLabel.Text = string.format("%.0f%%", healthPercent * 100)
                                        obj.healthLabel.Position = Vector2.new(pos.X, pos.Y - 5)
                                        obj.healthLabel.Color = healthColor
                                        obj.healthLabel.Visible = true
                                    else
                                        obj.healthLabel.Visible = false
                                    end
                                    
                                    if playerBoxEnabled then
                                        local headPos = Camera:WorldToViewportPoint(position + Vector3.new(0, 2.5, 0))
                                        local feetPos = Camera:WorldToViewportPoint(position - Vector3.new(0, 2, 0))
                                        local height = math.abs(headPos.Y - feetPos.Y)
                                        local width = height * 0.5
                                        local left = headPos.X - width / 2
                                        local top = headPos.Y - height
                                        obj.box.Position = Vector2.new(left, top)
                                        obj.box.Size = Vector2.new(width, height)
                                        obj.box.Visible = true
                                        obj.box.Color = espColor
                                    else
                                        obj.box.Visible = false
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
                    elseif playerEspObjects[plr] then
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
    end
    
    noclipConnection = RunService.Heartbeat:Connect(function()
        if noclipEnabled then
            local character = player.Character
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        pcall(function() part.CanCollide = false end)
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
    
    local character = player.Character
    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.CanCollide = true end)
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
print("[Simforea Hub] Loading Rayfield...")

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Simforea Hub",
    Icon = 0,
    LoadingTitle = "Simforea Hub",
    LoadingSubtitle = "Simforea Hub",
    Theme = "Default",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "SimforeaHub",
        FileName = "Settings"
    },
    KeySystem = false
})

print("[Simforea Hub] Rayfield loaded!")

-- ==================== TABS ====================
local TeleportTab = Window:CreateTab("Teleports", 0)
local MovementTab = Window:CreateTab("Movement", 0)
local AntiStuffTab = Window:CreateTab("Anti Stuff", 0)
local ESPTab = Window:CreateTab("Player ESP", 0)
local ItemsTab = Window:CreateTab("Items", 0)
local InfoTab = Window:CreateTab("Info", 0)

-- ==================== ITEMS TAB ====================
ItemsTab:CreateButton({
    Name = "Give Carbon Ice Axe (Clear Backpack)",
    Callback = function()
        giveItem()
    end
})

ItemsTab:CreateButton({
    Name = "Clear Backpack Only",
    Callback = function()
        clearBackpack()
        safeNotify("Backpack", "Backpack cleared!", 2)
    end
})

ItemsTab:CreateParagraph({
    Title = "📦 Item Info",
    Content = "Item: Carbon Ice Axe\nPath: ReplicatedStorage.iceaxeshop.Carbon Ice Axe\n\n⚠️ Backpack will be cleared before giving the item!\n⚠️ Item will be auto-equipped if possible."
})

-- ==================== TELEPORT TAB ====================
local dropdownOptions = {}
for _, location in ipairs(teleportLocations) do
    table.insert(dropdownOptions, location.Name)
end

TeleportTab:CreateDropdown({
    Name = "Select Teleport Location",
    Options = dropdownOptions,
    CurrentOption = selectedTeleportName,
    Callback = function(option)
        if type(option) == "table" then
            selectedTeleportName = option[1]
        else
            selectedTeleportName = option
        end
        print("[Simforea Hub] Selected: " .. selectedTeleportName)
    end
})

TeleportTab:CreateButton({
    Name = "Teleport",
    Callback = function()
        teleportToLocation(selectedTeleportName)
    end
})

TeleportTab:CreateButton({
    Name = "Emergency Respawn",
    Callback = function()
        emergencyRespawn()
    end
})

TeleportTab:CreateParagraph({
    Title = "Teleport Locations",
    Content = "Basecamp\nCamp 1\nCamp 2\nCamp 3\nPeak (End)"
})

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
    Name = "NoClip",
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

-- ==================== ANTI STUFF TAB ====================
AntiStuffTab:CreateToggle({
    Name = "Anti Fall Damage",
    CurrentValue = antiFallDamageEnabled,
    Callback = function(v)
        antiFallDamageEnabled = v
        updateAntiFallDamageState()
        if v then
            safeNotify("Anti Fall Damage", "Disabled! No fall damage.", 2)
        else
            safeNotify("Anti Fall Damage", "Enabled! Fall damage active.", 2)
        end
    end
})

AntiStuffTab:CreateToggle({
    Name = "Anti Slip (SlipScript)",
    CurrentValue = antiSlipEnabled,
    Callback = function(v)
        antiSlipEnabled = v
        updateAntiSlipState()
        if v then
            safeNotify("Anti Slip", "Disabled! No slipping.", 2)
        else
            safeNotify("Anti Slip", "Enabled! Slipping active.", 2)
        end
    end
})

AntiStuffTab:CreateToggle({
    Name = "Anti Oxygen (No suffocation)",
    CurrentValue = antiOxygenEnabled,
    Callback = function(v)
        antiOxygenEnabled = v
        updateAntiOxygenState()
        if v then
            safeNotify("Anti Oxygen", "Disabled! No suffocation.", 2)
        else
            safeNotify("Anti Oxygen", "Enabled! Suffocation active.", 2)
        end
    end
})

AntiStuffTab:CreateToggle({
    Name = "Anti Ragdoll",
    CurrentValue = antiRagdollEnabled,
    Callback = function(v)
        antiRagdollEnabled = v
        updateAntiRagdollState()
        if v then
            safeNotify("Anti Ragdoll", "Disabled! No ragdoll.", 2)
        else
            safeNotify("Anti Ragdoll", "Enabled! Ragdoll active.", 2)
        end
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
    Name = "Show Health",
    CurrentValue = playerHealthEnabled,
    Callback = function(v) playerHealthEnabled = v end
})

ESPTab:CreateToggle({
    Name = "Show Box",
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
    Title = "Simforea Hub",
    Content = "Simforea Hub"
})

-- ==================== SETUP ANTI STUFF ====================
local function setupAntiStuffWatcher(objectName, enabledVar, storageVarName)
    local function apply()
        applyAntiStuff(objectName, enabledVar, storageVarName)
    end
    
    if player.Character then
        apply()
    end
    
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        apply()
    end)
    
    Workspace.ChildAdded:Connect(function(child)
        if player.Character and child.Name == player.Character.Name then
            task.wait(0.5)
            apply()
        end
    end)
end

setupAntiStuffWatcher("FallDamage", antiFallDamageEnabled, "FallDamage")
setupAntiStuffWatcher("SlipScript", antiSlipEnabled, "SlipScript")
setupAntiStuffWatcher("oxygen", antiOxygenEnabled, "oxygen")
setupAntiStuffWatcher("Ragdoll", antiRagdollEnabled, "Ragdoll")

-- ==================== MAIN LOOP ====================
RunService.RenderStepped:Connect(function()
    pcall(updatePlayerESP)
    pcall(updateSpeedhack)
    pcall(updateInfiniteJump)
end)

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

Players.LocalPlayer.CharacterAdded:Connect(function()
    print("[Simforea Hub] Character respawned")
    task.wait(0.5)
    if noclipEnabled then
        startNoclip()
    end
    updateAntiFallDamageState()
    updateAntiSlipState()
    updateAntiOxygenState()
    updateAntiRagdollState()
end)

if noclipEnabled then
    startNoclip()
end

print("========================================")
print("[Simforea Hub] LOADED SUCCESSFULLY!")
print("========================================")

safeNotify("Simforea Hub", "Loaded!", 3)
