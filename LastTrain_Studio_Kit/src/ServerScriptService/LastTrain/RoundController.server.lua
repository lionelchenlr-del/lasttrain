-- Server-owned story progression and carriage movement. Prompts are validated
-- here, and only the server awards currency or advances the train.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")
local Workspace=game:GetService("Workspace")
local GameConfig=require(ReplicatedStorage:WaitForChild("LastTrain"):WaitForChild("Shared"):WaitForChild("GameConfig"))
local Profiles=require(script.Parent:WaitForChild("ProfileService"))
local objectiveEvent=ReplicatedStorage:WaitForChild("LastTrain"):WaitForChild("Remotes"):WaitForChild("ObjectiveUpdate")
while Workspace:GetAttribute("LastTrainMode") == nil do
 Workspace:GetAttributeChangedSignal("LastTrainMode"):Wait()
end
while Workspace:GetAttribute("LastTrainMode") ~= "Game" do
 Workspace:GetAttributeChangedSignal("LastTrainMode"):Wait()
end
local world=Workspace:WaitForChild("LastTrainWorld")
while not world:GetAttribute("Ready") do world:GetAttributeChangedSignal("Ready"):Wait() end
local objectiveFolder=world:WaitForChild("Objectives")
local train=world:WaitForChild("Props"):WaitForChild("LastTrainCar")
local stage,completed,choice,traveling=0,false,nil,false
local station=1
local spacing=GameConfig.StationSpacing

local function storyFor(index) return GameConfig.Stations[index] and GameConfig.Stations[index].Story or "" end
local function broadcast(endingKey)
 local data=GameConfig.Stations[station]
 objectiveEvent:FireAllClients(stage,GameConfig.Objectives[math.min(stage+1,#GameConfig.Objectives)],completed,data and data.Name or "",storyFor(station),endingKey)
end
local function setDoors(open)
 for _,d in ipairs(train:GetDescendants()) do if d:IsA("BasePart") then
  if d.Name=="SlidingDoor" then
   -- Only the platform-facing doors open; track-side doors stay sealed.
   local shouldOpen=open and d:GetAttribute("Side")==-1
   local x=d:GetAttribute(shouldOpen and "OpenX" or "ClosedX") or d.Position.X
   d.Position=Vector3.new(x,d.Position.Y,d.Position.Z); d.CanCollide=not shouldOpen
  elseif d.Name=="BoardingBridge" then
   local shouldOpen=open and d:GetAttribute("Side")==-1
   d.Transparency=shouldOpen and 0 or 1; d.CanCollide=shouldOpen
  end
 end end
end
local function boardPlayer(player)
 local character=player.Character; local humanoid=character and character:FindFirstChildWhichIsA("Humanoid")
 if not character or not humanoid or humanoid.Health<=0 then return end
 character:PivotTo(train:GetPivot()*CFrame.new(-10,-1,0)); player:SetAttribute("OnLastTrain",true)
end
-- Keep the ride state in sync with where the player is standing. This lets
-- players walk through the open doors and remain at a station when the train leaves.
RunService.Heartbeat:Connect(function()
 local pivot=train:GetPivot()
 for _,p in ipairs(Players:GetPlayers()) do
  local character=p.Character; local root=character and character:FindFirstChild("HumanoidRootPart")
  if root then
   local localPosition=pivot:PointToObjectSpace(root.Position)
   local aboard=math.abs(localPosition.X)<=96 and localPosition.Y>=-5 and localPosition.Y<=9 and math.abs(localPosition.Z)<=5.8
   p:SetAttribute("OnLastTrain",aboard)
  else p:SetAttribute("OnLastTrain",false) end
 end
end)
local function moveToNextStation()
 traveling=true; setDoors(false)
 local start=train:GetPivot(); local target=start+Vector3.new(spacing,0,0)
 local value=Instance.new("CFrameValue"); value.Value=start
 local previous=start
 local connection=value:GetPropertyChangedSignal("Value"):Connect(function()
  local current=value.Value; local delta=current*previous:Inverse(); train:PivotTo(current)
  for _,p in ipairs(Players:GetPlayers()) do
   if p:GetAttribute("OnLastTrain") then local character=p.Character; local root=character and character:FindFirstChild("HumanoidRootPart"); local h=character and character:FindFirstChildWhichIsA("Humanoid")
    if root and h and h.Health>0 then character:PivotTo(delta*character:GetPivot()) end
   end
  end
  previous=current
 end)
 local tween=TweenService:Create(value,TweenInfo.new(14,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Value=target})
 tween:Play(); tween.Completed:Wait(); connection:Disconnect(); value:Destroy()
 station=math.min(station+1,#GameConfig.Stations); world:SetAttribute("Station",station)
 Workspace:SetAttribute("LastTrainStation",station); traveling=false; setDoors(true); broadcast()
end

-- Initial carriage is already docked at NEW MOON with its doors open.
setDoors(true); Workspace:SetAttribute("LastTrainStation",1); broadcast()
 for _,anchor in ipairs(objectiveFolder:GetChildren()) do
 local p=anchor:FindFirstChildOfClass("ProximityPrompt")
 if p then p.Triggered:Connect(function(player)
  if anchor.Name:match("^BoardTrain_") then
   local requiredStation=anchor:GetAttribute("StationIndex")
   local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
   if not traveling and requiredStation==station and root and (root.Position-anchor.Position).Magnitude<=p.MaxActivationDistance+4 then boardPlayer(player) end
   return
  end
  if completed or traveling or anchor:GetAttribute("ObjectiveStage")~=stage then return end
  local character=player.Character; local root=character and character:FindFirstChild("HumanoidRootPart"); local humanoid=character and character:FindFirstChildWhichIsA("Humanoid")
  if not root or not humanoid or humanoid.Health<=0 or (root.Position-anchor.Position).Magnitude>p.MaxActivationDistance+4 then return end
  if stage==5 then choice=anchor:GetAttribute("Choice") end
  if stage==6 then
   local endingKey=anchor:GetAttribute("Ending")
   if endingKey=="Station08" and choice~="Records" then objectiveEvent:FireClient(player,stage,"需要先找到終寂站的事故紀錄，封存系統才會解鎖。",false,GameConfig.Stations[station].Name,storyFor(station)); return end
   completed=true; Workspace:SetAttribute("LastTrainRoundStage",stage); Profiles.AwardCoins(player,GameConfig.ObjectiveRewards[stage+1] or 0)
   objectiveEvent:FireAllClients(stage,GameConfig.Endings[endingKey] or "旅程結束。",true,GameConfig.Stations[station].Name,storyFor(station),endingKey); return
  end
  stage+=1; Workspace:SetAttribute("LastTrainRoundStage",stage); Profiles.AwardCoins(player,GameConfig.ObjectiveRewards[stage] or 0)
  if stage==5 then choice=anchor:GetAttribute("Choice") or choice end
  broadcast()
  task.spawn(moveToNextStation)
 end) end
end
for _,anchor in ipairs(train:GetDescendants()) do
 if anchor:GetAttribute("PromptType")=="Disembark" then
  local p=anchor:FindFirstChildOfClass("ProximityPrompt")
  if p then p.Triggered:Connect(function(player)
   if traveling or not player:GetAttribute("OnLastTrain") then return end
   local character=player.Character; local humanoid=character and character:FindFirstChildWhichIsA("Humanoid")
   if not character or not humanoid or humanoid.Health<=0 then return end
   local platformCFrame=train:GetPivot()*CFrame.new(0,-2,-16)
   character:PivotTo(platformCFrame); player:SetAttribute("OnLastTrain",false)
  end) end
 end
end
-- Carriage memories are optional, one-time story interactions per player.
for _,item in ipairs(train:GetDescendants()) do
 local promptObject=item:FindFirstChildOfClass("ProximityPrompt")
 local key=item:GetAttribute("NarrativeKey")
 if promptObject and key then promptObject.Triggered:Connect(function(player)
  if traveling or not player:GetAttribute("OnLastTrain") then return end
  local character=player.Character; local root=character and character:FindFirstChild("HumanoidRootPart")
  local humanoid=character and character:FindFirstChildWhichIsA("Humanoid")
  if not root or not humanoid or humanoid.Health<=0 or (root.Position-item.Position).Magnitude>promptObject.MaxActivationDistance+4 then return end
  local playerKey="Read_"..key
  if player:GetAttribute(playerKey) then return end
  player:SetAttribute(playerKey,true)
  objectiveEvent:FireClient(player,stage,item:GetAttribute("NarrativeText") or "車廂裡留下了一段記憶。",false,"列車記憶",item:GetAttribute("NarrativeText") or "")
 end) end
end
Players.PlayerAdded:Connect(function(player)
 task.delay(2,function() if player.Parent then local d=GameConfig.Stations[station]; objectiveEvent:FireClient(player,stage,GameConfig.Objectives[math.min(stage+1,#GameConfig.Objectives)],completed,d and d.Name or "",storyFor(station)) end end)
end)
