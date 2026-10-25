-- Wait until the generated station spawn exists before assigning or loading characters.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
while Workspace:GetAttribute("LastTrainMode") == nil do
	Workspace:GetAttributeChangedSignal("LastTrainMode"):Wait()
end
if Workspace:GetAttribute("LastTrainMode") ~= "Game" then
	Players.CharacterAutoLoads = true
	return
end
Players.CharacterAutoLoads = false

local function getStationSpawnCFrame(player)
 local hidden=player:GetAttribute("HiddenRouteStation")
 if (hidden==8 or hidden==9) and Workspace:FindFirstChild("LastTrainHiddenRoute") then return CFrame.new(0,hidden==8 and 800.5 or 1040.5,23) end
	local world=Workspace:WaitForChild("LastTrainWorld")
	while not world:GetAttribute("Ready") do world:GetAttributeChangedSignal("Ready"):Wait() end
	local station = math.clamp(Workspace:GetAttribute("LastTrainStation") or 1, 1, 7)
	local config = require(game:GetService("ReplicatedStorage"):WaitForChild("LastTrain"):WaitForChild("Shared"):WaitForChild("GameConfig"))
	-- Respawns use the same clear approach point as a new round, away from the
	-- carriage body so the locked first-person camera cannot start inside it.
	local x = -80
	if station==1 and not player:GetAttribute("FirstStationValidated") then x=config.FirstStationEntrySpawnX end
	if workspace:GetAttribute("LastTrainTraveling") then return CFrame.new(25,.4,config.TrainCenterZ) end
	return CFrame.new(x, 0.4, -22) * CFrame.Angles(0, math.rad(-90), 0)
end

local function placeCharacter(player, character)
	local spawnCFrame = getStationSpawnCFrame(player)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if root and character.Parent then
		character:PivotTo(spawnCFrame * CFrame.new(0, 3, 0))
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end
end

local function loadAtStation(player)
	if not player.Parent then return end
	player.RespawnLocation = Workspace:WaitForChild("PlatformSpawn")
	player:LoadCharacterAsync()
	local character = player.Character
	if character then
		placeCharacter(player, character)
	end
end

local function setupPlayer(player)
	-- Connect before waiting for the generated map: Roblox can raise CharacterAdded
	-- while this script is still waiting for WorldBuilder to finish.
	player.CharacterAdded:Connect(function(character)
		task.spawn(placeCharacter, player, character)
		local humanoid = character:WaitForChild("Humanoid", 10)
		if humanoid then
			humanoid.Died:Once(function()
				task.delay(3, loadAtStation, player)
			end)
		end
	end)
	loadAtStation(player)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, player)
end
