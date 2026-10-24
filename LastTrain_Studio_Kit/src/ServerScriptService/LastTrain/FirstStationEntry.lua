local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Access=require(script.Parent.TicketAccess)
local Entry={}
Entry.__index=Entry
function Entry:Instruction(player)
 if not self.Access:HasTicket(player) then return "① 領取車票：前往入口取票機，領取無目的地的車票。" end
 if not self.Access:HasEntry(player) then return "② 刷卡進站：到閘門感應區刷卡，每位乘客都需要驗票。" end
 return "③ 上車：通過閘門，前往白色列車；可走進車門或使用「登上列車」提示。"
end
function Entry:CanBoard(player,station) return station~=1 or self.Access:HasEntry(player) end
function Entry:Notify(player,text)
 if (workspace:GetAttribute("LastTrainStation") or 1)==1 and player.Parent==Players then self.NotifyPlayer(player,text or self:Instruction(player)) end
end
function Entry:Effect(player,kind,screen,anomaly)
 self.Remote:FireClient(player,{Kind=kind,Screen=screen,Anomaly=anomaly==true})
end
function Entry:SetGate(gate,open)
 gate.Model:SetAttribute("Open",open)
 for _,leaf in ipairs(gate.Leaves) do
  if leaf.Tween then leaf.Tween:Cancel() end
  leaf.Part.CanCollide=false
  local target=open and leaf.Open or leaf.Closed
  local tween=TweenService:Create(leaf.Part,TweenInfo.new(.4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{CFrame=target})
  leaf.Tween=tween
  tween.Completed:Once(function(state)
   if state==Enum.PlaybackState.Completed and leaf.Tween==tween then leaf.Part.CanCollide=not open end
  end)
  tween:Play()
 end
end
function Entry:OpenGate(gate)
 gate.Version+=1; local version=gate.Version
 self:SetGate(gate,true)
 task.delay(3,function()
  if gate.Version~=version or not gate.Model.Parent then return end
  for _,p in ipairs(Players:GetPlayers()) do
   local r=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
   if r and math.abs(r.Position.X-self.Config.FirstStationGateX)<1.8 and math.abs(r.Position.Z-gate.Model:GetAttribute("LaneZ"))<2 then
    self:OpenGate(gate); return
   end
  end
  self:SetGate(gate,false)
 end)
end
function Entry:Near(player,anchor,prompt)
 local c=player.Character; local r=c and c:FindFirstChild("HumanoidRootPart")
 local h=c and c:FindFirstChildWhichIsA("Humanoid")
 return player.Parent==Players and r and h and h.Health>0 and (r.Position-anchor.Position).Magnitude<=prompt.MaxActivationDistance+1
  and (workspace:GetAttribute("LastTrainStation") or 1)==1 and not workspace:GetAttribute("LastTrainTraveling") and self.Train:GetAttribute("DoorsOpen")
end
function Entry:Enforce(player)
 if (workspace:GetAttribute("LastTrainStation") or 1)~=1 or self.Access:HasEntry(player) then return end
 local c=player.Character; local r=c and c:FindFirstChild("HumanoidRootPart")
 if not r or r.Position.X<=self.Config.FirstStationGateX+1 then return end
 local h=c:FindFirstChildWhichIsA("Humanoid")
 if h and h.SeatPart then
  local weld=h.SeatPart:FindFirstChild("SeatWeld"); h.Sit=false; if weld then weld:Destroy() end
 end
 c:PivotTo(CFrame.new(self.Config.FirstStationGateX-9,3.2,-22)*CFrame.Angles(0,-math.pi/2,0))
 r.AssemblyLinearVelocity=Vector3.zero; r.AssemblyAngularVelocity=Vector3.zero
 player:SetAttribute("OnLastTrain",false)
 if not self.LastNotice[player] or os.clock()-self.LastNotice[player]>2 then
  self.LastNotice[player]=os.clock(); self:Notify(player)
 end
end
function Entry.new(world,train,config,notify)
 local self=setmetatable({Access=Access.new(),Config=config,Train=train,NotifyPlayer=notify,LastNotice={},Gates={}},Entry)
 self.Remote=ReplicatedStorage.LastTrain.Remotes:WaitForChild("TicketUpdate")
 for _,model in ipairs(world.Props.FirstStationEntry:GetChildren()) do
  if model:GetAttribute("TicketGate") then
   local gate={Model=model,Leaves={},Version=0}
   for _,p in ipairs(model:GetChildren()) do
    if p.Name=="TicketGateLeaf" then
     table.insert(gate.Leaves,{Part=p,Closed=p.CFrame,Open=p.CFrame+Vector3.new(0,0,p:GetAttribute("OpenShiftZ"))})
    end
   end
   self.Gates[model.Name]=gate
  end
 end
 for _,anchor in ipairs(world.Objectives:GetChildren()) do
  local kind=anchor:GetAttribute("PromptType")
  local prompt=anchor:FindFirstChildOfClass("ProximityPrompt")
  if prompt and (kind=="CollectTicket" or kind=="TicketReader") then prompt.Triggered:Connect(function(player)
   if not self:Near(player,anchor,prompt) then return end
   if kind=="CollectTicket" then
    self.Access:Collect(player); player:SetAttribute("FirstStationHasTicket",true)
    self:Effect(player,"Collected"); self:Notify(player)
   else
    local gate=self.Gates[anchor:GetAttribute("GateName")]
    local ok,first=self.Access:Validate(player)
    if not ok then
     self:Effect(player,"Rejected",gate.Model.ReaderScreen)
     self:Notify(player,"請先到入口取票機領取車票，再來刷卡進站。"); return
    end
    player:SetAttribute("FirstStationValidated",true)
    self:OpenGate(gate)
    self:Effect(player,"Accepted",gate.Model.ReaderScreen,first)
    self:Notify(player)
   end
  end) end
 end
 local function initialize(player)
  player:SetAttribute("FirstStationHasTicket",false); player:SetAttribute("FirstStationValidated",false)
  player.CharacterAdded:Connect(function() task.delay(1,function() self:Notify(player) end) end)
  task.delay(1,function() self:Notify(player) end)
 end
 Players.PlayerAdded:Connect(initialize)
 for _,player in ipairs(Players:GetPlayers()) do initialize(player) end
 Players.PlayerRemoving:Connect(function(player) self.Access:Forget(player); self.LastNotice[player]=nil end)
 return self
end
return Entry
