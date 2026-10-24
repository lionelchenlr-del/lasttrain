-- Disposable real-player physics test. Run with Test, not Run.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
assert(RunService:IsStudio())
local previewAck=Instance.new("RemoteEvent");previewAck.Name="MotionPreviewAck";previewAck.Parent=game.ReplicatedStorage
local previews={}
previewAck.OnServerEvent:Connect(function(player,name) previews[name]=player end)
local W=workspace:WaitForChild("LastTrainWorld")
while not W:GetAttribute("Ready") do task.wait(.1) end
local Operations=require(game.ServerScriptService.LastTrain.TrainOperations)
local train=W.Props.LastTrainCar
local op=Operations.new(train)
while #Players:GetPlayers()==0 do task.wait(.1) end
local p=Players:GetPlayers()[1]
while not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") do task.wait(.1) end
task.wait(2)
local c=p.Character; local h=c:FindFirstChildWhichIsA("Humanoid"); local root=c.HumanoidRootPart
root.Anchored=false
c:PivotTo(Operations.Frame(train)*CFrame.new(-50,3.2,0))
root.AssemblyLinearVelocity=Vector3.zero
workspace:SetAttribute("MotionPlayerPhase","Walking")
task.wait(1)
local initial=train:GetPivot()
local samples,minX,maxX=0,1e9,-1e9
local failure=nil
local watching=RunService.Heartbeat:Connect(function()
 if op.Moving then
  local pos=Operations.Frame(train):PointToObjectSpace(root.Position)
  samples+=1; minX=math.min(minX,pos.X); maxX=math.max(maxX,pos.X)
  if h.SeatPart then failure="Passing a chair caused automatic sitting" end
  if (train:GetPivot().Position-initial.Position).Magnitude>.0001 then failure="Passenger train moved during visual travel" end
  if h.Health<=0 or pos.Y<1 or pos.Y>7 or math.abs(pos.Z)>4 then failure="Real player left floor: "..tostring(pos) end
 end
end)
op:SetDoors(false,true)
op:Move(2800,42)
workspace:SetAttribute("MotionPlayerPhase","Stop")
watching:Disconnect()
assert(not failure,failure)
assert(samples>300,"Not enough real physics samples")
assert(maxX-minX>65,"Walking did not traverse connected carriages")
assert(Operations.Contains(train,c),"Real player stranded after arrival")
print("LASTTRAIN_REAL_WALK_PASS",samples,minX,maxX,"unanchored client-owned player; normal Humanoid movement")
op:SetDoors(true); task.wait(1); op:SetDoors(false)
local seat=train:FindFirstChild("PassengerSeat",true)
c:PivotTo(seat.CFrame*CFrame.new(0,2,0)); seat:Sit(h)
task.wait(.5)
assert(h.SeatPart==seat,"Real player did not sit")
workspace:SetAttribute("MotionPlayerPhase","Seated")
op:Move(2800,15)
assert(h.SeatPart==seat and (root.Position-seat.Position).Magnitude<5,"Real seated player detached")
print("LASTTRAIN_REAL_SEAT_PASS")
for _,name in ipairs({"RoyalCarriage","StarTrain","Close"}) do
 workspace:SetAttribute("MotionPlayerPhase","Preview:"..name)
 local deadline=os.clock()+20
 repeat task.wait(.1) until previews[name]==p or os.clock()>deadline
 assert(previews[name]==p,"Full preview failed: "..name)
 assert(h.SeatPart==seat,"Preview clone stole original seat weld")
 assert((train:GetPivot().Position-initial.Position).Magnitude==0,"Preview moved passenger train")
 assert((root.Position-seat.Position).Magnitude<5,"Preview moved the seated player")
end
print("LASTTRAIN_FULL_PREVIEW_PASS royal/galaxy; original seat and passenger train unchanged")

h.Sit=false
local weld=seat:FindFirstChild("SeatWeld");if weld then weld:Destroy() end
c:PivotTo(Operations.Frame(train)*CFrame.new(0,3.2,0)); task.wait(.3)
assert(h.SeatPart==nil,"Real player cannot leave seat")
op:SetDoors(true)
-- Exercise the normal respawn script during a visual journey.
op:SetDoors(false)
workspace:SetAttribute("LastTrainTraveling",true)
local oldCharacter=c
local finished=false
task.spawn(function() op:Move(2800,9);finished=true end)
task.wait(1);h.Health=0
local deadline=os.clock()+7
repeat task.wait(.1) until (p.Character and p.Character~=oldCharacter and p.Character:FindFirstChild("HumanoidRootPart")) or os.clock()>deadline
assert(p.Character and p.Character~=oldCharacter,"Travel respawn failed")
task.wait(.5)
assert(Operations.Contains(train,p.Character),"Travel respawn stranded player on inactive platform")
while not finished do task.wait(.1) end
workspace:SetAttribute("LastTrainTraveling",false)
op:SetDoors(true)
print("LASTTRAIN_REAL_TRAVEL_RESPAWN_PASS")
print("LASTTRAIN_REAL_PLAYER_ALL_PASS")
workspace:SetAttribute("MotionPlayerPhase","Finished")
