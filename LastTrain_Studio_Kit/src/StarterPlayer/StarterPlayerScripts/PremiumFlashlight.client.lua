local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local p=Players.LocalPlayer
local model=Instance.new("Model");model.Name="NeonFlashlightView"
local pieces={}
local function part(name,size,offset,color,material)
 local v=Instance.new("Part");v.Name=name;v.Size=size;v.Color=color;v.Material=material or Enum.Material.SmoothPlastic
 v.Anchored=true;v.CanCollide=false;v.CanTouch=false;v.CanQuery=false;v.CastShadow=false;v.Parent=model
 table.insert(pieces,{Part=v,Offset=offset});return v
end
part("Grip",Vector3.new(.22,.22,.63),CFrame.new(0,0,.18),Color3.fromRGB(29,35,45))
part("Head",Vector3.new(.32,.32,.25),CFrame.new(0,0,-.18),Color3.fromRGB(58,65,76))
local ring=part("NeonRing",Vector3.new(.34,.34,.045),CFrame.new(0,0,-.315),Color3.fromRGB(104,225,240),Enum.Material.Neon)
local colors={Ice=Color3.fromRGB(173,235,255),Amber=Color3.fromRGB(255,209,137),Violet=Color3.fromRGB(202,184,255)}
Run:BindToRenderStep("PremiumFlashlight",Enum.RenderPriority.Camera.Value+2,function()
 local camera=workspace.CurrentCamera
 if not camera then return end
 local light=camera:FindFirstChild("LastTrainFlashlight")
 local beam=light and light:FindFirstChild("LastTrainBeam")
 local enabled=workspace:GetAttribute("LastTrainMode")=="Game" and p:GetAttribute("EquippedFlashlight")=="Neon"
 if beam then beam.Color=enabled and (colors[p:GetAttribute("FlashlightColor")] or colors.Ice) or Color3.fromRGB(255,255,255) end
 if enabled and beam and beam.Enabled then
  model.Parent=camera;ring.Color=colors[p:GetAttribute("FlashlightColor")] or colors.Ice
  local pose=camera.CFrame*CFrame.new(.58,-.48,-.9)*CFrame.Angles(math.rad(-5),math.rad(-6),0)
  for _,item in ipairs(pieces) do item.Part.CFrame=pose*item.Offset end
 else model.Parent=nil end
end)
