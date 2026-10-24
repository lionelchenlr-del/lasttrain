-- Pathfinding chase without a downloaded character asset. Replace the blockout model with a custom rig in the art pass.
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local GameConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("LastTrain"):WaitForChild("Shared"):WaitForChild("GameConfig"))

while Workspace:GetAttribute("LastTrainMode") == nil do
    Workspace:GetAttributeChangedSignal("LastTrainMode"):Wait()
end
while Workspace:GetAttribute("LastTrainMode") ~= "Game" do
    Workspace:GetAttributeChangedSignal("LastTrainMode"):Wait()
end

local world = Workspace:WaitForChild("LastTrainWorld")
while not world:GetAttribute("Ready") do world:GetAttributeChangedSignal("Ready"):Wait() end
local spawnPart = world:WaitForChild("MonsterSpawn")
local spawnPosition = Vector3.new(spawnPart.Position.X, 0, spawnPart.Position.Z)
local monster = Instance.new("Model")
monster.Name = "Stationmaster"
monster.Parent = world

local root = Instance.new("Part")
root.Name = "Root"
root.Size = Vector3.new(1, 1, 1)
root.Transparency = 1
root.Anchored = true
root.CanCollide = false
root.CanTouch = false
root.Position = spawnPosition + Vector3.new(0, 0.5, 0)
root.Parent = monster
monster.PrimaryPart = root

local function piece(name, size, offset, color, material)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CastShadow = true
    part.CFrame = CFrame.new(spawnPosition + offset)
    part.Parent = monster
    return part
end

piece("LongCoat", Vector3.new(2.8, 4.4, 1.45), Vector3.new(0, 3.4, 0), Color3.fromRGB(15, 20, 24), Enum.Material.Fabric)
piece("Collar", Vector3.new(1.8, 0.55, 1.2), Vector3.new(0, 5.6, 0), Color3.fromRGB(95, 35, 33), Enum.Material.Fabric)
piece("BlankFace", Vector3.new(1.65, 1.9, 1.25), Vector3.new(0, 6.85, 0), Color3.fromRGB(172, 177, 167), Enum.Material.SmoothPlastic)
piece("Cap", Vector3.new(2.5, 0.5, 2.2), Vector3.new(0, 7.95, 0), Color3.fromRGB(18, 23, 28), Enum.Material.Fabric)
piece("CapBrim", Vector3.new(2.9, 0.15, 1), Vector3.new(0, 7.7, -0.75), Color3.fromRGB(18, 23, 28), Enum.Material.Fabric)
for _, x in ipairs({-0.42, 0.42}) do
    local eye = piece("RedEye", Vector3.new(0.22, 0.13, 0.08), Vector3.new(x, 6.95, -0.66), Color3.fromRGB(200, 39, 31), Enum.Material.Neon)
    eye.CastShadow = false
end
for _, x in ipairs({-1.85, 1.85}) do
    piece("Sleeve", Vector3.new(0.8, 3.9, 0.9), Vector3.new(x, 3.55, 0), Color3.fromRGB(18, 23, 27), Enum.Material.Fabric)
end
for _, x in ipairs({-0.78, 0.78}) do
    piece("TrouserLeg", Vector3.new(0.9, 2.3, 1), Vector3.new(x, 1.05, 0), Color3.fromRGB(21, 25, 29), Enum.Material.Fabric)
end

local function setModelPosition(position, direction)
    local look = Vector3.new(direction.X, 0, direction.Z)
    if look.Magnitude < 0.01 then look = Vector3.new(0, 0, -1) end
    local target = CFrame.lookAt(Vector3.new(position.X, 0.5, position.Z), Vector3.new(position.X, 0.5, position.Z) + look.Unit)
    monster:PivotTo(target)
end

local active = false
local speed = 10.5
local function huntAllowed()
    local stage=Workspace:GetAttribute("LastTrainRoundStage") or 0
    local station=Workspace:GetAttribute("LastTrainStation") or 1
    return stage>=1 and stage<3 and station>=2 and station<=3
        and not Workspace:GetAttribute("LastTrainTraveling")
end
local function nearestPlayer()
    local bestRoot, bestDistance, bestRange, bestScore
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
        local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
        if humanoid and playerRoot and humanoid.Health > 0 then
            local distance = (playerRoot.Position - root.Position).Magnitude
            local range = 190 * (player:GetAttribute("MonsterDetectionMultiplier") or 1)
            local score = distance / math.max(range, 1)
            if distance <= range and (not bestScore or score < bestScore) then
                bestRoot, bestDistance, bestRange, bestScore = playerRoot, distance, range, score
            end
        end
    end
    return bestRoot, bestDistance, bestRange
end

local function catchNearbyPlayer()
    if not huntAllowed() then return end
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
        local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
        if humanoid and playerRoot and humanoid.Health > 0 and (playerRoot.Position - root.Position).Magnitude < 4.2 then
            humanoid.Health = 0
        end
    end
end

while true do
    local stage = Workspace:GetAttribute("LastTrainRoundStage") or 0
    local station = math.clamp(Workspace:GetAttribute("LastTrainStation") or 1, 1, 7)
    local stationSpawn = Vector3.new(118, 0, -22)
    if (stationSpawn - spawnPosition).Magnitude > 1 then
        spawnPosition = stationSpawn
        setModelPosition(spawnPosition, Vector3.new(-1, 0, 0))
    end
    local shouldHunt = huntAllowed()
    if shouldHunt and not active then
        active = true
        setModelPosition(spawnPosition, Vector3.new(-1, 0, 0))
    elseif not shouldHunt and active then
        active = false
        setModelPosition(spawnPosition, Vector3.new(-1, 0, 0))
    end

    if active then
        local target, distance, targetRange = nearestPlayer()
        if target and distance and distance < targetRange then
            local path = PathfindingService:CreatePath({
                AgentRadius = 2,
                AgentHeight = 8,
                AgentCanJump = false,
                WaypointSpacing = 5,
            })
            local success = pcall(function()
                path:ComputeAsync(root.Position, target.Position)
            end)
            if success and path.Status == Enum.PathStatus.Success then
                local waypoints = path:GetWaypoints()
                for index = 2, #waypoints do
                    if not active or not huntAllowed() then break end
                    local destination = Vector3.new(waypoints[index].Position.X, 0.5, waypoints[index].Position.Z)
                    local start = root.Position
                    local delta = Vector3.new(destination.X - start.X, 0, destination.Z - start.Z)
                    local length = delta.Magnitude
                    if length > 0.2 then
                        local direction = delta.Unit
                        local travelled = 0
                        while travelled < length and active and huntAllowed() do
                            local dt = RunService.Heartbeat:Wait()
                            local step = math.min(speed * dt, length - travelled)
                            travelled += step
                            local position = start + direction * travelled
                            setModelPosition(position, direction)
                            catchNearbyPlayer()
                            local currentTarget, currentDistance, currentRange = nearestPlayer()
                            if not currentTarget or not currentDistance or currentDistance > currentRange + 20 then break end
                            if currentDistance < 4.5 then catchNearbyPlayer() end
                        end
                    end
                    local _, currentDistance, currentRange = nearestPlayer()
                    if not currentDistance or currentDistance > currentRange + 20 then break end
                end
            end
        end
    end
    task.wait(0.45)
end
