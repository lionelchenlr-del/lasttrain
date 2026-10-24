-- Use the normal prompt input path, including its hold duration and server
-- distance checks. This local driver exists only in the disposable test place.
local RunService=game:GetService("RunService")
assert(RunService:IsStudio(),"Studio only")
local W=workspace:WaitForChild("LastTrainWorld")
local ack=game.ReplicatedStorage:WaitForChild("StoryTestAck")
game.ReplicatedStorage.LastTrain.Remotes:WaitForChild("TicketUpdate").OnClientEvent:Connect(function(data)
 if data.Anomaly then
  task.delay(.15,function()
   local text=data.Screen.ReaderDisplay.StatusText
   ack:FireServer("Anomaly",text.Text=="你已於二十年前進站")
  end)
  task.delay(1.5,function()
   local text=data.Screen.ReaderDisplay.StatusText
   ack:FireServer("AnomalyCleared",string.find(text.Text,"驗票成功",1,true)~=nil)
  end)
 end
end)
game.ReplicatedStorage.LastTrain.Remotes.ObjectiveUpdate.OnClientEvent:Connect(function(_,_,completed,_,_,ending)
 if completed and ending then
  ack:FireServer("Ending",ending)
  task.spawn(function()
   local player=game.Players.LocalPlayer
   local gui=player.PlayerGui:WaitForChild("EndingCinema",10)
   local deadline=os.clock()+10
   repeat task.wait(.05) until gui:GetAttribute("State")=="Playing" or os.clock()>deadline
   assert(gui:GetAttribute("State")=="Playing","Movie never started")
   local root=player.Character.HumanoidRootPart
   local train=W.Props.LastTrainCar
   local frame=train:GetPivot();local position=root.Position
   assert(workspace.CurrentCamera.CameraType==Enum.CameraType.Scriptable,"Movie camera not scripted")
   assert(player:GetAttribute("LastTrainCinematic"),"Movie did not own input")
   print("LASTTRAIN_CINEMA_STARTED",ending)
   local view=workspace.CurrentCamera.CFrame
   task.wait(7)
   assert((workspace.CurrentCamera.CFrame.Position-view.Position).Magnitude>2,"Movie camera did not animate")
   print("LASTTRAIN_CINEMA_VIEW",ending)
   deadline=os.clock()+15
   repeat task.wait(.1) until gui:GetAttribute("State")=="Card" or os.clock()>deadline
   assert(gui:GetAttribute("State")=="Card","Movie did not reach ending card")
   assert(not player:GetAttribute("LastTrainCinematic"),"Movie did not release input")
   local camera=workspace.CurrentCamera;local kind=camera.CameraType;local fov=camera.FieldOfView
   gui.Action:Fire("Replay");task.wait(.2)
   assert(gui:GetAttribute("State")=="Playing" and player:GetAttribute("LastTrainCinematic"),"Replay failed")
   gui.Action:Fire("Skip");task.wait(.1)
   assert(gui:GetAttribute("State")=="Playing","Early skip bypassed two second guard")
   task.wait(2.1);gui.Action:Fire("Skip");task.wait(.1)
   assert(gui:GetAttribute("State")=="Card" and not player:GetAttribute("LastTrainCinematic"),"Skip did not clean up")
   gui.Action:Fire("Close");task.wait(.1)
   assert(not gui.Enabled and gui:GetAttribute("State")=="Closed","Return failed")
   assert(not workspace:FindFirstChild("LastTrainEndingSet"),"Movie scenery leaked")
   assert(camera.CameraType==kind and camera.FieldOfView==fov,"Camera not restored")
   assert((train:GetPivot().Position-frame.Position).Magnitude<.001,"Movie moved real train")
   assert((root.Position-position).Magnitude<.001,"Movie moved real character")
   print("LASTTRAIN_CINEMA_ALL_PASS",ending,"natural end; replay; skip; return; no train/player drift")
   ack:FireServer("Cinema",ending)
  end)
 end
end)
local puzzleState=nil
local puzzleRemotes=game.ReplicatedStorage.LastTrain.Remotes
puzzleRemotes:WaitForChild("PlatformChallengeUpdate").OnClientEvent:Connect(function(state)
 if state.closed then puzzleState=nil else puzzleState=state end
end)
local function ask(action,value,origin,direction)
 assert(puzzleState,"No puzzle session for "..action)
 local result=puzzleRemotes.PlatformChallengeRequest:InvokeServer(puzzleState.token,action,value,origin,direction)
 if result.ok and not result.closed then puzzleState=result end
 return result
end
local function solvePuzzle(name)
 local puzzleNames={PassengerLedger=true,TrueRecording=true,MirrorReport=true,CCTVEvidence=true,TrustConductor=true,ReadAccidentLog=true,LeaveEnding=true,TruthEnding=true,SecretEnding=true}
 if not puzzleNames[name] then return end
 local deadline=os.clock()+10
 while not puzzleState and os.clock()<deadline do task.wait(.05) end
 assert(puzzleState,"Puzzle did not open: "..name)
 local index=puzzleState.station
 if index==2 then
  local r=ask("Passenger",1);assert(not r.closed and r.count==3,"Wrong passenger advanced")
  task.wait(.25);assert(ask("Passenger",3).closed,"Correct passenger failed")
 elseif index==3 then
  task.wait(3.5)
  local sequence=table.clone(puzzleState.sequence)
  local wrong=ask("Signal",sequence[1]%3+1);assert(wrong.progress==0,"Wrong signal advanced")
  for _,signal in ipairs(sequence) do task.wait(.25);ask("Signal",signal) end
 elseif index==4 then
  local camera=workspace.CurrentCamera;local target=W.Props.MirrorWitnessTarget
  camera.CameraType=Enum.CameraType.Scriptable
  camera.CFrame=CFrame.lookAt(W.Objectives.MirrorReport.Position+Vector3.new(0,2,3),target.Position)
  task.wait(3)
  local r=ask("Photo",nil,camera.CFrame.Position,camera.CFrame.LookVector)
  assert(r.closed,"Aligned real camera did not finish photo: "..tostring(r.message))
 elseif index==5 then
  local wrong=ask("Evidence");assert(not wrong.closed,"Wrong CCTV frame advanced")
  task.wait(.25);ask("Camera",2);task.wait(.25);ask("Frame",3)
  print("LASTTRAIN_PLATFORM_VIEW CCTV camera2 time23:47")
  task.wait(3);assert(ask("Evidence").closed,"Correct CCTV evidence rejected")
 elseif index==6 then
  if not puzzleState.ready then local wrong=ask("Choice","Records");assert(not wrong.closed,"Unpowered circuit advanced") end
  local targets={1,3,2}
  for i=1,3 do while puzzleState.dials[i]~=targets[i] do task.wait(.25);ask("Dial",i) end end
  task.wait(.25);assert(ask("Choice",name=="TrustConductor" and "Conductor" or "Records").closed,"Powered branch rejected")
 elseif index==7 then
  local centers={.25,.65,.45}
  while (puzzleState.progress or 0)<3 do
   local wanted=centers[puzzleState.progress+1]
   repeat task.wait(.05) until math.abs(((workspace:GetServerTimeNow()-puzzleState.epoch)%4)/4-wanted)<.04
   ask("Stabilize")
  end
  task.wait(.25)
  local ending=name=="TruthEnding" and "Truth" or name=="SecretEnding" and "Station08" or "Conductor"
  local secretAllowed=puzzleState.secret
  local result=ask("Ending",ending)
  if ending=="Station08" and not secretAllowed then assert(not result.closed,"Secret ending bypassed record requirement") else assert(result.closed,"Ending puzzle rejected") end
 end
 print("LASTTRAIN_PLATFORM_PUZZLE_PASS",index,name)
end
local last=nil
local function input()
 local token=workspace:GetAttribute("StoryTestToken")
 if not token or token==last then return end
 last=token
 local name=workspace:GetAttribute("StoryTestPrompt")
 if name=="DrinkTea" then
  local pl=game.Players.LocalPlayer;local tool=pl.Backpack:WaitForChild("皇家茶飲")
  pl.Character.Humanoid:EquipTool(tool);task.wait(.5);tool:Activate();task.wait(.5)
  ack:FireServer("Input",token);return
 end
 local anchor
 if name:sub(1,5)=="Seat:" then
  for _,seat in ipairs(W.Props.LastTrainCar:GetDescendants()) do
   if seat:IsA("Seat") and seat:GetAttribute("RequiredPass")==name:sub(6) and seat:GetAttribute("SeatNumber")==workspace:GetAttribute("StoryTestSeatNumber") then anchor=seat;break end
  end
 elseif name=="RoyalTea" then
  for _,part in ipairs(W.Props.LastTrainCar:GetDescendants()) do if part:GetAttribute("RoyalFacility")=="TeaBar" then anchor=part;break end end
 else anchor=W:WaitForChild("Objectives"):WaitForChild(name) end
 assert(anchor,"Test prompt anchor missing: "..name)
 local premium=game.Players.LocalPlayer.PlayerGui:FindFirstChild("LastTrainPremiumShop")
 if premium then premium.PremiumPanel.Visible=false end
 local prompt=anchor:WaitForChild("ProximityPrompt")
 -- A neighboring Seat prompt otherwise competes for the same keyboard key.
 -- Aim at the target as a player would before using the normal hold input.
 prompt.Exclusivity=Enum.ProximityPromptExclusivity.AlwaysShow
 workspace.CurrentCamera.CameraType=Enum.CameraType.Scriptable
 workspace.CurrentCamera.CFrame=CFrame.lookAt(prompt.Parent.Position+(anchor:IsA("Seat") and Vector3.new(2,2,0) or Vector3.new(0,2,4)),prompt.Parent.Position)
 task.wait(1)
 prompt:InputHoldBegin(); task.wait(prompt.HoldDuration+.3); prompt:InputHoldEnd()
 solvePuzzle(name)
 print("LASTTRAIN_STORY_CLIENT_INPUT",name)
 ack:FireServer("Input",token)
end
workspace:GetAttributeChangedSignal("StoryTestToken"):Connect(function() task.spawn(input) end)
input()
