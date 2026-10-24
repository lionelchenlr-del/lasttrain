-- A continuous tapered cab skin made from adjoining native triangles. The
-- windshield and livery follow the same surface, so no flat mask floats ahead
-- of the nose. No external mesh permissions or third-party assets are required.
local Finish = require(script.Parent.TrainFinish)
local Geometry = {}
local function triangle(parent,a,b,c,color,material,endName,rootSeal)
 local ab,ac,bc=b-a,c-a,c-b
 if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then a,c=c,a
 elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
 ab,ac,bc=b-a,c-a,c-b
 local cross=ac:Cross(ab)
 if cross.Magnitude<0.00001 then return end
 local right=cross.Unit
 local back=bc.Unit
 local up=bc:Cross(right).Unit
 local height=math.abs(ab:Dot(up))
 for i,data in ipairs({{(a+b)/2,right,back,math.abs(ab:Dot(back))},{(a+c)/2,-right,-back,math.abs(ac:Dot(back))}}) do
  if data[4]>0.0001 and height>0.0001 then
   local p=Instance.new("WedgePart")
   p.Name=(rootSeal and "CabRootSeal_" or "CabSurface_")..endName
   p.Size=Vector3.new(0.04,height,data[4])
   p.CFrame=CFrame.fromMatrix(data[1],data[2],up,data[3])
   p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CastShadow=false
   p.Color=color; p.Material=material
   p.Reflectance=material==Enum.Material.Metal and 0.2 or 0.06
   p:SetAttribute("CabEnd",endName)
   p:SetAttribute("CabGlazing",material==Enum.Material.SmoothPlastic)
   p.Parent=parent
  end
 end
end
function Geometry.BuildCab(parent,endName,shoulderX,direction)
 local rings,sides,length=16,32,26.7
 -- Match the body's flat crown and broad shoulders with a rounded rectangle.
 -- The small allowance covers the roof/skin edges; the root sits 0.45 studs
 -- inside the body, so it cannot expose a butt joint against separate panels.
 local function bodyProfile(angle)
  local co,si=math.cos(angle),math.sin(angle)
  local low,high=0,10
  local width,height,radius=5.89,4.44,.85
  for _=1,22 do
   local r=(low+high)/2
   local z=math.max(math.abs(co)*r-(width-radius),0)
   local y=math.max(math.abs(si)*r-(height-radius),0)
   if z*z+y*y<=radius*radius then low=r else high=r end
  end
  return Vector3.new(0,3.9+si*low,co*low)
 end
 local function surface(t,angle)
  local width=5.85*math.cos(t*math.pi/2)^0.72+0.035
  local height=4.15*(1-0.88*t^1.45)
  local y=4.1-1.45*t
  local round=Vector3.new(0,y+height*math.sin(angle),width*math.cos(angle))
  local u=math.clamp(t/.22,0,1)
  local blend=u*u*(3-2*u)
  local cross=bodyProfile(angle):Lerp(round,blend)
  return Vector3.new(shoulderX+direction*(length*t-.45*(1-blend)),cross.Y,cross.Z)
 end
 -- Close the rear of the shell as well as its outer surface. This seal is
 -- behind the existing cab bulkhead and cannot obstruct passenger circulation.
 local rootCenter=Vector3.new(shoulderX-direction*.45,3.9,0)
 for side=0,sides-1 do
  triangle(parent,rootCenter,surface(0,2*math.pi*side/sides),surface(0,2*math.pi*(side+1)/sides),Finish.Silver,Enum.Material.Metal,endName,true)
 end
 for ring=0,rings-1 do
  local t0,t1=ring/rings,(ring+1)/rings
  for side=0,sides-1 do
   local angle0,angle1=2*math.pi*side/sides,2*math.pi*(side+1)/sides
   local mid=(angle0+angle1)/2
   local windshield=ring>=1 and ring<=5 and math.sin(mid)>0.78
   local orange=math.sin(mid)>-0.62 and math.sin(mid)<-0.38
   local color=windshield and Finish.Graphite or (orange and Finish.Orange or Finish.Silver)
   -- Opaque glazing over a sealed cab keeps its dark visor under strong
   -- station reflections; native Glass can wash this curved surface white.
   local material=windshield and Enum.Material.SmoothPlastic or Enum.Material.Metal
   local a,b,c,d=surface(t0,angle0),surface(t1,angle0),surface(t0,angle1),surface(t1,angle1)
   triangle(parent,a,b,c,color,material,endName)
   triangle(parent,b,d,c,color,material,endName)
  end
 end
 local tip=Instance.new("Part")
 tip.Name="CabTip_"..endName; tip.Shape=Enum.PartType.Ball
 tip.Size=Vector3.new(0.18,1.0,0.18)
 tip.Position=Vector3.new(shoulderX+direction*length,2.65,0)
 tip.Color=Finish.Silver; tip.Material=Enum.Material.Metal; tip.Reflectance=0.2
 tip.Anchored=true; tip.CanCollide=false; tip:SetAttribute("CabEnd",endName); tip.Parent=parent
 for _,side in ipairs({-1,1}) do
  local t=0.66
  local position=surface(t,side==1 and 0.05 or math.pi-0.05)
  local lamp=Instance.new("Part"); lamp.Name="CabHeadlamp_"..endName
  lamp.Shape=Enum.PartType.Ball; lamp.Size=Vector3.new(1.5,0.28,0.18)
  lamp.Position=position+Vector3.new(0,0,side*0.04)
  lamp.Color=Color3.fromRGB(255,234,194); lamp.Material=Enum.Material.Neon
  lamp.Anchored=true; lamp.CanCollide=false; lamp:SetAttribute("CabEnd",endName); lamp.Parent=parent
 end
end
return Geometry
