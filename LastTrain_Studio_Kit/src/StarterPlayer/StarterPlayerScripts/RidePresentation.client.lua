local RS=game:GetService("ReplicatedStorage")
local Tween=game:GetService("TweenService")
local Run=game:GetService("RunService")
local player=game.Players.LocalPlayer
local remotes=RS:WaitForChild("LastTrain"):WaitForChild("Remotes")
local gui=Instance.new("ScreenGui");gui.Name="LastTrainRidePresentation";gui.ResetOnSpawn=false;gui.DisplayOrder=18;gui.Parent=player:WaitForChild("PlayerGui")
local title=Instance.new("TextLabel");title.AnchorPoint=Vector2.new(.5,1);title.Position=UDim2.new(.5,0,1,-24);title.Size=UDim2.fromOffset(460,38);title.BackgroundColor3=Color3.fromRGB(22,28,43);title.BackgroundTransparency=.16;title.TextColor3=Color3.fromRGB(244,223,174);title.Font=Enum.Font.GothamMedium;title.TextSize=15;title.Visible=false;title.Parent=gui
local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=title
local version=0
local function show(text,color)
 version+=1;local token=version;title.Text=text;title.TextColor3=color or Color3.fromRGB(244,223,174);title.TextTransparency=0;title.BackgroundTransparency=.16;title.Visible=true
 task.delay(3,function() if token==version then local t=Tween:Create(title,TweenInfo.new(.6),{TextTransparency=1,BackgroundTransparency=1});t:Play();t.Completed:Wait();if token==version then title.Visible=false end end end)
end
remotes:WaitForChild("RoyalFeedback").OnClientEvent:Connect(show)
local train=nil;local gradients={};local time=0
task.spawn(function()
 while workspace:GetAttribute("LastTrainMode")~="Game" do workspace:GetAttributeChangedSignal("LastTrainMode"):Wait() end
 local w=workspace:WaitForChild("LastTrainWorld")
 while not w:GetAttribute("Ready") do w:GetAttributeChangedSignal("Ready"):Wait() end
 train=w:WaitForChild("Props"):WaitForChild("LastTrainCar")
 local function refresh()
  table.clear(gradients)
  for _,d in ipairs(train:GetDescendants()) do if d:IsA("UIGradient") and d.Name=="GalaxyGradient" then table.insert(gradients,d) end end
 end
 train:GetAttributeChangedSignal("SelectedLivery"):Connect(refresh)
 train.DescendantAdded:Connect(function(d) if d:IsA("UIGradient") and d.Name=="GalaxyGradient" then table.insert(gradients,d) end end)
 refresh()
end)
Run.RenderStepped:Connect(function(dt)
 if not train or train:GetAttribute("SelectedLivery")~="Starfield" then return end
 time+=dt
 for _,g in ipairs(gradients) do g.Offset=Vector2.new(math.sin(time*.12)*.15,math.cos(time*.09)*.08) end
end)
remotes:WaitForChild("ObjectiveUpdate").OnClientEvent:Connect(function(_,_,_,_,_,_,state)
 if state~="Moving" or not train then return end
 local key=train:GetAttribute("SelectedLivery")
 if key=="Royal" then show("♛  ROYAL LAST TRAIN · 皇家白金列車")
 elseif key=="Starfield" then
  local serial=train:GetAttribute("EditionSerial")
  show(serial and string.format("GALAXY LAST TRAIN · #%03d / 500",serial) or "GALAXY LAST TRAIN · LIMITED 500",Color3.fromRGB(187,205,255))
 end
end)
