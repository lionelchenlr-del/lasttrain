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

local Safety=require(script.Parent:WaitForChild("RouteSafety"))
local Operations=require(script.Parent:WaitForChild("TrainOperations"))
local world=Workspace:WaitForChild("LastTrainWorld")
while not world:GetAttribute("Ready") do world:GetAttributeChangedSignal("Ready"):Wait() end
local train=world:WaitForChild("Props"):WaitForChild("LastTrainCar")
local lastRecovery = {}

RunService.Heartbeat:Connect(function()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
		if root and humanoid and humanoid.Health > 0 then
			local position = root.Position
			local currentStop=math.clamp(Workspace:GetAttribute("LastTrainStation") or 1,1,#GameConfig.Stations)
   local aboard=Operations.Contains(train,character)
   local hidden=player:GetAttribute("HiddenRouteStation")
   local hiddenY=(hidden==8 or hidden==9) and Workspace:FindFirstChild("LastTrainHiddenRoute") and (hidden==8 and 800 or 1040)
   local outsideStation=hiddenY and (math.abs(position.X)>74 or math.abs(position.Z)>37 or position.Y<hiddenY-5 or position.Y>hiddenY+22) or not hiddenY and Safety.ShouldRecover(position,aboard,currentStop,GameConfig)
			if outsideStation and (not lastRecovery[player] or os.clock() - lastRecovery[player] > 2) then
				lastRecovery[player] = os.clock()
				local stop = currentStop
				local x = -80
    if stop==1 and not player:GetAttribute("FirstStationValidated") then x=GameConfig.FirstStationEntrySpawnX end
				if workspace:GetAttribute("LastTrainTraveling") then x=25 end
    character:PivotTo(hiddenY and CFrame.new(0,hiddenY+4,23) or CFrame.new(x, 3, workspace:GetAttribute("LastTrainTraveling") and GameConfig.TrainCenterZ or -22) * CFrame.Angles(0, math.rad(-90), 0))
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastRecovery[player] = nil
end)
