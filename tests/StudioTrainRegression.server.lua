-- Run only in a temporary Studio test place, never installed in the shipped game.
local RunService=game:GetService("RunService")
assert(RunService:IsStudio(),"Studio-only regression fixture")
local W=workspace:WaitForChild("LastTrainWorld")
while not W:GetAttribute("Ready") do task.wait(.1) end
local Config=require(game.ReplicatedStorage.LastTrain.Shared.GameConfig)
local Operations=require(game.ServerScriptService.LastTrain.TrainOperations)
local train=W.Props.LastTrainCar
local op=Operations.new(train)
local Safety=require(game.ServerScriptService.LastTrain.RouteSafety)
local tests=0
local function check(ok,message)
 assert(ok,message); tests+=1
end
local function rig(name,position,anchored)
 local model=Instance.new("Model"); model.Name=name
 local root=Instance.new("Part"); root.Name="HumanoidRootPart"; root.Size=Vector3.new(2,2,1)
 root.CFrame=CFrame.new(position); root.Anchored=anchored; root.CanCollide=false; root.Parent=model
 local torso=root:Clone(); torso.Name="Torso"; torso.Anchored=false; torso.Parent=model
 local head=root:Clone(); head.Name="Head"; head.Size=Vector3.new(2,1,1); head.Anchored=false; head.CFrame=root.CFrame*CFrame.new(0,1.5,0); head.Parent=model
 local neck=Instance.new("Motor6D"); neck.Name="Neck"; neck.Part0=torso; neck.Part1=head; neck.C0=CFrame.new(0,1.5,0); neck.Parent=torso
 local joint=Instance.new("Motor6D"); joint.Name="RootJoint"; joint.Part0=root; joint.Part1=torso; joint.Parent=root
 local h=Instance.new("Humanoid"); h.RequiresNeck=false; h.Parent=model
 model.PrimaryPart=root; model.Parent=workspace
 return model,h
end
for station=1,#Config.Stations do
 local x=(station-1)*Config.StationSpacing
 check(not Safety.ShouldRecover(Vector3.new(x,3,-22),false,station,Config),"Valid platform rejected")
 check(Safety.ShouldRecover(Vector3.new(x+230,3,-22),false,station,Config),"Walking past platform allowed")
 check(Safety.ShouldRecover(Vector3.new(x+500,3,Config.TrainCenterZ),false,station,Config),"Tunnel traversal allowed")
 check(Safety.ShouldRecover(Vector3.new(x,-10,-22),false,station,Config),"Falling not recovered")
 if station<#Config.Stations then
  check(not Safety.ShouldRecover(Vector3.new(x+500,3,Config.TrainCenterZ),true,station,Config),"Valid moving rider rejected")
  check(Safety.ShouldRecover(Vector3.new(x+Config.StationSpacing,3,-22),false,station,Config),"Skipping station allowed")
 end
end
local seats={}
local glazing=0
for _,part in ipairs(train:GetDescendants()) do
 if part:IsA("Seat") then table.insert(seats,part) end
 if part.Name=="PanoramicWindowBand" then check(part.Transparency>=.65,"Opaque passenger glass") end
 if part.Name=="BogieWheel" then
  local z=part.Position.Z
  check(math.abs(math.abs(z-Config.TrainCenterZ)-Config.TrackHalfGauge)<.001,"Wheel gauge mismatch")
  check(math.abs(part.Position.Y-.675-Config.RailTop)<.001,"Wheel not resting on rail")
 end
 if part:GetAttribute("CabGlazing") then glazing+=1 end
end
check(glazing>=200,"Dark cab glazing missing")
check(#seats>=32,"Missing usable seats")
check(Config.StationSpacing>=2800 and Config.TravelDuration>=40,"Route too short")
local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Include
params.FilterDescendantsInstances={train}; params.RespectCanCollide=true
check(not workspace:Raycast(Vector3.new(-25,3.5,Config.TrainCenterZ),Vector3.new(120,0,0),params),"Aisle obstruction")
for _,x in ipairs({4.9,5.1,64.9,65.1}) do
 check(workspace:Raycast(Vector3.new(x,2,Config.TrainCenterZ),Vector3.new(0,-5,0),params)~=nil,"Missing seam floor")
 check(workspace:Raycast(Vector3.new(x,3,Config.TrainCenterZ),Vector3.new(0,10,0),params)~=nil,"Missing seam ceiling")
end
local function checkConnections()
 local frame=Operations.Frame(train)
 for _,jointX in ipairs({5,65}) do
  for _,z in ipairs({-3,0,3}) do
   for _,dx in ipairs({-3.2,-2.6,-.1,0,.1,2.6,3.2}) do
    local start=frame:PointToWorldSpace(Vector3.new(jointX-35+dx,2,z))
    local floor=workspace:Raycast(start,Vector3.new(0,-3,0),params)
    check(floor~=nil,"Connection floor gap")
    check(math.abs(floor.Position.Y-frame.Position.Y-.1)<.015,"Connection collision floor step")
   end
   local start=frame:PointToWorldSpace(Vector3.new(jointX-35-3,3.5,z))
   check(not workspace:Raycast(start,frame:VectorToWorldSpace(Vector3.new(6,0,0)),params),"Connection passage obstructed")
  end
  for _,side in ipairs({-1,1}) do
   local start=frame:PointToWorldSpace(Vector3.new(jointX-35,3.5,0))
   check(workspace:Raycast(start,frame:VectorToWorldSpace(Vector3.new(0,0,side*5)),params)~=nil,"Connection side wall missing")
  end
 end
end
checkConnections()
local visible=RaycastParams.new(); visible.FilterType=Enum.RaycastFilterType.Include
visible.FilterDescendantsInstances={train}
-- Trace the actual generated shell, independently of the shape function.
-- Include only cab parts so a body panel cannot hide a hole in the transition.
for _,cab in ipairs({{train.RearCarriage,"Rear",-34,-1},{train.FrontCarriage,"Front",104,1}}) do
 local surfaces={}
 for _,p in ipairs(cab[1]:GetChildren()) do
  if p:IsA("BasePart") and p:GetAttribute("CabEnd")==cab[2] then table.insert(surfaces,p) end
 end
 local filter=RaycastParams.new(); filter.FilterType=Enum.RaycastFilterType.Include
 filter.FilterDescendantsInstances=surfaces
 for _,dx in ipairs({-.3,0,.3,.8,1.5,2.5,4,5.5}) do
  for i=0,31 do
   local a=(i+.37)*math.pi/16
   local start=Vector3.new(cab[3]+cab[4]*dx,3.9,Config.TrainCenterZ)
   local ray=Vector3.new(0,math.sin(a),math.cos(a))*12
   check(workspace:Raycast(start,ray,filter)~=nil,"Cab transition shell opening")
  end
 end
 for i=0,31 do
  local a=(i+.37)*math.pi/16
  local start=Vector3.new(cab[3]-cab[4]*2,3.9+2.8*math.sin(a),Config.TrainCenterZ+3.8*math.cos(a))
  local hit=workspace:Raycast(start,Vector3.new(cab[4]*3,0,0),filter)
  check(hit and hit.Instance.Name=="CabRootSeal_"..cab[2],"Unsealed cab root")
 end
end
local function setDoorsChecked(open)
 local samples=0
 local fault=nil
 local overlap=OverlapParams.new(); overlap.FilterType=Enum.RaycastFilterType.Include
 overlap.FilterDescendantsInstances={train}
 local connection=RunService.Heartbeat:Connect(function()
  samples+=1
  for _,door in ipairs(op.Doors) do
   local p=door.Part
   local localPose=train:GetPivot():ToObjectSpace(p.CFrame)
   if math.abs(localPose.Y-door.Closed.Y)>.005 or math.abs(localPose.Z-door.Closed.Z)>.005 then fault="Door left its track" end
   if p.Material~=Enum.Material.SmoothPlastic or math.abs(p.Transparency-.58)>.001 then fault="Unstable door glazing" end
   for _,fixed in ipairs(workspace:GetPartsInPart(p,overlap)) do
    if fixed~=p and fixed.Name~="SlidingDoor" and fixed.Transparency<.95 and fixed.Position.Y>.3 then
     fault="Door intersects fixed trim: "..fixed.Name
    end
   end
  end
 end)
 local ok,err=pcall(function() op:SetDoors(open) end)
 connection:Disconnect()
 check(ok,"Door operation failed: "..tostring(err))
 check(samples>2,"Door animation not observed")
 check(fault==nil,fault or "Door rendering clearance")
end
for _,p in ipairs(train:GetDescendants()) do
 if p.Name=="GangwayCeilingLight" then
  local hit=workspace:Raycast(p.Position-Vector3.new(0,.8,0),Vector3.new(0,.9,0),visible)
  check(hit and hit.Instance==p,"Gangway light hidden above ceiling")
 end
 if p.Name=="PassengerSeat" then
  check(p:FindFirstChildWhichIsA("ProximityPrompt")~=nil,"Seat prompt missing after finishing")
 end
end
for _,entry in ipairs({{train.RearCarriage,"01 / 03"},{train,"02 / 03"},{train.FrontCarriage,"03 / 03"}}) do
 for _,p in ipairs(entry[1]:GetChildren()) do
  if p.Name=="CoachNumberDisplay" then
   local gui=p:FindFirstChildWhichIsA("SurfaceGui")
   check(gui and string.find(gui.TextLabel.Text,entry[2],1,true)~=nil,"Coach number overwritten by parent")
  end
 end
end
for _,rail in ipairs(W.Geometry:GetChildren()) do
 if rail.Name=="ContinuousRail" then
  check(math.abs(math.abs(rail.Position.Z-Config.TrainCenterZ)-Config.TrackHalfGauge)<.001,"Rail gauge mismatch")
  check(math.abs(rail.Position.Y+rail.Size.Y/2-Config.RailTop)<.001,"Rail height mismatch")
 end
 if rail:IsA("BasePart") then check(rail.Size.X<=512.01,"Route segment truncated") end
end
local standing=rig("StandingPassenger",Vector3.new(35,3.2,Config.TrainCenterZ),true)
local seated,h=rig("SeatedPassenger",seats[1].Position+Vector3.new(0,2,0),false)
seats[1]:Sit(h); task.wait(.4)
check(h.SeatPart==seats[1],"Seat did not attach humanoid")
check(Operations.Contains(train,seated),"Seated rider not aboard")
local initial=train:GetPivot()
-- Six stops, return, then repeat the full route: doors must remain local each time.
for cycle=1,2 do
 for stop=1,6 do
  setDoorsChecked(false)
  local before=standing:GetPivot().Position
  op:Move(Config.StationSpacing,.7,{standing,seated})
  task.wait(.15)
  check(math.abs(standing:GetPivot().Position.X-before.X-Config.StationSpacing)<.05,"Standing rider slipped")
  check(h.SeatPart==seats[1],"Seat detached during motion")
  check((seated.HumanoidRootPart.Position-seats[1].Position).Magnitude<5,"Seated rider did not move")
  setDoorsChecked(true)
  checkConnections()
  for _,door in ipairs(op.Doors) do
   local expected=train:GetPivot()*(door.Part:GetAttribute("Side")==-1 and door.Open or door.Closed)
   check((door.Part.Position-expected.Position).Magnitude<.02,"Door detached after arrival")
  end
  print("LASTTRAIN_REGRESSION_STOP_PASS",cycle,stop)
 end
 setDoorsChecked(false)
 op:Move(-Config.StationSpacing*6,1,{standing,seated})
 check((train:GetPivot().Position-initial.Position).Magnitude<.02,"Return drift")
end
setDoorsChecked(true)
h.Sit=false
local weld=seats[1]:FindFirstChild("SeatWeld"); if weld then weld:Destroy() end
seated:PivotTo(Operations.Frame(train)*CFrame.new(0,3.2,0)); task.wait(.15)
check(h.SeatPart==nil,"Cannot leave seat")
local roofIntruder=rig("RoofIntruder",Operations.Frame(train).Position+Vector3.new(0,12,0),true)
check(not Operations.Contains(train,roofIntruder),"Roof counted as carriage")
roofIntruder:Destroy()
standing:Destroy(); seated:Destroy()
print("LASTTRAIN_REGRESSION_ALL_PASS",tests,"assertions; two full routes; seated and standing riders; 12 arrivals")

-- Optional visual review: 12 seconds per view after all checks finish.
local camera=workspace.CurrentCamera
if camera then
 camera.CameraType=Enum.CameraType.Scriptable
 camera.FieldOfView=65
 for _,view in ipairs({
  {"Exterior",Vector3.new(-84,7.6,-23),Vector3.new(-12,3.8,-6.35)},
  {"Interior",Vector3.new(30,4.1,-6.35),Vector3.new(8,4.1,-6.35)},
  {"Gangway",Vector3.new(0,4.1,-6.35),Vector3.new(20,4.1,-6.35)},
  {"Rail contact",Vector3.new(-4,2.5,1.9),Vector3.new(14,-.8,-6.35)},
 }) do
  camera.CFrame=CFrame.lookAt(view[2],view[3])
  print("LASTTRAIN_VISUAL_VIEW",view[1]); task.wait(12)
 end
 camera.CFrame=CFrame.lookAt(Vector3.new(-92,7.6,-25),Vector3.new(-20,4,-6.35))
end
