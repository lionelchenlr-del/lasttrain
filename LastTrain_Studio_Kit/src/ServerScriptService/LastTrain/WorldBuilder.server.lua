-- Seven-stop, walkable horror route. All geometry is generated from this file so
-- the map remains editable in Studio without external packages or asset IDs.
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("LastTrain"):WaitForChild("Shared"):WaitForChild("GameConfig"))

-- This place also hosts the public lobby. Only reserved round servers build the route.
while Workspace:GetAttribute("LastTrainMode") ~= "Game" do
	Workspace:GetAttributeChangedSignal("LastTrainMode"):Wait()
end

local old = Workspace:FindFirstChild("LastTrainWorld")
if old then old:Destroy() end
local world = Instance.new("Folder"); world.Name = "LastTrainWorld"; world.Parent = Workspace
world:SetAttribute("Ready", false); world:SetAttribute("Station", 1)
Workspace:SetAttribute("LastTrainRoundStage", 0)
local function folder(name) local f=Instance.new("Folder"); f.Name=name; f.Parent=world; return f end
local geometry, props, objectives = folder("Geometry"), folder("Props"), folder("Objectives")
local C={ concrete=Color3.fromRGB(77,88,95), tile=Color3.fromRGB(105,117,122), dark=Color3.fromRGB(28,37,43), metal=Color3.fromRGB(128,141,145), gold=Color3.fromRGB(233,188,99), cyan=Color3.fromRGB(92,212,226), glass=Color3.fromRGB(31,63,76) }
local function part(parent,name,size,pos,color,material,transparency,collide)
 local p=Instance.new("Part"); p.Name=name; p.Size=size; p.Position=pos; p.Color=color; p.Material=material or Enum.Material.SmoothPlastic; p.Transparency=transparency or 0; p.Anchored=true; p.CanCollide=collide~=false; p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth; p.Parent=parent; return p
end
local function ellipsoid(parent,name,pos,scale,color,material,transparency,collide)
 local p=part(parent,name,Vector3.one,pos,color,material,transparency,collide)
 local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Sphere; mesh.Scale=scale; mesh.Parent=p
 return p
end
local function pointLight(host,color,brightness,range)
 local l=Instance.new("PointLight"); l.Color=color; l.Brightness=brightness; l.Range=range; l.Shadows=false; l.Parent=host; return l
end
local function label(host,text,color,width,height)
 local gui=Instance.new("SurfaceGui"); gui.Face=Enum.NormalId.Front; gui.CanvasSize=Vector2.new(1000,260); gui.LightInfluence=0; gui.Parent=host
 local t=Instance.new("TextLabel"); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1; t.Text=text; t.TextColor3=color; t.TextStrokeTransparency=.72; t.Font=Enum.Font.GothamBlack; t.TextScaled=true; t.Parent=gui; return gui
end
local function prompt(name,stage,pos,action,objectText,extra)
 local a=part(objectives,name,Vector3.new(2,3,2),pos,C.cyan,Enum.Material.Neon,1,false); a:SetAttribute("ObjectiveStage",stage)
 if extra then for k,v in pairs(extra) do a:SetAttribute(k,v) end end
 local pr=Instance.new("ProximityPrompt"); pr.ActionText=action; pr.ObjectText=objectText; pr.HoldDuration=.65; pr.MaxActivationDistance=11; pr.RequiresLineOfSight=false; pr.Parent=a; return a
end
-- Surface-following trim and glazing sit directly on the compound rounded shell.
local function shellSurface(x,y,side,offset)
 local nx=(x-35)/33; local ny=(y-4.25)/5.9
 local inside=math.max(.015,1-nx*nx-ny*ny); local root=math.sqrt(inside)
 local z=6.2*root+(offset or .035)
 local dzdx=-6.2*(x-35)/(33*33*root)
 local dzdy=-6.2*(y-4.25)/(5.9*5.9*root)
 local sx,sy=side*dzdx,side*dzdy
 local right=Vector3.new(1,0,sx).Unit; if side<0 then right=-right end
 local up=Vector3.new(0,1,sy).Unit
 local normal=right:Cross(up).Unit
 return Vector3.new(x,y,side*z),right,up,normal
end
local function surfacePanel(parent,name,size,x,y,side,color,material,transparency)
 local pos,right,up,normal=shellSurface(x,y,side,.055)
 local p=part(parent,name,size,pos,color,material,transparency or 0,false)
 p.CFrame=CFrame.fromMatrix(pos,right,up,normal); return p
end
local function curvedWindowBand(parent,name,centerX,side)
 local columns,rows=5,2; local span,height=17,2.7
 for column=1,columns do for row=1,rows do
  local x=centerX-span/2+(column-.5)*span/columns
  local y=3.8+(row-.5)*height/rows
  local pane=surfacePanel(parent,name,Vector3.new(span/columns-.055,height/rows-.055,.1),x,y,side,Color3.fromRGB(18,42,52),Enum.Material.Glass,.035)
  pane.Reflectance=.14
 end end
end
local function curvedStripe(parent,name,side,y,color,thickness)
 local segments=18; local xStart,xEnd=8,62
 for i=1,segments do
  local x=xStart+(i-.5)*(xEnd-xStart)/segments
  local p=surfacePanel(parent,name,Vector3.new((xEnd-xStart)/segments+.03,thickness,.12),x,y,side,color,Enum.Material.Neon,0)
  p:SetAttribute("SurfaceStripe",true)
 end
end
local function beam(parent,name,a,b,width,color,material)
 local delta=b-a
 local p=part(parent,name,Vector3.new(width,width,delta.Magnitude),(a+b)/2,color,material or Enum.Material.Metal,0,false)
 p.CFrame=CFrame.lookAt((a+b)/2,b)
 return p
end

-- A long route with a 600-stud run between each of the seven stations.
local spacing=GameConfig.StationSpacing
local routeLength=spacing*(#GameConfig.Stations-1)+480
local routeCenter=spacing*(#GameConfig.Stations-1)/2
local routeStart=routeCenter-routeLength/2
local routeEnd=routeCenter+routeLength/2
part(geometry,"Foundation",Vector3.new(routeLength,2,66),Vector3.new(routeCenter,-2,0),C.concrete,Enum.Material.Concrete)
part(geometry,"ContinuousTrackBed",Vector3.new(routeLength-24,1,22),Vector3.new(routeCenter,-1.1,0),C.dark,Enum.Material.Asphalt)
part(geometry,"ContinuousCeiling",Vector3.new(routeLength,2,66),Vector3.new(routeCenter,18,0),C.dark,Enum.Material.Metal)
for _,side in ipairs({-1,1}) do
 part(geometry,"ContinuousBackWall",Vector3.new(routeLength,18,2),Vector3.new(routeCenter,8,side*33),C.tile,Enum.Material.Concrete)
 part(geometry,"WallLowerTrim",Vector3.new(routeLength,1.3,.24),Vector3.new(routeCenter,2.25,side*31.85),C.dark,Enum.Material.Metal)
end
-- Close the route at both ends; the long side walls and ceiling enclose all seven stops.
for _,x in ipairs({routeStart+1,routeEnd-1}) do
 part(geometry,"TunnelEndWall",Vector3.new(2,18,66),Vector3.new(x,8,0),C.tile,Enum.Material.Concrete)
 part(geometry,"EndWallServiceDoor",Vector3.new(.18,8,5),Vector3.new(x-1.08,4,0),C.dark,Enum.Material.Metal)
 part(geometry,"EndWallExitGlow",Vector3.new(.12,.2,3.5),Vector3.new(x-1.2,7.55,0),C.cyan,Enum.Material.Neon,0,false)
end
for _,z in ipairs({-4.6,4.6}) do part(geometry,"ContinuousRail",Vector3.new(routeLength-25,.3,.3),Vector3.new(routeCenter,-.35,z),C.metal,Enum.Material.Metal) end
for x=routeStart+10,routeEnd-10,5 do part(geometry,"TrackSleeper",Vector3.new(.8,.25,13),Vector3.new(x,-.55,0),C.dark,Enum.Material.WoodPlanks) end

-- A silver high-speed style carriage with tapered noses, broad dark glazing,
-- a curved roof, and a bright cyan beltline rather than a box shell.
local train=Instance.new("Model"); train.Name="LastTrainCar"; train.Parent=props
part(train,"CarFloor",Vector3.new(60,.6,11.4),Vector3.new(35,-.2,0),Color3.fromRGB(41,52,59),Enum.Material.Metal)
-- One continuous rounded body/roof shell blends the cab nose into the passenger
-- body; adjacent shells overlap at the gangway instead of leaving ceiling gaps.
local shell=ellipsoid(train,"CarBodyShell",Vector3.new(35,4.25,0),Vector3.new(66,11.8,12),Color3.fromRGB(174,190,194),Enum.Material.Metal,0,false)
shell.Reflectance=.12
local rearNose=ellipsoid(train,"TaperedNose_Rear",Vector3.new(18,4.25,0),Vector3.new(32,7,8.3),Color3.fromRGB(174,190,194),Enum.Material.Metal,0,false)
local frontNose=ellipsoid(train,"TaperedNose_Front",Vector3.new(52,4.25,0),Vector3.new(38,6.5,7.7),Color3.fromRGB(174,190,194),Enum.Material.Metal,0,false)
rearNose.Reflectance=.12; frontNose.Reflectance=.12
for _,side in ipairs({-1,1}) do
 part(train,"ContinuousLowerSkirt",Vector3.new(46,1.15,.26),Vector3.new(35,1.45,side*5.5),Color3.fromRGB(65,83,92),Enum.Material.Metal,0,false)
 part(train,"BeltlineAccent",Vector3.new(47,.24,.2),Vector3.new(35,2.25,side*5.75),Color3.fromRGB(19,109,145),Enum.Material.Metal,0,false)
 part(train,"LowerSidePanel_Front",Vector3.new(22,1.2,.16),Vector3.new(20,1.65,side*4.7),Color3.fromRGB(220,227,224),Enum.Material.SmoothPlastic,0,false)
 part(train,"LowerSidePanel_Rear",Vector3.new(22,1.2,.16),Vector3.new(50,1.65,side*4.7),Color3.fromRGB(220,227,224),Enum.Material.SmoothPlastic,0,false)
 part(train,"SideHeader",Vector3.new(38,.42,.16),Vector3.new(35,7.5,side*3.95),Color3.fromRGB(196,209,208),Enum.Material.SmoothPlastic,0,false)
 for _,x in ipairs({32,38}) do
  part(train,"DoorFrame",Vector3.new(.24,6.35,.26),Vector3.new(x,3.25,side*5.95),C.metal,Enum.Material.SmoothPlastic,0,false)
 end
 for _,x in ipairs({33.55,36.45}) do
  local d=part(train,"SlidingDoor",Vector3.new(2.9,6.1,.32),Vector3.new(x,2.65,side*5.96),Color3.fromRGB(133,171,178),Enum.Material.Glass,.12,false)
  d:SetAttribute("ClosedX",x); d:SetAttribute("OpenX",x+(x<35 and -3.05 or 3.05)); d:SetAttribute("Side",side)
 end
 curvedWindowBand(train,"PanoramicWindowBand",20,side)
 curvedWindowBand(train,"PanoramicWindowBand",50,side)
 -- Slim window posts, door status lamps and flush maintenance seams add a
 -- finer scale to the long body without breaking its clean high-speed profile.
 for _,x in ipairs({12,28.5,41.5,57,63}) do
  local px,right,up,normal=shellSurface(x,5.2,side,.11)
  local post=part(train,"WindowMullion",Vector3.new(.12,2.25,.1),px,Color3.fromRGB(108,127,132),Enum.Material.Metal,0,false)
  post.CFrame=CFrame.fromMatrix(px,right,up,normal)
 end
 for _,x in ipairs({31.5,38.5}) do
  local lamp=part(train,"DoorStatusLamp",Vector3.new(.28,.12,.1),Vector3.new(x,6.68,side*5.86),Color3.fromRGB(116,233,213),Enum.Material.Neon,0,false)
  lamp:SetAttribute("Side",side)
 end
 for _,x in ipairs({18,26,44,52}) do
  part(train,"FlushServicePanel",Vector3.new(2.2,.5,.07),Vector3.new(x,1.25,side*5.68),Color3.fromRGB(149,164,166),Enum.Material.Metal,0,false)
 end
end
local noseMask=part(train,"CabNoseMask",Vector3.new(.22,2.05,7.4),Vector3.new(70.7,5.1,0),Color3.fromRGB(17,97,129),Enum.Material.Metal,0,false)
noseMask.CFrame=CFrame.new(noseMask.Position)*CFrame.Angles(0,0,math.rad(8))
part(train,"LowerCabApron",Vector3.new(.24,.7,5.4),Vector3.new(70.7,2.8,0),Color3.fromRGB(41,58,68),Enum.Material.Metal,0,false)
for _,z in ipairs({-2.35,2.35}) do
 local lamp=part(train,"CabHeadlamp",Vector3.new(.28,.42,1.15),Vector3.new(70.9,4.2,z),Color3.fromRGB(255,239,194),Enum.Material.Neon,0,false)
 pointLight(lamp,Color3.fromRGB(255,225,164),1.4,18)
end
for _,side in ipairs({-1,1}) do
 curvedStripe(train,"CyanBeltline",side,7.05,C.cyan,.16)
 curvedStripe(train,"GoldBeltline",side,1.72,C.gold,.12)
 local signPosition,signRight,signUp,signNormal=shellSurface(25,7.35,side,.08)
 local routeSign=part(train,"DestinationDisplay",Vector3.new(7,1.05,.16),signPosition,Color3.fromRGB(5,17,22),Enum.Material.Glass,.04,false)
 routeSign.CFrame=CFrame.fromMatrix(signPosition,signRight,signUp,signNormal); label(routeSign,"LAST TRAIN   •   07 STOPS",C.cyan)
end
-- Slanted end glazing and paired lamps make the tapered ends read as a cab.
for _,x in ipairs({3,67}) do
 local isFront=x>35
 local screen=part(train,"SlopedCabWindshield",Vector3.new(.12,1.35,2.8),Vector3.new(x,5.05,0),Color3.fromRGB(13,34,45),Enum.Material.Glass,.025,false)
 screen.CFrame=CFrame.new(screen.Position)*CFrame.Angles(0,0,math.rad(isFront and 13 or -13)); screen.Reflectance=.32
 for _,z in ipairs({-1.35,1.35}) do
  local h=part(train,"StreamlinedHeadlamp",Vector3.new(.18,.32,.52),Vector3.new(x+(isFront and .15 or -.15),3.55,z),Color3.fromRGB(255,241,207),Enum.Material.Neon,0,false)
  h.CFrame=CFrame.new(h.Position)*CFrame.Angles(0,0,math.rad(isFront and 13 or -13)); pointLight(h,Color3.fromRGB(255,228,176),1.8,22)
 end
end
for _,x in ipairs({20,50}) do
 local strip=part(train,"WarmCabinLight",Vector3.new(13,.18,1.25),Vector3.new(x,8.85,0),Color3.fromRGB(255,225,176),Enum.Material.Neon,0,false); pointLight(strip,Color3.fromRGB(255,216,158),1.1,23)
 local pole=part(train,"GrabPole",Vector3.new(.16,5.1,.16),Vector3.new(x,2.5,0),C.gold,Enum.Material.Metal); pole.Shape=Enum.PartType.Cylinder
end
for _,x in ipairs({14,24,46,56}) do for _,side in ipairs({-1,1}) do
 part(train,"UpholsteredSeat",Vector3.new(5,.5,2.05),Vector3.new(x,.62,side*3.3),Color3.fromRGB(40,106,112),Enum.Material.Fabric)
 part(train,"SeatBack",Vector3.new(5,2,.45),Vector3.new(x,1.8,side*2.25),Color3.fromRGB(40,106,112),Enum.Material.Fabric)
 part(train,"SeatHeadrest",Vector3.new(1.65,.52,.5),Vector3.new(x,2.72,side*2.25),Color3.fromRGB(63,137,139),Enum.Material.Fabric,0,false)
 for _,armX in ipairs({x-2.1,x+2.1}) do
  part(train,"SeatArmrest",Vector3.new(.28,.5,1.4),Vector3.new(armX,1.14,side*3.05),Color3.fromRGB(169,179,175),Enum.Material.Metal,0,false)
 end
end end
-- Distinct roof equipment, passenger information panels and threshold lights
-- make all three coaches read as working high-speed rolling stock.
for _,x in ipairs({19,51}) do
 local pod=ellipsoid(train,"RoofHVACPod",Vector3.new(x,10.08,0),Vector3.new(12,.5,3.8),Color3.fromRGB(142,157,160),Enum.Material.Metal,0,false)
 for _,z in ipairs({-1.05,1.05}) do
  part(train,"HVACVent",Vector3.new(8,.08,.22),Vector3.new(x,10.31,z),Color3.fromRGB(73,91,96),Enum.Material.Metal,0,false)
 end
end
for _,x in ipairs({11,29,41,59}) do
 local box=part(train,"InteriorRouteDisplay",Vector3.new(3.8,.72,.12),Vector3.new(x,7.6,0),Color3.fromRGB(5,20,26),Enum.Material.Glass,.02,false)
 label(box,"末班車  •  下一站",C.cyan)
end
-- A low articulated pantograph gives the electrical roofline a recognizable
-- high-speed train detail while staying clear of the station ceiling.
for _,z in ipairs({-.72,.72}) do
 local a=Vector3.new(35,10.28,z); local b=Vector3.new(39,10.28,z)
 local c=Vector3.new(37.3,11.55,z)
 part(train,"PantographInsulator",Vector3.new(.55,.22,.55),a,Color3.fromRGB(46,65,72),Enum.Material.Metal,0,false)
 part(train,"PantographInsulator",Vector3.new(.55,.22,.55),b,Color3.fromRGB(46,65,72),Enum.Material.Metal,0,false)
 beam(train,"PantographArm",a+Vector3.new(0,.12,0),c,.18,Color3.fromRGB(77,91,94),Enum.Material.Metal)
 beam(train,"PantographArm",b+Vector3.new(0,.12,0),c,.18,Color3.fromRGB(77,91,94),Enum.Material.Metal)
end
beam(train,"PantographContactBar",Vector3.new(37.3,11.55,-.72),Vector3.new(37.3,11.55,.72),.16,Color3.fromRGB(46,55,57),Enum.Material.Metal)
for _,side in ipairs({-1,1}) do
 for _,x in ipairs({32,38}) do
  local threshold=part(train,"DoorThresholdGlow",Vector3.new(2.5,.08,.16),Vector3.new(x,-.02,side*5.92),Color3.fromRGB(98,225,211),Enum.Material.Neon,0,false)
  threshold:SetAttribute("Side",side)
 end
end
-- Two articulated bogies per coach. The dark skirts conceal most machinery at
-- standing height, while the frames, wheel faces and axle details show below.
for _,centerX in ipairs({13,57}) do
 local frame=part(train,"BogieFrame",Vector3.new(11,.7,7.1),Vector3.new(centerX,-.9,0),Color3.fromRGB(46,57,63),Enum.Material.Metal,0,false)
 for _,axleX in ipairs({centerX-3.1,centerX+3.1}) do
  for _,side in ipairs({-1,1}) do
   local wheel=part(train,"BogieWheel",Vector3.new(1.35,.58,1.35),Vector3.new(axleX,-.875,side*4.05),Color3.fromRGB(31,37,41),Enum.Material.Metal,0,false)
   wheel.Shape=Enum.PartType.Cylinder; wheel.CFrame=CFrame.new(wheel.Position)*CFrame.Angles(math.rad(90),0,0)
   local hub=part(train,"WheelHub",Vector3.new(.52,.16,.52),Vector3.new(axleX,-.875,side*4.38),Color3.fromRGB(151,165,165),Enum.Material.Metal,0,false)
   hub.Shape=Enum.PartType.Cylinder; hub.CFrame=CFrame.new(hub.Position)*CFrame.Angles(math.rad(90),0,0)
  end
 end
 for _,side in ipairs({-1,1}) do
  part(train,"BrakeHousing",Vector3.new(3.3,.48,.45),Vector3.new(centerX,-1.45,side*4.28),Color3.fromRGB(112,67,55),Enum.Material.Metal,0,false)
 end
end
local recorder=part(train,"ConductorRecorder",Vector3.new(1.3,.5,.9),Vector3.new(24,1.4,-1.8),C.gold,Enum.Material.Metal)
local recLight=part(train,"RecorderStatus",Vector3.new(.18,.16,.1),Vector3.new(24,1.65,-2.3),Color3.fromRGB(250,73,65),Enum.Material.Neon,0,false); pointLight(recLight,recLight.Color,.3,4)

-- Extend the high-speed train to three connected cars. The original carriage is
-- the center car; outer cars retain only the matching cab nose at the train ends.
local originalParts={}
for _,child in ipairs(train:GetChildren()) do if child:IsA("BasePart") then table.insert(originalParts,child) end end
local function makeCarriage(name,offset,keepCab)
 local car=Instance.new("Model"); car.Name=name; car.Parent=train
 local omit={ConductorRecorder=true,RecorderStatus=true,PantographInsulator=true,PantographArm=true,PantographContactBar=true}
 for _,source in ipairs(originalParts) do
  local isRear=source.Name=="TaperedNose_Rear" or (source.Name=="SlopedCabWindshield" and source.Position.X<35) or (source.Name=="StreamlinedHeadlamp" and source.Position.X<35)
  local isFront=source.Name=="TaperedNose_Front" or (source.Name=="SlopedCabWindshield" and source.Position.X>35) or (source.Name=="StreamlinedHeadlamp" and source.Position.X>35) or source.Name=="CabNoseMask" or source.Name=="LowerCabApron" or source.Name=="CabHeadlamp"
  if source.Name=="TaperedNose_Rear" or source.Name=="TaperedNose_Front" or source.Name=="SlopedCabWindshield" or source.Name=="StreamlinedHeadlamp" or source.Name=="CabNoseMask" or source.Name=="LowerCabApron" or source.Name=="CabHeadlamp" then
   if (keepCab=="Rear" and isRear) or (keepCab=="Front" and isFront) then
    local clone=source:Clone(); clone.Position=clone.Position+Vector3.new(offset,0,0); clone.Parent=car
   end
  elseif not omit[source.Name] then
   local clone=source:Clone(); clone.Position=clone.Position+Vector3.new(offset,0,0)
   for _,attribute in ipairs({"ClosedX","OpenX"}) do local value=clone:GetAttribute(attribute); if value then clone:SetAttribute(attribute,value+offset) end end
   clone.Parent=car
  end
 end
 -- Flexible, dark gangways bridge the one-stud body seams while keeping a
 -- clear interior passage between the cars.
 local jointX=offset<0 and 65 or 5
 if offset== -60 or offset==60 then
  ellipsoid(car,"ArticulatedGangway",Vector3.new(jointX+offset,4.1,0),Vector3.new(4.2,6.9,9.2),Color3.fromRGB(32,43,48),Enum.Material.Rubber,0,false)
  ellipsoid(car,"ConnectedCeiling",Vector3.new(jointX+offset,7.2,0),Vector3.new(5.4,1.35,8.4),Color3.fromRGB(190,202,202),Enum.Material.SmoothPlastic,0,false)
  for _,side in ipairs({-1,1}) do
   local outer=part(car,"GangwayRim",Vector3.new(.18,6.35,.22),Vector3.new(jointX+offset,4.15,side*4.45),Color3.fromRGB(117,133,137),Enum.Material.Metal,0,false)
   outer:SetAttribute("CoachConnection",true)
  end
 end
 return car
end
local rearCar=makeCarriage("RearCarriage",-60,"Rear")
local frontCar=makeCarriage("FrontCarriage",60,"Front")
-- Hide the center carriage's cab ends: it is an intermediate passenger car.
for _,name in ipairs({"TaperedNose_Rear","TaperedNose_Front","SlopedCabWindshield","StreamlinedHeadlamp","CabNoseMask","LowerCabApron","CabHeadlamp"}) do
 for _,child in ipairs(train:GetChildren()) do if child.Name==name and child:IsA("BasePart") then child.Transparency=1; child.CanCollide=false end end
end
-- Recessed walk plates meet the platform edge when the platform-side doors open.
for _,car in ipairs({train,rearCar,frontCar}) do
 local offset=car==rearCar and -60 or (car==frontCar and 60 or 0)
 local bridge=part(car,"BoardingBridge",Vector3.new(6.2,.18,.72),Vector3.new(35+offset,-.02,-5.86),C.metal,Enum.Material.Metal,1,false)
 bridge:SetAttribute("Side",-1); bridge.CanCollide=false
end
-- Two discoverable onboard story beats, each housed in one added carriage.
local function carriageMemory(parent,name,pos,title,story,color)
 local artifact=part(parent,name,Vector3.new(1.6,.7,1.1),pos,color,Enum.Material.Metal)
 artifact:SetAttribute("NarrativeKey",name); artifact:SetAttribute("NarrativeText",story)
 local glow=part(parent,name.."Glow",Vector3.new(1.1,.08,.08),pos+Vector3.new(0,.39,-.57),color,Enum.Material.Neon,0,false); pointLight(glow,color,.45,7)
 local pr=Instance.new("ProximityPrompt"); pr.ActionText=title; pr.ObjectText="列車上的記憶"; pr.HoldDuration=.5; pr.MaxActivationDistance=9; pr.RequiresLineOfSight=false; pr.Parent=artifact
 return artifact
end
carriageMemory(rearCar,"LostBroadcast",Vector3.new(-36,1.2,-1.2),"播放失蹤廣播","錄音裡的列車長急促地說：『新月站不要下車。這段錄音是三天前留下的。』背景裡，卻傳來你剛剛才說過的話。",C.cyan)
carriageMemory(frontCar,"ReturnTicket",Vector3.new(84,1.2,-1.2),"翻看舊車票","車票的日期是二十年前。目的地欄寫著你的名字。翻到背面，有人用鉛筆補上一句：『第七次抵達時，請別再上車。』",C.gold)
-- A simple prompt offers a reliable way to get off at every stop; walking
-- through the open platform-side doors works as well.
local function addDisembarkPrompt(parent,x)
 local anchor=part(parent,"DisembarkPrompt",Vector3.new(1,1,1),Vector3.new(x,2.1,-4.4),C.cyan,Enum.Material.Neon,1,false)
 anchor:SetAttribute("PromptType","Disembark")
 local p=Instance.new("ProximityPrompt"); p.ActionText="下車到月台"; p.ObjectText="列車已到站"; p.HoldDuration=.35; p.MaxActivationDistance=9; p.RequiresLineOfSight=false; p.Parent=anchor
end
addDisembarkPrompt(train,35)
addDisembarkPrompt(rearCar,-25)
addDisembarkPrompt(frontCar,95)
-- Align the negative-side doors within arm's reach of the platform edge.
for _,desc in ipairs(train:GetDescendants()) do if desc:IsA("BasePart") then desc.Position=desc.Position+Vector3.new(0,0,-6.35) end end

for i,station in ipairs(GameConfig.Stations) do
 local center=(i-1)*spacing; local accent=station.Accent
 for _,side in ipairs({-1,1}) do
  -- Finished wall cladding, inset light panels, and service access doors make the
  -- full tunnel enclosure read as a designed station instead of a bare corridor.
  part(geometry,"StationWallCladding",Vector3.new(380,11,.18),Vector3.new(center,8,side*31.82),i%2==0 and C.concrete or Color3.fromRGB(91,103,108),Enum.Material.SmoothPlastic,0,false)
  for _,panelX in ipairs({-90,-45,0,45,90}) do
   part(geometry,"WallRecessPanel",Vector3.new(24,5,.22),Vector3.new(center+panelX,8,side*31.68),C.tile,Enum.Material.Metal,0,false)
   part(geometry,"WallPanelLight",Vector3.new(18,.12,.08),Vector3.new(center+panelX,10.35,side*31.52),accent,Enum.Material.Neon,0,false)
  end
  part(geometry,"Platform_"..i,Vector3.new(420,1,21),Vector3.new(center,-.5,side*22.5),i%2==0 and Color3.fromRGB(92,103,108) or Color3.fromRGB(99,108,112),Enum.Material.Concrete)
  -- Fine stone joints, direction bands and inset edge lighting make the long
  -- platforms read as finished public architecture at walking distance.
  for xoff=-180,180,30 do
   part(geometry,"PlatformTileJoint",Vector3.new(.055,.025,20.5),Vector3.new(center+xoff,.012,side*22.5),Color3.fromRGB(137,148,148),Enum.Material.Metal,0,false)
  end
  for _,zoff in ipairs({-8.5,-2.5,3.5,8.5}) do
   part(geometry,"PlatformStoneBand",Vector3.new(412,.035,.12),Vector3.new(center,.025,side*22.5+zoff),Color3.fromRGB(133,144,145),Enum.Material.SmoothPlastic,0,false)
  end
  part(geometry,"PlatformWayfindingStripe",Vector3.new(396,.045,.28),Vector3.new(center,.035,side*28.4),accent,Enum.Material.Neon,.12,false)
  part(geometry,"TactileSafetyStrip_"..i,Vector3.new(416,.09,.8),Vector3.new(center,.06,side*11.55),C.gold,Enum.Material.DiamondPlate,0,false)
  part(geometry,"PlatformEdge_"..i,Vector3.new(418,.13,.22),Vector3.new(center,.08,side*12.3),accent,Enum.Material.Neon,0,false)
  for _,xoff in ipairs({-100,-40,40,100}) do
   local col=part(geometry,"RoundArchitecturalColumn",Vector3.new(1.45,13.3,1.45),Vector3.new(center+xoff,6.85,side*12.8),Color3.fromRGB(153,167,168),Enum.Material.SmoothPlastic); col.Shape=Enum.PartType.Cylinder
   local foot=part(geometry,"ColumnSocket",Vector3.new(2,.42,2),Vector3.new(center+xoff,.21,side*12.8),C.dark,Enum.Material.Metal); foot.Shape=Enum.PartType.Cylinder
  end
  ellipsoid(geometry,"SweptPlatformCanopy",Vector3.new(center,15.5,side*22.5),Vector3.new(360,2.8,18.2),Color3.fromRGB(51,69,76),Enum.Material.Metal,0,false)
  part(geometry,"CanopyUndersideLight",Vector3.new(350,.14,.8),Vector3.new(center,14.02,side*22.5),Color3.fromRGB(255,231,190),Enum.Material.Neon,.01,false)
  for _,xoff in ipairs({-105,-50,5,60,110}) do
   local lamp=part(geometry,"StationLight",Vector3.new(15,.18,.85),Vector3.new(center+xoff,13.92,side*22),Color3.fromRGB(255,230,191),Enum.Material.Neon,.01,false); pointLight(lamp,Color3.fromRGB(255,219,163),2.15,38)
  end
  -- Overhead platform number plates and discreet wall wash lights unify each
  -- stop's accent color and create readable visual landmarks.
  local pylon=part(props,"PlatformNumberPylon",Vector3.new(1.25,7.5,1.25),Vector3.new(center+145,3.75,side*15.4),C.dark,Enum.Material.Metal)
  local pylonFace=part(props,"PlatformNumberFace",Vector3.new(.08,4.4,.86),pylon.Position+Vector3.new(side*.67,.6,0),accent,Enum.Material.Neon,.08,false)
  local pylonGui=Instance.new("SurfaceGui"); pylonGui.Face=side==1 and Enum.NormalId.Right or Enum.NormalId.Left; pylonGui.CanvasSize=Vector2.new(180,480); pylonGui.LightInfluence=0; pylonGui.Parent=pylonFace
  local pylonText=Instance.new("TextLabel"); pylonText.Size=UDim2.fromScale(1,1); pylonText.BackgroundTransparency=1; pylonText.Text=string.format("%02d\n月台",i); pylonText.TextColor3=Color3.fromRGB(245,249,239); pylonText.Font=Enum.Font.GothamBlack; pylonText.TextScaled=true; pylonText.Parent=pylonGui
  for _,xoff in ipairs({-80,0,80}) do for step=1,4 do
   local z=side*(12.25-step*.58); local y=.05-step*.38
   part(geometry,"TrackAccessStep",Vector3.new(8,.5,.72),Vector3.new(center+xoff,y,z),C.metal,Enum.Material.Metal)
  end end
 end
 local sign=part(props,"StationSign_"..i,Vector3.new(32,3.7,.45),Vector3.new(center,12.1,-31.55),Color3.fromRGB(18,29,35),Enum.Material.Metal)
 part(props,"SignGlow_"..i,Vector3.new(31.5,.12,.12),Vector3.new(center,10.15,-31.25),accent,Enum.Material.Neon,0,false); label(sign,station.Name.."   /   "..station.English,accent)
 local kiosk=part(props,"StoryTotem_"..i,Vector3.new(2.4,4.5,1.15),Vector3.new(center-88,2.25,-28),Color3.fromRGB(24,35,41),Enum.Material.Metal)
 local screen=part(props,"StoryScreen_"..i,Vector3.new(1.75,2.1,.08),Vector3.new(center-88,2.95,-27.37),accent,Enum.Material.Neon,.14,false); pointLight(screen,accent,.4,8)
 local boardAnchor=part(objectives,"BoardTrain_"..i,Vector3.new(1,3,1),Vector3.new(center+35,2,-15.5),accent,Enum.Material.Neon,1,false)
 boardAnchor:SetAttribute("StationIndex",i)
 local boardPrompt=Instance.new("ProximityPrompt"); boardPrompt.ActionText="登上列車"; boardPrompt.ObjectText=station.Name.."：末班車"; boardPrompt.HoldDuration=.35; boardPrompt.MaxActivationDistance=11; boardPrompt.RequiresLineOfSight=false; boardPrompt.Parent=boardAnchor
 -- A distinctive visual landmark palette for each stop.
 if i==2 then
  for n=1,4 do local gate=part(props,"SilentTurnstile",Vector3.new(.4,2.6,4),Vector3.new(center-20+n*7,1.3,-20),Color3.fromRGB(79,119,100),Enum.Material.Metal); part(props,"TurnstileGlow",Vector3.new(.3,.12,3.7),gate.Position+Vector3.new(0,1.2,0),accent,Enum.Material.Neon,0,false) end
  -- Wordless passengers stare at the tiled wall; the child holds the warning photo.
  for n=1,5 do
   local px=center-48+n*17; local clothing=Color3.fromRGB(27+n*3,39+n*2,43+n*2)
   part(props,"SilentPassengerBody",Vector3.new(1.15,2.1,.65),Vector3.new(px,2.15,-25.8),clothing,Enum.Material.Fabric)
   part(props,"SilentPassengerHead",Vector3.new(.78,.86,.78),Vector3.new(px,3.63,-25.8),Color3.fromRGB(130,137,132),Enum.Material.SmoothPlastic)
   part(props,"SilentPassengerLeftArm",Vector3.new(.32,1.65,.38),Vector3.new(px-.78,2.25,-25.8),clothing,Enum.Material.Fabric)
   part(props,"SilentPassengerRightArm",Vector3.new(.32,1.65,.38),Vector3.new(px+.78,2.25,-25.8),clothing,Enum.Material.Fabric)
   for _,dx in ipairs({-.28,.28}) do part(props,"SilentPassengerLeg",Vector3.new(.42,1.12,.48),Vector3.new(px+dx,.56,-25.8),C.dark,Enum.Material.Fabric) end
  end
  local girl=part(props,"WarningGirlCoat",Vector3.new(.8,1.65,.55),Vector3.new(center-67,1.9,-24.6),Color3.fromRGB(119,49,52),Enum.Material.Fabric)
  part(props,"WarningGirlHead",Vector3.new(.65,.72,.65),girl.Position+Vector3.new(0,1.25,0),Color3.fromRGB(211,184,158),Enum.Material.SmoothPlastic)
 elseif i==3 then
  for n=1,3 do local speaker=part(props,"EchoSpeaker",Vector3.new(2.4,5,.7),Vector3.new(center-20+n*20,2.5,-31),C.dark,Enum.Material.Metal); part(props,"SpeakerRing",Vector3.new(.12,2.2,.08),speaker.Position+Vector3.new(0,0,-.4),accent,Enum.Material.Neon,0,false) end
 elseif i==4 then
  part(props,"MirrorLakeGlass",Vector3.new(82,9,.35),Vector3.new(center,5,-31.25),Color3.fromRGB(49,111,142),Enum.Material.Glass,.32,false)
  for n=-3,3 do part(props,"MirrorFrame",Vector3.new(.18,9,.5),Vector3.new(center+n*11,5,-30.95),accent,Enum.Material.Neon,.25,false) end
 elseif i==5 then
  for n=1,4 do local crt=part(props,"ForgottenMonitor",Vector3.new(5,3.3,.55),Vector3.new(center-30+n*15,4.1,-31),Color3.fromRGB(13,25,31),Enum.Material.Metal); part(props,"CCTVImage",Vector3.new(4.55,2.45,.08),crt.Position+Vector3.new(0,0,-.34),Color3.fromRGB(91,129,119),Enum.Material.Neon,.26,false) end
 elseif i==6 then
  for n=1,5 do local hazard=part(props,"RepairBayColumn",Vector3.new(1.5,8,1.5),Vector3.new(center-28+n*14,4,-28),C.metal,Enum.Material.Metal); part(props,"HazardBand",Vector3.new(1.55,.5,1.55),hazard.Position+Vector3.new(0,-1,0),accent,Enum.Material.Neon,0,false) end
  for _,offset in ipairs({-104,104}) do
   local parked=part(props,"GhostTrainBody",Vector3.new(54,7.5,8),Vector3.new(center+offset,4.1,offset<0 and 25 or -25),Color3.fromRGB(41,54,61),Enum.Material.Metal)
   part(props,"GhostTrainWindowBand",Vector3.new(46,2.5,.15),parked.Position+Vector3.new(0,1.2,offset<0 and -4.1 or 4.1),Color3.fromRGB(74,127,136),Enum.Material.Glass,.18,false)
   part(props,"GhostTrainRouteGlow",Vector3.new(48,.15,.12),parked.Position+Vector3.new(0,-2.3,offset<0 and -4.12 or 4.12),accent,Enum.Material.Neon,0,false)
  end
 elseif i==7 then
  for n=1,3 do local arch=part(props,"HomeTerminalArch",Vector3.new(.7,14,.8),Vector3.new(center+30+n*13,7,-29),accent,Enum.Material.Neon,.14,false); pointLight(arch,accent,.55,14) end
 end
end

-- Station 01 notices and entry signage.
local notice=part(props,"OpeningNotice",Vector3.new(7,4,.55),Vector3.new(-82,4,-31.5),C.dark,Enum.Material.Metal)
local noticeFace=part(props,"OpeningNoticeGlow",Vector3.new(6.5,2.8,.08),Vector3.new(-82,4,-31.17),C.cyan,Enum.Material.Neon,.22,false); label(noticeFace,"NIGHT SERVICE  /  PLATFORM 01",Color3.fromRGB(234,248,244))
for _,x in ipairs({-94,-43,11,98}) do for _,side in ipairs({-1,1}) do
 local z=side*26; part(props,"BenchSeat",Vector3.new(8,.5,2),Vector3.new(x,1.1,z),C.dark,Enum.Material.Metal); part(props,"BenchBack",Vector3.new(8,2,.35),Vector3.new(x,2.1,z+side*.85),C.metal,Enum.Material.Metal)
 for dx=-3,3,6 do part(props,"BenchLeg",Vector3.new(.35,1.1,1.4),Vector3.new(x+dx,.35,z),C.metal,Enum.Material.Metal) end
end end

-- One clear prompt per story beat. Branches at stops six and seven are deliberate.
prompt("TicketClue",0,Vector3.new(24,2.2,-6.35),"檢查車票","新月站：無目的地車票")
prompt("PassengerLedger",1,Vector3.new(spacing-82,2.2,-27),"翻閱乘客簿","失語站：空白離站紀錄")
prompt("TrueRecording",2,Vector3.new(spacing*2-80,2.2,-27),"播放真正的錄音","回聲站：第三次循環")
prompt("MirrorReport",3,Vector3.new(spacing*3-82,2.2,-27),"拍下倒影並取回報告","鏡湖站：異常倒影")
prompt("CCTVEvidence",4,Vector3.new(spacing*4-45,2.2,-27),"調閱監視器","遺忘站：三天前的影像")
prompt("TrustConductor",5,Vector3.new(spacing*5-40,2.2,-27),"相信站務員","終寂站：跟隨列車長",{Choice="Conductor"})
prompt("ReadAccidentLog",5,Vector3.new(spacing*5+40,2.2,-27),"讀取事故紀錄","終寂站：查明真相",{Choice="Records"})
prompt("LeaveEnding",6,Vector3.new(spacing*6-50,2.2,-27),"相信列車長，離開","結局：回到城市",{Ending="Conductor"})
prompt("TruthEnding",6,Vector3.new(spacing*6,2.2,-27),"關閉核心，終止循環","真相結局：讓列車停下",{Ending="Truth"})
prompt("SecretEnding",6,Vector3.new(spacing*6+50,2.2,-27),"啟動封存系統","隱藏結局：STATION 08",{Ending="Station08"})
local monsterSpawn=part(world,"MonsterSpawn",Vector3.new(2,1,2),Vector3.new(spacing+118,0.15,0),Color3.fromRGB(174,45,38),Enum.Material.Neon,1,false); monsterSpawn.CanTouch=false
local ambience=Instance.new("Sound"); ambience.Name="StationAmbience"; ambience.SoundId=""; ambience.Looped=true; ambience.Volume=.12; ambience.RollOffMaxDistance=200; ambience.Parent=world
world:SetAttribute("Ready",true)
