local Catalog=require(script.Parent.PremiumCatalog)
local Finish=require(script.Parent.TrainFinish)
local Livery={}
function Livery.Apply(model,key)
 local style=Catalog.Liveries[key];if not style then return false end
 for _,p in ipairs(model:GetDescendants()) do
  if p:IsA("BasePart") then
   local role=p:GetAttribute("LiveryRole")
   if not role then
    if p.Color==Finish.Silver or p.Color==Finish.Roof then role="Body"
    elseif p.Color==Finish.Orange then role="Stripe" end
    if role then p:SetAttribute("LiveryRole",role) end
   end
   if role=="Body" then
    p.Color=style.Body
    if p:GetAttribute("CabEnd") then
     local point=model:GetPivot():PointToObjectSpace(p.Position)
     if key=="Starfield" then
      local nebula=math.clamp(math.noise(point.X*.09,point.Y*.26,point.Z*.19)+.4,0,1)
      p.Color=style.Body:Lerp(Color3.fromRGB(84,39,139),nebula*.65)
     elseif key=="Royal" and math.abs(point.Z)<1.55 and point.Y>2.4 and point.Y<5.2 then p.Color=Color3.fromRGB(220,185,111) end
    end
   elseif role=="Stripe" then
    if not p:GetAttribute("LiveryBaseMaterial") then p:SetAttribute("LiveryBaseMaterial",p.Material.Name) end
    p.Color=style.Stripe;p.Material=key=="Starfield" and Enum.Material.Neon or Enum.Material[p:GetAttribute("LiveryBaseMaterial")]
   end
   if p.Name=="CoachLowerSideSkin" or p.Name=="DisplayCarBody" then
    local marks=p:FindFirstChild("StarfieldMarks")
    if not marks then
     marks=Instance.new("Folder");marks.Name="StarfieldMarks";marks.Parent=p
     for _,face in ipairs({Enum.NormalId.Front,Enum.NormalId.Back}) do
      local gui=Instance.new("SurfaceGui");gui.Face=face;gui.CanvasSize=Vector2.new(1200,140);gui.LightInfluence=.35;gui.Adornee=p;gui.Parent=marks
      local stars=Instance.new("TextLabel");stars.BackgroundTransparency=1;stars.Size=UDim2.fromScale(1,1);stars.Text="·     ✦       ·      ·        ✧       ·       ✦      ·";stars.TextColor3=Color3.fromRGB(196,206,247);stars.TextScaled=true;stars.Parent=gui
      local planet=Instance.new("Frame");planet.Name="GalaxyPlanet";planet.Size=UDim2.fromScale(.14,.76);planet.Position=UDim2.fromScale(.43,.12);planet.BackgroundColor3=Color3.new(1,1,1);planet.BorderSizePixel=0;planet.Parent=gui
      local round=Instance.new("UICorner");round.CornerRadius=UDim.new(1,0);round.Parent=planet
      local shine=Instance.new("UIGradient");shine.Name="GalaxyGradient";shine.Color=ColorSequence.new(Color3.fromRGB(89,180,246),Color3.fromRGB(119,63,188));shine.Rotation=30;shine.Parent=planet
      local ring=Instance.new("Frame");ring.Name="PlanetRing";ring.BackgroundTransparency=1;ring.Size=UDim2.fromScale(.32,.46);ring.Position=UDim2.fromScale(.34,.26);ring.Rotation=-12;ring.Parent=gui
      local rounding=Instance.new("UICorner");rounding.CornerRadius=UDim.new(1,0);rounding.Parent=ring
      local stroke=Instance.new("UIStroke");stroke.Thickness=3;stroke.Color=Color3.fromRGB(162,207,255);stroke.Parent=ring
     end
    end
    for _,gui in ipairs(marks:GetChildren()) do gui.Enabled=key=="Starfield" end
    local royal=p:FindFirstChild("RoyalWordmark")
    if not royal then
     royal=Instance.new("SurfaceGui");royal.Name="RoyalWordmark";royal.Adornee=p;royal.Face=Enum.NormalId.Front;royal.CanvasSize=Vector2.new(1000,140);royal.LightInfluence=.1;royal.Parent=p
     local logo=Instance.new("TextLabel");logo.Size=UDim2.fromScale(1,1);logo.BackgroundTransparency=1;logo.Text="♛  ROYAL  ·  LAST TRAIN";logo.TextColor3=Color3.fromRGB(184,135,49);logo.Font=Enum.Font.GothamBold;logo.TextScaled=true;logo.Parent=royal
    end
    royal.Enabled=key=="Royal"
   end
  end
 end
 require(script.Parent.InteriorTheme).Apply(model,key)
 model:SetAttribute("SelectedLivery",key);return true
end
return Livery
