-- Return players to the platform if they fall out of the station or get stranded.
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

local lastRecovery = {}

RunService.Heartbeat:Connect(function()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
		if root and humanoid and humanoid.Health > 0 then
			local position = root.Position
			local outsideStation = position.Y < -8
				or position.X < -250 or position.X > GameConfig.StationSpacing * (#GameConfig.Stations - 1) + 250
				or math.abs(position.Z) > 45
			if outsideStation and (not lastRecovery[player] or os.clock() - lastRecovery[player] > 2) then
				lastRecovery[player] = os.clock()
				local stop = math.clamp(Workspace:GetAttribute("LastTrainStation") or 1, 1, 7)
				local x = (stop - 1) * GameConfig.StationSpacing - 40
				character:PivotTo(CFrame.new(x, 3, -22) * CFrame.Angles(0, math.rad(-90), 0))
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastRecovery[player] = nil
end)
