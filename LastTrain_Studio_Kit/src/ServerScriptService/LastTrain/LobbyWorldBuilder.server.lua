local Workspace = game:GetService("Workspace")
local TrainGeometry = require(game:GetService("ReplicatedStorage").LastTrain.Shared:WaitForChild("TrainGeometry"))
local TrainFinish = require(game:GetService("ReplicatedStorage").LastTrain.Shared:WaitForChild("TrainFinish"))
while Workspace:GetAttribute("LastTrainMode") == nil do
	Workspace:GetAttributeChangedSignal("LastTrainMode"):Wait()
end
if Workspace:GetAttribute("LastTrainMode") ~= "Lobby" then return end

local old = Workspace:FindFirstChild("LastTrainLobby")
if old then old:Destroy() end
local lobby = Instance.new("Folder")
lobby.Name = "LastTrainLobby"
lobby.Parent = Workspace

local function part(name, size, position, color, material, transparency, collide)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = position
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.Anchored = true
	p.CanCollide = collide ~= false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = lobby
	return p
end

local midnight = Color3.fromRGB(43, 60, 72)
local steel = Color3.fromRGB(145, 161, 170)
local cyan = Color3.fromRGB(75, 205, 221)
local gold = Color3.fromRGB(226, 181, 91)
part("PolishedStoneFloor", Vector3.new(190, 1, 200), Vector3.new(0, -0.5, 0), Color3.fromRGB(132, 148, 156), Enum.Material.Marble)
-- Inlaid floor lanes and a framed central concourse break up the broad stone
-- surface without adding collision clutter to the player routes.
for _, x in ipairs({-82, -62, 62, 82}) do
	part("FloorInlayLong", Vector3.new(0.22, 0.035, 120), Vector3.new(x, 0.025, 0), Color3.fromRGB(129, 150, 151), Enum.Material.Metal, 0, false)
end
for _, z in ipairs({-90, -70, 70, 90}) do
	part("FloorInlayCross", Vector3.new(170, 0.035, 0.22), Vector3.new(0, 0.025, z), Color3.fromRGB(129, 150, 151), Enum.Material.Metal, 0, false)
end
for _, x in ipairs({-12, 12}) do
	part("ConcourseWayfindingLine", Vector3.new(0.42, 0.045, 118), Vector3.new(x, 0.035, 1), cyan, Enum.Material.Neon, 0.12, false)
end
part("LobbyCeiling", Vector3.new(190, 2, 200), Vector3.new(0, 24, 0), midnight, Enum.Material.Metal)
part("RearWall", Vector3.new(190, 24, 2), Vector3.new(0, 12, -100), steel, Enum.Material.Concrete)
part("FrontGlassWall", Vector3.new(190, 24, 1), Vector3.new(0, 12, 100), Color3.fromRGB(38, 74, 87), Enum.Material.Glass, 0.45, false)
for _, x in ipairs({-96, 96}) do
	part("SideWall", Vector3.new(2, 24, 200), Vector3.new(x, 12, 0), steel, Enum.Material.Concrete)
end

-- Repeated metal ribs and inset wall bays give the terminal a designed, vaulted
-- station profile instead of the original empty rectangular hall.
for _, z in ipairs({-84, -56, -28, 0, 28, 56, 84}) do
	local points = {}
	for segment = 0, 8 do
		local angle = math.pi * segment / 8
		local x = math.cos(angle) * 88
		local y = 4 + math.sin(angle) * 18
		table.insert(points, Vector3.new(x, y, z))
	end
	for segment = 1, #points - 1 do
		local a, b = points[segment], points[segment + 1]
		local length = (b - a).Magnitude
		local rib = part("VaultRib", Vector3.new(length + 0.2, 0.66, 0.66), (a + b) / 2, Color3.fromRGB(142, 159, 166), Enum.Material.Metal, 0, false)
		rib.Shape = Enum.PartType.Cylinder
		rib.CFrame = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0)
	end
	local crown = part("VaultCrownLight", Vector3.new(28, 0.18, 1.1), Vector3.new(0, 21.4, z), cyan, Enum.Material.Neon, 0.12, false)
	local glow = Instance.new("SurfaceLight"); glow.Face = Enum.NormalId.Bottom; glow.Range = 22; glow.Brightness = 1.1; glow.Color = cyan; glow.Parent = crown
end
for _, z in ipairs({-92, -76, -60, -44, -28, -12, 4, 20, 36, 52, 68, 84}) do
	for _, side in ipairs({-1, 1}) do
		part("WallCladdingBay", Vector3.new(0.16, 14, 12), Vector3.new(side * 94.85, 10, z), Color3.fromRGB(108, 129, 139), Enum.Material.SmoothPlastic, 0, false)
		part("WallBayReveal", Vector3.new(0.12, 0.14, 10.8), Vector3.new(side * 94.72, 16.8, z), cyan, Enum.Material.Neon, 0.22, false)
	end
end

	for _, z in ipairs({-84, -56, -28, 0, 28, 56, 84}) do
	local strip = part("CeilingLight", Vector3.new(148, 0.2, 1.6), Vector3.new(0, 22.7, z), Color3.fromRGB(227, 242, 236), Enum.Material.Neon, 0, false)
	local light = Instance.new("SurfaceLight")
	light.Face = Enum.NormalId.Bottom
	light.Range = 34
	light.Brightness = 2.7
	light.Color = Color3.fromRGB(197, 233, 231)
	light.Parent = strip
end
for _, x in ipairs({-76, -38, 38, 76}) do
	local pillar = part("OvalLobbyPillar", Vector3.new(22, 3.2, 3.2), Vector3.new(x, 11, 4), Color3.fromRGB(124, 148, 151), Enum.Material.SmoothPlastic)
	pillar.Shape = Enum.PartType.Cylinder
	pillar.CFrame = CFrame.new(pillar.Position) * CFrame.Angles(0, 0, math.rad(90))
	part("PillarFoot", Vector3.new(5, 0.65, 5), Vector3.new(x, 0.3, 4), midnight, Enum.Material.Metal)
	local accent = part("PillarAccent", Vector3.new(0.18, 3.25, 3.25), Vector3.new(x, 18.7, 4), cyan, Enum.Material.Neon, 0, false)
	accent.Shape = Enum.PartType.Cylinder
	accent.CFrame = CFrame.new(accent.Position) * CFrame.Angles(0, 0, math.rad(90))
end

-- Platform-style information furniture gives the lobby a finished terminal
-- identity and makes the story, queue and route legible at a glance.
local infoBoard = part("DepartureBoardHousing", Vector3.new(30, 6.8, 0.8), Vector3.new(0, 14.8, -63.6), midnight, Enum.Material.Metal)
local boardFace = part("DepartureBoardFace", Vector3.new(28.4, 5.2, 0.12), Vector3.new(0, 14.8, -63.12), Color3.fromRGB(8, 20, 27), Enum.Material.Glass, 0.04, false)
local boardGui = Instance.new("SurfaceGui")
boardGui.Face = Enum.NormalId.Back
boardGui.CanvasSize = Vector2.new(1200, 420)
boardGui.LightInfluence = 0
boardGui.Parent = boardFace
local boardText = Instance.new("TextLabel")
boardText.Size = UDim2.fromScale(1, 1)
boardText.BackgroundTransparency = 1
boardText.Text = "末班車  /  LAST TRAIN\n七站旅程    •    夜間列車    •    請留意月台廣播"
boardText.TextColor3 = Color3.fromRGB(195, 239, 232)
boardText.Font = Enum.Font.GothamBold
boardText.TextScaled = true
boardText.Parent = boardGui
for _, x in ipairs({-54, 54}) do
	local kiosk = part("RouteMapKiosk", Vector3.new(4.4, 5.5, 1.2), Vector3.new(x, 2.75, 4), midnight, Enum.Material.Metal)
	local map = part("RouteMapScreen", Vector3.new(3.8, 4.1, 0.1), Vector3.new(x, 3.05, 3.34), Color3.fromRGB(23, 53, 60), Enum.Material.Glass, 0.02, false)
	local mapGui = Instance.new("SurfaceGui")
	mapGui.Face = Enum.NormalId.Front
	mapGui.CanvasSize = Vector2.new(360, 500)
	mapGui.LightInfluence = 0
	mapGui.Parent = map
	local mapText = Instance.new("TextLabel")
	mapText.Size = UDim2.fromScale(1, 1)
	mapText.BackgroundTransparency = 1
	mapText.Text = "路線圖\n新月 ─ 失語 ─ 回聲\n鏡湖 ─ 遺忘 ─ 終寂 ─ 歸途"
	mapText.TextWrapped = true
	mapText.TextColor3 = cyan
	mapText.Font = Enum.Font.GothamBold
	mapText.TextScaled = true
	mapText.Parent = mapGui
	part("KioskFoot", Vector3.new(5, 0.28, 1.6), Vector3.new(x, 0.14, 4), steel, Enum.Material.Metal)
end

-- A sculpted silver train display makes the lobby read as a high speed terminal.
local train = Instance.new("Model")
train.Name = "LobbyTrainDisplay"
train.Parent = lobby
local shell = part("DisplayCarBody", Vector3.new(1, 1, 1), Vector3.new(-5.5, 4.1, -31), Color3.fromRGB(246, 249, 250), Enum.Material.Metal, 0, false)
local mesh = Instance.new("SpecialMesh")
mesh.MeshType = Enum.MeshType.Sphere
mesh.Scale = Vector3.new(93, 8.3, 11.7)
mesh.Parent = shell
shell.Reflectance = 0.16
shell.Parent = train
local shoulder = part("DisplayShoulderBody",Vector3.new(40,7.2,11.2),Vector3.new(21,4.1,-31),TrainFinish.Silver,Enum.Material.Metal,0,false)
shoulder.Parent=train
local roof = part("ContinuousCoachRoof",Vector3.new(40,.6,10),Vector3.new(21,8,-31),TrainFinish.Roof,Enum.Material.Metal,0,false)
roof.Parent=train
for _,side in ipairs({-1,1}) do
 local edge=part("RoofShoulder",Vector3.new(40,1.7,1.7),Vector3.new(21,7.45,-31+side*5),TrainFinish.Silver,Enum.Material.Metal,0,false)
 edge.Shape=Enum.PartType.Cylinder; edge.Parent=train
end
TrainGeometry.BuildCab(train,"Front",41,1)
for _,surface in ipairs(train:GetChildren()) do
 if surface:IsA("BasePart") and surface:GetAttribute("CabEnd") then surface.Position+=Vector3.new(0,0,-31) end
end
local glass = part("DisplayWindowBand", Vector3.new(91, 2.55, 0.18), Vector3.new(-5, 6.0, -25.08), Color3.fromRGB(12, 31, 43), Enum.Material.Glass, 0.025, false)
glass.Parent = train
local stripe = part("DisplayCyanStripe", Vector3.new(93, 0.26, 0.18), Vector3.new(-5, 2.25, -25.08), cyan, Enum.Material.Neon, 0, false)
stripe.Parent = train
local lowerBlueStripe = part("DisplayLowerBlueStripe", Vector3.new(93, 0.11, 0.18), Vector3.new(-5, 2.18, -24.6), Color3.fromRGB(24, 112, 162), Enum.Material.Metal, 0, false)
lowerBlueStripe.Parent = train
-- Car doors, dark window mullions, a separate lower skirt, and an unmistakable
-- blue/cyan HTSR-style nose band make the display read as a train at a glance.
for _, x in ipairs({-39, -25, -11, 3, 17, 31}) do
	local mullion = part("DisplayWindowMullion", Vector3.new(0.16, 2.8, 0.22), Vector3.new(x, 6, -24.65), Color3.fromRGB(51, 76, 86), Enum.Material.Metal, 0, false); mullion.Parent = train
end
for _, x in ipairs({-30, 10}) do
	local door = part("DisplayPassengerDoor", Vector3.new(3.3, 5.9, 0.2), Vector3.new(x, 4.7, -24.65), Color3.fromRGB(111, 145, 153), Enum.Material.Glass, 0.16, false); door.Parent = train
end
local skirt = part("DisplayContinuousSkirt", Vector3.new(90, 1, 0.42), Vector3.new(-5, 1.9, -24.75), Color3.fromRGB(69, 86, 93), Enum.Material.Metal, 0, false); skirt.Parent = train
for _, x in ipairs({-44, -30, -12, 10, 30, 48}) do
	local bogie = part("DisplayBogie", Vector3.new(7.4, 1.15, 9.6), Vector3.new(x, 1.15, -31), Color3.fromRGB(44, 55, 60), Enum.Material.Metal, 0, false)
	bogie.Parent = train
	for _, z in ipairs({-36, -26}) do
	local wheel = part("DisplayWheel", Vector3.new(0.55, 2.7, 2.7), Vector3.new(x, 0.9, z), Color3.fromRGB(27, 35, 39), Enum.Material.Metal, 0, false)
		wheel.Shape = Enum.PartType.Cylinder
		wheel.CFrame = CFrame.new(x, 0.9, z) * CFrame.Angles(0, math.rad(90), 0)
		wheel.Parent = train
	end
end
local displayTrack = part("DisplayTrack", Vector3.new(126, 0.4, 20), Vector3.new(-1, 0.15, -31), midnight, Enum.Material.Metal, 0, false); displayTrack.Parent = train

TrainFinish.Apply(train)

-- Turn the long display toward the entrance and leave a clear walking lane.
local oldPivot = CFrame.new(-1, 4.7, -31)
-- The default spawn looks down the station's +X axis. Align the train nose with
-- that sightline so players can read the cab instead of seeing a broad side wall.
local newPivot = CFrame.new(-58, 4.7, -14)
for _, descendant in ipairs(train:GetDescendants()) do
	if descendant:IsA("BasePart") then descendant.CFrame = newPivot * oldPivot:ToObjectSpace(descendant.CFrame) end
end

-- Four walk-up party gates sit in two calm side bays, leaving the central
-- entrance-to-platform concourse clear as shown in the approved floor plan.
local gateFolder = Instance.new("Folder")
gateFolder.Name = "MatchmakingGates"
gateFolder.Parent = lobby
local gateColors = {
	Color3.fromRGB(90, 207, 218), Color3.fromRGB(105, 205, 172),
	Color3.fromRGB(232, 190, 99), Color3.fromRGB(221, 139, 104),
}
local gatePositions = {
	Vector3.new(-68, 0, -4), Vector3.new(-68, 0, 28),
	Vector3.new(68, 0, -4), Vector3.new(68, 0, 28),
}
for count, center in ipairs(gatePositions) do
	local x, z = center.X, center.Z
	local accent = gateColors[count]
	local side = x < 0 and 1 or -1
	local pad = part("Gate" .. count, Vector3.new(18, 0.6, 14), Vector3.new(x, 0.3, z), Color3.fromRGB(16, 39, 53), Enum.Material.Metal)
	pad.Parent = gateFolder
	local inset = part("GateFloorGlow", Vector3.new(16.2, 0.08, 12.2), Vector3.new(x, 0.64, z), accent, Enum.Material.Neon, 0.18, false)
	inset.Parent = gateFolder
	local centerDisc = part("GateQueueDisc", Vector3.new(7.8, 0.1, 7.8), Vector3.new(x, 0.72, z), Color3.fromRGB(20, 59, 76), Enum.Material.Glass, 0.08, false)
	centerDisc.Shape = Enum.PartType.Cylinder
	centerDisc.Size = Vector3.new(0.1, 7.8, 7.8)
	centerDisc.CFrame = CFrame.new(centerDisc.Position) * CFrame.Angles(0, 0, math.rad(90))
	centerDisc.Parent = gateFolder
	for _, dx in ipairs({-7.4, 7.4}) do
		for _, dz in ipairs({-5.4, 5.4}) do
			local post = part("GateFramePost", Vector3.new(0.72, 8.8, 0.72), Vector3.new(x + dx, 4.7, z + dz), steel, Enum.Material.Metal)
			post.Parent = gateFolder
			local light = part("GateFrameLight", Vector3.new(0.18, 7.8, 0.18), Vector3.new(x + dx, 4.8, z + dz), accent, Enum.Material.Neon, 0.03, false)
			light.Parent = gateFolder
		end
	end
	local header = part("GateHeader", Vector3.new(15.4, 0.8, 1), Vector3.new(x, 9.2, z), steel, Enum.Material.Metal)
	header.Parent = gateFolder
	local promptAnchor = part("GatePrompt" .. count, Vector3.new(18, 5, 14), Vector3.new(x, 2.5, z), accent, Enum.Material.Neon, 1, false)
	promptAnchor.Parent = gateFolder
	promptAnchor:SetAttribute("PartySize", count)
	promptAnchor.CanCollide = false
	promptAnchor.CanTouch = true
	local facePoint = Vector3.new(0, 6.1, z)
	local signPosition = Vector3.new(x + side * 7.45, 6.1, z)
	local sign = part("GateSign" .. count, Vector3.new(11.4, 4.1, 0.24), signPosition, Color3.fromRGB(24, 67, 84), Enum.Material.SmoothPlastic, 0.04, false)
	sign.CFrame = CFrame.lookAt(sign.Position, facePoint)
	sign.Parent = gateFolder
	local signGui = Instance.new("SurfaceGui")
	signGui.Name = "GateDisplay"
	signGui.Face = Enum.NormalId.Front
	signGui.CanvasSize = Vector2.new(600, 340)
	signGui.LightInfluence = 0
	signGui.Parent = sign
	local signText = Instance.new("TextLabel")
	signText.Name = "PortalStatus"
	signText.Size = UDim2.fromScale(1, 1)
	signText.BackgroundColor3 = Color3.fromRGB(17, 51, 67)
	signText.BackgroundTransparency = 0.03
	signText.Text = string.format("%d 人列車\n走進入口加入\n0 / %d", count, count)
	signText.TextColor3 = accent
	signText.Font = Enum.Font.GothamBlack
	signText.TextScaled = true
	signText.TextWrapped = true
	local signStroke = Instance.new("UIStroke")
	signStroke.Color = accent
	signStroke.Transparency = 0.48
	signStroke.Thickness = 3
	signStroke.Parent = signText
	signText.Parent = signGui
	local rearGui = Instance.new("SurfaceGui")
	rearGui.Name = "GateDisplayRear"
	rearGui.Face = Enum.NormalId.Back
	rearGui.CanvasSize = Vector2.new(600, 340)
	rearGui.LightInfluence = 0
	rearGui.Parent = sign
	local rearText = signText:Clone()
	rearText.Parent = rearGui
	local counter = part("GateCounter" .. count, Vector3.new(5.2, 1.05, 0.18), Vector3.new(x, 9.95, z), Color3.fromRGB(24, 67, 84), Enum.Material.SmoothPlastic, 0.02, false)
	counter.CFrame = CFrame.lookAt(counter.Position, facePoint)
	counter.Parent = gateFolder
	local counterGui = Instance.new("SurfaceGui")
	counterGui.Face = Enum.NormalId.Front
	counterGui.CanvasSize = Vector2.new(500, 140)
	counterGui.LightInfluence = 0
	counterGui.Parent = counter
	local counterText = Instance.new("TextLabel")
	counterText.Name = "QueueCounter"
	counterText.Size = UDim2.fromScale(1, 1)
	counterText.BackgroundTransparency = 1
	counterText.Text = string.format("0 / %d   •   10", count)
	counterText.TextColor3 = accent
	counterText.Font = Enum.Font.GothamBlack
	counterText.TextScaled = true
	counterText.Parent = counterGui
	local counterBackGui = Instance.new("SurfaceGui")
	counterBackGui.Name = "CounterDisplayRear"
	counterBackGui.Face = Enum.NormalId.Back
	counterBackGui.CanvasSize = Vector2.new(500, 140)
	counterBackGui.LightInfluence = 0
	counterBackGui.Parent = counter
	local counterBackText = counterText:Clone()
	counterBackText.Parent = counterBackGui
end

-- Large, readable story and character-shop kiosks anchor the entrance zone.
local function buildLobbyKiosk(name, title, subtitle, x, accent, promptAction)
	local body = part(name .. "Body", Vector3.new(18, 8, 2.2), Vector3.new(x, 4, 49), midnight, Enum.Material.Metal)
	local screen = part(name .. "Screen", Vector3.new(16.8, 6.4, 0.16), Vector3.new(x, 4.4, 47.82), Color3.fromRGB(10, 31, 43), Enum.Material.Glass, 0.02, false)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(900, 360)
	gui.LightInfluence = 0
	gui.Parent = screen
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = title .. "\n" .. subtitle
	text.TextColor3 = accent
	text.Font = Enum.Font.GothamBold
	text.TextScaled = true
	text.TextWrapped = true
	text.Parent = gui
	local base = part(name .. "Base", Vector3.new(20, 0.4, 3.2), Vector3.new(x, 0.2, 49), steel, Enum.Material.Metal)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = promptAction
	prompt.ObjectText = title
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = body
	return body, screen, base
end
buildLobbyKiosk("StoryKiosk", "故事序章", "七站旅程即將開始\n末班車，請準備上車", -34, Color3.fromRGB(147, 225, 235), "查看故事")
buildLobbyKiosk("CharacterShopKiosk", "角色商店", "解鎖角色外觀與能力\n遊戲幣 / Robux", 34, Color3.fromRGB(245, 204, 116), "開啟商店")

-- A small staffed-looking uniform counter gives the shop a real place in the
-- concourse. Rounded display figures and warm brass lights distinguish it from
-- the matching story kiosk across the aisle.
local shopTrim = Color3.fromRGB(201, 160, 91)
local shopCream = Color3.fromRGB(220, 214, 192)
local shopTeal = Color3.fromRGB(38, 86, 91)
part("UniformShopRunner", Vector3.new(40, 0.08, 28), Vector3.new(34, 0.06, 43), Color3.fromRGB(52, 76, 78), Enum.Material.Fabric, 0, false)
part("UniformShopBackWall", Vector3.new(40, 10, 1.1), Vector3.new(34, 5, 24), Color3.fromRGB(89, 111, 116), Enum.Material.Metal, 0, false)
part("UniformShopWallInset", Vector3.new(37, 7.4, 0.16), Vector3.new(34, 5.2, 23.38), Color3.fromRGB(53, 78, 84), Enum.Material.SmoothPlastic, 0, false)
part("UniformShopHeader", Vector3.new(40, 1.25, 1.4), Vector3.new(34, 11.8, 48), shopTeal, Enum.Material.Metal, 0, false)
local shopHeader = part("UniformShopHeaderLight", Vector3.new(38, 0.16, 1.6), Vector3.new(34, 12.45, 48), shopTrim, Enum.Material.Neon, 0.18, false)
local headerGlow = Instance.new("SurfaceLight")
headerGlow.Face = Enum.NormalId.Bottom
headerGlow.Range = 20
headerGlow.Brightness = 1.15
headerGlow.Color = Color3.fromRGB(255, 218, 154)
headerGlow.Parent = shopHeader
for _, x in ipairs({14.5, 53.5}) do
	local post = part("UniformShopPost", Vector3.new(12, 1.3, 1.3), Vector3.new(x, 6, 48), shopTrim, Enum.Material.Metal)
	post.Shape = Enum.PartType.Cylinder
	post.CFrame = CFrame.new(post.Position) * CFrame.Angles(0, 0, math.rad(90))
	part("UniformShopFoot", Vector3.new(2.2, 0.48, 2.2), Vector3.new(x, 0.24, 48), shopTeal, Enum.Material.Metal)
end

local function roundedMannequin(prefix, x, colors, label)
	local z = 37
	part(prefix .. "Plinth", Vector3.new(6.6, 0.65, 5.2), Vector3.new(x, 0.325, z), Color3.fromRGB(87, 103, 103), Enum.Material.Marble)
	part(prefix .. "PlinthTrim", Vector3.new(6.8, 0.12, 5.4), Vector3.new(x, 0.68, z), shopTrim, Enum.Material.Metal, 0, false)
	local legA = part(prefix .. "LegA", Vector3.new(2.25, 0.68, 0.72), Vector3.new(x - 0.48, 2.03, z), colors.Legs, Enum.Material.SmoothPlastic, 0, false)
	local legB = part(prefix .. "LegB", Vector3.new(2.25, 0.68, 0.72), Vector3.new(x + 0.48, 2.03, z), colors.Legs, Enum.Material.SmoothPlastic, 0, false)
	legA.Shape = Enum.PartType.Cylinder; legB.Shape = Enum.PartType.Cylinder
	legA.CFrame = CFrame.new(legA.Position) * CFrame.Angles(0, 0, math.rad(90))
	legB.CFrame = CFrame.new(legB.Position) * CFrame.Angles(0, 0, math.rad(90))
	local torso = part(prefix .. "Coat", Vector3.new(2.5, 2.4, 1.25), Vector3.new(x, 4.2, z), colors.Coat, Enum.Material.SmoothPlastic, 0, false)
	torso.Shape = Enum.PartType.Cylinder
	torso.CFrame = CFrame.new(torso.Position) * CFrame.Angles(0, 0, math.rad(90))
	local collar = part(prefix .. "Collar", Vector3.new(1.05, 0.18, 0.2), Vector3.new(x, 5.35, z + 0.62), colors.Trim, Enum.Material.Metal, 0, false)
	local tie = part(prefix .. "UniformPlacket", Vector3.new(0.22, 1.5, 0.1), Vector3.new(x, 4.4, z + 0.68), colors.Trim, Enum.Material.SmoothPlastic, 0, false)
	local belt = part(prefix .. "UniformBelt", Vector3.new(2.2, 0.16, 0.12), Vector3.new(x, 3.2, z + 0.62), colors.Trim, Enum.Material.Metal, 0, false)
	part(prefix .. "JacketPocketL", Vector3.new(0.62, 0.48, 0.08), Vector3.new(x - 0.65, 4.55, z + 0.66), colors.Coat, Enum.Material.SmoothPlastic, 0, false)
	part(prefix .. "JacketPocketR", Vector3.new(0.62, 0.48, 0.08), Vector3.new(x + 0.65, 4.55, z + 0.66), colors.Coat, Enum.Material.SmoothPlastic, 0, false)
	local badge = part(prefix .. "EnamelBadge", Vector3.new(0.32, 0.4, 0.1), Vector3.new(x - 0.67, 4.94, z + 0.72), colors.Trim, Enum.Material.Metal, 0, false)
	badge.Shape = Enum.PartType.Ball
	local head = part(prefix .. "Head", Vector3.new(1.35, 1.35, 1.25), Vector3.new(x, 6.15, z), shopCream, Enum.Material.SmoothPlastic, 0, false)
	head.Shape = Enum.PartType.Ball
	for _, eyeX in ipairs({x - 0.23, x + 0.23}) do
		local eye = part(prefix .. "Eye", Vector3.new(0.12, 0.13, 0.055), Vector3.new(eyeX, 6.2, z + 0.61), Color3.fromRGB(30, 47, 55), Enum.Material.SmoothPlastic, 0, false)
		eye.Shape = Enum.PartType.Ball
		part(prefix .. "EyeGlint", Vector3.new(0.035, 0.035, 0.025), eye.Position + Vector3.new(-0.018, 0.025, 0.03), Color3.fromRGB(233, 241, 232), Enum.Material.Neon, 0, false).Shape = Enum.PartType.Ball
	end
	part(prefix .. "Mouth", Vector3.new(0.18, 0.035, 0.035), Vector3.new(x, 5.94, z + 0.63), Color3.fromRGB(107, 70, 62), Enum.Material.SmoothPlastic, 0, false)
	local cap = part(prefix .. "Cap", Vector3.new(0.32, 1.6, 1.4), Vector3.new(x, 6.82, z), colors.Trim, Enum.Material.SmoothPlastic, 0, false)
	cap.Shape = Enum.PartType.Cylinder
	cap.CFrame = CFrame.new(cap.Position) * CFrame.Angles(0, 0, math.rad(90))
	local shoulderA = part(prefix .. "SleeveA", Vector3.new(1.75, 0.72, 0.72), Vector3.new(x - 1.35, 4.15, z), colors.Coat, Enum.Material.SmoothPlastic, 0, false)
	local shoulderB = part(prefix .. "SleeveB", Vector3.new(1.75, 0.72, 0.72), Vector3.new(x + 1.35, 4.15, z), colors.Coat, Enum.Material.SmoothPlastic, 0, false)
	shoulderA.Shape = Enum.PartType.Cylinder; shoulderB.Shape = Enum.PartType.Cylinder
	shoulderA.CFrame = CFrame.new(shoulderA.Position) * CFrame.Angles(0, 0, math.rad(90))
	shoulderB.CFrame = CFrame.new(shoulderB.Position) * CFrame.Angles(0, 0, math.rad(90))
	for _, armX in ipairs({x - 1.35, x + 1.35}) do
		local cuff = part(prefix .. "Cuff", Vector3.new(0.12, 0.82, 0.78), Vector3.new(armX, 3.5, z), colors.Trim, Enum.Material.Metal, 0, false)
		cuff.Shape = Enum.PartType.Cylinder
		cuff.CFrame = CFrame.new(cuff.Position) * CFrame.Angles(0, 0, math.rad(90))
	end
	local plaque = part(prefix .. "Nameplate", Vector3.new(6.1, 0.8, 0.16), Vector3.new(x, 1.08, z + 2.68), shopTeal, Enum.Material.Metal, 0, false)
	for _, footX in ipairs({x - 0.48, x + 0.48}) do
		local boot = part(prefix .. "Boot", Vector3.new(0.8, 0.3, 1.12), Vector3.new(footX, 0.84, z + 0.08), colors.Legs, Enum.Material.Leather, 0, false)
		boot.Shape = Enum.PartType.Ball
		part(prefix .. "BootSole", Vector3.new(0.76, 0.08, 1.08), Vector3.new(footX, 0.71, z + 0.08), midnight, Enum.Material.Rubber, 0, false)
	end
	if prefix == "UniformWorker" then
		for _, y in ipairs({3.85, 4.25}) do
			part(prefix .. "ReflectiveBackline", Vector3.new(2.1, 0.12, 0.09), Vector3.new(x, y, z + 0.67), colors.Trim, Enum.Material.Neon, 0, false)
		end
	elseif prefix == "UniformConductor" then
		for _, buttonY in ipairs({3.85, 4.2, 4.55}) do
			local button = part(prefix .. "BrassButton", Vector3.new(0.11, 0.11, 0.08), Vector3.new(x, buttonY, z + 0.72), colors.Trim, Enum.Material.Metal, 0, false)
			button.Shape = Enum.PartType.Ball
		end
	elseif prefix == "UniformSignalman" then
		part(prefix .. "SignalRadio", Vector3.new(0.34, 0.48, 0.32), Vector3.new(x + 0.82, 4.72, z + 0.24), midnight, Enum.Material.Metal, 0, false)
	elseif prefix == "UniformNightGuard" then
		part(prefix .. "Scarf", Vector3.new(1.7, 0.52, 0.28), Vector3.new(x, 5.08, z + 0.72), colors.Trim, Enum.Material.Fabric, 0, false)
		part(prefix .. "ScarfTail", Vector3.new(0.28, 1.12, 0.22), Vector3.new(x + 0.28, 4.45, z + 0.72), colors.Trim, Enum.Material.Fabric, 0, false)
	end
	local face = Instance.new("SurfaceGui")
	face.Face = Enum.NormalId.Back
	face.CanvasSize = Vector2.new(500, 100)
	face.LightInfluence = 0
	face.Parent = plaque
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = label
	text.TextColor3 = colors.Trim
	text.Font = Enum.Font.GothamBold
	text.TextScaled = true
	text.Parent = face
end

roundedMannequin("UniformWorker", 18, { Coat = Color3.fromRGB(61, 81, 87), Legs = Color3.fromRGB(37, 52, 61), Trim = Color3.fromRGB(223, 180, 92) }, "月台巡守")
roundedMannequin("UniformConductor", 28, { Coat = Color3.fromRGB(42, 58, 78), Legs = Color3.fromRGB(29, 39, 55), Trim = Color3.fromRGB(235, 199, 122) }, "夜班列車長")
roundedMannequin("UniformSignalman", 40, { Coat = Color3.fromRGB(112, 54, 45), Legs = Color3.fromRGB(49, 48, 46), Trim = Color3.fromRGB(214, 207, 183) }, "號誌技師")
roundedMannequin("UniformNightGuard", 50, { Coat = Color3.fromRGB(34, 39, 46), Legs = Color3.fromRGB(23, 28, 34), Trim = Color3.fromRGB(178, 63, 57) }, "深夜站務員")

local spawn = Workspace:FindFirstChild("PlatformSpawn")
if spawn then
	spawn.CFrame = CFrame.new(0, 0.4, 78)
	spawn.Neutral = true
	spawn.Duration = 0
end

