-- Disposable fixture: keep the real RoundController and a real Studio client.
assert(game:GetService("RunService"):IsStudio(),"Studio only")
local Players=game:GetService("Players")
local W=workspace:WaitForChild("LastTrainWorld")
while not W:GetAttribute("Ready") do task.wait(.1) end
local Operations=require(game.ServerScriptService.LastTrain.TrainOperations)
local train=W.Props.LastTrainCar
local function untilTrue(predicate,message,timeout)
 local deadline=os.clock()+(timeout or 20)
 repeat if predicate() then return end; task.wait(.05) until os.clock()>deadline
 error(message)
end
untilTrue(function() return #Players:GetPlayers()>0 end,"Start with Test, not Run",60)
local player=Players:GetPlayers()[1]
untilTrue(function() return player.Character and player.Character:FindFirstChild("HumanoidRootPart") end,"No client character",30)
task.wait(2)
local character=player.Character
local root=character.HumanoidRootPart; root.Anchored=true
local function position(cf) character:PivotTo(cf); root.AssemblyLinearVelocity=Vector3.zero end
local function trigger(name)
 workspace:SetAttribute("StoryTestPrompt",name)
 workspace:SetAttribute("StoryTestToken",(workspace:GetAttribute("StoryTestToken") or 0)+1)
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
position(CFrame.new(24,3.2,-6.35)); trigger("TicketClue")
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
print("LASTTRAIN_STORY_ALL_PASS real client; actual prompts; station-2 waiting; reboarding; exit during closing; station 4 reached")
