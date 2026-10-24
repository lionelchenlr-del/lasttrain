local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local RS=game:GetService("ReplicatedStorage")
local remotes=RS:WaitForChild("LastTrain"):WaitForChild("Remotes")
local notice=remotes:WaitForChild("PremiumNotice")
while workspace:GetAttribute("LastTrainMode")==nil do workspace:GetAttributeChangedSignal("LastTrainMode"):Wait() end
if workspace:GetAttribute("LastTrainMode")~="Lobby" then return end
local lobby=workspace:WaitForChild("LastTrainLobby")
local lounge=Instance.new("Model");lounge.Name="VIPLounge";lounge.Parent=lobby
local function part(name,size,pos,color)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.Position=pos;p.Color=color;p.Material=Enum.Material.SmoothPlastic
 p.Anchored=true;p.Parent=lounge;return p
end
local gold=Color3.fromRGB(212,182,112)
part("LoungeCarpet",Vector3.new(30,.06,22),Vector3.new(-59,.05,57),Color3.fromRGB(39,45,59))
for _,x in ipairs({-74,-44}) do part("LoungeSide",Vector3.new(.15,3,22),Vector3.new(x,1.5,57),Color3.fromRGB(55,63,77)) end
local panel=part("VIPLoungeSign",Vector3.new(20,2,.14),Vector3.new(-59,5,67),Color3.fromRGB(24,31,44))
local g=Instance.new("SurfaceGui");g.Face=Enum.NormalId.Front;g.CanvasSize=Vector2.new(800,100);g.LightInfluence=0;g.Parent=panel
local text=Instance.new("TextLabel");text.Size=UDim2.fromScale(1,1);text.BackgroundTransparency=1;text.Text="VIP  LOUNGE  ·  專屬候車區";text.TextColor3=gold;text.Font=Enum.Font.GothamBold;text.TextScaled=true;text.Parent=g
for _,x in ipairs({-68,-59,-50}) do
 local seat=Instance.new("Seat");seat.Name="VIPLoungeSeat";seat.Size=Vector3.new(2.4,.4,2.4);seat.Position=Vector3.new(x,1.2,61);seat.Color=Color3.fromRGB(41,47,65);seat.Anchored=true;seat.CanTouch=false;seat.Parent=lounge
 part("LoungeSeatBack",Vector3.new(2.4,2.4,.3),Vector3.new(x,2.3,62.1),Color3.fromRGB(41,47,65))
 local prompt=Instance.new("ProximityPrompt");prompt.ActionText="坐下";prompt.ObjectText="VIP 專屬候車座位";prompt.MaxActivationDistance=7;prompt.Parent=seat
 prompt.Triggered:Connect(function(p)
  local c=p.Character;local h=c and c:FindFirstChildWhichIsA("Humanoid");local r=c and c:FindFirstChild("HumanoidRootPart")
  if p:GetAttribute("Owns_VIP") and h and h.Health>0 and r and (r.Position-seat.Position).Magnitude<8 and not seat.Occupant then seat:Sit(h) end
 end)
end
local noticeAt={}
RunService.Heartbeat:Connect(function()
 if not lounge.Parent then return end
 for _,p in ipairs(Players:GetPlayers()) do
  local c=p.Character;local r=c and c:FindFirstChild("HumanoidRootPart")
  if r and not p:GetAttribute("Owns_VIP") and r.Position.X> -74 and r.Position.X< -44 and r.Position.Z>46 and r.Position.Z<68 then
   local h=c:FindFirstChildWhichIsA("Humanoid");if h then
    local seat=h.SeatPart;h.Sit=false
    local weld=seat and seat:FindFirstChild("SeatWeld");if weld then weld:Destroy() end
   end
   c:PivotTo(CFrame.new(-59,3.5,42));r.AssemblyLinearVelocity=Vector3.zero
   if os.clock()-(noticeAt[p] or 0)>3 then noticeAt[p]=os.clock();notice:FireClient(p,"VIP 專屬候車區；可在精品商店預覽。","VIP") end
  end
 end
end)
Players.PlayerRemoving:Connect(function(p) noticeAt[p]=nil end)
