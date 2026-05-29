local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Mouse = Players.LocalPlayer:GetMouse()
local Rarities = {
{ name = "Common", color = Color3.fromRGB(180, 180, 180), icon = "⬜" },
{ name = "Uncommon", color = Color3.fromRGB(80, 200, 80), icon = "🟩" },
{ name = "Rare", color = Color3.fromRGB(80, 140, 255), icon = "🟦" },
{ name = "Epic", color = Color3.fromRGB(180, 80, 255), icon = "🟪" },
{ name = "Legendary", color = Color3.fromRGB(255, 180, 0), icon = "🟨" },
{ name = "Ultimate", color = Color3.fromRGB(255, 60, 60), icon = "🟥" },
}
local RarityMap = {}
for _, r in ipairs(Rarities) do
RarityMap[r.name] = r
end
local ESP_BASE = {
BillboardW = 118,
BillboardH = 56,
TierText = 8,
RarityText = 12,
DistText = 9,
Stroke = 1.5,
Corner = 6,
StudsOffsetY = 4,
}
local Config = {
Enabled = false,
MaxDistance = 500,
UpdateRate = 1.0,
ESPUIScale = 1.0,
BuildingCheckRate = 30,
Filter = {
All = true,
Common = true,
Uncommon = true,
Rare = true,
Epic = true,
Legendary = true,
Ultimate = true,
},
}
local ESP_ENABLE_DELAY = 2
local OrbConfig = {
Enabled = false,
MaxDistance = 500,
UpdateRate = 1.0,
ESPUIScale = 1.0,
Filter = {
All = true,
Common = true,
Uncommon = true,
Rare = true,
Epic = true,
Legendary = true,
Ultimate = true,
},
}
local EspVisual = {
ShowLabels = true,
ShowStuds = true,
ShowTracer = true,
ShowHighlight = true,
TracerWidth0 = 0.18,
TracerWidth1 = 0.06,
TracerTransparency = 0.25,
HlFillTransparency = 0.76,
HlOutlineTransparency = 0.26,
}
local function applyHighlightProps(highlight)
if not highlight then
return
end
highlight.FillTransparency = EspVisual.HlFillTransparency
highlight.OutlineTransparency = EspVisual.HlOutlineTransparency
end
local ESPObjects = {}
local OrbESPObjects = {}
local insideBuilding = {}
local buildingParts = {}
local lastBuildingCheckFinishedAt = nil
local buildingUpdating = false
local function cacheBuildingParts()
buildingParts = {}
local buildings = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Buildings")
if not buildings then
return
end
for _, obj in ipairs(buildings:GetDescendants()) do
if obj:IsA("BasePart") and obj.Size.X > 10 and obj.Size.Z > 10 then
table.insert(buildingParts, obj)
end
end
end
local function isInsidePart(part, point)
local lp = part.CFrame:PointToObjectSpace(point)
local half = part.Size / 2
return math.abs(lp.X) <= half.X and math.abs(lp.Y) <= half.Y and math.abs(lp.Z) <= half.Z
end
local function isInsideAnyBuilding(position)
for _, part in ipairs(buildingParts) do
if isInsidePart(part, position) then
return true
end
end
return false
end
local function getModelCenter(model)
local main = model:FindFirstChild("Main")
if main and main:IsA("BasePart") then
return main.Position
end
local ok, cf = pcall(function()
return model:GetBoundingBox()
end)
if ok then
return cf.Position
end
return nil
end
local function getActiveBuildingCheckPeriod()
if not Config.Enabled then
return nil
end
return Config.BuildingCheckRate
end
local function runBuildingCheck()
if buildingUpdating then
return
end
buildingUpdating = true
task.spawn(function()
local bagList = {}
for model in pairs(ESPObjects) do
table.insert(bagList, model)
end
for i, model in ipairs(bagList) do
local center = getModelCenter(model)
if center then
insideBuilding[model] = isInsideAnyBuilding(center)
if ESPObjects[model] then
ESPObjects[model].cachedCenter = center
end
end
if i % 10 == 0 then
task.wait()
end
end
lastBuildingCheckFinishedAt = tick()
buildingUpdating = false
end)
end
local function px(n)
return math.max(6, math.floor(n * Config.ESPUIScale + 0.5))
end
local function applyESPVisual(data)
local b = data.billboard
local tierTag = data.tierTag
local rlbl = data.rarityLbl
local dlbl = data.distLabel
local bg = rlbl.Parent
local bgStroke = bg:FindFirstChildOfClass("UIStroke")
local cornerBg = bg:FindFirstChildOfClass("UICorner")
b.Size = UDim2.new(0, px(ESP_BASE.BillboardW), 0, px(ESP_BASE.BillboardH))
b.StudsOffset = Vector3.new(0, ESP_BASE.StudsOffsetY * Config.ESPUIScale, 0)
if tierTag then
tierTag.Size = UDim2.new(1, -px(8), 0, px(11))
tierTag.Position = UDim2.new(0, px(4), 0, px(1))
tierTag.TextSize = px(ESP_BASE.TierText)
end
rlbl.Size = UDim2.new(1, -px(8), 0, px(22))
rlbl.Position = UDim2.new(0, px(4), 0, px(12))
rlbl.TextSize = px(ESP_BASE.RarityText)
dlbl.Size = UDim2.new(1, -px(8), 0, px(15))
dlbl.Position = UDim2.new(0, px(4), 0, px(34))
dlbl.TextSize = px(ESP_BASE.DistText)
if cornerBg then
cornerBg.CornerRadius = UDim.new(0, math.max(2, px(ESP_BASE.Corner)))
end
if bgStroke then
bgStroke.Thickness = math.max(1, ESP_BASE.Stroke * Config.ESPUIScale)
end
if dlbl then
dlbl.Visible = EspVisual.ShowStuds
end
end
local function getBagRarity(model)
local rv = model:FindFirstChild("RealBagValues")
if rv and rv:IsA("StringValue") then
return rv.Value
end
return "Common"
end
local function isVisible(rarity)
if Config.Filter.All then
return true
end
return Config.Filter[rarity] == true
end
local function findBags()
local bags = {}
local map = workspace:FindFirstChild("Map")
if not map then
return bags
end
for _, obj in ipairs(map:GetChildren()) do
if obj:IsA("Model") and obj:FindFirstChild("RealBagValues") and obj:FindFirstChild("Main") then
table.insert(bags, obj)
end
end
return bags
end
local function isLikelyGuidOrbName(name)
if #name < 36 then
return false
end
local function hex(b)
return (b >= 48 and b <= 57) or (b >= 97 and b <= 102) or (b >= 65 and b <= 70)
end
local function sep(b)
return b == 45
end
local i = 1
for _ = 1, 8 do
if not hex(string.byte(name, i)) then
return false
end
i = i + 1
end
if not sep(string.byte(name, i)) then
return false
end
i = i + 1
for _ = 1, 4 do
if not hex(string.byte(name, i)) then
return false
end
i = i + 1
end
if not sep(string.byte(name, i)) then
return false
end
i = i + 1
for _ = 1, 4 do
if not hex(string.byte(name, i)) then
return false
end
i = i + 1
end
if not sep(string.byte(name, i)) then
return false
end
i = i + 1
for _ = 1, 4 do
if not hex(string.byte(name, i)) then
return false
end
i = i + 1
end
if not sep(string.byte(name, i)) then
return false
end
i = i + 1
for _ = 1, 12 do
if not hex(string.byte(name, i)) then
return false
end
i = i + 1
end
return true
end
local function orbHasEffectMarkers(p)
local glow = p:FindFirstChild("Glow")
local spark = p:FindFirstChild("Sparkles")
local glowOk = glow
and (glow:IsA("ParticleEmitter") or glow:IsA("Beam") or glow:IsA("Trail"))
local sparkOk = spark
and (spark:IsA("ParticleEmitter") or spark:IsA("Sparkles") or spark:IsA("Trail"))
return glowOk and sparkOk
end
local function orbPartHasAnyVfx(p)
if orbHasEffectMarkers(p) then
return true
end
for _, d in ipairs(p:GetDescendants()) do
local c = d.ClassName
if c == "ParticleEmitter" or c == "Trail" or c == "Beam" or c == "Sparkles" then
return true
end
if c == "PointLight" or c == "SurfaceLight" or c == "SpotLight" then
return true
end
end
return false
end
local function isLikelyOrbPart(p)
if not p:IsA("BasePart") then
return false
end
if p:IsA("Terrain") then
return false
end
local par = p.Parent
if par ~= workspace then
return false
end
local s = p.Size
local mx = math.max(s.X, s.Y, s.Z)
local mn = math.min(s.X, s.Y, s.Z)
if mx > 5 or mn < 0.18 then
return false
end
if isLikelyGuidOrbName(p.Name) then
return true
end
local matOk = p.Material == Enum.Material.Neon
or p.Material == Enum.Material.ForceField
or p.Material == Enum.Material.Glass
if not matOk then
return false
end
if orbPartHasAnyVfx(p) then
return true
end
return p:FindFirstChild("TouchInterest") ~= nil or p:FindFirstChild("LensFlareAttachment") ~= nil
end
local function findOrbs()
local list = {}
for _, ch in ipairs(workspace:GetChildren()) do
if isLikelyOrbPart(ch) then
table.insert(list, ch)
end
end
return list
end
local function normalizeOrbBrickName(s)
s = string.lower(s)
return string.gsub(s, "[^%a%d]", "")
end
local ORB_COLOR_SAMPLES = {
{ name = "Common", rgb = { 255, 255, 255 } },
{ name = "Uncommon", rgb = { 100, 255, 100 } },
{ name = "Rare", rgb = { 228, 100, 255 } },
{ name = "Epic", rgb = { 100, 255, 255 } },
{ name = "Legendary", rgb = { 255, 255, 120 } },
{ name = "Ultimate", rgb = { 255, 120, 90 } },
}
local ORB_BRICK_SUBSTRINGS = {
{ sub = "institutionalwhite", rarity = "Common" },
{ sub = "transparentfluorescentyellow", rarity = "Legendary" },
{ sub = "transfluorescentyellow", rarity = "Legendary" },
{ sub = "fluorescentyellow", rarity = "Legendary" },
{ sub = "pastelbluegreen", rarity = "Epic" },
{ sub = "persimmon", rarity = "Ultimate" },
{ sub = "persim", rarity = "Ultimate" },
{ sub = "alder", rarity = "Rare" },
{ sub = "moss", rarity = "Uncommon" },
}
local function orbRarityFromPartColor(p)
local c = p.Color
local r255 = math.floor(c.R * 255 + 0.5)
local g255 = math.floor(c.G * 255 + 0.5)
local b255 = math.floor(c.B * 255 + 0.5)
local best = "Common"
local bestD = math.huge
for _, row in ipairs(ORB_COLOR_SAMPLES) do
local rgb = row.rgb
local d = (r255 - rgb[1]) ^ 2 + (g255 - rgb[2]) ^ 2 + (b255 - rgb[3]) ^ 2
if d < bestD then
bestD = d
best = row.name
end
end
return best
end
local function getOrbRarity(p)
local n = normalizeOrbBrickName(p.BrickColor.Name)
for _, row in ipairs(ORB_BRICK_SUBSTRINGS) do
if string.find(n, row.sub, 1, true) then
return row.rarity
end
end
if string.find(n, "tr", 1, true) and string.find(n, "flu", 1, true) and string.find(n, "yellow", 1, true) then
return "Legendary"
end
return orbRarityFromPartColor(p)
end
local function pxOrb(n)
return math.max(6, math.floor(n * OrbConfig.ESPUIScale + 0.5))
end
local function applyOrbESPVisual(data)
local b = data.billboard
local tierTag = data.tierTag
local rlbl = data.rarityLbl
local dlbl = data.distLabel
local bg = rlbl.Parent
local bgStroke = bg:FindFirstChildOfClass("UIStroke")
local cornerBg = bg:FindFirstChildOfClass("UICorner")
b.Size = UDim2.new(0, pxOrb(ESP_BASE.BillboardW), 0, pxOrb(ESP_BASE.BillboardH))
b.StudsOffset = Vector3.new(0, ESP_BASE.StudsOffsetY * OrbConfig.ESPUIScale, 0)
if tierTag then
tierTag.Size = UDim2.new(1, -pxOrb(8), 0, pxOrb(11))
tierTag.Position = UDim2.new(0, pxOrb(4), 0, pxOrb(1))
tierTag.TextSize = pxOrb(ESP_BASE.TierText)
end
rlbl.Size = UDim2.new(1, -pxOrb(8), 0, pxOrb(22))
rlbl.Position = UDim2.new(0, pxOrb(4), 0, pxOrb(12))
rlbl.TextSize = pxOrb(ESP_BASE.RarityText)
dlbl.Size = UDim2.new(1, -pxOrb(8), 0, pxOrb(15))
dlbl.Position = UDim2.new(0, pxOrb(4), 0, pxOrb(34))
dlbl.TextSize = pxOrb(ESP_BASE.DistText)
if cornerBg then
cornerBg.CornerRadius = UDim.new(0, math.max(2, pxOrb(ESP_BASE.Corner)))
end
if bgStroke then
bgStroke.Thickness = math.max(1, ESP_BASE.Stroke * OrbConfig.ESPUIScale)
end
if dlbl then
dlbl.Visible = EspVisual.ShowStuds
end
end
local function isOrbVisible(rarity)
if OrbConfig.Filter.All then
return true
end
return OrbConfig.Filter[rarity] == true
end
local function createOrbESP(part)
if not OrbConfig.Enabled then
return
end
if OrbESPObjects[part] then
return
end
local rarity = getOrbRarity(part)
local rd = RarityMap[rarity] or { color = Color3.fromRGB(255, 255, 255), icon = "🔮" }
local billboard = Instance.new("BillboardGui")
billboard.Name = "CacheESP"
billboard.AlwaysOnTop = true
billboard.MaxDistance = 0
billboard.Enabled = false
local bg = Instance.new("Frame", billboard)
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
bg.BackgroundTransparency = 0.35
bg.BorderSizePixel = 0
Instance.new("UICorner", bg)
local bgStroke = Instance.new("UIStroke", bg)
bgStroke.Color = rd.color
local tierTag = Instance.new("TextLabel", bg)
tierTag.Name = "TierTag"
tierTag.BackgroundTransparency = 1
tierTag.Text = "CACHE"
tierTag.TextColor3 = Color3.fromRGB(120, 118, 145)
tierTag.Font = Enum.Font.GothamBold
tierTag.TextXAlignment = Enum.TextXAlignment.Center
local rarityLbl = Instance.new("TextLabel", bg)
rarityLbl.BackgroundTransparency = 1
rarityLbl.Text = rd.icon .. "  " .. string.upper(rarity)
rarityLbl.TextColor3 = rd.color
rarityLbl.Font = Enum.Font.GothamBold
rarityLbl.TextStrokeTransparency = 0.4
rarityLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
rarityLbl.TextXAlignment = Enum.TextXAlignment.Center
local distLabel = Instance.new("TextLabel", bg)
distLabel.BackgroundTransparency = 1
distLabel.Text = "? studs"
distLabel.TextColor3 = Color3.fromRGB(210, 210, 210)
distLabel.Font = Enum.Font.Gotham
distLabel.TextStrokeTransparency = 0.4
distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
distLabel.TextXAlignment = Enum.TextXAlignment.Center
billboard.Adornee = part
billboard.Parent = part
local hi = Instance.new("Highlight")
hi.Name = "CacheESP_HL"
hi.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
hi.FillColor = rd.color
hi.OutlineColor = rd.color:Lerp(Color3.new(1, 1, 1), 0.2)
hi.Enabled = false
hi.Parent = part
applyHighlightProps(hi)
local pos = part.Position
local data = {
billboard = billboard,
tierTag = tierTag,
distLabel = distLabel,
rarityLbl = rarityLbl,
rarity = rarity,
cachedCenter = pos,
lastDistStuds = nil,
adorneePart = part,
highlight = hi,
beam = nil,
beamAtt1 = nil,
}
OrbESPObjects[part] = data
applyOrbESPVisual(data)
end
local function removeOrbESP(part)
local data = OrbESPObjects[part]
if data then
disableCacheEspData(data)
OrbESPObjects[part] = nil
end
if part.Parent then
sweepLeftoverCacheEspOnPart(part)
end
end
local function clearAllOrbESP()
for part in pairs(OrbESPObjects) do
removeOrbESP(part)
end
end
local cacheEspRunId = 0
local function disableCacheEspData(data)
if not data then
return
end
if data.billboard then
data.billboard.Enabled = false
if data.billboard.Parent then
data.billboard:Destroy()
end
data.billboard = nil
end
if data.highlight then
data.highlight.Enabled = false
if data.highlight.Parent then
data.highlight:Destroy()
end
data.highlight = nil
end
if data.beam then
data.beam.Enabled = false
if data.beam.Parent then
data.beam:Destroy()
end
data.beam = nil
end
if data.beamAtt1 then
if data.beamAtt1.Parent then
data.beamAtt1:Destroy()
end
data.beamAtt1 = nil
end
end
local function isCacheOrbBeamTarget(p)
if not p:IsA("BasePart") then
return false
end
local par = p.Parent
if par == workspace then
return true
end
return false
end
local function purgeOrphanCacheBeams()
local char = Players.LocalPlayer.Character
local hrp = char and char:FindFirstChild("HumanoidRootPart")
if not hrp then
return
end
for _, child in ipairs(hrp:GetChildren()) do
if child:IsA("Beam") and child.Name == "ESPBeam" then
local att1 = child.Attachment1
local endPart = att1 and att1.Parent
if endPart and isCacheOrbBeamTarget(endPart) then
child:Destroy()
if att1 and att1.Parent then
att1:Destroy()
end
end
end
end
end
local function sweepLeftoverCacheEspOnPart(p)
for _, name in ipairs({ "CacheESP", "OrbESP" }) do
local ch = p:FindFirstChild(name)
if ch and ch:IsA("BillboardGui") then
ch.Enabled = false
ch:Destroy()
end
end
for _, name in ipairs({ "CacheESP_HL", "OrbESP_HL" }) do
local ch = p:FindFirstChild(name)
if ch and ch:IsA("Highlight") then
ch.Enabled = false
ch:Destroy()
end
end
local att = p:FindFirstChild("ESPBeamEnd")
if att and att:IsA("Attachment") then
att:Destroy()
end
end
local function sweepWorkspaceCacheEsp()
for _, ch in ipairs(workspace:GetChildren()) do
if ch:IsA("BasePart") then
sweepLeftoverCacheEspOnPart(ch)
end
end
purgeOrphanCacheBeams()
end
local function shutdownCacheEsp()
cacheEspRunId = cacheEspRunId + 1
orbEspResumeAt = 0
orbUpdating = false
for _, data in pairs(OrbESPObjects) do
disableCacheEspData(data)
end
for k in pairs(OrbESPObjects) do
OrbESPObjects[k] = nil
end
sweepWorkspaceCacheEsp()
end
local function refreshAllOrbESPVisuals()
for _, data in pairs(OrbESPObjects) do
applyOrbESPVisual(data)
end
end
local function purgeBeamData(data)
if data.beam then
data.beam:Destroy()
data.beam = nil
end
if data.beamAtt1 then
data.beamAtt1:Destroy()
data.beamAtt1 = nil
end
end
local function purgeAllBeams()
for _, data in pairs(ESPObjects) do
purgeBeamData(data)
end
for _, data in pairs(OrbESPObjects) do
purgeBeamData(data)
end
end
local function getHrpLineOrigin(hrp)
local a = hrp:FindFirstChild("ESPLineOrigin")
if not a then
a = Instance.new("Attachment")
a.Name = "ESPLineOrigin"
a.Position = Vector3.new(0, 1.15, 0)
a.Parent = hrp
end
return a
end
local function purgeWorldEspVfx(data)
purgeBeamData(data)
if data.highlight then
data.highlight:Destroy()
data.highlight = nil
end
end
local function applyBeamProps(beam)
if not beam then
return
end
beam.Width0 = EspVisual.TracerWidth0
beam.Width1 = EspVisual.TracerWidth1
local t = math.clamp(EspVisual.TracerTransparency, 0, 0.95)
beam.Transparency = NumberSequence.new(t)
end
local function refreshAllWorldVfxStyle()
for _, data in pairs(ESPObjects) do
applyHighlightProps(data.highlight)
applyBeamProps(data.beam)
end
for _, data in pairs(OrbESPObjects) do
applyHighlightProps(data.highlight)
applyBeamProps(data.beam)
end
end
local function refreshAllDistLabelVis()
for _, data in pairs(ESPObjects) do
if data.distLabel then
data.distLabel.Visible = EspVisual.ShowStuds
end
end
for _, data in pairs(OrbESPObjects) do
if data.distLabel then
data.distLabel.Visible = EspVisual.ShowStuds
end
end
end
local function setAccentFromRarity(data, color)
if data.highlight then
data.highlight.FillColor = color
data.highlight.OutlineColor = color:Lerp(Color3.new(1, 1, 1), 0.22)
end
if data.beam and data.beam.Parent then
local c0 = color:Lerp(Color3.new(1, 1, 1), 0.1)
data.beam.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, c0),
ColorSequenceKeypoint.new(1, color),
})
end
end
local function ensureBeam(data, hrp, endPart, color)
if not EspVisual.ShowTracer then
return
end
if not endPart or not endPart:IsDescendantOf(workspace) then
return
end
if data.beam then
local b = data.beam
local att0ok = b.Attachment0 and b.Attachment0.Parent == hrp
local att1ok = b.Attachment1 and b.Attachment1.Parent == endPart
local parentOk = b.Parent == hrp
if not (parentOk and att0ok and att1ok) then
purgeBeamData(data)
end
end
if not data.beam or not data.beam.Parent then
local att1 = Instance.new("Attachment")
att1.Name = "ESPBeamEnd"
att1.Position = Vector3.new(0, 0.35, 0)
att1.Parent = endPart
local beam = Instance.new("Beam")
beam.Name = "ESPBeam"
beam.Attachment0 = getHrpLineOrigin(hrp)
beam.Attachment1 = att1
beam.Parent = hrp
beam.FaceCamera = true
beam.LightEmission = 1
beam.Texture = ""
data.beam = beam
data.beamAtt1 = att1
end
setAccentFromRarity(data, color)
applyBeamProps(data.beam)
data.beam.Enabled = true
end
local function setWorldEspVfxActive(data, active)
if data.highlight then
data.highlight.Enabled = active and EspVisual.ShowHighlight
end
if data.beam then
data.beam.Enabled = active
and EspVisual.ShowTracer
and (data.beamAtt1 ~= nil)
and (data.beamAtt1.Parent ~= nil)
end
end
Players.LocalPlayer.CharacterAdded:Connect(function()
task.defer(purgeAllBeams)
end)
local function createESP(model)
if ESPObjects[model] then
return
end
local rarity = getBagRarity(model)
local rd = RarityMap[rarity] or { color = Color3.fromRGB(255, 255, 255), icon = "🎒" }
local billboard = Instance.new("BillboardGui")
billboard.Name = "BagESP"
billboard.AlwaysOnTop = true
billboard.MaxDistance = 0
billboard.Enabled = false
local bg = Instance.new("Frame", billboard)
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
bg.BackgroundTransparency = 0.35
bg.BorderSizePixel = 0
Instance.new("UICorner", bg)
local bgStroke = Instance.new("UIStroke", bg)
bgStroke.Color = rd.color
local tierTag = Instance.new("TextLabel", bg)
tierTag.Name = "TierTag"
tierTag.BackgroundTransparency = 1
tierTag.Text = "BAG"
tierTag.TextColor3 = Color3.fromRGB(120, 118, 145)
tierTag.Font = Enum.Font.GothamBold
tierTag.TextXAlignment = Enum.TextXAlignment.Center
local rarityLbl = Instance.new("TextLabel", bg)
rarityLbl.BackgroundTransparency = 1
rarityLbl.Text = rd.icon .. "  " .. string.upper(rarity)
rarityLbl.TextColor3 = rd.color
rarityLbl.Font = Enum.Font.GothamBold
rarityLbl.TextStrokeTransparency = 0.4
rarityLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
rarityLbl.TextXAlignment = Enum.TextXAlignment.Center
local distLabel = Instance.new("TextLabel", bg)
distLabel.BackgroundTransparency = 1
distLabel.Text = "? studs"
distLabel.TextColor3 = Color3.fromRGB(210, 210, 210)
distLabel.Font = Enum.Font.Gotham
distLabel.TextStrokeTransparency = 0.4
distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
distLabel.TextXAlignment = Enum.TextXAlignment.Center
local main = model:FindFirstChild("Main")
local adornee = (main and main:IsA("BasePart")) and main or model.PrimaryPart
if not adornee then
adornee = model:FindFirstChildWhichIsA("BasePart")
end
billboard.Adornee = adornee
billboard.Parent = adornee
local hi = Instance.new("Highlight")
hi.Name = "BagESP_HL"
hi.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
hi.FillColor = rd.color
hi.OutlineColor = rd.color:Lerp(Color3.new(1, 1, 1), 0.2)
hi.Enabled = false
hi.Parent = model
applyHighlightProps(hi)
local center = getModelCenter(model)
local data = {
billboard = billboard,
tierTag = tierTag,
distLabel = distLabel,
rarityLbl = rarityLbl,
rarity = rarity,
cachedCenter = center,
lastDistStuds = nil,
adorneePart = adornee,
highlight = hi,
beam = nil,
beamAtt1 = nil,
}
ESPObjects[model] = data
insideBuilding[model] = false
applyESPVisual(data)
end
local function removeESP(model)
local data = ESPObjects[model]
if data then
purgeWorldEspVfx(data)
data.billboard:Destroy()
ESPObjects[model] = nil
insideBuilding[model] = nil
end
end
local function clearAllESP()
for model in pairs(ESPObjects) do
removeESP(model)
end
end
local function refreshAllESPVisuals()
for _, data in pairs(ESPObjects) do
applyESPVisual(data)
end
end
local lastUpdate = 0
local bagEspResumeAt = 0
local updating = false
local timerLabel
local function heavyUpdate()
if updating then
return
end
updating = true
local currentBags = {}
for _, bag in ipairs(findBags()) do
currentBags[bag] = true
createESP(bag)
end
for model, data in pairs(ESPObjects) do
if currentBags[model] then
local c = getModelCenter(model)
if c then
data.cachedCenter = c
end
local newR = getBagRarity(model)
if newR ~= data.rarity then
data.rarity = newR
local rd = RarityMap[newR] or { color = Color3.fromRGB(255, 255, 255), icon = "🎒" }
data.rarityLbl.Text = rd.icon .. "  " .. string.upper(newR)
data.rarityLbl.TextColor3 = rd.color
local bgStroke = data.rarityLbl.Parent:FindFirstChildOfClass("UIStroke")
if bgStroke then
bgStroke.Color = rd.color
end
setAccentFromRarity(data, rd.color)
end
end
end
local toRemove = {}
for model in pairs(ESPObjects) do
if not currentBags[model] then
table.insert(toRemove, model)
end
end
for _, model in ipairs(toRemove) do
removeESP(model)
end
updating = false
end
local lastOrbUpdate = 0
local orbEspResumeAt = 0
local orbUpdating = false
local function orbHeavyUpdate(expectedRunId)
if expectedRunId and cacheEspRunId ~= expectedRunId then
return
end
if not OrbConfig.Enabled then
return
end
if orbUpdating then
return
end
orbUpdating = true
local ok, err = pcall(function()
if not OrbConfig.Enabled or (expectedRunId and cacheEspRunId ~= expectedRunId) then
return
end
local current = {}
for _, orb in ipairs(findOrbs()) do
if not OrbConfig.Enabled or (expectedRunId and cacheEspRunId ~= expectedRunId) then
return
end
current[orb] = true
createOrbESP(orb)
end
for part, data in pairs(OrbESPObjects) do
if not OrbConfig.Enabled or (expectedRunId and cacheEspRunId ~= expectedRunId) then
return
end
if current[part] and data and part.Parent then
data.cachedCenter = part.Position
local newR = getOrbRarity(part)
if newR ~= data.rarity then
data.rarity = newR
local rd = RarityMap[newR] or { color = Color3.fromRGB(255, 255, 255), icon = "🔮" }
data.rarityLbl.Text = rd.icon .. "  " .. string.upper(newR)
data.rarityLbl.TextColor3 = rd.color
local bgStroke = data.rarityLbl.Parent:FindFirstChildOfClass("UIStroke")
if bgStroke then
bgStroke.Color = rd.color
end
setAccentFromRarity(data, rd.color)
end
end
end
local toRemove = {}
for part in pairs(OrbESPObjects) do
if not current[part] then
table.insert(toRemove, part)
end
end
for _, p in ipairs(toRemove) do
removeOrbESP(p)
end
end)
if not ok then
warn("[BagESP] orbHeavyUpdate: ", err)
end
orbUpdating = false
end
RunService.RenderStepped:Connect(function()
local now = tick()
if Config.Enabled and now >= bagEspResumeAt and now - lastUpdate >= Config.UpdateRate then
lastUpdate = now
task.spawn(heavyUpdate)
end
if OrbConfig.Enabled and now >= orbEspResumeAt and now - lastOrbUpdate >= OrbConfig.UpdateRate then
lastOrbUpdate = now
task.spawn(function()
orbHeavyUpdate(cacheEspRunId)
end)
end
local br = getActiveBuildingCheckPeriod()
if br and Config.Enabled and now >= bagEspResumeAt and not buildingUpdating and lastBuildingCheckFinishedAt ~= nil and (now - lastBuildingCheckFinishedAt >= br) then
runBuildingCheck()
end
if timerLabel and Config.Enabled then
local period = br or Config.BuildingCheckRate
local function styleTimer(lbl)
if not lbl then
return
end
if buildingUpdating then
lbl.Text = "🏠 Refreshing…"
lbl.TextColor3 = Color3.fromRGB(255, 220, 80)
elseif lastBuildingCheckFinishedAt == nil then
lbl.Text = "🏠 Waiting for first refresh…"
lbl.TextColor3 = Color3.fromRGB(160, 180, 220)
else
local elapsed = now - lastBuildingCheckFinishedAt
local remaining = math.max(0, math.ceil(period - elapsed))
local m = math.floor(remaining / 60)
local s = remaining % 60
local timeStr = m > 0 and (m .. "m " .. s .. "s") or (s .. "s")
lbl.Text = "🏠 Next refresh in: " .. timeStr
lbl.TextColor3 = remaining <= 10 and Color3.fromRGB(255, 150, 80)
or Color3.fromRGB(80, 200, 120)
end
end
styleTimer(timerLabel)
end
if not Config.Enabled and not OrbConfig.Enabled then
return
end
local char = Players.LocalPlayer.Character
local hrp = char and char:FindFirstChild("HumanoidRootPart")
local cam = workspace.CurrentCamera
local originPos = (hrp and hrp.Position) or (cam and cam.CFrame.Position)
if not originPos then
return
end
if Config.Enabled then
for model, data in pairs(ESPObjects) do
local center = data.cachedCenter or getModelCenter(model)
if center then
local dist = math.floor((originPos - center).Magnitude)
local show = dist <= Config.MaxDistance
and isVisible(data.rarity)
and not insideBuilding[model]
and center.Y >= -6.2
local rd = RarityMap[data.rarity] or Rarities[1]
data.billboard.Enabled = show and EspVisual.ShowLabels
if show then
if EspVisual.ShowStuds then
if data.lastDistStuds ~= dist then
data.lastDistStuds = dist
data.distLabel.Text = dist .. " studs"
end
else
data.lastDistStuds = dist
end
setWorldEspVfxActive(data, true)
if hrp then
ensureBeam(data, hrp, data.adorneePart, rd.color)
end
else
setWorldEspVfxActive(data, false)
end
else
data.billboard.Enabled = false
setWorldEspVfxActive(data, false)
end
end
end
if OrbConfig.Enabled then
for part, data in pairs(OrbESPObjects) do
local center = data.cachedCenter or (part.Parent and part.Position)
if center and part.Parent then
local dist = math.floor((originPos - center).Magnitude)
local show = dist <= OrbConfig.MaxDistance
and isOrbVisible(data.rarity)
local rd = RarityMap[data.rarity] or Rarities[1]
data.billboard.Enabled = show and EspVisual.ShowLabels
if show then
if EspVisual.ShowStuds then
if data.lastDistStuds ~= dist then
data.lastDistStuds = dist
data.distLabel.Text = dist .. " studs"
end
else
data.lastDistStuds = dist
end
setWorldEspVfxActive(data, true)
if hrp then
ensureBeam(data, hrp, data.adorneePart, rd.color)
end
else
setWorldEspVfxActive(data, false)
end
else
data.billboard.Enabled = false
setWorldEspVfxActive(data, false)
end
end
end
end)
local PANEL_W = 210
local DIVIDER_W = 3
local sepY = 190
local filterHeaderY = 194
local FY = 212
local PANEL_BODY_H = FY + 180 + 36
local PREVIEW_H = 316
local SHELL_H = PANEL_BODY_H + PREVIEW_H
local SHELL_W = PANEL_W * 2 + DIVIDER_W
local refreshEspPreview = function() end
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BagESP_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = PlayerGui
local Shell = Instance.new("Frame")
Shell.Name = "ESPMenuShell"
Shell.Size = UDim2.new(0, SHELL_W, 0, SHELL_H)
Shell.Position = UDim2.new(1, -SHELL_W - 20, 0, 20)
Shell.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Shell.BorderSizePixel = 0
Shell.Active = true
Shell.Draggable = true
Shell.Parent = ScreenGui
Instance.new("UICorner", Shell).CornerRadius = UDim.new(0, 10)
local shellStroke = Instance.new("UIStroke", Shell)
shellStroke.Color = Color3.fromRGB(0, 200, 255)
shellStroke.Thickness = 1
local bagPanel = Instance.new("Frame")
bagPanel.Name = "BagPanel"
bagPanel.Size = UDim2.new(0, PANEL_W, 0, PANEL_BODY_H)
bagPanel.Position = UDim2.new(0, 0, 0, 0)
bagPanel.BackgroundTransparency = 1
bagPanel.BorderSizePixel = 0
bagPanel.Parent = Shell
local vDivider = Instance.new("Frame", Shell)
vDivider.Name = "Divider"
vDivider.Size = UDim2.new(0, DIVIDER_W, 0, PANEL_BODY_H - 20)
vDivider.Position = UDim2.new(0, PANEL_W, 0, 10)
vDivider.BackgroundColor3 = Color3.fromRGB(40, 48, 62)
vDivider.BorderSizePixel = 0
Instance.new("UICorner", vDivider).CornerRadius = UDim.new(1, 0)
local orbPanel = Instance.new("Frame")
orbPanel.Name = "OrbPanel"
orbPanel.Size = UDim2.new(0, PANEL_W, 0, PANEL_BODY_H)
orbPanel.Position = UDim2.new(0, PANEL_W + DIVIDER_W, 0, 0)
orbPanel.BackgroundTransparency = 1
orbPanel.BorderSizePixel = 0
orbPanel.Parent = Shell
local function updateShellAccent()
if Config.Enabled and OrbConfig.Enabled then
shellStroke.Color = Color3.fromRGB(80, 235, 170)
elseif Config.Enabled then
shellStroke.Color = Color3.fromRGB(0, 255, 120)
elseif OrbConfig.Enabled then
shellStroke.Color = Color3.fromRGB(170, 140, 255)
else
shellStroke.Color = Color3.fromRGB(0, 200, 255)
end
end
local titleBar = Instance.new("Frame", bagPanel)
titleBar.Size = UDim2.new(1, 0, 0, 32)
titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
titleBar.BorderSizePixel = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)
local titleFix = Instance.new("Frame", titleBar)
titleFix.Size = UDim2.new(1, 0, 0.5, 0)
titleFix.Position = UDim2.new(0, 0, 0.5, 0)
titleFix.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
titleFix.BorderSizePixel = 0
local titleLbl = Instance.new("TextLabel", titleBar)
titleLbl.Size = UDim2.new(1, 0, 1, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "👜  BAG ESP"
titleLbl.TextColor3 = Color3.fromRGB(0, 200, 255)
titleLbl.TextSize = 13
titleLbl.Font = Enum.Font.GothamBold
local toggleBtn = Instance.new("TextButton", bagPanel)
toggleBtn.Size = UDim2.new(1, -20, 0, 28)
toggleBtn.Position = UDim2.new(0, 10, 0, 40)
toggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
toggleBtn.Text = "ESP: OFF"
toggleBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
toggleBtn.TextSize = 13
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BorderSizePixel = 0
toggleBtn.AutoButtonColor = false
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 7)
local activeSlider = nil
local function makeSlider(parent, yPos, labelText, minVal, maxVal, defaultVal, isFloat, formatFn, onChange)
local lbl = Instance.new("TextLabel", parent)
lbl.Size = UDim2.new(1, -20, 0, 14)
lbl.Position = UDim2.new(0, 10, 0, yPos)
lbl.BackgroundTransparency = 1
lbl.TextColor3 = Color3.fromRGB(160, 160, 185)
lbl.TextSize = 11
lbl.Font = Enum.Font.Gotham
lbl.TextXAlignment = Enum.TextXAlignment.Left
local track = Instance.new("TextButton", parent)
track.Size = UDim2.new(1, -20, 0, 7)
track.Position = UDim2.new(0, 10, 0, yPos + 16)
track.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
track.Text = ""
track.AutoButtonColor = false
track.BorderSizePixel = 0
Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
local fill = Instance.new("Frame", track)
fill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
fill.BorderSizePixel = 0
fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
local function update(v)
fill.Size = UDim2.new(math.clamp((v - minVal) / (maxVal - minVal), 0, 1), 0, 1, 0)
lbl.Text = labelText .. ": " .. formatFn(v)
onChange(v)
end
update(defaultVal)
local function applyMouse()
local rel = math.clamp((Mouse.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
local v = minVal + rel * (maxVal - minVal)
if isFloat then
v = math.floor(v * 100 + 0.5) / 100
else
v = math.floor(v / 50 + 0.5) * 50
end
update(math.clamp(v, minVal, maxVal))
end
track.InputBegan:Connect(function(i)
if i.UserInputType == Enum.UserInputType.MouseButton1 then
activeSlider = applyMouse
applyMouse()
end
end)
end
UserInputService.InputChanged:Connect(function(i)
if i.UserInputType == Enum.UserInputType.MouseMovement and activeSlider then
activeSlider()
end
end)
UserInputService.InputEnded:Connect(function(i)
if i.UserInputType == Enum.UserInputType.MouseButton1 then
activeSlider = nil
end
end)
local function fmtNum(v)
if v >= 1000 then
return math.floor(v / 1000) .. "k"
end
return tostring(math.floor(v))
end
local function fmtTime(v)
local m = math.floor(v / 60)
local s = math.floor(v % 60)
if m > 0 then
return m .. "m " .. s .. "s"
end
return s .. "s"
end
local function fmtFloat(v)
return string.format("%.2f", v)
end
makeSlider(bagPanel, 76, "Distance (studs)", 50, 10000, Config.MaxDistance, false, fmtNum, function(v)
Config.MaxDistance = v
end)
makeSlider(bagPanel, 112, "ESP Size (scale)", 0.35, 3.0, Config.ESPUIScale, true, fmtFloat, function(v)
Config.ESPUIScale = v
refreshAllESPVisuals()
refreshEspPreview()
end)
makeSlider(bagPanel, 148, "Update Rate", 5, 300, Config.BuildingCheckRate, false, fmtTime, function(v)
Config.BuildingCheckRate = v
end)
timerLabel = Instance.new("TextLabel", bagPanel)
timerLabel.Size = UDim2.new(1, -20, 0, 16)
timerLabel.Position = UDim2.new(0, 10, 0, 176)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = "🏠 Next refresh: --"
timerLabel.TextColor3 = Color3.fromRGB(80, 200, 120)
timerLabel.TextSize = 11
timerLabel.Font = Enum.Font.Gotham
timerLabel.TextXAlignment = Enum.TextXAlignment.Left
local sep = Instance.new("Frame", bagPanel)
sep.Size = UDim2.new(1, -20, 0, 1)
sep.Position = UDim2.new(0, 10, 0, sepY)
sep.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
sep.BorderSizePixel = 0
local filterLbl = Instance.new("TextLabel", bagPanel)
filterLbl.Size = UDim2.new(1, -20, 0, 14)
filterLbl.Position = UDim2.new(0, 10, 0, filterHeaderY)
filterLbl.BackgroundTransparency = 1
filterLbl.Text = "RARITY FILTER"
filterLbl.TextColor3 = Color3.fromRGB(100, 100, 130)
filterLbl.TextSize = 10
filterLbl.Font = Enum.Font.GothamBold
filterLbl.TextXAlignment = Enum.TextXAlignment.Left
local filterButtons = {}
local function makeFilterBtn(parent, yPos, label, color, key)
local btn = Instance.new("TextButton", parent)
btn.Size = UDim2.new(1, -20, 0, 26)
btn.Position = UDim2.new(0, 10, 0, yPos)
btn.BorderSizePixel = 0
btn.AutoButtonColor = false
btn.Text = ""
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
local btnStroke = Instance.new("UIStroke", btn)
btnStroke.Thickness = 1
local lbl = Instance.new("TextLabel", btn)
lbl.Size = UDim2.new(1, -40, 1, 0)
lbl.Position = UDim2.new(0, 10, 0, 0)
lbl.BackgroundTransparency = 1
lbl.Text = label
lbl.TextSize = 12
lbl.Font = Enum.Font.GothamBold
lbl.TextXAlignment = Enum.TextXAlignment.Left
local dot = Instance.new("Frame", btn)
dot.Size = UDim2.new(0, 10, 0, 10)
dot.Position = UDim2.new(1, -18, 0.5, -5)
dot.BorderSizePixel = 0
Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
local function refresh(on)
if on then
btn.BackgroundColor3 = Color3.fromRGB(
math.clamp(math.floor(color.R * 255 * 0.18), 0, 255),
math.clamp(math.floor(color.G * 255 * 0.18), 0, 255),
math.clamp(math.floor(color.B * 255 * 0.18), 0, 255)
)
btnStroke.Color = color
lbl.TextColor3 = color
dot.BackgroundColor3 = color
else
btn.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
btnStroke.Color = Color3.fromRGB(50, 50, 65)
lbl.TextColor3 = Color3.fromRGB(90, 90, 110)
dot.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
end
end
refresh(Config.Filter[key] ~= false)
filterButtons[key] = refresh
btn.MouseButton1Click:Connect(function()
if key == "All" then
local newState = not Config.Filter.All
Config.Filter.All = newState
for _, r in ipairs(Rarities) do
Config.Filter[r.name] = newState
if filterButtons[r.name] then
filterButtons[r.name](newState)
end
end
refresh(newState)
else
Config.Filter.All = false
if filterButtons["All"] then
filterButtons["All"](false)
end
Config.Filter[key] = not Config.Filter[key]
refresh(Config.Filter[key])
end
end)
end
makeFilterBtn(bagPanel, FY, "⬛ ALL", Color3.fromRGB(200, 200, 200), "All")
makeFilterBtn(bagPanel, FY + 30, "⬜ Common", Rarities[1].color, "Common")
makeFilterBtn(bagPanel, FY + 60, "🟩 Uncommon", Rarities[2].color, "Uncommon")
makeFilterBtn(bagPanel, FY + 90, "🟦 Rare", Rarities[3].color, "Rare")
makeFilterBtn(bagPanel, FY + 120, "🟪 Epic", Rarities[4].color, "Epic")
makeFilterBtn(bagPanel, FY + 150, "🟨 Legendary", Rarities[5].color, "Legendary")
makeFilterBtn(bagPanel, FY + 180, "🟥 Ultimate", Rarities[6].color, "Ultimate")
local orbTitleBar = Instance.new("Frame", orbPanel)
orbTitleBar.Size = UDim2.new(1, 0, 0, 32)
orbTitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
orbTitleBar.BorderSizePixel = 0
Instance.new("UICorner", orbTitleBar).CornerRadius = UDim.new(0, 10)
local orbTitleFix = Instance.new("Frame", orbTitleBar)
orbTitleFix.Size = UDim2.new(1, 0, 0.5, 0)
orbTitleFix.Position = UDim2.new(0, 0, 0.5, 0)
orbTitleFix.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
orbTitleFix.BorderSizePixel = 0
local orbTitleLbl = Instance.new("TextLabel", orbTitleBar)
orbTitleLbl.Size = UDim2.new(1, 0, 1, 0)
orbTitleLbl.BackgroundTransparency = 1
orbTitleLbl.Text = "📦  CACHE ESP"
orbTitleLbl.TextColor3 = Color3.fromRGB(188, 160, 255)
orbTitleLbl.TextSize = 13
orbTitleLbl.Font = Enum.Font.GothamBold
local orbToggleBtn = Instance.new("TextButton", orbPanel)
orbToggleBtn.Size = UDim2.new(1, -20, 0, 28)
orbToggleBtn.Position = UDim2.new(0, 10, 0, 40)
orbToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
orbToggleBtn.Text = "CACHE: OFF"
orbToggleBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
orbToggleBtn.TextSize = 13
orbToggleBtn.Font = Enum.Font.GothamBold
orbToggleBtn.BorderSizePixel = 0
orbToggleBtn.AutoButtonColor = false
Instance.new("UICorner", orbToggleBtn).CornerRadius = UDim.new(0, 7)
makeSlider(orbPanel, 76, "Distance (studs)", 50, 10000, OrbConfig.MaxDistance, false, fmtNum, function(v)
OrbConfig.MaxDistance = v
end)
makeSlider(orbPanel, 112, "Update Rate (sec)", 0.1, 10.0, OrbConfig.UpdateRate, true, fmtFloat, function(v)
OrbConfig.UpdateRate = v
end)
makeSlider(orbPanel, 148, "ESP Size (scale)", 0.35, 3.0, OrbConfig.ESPUIScale, true, fmtFloat, function(v)
OrbConfig.ESPUIScale = v
refreshAllOrbESPVisuals()
refreshEspPreview()
end)
local orbNoBuildingHint = Instance.new("TextLabel", orbPanel)
orbNoBuildingHint.Size = UDim2.new(1, -20, 0, 32)
orbNoBuildingHint.Position = UDim2.new(0, 10, 0, 176)
orbNoBuildingHint.BackgroundTransparency = 1
orbNoBuildingHint.Text = "Cache items are not hidden inside buildings (bags only)."
orbNoBuildingHint.TextColor3 = Color3.fromRGB(120, 115, 150)
orbNoBuildingHint.TextSize = 10
orbNoBuildingHint.Font = Enum.Font.Gotham
orbNoBuildingHint.TextXAlignment = Enum.TextXAlignment.Left
orbNoBuildingHint.TextYAlignment = Enum.TextYAlignment.Top
orbNoBuildingHint.TextWrapped = true
local orbSep = Instance.new("Frame", orbPanel)
orbSep.Size = UDim2.new(1, -20, 0, 1)
orbSep.Position = UDim2.new(0, 10, 0, sepY)
orbSep.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
orbSep.BorderSizePixel = 0
local orbFilterLbl = Instance.new("TextLabel", orbPanel)
orbFilterLbl.Size = UDim2.new(1, -20, 0, 14)
orbFilterLbl.Position = UDim2.new(0, 10, 0, filterHeaderY)
orbFilterLbl.BackgroundTransparency = 1
orbFilterLbl.Text = "RARITY FILTER"
orbFilterLbl.TextColor3 = Color3.fromRGB(100, 100, 130)
orbFilterLbl.TextSize = 10
orbFilterLbl.Font = Enum.Font.GothamBold
orbFilterLbl.TextXAlignment = Enum.TextXAlignment.Left
local orbFilterButtons = {}
local function makeOrbFilterBtn(parent, yPos, label, color, key)
local btn = Instance.new("TextButton", parent)
btn.Size = UDim2.new(1, -20, 0, 26)
btn.Position = UDim2.new(0, 10, 0, yPos)
btn.BorderSizePixel = 0
btn.AutoButtonColor = false
btn.Text = ""
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
local btnStroke = Instance.new("UIStroke", btn)
btnStroke.Thickness = 1
local lbl = Instance.new("TextLabel", btn)
lbl.Size = UDim2.new(1, -40, 1, 0)
lbl.Position = UDim2.new(0, 10, 0, 0)
lbl.BackgroundTransparency = 1
lbl.Text = label
lbl.TextSize = 12
lbl.Font = Enum.Font.GothamBold
lbl.TextXAlignment = Enum.TextXAlignment.Left
local dot = Instance.new("Frame", btn)
dot.Size = UDim2.new(0, 10, 0, 10)
dot.Position = UDim2.new(1, -18, 0.5, -5)
dot.BorderSizePixel = 0
Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
local function refresh(on)
if on then
btn.BackgroundColor3 = Color3.fromRGB(
math.clamp(math.floor(color.R * 255 * 0.18), 0, 255),
math.clamp(math.floor(color.G * 255 * 0.18), 0, 255),
math.clamp(math.floor(color.B * 255 * 0.18), 0, 255)
)
btnStroke.Color = color
lbl.TextColor3 = color
dot.BackgroundColor3 = color
else
btn.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
btnStroke.Color = Color3.fromRGB(50, 50, 65)
lbl.TextColor3 = Color3.fromRGB(90, 90, 110)
dot.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
end
end
refresh(OrbConfig.Filter[key] ~= false)
orbFilterButtons[key] = refresh
btn.MouseButton1Click:Connect(function()
if key == "All" then
local newState = not OrbConfig.Filter.All
OrbConfig.Filter.All = newState
for _, r in ipairs(Rarities) do
OrbConfig.Filter[r.name] = newState
if orbFilterButtons[r.name] then
orbFilterButtons[r.name](newState)
end
end
refresh(newState)
else
OrbConfig.Filter.All = false
if orbFilterButtons["All"] then
orbFilterButtons["All"](false)
end
OrbConfig.Filter[key] = not OrbConfig.Filter[key]
refresh(OrbConfig.Filter[key])
end
end)
end
makeOrbFilterBtn(orbPanel, FY, "⬛ ALL", Color3.fromRGB(200, 200, 200), "All")
makeOrbFilterBtn(orbPanel, FY + 30, "⬜ Common", Rarities[1].color, "Common")
makeOrbFilterBtn(orbPanel, FY + 60, "🟩 Uncommon", Rarities[2].color, "Uncommon")
makeOrbFilterBtn(orbPanel, FY + 90, "🟦 Rare", Rarities[3].color, "Rare")
makeOrbFilterBtn(orbPanel, FY + 120, "🟪 Epic", Rarities[4].color, "Epic")
makeOrbFilterBtn(orbPanel, FY + 150, "🟨 Legendary", Rarities[5].color, "Legendary")
makeOrbFilterBtn(orbPanel, FY + 180, "🟥 Ultimate", Rarities[6].color, "Ultimate")
local previewRarityName = "Epic"
local previewChipButtons = {}
local previewPanel = Instance.new("Frame", Shell)
previewPanel.Name = "ESPPreview"
previewPanel.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
previewPanel.BorderSizePixel = 0
previewPanel.Size = UDim2.new(1, -16, 0, PREVIEW_H - 10)
previewPanel.Position = UDim2.new(0, 8, 0, PANEL_BODY_H + 4)
Instance.new("UICorner", previewPanel).CornerRadius = UDim.new(0, 9)
local previewStroke = Instance.new("UIStroke", previewPanel)
previewStroke.Color = Color3.fromRGB(55, 58, 78)
previewStroke.Thickness = 1
local prevTitle = Instance.new("TextLabel", previewPanel)
prevTitle.Size = UDim2.new(1, -12, 0, 16)
prevTitle.Position = UDim2.new(0, 6, 0, 4)
prevTitle.BackgroundTransparency = 1
prevTitle.Font = Enum.Font.GothamBold
prevTitle.TextSize = 11
prevTitle.TextColor3 = Color3.fromRGB(155, 160, 195)
prevTitle.TextXAlignment = Enum.TextXAlignment.Left
prevTitle.Text = "ESP PREVIEW — rarity, beam, highlight, text, studs"
local chipHolder = Instance.new("Frame", previewPanel)
chipHolder.BackgroundTransparency = 1
chipHolder.Size = UDim2.new(1, -12, 0, 22)
chipHolder.Position = UDim2.new(0, 6, 0, 22)
local chipLayout = Instance.new("UIListLayout", chipHolder)
chipLayout.FillDirection = Enum.FillDirection.Horizontal
chipLayout.Padding = UDim.new(0, 4)
chipLayout.SortOrder = Enum.SortOrder.LayoutOrder
for i, r in ipairs(Rarities) do
local chip = Instance.new("TextButton", chipHolder)
chip.LayoutOrder = i
chip.Size = UDim2.new(0, 54, 0, 18)
chip.AutoButtonColor = false
chip.BorderSizePixel = 0
chip.TextSize = 8
chip.Font = Enum.Font.GothamBold
chip.Text = string.upper(r.name)
Instance.new("UICorner", chip).CornerRadius = UDim.new(0, 4)
previewChipButtons[r.name] = chip
chip.MouseButton1Click:Connect(function()
previewRarityName = r.name
refreshEspPreview()
end)
end
local toggleRow = Instance.new("Frame", previewPanel)
toggleRow.BackgroundTransparency = 1
toggleRow.Position = UDim2.new(0, 6, 0, 46)
toggleRow.Size = UDim2.new(1, -12, 0, 22)
local function styleOnOffBtn(btn, on)
btn.BackgroundColor3 = on and Color3.fromRGB(40, 95, 70) or Color3.fromRGB(38, 38, 52)
btn.TextColor3 = on and Color3.fromRGB(220, 255, 235) or Color3.fromRGB(140, 140, 165)
end
local function makeVisToggle(parent, x, w, label, get, set, onAfter)
local btn = Instance.new("TextButton", parent)
btn.Size = UDim2.new(0, w, 0, 20)
btn.Position = UDim2.new(0, x, 0, 1)
btn.BorderSizePixel = 0
btn.AutoButtonColor = false
btn.Font = Enum.Font.GothamBold
btn.TextSize = 9
btn.TextWrapped = true
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
local function sync()
btn.Text = label .. (get() and ": ON" or ": OFF")
styleOnOffBtn(btn, get())
end
sync()
btn.MouseButton1Click:Connect(function()
set(not get())
sync()
if onAfter then
onAfter()
end
refreshEspPreview()
end)
return sync
end
local studsRow = Instance.new("Frame", previewPanel)
studsRow.BackgroundTransparency = 1
studsRow.Position = UDim2.new(0, 6, 0, 70)
studsRow.Size = UDim2.new(1, -12, 0, 22)
local tracerOpts = Instance.new("Frame", previewPanel)
tracerOpts.BackgroundTransparency = 1
tracerOpts.Position = UDim2.new(0, 6, 0, 94)
tracerOpts.Size = UDim2.new(1, -12, 0, 68)
makeSlider(tracerOpts, 4, "Beam width A", 0.04, 0.45, EspVisual.TracerWidth0, true, fmtFloat, function(v)
EspVisual.TracerWidth0 = v
refreshAllWorldVfxStyle()
refreshEspPreview()
end)
makeSlider(tracerOpts, 26, "Beam width B", 0.02, 0.22, EspVisual.TracerWidth1, true, fmtFloat, function(v)
EspVisual.TracerWidth1 = v
refreshAllWorldVfxStyle()
refreshEspPreview()
end)
makeSlider(tracerOpts, 48, "Beam transparency", 0, 0.92, EspVisual.TracerTransparency, true, fmtFloat, function(v)
EspVisual.TracerTransparency = v
refreshAllWorldVfxStyle()
refreshEspPreview()
end)
local hlOpts = Instance.new("Frame", previewPanel)
hlOpts.BackgroundTransparency = 1
hlOpts.Position = UDim2.new(0, 6, 0, 162)
hlOpts.Size = UDim2.new(1, -12, 0, 52)
makeSlider(hlOpts, 4, "HL fill", 0.5, 0.98, EspVisual.HlFillTransparency, true, fmtFloat, function(v)
EspVisual.HlFillTransparency = v
refreshAllWorldVfxStyle()
refreshEspPreview()
end)
makeSlider(hlOpts, 26, "HL outline", 0.05, 0.95, EspVisual.HlOutlineTransparency, true, fmtFloat, function(v)
EspVisual.HlOutlineTransparency = v
refreshAllWorldVfxStyle()
refreshEspPreview()
end)
local function layoutPreviewOptionVisibility()
tracerOpts.Visible = EspVisual.ShowTracer
hlOpts.Visible = EspVisual.ShowHighlight
end
makeVisToggle(toggleRow, 0, 62, "Beam", function()
return EspVisual.ShowTracer
end, function(v)
EspVisual.ShowTracer = v
if not v then
purgeAllBeams()
end
end, function()
layoutPreviewOptionVisibility()
end)
makeVisToggle(toggleRow, 66, 72, "HL", function()
return EspVisual.ShowHighlight
end, function(v)
EspVisual.ShowHighlight = v
end, function()
layoutPreviewOptionVisibility()
end)
makeVisToggle(toggleRow, 142, 68, "Text", function()
return EspVisual.ShowLabels
end, function(v)
EspVisual.ShowLabels = v
end, function()
layoutPreviewOptionVisibility()
end)
makeVisToggle(studsRow, 0, 118, "Studs", function()
return EspVisual.ShowStuds
end, function(v)
EspVisual.ShowStuds = v
end, function()
refreshAllDistLabelVis()
for _, data in pairs(ESPObjects) do
applyESPVisual(data)
end
for _, data in pairs(OrbESPObjects) do
applyOrbESPVisual(data)
end
end)
layoutPreviewOptionVisibility()
local previewRefs = { bag = {}, orb = {} }
local function makePreviewMini(sideKey, caption, position)
local card = Instance.new("Frame", previewPanel)
card.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
card.BorderSizePixel = 0
card.Size = UDim2.new(0.5, -9, 0, 72)
card.Position = position
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
local cap = Instance.new("TextLabel", card)
cap.Size = UDim2.new(1, -6, 0, 12)
cap.Position = UDim2.new(0, 3, 0, 2)
cap.BackgroundTransparency = 1
cap.Font = Enum.Font.GothamBold
cap.TextSize = 9
cap.TextColor3 = Color3.fromRGB(115, 118, 145)
cap.TextXAlignment = Enum.TextXAlignment.Left
cap.Text = caption
local hlRing = Instance.new("Frame", card)
hlRing.Name = "HLRing"
hlRing.ZIndex = 1
hlRing.Position = UDim2.new(0, 3, 0, 14)
hlRing.Size = UDim2.new(1, -6, 0, 50)
hlRing.BackgroundTransparency = 0.88
hlRing.BorderSizePixel = 0
Instance.new("UICorner", hlRing).CornerRadius = UDim.new(0, 5)
local ringStroke = Instance.new("UIStroke", hlRing)
ringStroke.Thickness = 2
local bg = Instance.new("Frame", card)
bg.ZIndex = 2
bg.Size = UDim2.new(1, -10, 0, 46)
bg.Position = UDim2.new(0, 5, 0, 16)
bg.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
bg.BackgroundTransparency = 0.35
bg.BorderSizePixel = 0
Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 4)
local stroke = Instance.new("UIStroke", bg)
stroke.Thickness = 1
local tier = Instance.new("TextLabel", bg)
tier.BackgroundTransparency = 1
tier.ZIndex = 3
tier.Font = Enum.Font.GothamBold
tier.TextXAlignment = Enum.TextXAlignment.Center
tier.Text = sideKey == "bag" and "BAG" or "CACHE"
tier.TextColor3 = Color3.fromRGB(120, 118, 145)
local rarity = Instance.new("TextLabel", bg)
rarity.BackgroundTransparency = 1
rarity.ZIndex = 3
rarity.Font = Enum.Font.GothamBold
rarity.TextXAlignment = Enum.TextXAlignment.Center
rarity.TextStrokeTransparency = 0.4
rarity.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
local dist = Instance.new("TextLabel", bg)
dist.BackgroundTransparency = 1
dist.ZIndex = 3
dist.Font = Enum.Font.Gotham
dist.TextXAlignment = Enum.TextXAlignment.Center
dist.Text = "420 studs"
dist.TextColor3 = Color3.fromRGB(210, 210, 210)
dist.TextStrokeTransparency = 0.4
dist.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
local traceLine = Instance.new("Frame", card)
traceLine.Name = "TracerLine"
traceLine.ZIndex = 4
traceLine.Position = UDim2.new(0.06, 0, 1, -7)
traceLine.Size = UDim2.new(0.88, 0, 0, 3)
traceLine.BorderSizePixel = 0
traceLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", traceLine).CornerRadius = UDim.new(1, 0)
previewRefs[sideKey] = {
tier = tier,
rarity = rarity,
dist = dist,
stroke = stroke,
hlRing = hlRing,
hlStroke = ringStroke,
traceLine = traceLine,
}
end
makePreviewMini("bag", "👜 Bag ESP", UDim2.new(0, 6, 0, 220))
makePreviewMini("orb", "📦 Cache ESP", UDim2.new(0.5, 3, 0, 220))
refreshEspPreview = function()
local rd = RarityMap[previewRarityName] or RarityMap["Common"]
local function styleSide(side, scale)
local function pxv(n)
return math.max(5, math.floor(n * scale + 0.5))
end
side.tier.TextSize = pxv(ESP_BASE.TierText)
side.tier.Size = UDim2.new(1, -pxv(6), 0, pxv(10))
side.tier.Position = UDim2.new(0, pxv(3), 0, pxv(1))
side.rarity.Size = UDim2.new(1, -pxv(6), 0, pxv(20))
side.rarity.Position = UDim2.new(0, pxv(3), 0, pxv(12))
side.rarity.Text = rd.icon .. "  " .. string.upper(previewRarityName)
side.rarity.TextColor3 = rd.color
side.rarity.TextSize = pxv(ESP_BASE.RarityText)
side.dist.Size = UDim2.new(1, -pxv(6), 0, pxv(13))
side.dist.Position = UDim2.new(0, pxv(3), 0, pxv(34))
side.dist.TextSize = pxv(ESP_BASE.DistText)
side.stroke.Color = rd.color
side.tier.Visible = EspVisual.ShowLabels
side.rarity.Visible = EspVisual.ShowLabels
side.dist.Visible = EspVisual.ShowLabels and EspVisual.ShowStuds
if side.hlRing then
side.hlRing.Visible = EspVisual.ShowHighlight
side.hlStroke.Color = rd.color
side.hlRing.BackgroundColor3 = rd.color
side.hlRing.BackgroundTransparency = math.clamp(EspVisual.HlFillTransparency, 0, 1)
side.hlStroke.Transparency = math.clamp(EspVisual.HlOutlineTransparency, 0, 1)
end
if side.traceLine then
side.traceLine.Visible = EspVisual.ShowTracer
side.traceLine.BackgroundColor3 = rd.color
side.traceLine.BackgroundTransparency = math.clamp(EspVisual.TracerTransparency, 0, 1)
side.traceLine.Size = UDim2.new(0.88, 0, 0, math.max(2, math.floor(2 + EspVisual.TracerWidth0 * 18)))
end
end
styleSide(previewRefs.bag, Config.ESPUIScale)
styleSide(previewRefs.orb, OrbConfig.ESPUIScale)
for name, chip in pairs(previewChipButtons) do
local on = name == previewRarityName
chip.BackgroundColor3 = on and Color3.fromRGB(52, 58, 92) or Color3.fromRGB(30, 30, 42)
chip.TextColor3 = on and Color3.fromRGB(235, 235, 250) or Color3.fromRGB(125, 125, 150)
end
end
refreshEspPreview()
toggleBtn.MouseButton1Click:Connect(function()
Config.Enabled = not Config.Enabled
if Config.Enabled then
toggleBtn.Text = "ESP: ON"
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 130, 80)
lastBuildingCheckFinishedAt = nil
local t0 = tick()
bagEspResumeAt = t0 + ESP_ENABLE_DELAY
lastUpdate = t0
task.delay(ESP_ENABLE_DELAY, function()
if not Config.Enabled then
return
end
cacheBuildingParts()
task.spawn(heavyUpdate)
runBuildingCheck()
end)
else
toggleBtn.Text = "ESP: OFF"
toggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
bagEspResumeAt = 0
clearAllESP()
end
updateShellAccent()
end)
orbToggleBtn.MouseButton1Click:Connect(function()
if OrbConfig.Enabled then
OrbConfig.Enabled = false
orbToggleBtn.Text = "CACHE: OFF"
orbToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
shutdownCacheEsp()
else
OrbConfig.Enabled = true
orbToggleBtn.Text = "CACHE: ON"
orbToggleBtn.BackgroundColor3 = Color3.fromRGB(90, 50, 140)
cacheEspRunId = cacheEspRunId + 1
local myRunId = cacheEspRunId
local t1 = tick()
orbEspResumeAt = t1 + ESP_ENABLE_DELAY
lastOrbUpdate = t1 + ESP_ENABLE_DELAY - OrbConfig.UpdateRate
task.delay(ESP_ENABLE_DELAY, function()
if not OrbConfig.Enabled or cacheEspRunId ~= myRunId then
return
end
task.spawn(function()
orbHeavyUpdate(myRunId)
lastOrbUpdate = tick()
end)
end)
end
updateShellAccent()
end)
updateShellAccent()
UserInputService.InputBegan:Connect(function(input, processed)
if processed then
return
end
if input.KeyCode == Enum.KeyCode.Delete then
ScreenGui.Enabled = not ScreenGui.Enabled
end
end)
print("[BagESP] Bag + Cache ESP. Delete toggles menu only. Billboards parented to world parts.")
