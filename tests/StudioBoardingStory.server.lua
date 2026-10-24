-- Disposable fixture: keep the real RoundController and a real Studio client.
assert(game:GetService("RunService"):IsStudio(),"Studio only")
local Players=game:GetService("Players")
local W=workspace:WaitForChild("LastTrainWorld")
while not W:GetAttribute("Ready") do task.wait(.1) end
local Operations=require(game.ServerScriptService.LastTrain.TrainOperations)
local train=W.Props.LastTrainCar
local ack=Instance.new("RemoteEvent"); ack.Name="StoryTestAck"; ack.Parent=game.ReplicatedStorage
local inputAcks={}; local anomalyCount=0; local anomalyCorrect=false; local anomalyCleared=false
local player
ack.OnServerEvent:Connect(function(sender,kind,value)
 if sender~=player then return end
 if kind=="Input" then inputAcks[value]=true
 elseif kind=="Anomaly" then anomalyCount+=1; anomalyCorrect=value==true
 elseif kind=="AnomalyCleared" then anomalyCleared=value==true end
end)
local function untilTrue(predicate,message,timeout)
 local deadline=os.clock()+(timeout or 20)
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
root.Anchored=false
print("LASTTRAIN_STORY_ALL_PASS real client; personal ticket; reader; private anomaly; gate collision; respawn; station-2 waiting; closing exit; station 4 reached")
