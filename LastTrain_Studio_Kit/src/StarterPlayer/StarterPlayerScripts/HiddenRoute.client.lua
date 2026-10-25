local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local player=Players.LocalPlayer
local remotes=game.ReplicatedStorage:WaitForChild("LastTrain"):WaitForChild("Remotes")
local request=remotes:WaitForChild("HiddenRouteRequest")
local gui=Instance.new("ScreenGui");gui.Name="HiddenRouteUI";gui.ResetOnSpawn=false;gui.DisplayOrder=48;gui.Parent=player:WaitForChild("PlayerGui")
local navy=Color3.fromRGB(22,33,49);local cream=Color3.fromRGB(248,245,235);local orange=Color3.fromRGB(218,113,45)
local function make(kind,parent,name,pos,size,color)
 local x=Instance.new(kind);x.Name=name;x.Position=pos;x.Size=size;x.BackgroundColor3=color or navy;x.BorderSizePixel=0;x.Parent=parent;return x
end
local function text(parent,name,value,pos,size,fontSize)
 local x=make("TextLabel",parent,name,pos,size);x.BackgroundTransparency=1;x.Text=value;x.TextColor3=cream;x.TextSize=fontSize or 18;x.TextWrapped=true;x.Font=Enum.Font.GothamMedium;return x
end
local function button(parent,name,value,pos,size,callback)
 local x=make("TextButton",parent,name,pos,size,orange);x.Text=value;x.TextColor3=cream;x.TextSize=16;x.Font=Enum.Font.GothamMedium;x.TextWrapped=true;x.Activated:Connect(callback);return x
end
local hud=text(gui,"HiddenGoal","",UDim2.new(.5,0,0,85),UDim2.new(.9,0,0,82),17);hud.AnchorPoint=Vector2.new(.5,0);local hudLimit=Instance.new("UISizeConstraint");hudLimit.MaxSize=Vector2.new(460,82);hudLimit.Parent=hud;hud.BackgroundTransparency=.12;hud.Visible=false
local ticketCard=make("Frame",gui,"InvestigationTicket",UDim2.new(1,-235,1,-155),UDim2.fromOffset(215,103),cream);ticketCard.Visible=false
local ticketBand=text(ticketCard,"Band","末班車 · 調查通行票",UDim2.new(),UDim2.new(1,0,0,28),15);ticketBand.BackgroundTransparency=0;ticketBand.BackgroundColor3=orange
local ticketText=text(ticketCard,"Details","009  ·  白橘調查票\n封存檔案室 → 第九站\n免費領取 · 本局有效",UDim2.fromOffset(9,33),UDim2.new(1,-18,0,63),14);ticketText.TextColor3=navy
local enter
local panel=make("Frame",gui,"InvestigationPanel",UDim2.fromScale(.13,.2),UDim2.fromScale(.74,.65));panel.Visible=false
local limit=Instance.new("UISizeConstraint");limit.MaxSize=Vector2.new(800,560);limit.MinSize=Vector2.new(260,260);limit.Parent=panel
local title=text(panel,"Title","",UDim2.fromScale(.06,.03),UDim2.fromScale(.8,.12),24)
local body=make("ScrollingFrame",panel,"Body",UDim2.fromScale(.06,.18),UDim2.fromScale(.88,.38));body.BackgroundTransparency=1;body.ScrollBarThickness=4;body.AutomaticCanvasSize=Enum.AutomaticSize.Y;body.CanvasSize=UDim2.new()
local content=text(body,"Document","",UDim2.new(),UDim2.new(1,-12,0,0),19);content.AutomaticSize=Enum.AutomaticSize.Y;content.TextXAlignment=Enum.TextXAlignment.Left;content.TextYAlignment=Enum.TextYAlignment.Top
local status=text(panel,"Status","",UDim2.fromScale(.06,.58),UDim2.fromScale(.88,.12),16)
local actions=make("Frame",panel,"Actions",UDim2.fromScale(.06,.73),UDim2.fromScale(.88,.22));actions.BackgroundTransparency=1
local layout=Instance.new("UIListLayout");layout.FillDirection=Enum.FillDirection.Horizontal;layout.Padding=UDim.new(.02,0);layout.Parent=actions
local session,controls,busy=nil,nil,false
local apply,send
local function close()
 panel.Visible=false;session=nil;player:SetAttribute("PlatformTaskOpen",false)
 if controls then controls:Enable();controls=nil end
end
button(panel,"Close","×",UDim2.new(1,-45,0,7),UDim2.fromOffset(36,36),function() local token=session and session.token;close();task.spawn(function() pcall(request.InvokeServer,request,"Close",token) end) end)
local function render()
 for _,x in ipairs(actions:GetChildren()) do if x:IsA("GuiButton") then x:Destroy() end end
 if not session then return end
 local kind=session.kind
 local function option(name,label,action,value,n)
  button(actions,name,label,UDim2.new(),UDim2.new(1/n-.02,0,1,0),function() send(action,value) end)
 end
 if kind=="Compare" then
  for i,id in ipairs({"008","009","010"}) do option("Passenger"..id,"乘客 "..id,"Compare",id,3) end
 elseif kind=="Sequence" then
  for _,row in ipairs({{2,"解除門鎖"},{3,"開啟出口"},{1,"停止發車"}}) do option("Broadcast"..row[1],row[2],"Sequence",row[1],3) end
 elseif kind=="Publish" then option("PublishEvidence","公開原始證據","Publish",nil,1)
 else option("ReadDone","記下線索，繼續調查","Close",nil,1) end
end
apply=function(s)
 if type(s)~="table" then return end
 if s.station then
  ticketCard.Visible=s.ticket==true
  hud.Visible=true;hud.Text=string.format("隱藏第 %d 站  ·  %s\n線索 %d/3  ·  廣播 %d/3",s.station,s.done and "真相已公開" or s.goal or "繼續調查",s.clues or 0,s.sequence or 0)
 end
 if s.message and s.message~="" then status.Text=s.message;if not s.station and not panel.Visible then hud.Visible=true;hud.Text=s.message end end
 if s.left then hud.Visible=false;ticketCard.Visible=false end
 if s.closed or s.ending then close();return end
 if s.open then
  close();session=s;panel.Visible=true;title.Text=s.title or "封存檔案";content.Text=s.text or "";body.CanvasPosition=Vector2.zero;status.Text=""
  player:SetAttribute("PlatformTaskOpen",true);controls=require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls();controls:Disable();render()
 elseif session and s.sequence then status.Text=(s.message or "").."\n已還原 "..s.sequence.." / 3 段" end
end
send=function(action,value)
 if busy then return end;busy=true
 local token=session and session.token
 local ok,s=pcall(request.InvokeServer,request,action,token,value);busy=false
 if ok then apply(s) else status.Text="連線稍慢，請再試一次。" end
 if action=="Close" then close() end
end
enter=button(gui,"ContinueInvestigation","繼續隱藏調查 · 第八站",UDim2.new(.5,-150,1,-140),UDim2.fromOffset(300,48),function()
 if player:GetAttribute("LastTrainCinematic") then return end
 send("Enter8")
end)
local function refreshEntry() enter.Visible=player:GetAttribute("HiddenRouteUnlocked")==true and player:GetAttribute("HiddenRouteStation")==nil end
player:GetAttributeChangedSignal("HiddenRouteUnlocked"):Connect(refreshEntry);player:GetAttributeChangedSignal("HiddenRouteStation"):Connect(refreshEntry);refreshEntry()
remotes:WaitForChild("HiddenRouteUpdate").OnClientEvent:Connect(apply)
UIS.InputBegan:Connect(function(input,processed)
 if session and (input.KeyCode==Enum.KeyCode.Escape or not processed and input.KeyCode==Enum.KeyCode.Q) then send("Close") end
end)
player.CharacterAdded:Connect(function() close();refreshEntry() end)
game:GetService("RunService").Heartbeat:Connect(function()
 if session then
  local c=player.Character;local h=c and c:FindFirstChildOfClass("Humanoid");local r=c and c:FindFirstChild("HumanoidRootPart")
  if not h or h.Health<=0 or not r then close() end
 end
end)
