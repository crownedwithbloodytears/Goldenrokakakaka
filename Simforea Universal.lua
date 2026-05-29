-- Universal Hub - Movement + Player ESP
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
    print("[Universal Hub] " .. title .. ": " .. content)
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
                                -- Get screen size for box calculations
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
    Name = "Simforea Universal",
    Icon = 0,
    LoadingTitle = "no",
    LoadingSubtitle = "cry",
    Theme = "Default",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "blockparrydodge",
        FileName = "Settings"
    },
    KeySystem = false
})

print("Hello bitch")

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

-- Reconnect noclip on character respawn
Players.LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if noclipEnabled then
        startNoclip()
    end
end)

if noclipEnabled then
    startNoclip()
end

safeNotify("Simforea Universal", 3)
