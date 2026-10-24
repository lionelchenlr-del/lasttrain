-- Disposable fixture: keep the real RoundController and a real Studio client.
assert(game:GetService("RunService"):IsStudio(),"Studio only")
local Players=game:GetService("Players")
local W=workspace:WaitForChild("LastTrainWorld")
while not W:GetAttribute("Ready") do task.wait(.1) end
local Operations=require(game.ServerScriptService.LastTrain.TrainOperations)
local train=W.Props.LastTrainCar
local ack=Instance.new("RemoteEvent"); ack.Name="StoryTestAck"; ack.Parent=game.ReplicatedStorage
local inputAcks={}; local anomalyCount=0; local anomalyCorrect=false; local anomalyCleared=false
local endingSeen=nil
local cinemaSeen=nil
local player
ack.OnServerEvent:Connect(function(sender,kind,value)
 if sender~=player then return end
 if kind=="Cinema" then cinemaSeen=value
 elseif kind=="Ending" then endingSeen=value
 elseif kind=="Input" then inputAcks[value]=true
 elseif kind=="Anomaly" then anomalyCount+=1; anomalyCorrect=value==true
 elseif kind=="AnomalyCleared" then anomalyCleared=value==true end
end)
local function untilTrue(predicate,message,timeout)
 local deadline=os.clock()+(timeout or 75)
 repeat if predicate() then return end; task.wait(.05) until os.clock()>deadline
 error(message)
end
untilTrue(function() return #Players:GetPlayers()>0 end,"Start with Test, not Run",60)
player=Players:GetPlayers()[1]
untilTrue(function() return player.Character and player.Character:FindFirstChild("HumanoidRootPart") end,"No client character",30)
task.wait(2)
local character=player.Character
local root=character.HumanoidRootPart; root.Anchored=true
local function position(cf) character:PivotTo(cf); root.AssemblyLinearVelocity=Vector3.zero end
local function trigger(name)
 workspace:SetAttribute("StoryTestPrompt",name)
 workspace:SetAttribute("StoryTestToken",(workspace:GetAttribute("StoryTestToken") or 0)+1)
 local token=workspace:GetAttribute("StoryTestToken")
 untilTrue(function() return inputAcks[token] end,"No client input acknowledgement: "..name)
end
local function atStation(index)
 untilTrue(function() return workspace:GetAttribute("LastTrainStation")==index and train:GetAttribute("DoorsOpen") and not workspace:GetAttribute("LastTrainTraveling") end,"Never docked at station "..index)
 task.wait(.2)
end
local function platformTask(name,stage)
 if name=="PassengerLedger" then
  for i=1,3 do local tag=W.Objectives["MissingLuggageTag"..i];position(CFrame.new(tag.Position+Vector3.new(0,1,2)));trigger(tag.Name) end
 end
 position(CFrame.new(W.Objectives[name].Position+Vector3.new(0,1,0)))
 trigger(name)
 untilTrue(function() return workspace:GetAttribute("LastTrainRoundStage")==stage end,"Objective not triggered: "..name)
end
local function board(index)
 local name="BoardTrain_"..index
 position(CFrame.new(W.Objectives[name].Position+Vector3.new(0,1,0)))
 trigger(name)
 untilTrue(function() return Operations.Contains(train,character) end,"Boarding prompt blocked while pending")
end
local config=require(game.ReplicatedStorage.LastTrain.Shared.GameConfig)
assert(math.abs(root.Position.X-config.FirstStationEntrySpawnX)<1,"New passenger did not spawn at ticket entrance")
local reader=W.Objectives.TicketReader_1
local gate=W.Props.FirstStationEntry.EntryGate1
position(CFrame.new(reader.Position+Vector3.new(0,1,0))); trigger("TicketReader_1")
assert(not player:GetAttribute("FirstStationValidated") and not gate:GetAttribute("Open"),"Reader accepted missing ticket")
print("LASTTRAIN_ENTRY_NO_TICKET_PASS")
position(CFrame.new(W.Objectives.TicketClue.Position+Vector3.new(0,1,0))); trigger("TicketClue")
untilTrue(function() return player:GetAttribute("FirstStationHasTicket") end,"Ticket not collected")
assert(not player:GetAttribute("FirstStationValidated"),"Collection bypassed reader")
trigger("TicketClue")
assert(workspace:GetAttribute("LastTrainRoundStage")==0,"Repeated ticket collection advanced story")
position(Operations.Frame(train)*CFrame.new(-10,3.2,0))
untilTrue(function() return root.Position.X< -120 end,"Unvalidated passenger remained aboard")
assert(not Operations.Contains(train,character) and workspace:GetAttribute("LastTrainRoundStage")==0,"Gate bypass advanced story")
print("LASTTRAIN_ENTRY_BYPASS_BLOCKED_PASS")
position(CFrame.new(reader.Position+Vector3.new(0,1,0))); trigger("TicketReader_1")
untilTrue(function() return player:GetAttribute("FirstStationValidated") and anomalyCleared end,"Validation or private anomaly failed")
assert(anomalyCount==1 and anomalyCorrect,"Private anomaly text incorrect")
assert(gate.ReaderScreen.ReaderDisplay.StatusText.Text=="感應車票\nTAP TO ENTER","Client anomaly changed shared server display")
trigger("TicketReader_1")
assert(anomalyCount==1 and gate:GetAttribute("Open"),"Rescan replayed anomaly or failed to open")
for _,p in ipairs(gate:GetChildren()) do if p.Name=="TicketGateLeaf" then assert(not p.CanCollide,"Open gate obstructs lane") end end
untilTrue(function() return not gate:GetAttribute("Open") end,"Gate never closed")
task.wait(.5)
for _,p in ipairs(gate:GetChildren()) do if p.Name=="TicketGateLeaf" then assert(p.CanCollide,"Closed gate has no collision") end end
print("LASTTRAIN_ENTRY_SCAN_ANOMALY_FLAPS_PASS")
local old=character
player:LoadCharacterAsync()
untilTrue(function() return player.Character and player.Character~=old and player.Character:FindFirstChild("HumanoidRootPart") end,"Respawn failed")
character=player.Character; root=character.HumanoidRootPart
task.wait(1.5); root.Anchored=true
assert(player:GetAttribute("FirstStationValidated") and player:GetAttribute("FirstStationHasTicket"),"Respawn lost ticket")
assert(root.Position.X> -120,"Validated respawn returned outside gate")
assert(workspace:GetAttribute("LastTrainRoundStage")==0,"Validation alone advanced first task")
print("LASTTRAIN_ENTRY_RESPAWN_PASS")
board(1)
untilTrue(function() return workspace:GetAttribute("LastTrainRoundStage")==1 end,"Ticket objective failed")
atStation(2)
platformTask("PassengerLedger",2)
local before=train:GetPivot()
task.wait(4)
assert(workspace:GetAttribute("LastTrainStation")==2,"Station 2 departed without passenger")
assert((train:GetPivot().Position-before.Position).Magnitude<.01,"Train moved while passenger on platform")
assert(train:GetAttribute("DoorsOpen"),"Doors closed on waiting passenger")
assert(not workspace:GetAttribute("LastTrainTraveling"),"Waiting train marked moving")
print("LASTTRAIN_STORY_PLATFORM_WAIT_PASS")
board(2); atStation(3)
print("LASTTRAIN_STORY_REBOARD_PROMPT_PASS")
platformTask("TrueRecording",3); board(3)
untilTrue(function() return not train:GetAttribute("DoorsOpen") end,"No closing animation")
position(CFrame.new(W.Objectives.TrueRecording.Position+Vector3.new(0,1,0)))
before=train:GetPivot()
untilTrue(function() return train:GetAttribute("DoorsOpen") end,"Doors did not reopen after passenger exited")
task.wait(1)
assert(workspace:GetAttribute("LastTrainStation")==3,"Closing-door exit left passenger behind")
assert((train:GetPivot().Position-before.Position).Magnitude<.01,"Closing-door exit did not cancel departure")
print("LASTTRAIN_STORY_CLOSING_EXIT_PASS")
board(3); atStation(4)
platformTask("MirrorReport",4); board(4); atStation(5)
platformTask("CCTVEvidence",5); board(5); atStation(6)
local branch=workspace:GetAttribute("StoryTestBranch") or "Records"
platformTask(branch=="Conductor" and "TrustConductor" or "ReadAccidentLog",6)
board(6); atStation(7)
local ending=workspace:GetAttribute("StoryTestEnding") or "Truth"
if branch=="Conductor" then
 position(CFrame.new(W.Objectives.SecretEnding.Position+Vector3.new(0,1,0)))
 trigger("SecretEnding"); task.wait(.4)
 assert(endingSeen==nil,"Secret ending unlocked without records")
 print("LASTTRAIN_STORY_SECRET_LOCK_PASS")
end
local prompt=ending=="Truth" and "TruthEnding" or ending=="Station08" and "SecretEnding" or "LeaveEnding"
position(CFrame.new(W.Objectives[prompt].Position+Vector3.new(0,1,0))); trigger(prompt)
untilTrue(function() return endingSeen==ending end,"Ending did not reach the real client: "..ending)
assert(workspace:GetAttribute("LastTrainStation")==7,"Ending skipped final station")
untilTrue(function() return cinemaSeen==ending end,"Ending cinema failed: "..ending,50)
local Profiles=require(game.ServerScriptService.LastTrain.ProfileService)
for _,key in ipairs({"LuxuryPass","RoyalCarriage"}) do
 local seat
 for _,candidate in ipairs(train:GetDescendants()) do
  if candidate:IsA("Seat") and candidate:GetAttribute("RequiredPass")==key then seat=candidate;break end
 end
 assert(seat,"Missing paid seat: "..key)
 workspace:SetAttribute("StoryTestSeatNumber",seat:GetAttribute("SeatNumber"))
 root.Anchored=false
 position(CFrame.new(seat.Position+Vector3.new(1.6,2,0)))
 trigger("Seat:"..key);task.wait(.3)
 assert(character.Humanoid.SeatPart==nil,"Unowned seat accepted: "..key)
 assert(Profiles.SetPass(player,key,true)) -- Fixture grant, never a purchase.
 task.wait(3.2) -- Native Seat has a reseat cooldown after a denied touch.
 trigger("Seat:"..key)
 untilTrue(function() return character.Humanoid.SeatPart==seat end,"Owned paid seat rejected: "..key)
 character.Humanoid.Sit=false
 local weld=seat:FindFirstChild("SeatWeld");if weld then weld:Destroy() end
 position(Operations.Frame(train)*CFrame.new(0,3.2,0));task.wait(.3)
 assert(Profiles.SetPass(player,key,false))
end
print("LASTTRAIN_PREMIUM_SEAT_PROMPTS_PASS rejected unowned; accepted owned; native prompt input")
root.Anchored=true
local bar
for _,part in ipairs(train:GetDescendants()) do if part:GetAttribute("RoyalFacility")=="TeaBar" then bar=part;break end end
assert(bar,"Missing tea facility")
position(CFrame.new(bar.Position+Vector3.new(0,1,2)))
trigger("RoyalTea");task.wait(.3)
assert(not player.Backpack:FindFirstChild("皇家茶飲"),"Unowned tea service accepted")
assert(Profiles.SetPass(player,"RoyalCarriage",true))
trigger("RoyalTea")
untilTrue(function() return player.Backpack:FindFirstChild("皇家茶飲")~=nil end,"Owned tea not delivered")
trigger("DrinkTea")
untilTrue(function() return not character:FindFirstChild("皇家茶飲") and not player.Backpack:FindFirstChild("皇家茶飲") end,"Tea did not consume")
assert(Profiles.SetPass(player,"RoyalCarriage",false))
print("LASTTRAIN_ROYAL_TEA_PASS rejected unowned; served and consumed with native client input")
root.Anchored=false
print("LASTTRAIN_STORY_ALL_PASS seven stations; ending",ending,"branch",branch)
