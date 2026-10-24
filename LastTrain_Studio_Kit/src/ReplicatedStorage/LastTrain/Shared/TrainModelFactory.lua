-- The actual passenger model is shared with the shop preview.
-- Keep preview clones isolated from the world so seat joints never cross over.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TrainFinish=require(script.Parent.TrainFinish)
local TrainGeometry=require(script.Parent.TrainGeometry)
local TrainLuxury=require(script.Parent.TrainLuxury)
local GameConfig=require(script.Parent.GameConfig)
local Factory={}
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
local function label(host,text,color,width,height,face)
 local gui=Instance.new("SurfaceGui"); gui.Face=face or Enum.NormalId.Front; gui.CanvasSize=Vector2.new(1000,260); gui.LightInfluence=0; gui.Parent=host
 local t=Instance.new("TextLabel"); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1; t.Text=text; t.TextColor3=color; t.TextStrokeTransparency=.72; t.Font=Enum.Font.GothamBlack; t.TextScaled=true; t.Parent=gui; return gui
end
-- Flush window and trim surfaces on the passenger body.
local function shellSurface(x,y,side,offset)
 local pos=Vector3.new(x,y,side*(5.59+(offset or .035)))
 local right=Vector3.new(side,0,0)
 local up=Vector3.new(0,1,0)
 return pos,right,up,right:Cross(up)
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
  local y=2.65+(row-.5)*height/rows
  local pane=surfacePanel(parent,name,Vector3.new(span/columns-.055,height/rows-.055,.1),x,y,side,Color3.fromRGB(18,42,52),Enum.Material.Glass,.035)
  pane.CanCollide=true
  pane.Reflectance=.14
 end end
end
local function curvedStripe(parent,name,side,y,color,thickness)
 -- One face per uninterrupted run: adjoining coplanar segments used to
 -- overlap by .03 studs and shimmer when viewed from a moving camera.
 local runs=name=="GoldBeltline" and {{8,32},{38,62}} or {{8,62}}
 for _,run in ipairs(runs) do
  local x=(run[1]+run[2])/2
  local pos=Vector3.new(x,y,side*(5.64+.025))
  local right=Vector3.new(side,0,0)
  local p=part(parent,name,Vector3.new(run[2]-run[1],thickness,.12),pos,color,Enum.Material.SmoothPlastic,0,false)
  p.CFrame=CFrame.fromMatrix(pos,right,Vector3.yAxis,right:Cross(Vector3.yAxis))
  p:SetAttribute("SurfaceStripe",true)
 end
end
local function beam(parent,name,a,b,width,color,material)
 local delta=b-a
 local p=part(parent,name,Vector3.new(width,width,delta.Magnitude),(a+b)/2,color,material or Enum.Material.Metal,0,false)
 p.CFrame=CFrame.lookAt((a+b)/2,b)
 return p
end


function Factory.Build(parent)
local train=Instance.new("Model"); train.Name="LastTrainCar"; train.Parent=parent
part(train,"CarFloor",Vector3.new(60,.6,11.4),Vector3.new(35,-.2,0),Color3.fromRGB(41,52,59),Enum.Material.SmoothPlastic)
part(train,"CarInteriorCeiling",Vector3.new(60,.16,11),Vector3.new(35,7.45,0),Color3.fromRGB(157,171,171),Enum.Material.Metal)
train.CarInteriorCeiling.Transparency=1; train.CarInteriorCeiling.CastShadow=false; train.CarInteriorCeiling.CanQuery=false
-- Use a roof crown and separate lower/header skins instead of a solid oval
-- shell. This leaves the glazed bands genuinely open so passengers can see out.
local shell=ellipsoid(train,"CarBodyShell",Vector3.new(35,4.25,0),Vector3.new(60,11.8,12),Color3.fromRGB(193,204,205),Enum.Material.Metal,0,false)
shell.Transparency=1
shell.Reflectance=0
local roofShell=part(train,"ContinuousCoachRoof",Vector3.new(60,.6,10),Vector3.new(35,8.0,0),TrainFinish.Roof,Enum.Material.Metal,0,false)
roofShell.Reflectance=.2
for _,side in ipairs({-1,1}) do
 local shoulder=part(train,"RoofShoulder",Vector3.new(60,1.7,1.7),Vector3.new(35,7.45,side*5),TrainFinish.Silver,Enum.Material.Metal,0,false)
 shoulder.Shape=Enum.PartType.Cylinder
end
for _,side in ipairs({-1,1}) do
 for _,x in ipairs({18,52}) do
  part(train,"CoachLowerSideSkin",Vector3.new(21,2.6,.55),Vector3.new(x,1.35,side*5.3),Color3.fromRGB(193,204,205),Enum.Material.Metal,0,true)
  part(train,"CoachUpperSideSkin",Vector3.new(21,2.95,.58),Vector3.new(x,6.75,side*5.25),Color3.fromRGB(193,204,205),Enum.Material.Metal,0,true)
 end
 for _,x in ipairs({8.25,61.75}) do
  part(train,"CoachEndSideSkin",Vector3.new(6.5,7.4,.4),Vector3.new(x,3.8,side*5.4),TrainFinish.Silver,Enum.Material.Metal,0,true)
 end
 -- Narrow filler panels beside the doors close the coach side cleanly while
 -- keeping the open doorway itself clear when the paired sliders retract.
 for _,x in ipairs({30,40}) do
  part(train,"DoorJambMiddleSkin",Vector3.new(4,2.9,.4),Vector3.new(x,3.85,side*5.4),TrainFinish.Silver,Enum.Material.Metal,0,true)
  part(train,"DoorJambLowerSkin",Vector3.new(4,2.0,.48),Vector3.new(x,1.42,side*5.28),Color3.fromRGB(193,204,205),Enum.Material.Metal,0,true)
  part(train,"DoorJambHeaderSkin",Vector3.new(4,2.45,.5),Vector3.new(x,6.62,side*5.25),Color3.fromRGB(193,204,205),Enum.Material.Metal,0,true)
 end
end
-- Keep the coach body full-width up to its articulated ends. Short, tapered
-- cab shells are only retained at the two outside ends of the three-car set.
TrainGeometry.BuildCab(train,"Rear",26,-1)
TrainGeometry.BuildCab(train,"Front",44,1)
for _,side in ipairs({-1,1}) do
 part(train,"ContinuousLowerSkirt",Vector3.new(46,.62,.3),Vector3.new(35,.62,side*5.5),Color3.fromRGB(65,83,92),Enum.Material.Metal,0,false)
 part(train,"BeltlineAccent_Front",Vector3.new(20,.24,.08),Vector3.new(22,2.25,side*5.72),Color3.fromRGB(19,109,145),Enum.Material.Metal,0,false)
 part(train,"BeltlineAccent_Rear",Vector3.new(20,.24,.08),Vector3.new(48,2.25,side*5.72),Color3.fromRGB(19,109,145),Enum.Material.Metal,0,false)
 part(train,"LowerSidePanel_Front",Vector3.new(20,.42,.12),Vector3.new(18,1.45,side*5.62),Color3.fromRGB(220,227,224),Enum.Material.SmoothPlastic,0,false)
 part(train,"LowerSidePanel_Rear",Vector3.new(20,.42,.12),Vector3.new(52,1.45,side*5.62),Color3.fromRGB(220,227,224),Enum.Material.SmoothPlastic,0,false)
 part(train,"SideHeader",Vector3.new(42,.32,.18),Vector3.new(35,7.98,side*5.66),Color3.fromRGB(196,209,208),Enum.Material.SmoothPlastic,0,false)
 for _,x in ipairs({32,38}) do
  -- Keep the entire fixed frame behind the sliding leaf's inner face (5.80).
  -- The former frame occupied the door track and shimmered as glass crossed it.
  part(train,"DoorFrame",Vector3.new(.24,6.35,.10),Vector3.new(x,3.25,side*5.72),C.metal,Enum.Material.SmoothPlastic,0,false)
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
  local px,right,up,normal=shellSurface(x,3.8,side,.11)
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
for _,side in ipairs({-1,1}) do
 curvedStripe(train,"CyanBeltline",side,7.05,C.cyan,.16)
 curvedStripe(train,"GoldBeltline",side,1.72,C.gold,.12)
 local signPosition,signRight,signUp,signNormal=shellSurface(25,7.35,side,.08)
 local routeSign=part(train,"DestinationDisplay",Vector3.new(7,1.05,.16),signPosition,Color3.fromRGB(5,17,22),Enum.Material.Glass,.04,false)
 routeSign.CFrame=CFrame.fromMatrix(signPosition,signRight,signUp,signNormal); label(routeSign,"LAST TRAIN   •   07 STOPS",C.cyan,nil,nil,Enum.NormalId.Back)
 local numberPosition,numberRight,numberUp,numberNormal=shellSurface(45,7.25,side,.08)
 local coachSign=part(train,"CoachNumberDisplay",Vector3.new(4.2,.62,.14),numberPosition,Color3.fromRGB(5,17,22),Enum.Material.Glass,.04,false)
 coachSign.CFrame=CFrame.fromMatrix(numberPosition,numberRight,numberUp,numberNormal); label(coachSign,"COACH 02",C.gold,nil,nil,Enum.NormalId.Back)
end
for _,x in ipairs({20,50}) do
 local strip=part(train,"WarmCabinLight",Vector3.new(15,.12,1.35),Vector3.new(x,7.28,0),Color3.fromRGB(255,232,198),Enum.Material.Neon,0,false); pointLight(strip,Color3.fromRGB(255,219,170),1.25,23)

end
-- Forward-facing two-by-two high-speed seats. Rounded shells and separate
-- headrest covers keep the upholstery smooth without stretching fabric UVs.
for rowIndex,x in ipairs({14,24,46,56}) do
 for _,side in ipairs({-1,1}) do
  for column,zOffset in ipairs({2.2,4.1}) do
   local z=side*zOffset
   part(train,"UpholsteredSeat",Vector3.new(1.65,.26,1.34),Vector3.new(x,.88,z),Color3.fromRGB(39,62,81),Enum.Material.SmoothPlastic,0,false)
   local roll=part(train,"SeatFrontBolster",Vector3.new(1.34,.26,.26),Vector3.new(x+.79,.88,z),Color3.fromRGB(45,68,89),Enum.Material.SmoothPlastic,0,false)
   roll.Shape=Enum.PartType.Cylinder; roll.CFrame=CFrame.new(roll.Position)*CFrame.Angles(0,math.pi/2,0)
   part(train,"SeatBack",Vector3.new(.48,1.95,1.38),Vector3.new(x-.78,1.91,z),Color3.fromRGB(51,78,98),Enum.Material.SmoothPlastic,0,false)
   part(train,"SeatTopRail",Vector3.new(.48,.42,.96),Vector3.new(x-.78,2.9,z),Color3.fromRGB(51,78,98),Enum.Material.SmoothPlastic,0,false)
   for _,edge in ipairs({-.48,.48}) do
    local corner=part(train,"SeatTopCorner",Vector3.new(.48,.42,.42),Vector3.new(x-.78,2.9,z+edge),Color3.fromRGB(51,78,98),Enum.Material.SmoothPlastic,0,false)
    corner.Shape=Enum.PartType.Cylinder
   end
   part(train,"SeatLumbarPanel",Vector3.new(.08,.64,1.13),Vector3.new(x-.51,1.68,z),Color3.fromRGB(58,84,105),Enum.Material.SmoothPlastic,0,false)
   part(train,"SeatHeadrest",Vector3.new(.55,.5,1.2),Vector3.new(x-.74,2.94,z),Color3.fromRGB(72,97,118),Enum.Material.SmoothPlastic,0,false)
   part(train,"HeadrestCover",Vector3.new(.075,.42,.84),Vector3.new(x-.43,2.98,z),Color3.fromRGB(222,224,220),Enum.Material.SmoothPlastic,0,false)
   part(train,"SeatPedestal",Vector3.new(.8,.52,.9),Vector3.new(x-.12,.35,z),Color3.fromRGB(76,88,101),Enum.Material.Metal,0,false)
   for _,edge in ipairs({-.69,.69}) do
    local arm=part(train,"SeatArmrest",Vector3.new(1.48,.16,.16),Vector3.new(x-.04,1.35,z+edge),Color3.fromRGB(154,163,173),Enum.Material.Metal,0,false)
    arm.Shape=Enum.PartType.Cylinder
   end
   local badge=part(train,"SeatNumberBadge",Vector3.new(.05,.22,.33),Vector3.new(x-1.05,2.72,z),C.gold,Enum.Material.Metal,0,false)
   label(badge,string.format("%02d%s",rowIndex,side<0 and (column==1 and "A" or "B") or (column==1 and "C" or "D")),Color3.fromRGB(23,30,40),nil,nil,Enum.NormalId.Left)
   local seat=Instance.new("Seat"); seat.Name="PassengerSeat"; seat.Size=Vector3.new(1.3,.18,1.55)
   seat.CFrame=CFrame.new(x,1.03,z)*CFrame.Angles(0,-math.pi/2,0)
   seat.Anchored=true; seat.Transparency=1; seat.CanCollide=false; seat.CanTouch=false; seat.CastShadow=false
   seat:SetAttribute("SeatNumber",string.format("%02d%s",rowIndex,side<0 and (column==1 and "A" or "B") or (column==1 and "C" or "D")))
   seat.Parent=train
   local sit=Instance.new("ProximityPrompt"); sit.ActionText="坐下"; sit.ObjectText="座位 "..seat:GetAttribute("SeatNumber")
   sit.MaxActivationDistance=6; sit.HoldDuration=.2; sit.RequiresLineOfSight=true; sit.Parent=seat
   -- Keep the collision behind the passenger rather than filling the chair.
   local collider=part(train,"SeatBackCollider",Vector3.new(.3,2.25,1.4),Vector3.new(x-.86,1.95,z),C.dark,Enum.Material.SmoothPlastic,1,true)
   part(train,"FoldedTrayTable",Vector3.new(.10,.68,1.04),Vector3.new(x-1.06,1.94,z),Color3.fromRGB(175,183,188),Enum.Material.SmoothPlastic,0,false)
   part(train,"TrayLatch",Vector3.new(.06,.09,.24),Vector3.new(x-1.13,2.3,z),Color3.fromRGB(96,108,118),Enum.Material.Metal,0,false)
   part(train,"SeatBackPocket",Vector3.new(.11,.42,.92),Vector3.new(x-1.06,1.2,z),Color3.fromRGB(29,45,62),Enum.Material.Fabric,0,false)
   collider.CastShadow=false
  end
 end
end
-- A quiet center aisle, recessed service panels and luggage rails complete the
-- interior without blocking the continuous walk path between coaches.
part(train,"AisleRunner",Vector3.new(58,.035,1.72),Vector3.new(35,.115,0),Color3.fromRGB(53,62,74),Enum.Material.SmoothPlastic,0,false)
for _,x in ipairs({11,29,41,59}) do
 for _,side in ipairs({-1,1}) do
  local rack=part(train,"LuggageShelf",Vector3.new(7.2,.18,1.5),Vector3.new(x,6.2,side*3.82),Color3.fromRGB(145,161,162),Enum.Material.Metal,0,false)
  part(train,"LuggageShelfLip",Vector3.new(7.2,.12,.12),Vector3.new(x,6.08,side*4.55),C.gold,Enum.Material.Metal,0,false)
 end
end
-- Distinct roof equipment, passenger information panels and threshold lights
-- make all three coaches read as working high-speed rolling stock.
for _,x in ipairs({19,51}) do
 local pod=ellipsoid(train,"RoofHVACPod",Vector3.new(x,8.48,0),Vector3.new(12,.5,3.8),Color3.fromRGB(142,157,160),Enum.Material.Metal,0,false)
 for _,z in ipairs({-1.05,1.05}) do
  part(train,"HVACVent",Vector3.new(8,.08,.22),Vector3.new(x,8.71,z),Color3.fromRGB(73,91,96),Enum.Material.Metal,0,false)
 end
end
for _,side in ipairs({-1,1}) do
 for _,x in ipairs({20,50}) do
  part(train,"WindowSill",Vector3.new(17.1,.14,.42),Vector3.new(x,2.59,side*5.34),Color3.fromRGB(191,197,196),Enum.Material.SmoothPlastic,0,false)
  part(train,"WindowTopFrame",Vector3.new(17.1,.09,.14),Vector3.new(x,5.4,side*5.58),Color3.fromRGB(154,166,177),Enum.Material.Metal,0,false)
 end
 local warm=part(train,"IndirectCeilingStrip",Vector3.new(58,.06,.12),Vector3.new(35,7.2,side*4.8),Color3.fromRGB(255,231,200),Enum.Material.Neon,0,false)
 pointLight(warm,Color3.fromRGB(255,234,209),.3,15)
end
for _,x in ipairs({29,41}) do
 for _,side in ipairs({-1,1}) do
  local bag=part(train,"OverheadCarryOn",Vector3.new(2.1,.94,.9),Vector3.new(x,6.76,side*3.9),side<0 and Color3.fromRGB(74,92,110) or Color3.fromRGB(139,107,83),Enum.Material.Fabric,0,false)
  for _,strap in ipairs({-.64,.64}) do
   part(train,"LuggageStrap",Vector3.new(.08,.96,.92),bag.Position+Vector3.new(strap,0,0),Color3.fromRGB(28,34,41),Enum.Material.SmoothPlastic,0,false)
  end
 end
end
for _,x in ipairs({11,29,41,59}) do
 local box=part(train,"InteriorRouteDisplay",Vector3.new(3.8,.54,.12),Vector3.new(x,7.12,0),Color3.fromRGB(5,20,26),Enum.Material.SmoothPlastic,0,false)
 label(box,"末班車  •  下一站",C.cyan)
end
-- A low articulated pantograph gives the electrical roofline a recognizable
-- high-speed train detail while staying clear of the station ceiling.
for _,z in ipairs({-.72,.72}) do
 local a=Vector3.new(35,8.55,z); local b=Vector3.new(39,8.55,z)
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
   local wheel=part(train,"BogieWheel",Vector3.new(.72,1.35,1.35),Vector3.new(axleX,-.875,side*4.05),Color3.fromRGB(31,37,41),Enum.Material.Metal,0,false)
   wheel.Shape=Enum.PartType.Cylinder; wheel.CFrame=CFrame.new(wheel.Position)*CFrame.Angles(0,math.rad(90),0)
   local hub=part(train,"WheelHub",Vector3.new(.2,.52,.52),Vector3.new(axleX,-.875,side*4.48),Color3.fromRGB(151,165,165),Enum.Material.Metal,0,false)
   hub.Shape=Enum.PartType.Cylinder; hub.CFrame=CFrame.new(hub.Position)*CFrame.Angles(0,math.rad(90),0)
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
 local trimNames={CarFloor=true,CarInteriorCeiling=true,ContinuousCoachRoof=true,RoofShoulder=true,AisleRunner=true,ContinuousLowerSkirt=true,BeltlineAccent_Front=true,BeltlineAccent_Rear=true,LowerSidePanel_Front=true,LowerSidePanel_Rear=true,SideHeader=true,CoachLowerSideSkin=true,CoachUpperSideSkin=true,CoachEndSideSkin=true}
 -- Flat fittings must end at the cab shoulder too. Previously short stripes
 -- and glazing were kept by their centers and could stick out over the nose.
 for _,n in ipairs({"CyanBeltline","GoldBeltline","PanoramicWindowBand","WindowMullion","FlushServicePanel","WindowSill","WindowTopFrame","IndirectCeilingStrip","LuggageShelf","LuggageShelfLip"}) do trimNames[n]=true end
 local minX,maxX=keepCab=="Rear" and 26 or 5,keepCab=="Front" and 44 or 65
 for _,source in ipairs(originalParts) do
  local cabEnd=source:GetAttribute("CabEnd")
  if cabEnd then
   if cabEnd==keepCab then
    local clone=source:Clone(); clone.Position+=Vector3.new(offset,0,0); clone.Parent=car
   end
  elseif not omit[source.Name] then
   local x=source.Position.X
   local from,to=math.max(minX,x-source.Size.X/2),math.min(maxX,x+source.Size.X/2)
   local keep=trimNames[source.Name] and to>from or (not trimNames[source.Name] and x>=minX and x<=maxX)
   if keep then
    local clone=source:Clone()
    if trimNames[source.Name] then
     clone.Size=Vector3.new(to-from,clone.Size.Y,clone.Size.Z)
     clone.Position=Vector3.new((from+to)/2,clone.Position.Y,clone.Position.Z)
    end
    clone.Position+=Vector3.new(offset,0,0)
    for _,attribute in ipairs({"ClosedX","OpenX"}) do local value=clone:GetAttribute(attribute); if value then clone:SetAttribute(attribute,value+offset) end end
    clone.Parent=car
   end
  end
 end
 -- Both coach bodies meet at this shared plane. The flexible surround covers
 -- their seam; a matching-height collision floor bridges the entire passage.
 local jointX=offset<0 and 65 or 5
 if offset== -60 or offset==60 then
  for _,side in ipairs({-1,1}) do
   part(car,"GangwaySideWall",Vector3.new(5.6,7.2,.24),Vector3.new(jointX+offset,3.75,side*4.28),Color3.fromRGB(30,41,47),Enum.Material.Rubber,0,true)
   for _,endOffset in ipairs({-2.7,2.7}) do
    part(car,"GangwayEndCollar",Vector3.new(.18,7.2,1.8),Vector3.new(jointX+offset+endOffset,3.75,side*5.05),Color3.fromRGB(52,63,68),Enum.Material.Rubber,0,true)
   end
  end
  part(car,"ConnectedCeiling",Vector3.new(5.6,.84,8.8),Vector3.new(jointX+offset,7.88,0),TrainFinish.Silver,Enum.Material.Metal,0,false)
  local ceilingCollider=part(car,"GangwayCeilingCollider",Vector3.new(5.6,.18,7.4),Vector3.new(jointX+offset,7.42,0),Color3.fromRGB(157,171,171),Enum.Material.Metal)
  ceilingCollider.Transparency=1; ceilingCollider.CastShadow=false; ceilingCollider.CanQuery=false
  local bridgeFloor=part(car,"GangwayStructuralFloor",Vector3.new(5.6,.6,8.32),Vector3.new(jointX+offset,-.2,0),Color3.fromRGB(38,44,54),Enum.Material.Metal,1,true)
  bridgeFloor.CastShadow=false
  part(car,"GangwayFloorPlate",Vector3.new(5.4,.035,7.5),Vector3.new(jointX+offset,.115,0),Color3.fromRGB(49,57,65),Enum.Material.Rubber,0,false)
  local ceilingLight=part(car,"GangwayCeilingLight",Vector3.new(2.8,.06,.62),Vector3.new(jointX+offset,7.22,0),Color3.fromRGB(255,235,207),Enum.Material.Neon,0,false)
  pointLight(ceilingLight,Color3.fromRGB(255,231,202),.5,8)
  for _,side in ipairs({-1,1}) do
   local outer=part(car,"GangwayRim",Vector3.new(.22,6.1,.24),Vector3.new(jointX+offset,4.15,side*4.28),Color3.fromRGB(137,153,154),Enum.Material.Metal,0,false)
   outer:SetAttribute("CoachConnection",true)
   for _,foldX in ipairs({-1.6,-.8,0,.8,1.6}) do
    part(car,"GangwayBellowsFold",Vector3.new(.09,5.45,.12),Vector3.new(jointX+offset+foldX,4.12,side*4.18),Color3.fromRGB(64,78,82),Enum.Material.Rubber,0,false)
   end
  end
 end
 return car
end
local rearCar=makeCarriage("RearCarriage",-60,"Rear")
local frontCar=makeCarriage("FrontCarriage",60,"Front")
local function labelCoach(model,description)
 -- Nested coaches carry their own numbers; labeling the center must not
 -- overwrite the rear coach through the parent train model.
 for _,display in ipairs(model:GetChildren()) do
  if display.Name=="InteriorRouteDisplay" then
   for _,gui in ipairs(display:GetChildren()) do
    local text=gui:FindFirstChildWhichIsA("TextLabel")
    if text then text.Text=description end
   end
  elseif display.Name=="CoachNumberDisplay" then
   for _,gui in ipairs(display:GetChildren()) do
    local text=gui:FindFirstChildWhichIsA("TextLabel")
    if text then text.Text=string.upper(description) end
   end
  end
 end
end
labelCoach(rearCar,"01 / 03  •  MEMORY CAR")
labelCoach(train,"02 / 03  •  CENTRAL CAR")
labelCoach(frontCar,"03 / 03  •  LAST CAR")
-- The middle coach has no cab. Outer cab surfaces are retained on the two
-- outer cars only, leaving both inter-car walkways completely open.
for _,child in ipairs(train:GetChildren()) do
 if child:IsA("BasePart") and child:GetAttribute("CabEnd") then child:Destroy() end
end
TrainFinish.Apply(train)
TrainLuxury.Apply(train,rearCar,frontCar)
require(ReplicatedStorage.LastTrain.Shared.TrainPremium).Apply(train,frontCar)
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
carriageMemory(rearCar,"LostBroadcast",Vector3.new(-18,1.2,-1.2),"播放失蹤廣播","錄音裡的列車長急促地說：『新月站不要下車。這段錄音是三天前留下的。』背景裡，卻傳來你剛剛才說過的話。",C.cyan)
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
-- Passenger areas end at the sealed driver cabs. The side windows remain clear
-- to the outside, while players cannot walk through the nose shell itself.
part(rearCar,"RearCabBulkhead",Vector3.new(.42,7.4,8.5),Vector3.new(-32,4.1,0),C.dark,Enum.Material.Metal)
part(frontCar,"FrontCabBulkhead",Vector3.new(.42,7.4,8.5),Vector3.new(99,4.1,0),C.dark,Enum.Material.Metal)
-- Align the negative-side doors within arm's reach of the platform edge.
for _,desc in ipairs(train:GetDescendants()) do if desc:IsA("BasePart") then desc.Position=desc.Position+Vector3.new(0,0,GameConfig.TrainCenterZ) end end

-- A replicated anchor gives both server and clients the same stable pivot.
-- Model.WorldPivot alone does not replicate when parts are moved in a batch.
local motionRoot=part(train,"TrainMotionRoot",Vector3.one,Vector3.new(35,0,GameConfig.TrainCenterZ),C.dark,Enum.Material.SmoothPlastic,1,false)
motionRoot.CanTouch=false; motionRoot.CanQuery=false; motionRoot.CastShadow=false
train.PrimaryPart=motionRoot
train:PivotTo(train:GetPivot())
train:SetAttribute("PassengerFrameOffset",train:GetPivot():ToObjectSpace(CFrame.new(35,0,GameConfig.TrainCenterZ)))

return train
end
return Factory
