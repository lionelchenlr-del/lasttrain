-- Station coordinates are local to a fixed passenger train. Only scenery moves.
local Scenes={};Scenes.__index=Scenes
function Scenes.new(world,config)
 local self=setmetatable({World=world,Config=config,Stations={}},Scenes)
 for _,p in ipairs(world:GetDescendants()) do
  if p:IsA("BasePart") then
   local index=p:GetAttribute("StationIndex")
   if index then
    if not p:GetAttribute("StationLocalFrame") then
     p:SetAttribute("StationLocalFrame",p.CFrame-Vector3.new((index-1)*config.StationSpacing,0,0))
     p:SetAttribute("StationCollision",p.CanCollide);p:SetAttribute("StationQuery",p.CanQuery)
    end
    self.Stations[index]=self.Stations[index] or {};table.insert(self.Stations[index],p)
   end
  end
 end
 return self
end
function Scenes:Dock(index)
 local parts,poses={},{}
 for station,list in pairs(self.Stations) do
  local active=station==index
  for _,p in ipairs(list) do
   table.insert(parts,p)
   table.insert(poses,p:GetAttribute("StationLocalFrame")+Vector3.new(0,active and 0 or -1000-station*100,0))
   p.CanCollide=active and p:GetAttribute("StationCollision")==true
   p.CanQuery=active and p:GetAttribute("StationQuery")==true
   for _,d in ipairs(p:GetDescendants()) do
    if d:IsA("ProximityPrompt") or (d:IsA("SurfaceGui") or d:IsA("BillboardGui")) or d:IsA("Light") then d.Enabled=active end
   end
  end
 end
 workspace:BulkMoveTo(parts,poses,Enum.BulkMoveMode.FireCFrameChanged)
 self.World:SetAttribute("ActiveStation",index)
end
function Scenes:Depart(index)
 -- All passengers are already inside. Remove platform collisions while its
 -- departure is rendered locally; the train's collision floor never moves.
 for _,p in ipairs(self.Stations[index] or {}) do
  p.CanCollide=false;p.CanQuery=false
  for _,d in ipairs(p:GetDescendants()) do if d:IsA("ProximityPrompt") then d.Enabled=false end end
 end
end
return Scenes
