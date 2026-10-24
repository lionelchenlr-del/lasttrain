-- Server-only operations shared by the story controller and Studio regression tests.
local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local HttpService=game:GetService("HttpService")
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
    p:SetAttribute("MotionClosedFrame",closed)
    table.insert(self.Doors,{Part=p,Closed=closed,Open=closed+Vector3.new(shift,0,0)})
   elseif p.Name=="BogieWheel" or p.Name=="WheelHub" then
    local relative=pivot:ToObjectSpace(p.CFrame)
    p:SetAttribute("MotionWheelFrame",relative)
    table.insert(self.Wheels,{Part=p,Relative=relative})
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

function Operations:Move(distance,duration,_extraRiders)
 assert(not self.Moving,"Train already moving")
 assert(not self.Train:GetAttribute("DoorsOpen"),"Close doors before departure")
 assert(duration>0,"Travel duration must be positive")
 self.Moving=true
 local startedAt=workspace:GetServerTimeNow()
 local from=workspace:GetAttribute("LastTrainStation") or 1
 self.Train:SetAttribute("TravelScene",HttpService:JSONEncode({Distance=distance,Duration=duration,
  StartedAt=startedAt,From=from,To=math.min(from+1,7)}))
 -- No train, character, camera, collision floor or seat transform is changed.
 -- Every client draws only the passing scenery using the shared server clock.
 task.wait(duration)
 self.Moving=false
end
return Operations
