local P=game.Players.LocalPlayer
local previewAck=game.ReplicatedStorage:WaitForChild("MotionPreviewAck")
local W=workspace:WaitForChild("LastTrainWorld")
while not W:GetAttribute("Ready") do task.wait(.1) end
local train=W.Props.LastTrainCar
local controls=require(P.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
controls:Disable()
local direction=1
local samples,maxRelativeStep=0,0
local fixed=train:GetPivot()
local maximumTrainDrift=0
local previous=nil
local RunService=game:GetService("RunService")
RunService:BindToRenderStep("MotionTestWalk",Enum.RenderPriority.Input.Value+1,function()
 local c=P.Character; local h=c and c:FindFirstChildWhichIsA("Humanoid")
 local r=c and c:FindFirstChild("HumanoidRootPart")
 if not r or not h or not train.PrimaryPart then return end
 local frame=train:GetPivot()*train:GetAttribute("PassengerFrameOffset")
 local pos=frame:PointToObjectSpace(r.Position)
 if workspace:GetAttribute("MotionPlayerPhase")=="Walking" then
  if pos.X>50 then direction=-1 elseif pos.X< -50 then direction=1 end
  h:Move(frame:VectorToWorldSpace(Vector3.new(direction,0,math.clamp(-pos.Z,-.5,.5))),false)
  if previous then maxRelativeStep=math.max(maxRelativeStep,(pos-previous).Magnitude) end
  maximumTrainDrift=math.max(maximumTrainDrift,(train:GetPivot().Position-fixed.Position).Magnitude)
  samples+=1;previous=pos
 else h:Move(Vector3.zero,false) end
end)
workspace:GetAttributeChangedSignal("MotionPlayerPhase"):Connect(function()
 local phase=workspace:GetAttribute("MotionPlayerPhase")
 if phase and phase:sub(1,8)=="Preview:" then
  local name=phase:sub(9)
  P.PlayerGui:SetAttribute("FullPreviewProduct",name)
  task.wait(1)
  local clone=workspace:FindFirstChild("PremiumFullPreview")
  assert((name=="Close" and not clone) or (name~="Close" and clone),"Preview visibility incorrect")
  if clone then
   for _,d in ipairs(clone:GetDescendants()) do assert(not d:IsA("JointInstance") and not d:IsA("WeldConstraint"),"Preview retained external joint") end
  end
  previewAck:FireServer(name)
 end

 if phase=="Walking" then
  local c=P.Character; local h=c:FindFirstChildWhichIsA("Humanoid")
  local camera=workspace.CurrentCamera; camera.CameraType=Enum.CameraType.Custom; camera.CameraSubject=h
  camera.CFrame=CFrame.lookAt(c.Head.Position,c.Head.Position+Vector3.xAxis)
 elseif phase=="Stop" then
  assert(maximumTrainDrift<.0001,"Client passenger carriage jitter detected")
  print("LASTTRAIN_REAL_CLIENT_SAMPLES",samples,"max-relative-step",maxRelativeStep,"maximum-train-drift",maximumTrainDrift)
 end
end)
