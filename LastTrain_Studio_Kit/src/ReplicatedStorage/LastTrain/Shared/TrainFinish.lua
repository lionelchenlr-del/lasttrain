-- A shared finish keeps lobby and playable stock in the same silver livery.
local Finish = {}
Finish.Silver = Color3.fromRGB(184, 192, 203)
Finish.Roof = Color3.fromRGB(197, 204, 213)
Finish.Orange = Color3.fromRGB(219, 106, 38)
Finish.Graphite = Color3.fromRGB(25, 29, 35)
local bodyNames = {
 CarBodyShell=true, ContinuousCoachRoof=true, RoofShoulder=true,
 CoachLowerSideSkin=true, CoachUpperSideSkin=true, DoorJambLowerSkin=true,
 DoorJambHeaderSkin=true, DoorJambMiddleSkin=true, CoachEndSideSkin=true,
 LowerSidePanel_Front=true, LowerSidePanel_Rear=true, SideHeader=true,
 FlushServicePanel=true, DoorFrame=true, ConnectedCeiling=true,
 DisplayCarBody=true, DisplayShoulderBody=true, DisplaySculptedNose=true, DisplayPassengerDoor=true,
}
local orangeNames = {CyanBeltline=true,BeltlineAccent_Front=true,BeltlineAccent_Rear=true,DisplayCyanStripe=true}
local blackNames = {GoldBeltline=true,ContinuousLowerSkirt=true,DisplayLowerBlueStripe=true,DisplayContinuousSkirt=true}
function Finish.Apply(model)
 for _,p in ipairs(model:GetDescendants()) do
  if p:IsA("BasePart") then
   if bodyNames[p.Name] then
    p.Color = p.Name=="ContinuousCoachRoof" and Finish.Roof or Finish.Silver
    p.Material = Enum.Material.Metal
    p.Reflectance = 0.2
   elseif orangeNames[p.Name] then
    p.Color=Finish.Orange; p.Material=Enum.Material.Metal; p.Reflectance=0.08
   elseif blackNames[p.Name] then
    p.Color=Finish.Graphite; p.Material=Enum.Material.Metal; p.Reflectance=0.1
   elseif p.Name=="PanoramicWindowBand" or p.Name=="DisplayWindowBand" then
    p.Color=Color3.fromRGB(166,195,204); p.Material=Enum.Material.Glass
    p.Reflectance=0.04; p.Transparency=0.72
   elseif p.Name=="SlidingDoor" then
    -- A single translucent layer avoids refractive Glass sorting against the
    -- stationary passenger glazing while the leaf slides across the body.
    p.Color=Color3.fromRGB(174,197,204); p.Material=Enum.Material.SmoothPlastic
    p.Reflectance=0; p.Transparency=0.58
   end
  end
 end
end
return Finish
