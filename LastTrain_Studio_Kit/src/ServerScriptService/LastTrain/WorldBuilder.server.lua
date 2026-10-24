-- Seven-stop, walkable horror route. All geometry is generated from this file so
-- the map remains editable in Studio without external packages or asset IDs.
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TrainFinish = require(ReplicatedStorage.LastTrain.Shared:WaitForChild("TrainFinish"))
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
local buildingStation=nil
local function part(parent,name,size,pos,color,material,transparency,collide)
 local p=Instance.new("Part"); p.Name=name; p.Size=size; p.Position=pos; p.Color=color; p.Material=material or Enum.Material.SmoothPlastic; p.Transparency=transparency or 0; p.Anchored=true; p.CanCollide=collide~=false; p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth; p.Parent=parent; if buildingStation then p:SetAttribute("StationIndex",buildingStation) end; return p
end
local function routePart(parent,name,size,pos,color,material,transparency,collide)
 local count=math.ceil(size.X/512)
 local length=size.X/count
 for i=1,count do
  part(parent,name,Vector3.new(length,size.Y,size.Z),pos+Vector3.new(-size.X/2+(i-.5)*length,0,0),color,material,transparency,collide)
 end
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
local function prompt(name,stage,pos,action,objectText,extra)
 local a=part(objectives,name,Vector3.new(2,3,2),pos,C.cyan,Enum.Material.Neon,1,false); a:SetAttribute("ObjectiveStage",stage); a:SetAttribute("StationIndex",math.max(1,stage+1))
 if extra then for k,v in pairs(extra) do a:SetAttribute(k,v) end end
 local pr=Instance.new("ProximityPrompt"); pr.ActionText=action; pr.ObjectText=objectText; pr.HoldDuration=.65; pr.MaxActivationDistance=11; pr.RequiresLineOfSight=false; pr.Parent=a; return a
end
-- Long, enclosed runs separate all seven stations; boarding is mandatory.
local spacing=GameConfig.StationSpacing
local routeLength=960
local routeCenter=0
local routeStart=routeCenter-routeLength/2
local routeEnd=routeCenter+routeLength/2
routePart(geometry,"Foundation",Vector3.new(routeLength,2,66),Vector3.new(routeCenter,-3.5,0),C.concrete,Enum.Material.Concrete)
routePart(geometry,"ContinuousTrackBed",Vector3.new(routeLength-24,.6,15),Vector3.new(routeCenter,-2.3,GameConfig.TrainCenterZ),C.dark,Enum.Material.Asphalt)
routePart(geometry,"ContinuousCeiling",Vector3.new(routeLength,2,66),Vector3.new(routeCenter,18,0),C.dark,Enum.Material.Metal)
for _,side in ipairs({-1,1}) do
 routePart(geometry,"ContinuousBackWall",Vector3.new(routeLength,18,2),Vector3.new(routeCenter,8,side*33),C.tile,Enum.Material.Concrete)
 routePart(geometry,"WallLowerTrim",Vector3.new(routeLength,1.3,.24),Vector3.new(routeCenter,2.25,side*31.85),C.dark,Enum.Material.Metal)
end
-- Close the route at both ends; the long side walls and ceiling enclose all seven stops.
for _,x in ipairs({routeStart+1,routeEnd-1}) do
 part(geometry,"TunnelEndWall",Vector3.new(2,18,66),Vector3.new(x,8,0),C.tile,Enum.Material.Concrete)
 part(geometry,"EndWallServiceDoor",Vector3.new(.18,8,5),Vector3.new(x-1.08,4,0),C.dark,Enum.Material.Metal)
 part(geometry,"EndWallExitGlow",Vector3.new(.12,.2,3.5),Vector3.new(x-1.2,7.55,0),C.cyan,Enum.Material.Neon,0,false)
end
for _,side in ipairs({-1,1}) do
 local z=GameConfig.TrainCenterZ+side*GameConfig.TrackHalfGauge
 routePart(geometry,"ContinuousRail",Vector3.new(routeLength-25,.3,.3),Vector3.new(routeCenter,GameConfig.RailTop-.15,z),Color3.fromRGB(169,177,182),Enum.Material.Metal)
 routePart(geometry,"RailFoot",Vector3.new(routeLength-25,.10,.65),Vector3.new(routeCenter,GameConfig.RailTop-.28,z),C.metal,Enum.Material.Metal)
end
for x=routeStart+10,routeEnd-10,8 do
 local sleeper=part(geometry,"TrackSleeper",Vector3.new(.95,.25,11),Vector3.new(x,GameConfig.RailTop-.425,GameConfig.TrainCenterZ),Color3.fromRGB(111,117,119),Enum.Material.Concrete,0,false)
 sleeper:SetAttribute("TravelLoop",960)
end
routePart(geometry,"OverheadContactWire",Vector3.new(routeLength-25,.07,.07),Vector3.new(routeCenter,11.64,GameConfig.TrainCenterZ),Color3.fromRGB(112,108,96),Enum.Material.Metal,0,false)
for x=routeStart+30,routeEnd-30,128 do
 local stopDistance=math.abs(x-math.floor(x/spacing+.5)*spacing)
 if stopDistance>230 then
  for _,side in ipairs({-1,1}) do
   local lamp=part(geometry,"TunnelServiceLight",Vector3.new(4,.3,.16),Vector3.new(x,6,side*31.7),Color3.fromRGB(207,223,233),Enum.Material.Neon,0,false)
   lamp:SetAttribute("TravelLoop",960)
   pointLight(lamp,Color3.fromRGB(187,207,225),.7,27)
   local rib=part(geometry,"TunnelWallRib",Vector3.new(.32,16,.32),Vector3.new(x,7,side*31.6),C.metal,Enum.Material.Metal,0,false);rib:SetAttribute("TravelLoop",960)
  end
 end
end

-- A silver high-speed style carriage with tapered noses, broad dark glazing,
-- a curved roof, and a bright cyan beltline rather than a box shell.
local train=require(ReplicatedStorage.LastTrain.Shared.TrainModelFactory).Build(props)

for i,station in ipairs(GameConfig.Stations) do
 buildingStation=i
 local center=(i-1)*spacing; local accent=station.Accent
 -- End screens close each platform while leaving the train clearance open.
 for _,endSign in ipairs({-1,1}) do
  for _,side in ipairs({-1,1}) do
   local gate=part(geometry,"PlatformEndScreen",Vector3.new(.26,9,20.5),Vector3.new(center+endSign*205,4.5,side*22.5),Color3.fromRGB(109,127,141),Enum.Material.Metal)
   local sign=part(geometry,"TunnelAccessNotice",Vector3.new(.12,1.45,9),gate.Position+Vector3.new(-endSign*.20,1.6,0),Color3.fromRGB(25,35,48),Enum.Material.SmoothPlastic,0,false)
   label(sign,"隧道封閉 · 請搭乘列車",Color3.fromRGB(243,220,163),nil,nil,endSign<0 and Enum.NormalId.Right or Enum.NormalId.Left)
  end
 end
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
  local col=part(geometry,"RoundArchitecturalColumn",Vector3.new(13.3,1.45,1.45),Vector3.new(center+xoff,6.85,side*12.8),Color3.fromRGB(153,167,168),Enum.Material.SmoothPlastic); col.Shape=Enum.PartType.Cylinder; col.CFrame=CFrame.new(col.Position)*CFrame.Angles(0,0,math.rad(90))
  local foot=part(geometry,"ColumnSocket",Vector3.new(.42,2,2),Vector3.new(center+xoff,.21,side*12.8),C.dark,Enum.Material.Metal); foot.Shape=Enum.PartType.Cylinder; foot.CFrame=CFrame.new(foot.Position)*CFrame.Angles(0,0,math.rad(90))
  end
  ellipsoid(geometry,"SweptPlatformCanopy",Vector3.new(center,15.5,side*22.5),Vector3.new(360,2.8,18.2),Color3.fromRGB(51,69,76),Enum.Material.Metal,0,false)
  part(geometry,"CanopyUndersideLight",Vector3.new(350,.14,.8),Vector3.new(center,14.02,side*22.5),Color3.fromRGB(228,236,248),Enum.Material.Neon,.01,false)
  for _,xoff in ipairs({-105,-50,5,60,110}) do
   local lamp=part(geometry,"StationLight",Vector3.new(15,.18,.85),Vector3.new(center+xoff,13.92,side*22),Color3.fromRGB(228,236,248),Enum.Material.Neon,.01,false); pointLight(lamp,Color3.fromRGB(228,236,255),2.15,38)
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

buildingStation=1
-- Station 01 notices and entry signage.
local entry=Instance.new("Model"); entry.Name="FirstStationEntry"; entry.Parent=props
local gx=GameConfig.FirstStationGateX
-- Two generous lanes span the first platform. The server separately checks
-- each passenger's ticket, so one open lane cannot validate a whole party.
for _,range in ipairs({{-33,-29.1},{-25.7,-20.5},{-17.1,-12}}) do
 local z=(range[1]+range[2])/2; local width=range[2]-range[1]
 part(entry,"TicketGateHousing",Vector3.new(3.8,3.1,width),Vector3.new(gx,1.55,z),Color3.fromRGB(166,177,183),Enum.Material.Metal)
 part(entry,"TicketGateCap",Vector3.new(3.85,.16,width),Vector3.new(gx,3.18,z),Color3.fromRGB(36,48,56),Enum.Material.SmoothPlastic,0,false)
end
for index,laneZ in ipairs({-27.4,-18.8}) do
 local gate=Instance.new("Model"); gate.Name="EntryGate"..index; gate.Parent=entry
 gate:SetAttribute("TicketGate",true); gate:SetAttribute("LaneZ",laneZ); gate:SetAttribute("Open",false)
 for _,side in ipairs({-1,1}) do
  local leaf=part(gate,"TicketGateLeaf",Vector3.new(.16,2.5,1.65),Vector3.new(gx,1.55,laneZ+side*.825),Color3.fromRGB(110,177,185),Enum.Material.SmoothPlastic,.30,true)
  leaf:SetAttribute("OpenShiftZ",side*1.75)
 end
 local screen=part(gate,"ReaderScreen",Vector3.new(.08,.85,1.7),Vector3.new(gx-1.95,2.72,laneZ-2.2),Color3.fromRGB(14,30,35),Enum.Material.SmoothPlastic,0,false)
 local gui=label(screen,"感應車票\nTAP TO ENTER",Color3.fromRGB(145,231,200),nil,nil,Enum.NormalId.Left)
 gui.Name="ReaderDisplay"; gui:FindFirstChildWhichIsA("TextLabel").Name="StatusText"
 part(gate,"ReaderTouchPad",Vector3.new(.65,.08,.8),Vector3.new(gx-1.15,3.3,laneZ-2.2),Color3.fromRGB(79,197,177),Enum.Material.Neon,0,false)
 local a=prompt("TicketReader_"..index,-1,Vector3.new(gx-2.8,2.6,laneZ),"刷卡進站","每位乘客請感應車票",{PromptType="TicketReader",GateName=gate.Name})
 local p=a:FindFirstChildOfClass("ProximityPrompt"); p.HoldDuration=.35; p.MaxActivationDistance=7
 part(entry,"EntryLaneArrow",Vector3.new(5,.035,.14),Vector3.new(gx-6,.10,laneZ),Color3.fromRGB(111,215,181),Enum.Material.Neon,0,false)
end
local kiosk=part(entry,"TicketMachine",Vector3.new(3.4,4.5,2),Vector3.new(-151,2.25,-29.6),Color3.fromRGB(213,221,221),Enum.Material.SmoothPlastic)
local machineScreen=part(entry,"TicketMachineScreen",Vector3.new(2.5,1.65,.08),Vector3.new(-151,3.1,-28.55),Color3.fromRGB(13,29,38),Enum.Material.SmoothPlastic,0,false)
label(machineScreen,"領取無目的地車票\nFREE TICKET",Color3.fromRGB(238,226,185),nil,nil,Enum.NormalId.Back)
part(entry,"TicketOutputSlot",Vector3.new(1.6,.12,.08),Vector3.new(-151,1.75,-28.5),C.dark,Enum.Material.SmoothPlastic,0,false)
local ticket=part(entry,"UnclaimedTicket",Vector3.new(1.35,.06,.8),Vector3.new(-151,1.69,-28.17),Color3.fromRGB(250,249,245),Enum.Material.SmoothPlastic,0,false)
local ticketFace=Instance.new("SurfaceGui"); ticketFace.Name="TicketFace"; ticketFace.Face=Enum.NormalId.Top
 ticketFace.CanvasSize=Vector2.new(540,320); ticketFace.LightInfluence=0; ticketFace.Parent=ticket
local ticketStripe=Instance.new("Frame"); ticketStripe.Name="OrangeBand"; ticketStripe.Size=UDim2.fromScale(1,.24)
 ticketStripe.BorderSizePixel=0; ticketStripe.BackgroundColor3=TrainFinish.Orange; ticketStripe.Parent=ticketFace
local ticketText=Instance.new("TextLabel"); ticketText.Name="TicketText"; ticketText.Position=UDim2.fromScale(.06,.28)
 ticketText.Size=UDim2.fromScale(.88,.66); ticketText.BackgroundTransparency=1; ticketText.TextColor3=TrainFinish.Graphite
 ticketText.Font=Enum.Font.GothamMedium; ticketText.TextScaled=true
 ticketText.Text="末班車  LAST TRAIN\n新月站 → 目的地未定\n單程車票 • 請感應進站"; ticketText.Parent=ticketFace
local entrySign=part(entry,"EntryInstructions",Vector3.new(.18,2.2,15.5),Vector3.new(gx-2,6.2,-22.5),C.dark,Enum.Material.SmoothPlastic,0,false)
local entryGui=label(entrySign,"① 領取車票　→　② 刷卡進站　→　③ 上車",Color3.fromRGB(243,232,201),nil,nil,Enum.NormalId.Left)
entryGui.CanvasSize=Vector2.new(1600,220); entryGui:FindFirstChildWhichIsA("TextLabel").TextWrapped=false
local notice=part(props,"OpeningNotice",Vector3.new(7,4,.55),Vector3.new(-82,4,-31.5),C.dark,Enum.Material.Metal)
local noticeFace=part(props,"OpeningNoticeGlow",Vector3.new(6.5,2.8,.08),Vector3.new(-82,4,-31.17),C.cyan,Enum.Material.Neon,.22,false); label(noticeFace,"NIGHT SERVICE  /  PLATFORM 01",Color3.fromRGB(234,248,244))
for _,x in ipairs({-94,-43,11,98}) do for _,side in ipairs({-1,1}) do
 local z=side*26; part(props,"BenchSeat",Vector3.new(8,.5,2),Vector3.new(x,1.1,z),C.dark,Enum.Material.Metal); part(props,"BenchBack",Vector3.new(8,2,.35),Vector3.new(x,2.1,z+side*.85),C.metal,Enum.Material.Metal)
 for dx=-3,3,6 do part(props,"BenchLeg",Vector3.new(.35,1.1,1.4),Vector3.new(x+dx,.35,z),C.metal,Enum.Material.Metal) end
end end

-- One clear prompt per story beat. Branches at stops six and seven are deliberate.
prompt("TicketClue",-1,Vector3.new(-151,2.4,-26.8),"領取車票","新月站：免費無目的地車票",{PromptType="CollectTicket"})
prompt("PassengerLedger",1,Vector3.new(spacing-82,2.2,-27),"翻閱乘客簿","失語站：空白離站紀錄")
prompt("TrueRecording",2,Vector3.new(spacing*2-80,2.2,-27),"播放真正的錄音","回聲站：第三次循環")
prompt("MirrorReport",3,Vector3.new(spacing*3-82,2.2,-27),"拍下倒影並取回報告","鏡湖站：異常倒影")
prompt("CCTVEvidence",4,Vector3.new(spacing*4-45,2.2,-27),"調閱監視器","遺忘站：三天前的影像")
prompt("TrustConductor",5,Vector3.new(spacing*5-40,2.2,-27),"相信站務員","終寂站：跟隨列車長",{Choice="Conductor"})
prompt("ReadAccidentLog",5,Vector3.new(spacing*5+40,2.2,-27),"讀取事故紀錄","終寂站：查明真相",{Choice="Records"})
prompt("LeaveEnding",6,Vector3.new(spacing*6-50,2.2,-27),"相信列車長，離開","結局：回到城市",{Ending="Conductor"})
prompt("TruthEnding",6,Vector3.new(spacing*6,2.2,-27),"關閉核心，終止循環","真相結局：讓列車停下",{Ending="Truth"})
prompt("SecretEnding",6,Vector3.new(spacing*6+50,2.2,-27),"啟動封存系統","隱藏結局：STATION 08",{Ending="Station08"})
-- Physical task stations make the next interaction visible from the platform.
local taskNames={PassengerLedger="乘客紀錄台",TrueRecording="廣播燈號台",MirrorReport="倒影攝影點",CCTVEvidence="監視器調閱台",TrustConductor="事故配電台",ReadAccidentLog="事故配電台",LeaveEnding="終點核心台",TruthEnding="終點核心台",SecretEnding="終點核心台"}
local function marker(anchor,text)
 local gui=Instance.new("BillboardGui");gui.Name="TaskMarker";gui.Size=UDim2.fromOffset(220,54);gui.StudsOffset=Vector3.new(0,4,0);gui.AlwaysOnTop=true;gui.MaxDistance=100;gui.Parent=anchor
 local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundColor3=Color3.fromRGB(18,29,43);t.BackgroundTransparency=.15;t.TextColor3=Color3.fromRGB(252,211,147);t.Font=Enum.Font.GothamBold;t.TextSize=18;t.TextWrapped=true;t.Text=text;t.Parent=gui
 local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,8);corner.Parent=t
end
for name,title in pairs(taskNames) do
 local anchor=objectives:FindFirstChild(name)
 if anchor then
  buildingStation=anchor:GetAttribute("StationIndex")
  local p=anchor:FindFirstChildOfClass("ProximityPrompt");p.ActionText="開啟任務";p.ObjectText=title;p.HoldDuration=.3
  local at=anchor.Position
  local desk=part(props,"PlatformTaskDesk",Vector3.new(4.8,1.6,2.2),Vector3.new(at.X,1,at.Z+.6),C.dark,Enum.Material.Metal)
  local screen=part(props,"PlatformTaskScreen",Vector3.new(4.2,2.4,.18),Vector3.new(at.X,3.25,at.Z-.8),C.dark,Enum.Material.SmoothPlastic,0,false)
  label(screen,title.."\n按 E / 點擊互動",Color3.fromRGB(159,221,221),nil,nil,Enum.NormalId.Back)
  marker(anchor,title)
  if buildingStation==2 or buildingStation==3 then
   local safe=part(props,"TaskSafeZone",Vector3.new(16,.025,16),Vector3.new(at.X,.14,at.Z+3),Color3.fromRGB(61,178,181),Enum.Material.Neon,.82,false)
   safe.CanQuery=false;safe.CanTouch=false;safe:SetAttribute("TaskSafeZone",true);safe:SetAttribute("SafeRadius",8)
  end
 end
end
for index,at in ipairs({Vector3.new(spacing-112,1.8,-22),Vector3.new(spacing-22,1.8,-29),Vector3.new(spacing+58,1.8,-23)}) do
 buildingStation=2
 local tag=prompt("MissingLuggageTag"..index,1,at,"登記行李牌","找回失蹤乘客的身分",{LuggageTagIndex=index})
 tag.Transparency=0;tag.Size=Vector3.new(1.4,.9,.14);tag.Color=Color3.fromRGB(239,182,82);tag.CanQuery=true
 local bag=part(props,"LostLuggage",Vector3.new(2.1,1.8,1.3),at+Vector3.new(0,-.7,.8),Color3.fromRGB(72,89,112),Enum.Material.Fabric)
 marker(tag,"行李牌 "..index.." / 3")
end
buildingStation=4
local witnessAt=Vector3.new(spacing*3-75,3.5,-29.2)
local witness=part(props,"MirrorWitnessTarget",Vector3.new(1.8,2.6,.45),witnessAt,Color3.fromRGB(81,191,224),Enum.Material.Neon,.15,false)
witness:SetAttribute("MirrorWitness",true);witness.CanQuery=true
for _,item in ipairs({{Name="MirrorWitnessHead",Size=Vector3.new(1.1,1.1,.5),Offset=Vector3.new(0,1.8,0)},{Name="MirrorWitnessArm",Size=Vector3.new(.5,1.9,.45),Offset=Vector3.new(-1.2,.5,0)},{Name="MirrorWitnessArm",Size=Vector3.new(.5,1.3,.45),Offset=Vector3.new(1.2,-.5,0)}}) do
 local p=part(props,item.Name,item.Size,witnessAt+item.Offset,witness.Color,Enum.Material.Neon,.2,false);p:SetAttribute("MirrorWitness",true)
end
buildingStation=nil
local monsterSpawn=part(world,"MonsterSpawn",Vector3.new(2,1,2),Vector3.new(118,0.15,-22),Color3.fromRGB(174,45,38),Enum.Material.Neon,1,false); monsterSpawn.CanTouch=false
local ambience=Instance.new("Sound"); ambience.Name="StationAmbience"; ambience.SoundId=""; ambience.Looped=true; ambience.Volume=.12; ambience.RollOffMaxDistance=200; ambience.Parent=world
local scenes=require(script.Parent.StationScenes).new(world,GameConfig)
scenes:Dock(1)
world:SetAttribute("Ready",true)
