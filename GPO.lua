-- Speedhack + Flyhack + ESP (with Chams) + Infinite Jump + Island ESP with Rayfield UI
--ESP немного криво работает
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

-- ==================== НАСТРОЙКИ ====================
local DEFAULT_SPEEDHACK_ENABLED = false
local DEFAULT_FLYHACK_ENABLED = false
local DEFAULT_INFINITE_JUMP_ENABLED = false
local DEFAULT_ISLAND_ESP_ENABLED = false
local DEFAULT_SPEED = 200
local DEFAULT_FLY_SPEED = 60
local DEFAULT_FLY_UP_SPEED = 40
local DEFAULT_INFINITE_JUMP_BOOST = 50
local MIN_SPEED = 50
local MAX_SPEED = 500

-- ESP настройки
local DEFAULT_ESP_ENABLED = false
local DEFAULT_BOX_ENABLED = true
local DEFAULT_CHAMS_ENABLED = true
local DEFAULT_HEALTH_ENABLED = true
local DEFAULT_DISTANCE_ENABLED = true
local DEFAULT_NAME_ENABLED = true
local DEFAULT_BOX_COLOR = Color3.fromRGB(255, 0, 0)
local DEFAULT_CHAMS_COLOR = Color3.fromRGB(255, 0, 0)
local DEFAULT_TEAM_CHECK = true

-- Island ESP настройки
local DEFAULT_ISLAND_TEXT_COLOR = Color3.fromRGB(100, 200, 255)
local DEFAULT_ISLAND_DISTANCE_COLOR = Color3.fromRGB(200, 200, 200)
-- ===================================================

-- Состояние
local speedhackEnabled = DEFAULT_SPEEDHACK_ENABLED
local flyhackEnabled = DEFAULT_FLYHACK_ENABLED
local infiniteJumpEnabled = DEFAULT_INFINITE_JUMP_ENABLED
local islandESPEnabled = DEFAULT_ISLAND_ESP_ENABLED
local currentSpeed = DEFAULT_SPEED
local currentFlySpeed = DEFAULT_FLY_SPEED
local currentFlyUpSpeed = DEFAULT_FLY_UP_SPEED
local currentInfiniteJumpBoost = DEFAULT_INFINITE_JUMP_BOOST

-- ESP состояние
local espEnabled = DEFAULT_ESP_ENABLED
local boxEnabled = DEFAULT_BOX_ENABLED
local chamsEnabled = DEFAULT_CHAMS_ENABLED
local healthEnabled = DEFAULT_HEALTH_ENABLED
local distanceEnabled = DEFAULT_DISTANCE_ENABLED
local nameEnabled = DEFAULT_NAME_ENABLED
local boxColor = DEFAULT_BOX_COLOR
local chamsColor = DEFAULT_CHAMS_COLOR
local teamCheck = DEFAULT_TEAM_CHECK

-- Island ESP состояние
local islandTextColor = DEFAULT_ISLAND_TEXT_COLOR
local islandDistanceColor = DEFAULT_ISLAND_DISTANCE_COLOR

-- Переменная для гравитации
local originalGravity = nil

-- Хранилище для ESP объектов
local espObjects = {}
local chamsObjects = {}
local islandESPObjects = {}

-- Список островов из игры
local islandsList = {
    "???? Shrine",
    "A rock",
    "Coco Island",
    "Colosseum",
    "Fishman Cave",
    "Fishman Island",
    "Gravito's Fort",
    "Island Of Zou",
    "Kori Island",
    "Land of the Sky",
    "Logue Town",
    "Marine Base G-1",
    "Marine Fort F-1",
    "Mysterious Cliff",
    "Orange Town",
    "Restaurant Baratie",
    "Reverse Mountain",
    "Roca Island",
    "Sandora",
    "Shark Park",
    "Shell's Town",
    "Sphinx Island",
    "Town of Beginnings"
}

-- ==================== RAYFIELD UI ====================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Создание окна
local Window = Rayfield:CreateWindow({
    Name = "Simforea Hub",
    Icon = 0,
    LoadingTitle = "Simforea Hub",
    LoadingSubtitle = "By PetraAnchor",
    Theme = "Default",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "SimforeaHub",
        FileName = "Settings"
    },
    KeySystem = false
})

-- ==================== ВКЛАДКА MOVEMENT ====================
local MovementTab = Window:CreateTab("Movement", 0)

local SpeedhackSection = MovementTab:CreateSection("Speedhack")

local SpeedhackToggle = MovementTab:CreateToggle({
    Name = "Speedhack",
    CurrentValue = speedhackEnabled,
    Flag = "SpeedhackToggle",
    Callback = function(Value)
        speedhackEnabled = Value
    end
})

local SpeedSlider = MovementTab:CreateSlider({
    Name = "Speed Value",
    Range = {MIN_SPEED, MAX_SPEED},
    Increment = 1,
    Suffix = "studs/s",
    CurrentValue = currentSpeed,
    Flag = "SpeedSlider",
    Callback = function(Value)
        currentSpeed = Value
    end
})

local FlyhackSection = MovementTab:CreateSection("Flyhack")

local FlyhackToggle = MovementTab:CreateToggle({
    Name = "Flyhack",
    CurrentValue = flyhackEnabled,
    Flag = "FlyhackToggle",
    Callback = function(Value)
        flyhackEnabled = Value
        
        local character = Players.LocalPlayer.Character
        if not character then return end
        
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return end
        
        if not Value then
            if originalGravity then
                Workspace.Gravity = originalGravity
            end
            humanoid.PlatformStand = false
        else
            originalGravity = Workspace.Gravity
            Workspace.Gravity = 0
            humanoid.PlatformStand = true
        end
    end
})

local FlySpeedSlider = MovementTab:CreateSlider({
    Name = "Fly Speed (Horizontal)",
    Range = {MIN_SPEED, MAX_SPEED},
    Increment = 1,
    Suffix = "studs/s",
    CurrentValue = currentFlySpeed,
    Flag = "FlySpeedSlider",
    Callback = function(Value)
        currentFlySpeed = Value
    end
})

local FlyUpSpeedSlider = MovementTab:CreateSlider({
    Name = "Fly Speed (Vertical)",
    Range = {MIN_SPEED, MAX_SPEED},
    Increment = 1,
    Suffix = "studs/s",
    CurrentValue = currentFlyUpSpeed,
    Flag = "FlyUpSpeedSlider",
    Callback = function(Value)
        currentFlyUpSpeed = Value
    end
})

local InfiniteJumpSection = MovementTab:CreateSection("Infinite Jump")

local InfiniteJumpToggle = MovementTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = infiniteJumpEnabled,
    Flag = "InfiniteJumpToggle",
    Callback = function(Value)
        infiniteJumpEnabled = Value
    end
})

local InfiniteJumpSlider = MovementTab:CreateSlider({
    Name = "Jump Boost Power",
    Range = {10, 200},
    Increment = 5,
    Suffix = "studs/s",
    CurrentValue = currentInfiniteJumpBoost,
    Flag = "InfiniteJumpBoost",
    Callback = function(Value)
        currentInfiniteJumpBoost = Value
    end
})

-- ==================== ВКЛАДКА ESP (ИГРОКИ) ====================
local ESPTab = Window:CreateTab("ESP", 0)

local ESPMainSection = ESPTab:CreateSection("Player ESP Settings")

local function clearAllESP()
    for player, objects in pairs(espObjects) do
        if objects then
            if objects.box then objects.box:Remove() end
            if objects.healthBar then objects.healthBar:Remove() end
            if objects.nameLabel then objects.nameLabel:Remove() end
            if objects.distanceLabel then objects.distanceLabel:Remove() end
            if objects.healthText then objects.healthText:Remove() end
        end
    end
    espObjects = {}
end

local function clearAllChams()
    for player, chams in pairs(chamsObjects) do
        if chams then
            if chams.highlight then
                chams.highlight:Destroy()
            end
        end
    end
    chamsObjects = {}
end

local ESPToggle = ESPTab:CreateToggle({
    Name = "Enable Player ESP",
    CurrentValue = espEnabled,
    Flag = "ESPToggle",
    Callback = function(Value)
        espEnabled = Value
        if not Value then
            clearAllESP()
            if not chamsEnabled then
                clearAllChams()
            end
        end
    end
})

local ESPDisplaySection = ESPTab:CreateSection("Display Settings")

local BoxToggle = ESPTab:CreateToggle({
    Name = "Show Box (2D outline)",
    CurrentValue = boxEnabled,
    Flag = "BoxToggle",
    Callback = function(Value)
        boxEnabled = Value
    end
})

local ChamsToggle = ESPTab:CreateToggle({
    Name = "Show Chams (3D highlight)",
    CurrentValue = chamsEnabled,
    Flag = "ChamsToggle",
    Callback = function(Value)
        chamsEnabled = Value
        if not Value then
            clearAllChams()
        elseif espEnabled then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= Players.LocalPlayer then
                    updateChamsForPlayer(player)
                end
            end
        end
    end
})

local HealthToggle = ESPTab:CreateToggle({
    Name = "Show Health (Text + Bar)",
    CurrentValue = healthEnabled,
    Flag = "HealthToggle",
    Callback = function(Value)
        healthEnabled = Value
    end
})

local DistanceToggle = ESPTab:CreateToggle({
    Name = "Show Distance",
    CurrentValue = distanceEnabled,
    Flag = "DistanceToggle",
    Callback = function(Value)
        distanceEnabled = Value
    end
})

local NameToggle = ESPTab:CreateToggle({
    Name = "Show Player Name",
    CurrentValue = nameEnabled,
    Flag = "NameToggle",
    Callback = function(Value)
        nameEnabled = Value
    end
})

local TeamCheckToggle = ESPTab:CreateToggle({
    Name = "Team Check (Different Colors)",
    CurrentValue = teamCheck,
    Flag = "TeamCheckToggle",
    Callback = function(Value)
        teamCheck = Value
        if chamsEnabled then
            clearAllChams()
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= Players.LocalPlayer then
                    updateChamsForPlayer(player)
                end
            end
        end
    end
})

local ESPColorSection = ESPTab:CreateSection("Colors")

local BoxColorPicker = ESPTab:CreateColorPicker({
    Name = "Box Color",
    Color = boxColor,
    Flag = "BoxColorPicker",
    Callback = function(Color)
        boxColor = Color
    end
})

local ChamsColorPicker = ESPTab:CreateColorPicker({
    Name = "Chams Color (3D Highlight)",
    Color = chamsColor,
    Flag = "ChamsColorPicker",
    Callback = function(Color)
        chamsColor = Color
        if chamsEnabled then
            for player, chams in pairs(chamsObjects) do
                if chams and chams.highlight then
                    chams.highlight.FillColor = getPlayerColor(player)
                    chams.highlight.OutlineColor = getPlayerColor(player)
                end
            end
        end
    end
})

-- ==================== ВКЛАДКА ISLAND ESP ====================
local IslandTab = Window:CreateTab("Islands", 0)

local IslandESPMainSection = IslandTab:CreateSection("Island ESP Settings")

local IslandESPToggle = IslandTab:CreateToggle({
    Name = "Enable Island ESP",
    CurrentValue = islandESPEnabled,
    Flag = "IslandESPToggle",
    Callback = function(Value)
        islandESPEnabled = Value
        if not Value then
            clearIslandESP()
        end
    end
})

local IslandColorSection = IslandTab:CreateSection("Colors")

local IslandTextColorPicker = IslandTab:CreateColorPicker({
    Name = "Island Name Color",
    Color = islandTextColor,
    Flag = "IslandTextColor",
    Callback = function(Color)
        islandTextColor = Color
    end
})

local IslandDistanceColorPicker = IslandTab:CreateColorPicker({
    Name = "Distance Text Color",
    Color = islandDistanceColor,
    Flag = "IslandDistanceColor",
    Callback = function(Color)
        islandDistanceColor = Color
    end
})

local IslandInfoSection = IslandTab:CreateSection("Info")
IslandTab:CreateParagraph({
    Title = "Island ESP Info",
    Content = "Shows:\n✓ Island Name\n✓ Distance to island\n\nIslands in the list:\n" .. table.concat(islandsList, "\n")
})

-- ==================== ВКЛАДКА INFO ====================
local InfoTab = Window:CreateTab("Info", 0)

InfoTab:CreateSection("About")

InfoTab:CreateParagraph({
    Title = "Simforea Hub",
    Content = "Features:\n✓ Speedhack\n✓ Flyhack (AssemblyLinearVelocity)\n✓ Infinite Jump\n✓ Player ESP (2D Boxes + 3D Chams)\n✓ Island ESP\n\nHotkeys:\nInsert - Toggle Speedhack\nHome - Toggle Flyhack\nPageUp - Toggle Infinite Jump\nEnd - Toggle Island ESP"
})

-- ==================== ESP ФУНКЦИИ (ИГРОКИ) ====================

local function getPlayerTeam(player)
    if player and player.Team then
        return player.Team
    end
    return nil
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
        if chamsEnabled then
            return chamsColor
        else
            return boxColor
        end
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
        
        chamsObjects[player] = {
            highlight = highlight
        }
    end
end

local function getCharacterSize(character)
    if not character then return 5, 5 end
    
    local extents = character:GetExtentsSize()
    local height = math.max(extents.Y, 5)
    local width = math.max(extents.X, 2)
    
    return width, height
end

local function createESPObject(player)
    if espObjects[player] then
        clearAllESP()
    end
    
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
    if not espEnabled then
        return
    end
    
    local localPlayer = Players.LocalPlayer
    if not localPlayer then return end
    
    local localCharacter = localPlayer.Character
    if not localCharacter then return end
    
    local localRoot = localCharacter:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid") then
                local rootPart = character.HumanoidRootPart
                local humanoid = character.Humanoid
                
                if chamsEnabled and espEnabled then
                    if not chamsObjects[player] or not chamsObjects[player].highlight then
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
                        
                        local boxPosition = Vector2.new(
                            vector.X - boxWidth / 2,
                            vector.Y - boxHeight / 2
                        )
                        
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
                            local distanceToPlayer = (localRoot.Position - rootPart.Position).Magnitude
                            objects.distanceLabel.Text = string.format("%.1f studs", distanceToPlayer)
                            objects.distanceLabel.Position = Vector2.new(vector.X, boxPosition.Y + boxSize.Y + 5)
                        else
                            objects.distanceLabel.Visible = false
                        end
                    else
                        if objects then
                            objects.box.Visible = false
                            objects.healthBar.Visible = false
                            objects.nameLabel.Visible = false
                            objects.distanceLabel.Visible = false
                            objects.healthText.Visible = false
                        end
                    end
                end
            else
                if espObjects[player] then
                    local objects = espObjects[player]
                    if objects then
                        if objects.box then objects.box:Remove() end
                        if objects.healthBar then objects.healthBar:Remove() end
                        if objects.nameLabel then objects.nameLabel:Remove() end
                        if objects.distanceLabel then objects.distanceLabel:Remove() end
                        if objects.healthText then objects.healthText:Remove() end
                    end
                    espObjects[player] = nil
                end
            end
        end
    end
end

local function onPlayerAdded(player)
    player.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        if espObjects[player] then
            local objects = espObjects[player]
            if objects then
                if objects.box then objects.box:Remove() end
                if objects.healthBar then objects.healthBar:Remove() end
                if objects.nameLabel then objects.nameLabel:Remove() end
                if objects.distanceLabel then objects.distanceLabel:Remove() end
                if objects.healthText then objects.healthText:Remove() end
            end
            espObjects[player] = nil
        end
        
        if chamsEnabled and espEnabled then
            task.wait(0.1)
            updateChamsForPlayer(player)
        end
    end)
end

local function onPlayerRemoving(player)
    if espObjects[player] then
        local objects = espObjects[player]
        if objects then
            if objects.box then objects.box:Remove() end
            if objects.healthBar then objects.healthBar:Remove() end
            if objects.nameLabel then objects.nameLabel:Remove() end
            if objects.distanceLabel then objects.distanceLabel:Remove() end
            if objects.healthText then objects.healthText:Remove() end
        end
        espObjects[player] = nil
    end
    
    if chamsObjects[player] then
        if chamsObjects[player].highlight then
            chamsObjects[player].highlight:Destroy()
        end
        chamsObjects[player] = nil
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- ==================== ISLAND ESP ФУНКЦИИ ====================

local function createIslandESP(islandObject, islandName)
    if islandESPObjects[islandObject] then
        return
    end
    
    local objects = {
        text = Drawing.new("Text"),
        distance = Drawing.new("Text")
    }
    
    objects.text.Outline = true
    objects.text.OutlineColor = Color3.fromRGB(0, 0, 0)
    objects.text.Color = islandTextColor
    objects.text.Size = 18
    objects.text.Center = true
    
    objects.distance.Outline = true
    objects.distance.OutlineColor = Color3.fromRGB(0, 0, 0)
    objects.distance.Color = islandDistanceColor
    objects.distance.Size = 14
    objects.distance.Center = true
    
    islandESPObjects[islandObject] = objects
end

local function clearIslandESP()
    for island, objects in pairs(islandESPObjects) do
        if objects.text then objects.text:Remove() end
        if objects.distance then objects.distance:Remove() end
    end
    islandESPObjects = {}
end

local function updateIslandESP()
    if not islandESPEnabled then
        return
    end
    
    local localPlayer = Players.LocalPlayer
    local character = localPlayer and localPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    
    if not rootPart then
        return
    end
    
    local islands = Workspace:FindFirstChild("Islands")
    if not islands then
        return
    end
    
    for _, islandName in ipairs(islandsList) do
        local island = islands:FindFirstChild(islandName)
        if island then
            local islandPosition = island:GetPivot().Position
            local distance = (rootPart.Position - islandPosition).Magnitude
            
            if not islandESPObjects[island] then
                createIslandESP(island, islandName)
            end
            
            local objects = islandESPObjects[island]
            if not objects then continue end
            
            local vector, onScreen = Camera:WorldToViewportPoint(islandPosition)
            
            objects.text.Color = islandTextColor
            objects.distance.Color = islandDistanceColor
            
            if onScreen then
                objects.text.Visible = true
                objects.text.Text = islandName
                objects.text.Position = Vector2.new(vector.X, vector.Y - 30)
                
                objects.distance.Visible = true
                objects.distance.Text = string.format("%.0f m", distance)
                objects.distance.Position = Vector2.new(vector.X, vector.Y - 12)
            else
                objects.text.Visible = false
                objects.distance.Visible = false
            end
        end
    end
end

-- ==================== ФУНКЦИИ SPEEDHACK, FLYHACK И INFINITE JUMP ====================

local function updateSpeedhack()
    local player = Players.LocalPlayer
    if not player then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    if not speedhackEnabled or flyhackEnabled then return end
    
    local moveDirection = humanoid.MoveDirection
    if moveDirection.Magnitude <= 0.001 then return end
    
    local currentVelocity = rootPart.AssemblyLinearVelocity
    local newVelocity = (moveDirection.Unit * currentSpeed) + Vector3.new(0, currentVelocity.Y, 0)
    rootPart.AssemblyLinearVelocity = newVelocity
end

local function updateFlyhack()
    local player = Players.LocalPlayer
    if not player then return end
    
    local character = player.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    
    if not rootPart or not humanoid then return end
    
    if not flyhackEnabled then
        return
    end
    
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
    
    if flyVelocity.Magnitude < 0.1 then
        rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end
end

local function updateInfiniteJump()
    local player = Players.LocalPlayer
    if not player then return end
    
    local character = player.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    if not infiniteJumpEnabled or flyhackEnabled then return end
    
    if not UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        return
    end
    
    rootPart.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
    rootPart.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity + Vector3.new(0, currentInfiniteJumpBoost, 0)
end

local function resetGravity()
    if not flyhackEnabled then
        Workspace.Gravity = originalGravity or 196.2
    end
end

-- ==================== ГОРЯЧИЕ КЛАВИШИ ====================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Insert then
        SpeedhackToggle:Set(not speedhackEnabled)
    end
    
    if input.KeyCode == Enum.KeyCode.Home then
        FlyhackToggle:Set(not flyhackEnabled)
    end
    
    if input.KeyCode == Enum.KeyCode.PageUp then
        InfiniteJumpToggle:Set(not infiniteJumpEnabled)
    end
    
    if input.KeyCode == Enum.KeyCode.End then
        IslandESPToggle:Set(not islandESPEnabled)
    end
end)

-- ==================== ЗАПУСК ====================

originalGravity = Workspace.Gravity

-- Обновление всех ESP и функций
RunService.RenderStepped:Connect(function()
    pcall(updatePlayerESP)
    pcall(updateIslandESP)
    pcall(updateSpeedhack)
    pcall(updateFlyhack)
    pcall(updateInfiniteJump)
end)

-- Обработка смены персонажа
Players.LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.5)
    
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = 16
        
        if flyhackEnabled then
            humanoid.PlatformStand = true
            Workspace.Gravity = 0
        else
            humanoid.PlatformStand = false
            resetGravity()
        end
    end
    
    clearAllESP()
end)

-- Очистка при телепорте
game:GetService("Players").LocalPlayer.OnTeleport:Connect(function()
    clearAllESP()
    clearAllChams()
    clearIslandESP()
    if flyhackEnabled then
        Workspace.Gravity = originalGravity or 196.2
    end
end)

-- Уведомление о запуске
Rayfield:Notify({
    Title = "Simforea Hub",
    Content = "Loaded!",
    Duration = 5
})
