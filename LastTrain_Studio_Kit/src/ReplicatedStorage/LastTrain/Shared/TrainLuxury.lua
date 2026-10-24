-- Native, asset-free finishing applied after cloning the three coaches.
-- Decorations never alter seats, door transforms, wheel contact or collision.
local Luxury = {}
local P = {
 Ivory=Color3.fromRGB(220,216,207), Navy=Color3.fromRGB(30,46,66),
 NavyLight=Color3.fromRGB(46,65,87), Champagne=Color3.fromRGB(180,158,117),
 Wood=Color3.fromRGB(100,76,59), Warm=Color3.fromRGB(255,235,208),
 Graphite=Color3.fromRGB(37,43,51), Silver=Color3.fromRGB(171,182,194),
}
local function part(parent,name,size,position,color,material)
 local p=Instance.new("Part")
 p.Name=name; p.Size=size; p.Position=position; p.Color=color
 p.Material=material or Enum.Material.SmoothPlastic
 p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CastShadow=false
 p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
 p.Parent=parent
 return p
end
local function text(host,value,face,color)
 local gui=Instance.new("SurfaceGui"); gui.Face=face; gui.CanvasSize=Vector2.new(720,150)
 gui.LightInfluence=.15; gui.Parent=host
 local label=Instance.new("TextLabel"); label.Size=UDim2.fromScale(1,1)
 label.BackgroundTransparency=1; label.Text=value; label.TextColor3=color or P.Warm
 label.Font=Enum.Font.GothamMedium; label.TextScaled=true; label.Parent=gui
end
local function finishFurniture(model)
 -- Snapshot first: new details are not visited recursively by this pass.
 for _,p in ipairs(model:GetDescendants()) do
  if p:IsA("BasePart") then
   local n=p.Name
   if n=="CarFloor" then p.Color=P.Graphite; p.Material=Enum.Material.SmoothPlastic
   elseif n=="AisleRunner" then p.Color=P.Navy; p.Material=Enum.Material.SmoothPlastic
   elseif n=="UpholsteredSeat" or n=="SeatBack" or n=="SeatTopRail" or n=="SeatTopCorner" then
    p.Color=P.Navy; p.Material=Enum.Material.SmoothPlastic
   elseif n=="SeatFrontBolster" or n=="SeatLumbarPanel" or n=="SeatHeadrest" then
    p.Color=P.NavyLight
   elseif n=="HeadrestCover" then
    p.Color=P.Ivory
    local emblem=part(p.Parent,"HeadrestMonogram",Vector3.new(.012,.12,.39),p.Position+Vector3.new(.044,0,0),P.Champagne,Enum.Material.Metal)
    text(emblem,"末班車",Enum.NormalId.Right,P.Navy)
   elseif n=="SeatArmrest" then
    p.Color=P.Champagne; p.Reflectance=.12
    part(p.Parent,"ArmrestLeatherPad",Vector3.new(1.14,.055,.19),p.Position+Vector3.new(.04,.095,0),P.Navy)
   elseif n=="FoldedTrayTable" then
    p.Color=P.Wood; p.Material=Enum.Material.SmoothPlastic
   elseif n=="SeatPedestal" then p.Color=P.Graphite
   elseif n=="SeatBackPocket" then p.Color=P.Navy; p.Material=Enum.Material.SmoothPlastic
   elseif n=="LuggageShelf" then p.Color=P.Ivory; p.Reflectance=.06
   elseif n=="LuggageShelfLip" or n=="SeatNumberBadge" then p.Color=P.Champagne
   elseif n=="WindowSill" then p.Color=P.Ivory
   elseif n=="WindowTopFrame" then p.Color=P.Champagne
   elseif n=="WarmCabinLight" then
    p.Position=Vector3.new(p.Position.X,7.19,p.Position.Z)
    p.Color=P.Warm
    for _,l in ipairs(p:GetChildren()) do
     if l:IsA("PointLight") then l.Color=P.Warm; l.Brightness=.85 end
    end
   elseif n=="IndirectCeilingStrip" then
    p.Color=P.Warm
   elseif n=="InteriorRouteDisplay" then
    -- Mount the information panels below the visible ceiling finish.
    p.Position=Vector3.new(p.Position.X,6.88,p.Position.Z)
   end
  end
 end
end
local function finishCoach(model,startX,endX,number)
 local length=endX-startX
 local middle=(startX+endX)/2
 -- Full-length interior lining is clipped to each passenger body, including
 -- the shorter cab coaches. Narrow decorative edges leave the aisle open.
 part(model,"IvoryCeilingLiner",Vector3.new(length-.04,.10,8.35),Vector3.new(middle,7.33,0),P.Ivory)
 for _,side in ipairs({-1,1}) do
  part(model,"CeilingChampagneReveal",Vector3.new(length-.06,.055,.08),Vector3.new(middle,7.245,side*3.22),P.Champagne,Enum.Material.Metal)
  part(model,"AisleEdgeInlay",Vector3.new(length-.06,.012,.035),Vector3.new(middle,.14,side*.91),P.Champagne,Enum.Material.Metal)
 end
 local doorX=number==1 and -25 or (number==3 and 95 or 35)
 for _,range in ipairs({{startX+.12,doorX-3.15},{doorX+3.15,endX-.12}}) do
  local span=range[2]-range[1]
  if span>0 then
   for _,side in ipairs({-1,1}) do
    local x=(range[1]+range[2])/2
    part(model,"InteriorSideLiner",Vector3.new(span,1.35,.055),Vector3.new(x,1.9,side*4.99),P.Ivory)
    part(model,"WalnutWindowRail",Vector3.new(span,.16,.07),Vector3.new(x,2.53,side*5.02),P.Wood,Enum.Material.Wood)
    part(model,"ChampagneWindowReveal",Vector3.new(span,.025,.08),Vector3.new(x,2.635,side*5.02),P.Champagne,Enum.Material.Metal)
   end
  end
 end
 -- Walnut vestibule panels sit beside the opening, with brushed-metal trims.
 for _,side in ipairs({-1,1}) do
  for _,dx in ipairs({-4.05,4.05}) do
   local x=doorX+dx
   part(model,"VestibuleWalnutPanel",Vector3.new(1.1,5.4,.055),Vector3.new(x,3.3,side*5.15),P.Wood,Enum.Material.Wood)
   part(model,"VestibulePanelTrim",Vector3.new(.035,5.4,.07),Vector3.new(x-.57,3.3,side*5.12),P.Champagne,Enum.Material.Metal)
  end
  local coach=part(model,"PremiumCoachPlaque",Vector3.new(.75,.76,.075),Vector3.new(doorX-4.05,5.3,side*5.1),P.Graphite)
  text(coach,string.format("%02d",number),side<0 and Enum.NormalId.Back or Enum.NormalId.Front,P.Champagne)
  -- One uninterrupted orange band stays above the door head. A narrow silver
  -- reveal adds depth without covering glass or crossing the open entrance.
  part(model,"ExteriorSilverReveal",Vector3.new(length-.10,.035,.035),Vector3.new(middle,6.9,side*5.73),P.Silver,Enum.Material.Metal)
 end
end
local function finishGangway(car,jointX)
 for _,side in ipairs({-1,1}) do
  part(car,"GangwayInnerLiner",Vector3.new(5.35,6.85,.045),Vector3.new(jointX,3.65,side*4.12),P.Graphite,Enum.Material.SmoothPlastic)
  for _,dx in ipairs({-2.55,2.55}) do
   part(car,"GangwayPortalTrim",Vector3.new(.10,6.85,.12),Vector3.new(jointX+dx,3.65,side*4.07),P.Champagne,Enum.Material.Metal)
  end
  -- Exterior accordion ribs continue across the roof, enclosing the seam.
  for _,dx in ipairs({-2,-1.5,-1,-.5,0,.5,1,1.5,2}) do
   part(car,"GangwayExteriorBellows",Vector3.new(.12,7.32,.14),Vector3.new(jointX+dx,3.78,side*5.70),P.Graphite,Enum.Material.Rubber)
   local a=Vector3.new(jointX+dx,7.44,side*5.70)
   local b=Vector3.new(jointX+dx,8.36,side*4.70)
   local shoulder=part(car,"GangwayShoulderBellows",Vector3.new(.12,.12,(b-a).Magnitude),(a+b)/2,P.Graphite,Enum.Material.Rubber)
   shoulder.CFrame=CFrame.lookAt((a+b)/2,b)
  end
 end
 for _,dx in ipairs({-2,-1.5,-1,-.5,0,.5,1,1.5,2}) do
  part(car,"GangwayRoofBellows",Vector3.new(.12,.09,9.4),Vector3.new(jointX+dx,8.36,0),P.Graphite,Enum.Material.Rubber)
 end
 for _,dx in ipairs({-2.5,2.5}) do
  part(car,"GangwayFloorSeam",Vector3.new(.045,.006,7.45),Vector3.new(jointX+dx,.1355,0),P.Champagne,Enum.Material.Metal)
 end
end
function Luxury.Apply(train,rearCar,frontCar)
 finishFurniture(train)
 finishCoach(train,5,65,2)
 finishCoach(rearCar,-34,5,1)
 finishCoach(frontCar,65,104,3)
 finishGangway(rearCar,5)
 finishGangway(frontCar,65)
 train:SetAttribute("InteriorFinish","Midnight Navy / Ivory / Walnut / Champagne")
end
return Luxury
