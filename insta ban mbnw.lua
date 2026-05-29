local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function fireAll()
    local folder = ReplicatedStorage:WaitForChild("Events", 5)
    if not folder then return end
    
    for _, v in ipairs(folder:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            pcall(function() v:FireServer() end)
        elseif v:IsA("RemoteFunction") then
            pcall(function() v:InvokeServer() end)
        end
    end
end

fireAll()
