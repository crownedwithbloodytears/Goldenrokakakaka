local Scripts = {
    [2809202155] = "https://raw.githubusercontent.com/crownedwithbloodytears/SimforeaHub/refs/heads/main/Yba%20Main.lua",
    [3978370137] = "https://raw.githubusercontent.com/crownedwithbloodytears/SimforeaHub/refs/heads/main/GPO.lua",
    [11424731604] = "https://raw.githubusercontent.com/crownedwithbloodytears/SimforeaHub/refs/heads/main/Cupid%20Dungeon.lua",
    [445664957] = "https://raw.githubusercontent.com/crownedwithbloodytears/SimforeaHub/refs/heads/main/Parkour%20legacy%20bags%20esp.lua"
}

local PlaceId = game.PlaceId
local ScriptUrl = Scripts[PlaceId]

if ScriptUrl then
    loadstring(game:HttpGet(ScriptUrl))()
else
    warn("Скрипт для этого плейса не найден. PlaceId: " .. tostring(PlaceId))
end
