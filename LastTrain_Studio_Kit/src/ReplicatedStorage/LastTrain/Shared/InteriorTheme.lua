local Theme={}
local seats={UpholsteredSeat=true,SeatBack=true,SeatHeadrest=true,SeatTopRail=true,SeatTopCorner=true,SeatLumbarPanel=true,SeatFrontBolster=true}
local liners={IvoryCeilingLiner=true,InteriorSideLiner=true,WindowSill=true,LuggageShelf=true}
local trims={CeilingChampagneReveal=true,ChampagneWindowReveal=true,SeatNumberBadge=true,SeatArmrest=true,LuggageShelfLip=true,RoyalGoldReveal=true,RoyalDividerTrim=true}
local function sky(p)
 local gui=p:FindFirstChild("GalaxyCeiling")
 if gui then return gui end
 gui=Instance.new("SurfaceGui");gui.Name="GalaxyCeiling";gui.Adornee=p;gui.Face=Enum.NormalId.Bottom;gui.CanvasSize=Vector2.new(1800,300);gui.LightInfluence=0;gui.Parent=p
 local background=Instance.new("Frame");background.Size=UDim2.fromScale(1,1);background.BorderSizePixel=0;background.BackgroundColor3=Color3.new(1,1,1);background.Parent=gui
 local gradient=Instance.new("UIGradient");gradient.Name="GalaxyGradient";gradient.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(17,28,69)),ColorSequenceKeypoint.new(.5,Color3.fromRGB(66,30,96)),ColorSequenceKeypoint.new(1,Color3.fromRGB(20,55,99))});gradient.Rotation=12;gradient.Parent=background
 for i=1,96 do
  local star=Instance.new("Frame");star.Name="CeilingStar";local diameter=i%9==0 and 14 or 7
  star.Size=UDim2.fromOffset(diameter,diameter);star.Position=UDim2.fromScale((i*149%1750)/1800,(i*73%270)/300)
  star.BackgroundColor3=Color3.fromRGB(225,236,255);star.BackgroundTransparency=i%9==0 and 0 or .14;star.BorderSizePixel=0;star.ZIndex=3;star.Parent=gui
  local round=Instance.new("UICorner");round.CornerRadius=UDim.new(1,0);round.Parent=star

 end
 return gui
end
function Theme.Apply(train,key)
 local galaxy=key=="Starfield";local royal=key=="Royal"
 local front=train:FindFirstChild("FrontCarriage")
 for _,p in ipairs(train:GetDescendants()) do
  if p:IsA("BasePart") then
   if seats[p.Name] or liners[p.Name] or trims[p.Name] or p.Name=="HeadrestCover" or p.Name=="AisleRunner" then
    if not p:GetAttribute("InteriorBaseColor") then p:SetAttribute("InteriorBaseColor",p.Color) end
    local activeRoyal=royal and front and p:IsDescendantOf(front)
    if galaxy then
     p.Color=seats[p.Name] and Color3.fromRGB(39,44,75) or liners[p.Name] and Color3.fromRGB(31,39,66) or trims[p.Name] and Color3.fromRGB(158,176,232) or p.Name=="HeadrestCover" and Color3.fromRGB(226,233,247) or Color3.fromRGB(26,33,67)
    elseif activeRoyal then
     p.Color=seats[p.Name] and Color3.fromRGB(222,209,179) or liners[p.Name] and Color3.fromRGB(244,230,202) or trims[p.Name] and Color3.fromRGB(205,167,79) or p.Name=="HeadrestCover" and Color3.fromRGB(249,243,225) or Color3.fromRGB(75,55,43)
    else p.Color=p:GetAttribute("InteriorBaseColor") end
   end
   if p.Name=="IvoryCeilingLiner" then sky(p).Enabled=galaxy end
   if p.Name=="WarmCabinLight" then
    if not p:GetAttribute("LightBaseColor") then p:SetAttribute("LightBaseColor",p.Color) end
    p.Color=galaxy and Color3.fromRGB(177,198,255) or royal and Color3.fromRGB(255,221,168) or p:GetAttribute("LightBaseColor")
    for _,l in ipairs(p:GetChildren()) do if l:IsA("Light") then l.Color=p.Color end end
   end
  end
 end
end
return Theme
