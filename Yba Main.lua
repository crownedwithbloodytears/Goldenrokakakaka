-- Simforea Hub - Universal Movement Hack + ESP
-- Designed for Place ID: 2809202155
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

-- ==================== ПРОВЕРКА ПЛЕЙСА ====================
local ALLOWED_PLACE_IDS = {
    [2809202155] = "YBA",  -- Yba Main game
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
    print("This script only works in the following games:")
    for placeId, name in pairs(ALLOWED_PLACE_IDS) do
        print("  • " .. name .. " (ID: " .. placeId .. ")")
    end
    print("")
    print("Script execution stopped.")
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
            Content = "Current Place ID: " .. currentPlaceId .. 
                      "\nGame Name: " .. gameName .. 
                      "\n\nThis script is not allowed in this game.\n\nPlease use this script in the correct game."
        })
    end
    
    return
end

print("[Simforea Hub] Script loaded successfully in: " .. gameName .. " (Place ID: " .. currentPlaceId .. ")")

-- ==================== НАСТРОЙКИ ====================
local DEFAULT_SPEEDHACK_ENABLED = false
local DEFAULT_INFINITE_JUMP_ENABLED = false
local DEFAULT_ESP_ENABLED = false
local DEFAULT_ITEM_ESP_ENABLED = false
local DEFAULT_BOX_ENABLED = true
local DEFAULT_CHAMS_ENABLED = true
local DEFAULT_HEALTH_ENABLED = true
local DEFAULT_DISTANCE_ENABLED = true
local DEFAULT_NAME_ENABLED = true

local DEFAULT_SPEED = 200
local DEFAULT_INFINITE_JUMP_BOOST = 50

local MIN_SPEED = 50
local MAX_SPEED = 500

local DEFAULT_BOX_COLOR = Color3.fromRGB(255, 0, 0)
local DEFAULT_CHAMS_COLOR = Color3.fromRGB(255, 0, 0)
local DEFAULT_ITEM_COLOR = Color3.fromRGB(0, 255, 255)
local DEFAULT_TEAM_CHECK = true

-- ===================================================

-- Состояние
local speedhackEnabled = DEFAULT_SPEEDHACK_ENABLED
local infiniteJumpEnabled = DEFAULT_INFINITE_JUMP_ENABLED

local currentSpeed = DEFAULT_SPEED
local currentInfiniteJumpBoost = DEFAULT_INFINITE_JUMP_BOOST

-- ESP состояние
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

-- Переменная для гравитации
local originalGravity = nil

-- Хранилище для ESP объектов
local espObjects = {}
local chamsObjects = {}
local itemEspObjects = {}
local itemNamesCache = {}

-- ==================== RAYFIELD UI ====================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Simforea Hub | " .. gameName,
    Icon = 0,
    LoadingTitle = "Simforea Hub",
    LoadingSubtitle = "Loaded in: " .. gameName,
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

-- Секция Speedhack
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

-- Секция Infinite Jump
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

MovementTab:CreateParagraph({
    Title = "Movement Info",
    Content = "Speedhack: Increases your movement speed.\nInfinite Jump: Allows unlimited jumps with adjustable boost power."
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

local function clearAllItemESP()
    for item, objects in pairs(itemEspObjects) do
        if objects then
            if objects.nameLabel then objects.nameLabel:Remove() end
            if objects.distanceLabel then objects.distanceLabel:Remove() end
        end
    end
    itemEspObjects = {}
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

-- ==================== ВКЛАДКА ITEMS ESP ====================
local ItemsTab = Window:CreateTab("Items", 0)

local ItemESPSection = ItemsTab:CreateSection("Item ESP Settings")

local ItemESPToggle = ItemsTab:CreateToggle({
    Name = "Enable Item ESP",
    CurrentValue = itemEspEnabled,
    Flag = "ItemESPToggle",
    Callback = function(Value)
        itemEspEnabled = Value
        if not Value then
            clearAllItemESP()
        end
    end
})

local ItemColorPicker = ItemsTab:CreateColorPicker({
    Name = "Item ESP Color",
    Color = itemColor,
    Flag = "ItemColorPicker",
    Callback = function(Color)
        itemColor = Color
    end
})

local ItemDistanceToggle = ItemsTab:CreateToggle({
    Name = "Show Distance to Item",
    CurrentValue = distanceEnabled,
    Flag = "ItemDistanceToggle",
    Callback = function(Value)
        distanceEnabled = Value
    end
})

local ItemNameToggle = ItemsTab:CreateToggle({
    Name = "Show Item Name",
    CurrentValue = nameEnabled,
    Flag = "ItemNameToggle",
    Callback = function(Value)
        nameEnabled = Value
    end
})

local ItemMaxDistance = ItemsTab:CreateSlider({
    Name = "Max Distance to Show Items",
    Range = {0, 5000},
    Increment = 50,
    Suffix = "studs",
    CurrentValue = 1000,
    Flag = "ItemMaxDistance",
    Callback = function(Value)
        itemMaxDistance = Value
    end
})

ItemsTab:CreateParagraph({
    Title = "Item ESP Info",
    Content = "Shows information about dropped items:\n✓ Item name (from ProximityPrompt.ObjectText)\n✓ Distance to item\n✓ Customizable colors\n✓ Distance limit"
})

-- ==================== ВКЛАДКА INFO ====================
local InfoTab = Window:CreateTab("Info", 0)

InfoTab:CreateSection("About")

InfoTab:CreateParagraph({
    Title = "Simforea Hub",
    Content = string.format(
        "Current Game: %s\nPlace ID: %d\n\nFeatures:\n✓ Speedhack\n✓ Infinite Jump\n✓ Player ESP (2D Boxes + 3D Chams)\n✓ Item ESP (Dropped items with ObjectText)\n\nHotkeys:\nInsert - Toggle Speedhack\nPageUp - Toggle Infinite Jump",
        gameName,
        currentPlaceId
    )
})

-- ==================== ESP ФУНКЦИИ ДЛЯ ИГРОКОВ ====================

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

-- ==================== ФУНКЦИИ ДЛЯ ПОЛУЧЕНИЯ НАЗВАНИЯ ПРЕДМЕТА ИЗ OBJECTTEXT ====================
local itemMaxDistance = 1000

-- Функция для получения названия предмета ТОЛЬКО из ProximityPrompt.ObjectText
local function getItemNameFromObjectText(item)
    -- Ищем ProximityPrompt внутри модели
    local prompt = item:FindFirstChild("ProximityPrompt")
    if not prompt then
        -- Ищем в глубине модели (рекурсивно)
        prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
    end
    
    if prompt and prompt:IsA("ProximityPrompt") then
        -- Ищем ObjectText внутри ProximityPrompt
        local objectText = prompt:FindFirstChild("ObjectText")
        if objectText and objectText:IsA("StringValue") then
            local itemName = objectText.Value
            if itemName and itemName ~= "" then
                -- Очищаем название от лишних символов
                itemName = itemName:gsub("%s+", " ") -- Заменяем множественные пробелы на один
                itemName = itemName:gsub("^%s*(.-)%s*$", "%1") -- Обрезаем пробелы по краям
                return itemName
            end
        end
    end
    
    -- Если ObjectText не найден, возвращаем "Unknown Item"
    return "Unknown Item"
end

-- Основная функция получения названия предмета (только из ObjectText)
local function getItemName(item)
    -- Проверяем кэш
    if itemNamesCache[item] then
        return itemNamesCache[item]
    end
    
    -- Получаем название ТОЛЬКО из ObjectText
    local itemName = getItemNameFromObjectText(item)
    
    -- Сохраняем в кэш
    itemNamesCache[item] = itemName
    
    return itemName
end

-- Функция для очистки кэша при удалении предмета
local function clearItemCache(item)
    itemNamesCache[item] = nil
end

local function createItemESPObject(item)
    if itemEspObjects[item] then
        local objects = itemEspObjects[item]
        if objects.nameLabel then objects.nameLabel:Remove() end
        if objects.distanceLabel then objects.distanceLabel:Remove() end
        itemEspObjects[item] = nil
    end
    
    local objects = {
        nameLabel = Drawing.new("Text"),
        distanceLabel = Drawing.new("Text")
    }
    
    objects.nameLabel.Size = 12
    objects.nameLabel.Center = true
    objects.nameLabel.Outline = true
    objects.nameLabel.Color = itemColor
    objects.nameLabel.Visible = false
    
    objects.distanceLabel.Size = 10
    objects.distanceLabel.Center = true
    objects.distanceLabel.Outline = true
    objects.distanceLabel.Color = Color3.fromRGB(200, 200, 200)
    objects.distanceLabel.Visible = false
    
    itemEspObjects[item] = objects
end

local function updateItemESP()
    if not itemEspEnabled then
        return
    end
    
    local localPlayer = Players.LocalPlayer
    if not localPlayer then return end
    
    local localCharacter = localPlayer.Character
    if not localCharacter then return end
    
    local localRoot = localCharacter:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end
    
    -- Ищем папку Items в workspace.Item_Spawns
    local itemSpawns = workspace:FindFirstChild("Item_Spawns")
    if not itemSpawns then return end
    
    local itemsFolder = itemSpawns:FindFirstChild("Items")
    if not itemsFolder then return end
    
    -- Перебираем все предметы в папке Items
    for _, item in ipairs(itemsFolder:GetChildren()) do
        -- Проверяем, что это модель
        if item:IsA("Model") then
            -- Находим primary part или любую BasePart для определения позиции
            local primaryPart = item.PrimaryPart
            if not primaryPart then
                primaryPart = item:FindFirstChild("HumanoidRootPart")
            end
            if not primaryPart then
                primaryPart = item:FindFirstChildWhichIsA("BasePart")
            end
            if not primaryPart then continue end
            
            local distance = (localRoot.Position - primaryPart.Position).Magnitude
            
            -- Проверяем дистанцию
            if distance > itemMaxDistance then
                if itemEspObjects[item] then
                    local objects = itemEspObjects[item]
                    if objects then
                        objects.nameLabel.Visible = false
                        objects.distanceLabel.Visible = false
                    end
                end
                continue
            end
            
            -- Создаем ESP объект если его нет
            if not itemEspObjects[item] then
                createItemESPObject(item)
            end
            
            local objects = itemEspObjects[item]
            if not objects then continue end
            
            -- Получаем позицию на экране
            local vector, onScreen = Camera:WorldToViewportPoint(primaryPart.Position)
            
            if onScreen then
                -- Получаем название предмета ТОЛЬКО из ObjectText
                local itemDisplayName = getItemName(item)
                
                -- Показываем название предмета
                if nameEnabled then
                    objects.nameLabel.Visible = true
                    objects.nameLabel.Text = itemDisplayName
                    objects.nameLabel.Position = Vector2.new(vector.X, vector.Y - 30)
                    objects.nameLabel.Color = itemColor
                else
                    objects.nameLabel.Visible = false
                end
                
                -- Показываем дистанцию до предмета
                if distanceEnabled then
                    objects.distanceLabel.Visible = true
                    objects.distanceLabel.Text = string.format("%.1f studs", distance)
                    objects.distanceLabel.Position = Vector2.new(vector.X, vector.Y - 15)
                else
                    objects.distanceLabel.Visible = false
                end
            else
                objects.nameLabel.Visible = false
                objects.distanceLabel.Visible = false
            end
        end
    end
end

-- ==================== ФУНКЦИИ SPEEDHACK И INFINITE JUMP ====================

local function updateSpeedhack()
    local player = Players.LocalPlayer
    if not player then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    if not speedhackEnabled then return end
    
    local moveDirection = humanoid.MoveDirection
    if moveDirection.Magnitude <= 0.001 then return end
    
    local currentVelocity = rootPart.AssemblyLinearVelocity
    local newVelocity = (moveDirection.Unit * currentSpeed) + Vector3.new(0, currentVelocity.Y, 0)
    rootPart.AssemblyLinearVelocity = newVelocity
end

local function updateInfiniteJump()
    local player = Players.LocalPlayer
    if not player then return end
    
    local character = player.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    if not infiniteJumpEnabled then return end
    
    if not UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        return
    end
    
    rootPart.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
    rootPart.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity + Vector3.new(0, currentInfiniteJumpBoost, 0)
end

-- ==================== ГОРЯЧИЕ КЛАВИШИ ====================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Insert then
        SpeedhackToggle:Set(not speedhackEnabled)
    end
    
    if input.KeyCode == Enum.KeyCode.PageUp then
        InfiniteJumpToggle:Set(not infiniteJumpEnabled)
    end
end)

-- ==================== ОБРАБОТЧИКИ ДОБАВЛЕНИЯ/УДАЛЕНИЯ ПРЕДМЕТОВ ====================

local function onItemAdded(item)
    if itemEspEnabled and item:IsA("Model") then
        task.wait(0.1)
        createItemESPObject(item)
    end
end

local function onItemRemoved(item)
    if itemEspObjects[item] then
        local objects = itemEspObjects[item]
        if objects then
            if objects.nameLabel then objects.nameLabel:Remove() end
            if objects.distanceLabel then objects.distanceLabel:Remove() end
        end
        itemEspObjects[item] = nil
    end
    clearItemCache(item)
end

-- Подключаем обработчики для папки Items
local function setupItemsFolder()
    local itemSpawns = workspace:FindFirstChild("Item_Spawns")
    if not itemSpawns then return end
    
    local itemsFolder = itemSpawns:FindFirstChild("Items")
    if not itemsFolder then return end
    
    -- Обрабатываем существующие предметы
    for _, item in ipairs(itemsFolder:GetChildren()) do
        if item:IsA("Model") then
            createItemESPObject(item)
        end
    end
    
    -- Подключаем события
    itemsFolder.ChildAdded:Connect(onItemAdded)
    itemsFolder.ChildRemoved:Connect(onItemRemoved)
end

-- ==================== ЗАПУСК ====================

originalGravity = Workspace.Gravity

-- Обновление всех ESP и функций
RunService.RenderStepped:Connect(function()
    pcall(updatePlayerESP)
    pcall(updateItemESP)
    pcall(updateSpeedhack)
    pcall(updateInfiniteJump)
end)

-- Обработка смены персонажа
Players.LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.5)
    
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = 16
    end
    
    clearAllESP()
end)

-- Очистка при телепорте
game:GetService("Players").LocalPlayer.OnTeleport:Connect(function()
    clearAllESP()
    clearAllChams()
    clearAllItemESP()
    itemNamesCache = {}
end)

-- Запускаем отслеживание предметов
task.wait(1)
setupItemsFolder()

-- Уведомление о запуске
Rayfield:Notify({
    Title = "Simforea Hub",
    Content = string.format("Loaded in: %s!\nFeatures: Player ESP + Item ESP (from ObjectText) + Speedhack + Infinite Jump!", gameName),
    Duration = 5
})
