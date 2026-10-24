local RS=game:GetService("ReplicatedStorage")
local remotes=RS:WaitForChild("LastTrain"):WaitForChild("Remotes")
local notice=remotes:WaitForChild("PremiumNotice")
local Players=game:GetService("Players")
local Access=require(script.Parent.PremiumAccess)
local Operations=require(script.Parent.TrainOperations)
while workspace:GetAttribute("LastTrainMode")~="Game" do workspace:GetAttributeChangedSignal("LastTrainMode"):Wait() end
local w=workspace:WaitForChild("LastTrainWorld")
while not w:GetAttribute("Ready") do w:GetAttributeChangedSignal("Ready"):Wait() end
local train=w.Props.LastTrainCar
local last={}
for _,p in ipairs(train:GetDescendants()) do
 if p:GetAttribute("RoyalFacility")=="TeaBar" then
  local prompt=p:FindFirstChildOfClass("ProximityPrompt")
  prompt.Triggered:Connect(function(player)
   local c=player.Character;local root=c and c:FindFirstChild("HumanoidRootPart")
   if not root or not Operations.Contains(train,c) or (root.Position-p.Position).Magnitude>8 then return end
   if not Access.Has(player,"RoyalCarriage") then notice:FireClient(player,"皇家茶飲吧供皇家乘客與受邀朋友使用。","RoyalCarriage");return end
   if os.clock()-(last[player] or -10)<5 then return end;last[player]=os.clock()
   local backpack=player:FindFirstChildOfClass("Backpack");if not backpack or backpack:FindFirstChild("皇家茶飲") or c:FindFirstChild("皇家茶飲") then return end
   local tea=Instance.new("Tool");tea.Name="皇家茶飲";tea.ToolTip="皇家茶飲吧 · 點擊品嚐";tea.CanBeDropped=false
   local cup=Instance.new("Part");cup.Name="Handle";cup.Shape=Enum.PartType.Cylinder;cup.Size=Vector3.new(.65,.55,.55);cup.Color=Color3.fromRGB(226,212,180);cup.Material=Enum.Material.SmoothPlastic;cup.CanCollide=false;cup.CanTouch=false;cup.Massless=true;cup.Parent=tea
   tea.Grip=CFrame.Angles(0,0,math.pi/2)
   tea.Activated:Connect(function() if tea.Parent==player.Character then tea:Destroy();remotes:WaitForChild("RoyalFeedback"):FireClient(player,"溫熱的皇家茶飲，帶著淡淡花香。") end end)
   tea.Parent=backpack;remotes:WaitForChild("RoyalFeedback"):FireClient(player,"皇家茶飲已放入背包，可裝備品嚐。")
  end)
 end
end
Players.PlayerRemoving:Connect(function(p) last[p]=nil end)
