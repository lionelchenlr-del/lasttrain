-- Server-only operations shared by the story controller and Studio regression tests.
local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local Operations={}
Operations.__index=Operations

function Operations.new(train)
 local self=setmetatable({Train=train,Doors={},Wheels={},Moving=false},Operations)
 local pivot=train:GetPivot()
 for _,p in ipairs(train:GetDescendants()) do
  if p:IsA("BasePart") then
   if p.Name=="SlidingDoor" then
    local closed=pivot:ToObjectSpace(p.CFrame)
    local shift=(p:GetAttribute("OpenX") or p.Position.X)-(p:GetAttribute("ClosedX") or p.Position.X)
    table.insert(self.Doors,{Part=p,Closed=closed,Open=closed+Vector3.new(shift,0,0)})
   elseif p.Name=="BogieWheel" or p.Name=="WheelHub" then
    table.insert(self.Wheels,{Part=p,Relative=pivot:ToObjectSpace(p.CFrame)})
   end
  end
 end
 return self
end

function Operations.Frame(train)
 return train:GetPivot()*(train:GetAttribute("PassengerFrameOffset") or CFrame.identity)
end
function Operations.Contains(train,character)
 local h=character and character:FindFirstChildWhichIsA("Humanoid")
 local root=character and character:FindFirstChild("HumanoidRootPart")
 if not h or h.Health<=0 or not root then return false end
 if h.SeatPart and h.SeatPart:IsDescendantOf(train) then return true end
 local p=Operations.Frame(train):PointToObjectSpace(root.Position)
 -- Passenger floors stop at the sealed cab bulkheads. Roofs are never ride areas.
 return p.X>=-66.4 and p.X<=63.5 and p.Y>=.25 and p.Y<=8.5 and math.abs(p.Z)<=5.5
end

function Operations:SetDoors(open,instant)
 assert(not self.Moving,"Cannot open doors while moving")
 self.Train:SetAttribute("DoorsOpen",false)
 local animations={}
 for _,door in ipairs(self.Doors) do
  local p=door.Part
  local shouldOpen=open and p:GetAttribute("Side")==-1
  -- Local coordinates keep doors attached at every station, including return trips.
  local target=self.Train:GetPivot()*(shouldOpen and door.Open or door.Closed)
  p.CanCollide=not shouldOpen
  if instant then p.CFrame=target else
   local t=TweenService:Create(p,TweenInfo.new(.85,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{CFrame=target})
   table.insert(animations,t); t:Play()
  end
 end
 if #animations>0 then animations[#animations].Completed:Wait() end
 for _,p in ipairs(self.Train:GetDescendants()) do
  if p:IsA("BasePart") then
   if p.Name=="BoardingBridge" then
    local active=open and p:GetAttribute("Side")==-1
    p.Transparency=active and 0 or 1; p.CanCollide=active
   elseif p.Name=="DoorThresholdGlow" then
    p.Color=open and Color3.fromRGB(98,225,211) or Color3.fromRGB(244,159,72)
   end
  end
 end
 self.Train:SetAttribute("DoorsOpen",open)
end

function Operations:Move(distance,duration,extraRiders)
 assert(not self.Moving,"Train already moving")
 assert(not self.Train:GetAttribute("DoorsOpen"),"Close doors before departure")
 self.Moving=true
 local start=self.Train:GetPivot()
 local value=Instance.new("CFrameValue"); value.Value=start
 local previous=start
 local function update()
  local current=value.Value
  local delta=current*previous:Inverse()
  local riders={}
  for _,player in ipairs(Players:GetPlayers()) do
   if Operations.Contains(self.Train,player.Character) then table.insert(riders,player.Character) end
  end
  -- Regression fixtures may supply server-owned NPCs; no client can call this module.
  for _,character in ipairs(extraRiders or {}) do
   if Operations.Contains(self.Train,character) then table.insert(riders,character) end
  end
  local standing={}
  for _,character in ipairs(riders) do
   local h=character:FindFirstChildWhichIsA("Humanoid")
   if not (h.SeatPart and h.SeatPart:IsDescendantOf(self.Train)) then
    table.insert(standing,{Character=character,Target=delta*character:GetPivot()})
   end
  end
  self.Train:PivotTo(current)
  for _,rider in ipairs(standing) do rider.Character:PivotTo(rider.Target) end
  local rotation=-(current.Position-start.Position).X/.675
  for _,wheel in ipairs(self.Wheels) do wheel.Part.CFrame=current*wheel.Relative*CFrame.Angles(rotation,0,0) end
  previous=current
 end
 local connection=value:GetPropertyChangedSignal("Value"):Connect(update)
 local tween=TweenService:Create(value,TweenInfo.new(duration,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Value=start+Vector3.new(distance,0,0)})
 tween:Play(); tween.Completed:Wait()
 connection:Disconnect(); value:Destroy(); self.Moving=false
end
return Operations
