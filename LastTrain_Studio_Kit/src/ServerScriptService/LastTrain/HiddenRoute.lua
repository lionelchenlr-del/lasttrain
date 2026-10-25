-- A round-scoped, free hidden chapter. The real passenger train is never moved.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Http=game:GetService("HttpService")
local Profiles=require(script.Parent.ProfileService)
local Route={};Route.__index=Route
local C={navy=Color3.fromRGB(22,33,49),white=Color3.fromRGB(235,234,225),gold=Color3.fromRGB(234,175,83),blue=Color3.fromRGB(91,192,228)}
local evidence={
 Original={name="原始乘客名單",text="23:40 原始封存名單\n乘客共 36 人。\n008：陳先生　009：紅衣孩子　010：林小姐\n附註：009 持有白橘單程票，尚未離站。"},
 Public={name="公開事故報告",text="對外報告：乘客共 35 人。\n008：陳先生　010：林小姐\n009 欄位被整行刪除。\n簽核：調度主任 周啟明。"},
 Tape={name="調度錄音",text="23:45：停止發車。\n23:46：解除門鎖。\n23:47：開啟出口。\n另一段覆寫錄音：『照常發車，把 009 從名單移除。』\n這不是一場單純的失蹤事故。"},
}
function Route.new()
 local self=setmetatable({Unlocked=false,Allowed={},At={},Tickets={},Origins={},Sessions={},Last={},Clues={},Compared=false,Sequence=0,Done=false,Sent={},Rewarded={},Anchors={}},Route)
 self.Remote=RS.LastTrain.Remotes:WaitForChild("HiddenRouteUpdate")
 RS.LastTrain.Remotes:WaitForChild("HiddenRouteRequest").OnServerInvoke=function(p,action,token,value) return self:Request(p,action,token,value) end
 local function hook(p)
  p.CharacterAdded:Connect(function()
   if self.At[p.UserId] then task.delay(1,function() if p.Parent then self:Place(p,self.At[p.UserId]);self:Send(p) end end) end
  end)
 end
 Players.PlayerAdded:Connect(hook);for _,p in ipairs(Players:GetPlayers()) do hook(p) end
 Players.PlayerRemoving:Connect(function(p) self.Sessions[p.UserId]=nil;self.Last[p.UserId]=nil;self.At[p.UserId]=nil end)
 return self
end
function Route:Unlock()
 self.Unlocked=true
 for _,p in ipairs(Players:GetPlayers()) do self.Allowed[p.UserId]=true;p:SetAttribute("HiddenRouteUnlocked",true) end
end
function Route:Snapshot(p,message)
 local count=0;for _ in pairs(self.Clues) do count+=1 end
 return {ok=true,station=self.At[p.UserId],clues=count,compared=self.Compared,ticket=self.Tickets[p.UserId]==true,sequence=self.Sequence,done=self.Done,message=message or "",goal=self.At[p.UserId]==9 and (self.Sequence<3 and "調度室：按時間順序重建三段廣播。" or "證據已重建，前往公開廣播台。") or (self.Compared and "領取白橘調查票，再前往封存入口。" or "調查三份紀錄，找出被刪除的乘客。")}
end
function Route:Send(p,message,extra)
 local s=self:Snapshot(p,message);for k,v in pairs(extra or {}) do s[k]=v end;self.Remote:FireClient(p,s);return s
end
function Route:Broadcast(message)
 for _,p in ipairs(Players:GetPlayers()) do if self.At[p.UserId] then self:Send(p,message) end end
end
function Route:Near(p,a)
 local c=p.Character;local r=c and c:FindFirstChild("HumanoidRootPart");local h=c and c:FindFirstChildOfClass("Humanoid")
 return r and h and h.Health>0 and a and a.Parent and (r.Position-a.Position).Magnitude<=14
end
function Route:Build()
 if self.Model then return end
 local m=Instance.new("Model");m.Name="LastTrainHiddenRoute";self.Model=m;m.Parent=workspace
 local function part(name,size,position,color,collide)
  local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=CFrame.new(position);p.Color=color;p.Anchored=true;p.CanCollide=collide==true;p.CanTouch=false;p.Material=Enum.Material.SmoothPlastic;p.Parent=m;return p
 end
 local function sign(p,text)
  local s=Instance.new("SurfaceGui");s.Face=Enum.NormalId.Back;s.CanvasSize=Vector2.new(900,240);s.Parent=p
  local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Text=text;t.TextColor3=C.gold;t.TextScaled=true;t.Font=Enum.Font.GothamBold;t.Parent=s
 end
 local function desk(id,name,station,x,z)
  local y=station==8 and 800 or 1040
  local p=part(id,Vector3.new(7,3,3),Vector3.new(x,y+2,z),C.navy,true);self.Anchors[id]=p;p:SetAttribute("HiddenStation",station)
  local screen=part(id.."Screen",Vector3.new(6,2,.3),Vector3.new(x,y+4.4,z),C.navy,false);sign(screen,name)
  local b=Instance.new("BillboardGui");b.Size=UDim2.fromOffset(210,48);b.StudsOffsetWorldSpace=Vector3.new(0,7,0);b.MaxDistance=90;b.AlwaysOnTop=true;b.Parent=p
  local l=Instance.new("TextLabel");l.Size=UDim2.fromScale(1,1);l.BackgroundColor3=C.navy;l.BackgroundTransparency=.18;l.Text=name;l.TextColor3=C.gold;l.TextSize=16;l.TextWrapped=true;l.Parent=b
  local prompt=Instance.new("ProximityPrompt");prompt.ActionText="調查";prompt.ObjectText=name;prompt.MaxActivationDistance=12;prompt.HoldDuration=.3;prompt.RequiresLineOfSight=false;prompt.Parent=p
  prompt.Triggered:Connect(function(player) self:Prompt(player,id) end)
 end
 for _,station in ipairs({8,9}) do
  local y=station==8 and 800 or 1040
  part("Platform"..station,Vector3.new(150,1,76),Vector3.new(0,y,0),Color3.fromRGB(79,86,98),true)
  for _,x in ipairs({-75,75}) do part("SafetyWall",Vector3.new(1,10,76),Vector3.new(x,y+5,0),C.navy,true) end
  for _,z in ipairs({-38,38}) do part("SafetyWall",Vector3.new(150,10,1),Vector3.new(0,y+5,z),C.navy,true) end
  part("Ceiling",Vector3.new(150,1,76),Vector3.new(0,y+19,0),C.navy,true)
  local board=part("StationSign"..station,Vector3.new(42,5,1),Vector3.new(0,y+13,-34),C.navy,false)
  sign(board,station==8 and "STATION 08  封存檔案室" or "STATION 09  被刪除的名字")
  for x=-60,60,20 do
   local lamp=part("CeilingLight",Vector3.new(12,.2,1),Vector3.new(x,y+17,4),C.white,false);lamp.Material=Enum.Material.Neon
   local light=Instance.new("PointLight");light.Range=36;light.Brightness=2;light.Shadows=false;light.Parent=lamp
   local strip=part("GuideLight",Vector3.new(12,.06,.3),Vector3.new(x,y+.56,24),station==8 and C.gold or C.blue,false);strip.Material=Enum.Material.Neon
  end
 end
 desk("Original",evidence.Original.name,8,-48,-15);desk("Public",evidence.Public.name,8,-16,-15);desk("Tape",evidence.Tape.name,8,16,-15)
 desk("Compare","乘客紀錄比對台",8,48,-15);desk("Ticket","調查票取票機",8,48,10);desk("Gate09","封存入口 · 第九站",8,0,-28)
 desk("Reconstruct","事故廣播重建台",9,-25,-12);desk("Publish","公開證據廣播台",9,25,-12);desk("Return08","返回第八站",9,55,12);desk("ReturnTrain","結束調查 · 返回列車月台",9,-55,12)
 -- White/orange ticket sculpture is confined to the platform terminal.
 part("TicketWhite",Vector3.new(4,.08,2),Vector3.new(48,803.55,10),C.white,false)
 part("TicketOrange",Vector3.new(4,.1,.5),Vector3.new(48,803.62,10.7),Color3.fromRGB(231,118,43),false)
end
function Route:Place(p,index)
 self:Build()
 local c=p.Character;local h=c and c:FindFirstChildOfClass("Humanoid");local r=c and c:FindFirstChild("HumanoidRootPart")
 if not h or h.Health<=0 or not r then return false end
 local seat=h.SeatPart;h.Sit=false
 local weld=seat and seat:FindFirstChild("SeatWeld");if weld then weld:Destroy() end
 c:PivotTo(CFrame.new(0,index==8 and 804 or 1044,23));r.AssemblyLinearVelocity=Vector3.zero;r.AssemblyAngularVelocity=Vector3.zero
 self.At[p.UserId]=index;self.Sessions[p.UserId]=nil;p:SetAttribute("OnLastTrain",false);p:SetAttribute("HiddenRouteStation",index)
 return true
end
function Route:Open(p,id,kind,text)
 local token=Http:GenerateGUID(false);self.Sessions[p.UserId]={token=token,id=id,station=self.At[p.UserId]}
 self:Send(p,"",{open=true,token=token,kind=kind,title=self.Anchors[id].ProximityPrompt.ObjectText,text=text})
end
function Route:Prompt(p,id)
 local uid=p.UserId;local a=self.Anchors[id]
 if not self.Allowed[uid] or not a or self.At[uid]~=a:GetAttribute("HiddenStation") or not self:Near(p,a) then return end
 if evidence[id] then
  self.Clues[id]=true;self:Broadcast("已找到："..evidence[id].name);self:Open(p,id,"Read",evidence[id].text)
 elseif id=="Compare" then
  self:Open(p,id,"Compare","原始名單 36 人，公開報告只有 35 人。\n哪一位乘客被刻意從報告刪除？")
 elseif id=="Ticket" then
  if not self.Compared then self:Send(p,"先在比對台確認被刪除的乘客。");return end
  self.Tickets[uid]=true;self:Send(p,"已取得白橘調查票。前往『封存入口 · 第九站』。")
 elseif id=="Gate09" then
  if not self.Compared or not self.Tickets[uid] then self:Send(p,"第九站需要調查票。比對名單後，請到取票機領取。");return end
  if self:Place(p,9) then self:Send(p,"隱藏第九站已抵達。你找到的不是出口，而是被改寫的事故。");if self.Done then self:Complete(p) end end
 elseif id=="Return08" then self:Place(p,8);self:Send(p)
 elseif id=="ReturnTrain" then
  if not self.Done then self:Send(p,"先公開原始證據，讓失蹤乘客回家。");return end
  local c=p.Character;local h=c and c:FindFirstChildOfClass("Humanoid");local r=c and c:FindFirstChild("HumanoidRootPart")
  if not r or not h or h.Health<=0 then return end
  self.At[uid]=nil;self.Sessions[uid]=nil;p:SetAttribute("HiddenRouteStation",nil)
  c:PivotTo(self.Origins[uid] or CFrame.new(-80,3.5,-22));r.AssemblyLinearVelocity=Vector3.zero;r.AssemblyAngularVelocity=Vector3.zero
  self:Send(p,"本局隱藏調查已完成。",{closed=true,left=true})
 elseif id=="Reconstruct" then
  self:Open(p,id,"Sequence","重建未被覆寫的安全廣播。\n23:45 停止發車 → 23:46 解除門鎖 → 23:47 開啟出口。")
 elseif id=="Publish" then
  self:Open(p,id,"Publish","原始錄音證實，調度主任為了掩蓋安全事故，刪除了第 009 名乘客。\n公開原始名單與錄音，讓所有人記得這個孩子。")
 end
end
function Route:Complete(p)
 if not self.Done then self.Done=true;self:Broadcast("原始證據已公開。被刪除的名字，終於回到名單。") end
 for _,member in ipairs(Players:GetPlayers()) do
  local uid=member.UserId
  if self.At[uid]==9 and not self.Sent[uid] then
   self.Sent[uid]=true
   self.Sessions[uid]=nil
   self:Send(member,"",{closed=true,ending="Station09"})
   if not self.Rewarded[uid] then self.Rewarded[uid]=true;task.spawn(function() Profiles.AwardCoins(member,90) end) end
  end
 end
end
function Route:Request(p,action,token,value)
 if type(action)~="string" or not self.Unlocked or not self.Allowed[p.UserId] then return {ok=false,message="需要先完成第七站的第八站隱藏結局。"} end
 local uid=p.UserId;local now=os.clock()
 if now-(self.Last[uid] or 0)<.15 then return {ok=false,message="請稍候再操作。"} end;self.Last[uid]=now
 if action=="Enter8" then
  if self.At[uid] then return self:Send(p,"已在隱藏支線中。") end
  local c=p.Character;if c then self.Origins[uid]=c:GetPivot() end
  if self:Place(p,8) then return self:Send(p,"第八站：調查名單、報告與錄音，尋找第九站的入口。") end
  return {ok=false,message="請等待角色重生後再進入。"}
 end
 if action=="State" then return self:Snapshot(p) end
 if action=="Close" then self.Sessions[uid]=nil;return {ok=true,closed=true} end
 local session=self.Sessions[uid]
 if not session or type(token)~="string" or session.token~=token or session.station~=self.At[uid] or not self:Near(p,self.Anchors[session.id]) then return {ok=false,closed=true,message="請重新靠近任務台操作。"} end
 if action=="Compare" and session.id=="Compare" then
  if not (self.Clues.Original and self.Clues.Public and self.Clues.Tape) then return self:Send(p,"請先調查三份紀錄。") end
  if value~="009" then return self:Send(p,"比對失敗。找出原始名單存在、公開報告卻消失的編號。") end
  self.Compared=true;self.Sessions[uid]=nil;self:Send(p,"",{closed=true});self:Broadcast("確認第 009 名乘客遭到刪除。調查票取票機已解鎖。")
  return {ok=true,closed=true}
 elseif action=="Sequence" and session.id=="Reconstruct" and type(value)=="number" then
  if self.Sequence<3 then
   if value==self.Sequence+1 then self.Sequence+=1 else self.Sequence=0;return self:Send(p,"順序錯誤，請依 23:45 → 23:46 → 23:47 重建。") end
  end
  if self.Sequence==3 then
   self.Sessions[uid]=nil
   self:Broadcast("三段安全廣播已還原。前往公開證據廣播台。")
   return self:Send(p,"",{closed=true})
  end
  return self:Send(p,"已還原一段廣播。")
 elseif action=="Publish" and session.id=="Publish" then
  if self.Sequence<3 then return self:Send(p,"先在重建台還原三段安全廣播。") end
  self:Complete(p);return {ok=true,closed=true}
 end
 return {ok=false,message="這個任務台沒有此操作。"}
end
return Route
