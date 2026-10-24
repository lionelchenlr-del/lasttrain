-- Round-scoped cooperative platform puzzles. Only this server advances state.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Http=game:GetService("HttpService")
local Challenges={};Challenges.__index=Challenges
local names={PassengerLedger=2,TrueRecording=3,MirrorReport=4,CCTVEvidence=5,TrustConductor=6,ReadAccidentLog=6,LeaveEnding=7,TruthEnding=7,SecretEnding=7}
local titles={[2]="失語站｜失蹤的乘客",[3]="回聲站｜重播燈號",[4]="鏡湖站｜拍下異常倒影",[5]="遺忘站｜監視器倒帶",[6]="終寂站｜恢復事故電路",[7]="不存在的終點｜穩定核心"}
local instructions={[2]="先在月台找齊三張行李牌，再比對紀錄簿，選出沒有離站紀錄的乘客。",[3]="記住四次亮燈的順序，再依序按下同名按鈕。答錯可重播，不會扣除獎勵。",[4]="將畫面中央準星對準藍色人影，保持穩定兩秒，再按快門或 C 拍攝。",[5]="值班便條：調查三天前 23:47、2 號鏡頭。倒帶找出那一格，再截存證據。",[6]="轉動三個配電旋鈕，使箭頭與上方的接線圖一致。通電後決定是否相信站務員。",[7]="等游標進入綠色區域再按「穩定」。依序穩定三個節點，然後選擇結局。"}
local tagText={"12A 林先生：已離站","08B 陳小姐：已離站","03C 紅衣孩童：離站欄空白"}
local allowedChoice={Conductor=true,Records=true}
local allowedEnding={Truth=true,Conductor=true,Station08=true}
function Challenges.new(world,context,complete,notify)
 local self=setmetatable({World=world,Context=context,Complete=complete,Notify=notify,Sessions={},Last={},Tags={},Echo={Progress=0,Sequence={}},Circuit={Dials={0,0,0}},Core={Progress=0,Epoch=workspace:GetServerTimeNow()},CCTV={}},Challenges)
 local random=Random.new();for i=1,4 do self.Echo.Sequence[i]=random:NextInteger(1,3) end
 for i=1,3 do self.Circuit.Dials[i]=random:NextInteger(0,3) end
 if self.Circuit.Dials[1]==1 and self.Circuit.Dials[2]==3 and self.Circuit.Dials[3]==2 then self.Circuit.Dials[1]=0 end
 local remotes=RS.LastTrain:WaitForChild("Remotes");self.Updates=remotes:WaitForChild("PlatformChallengeUpdate")
 remotes:WaitForChild("PlatformChallengeRequest").OnServerInvoke=function(p,token,action,value,origin,direction) return self:Request(p,token,action,value,origin,direction) end
 Players.PlayerRemoving:Connect(function(p) self.Sessions[p]=nil;self.Last[p]=nil end)
 return self
end
function Challenges:Valid(p,anchor,index)
 local stage,station,completed,traveling,pending=self.Context()
 if completed or traveling or pending or stage~=index-1 or station~=index or not anchor or not anchor.Parent then return false end
 local c=p.Character;local root=c and c:FindFirstChild("HumanoidRootPart");local h=c and c:FindFirstChildOfClass("Humanoid")
 local prompt=anchor:FindFirstChildOfClass("ProximityPrompt")
 return root and h and h.Health>0 and prompt and (root.Position-anchor.Position).Magnitude<=prompt.MaxActivationDistance+5
end
function Challenges:Snapshot(p,message)
 local s=self.Sessions[p];if not s then return {ok=false,closed=true} end
 local data={ok=true,token=s.Token,station=s.Station,title=titles[s.Station],instruction=instructions[s.Station],message=message or "",anchor=s.Anchor.Position}
 if s.Station==2 then
  data.tags={};for i=1,3 do data.tags[i]=self.Tags[i] and tagText[i] or "尚未找到行李牌 "..i end
  local count=0;for _ in pairs(self.Tags) do count+=1 end;data.count=count
 elseif s.Station==3 then data.sequence=table.clone(self.Echo.Sequence);data.progress=self.Echo.Progress
 elseif s.Station==4 then
  local target=self.World.Props:FindFirstChild("MirrorWitnessTarget");data.target=target and target.Position
  data.focus=s.FocusStart and math.clamp(workspace:GetServerTimeNow()-s.FocusStart,0,2) or 0
 elseif s.Station==5 then data.camera=s.Camera or 1;data.frame=s.Frame or 0
 elseif s.Station==6 then data.dials=table.clone(self.Circuit.Dials);data.ready=self.Circuit.Ready==true
 elseif s.Station==7 then
  data.progress=self.Core.Progress;data.epoch=self.Core.Epoch;data.ready=self.Core.Progress>=3
  local _,_,_,_,_,choice=self.Context();data.secret=choice=="Records"
 end
 return data
end
function Challenges:UpdateOthers(index)
 for p,s in pairs(self.Sessions) do
  if s.Station==index and p.Parent==Players then self.Updates:FireClient(p,self:Snapshot(p)) end
 end
end
function Challenges:Finish(p,override)
 local s=self.Sessions[p];if not s or not self:Valid(p,s.Anchor,s.Station) then return {ok=false,closed=true} end
 -- RoundController rechecks stage and locks departure before issuing rewards.
 local result=self.Complete(p,s.Anchor,override)
 if result then
  for player in pairs(self.Sessions) do if player.Parent==Players then self.Updates:FireClient(player,{closed=true,ok=true}) end end
  self.Sessions={}
  return {ok=true,closed=true}
 end
 return self:Snapshot(p,"目前無法完成，請確認任務條件。")
end
function Challenges:Open(p,anchor)
 local tag=anchor:GetAttribute("LuggageTagIndex")
 local index=names[anchor.Name] or (tag and 2)
 if not index then return false end
 if not self:Valid(p,anchor,index) then return true end
 if tag then
  if not self.Tags[tag] then
   self.Tags[tag]=true;anchor.Color=Color3.fromRGB(102,194,149)
   local count=0;for _ in pairs(self.Tags) do count+=1 end
   self.Notify(string.format("行李牌 %d / 3：%s%s",count,tagText[tag],count==3 and "。回到乘客簿比對紀錄。" or "。繼續搜尋月台。"))
   self:UpdateOthers(2)
  else self.Notify("這張行李牌已登記，請尋找其他牌或回到紀錄簿。",p) end
  return true
 end
 local previous=self.Sessions[p]
 self.Sessions[p]={Anchor=anchor,Station=index,Token=Http:GenerateGUID(false),Opened=workspace:GetServerTimeNow(),Camera=previous and previous.Station==index and previous.Camera or 1,Frame=previous and previous.Station==index and previous.Frame or 0}
 self.Updates:FireClient(p,self:Snapshot(p));return true
end
local function integer(v,min,max) return type(v)=="number" and v%1==0 and v>=min and v<=max end
function Challenges:Aiming(p,s,origin,direction)
 if typeof(origin)~="Vector3" or typeof(direction)~="Vector3" then return false end
 local function finite(v) return v.X==v.X and v.Y==v.Y and v.Z==v.Z and math.abs(v.X)<1e7 and math.abs(v.Y)<1e7 and math.abs(v.Z)<1e7 end
 if not finite(origin) or not finite(direction) or direction.Magnitude<.9 or direction.Magnitude>1.1 then return false end
 local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
 local target=self.World.Props:FindFirstChild("MirrorWitnessTarget")
 if not root or not target or (origin-root.Position).Magnitude>8 then return false end
 local delta=target.Position-origin
 if delta.Magnitude>42 or delta.Magnitude<.1 or direction.Unit:Dot(delta.Unit)<math.cos(math.rad(7)) then return false end
 local filter=RaycastParams.new();filter.FilterType=Enum.RaycastFilterType.Exclude;filter.FilterDescendantsInstances={p.Character}
 local hit=workspace:Raycast(origin,delta,filter)
 return hit~=nil and (hit.Instance==target or hit.Instance:GetAttribute("MirrorWitness")==true)
end
function Challenges:Request(p,token,action,value,origin,direction)
 local s=self.Sessions[p]
 if not s or token~=s.Token or type(action)~="string" then return {ok=false,closed=true} end
 if action=="Close" then self.Sessions[p]=nil;return {ok=true,closed=true} end
 if not self:Valid(p,s.Anchor,s.Station) then self.Sessions[p]=nil;return {ok=false,closed=true,message="已離開互動範圍，請回到任務台。"} end
 local now=workspace:GetServerTimeNow()
 if action~="Photo" and now-(self.Last[p] or 0)<.12 then return self:Snapshot(p) end;self.Last[p]=now
 if action=="State" then return self:Snapshot(p) end
 if s.Station==2 and action=="Passenger" then
  for i=1,3 do if not self.Tags[i] then return self:Snapshot(p,"先找齊月台上的三張行李牌。") end end
  if value~=3 then return self:Snapshot(p,"比對已找到的行李牌：誰的離站欄是空白？") end
  return self:Finish(p)
 elseif s.Station==3 and action=="Signal" and integer(value,1,3) then
  if value~=self.Echo.Sequence[self.Echo.Progress+1] then self.Echo.Progress=0;self:UpdateOthers(3);return self:Snapshot(p,"順序不符，從第一個燈號重新輸入；可按重播。") end
  self.Echo.Progress+=1
  if self.Echo.Progress==4 then return self:Finish(p) end
  self:UpdateOthers(3);return self:Snapshot(p,"燈號正確。")
 elseif s.Station==4 and (action=="Focus" or action=="Photo") then
  local valid=self:Aiming(p,s,origin,direction)
  if not valid then s.FocusStart=nil;s.LastFocus=nil;return self:Snapshot(p,"準星尚未對準人影，請調整鏡頭。") end
  if not s.LastFocus or now-s.LastFocus>1.1 then s.FocusStart=now end;s.LastFocus=now
  if action=="Photo" then
   if now-s.FocusStart<1.8 then return self:Snapshot(p,"保持穩定兩秒後再按快門。") end
   return self:Finish(p)
  end
  return self:Snapshot(p)
 elseif s.Station==5 then
  if action=="Camera" and integer(value,1,3) then s.Camera=value;s.ViewedAt=now
  elseif action=="Frame" and integer(value,0,4) then s.Frame=value;s.ViewedAt=now
  elseif action=="Evidence" then
   if s.Camera~=2 or s.Frame~=3 then return self:Snapshot(p,"影格不符。值班便條寫的是三天前 23:47、2 號鏡頭。") end
   if now-(s.ViewedAt or now)<.8 then return self:Snapshot(p,"先看清這一格，再截存證據。") end
   return self:Finish(p)
  else return self:Snapshot(p,"請使用鏡頭、倒帶與截存按鈕。") end
  self.Updates:FireClient(p,self:Snapshot(p))
  return self:Snapshot(p)
 elseif s.Station==6 then
  if action=="Dial" and integer(value,1,3) and not self.Circuit.Ready then
   self.Circuit.Dials[value]=(self.Circuit.Dials[value]+1)%4
   local d=self.Circuit.Dials;self.Circuit.Ready=d[1]==1 and d[2]==3 and d[3]==2
   self:UpdateOthers(6);return self:Snapshot(p,self.Circuit.Ready and "供電恢復。選擇相信站務員，或查看事故紀錄。" or "旋鈕已轉動。")
  elseif action=="Choice" and allowedChoice[value] and self.Circuit.Ready then return self:Finish(p,value) end
  return self:Snapshot(p,"先接通三個電路，再選擇調查方向。")
 elseif s.Station==7 then
  if action=="Stabilize" and self.Core.Progress<3 then
   local centers={.25,.65,.45};local center=centers[self.Core.Progress+1]
   local phase=((now-self.Core.Epoch)%4)/4
   if math.abs(phase-center)>.14 then return self:Snapshot(p,"稍早或稍晚了；等游標進入綠色區域再按，不會扣除已完成節點。") end
   self.Core.Progress+=1;self:UpdateOthers(7);return self:Snapshot(p,self.Core.Progress>=3 and "核心已穩定。現在選擇旅程的結局。" or "節點穩定，繼續下一個。")
  elseif action=="Ending" and allowedEnding[value] and self.Core.Progress>=3 then
   local _,_,_,_,_,choice=self.Context()
   if value=="Station08" and choice~="Records" then return self:Snapshot(p,"未讀取第六站事故紀錄，無法啟動封存結局。") end
   return self:Finish(p,value)
  end
  return self:Snapshot(p,"先依序穩定三個節點。")
 end
 return self:Snapshot(p,"請依畫面指示操作。")
end
return Challenges
