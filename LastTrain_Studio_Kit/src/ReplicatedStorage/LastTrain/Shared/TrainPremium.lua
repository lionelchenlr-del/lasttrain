local Premium={}
local function part(parent,name,size,pos,color,material,transparency)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.Position=pos;p.Color=color
 p.Material=material or Enum.Material.SmoothPlastic;p.Transparency=transparency or 0
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CastShadow=false;p.Parent=parent;return p
end
local function sign(parent,name,value,x,color)
 local p=part(parent,name,Vector3.new(.06,.62,3),Vector3.new(x,5.9,0),Color3.fromRGB(28,35,44))
 for _,face in ipairs({Enum.NormalId.Left,Enum.NormalId.Right}) do
  local g=Instance.new("SurfaceGui");g.Face=face;g.CanvasSize=Vector2.new(600,124);g.LightInfluence=0;g.Parent=p
  local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Text=value;t.TextColor3=color;t.Font=Enum.Font.GothamBold;t.TextScaled=true;t.Parent=g
 end
end
function Premium.Apply(train,front)
 local gold=Color3.fromRGB(202,173,111)
 for _,seat in ipairs(train:GetDescendants()) do
  if seat:IsA("Seat") and seat.Name=="PassengerSeat" then
   local key=seat:IsDescendantOf(front) and "RoyalCarriage" or (seat.Parent==train and seat.Position.X>40 and "LuxuryPass" or nil)
   if key then
    seat:SetAttribute("RequiredPass",key)
    local prompt=seat:FindFirstChildOfClass("ProximityPrompt")
    if prompt then prompt.ObjectText=(key=="RoyalCarriage" and "皇家座位 " or "商務座位 ")..tostring(seat:GetAttribute("SeatNumber")) end
   end
  end
 end
 for _,p in ipairs(front:GetDescendants()) do
  if p:IsA("BasePart") then
   if p.Name=="UpholsteredSeat" or p.Name=="SeatBack" or p.Name=="SeatHeadrest" then p.Color=Color3.fromRGB(53,43,60) end
   if p.Name=="HeadrestCover" then p.Color=Color3.fromRGB(237,226,202) end
  end
 end
 for _,side in ipairs({-1,1}) do
  part(front,"RoyalWalnutPanel",Vector3.new(24,1.18,.065),Vector3.new(83,1.9,side*4.86),Color3.fromRGB(81,57,47),Enum.Material.Wood)
  part(front,"RoyalGoldReveal",Vector3.new(24,.035,.075),Vector3.new(83,2.53,side*4.83),gold,Enum.Material.Metal)
  for _,x in ipairs({78.8,89.2}) do
   part(front,"RoyalPrivacyDivider",Vector3.new(.08,4.9,2.9),Vector3.new(x,2.8,side*3.4),Color3.fromRGB(149,159,170),Enum.Material.SmoothPlastic,.65)
   part(front,"RoyalDividerTrim",Vector3.new(.10,4.9,.055),Vector3.new(x,2.8,side*1.92),gold,Enum.Material.Metal)
  end
 end
 -- Furnish the front lounge inside the existing body; no cab ornaments.
 part(front,"RoyalDiningTable",Vector3.new(3.2,.12,2.6),Vector3.new(78.8,2.0,3.25),Color3.fromRGB(116,82,51),Enum.Material.Wood)
 part(front,"RoyalDiningTableBase",Vector3.new(.35,1.8,.35),Vector3.new(78.8,1,3.25),gold,Enum.Material.Metal)
 part(front,"RoyalTeaBar",Vector3.new(5,.20,1.7),Vector3.new(94,2.65,3.85),Color3.fromRGB(75,52,38),Enum.Material.Wood)
 part(front,"RoyalBarCabinet",Vector3.new(4.8,2.3,1.5),Vector3.new(94,1.4,3.85),Color3.fromRGB(92,67,47),Enum.Material.Wood)
 part(front,"RoyalBarGoldEdge",Vector3.new(5,.045,.05),Vector3.new(94,2.76,2.98),gold,Enum.Material.Metal)
 for i=1,4 do
  local cup=part(front,"RoyalGlassware",Vector3.new(.24,.40,.24),Vector3.new(92.5+i*.6,2.95,4.15),Color3.fromRGB(217,198,144),Enum.Material.SmoothPlastic,.35);cup.Shape=Enum.PartType.Cylinder
 end
 local facility=part(front,"RoyalTeaService",Vector3.one,Vector3.new(94,2.8,2.8),gold,Enum.Material.SmoothPlastic,1)
 facility:SetAttribute("RoyalFacility","TeaBar")
 local interaction=Instance.new("ProximityPrompt");interaction.ActionText="領取皇家茶飲";interaction.ObjectText="皇家茶飲吧";interaction.RequiresLineOfSight=false;interaction.MaxActivationDistance=7;interaction.HoldDuration=.4;interaction.Parent=facility
 part(front,"RoyalBedBase",Vector3.new(6.2,.8,2.9),Vector3.new(93,.6,-3.25),Color3.fromRGB(91,65,48),Enum.Material.Wood)
 part(front,"RoyalBedMattress",Vector3.new(6,.35,2.8),Vector3.new(93,1.18,-3.25),Color3.fromRGB(238,228,204))
 part(front,"RoyalBedPillow",Vector3.new(1.3,.24,2.3),Vector3.new(95.1,1.48,-3.25),Color3.fromRGB(249,245,233))
 local resting=Instance.new("Seat");resting.Name="PassengerSeat";resting.Size=Vector3.new(1.3,.18,1.55);resting.CFrame=CFrame.new(92.4,1.46,-3.25)*CFrame.Angles(0,-math.pi/2,0)
 resting.Transparency=1;resting.Anchored=true;resting.CanTouch=false;resting.CanCollide=false;resting:SetAttribute("RequiredPass","RoyalCarriage");resting:SetAttribute("SeatNumber","ROYAL SUITE");resting.Parent=front
 local rest=Instance.new("ProximityPrompt");rest.ActionText="休息";rest.ObjectText="皇家休息包廂";rest.MaxActivationDistance=6;rest.HoldDuration=.3;rest.Parent=resting
 sign(train,"BusinessAreaSign","BUSINESS  ·  商務座位",42,gold)
 sign(front,"RoyalAreaSign","ROYAL LOUNGE  ·  皇家包廂",72,gold)
end
return Premium
