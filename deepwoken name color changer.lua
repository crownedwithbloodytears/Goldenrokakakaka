local plr = game.Players.LocalPlayer
local gradientsFolder = plr.PlayerGui:WaitForChild("LeaderboardGui"):WaitForChild("LeaderboardClient"):WaitForChild("NameGradients")
local gradients = {
    {name = "Bronze", path = gradientsFolder.Bronze},
    {name = "Top 1", path = gradientsFolder.DarkGoldRed},
    {name = "W rank", path = gradientsFolder.Deep},
    {name = "Gold", path = gradientsFolder.Gold},
    {name = "Purple", path = gradientsFolder.IronVow},
    {name = "Godseeker", path = gradientsFolder.Red},
    {name = "Silver", path = gradientsFolder.Silver}
}
local settings = {toggleKey = Enum.KeyCode.F1}

local function getPlayerElement()
    local sf = plr.PlayerGui:FindFirstChild("LeaderboardGui") and plr.PlayerGui.LeaderboardGui:FindFirstChild("MainFrame") and plr.PlayerGui.LeaderboardGui.MainFrame:FindFirstChild("ScrollingFrame")
    if not sf then return nil end
    for _, pf in ipairs(sf:GetChildren()) do
        if pf:IsA("TextButton") and pf.Name == "PlayerFrame" then
            local ipf = pf:FindFirstChild("PlayerFrame")
            if ipf then
                local plbl = ipf:FindFirstChild("Player")
                if plbl and plbl:IsA("TextLabel") then
                    for _, c in ipairs(plbl:GetChildren()) do
                        if c:IsA("UIGradient") then return plbl end
                    end
                end
            end
        end
    end
    for _, pf in ipairs(sf:GetChildren()) do
        if pf:IsA("TextButton") and pf.Name == "PlayerFrame" then
            local ipf = pf:FindFirstChild("PlayerFrame")
            if ipf then
                local plbl = ipf:FindFirstChild("Player")
                if plbl and plbl:IsA("TextLabel") then return plbl end
            end
        end
    end
    return nil
end

local function getCurrentGradient(pe)
    if not pe then return nil end
    for _, c in ipairs(pe:GetChildren()) do if c:IsA("UIGradient") then return c end end
    return nil
end

local gui = Instance.new("ScreenGui")
gui.Name = "NameColorChanger"
gui.ResetOnSpawn = false
gui.Parent = plr.PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0,200,0,180)
mainFrame.Position = UDim2.new(0.5,-100,0.5,-90)
mainFrame.BackgroundColor3 = Color3.fromRGB(0,0,0)
mainFrame.BackgroundTransparency = 0
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Visible = false
mainFrame.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0,6)
mainCorner.Parent = mainFrame

local titleFrame = Instance.new("Frame")
titleFrame.Size = UDim2.new(1,0,0,32)
titleFrame.BackgroundColor3 = Color3.fromRGB(8,8,8)
titleFrame.BackgroundTransparency = 0
titleFrame.BorderSizePixel = 0
titleFrame.Parent = mainFrame

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1,-40,0,20)
titleText.Position = UDim2.new(0,8,0,6)
titleText.BackgroundTransparency = 1
titleText.Text = "Name Color"
titleText.TextColor3 = Color3.fromRGB(200,200,200)
titleText.TextSize = 11
titleText.Font = Enum.Font.GothamBold
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,26,0,20)
closeBtn.Position = UDim2.new(1,-32,0,6)
closeBtn.Text = "X"
closeBtn.BackgroundColor3 = Color3.fromRGB(30,15,15)
closeBtn.BackgroundTransparency = 0
closeBtn.TextColor3 = Color3.fromRGB(180,100,100)
closeBtn.TextSize = 10
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleFrame
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0,3)
closeCorner.Parent = closeBtn

local content = Instance.new("Frame")
content.Size = UDim2.new(1,0,1,-32)
content.Position = UDim2.new(0,0,0,32)
content.BackgroundTransparency = 1
content.Parent = mainFrame

local keyFrame = Instance.new("Frame")
keyFrame.Size = UDim2.new(1,-12,0,32)
keyFrame.Position = UDim2.new(0,6,0,6)
keyFrame.BackgroundColor3 = Color3.fromRGB(15,15,15)
keyFrame.BackgroundTransparency = 0
keyFrame.Parent = content
local kfCorner = Instance.new("UICorner")
kfCorner.CornerRadius = UDim.new(0,4)
kfCorner.Parent = keyFrame

local keyLabel = Instance.new("TextLabel")
keyLabel.Size = UDim2.new(0.5,0,0,20)
keyLabel.Position = UDim2.new(0,6,0,6)
keyLabel.BackgroundTransparency = 1
keyLabel.Text = "Key"
keyLabel.TextXAlignment = Enum.TextXAlignment.Left
keyLabel.TextColor3 = Color3.fromRGB(150,150,150)
keyLabel.TextSize = 9
keyLabel.Font = Enum.Font.GothamBold
keyLabel.Parent = keyFrame

local keyBtn = Instance.new("TextButton")
keyBtn.Size = UDim2.new(0.4,0,0,24)
keyBtn.Position = UDim2.new(0.55,0,0,4)
keyBtn.Text = "F1"
keyBtn.BackgroundColor3 = Color3.fromRGB(20,20,20)
keyBtn.BackgroundTransparency = 0
keyBtn.TextColor3 = Color3.fromRGB(200,200,200)
keyBtn.TextSize = 9
keyBtn.Font = Enum.Font.GothamBold
keyBtn.Parent = keyFrame
local kbCorner = Instance.new("UICorner")
kbCorner.CornerRadius = UDim.new(0,3)
kbCorner.Parent = keyBtn

local dropdownBtn = Instance.new("TextButton")
dropdownBtn.Size = UDim2.new(1,-12,0,32)
dropdownBtn.Position = UDim2.new(0,6,0,44)
dropdownBtn.Text = "Bronze"
dropdownBtn.BackgroundColor3 = Color3.fromRGB(15,15,15)
dropdownBtn.BackgroundTransparency = 0
dropdownBtn.TextColor3 = Color3.fromRGB(200,200,200)
dropdownBtn.TextSize = 9
dropdownBtn.Font = Enum.Font.Gotham
dropdownBtn.Parent = content
local dbCorner = Instance.new("UICorner")
dbCorner.CornerRadius = UDim.new(0,4)
dbCorner.Parent = dropdownBtn

local dropdownList = Instance.new("ScrollingFrame")
dropdownList.Size = UDim2.new(0,120,0,130)
dropdownList.Position = UDim2.new(1,4,0,44)
dropdownList.BackgroundColor3 = Color3.fromRGB(15,15,15)
dropdownList.BackgroundTransparency = 0
dropdownList.BorderSizePixel = 0
dropdownList.Visible = false
dropdownList.CanvasSize = UDim2.new(0,0,0,#gradients*30)
dropdownList.ScrollBarThickness = 2
dropdownList.Parent = content
local dlCorner = Instance.new("UICorner")
dlCorner.CornerRadius = UDim.new(0,4)
dlCorner.Parent = dropdownList
local llayout = Instance.new("UIListLayout")
llayout.Padding = UDim.new(0,1)
llayout.Parent = dropdownList

local applyBtn = Instance.new("TextButton")
applyBtn.Size = UDim2.new(1,-12,0,30)
applyBtn.Position = UDim2.new(0,6,1,-36)
applyBtn.Text = "Apply"
applyBtn.BackgroundColor3 = Color3.fromRGB(25,25,25)
applyBtn.BackgroundTransparency = 0
applyBtn.TextColor3 = Color3.fromRGB(200,200,200)
applyBtn.TextSize = 10
applyBtn.Font = Enum.Font.GothamBold
applyBtn.Parent = content
local apCorner = Instance.new("UICorner")
apCorner.CornerRadius = UDim.new(0,4)
apCorner.Parent = applyBtn

local selectedGradient = gradients[1]
local dropdownOpen = false
local waitingForInput = false

local function updateKeyDisplay()
    keyBtn.Text = tostring(settings.toggleKey):gsub("Enum.KeyCode.","")
end

for _, grad in ipairs(gradients) do
    local item = Instance.new("TextButton")
    item.Size = UDim2.new(1,0,0,26)
    item.Text = grad.name
    item.BackgroundColor3 = Color3.fromRGB(20,20,20)
    item.BackgroundTransparency = 0
    item.TextColor3 = Color3.fromRGB(200,200,200)
    item.TextSize = 9
    item.Font = Enum.Font.Gotham
    item.Parent = dropdownList
    local icorner = Instance.new("UICorner")
    icorner.CornerRadius = UDim.new(0,3)
    icorner.Parent = item
    item.MouseButton1Click:Connect(function()
        selectedGradient = grad
        dropdownBtn.Text = grad.name
        dropdownList.Visible = false
        dropdownOpen = false
    end)
end

local isMenuOpen = false

local function openMenu()
    if isMenuOpen then return end
    isMenuOpen = true
    mainFrame.Visible = true
end

local function closeMenu()
    if not isMenuOpen then return end
    mainFrame.Visible = false
    isMenuOpen = false
    if dropdownOpen then
        dropdownOpen = false
        dropdownList.Visible = false
    end
end

local function toggleMenu()
    if isMenuOpen then closeMenu() else openMenu() end
end

local function applyGradient()
    local pe = getPlayerElement()
    if not pe then return end
    local cg = getCurrentGradient(pe)
    if cg then cg:Destroy() end
    task.wait(0.05)
    local ng = selectedGradient.path:Clone()
    ng.Parent = pe
end

keyBtn.MouseButton1Click:Connect(function()
    waitingForInput = true
    keyBtn.Text = "..."
    keyBtn.BackgroundColor3 = Color3.fromRGB(35,25,20)
    local conn
    conn = game:GetService("UserInputService").InputBegan:Connect(function(inp, gp)
        if waitingForInput and not gp and inp.KeyCode ~= Enum.KeyCode.Unknown then
            settings.toggleKey = inp.KeyCode
            updateKeyDisplay()
            waitingForInput = false
            keyBtn.BackgroundColor3 = Color3.fromRGB(20,20,20)
            conn:Disconnect()
        end
    end)
    task.wait(5)
    if waitingForInput then
        waitingForInput = false
        keyBtn.BackgroundColor3 = Color3.fromRGB(20,20,20)
        updateKeyDisplay()
        if conn then conn:Disconnect() end
    end
end)

dropdownBtn.MouseButton1Click:Connect(function()
    dropdownOpen = not dropdownOpen
    dropdownList.Visible = dropdownOpen
end)

applyBtn.MouseButton1Click:Connect(applyGradient)
closeBtn.MouseButton1Click:Connect(closeMenu)

local keyConn
local function updateKeybind()
    if keyConn then keyConn:Disconnect() end
    keyConn = game:GetService("UserInputService").InputBegan:Connect(function(inp, gp)
        if not gp and inp.KeyCode == settings.toggleKey then toggleMenu() end
    end)
end
updateKeybind()

game:GetService("UserInputService").InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 and isMenuOpen then
        local mp = inp.Position
        local ba = dropdownBtn.AbsolutePosition
        local bs = dropdownBtn.AbsoluteSize
        local la = dropdownList.AbsolutePosition
        local ls = dropdownList.AbsoluteSize
        local onBtn = mp.X>=ba.X and mp.X<=ba.X+bs.X and mp.Y>=ba.Y and mp.Y<=ba.Y+bs.Y
        local onList = dropdownList.Visible and mp.X>=la.X and mp.X<=la.X+ls.X and mp.Y>=la.Y and mp.Y<=la.Y+ls.Y
        if not onBtn and not onList and dropdownOpen then
            dropdownOpen = false
            dropdownList.Visible = false
        end
    end
end)

local dragging = false
local dStart, sPos
titleFrame.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 and isMenuOpen then
        dragging = true
        dStart = inp.Position
        sPos = mainFrame.Position
    end
end)
game:GetService("UserInputService").InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
game:GetService("UserInputService").InputChanged:Connect(function(inp)
    if dragging and isMenuOpen and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = inp.Position - dStart
        mainFrame.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset+delta.X, sPos.Y.Scale, sPos.Y.Offset+delta.Y)
    end
end)

updateKeyDisplay()
