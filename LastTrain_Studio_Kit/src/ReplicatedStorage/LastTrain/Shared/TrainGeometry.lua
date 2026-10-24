-- Closed, asset-free high-speed cabs. Paint, glazing and lamps are part of the
-- same lofted skin; no separate balls, plates or trim project from the nose.
local Finish=require(script.Parent.TrainFinish)
local Geometry={}
local function triangle(parent,a,b,c,color,material,endName,section,glazing)
 local ab,ac,bc=b-a,c-a,c-b
 if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then a,c=c,a
 elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
 ab,ac,bc=b-a,c-a,c-b
 if ac:Cross(ab).Magnitude<.00001 then return end
 local right=ac:Cross(ab).Unit
 local back=bc.Unit
 local up=bc:Cross(right).Unit
 local height=math.abs(ab:Dot(up))
 for _,d in ipairs({{(a+b)/2,right,back,math.abs(ab:Dot(back))},{(a+c)/2,-right,-back,math.abs(ac:Dot(back))}}) do
  if d[4]>.0001 and height>.0001 then
   local p=Instance.new("WedgePart")
   p.Name=(section and "Cab"..section.."_" or "CabSurface_")..endName
   p.Size=Vector3.new(.04,height,d[4]); p.CFrame=CFrame.fromMatrix(d[1],d[2],up,d[3])
   p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CastShadow=false
   p.Color=color; p.Material=material; p.Reflectance=material==Enum.Material.Neon and 0 or .08
   p:SetAttribute("CabEnd",endName); p:SetAttribute("CabGlazing",glazing==true)
   p:SetAttribute("IntegratedHeadlamp",material==Enum.Material.Neon)
   p.Parent=parent
  end
 end
end
local function clip(polygon,height,above)
 local result={}
 for i,a in ipairs(polygon) do
  local b=polygon[i%#polygon+1]
  local insideA=above and a.Y>=height or not above and a.Y<=height
  local insideB=above and b.Y>=height or not above and b.Y<=height
  if insideA then table.insert(result,a) end
  if insideA~=insideB then table.insert(result,a:Lerp(b,(height-a.Y)/(b.Y-a.Y))) end
 end
 return result
end
local bands={
 {-20,1.66,"White"},{1.66,1.80,"Black"},{1.80,2.10,"White"},
 {2.10,2.40,"Orange"},{2.40,20,"White"},
}
local function paint(parent,a,b,c,endName,glazing,lamp)
 if glazing or lamp then
  triangle(parent,a,b,c,lamp and Color3.fromRGB(255,235,203) or Finish.Graphite,lamp and Enum.Material.Neon or Enum.Material.SmoothPlastic,endName,nil,glazing)
  return
 end
 -- Split at the paint boundaries instead of adding raised stripe panels.
 for _,band in ipairs(bands) do
  local poly=clip(clip({a,b,c},band[1],true),band[2],false)
  local color=band[3]=="Orange" and Finish.Orange or band[3]=="Black" and Finish.Graphite or Finish.Silver
  for i=2,#poly-1 do triangle(parent,poly[1],poly[i],poly[i+1],color,Enum.Material.SmoothPlastic,endName) end
 end
end
function Geometry.BuildCab(parent,endName,shoulderX,direction)
 local rings,sides,length=20,40,26.7
 local profile={}
 local function bodyProfile(angle)
  local key=string.format("%.8f",angle)
  if profile[key] then return profile[key] end
  local co,si=math.cos(angle),math.sin(angle)
  local low,high=0,10
  for _=1,22 do
   local r=(low+high)/2
   local z=math.max(math.abs(co)*r-5,0)
   local y=math.max(math.abs(si)*r-3.55,0)
   if z*z+y*y<=.85*.85 then low=r else high=r end
  end
  local y=3.9+si*low
  -- Broad roof shoulders are retained, while the waist meets the actual side
  -- skin. The former oversize rectangular root created a projecting collar.
  local sideScale=y<6.6 and 5.6/5.85 or y<7.45 and (5.6+(y-6.6)/.85*.25)/5.85 or 1
  local p=Vector3.new(0,y,co*low*sideScale); profile[key]=p; return p
 end
 local function surface(t,angle)
  local width=5.565*math.cos(t*math.pi/2)^.72+.035
  local height=4.15*(1-.88*t^1.45)
  if t>.88 then height*=.1+.9*(1-t)/.12 end
  local round=Vector3.new(0,4.1-1.45*t+height*math.sin(angle),width*math.cos(angle))
  local u=math.clamp(t/.22,0,1); local blend=u*u*(3-2*u)
  local p=bodyProfile(angle):Lerp(round,blend)
  return Vector3.new(shoulderX+direction*(length*t-.45*(1-blend)),p.Y,p.Z)
 end
 local root=Vector3.new(shoulderX-direction*.45,3.9,0)
 local tip=Vector3.new(shoulderX+direction*length,2.65,0)
 for side=0,sides-1 do
  local a,b=2*math.pi*side/sides,2*math.pi*(side+1)/sides
  triangle(parent,root,surface(0,a),surface(0,b),Finish.Silver,Enum.Material.SmoothPlastic,endName,"RootSeal")
  triangle(parent,tip,surface(1,a),surface(1,b),Finish.Silver,Enum.Material.SmoothPlastic,endName,"TipSeal")
 end
 for ring=0,rings-1 do
  local t0,t1=ring/rings,(ring+1)/rings
  for side=0,sides-1 do
   local a0,a1=2*math.pi*side/sides,2*math.pi*(side+1)/sides
   local mid=(a0+a1)/2
   local glazing=t0>=.05 and t1<=.35 and math.sin(mid)>.78
   local lamp=ring==13 and math.abs(math.sin(mid))<.09
   local a,b,c,d=surface(t0,a0),surface(t1,a0),surface(t0,a1),surface(t1,a1)
   paint(parent,a,b,c,endName,glazing,lamp); paint(parent,b,d,c,endName,glazing,lamp)
  end
 end
end
return Geometry
