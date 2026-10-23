-- Server-owned story progression and carriage movement. Prompts are validated
-- here, and only the server awards currency or advances the train.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Operations=require(script.Parent:WaitForChild("TrainOperations"))
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
local operations=Operations.new(train)

local function storyFor(index) return GameConfig.Stations[index] and GameConfig.Stations[index].Story or "" end
local function broadcast(endingKey)
 local data=GameConfig.Stations[station]
 objectiveEvent:FireAllClients(stage,GameConfig.Objectives[math.min(stage+1,#GameConfig.Objectives)],completed,data and data.Name or "",storyFor(station),endingKey)
end
local function setDoors(open,instant) operations:SetDoors(open,instant) end
local function updateDisplays(moving)
 local destination=GameConfig.Stations[math.min(station+(moving and 1 or 0),#GameConfig.Stations)]
 for _,part in ipairs(train:GetDescendants()) do
  if part.Name=="InteriorRouteDisplay" then
   for _,text in ipairs(part:GetDescendants()) do
    if text:IsA("TextLabel") then text.Text=(moving and "開往 " or "停靠 ")..destination.Name.."  •  "..destination.English end
   end
  end
 end
end
local function boardPlayer(player)
 local character=player.Character; local humanoid=character and character:FindFirstChildWhichIsA("Humanoid")
 if not character or not humanoid or humanoid.Health<=0 then return end
 character:PivotTo(Operations.Frame(train)*CFrame.new(-10,3.2,0)*CFrame.Angles(0,-math.pi/2,0)); player:SetAttribute("OnLastTrain",true)
end
-- Keep the ride state in sync with where the player is standing. This lets
-- players walk through the open doors and remain at a station when the train leaves.
RunService.Heartbeat:Connect(function()
 for _,p in ipairs(Players:GetPlayers()) do
  local character=p.Character; local root=character and character:FindFirstChild("HumanoidRootPart")
  if root then
   local aboard=Operations.Contains(train,character)
   p:SetAttribute("OnLastTrain",aboard)
  else p:SetAttribute("OnLastTrain",false) end
 end
end)
local function moveToNextStation()
 Workspace:SetAttribute("LastTrainTraveling",true)
 updateDisplays(true)
 objectiveEvent:FireAllClients(stage,"車門即將關閉，請遠離車門。",false,GameConfig.Stations[station].Name,storyFor(station))
 task.wait(2)
 setDoors(false)
 operations:Move(spacing,GameConfig.TravelDuration)
 station=math.min(station+1,#GameConfig.Stations); world:SetAttribute("Station",station)
 Workspace:SetAttribute("LastTrainStation",station)
 Workspace:SetAttribute("LastTrainTraveling",false)
 updateDisplays(false); setDoors(true); traveling=false; broadcast()
end

-- Initial carriage is already docked at NEW MOON with its doors open.
setDoors(true,true); Workspace:SetAttribute("LastTrainStation",1); Workspace:SetAttribute("LastTrainTraveling",false); updateDisplays(false); broadcast()
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
  traveling=true -- Lock before currency persistence or any other yielding work.
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
   if traveling or not Operations.Contains(train,player.Character) then return end
   local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
   if not root or (root.Position-anchor.Position).Magnitude>p.MaxActivationDistance+2 then return end
   local character=player.Character; local humanoid=character and character:FindFirstChildWhichIsA("Humanoid")
   if not character or not humanoid or humanoid.Health<=0 then return end
   local seat=humanoid.SeatPart
   humanoid.Sit=false
   local weld=seat and seat:FindFirstChild("SeatWeld"); if weld then weld:Destroy() end
   local platformCFrame=Operations.Frame(train)*CFrame.new(0,3.2,-16)
   character:PivotTo(platformCFrame); player:SetAttribute("OnLastTrain",false)
  end) end
 end
end
-- Carriage memories are optional, one-time story interactions per player.
for _,item in ipairs(train:GetDescendants()) do
 local promptObject=item:FindFirstChildOfClass("ProximityPrompt")
 local key=item:GetAttribute("NarrativeKey")
 if promptObject and key then promptObject.Triggered:Connect(function(player)
  if not Operations.Contains(train,player.Character) then return end
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

for _,seat in ipairs(train:GetDescendants()) do
 if seat:IsA("Seat") and seat.Name=="PassengerSeat" then
  local prompt=seat:FindFirstChildOfClass("ProximityPrompt")
  if prompt then
   seat:GetPropertyChangedSignal("Occupant"):Connect(function() prompt.Enabled=seat.Occupant==nil end)
   prompt.Triggered:Connect(function(player)
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local h=character and character:FindFirstChildWhichIsA("Humanoid")
    if not root or not h or h.Health<=0 or seat.Occupant or not Operations.Contains(train,character) then return end
    if (root.Position-seat.Position).Magnitude>prompt.MaxActivationDistance+1 then return end
    seat:Sit(h)
   end)
  end
 end
end
