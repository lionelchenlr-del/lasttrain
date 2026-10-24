-- The passenger carriage and camera never receive travel transforms.
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
while workspace:GetAttribute("LastTrainMode")~="Game" do workspace:GetAttributeChangedSignal("LastTrainMode"):Wait() end
local world=workspace:WaitForChild("LastTrainWorld")
while not world:GetAttribute("Ready") do world:GetAttributeChangedSignal("Ready"):Wait() end
local train=world:WaitForChild("Props"):WaitForChild("LastTrainCar")
local scenes,loops={},{}
for _,p in ipairs(world:GetDescendants()) do
 if p:IsA("BasePart") then
  local index=p:GetAttribute("StationIndex")
  if index and p:GetAttribute("StationLocalFrame") then
   scenes[index]=scenes[index] or {};table.insert(scenes[index],p)
  elseif p:GetAttribute("TravelLoop") then table.insert(loops,{Part=p,Frame=p.CFrame,Length=p:GetAttribute("TravelLoop")}) end
 end
end
local motion=nil
local function effects(index,on)
 for _,p in ipairs(scenes[index] or {}) do
  for _,d in ipairs(p:GetDescendants()) do
   if d:IsA("SurfaceGui") or d:IsA("Light") then d.Enabled=on end
  end
 end
end
local function begin()
 local raw=train:GetAttribute("TravelScene");if not raw then return end
 local ok,data=pcall(HttpService.JSONDecode,HttpService,raw)
 if not ok or type(data)~="table" or type(data.Duration)~="number" or data.Duration<=0 then return end
 motion=data;effects(data.From,true);effects(data.To,true)
end
train:GetAttributeChangedSignal("TravelScene"):Connect(begin);begin()
local parts,poses={},{}
RunService:BindToRenderStep("LastTrainScenery",Enum.RenderPriority.Camera.Value-2,function()
 if not motion then return end
 local elapsed=workspace:GetServerTimeNow()-motion.StartedAt
 local alpha=math.clamp(elapsed/motion.Duration,0,1)
 local travelled=motion.Distance*(.5-.5*math.cos(math.pi*alpha))
 table.clear(parts);table.clear(poses)
 for _,index in ipairs({motion.From,motion.To}) do
  for _,p in ipairs(scenes[index] or {}) do
   table.insert(parts,p)
   local x=index==motion.From and -travelled or motion.Distance-travelled
   table.insert(poses,p:GetAttribute("StationLocalFrame")+Vector3.new(x,0,0))
  end
 end
 for _,item in ipairs(loops) do
  local total=(motion.From-1)*motion.Distance+travelled
  local x=(item.Frame.X+item.Length/2-total)%item.Length-item.Length/2
  table.insert(parts,item.Part);table.insert(poses,item.Frame+Vector3.new(x-item.Frame.X,0,0))
 end
 workspace:BulkMoveTo(parts,poses,Enum.BulkMoveMode.FireCFrameChanged)
 if alpha>=1 then
  -- Park the departing station exactly where the server parks it. Incoming
  -- scenery is already docked at zero and server door animation can begin.
  table.clear(parts);table.clear(poses)
  for _,p in ipairs(scenes[motion.From] or {}) do
   table.insert(parts,p);table.insert(poses,p:GetAttribute("StationLocalFrame")+Vector3.new(0,-1000-motion.From*100,0))
  end
  workspace:BulkMoveTo(parts,poses,Enum.BulkMoveMode.FireCFrameChanged)
  effects(motion.From,false);effects(motion.To,true);motion=nil
 end
end)
