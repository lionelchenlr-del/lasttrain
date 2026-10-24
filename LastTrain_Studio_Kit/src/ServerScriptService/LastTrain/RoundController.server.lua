-- Server-owned story progression and carriage movement. Prompts are validated
-- here, and only the server awards currency or advances the train.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Operations=require(script.Parent:WaitForChild("TrainOperations"))
local DepartureGate=require(script.Parent:WaitForChild("DepartureGate"))
local FirstStationEntry=require(script.Parent:WaitForChild("FirstStationEntry"))
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
local departurePending=false
local boardingText=nil
local arrivedAt=os.clock()
local station=1
local spacing=GameConfig.StationSpacing
local PremiumAccess=require(script.Parent.PremiumAccess)
local operations=Operations.new(train)
local scenes=require(script.Parent.StationScenes).new(world,GameConfig)
local entry=FirstStationEntry.new(world,train,GameConfig,function(player,text)
 objectiveEvent:FireClient(player,stage,text,false,GameConfig.Stations[1].Name,"",nil,"Entry",1)
end)
local completeFirstBoarding

local function storyFor(index) return GameConfig.Stations[index] and GameConfig.Stations[index].Story or "" end
local function publish(text,story,endingKey,rideState)
 for _,player in ipairs(Players:GetPlayers()) do
  if station==1 and not entry:CanBoard(player,station) then
   entry:Notify(player)
  else
   objectiveEvent:FireClient(player,stage,text,completed,GameConfig.Stations[station].Name,story,endingKey,rideState,station)
  end
 end
end
local function broadcast(endingKey)
 publish(boardingText or GameConfig.Objectives[math.min(stage+1,#GameConfig.Objectives)],departurePending and "" or storyFor(station),endingKey,departurePending and "Boarding" or "Docked")
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
 if not entry:CanBoard(player,station) then entry:Notify(player); return end
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
   entry:Enforce(p)
   local aboard=Operations.Contains(train,character)
   p:SetAttribute("OnLastTrain",aboard)
   if aboard and station==1 and stage==0 and not departurePending and completeFirstBoarding and entry:CanBoard(p,station) then
    task.spawn(completeFirstBoarding,p)
   end
  else p:SetAttribute("OnLastTrain",false) end
 end
end)
local function moveToNextStation()
 local gate=DepartureGate.new(arrivedAt,GameConfig.MinimumStopDuration,GameConfig.DepartureCountdown)
 Workspace:SetAttribute("LastTrainBoardingPending",true)
 local lastMessage=nil
 local function readiness()
  return gate:Step(os.clock(),Players:GetPlayers(),function(p) return entry:CanBoard(p,station) and Operations.Contains(train,p.Character) end)
 end
 while true do
  local state=readiness()
  boardingText=state.State=="Countdown" and string.format("全員已上車，%d 秒後關門。",state.Seconds)
   or state.Ready and "車門即將關閉，請遠離車門。"
   or state.State=="Dwell" and "全員已上車，列車停站準備中。"
   or string.format("任務完成，請返回列車（已上車 %d / %d 人）。",state.Boarded,state.Total)
  Workspace:SetAttribute("LastTrainBoardedCount",state.Boarded)
  Workspace:SetAttribute("LastTrainPassengerCount",state.Total)
  if boardingText~=lastMessage then
   publish(boardingText,"",nil,state.State=="Countdown" and "Countdown" or "Boarding")
   lastMessage=boardingText
  end
  if state.Ready then
   traveling=true
   publish("全員已上車，車門關閉中。","",nil,"Closing")
   setDoors(false)
   -- Check real positions again after the door animation. Someone can walk
   -- out while it closes, die, respawn, or join during that animation.
   if readiness().Ready then break end
   gate:ResetCountdown()
   setDoors(true)
   traveling=false
   lastMessage=nil
  end
  task.wait(.15)
 end
 Workspace:SetAttribute("LastTrainBoardingPending",false)
 Workspace:SetAttribute("LastTrainTraveling",true)
 boardingText=nil
 updateDisplays(true)
 publish("列車開往下一站。","",nil,"Moving")
 scenes:Depart(station)
 operations:Move(spacing,GameConfig.TravelDuration)
 station=math.min(station+1,#GameConfig.Stations); world:SetAttribute("Station",station)
 scenes:Dock(station)
 Workspace:SetAttribute("LastTrainStation",station)
 Workspace:SetAttribute("LastTrainTraveling",false)
 arrivedAt=os.clock()
 updateDisplays(false); setDoors(true); traveling=false; departurePending=false; broadcast()
end

-- The first task now finishes by boarding after personal ticket validation,
-- including walking through the door. It has no shared collectible shortcut.
completeFirstBoarding=function(player)
 if station~=1 or stage~=0 or departurePending or traveling or player.Parent~=Players
  or not entry:CanBoard(player,station) or not Operations.Contains(train,player.Character) then return end
 departurePending=true; boardingText="進站任務完成，請等待所有乘客上車。"
 stage=1; Workspace:SetAttribute("LastTrainRoundStage",stage)
 Profiles.AwardCoins(player,GameConfig.ObjectiveRewards[1] or 0)
 broadcast(); task.spawn(moveToNextStation)
end

-- Initial carriage is already docked at NEW MOON with its doors open.
setDoors(true,true); Workspace:SetAttribute("LastTrainStation",1); Workspace:SetAttribute("LastTrainTraveling",false); updateDisplays(false); broadcast()
 for _,anchor in ipairs(objectiveFolder:GetChildren()) do
 local p=anchor:FindFirstChildOfClass("ProximityPrompt")
 if p then p.Triggered:Connect(function(player)
  if anchor:GetAttribute("PromptType")=="CollectTicket" or anchor:GetAttribute("PromptType")=="TicketReader" then return end
  if anchor.Name:match("^BoardTrain_") then
   local requiredStation=anchor:GetAttribute("StationIndex")
   local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
   if not traveling and train:GetAttribute("DoorsOpen") and requiredStation==station and root and (root.Position-anchor.Position).Magnitude<=p.MaxActivationDistance+4 then boardPlayer(player) end
   return
  end
  if completed or traveling or departurePending or anchor:GetAttribute("ObjectiveStage")~=stage then return end
  local character=player.Character; local root=character and character:FindFirstChild("HumanoidRootPart"); local humanoid=character and character:FindFirstChildWhichIsA("Humanoid")
  if not root or not humanoid or humanoid.Health<=0 or (root.Position-anchor.Position).Magnitude>p.MaxActivationDistance+4 then return end
  if stage==5 then choice=anchor:GetAttribute("Choice") end
  if stage==6 then
   local endingKey=anchor:GetAttribute("Ending")
   if endingKey=="Station08" and choice~="Records" then objectiveEvent:FireClient(player,stage,"需要先找到終寂站的事故紀錄，封存系統才會解鎖。",false,GameConfig.Stations[station].Name,storyFor(station)); return end
   completed=true; Workspace:SetAttribute("LastTrainRoundStage",stage); Profiles.AwardCoins(player,GameConfig.ObjectiveRewards[stage+1] or 0)
   objectiveEvent:FireAllClients(stage,GameConfig.Endings[endingKey] or "旅程結束。",true,GameConfig.Stations[station].Name,storyFor(station),endingKey,"Ending",station); return
  end
  departurePending=true -- Lock rewards/objectives while still allowing boarding.
  boardingText="任務完成，請所有乘客返回列車。"
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
 task.delay(2,function() if player.Parent then
  if station==1 and not entry:CanBoard(player,station) then entry:Notify(player); return end
  local d=GameConfig.Stations[station]; objectiveEvent:FireClient(player,stage,boardingText or GameConfig.Objectives[math.min(stage+1,#GameConfig.Objectives)],completed,d and d.Name or "",departurePending and "" or storyFor(station),nil,departurePending and "Boarding" or "Docked",station)
 end end)
end)

for _,seat in ipairs(train:GetDescendants()) do
 if seat:IsA("Seat") and seat.Name=="PassengerSeat" then
  local prompt=seat:FindFirstChildOfClass("ProximityPrompt")
  if prompt then
   seat:GetPropertyChangedSignal("Occupant"):Connect(function()
    local occupant=seat.Occupant
    prompt.Enabled=occupant==nil
    local required=seat:GetAttribute("RequiredPass")
    local owner=occupant and Players:GetPlayerFromCharacter(occupant.Parent)
    local state=owner and Profiles.GetState(owner)
    if required and owner and not PremiumAccess.Has(owner,required) then
     occupant.Sit=false
     local weld=seat:FindFirstChild("SeatWeld");if weld then weld:Destroy() end
    end
   end)
   prompt.Triggered:Connect(function(player)
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local h=character and character:FindFirstChildWhichIsA("Humanoid")
    if not root or not h or h.Health<=0 or seat.Occupant or not entry:CanBoard(player,station) or not Operations.Contains(train,character) then return end
    if (root.Position-seat.Position).Magnitude>prompt.MaxActivationDistance+1 then return end
    local required=seat:GetAttribute("RequiredPass")
    local state=Profiles.GetState(player)
    if required and not PremiumAccess.Has(player,required) then
     ReplicatedStorage.LastTrain.Remotes.PremiumNotice:FireClient(player,required=="RoyalCarriage" and "這是皇家專屬座位，可在精品商店預覽通行證。" or "這是商務專屬座位，可在精品商店預覽通行證。",required)
     return
    end
    seat:Sit(h)
   end)
  end
 end
end
