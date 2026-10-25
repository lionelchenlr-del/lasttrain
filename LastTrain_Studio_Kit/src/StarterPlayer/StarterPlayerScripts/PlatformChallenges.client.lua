local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local Audio=require(RS:WaitForChild("LastTrain").Shared:WaitForChild("AudioBus"))
local player=Players.LocalPlayer
local remotes=RS:WaitForChild("LastTrain"):WaitForChild("Remotes")
local request=remotes:WaitForChild("PlatformChallengeRequest")
local updates=remotes:WaitForChild("PlatformChallengeUpdate")
local gui=Instance.new("ScreenGui");gui.Name="LastTrainPlatformTasks";gui.ResetOnSpawn=false;gui.DisplayOrder=45;gui.Parent=player:WaitForChild("PlayerGui")
local navy=Color3.fromRGB(19,30,45);local cream=Color3.fromRGB(245,242,233);local orange=Color3.fromRGB(222,119,56);local blue=Color3.fromRGB(100,213,224)
local function round(p,r) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 8);c.Parent=p end
local function label(parent,text,pos,size,font,color)
 local t=Instance.new("TextLabel");t.Position=pos;t.Size=size;t.Text=text;t.BackgroundTransparency=1;t.Font=Enum.Font.GothamMedium;t.TextColor3=color or navy;t.TextSize=font or 16;t.TextWrapped=true;t.TextXAlignment=Enum.TextXAlignment.Left;t.Parent=parent;return t
end
local function button(parent,name,text,pos,size,color)
 local b=Instance.new("TextButton");b.Name=name;b.Text=text;b.Position=pos;b.Size=size;b.BackgroundColor3=color or orange;b.TextColor3=Color3.new(1,1,1);b.Font=Enum.Font.GothamBold;b.TextSize=16;b.TextWrapped=true;b.BorderSizePixel=0;b.Parent=parent;round(b);return b
end
local panel=Instance.new("Frame");panel.Name="TaskPanel";panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.5);panel.Size=UDim2.fromScale(.92,.86);panel.BackgroundColor3=cream;panel.Visible=false;panel.Parent=gui;round(panel,14)
local constraint=Instance.new("UISizeConstraint");constraint.MaxSize=Vector2.new(720,590);constraint.MinSize=Vector2.new(300,300);constraint.Parent=panel
local title=label(panel,"",UDim2.fromOffset(22,16),UDim2.new(1,-90,0,36),23)
local instruction=label(panel,"",UDim2.fromOffset(22,62),UDim2.new(1,-44,0,72),16)
local closeButton=button(panel,"CloseTask","×",UDim2.new(1,-57,0,18),UDim2.fromOffset(35,32));closeButton.Modal=true
local body=Instance.new("ScrollingFrame");body.Name="TaskContent";body.Position=UDim2.fromOffset(22,143);body.Size=UDim2.new(1,-44,1,-209);body.CanvasSize=UDim2.fromOffset(0,345);body.BackgroundTransparency=1;body.BorderSizePixel=0;body.ScrollBarThickness=4;body.Parent=panel
local status=label(panel,"",UDim2.new(0,22,1,-57),UDim2.new(1,-44,0,48),15,Color3.fromRGB(116,67,33))
local photo=Instance.new("Frame");photo.Name="PhotoOverlay";photo.Size=UDim2.fromScale(1,1);photo.BackgroundTransparency=1;photo.Visible=false;photo.Parent=gui
local photoGuide=label(photo,"",UDim2.new(.12,0,0,35),UDim2.new(.76,0,0,106),17,cream);photoGuide.BackgroundColor3=navy;photoGuide.BackgroundTransparency=.12;photoGuide.TextXAlignment=Enum.TextXAlignment.Center;round(photoGuide)
local reticle=label(photo,"＋",UDim2.new(.5,-25,.5,-25),UDim2.fromOffset(50,50),40,blue);reticle.TextXAlignment=Enum.TextXAlignment.Center
local shutter=button(photo,"Shutter","拍攝 [C]",UDim2.new(.5,-90,1,-85),UDim2.fromOffset(180,48))
local photoClose=button(photo,"CloseCamera","離開攝影 [Q]",UDim2.new(1,-160,1,-85),UDim2.fromOffset(145,48),navy)
local data=nil;local busy=false;local controls=nil;local playedToken=nil;local replaying=false;local gauge=nil;local greenZone=nil;local coreLabel=nil;local connection=nil;local focusPending=false;local focusAt=0;local playbackVersion=0
local photoNotice="";local photoNoticeUntil=0
local render,send
local function close(notify)
 local previous=data;data=nil;panel.Visible=false;photo.Visible=false;playbackVersion+=1;replaying=false;gauge=nil;greenZone=nil
 player:SetAttribute("PlatformTaskOpen",false)
 if controls then controls:Enable();controls=nil end
 if notify and previous then task.spawn(function() pcall(request.InvokeServer,request,previous.token,"Close") end) end
end
local function activate(nextData)
 local fresh=not data or data.token~=nextData.token
 data=nextData
 if fresh then
  body.CanvasPosition=Vector2.zero
  player:SetAttribute("PlatformTaskOpen",true)
  if nextData.station~=4 then controls=require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls();controls:Disable() end
 end
 panel.Visible=nextData.station~=4;photo.Visible=nextData.station==4
 title.Text=nextData.title or "月台任務";instruction.Text=nextData.instruction or "";status.Text=nextData.message or ""
 if data.station==4 then
  if data.message and data.message~="" then photoNotice=data.message;photoNoticeUntil=workspace:GetServerTimeNow()+3 end
  photoGuide.Text=data.instruction.."\n"..(data.message~="" and data.message or "尋找鏡面旁的藍色人影。")
 else render() end
end
send=function(action,value,origin,direction)
 if not data or busy then return end
 if action=="Photo" then Audio.Play("Shutter") elseif action=="Evidence" then Audio.Play("Evidence") elseif action~="Focus" and action~="Close" then Audio.Play("Click") end
 busy=true;local token=data.token
 task.spawn(function()
  local ok,result=pcall(request.InvokeServer,request,token,action,value,origin,direction);busy=false
  if not data or data.token~=token then return end
  if not ok then status.Text="連線忙碌，請稍後再試。";photoGuide.Text="連線忙碌，請稍後再試。";return end
  if result and result.closed then close(false) elseif result and result.ok then activate(result) end
 end)
end
local function photoShot()
 if not data or data.station~=4 then return end
 local camera=workspace.CurrentCamera
 send("Photo",nil,camera.CFrame.Position,camera.CFrame.LookVector)
end
shutter.Activated:Connect(photoShot);photoClose.Activated:Connect(function() close(true) end);closeButton.Activated:Connect(function() close(true) end)
local function block(text,y,height)
 local t=label(body,text,UDim2.fromOffset(0,y),UDim2.new(1,-8,0,height or 38),17);return t
end
render=function()
 body:ClearAllChildren();gauge=nil;greenZone=nil;coreLabel=nil
 if not data then return end
 local s=data.station
 if s==2 then
  block(string.format("行李牌 %d / 3　（全隊共用）",data.count or 0),0,30)
  for i,line in ipairs(data.tags or {}) do block((line:find("尚未") and "○ " or "✓ ")..line,35+(i-1)*34,32) end
  block("乘客簿：12A、08B 已離站。哪位乘客的離站欄空白？",143,44)
  for i,name in ipairs({"林先生 · 12A","陳小姐 · 08B","紅衣孩童 · 03C"}) do
   local b=button(body,"Passenger"..i,name,UDim2.new((i-1)/3,0,0,204),UDim2.new(1/3,-8,0,65),(data.count or 0)==3 and orange or Color3.fromRGB(114,125,135))
   b.Activated:Connect(function() send("Passenger",i) end)
  end
  block("未找齊：關閉此頁，在月台尋找三個金色行李牌標記。",281,48)
 elseif s==3 then
  block(string.format("已重現 %d / 4 次燈號",data.progress or 0),0,35)
  local palette={Color3.fromRGB(41,159,182),Color3.fromRGB(193,145,39),Color3.fromRGB(190,65,66)}
  local words={"青燈","黃燈","紅燈"};local lights={}
  local cue=block("準備輸入燈號",42,48);cue.TextXAlignment=Enum.TextXAlignment.Center
  for i,name in ipairs(words) do
   local b=button(body,"Signal"..i,name,UDim2.new((i-1)/3,0,0,105),UDim2.new(1/3,-8,0,92),palette[i]);lights[i]=b
   b.Activated:Connect(function() if not replaying then send("Signal",i) end end)
  end
  local function replay()
   if replaying or not data then return end
   playbackVersion+=1;local version=playbackVersion;local token=data.token;local sequence=table.clone(data.sequence);replaying=true
   task.spawn(function()
    for i,id in ipairs(sequence) do
     if not data or data.token~=token or playbackVersion~=version or not cue.Parent then replaying=false;return end
     Audio.Play("Countdown",.8+id*.16)
     cue.Text=string.format("第 %d 次：%s",i,words[id]);lights[id].BackgroundColor3=Color3.fromRGB(243,242,221)
     task.wait(.6);if not cue.Parent then replaying=false;return end;lights[id].BackgroundColor3=palette[id];cue.Text="· · ·";task.wait(.2)
    end
    replaying=false;if cue.Parent then cue.Text="請依序按下四次燈號" end
   end)
  end
  button(body,"ReplaySignal","重播燈號（不重設全隊進度）",UDim2.fromOffset(0,216),UDim2.new(1,-8,0,48),navy).Activated:Connect(replay)
  if playedToken~=data.token then playedToken=data.token;task.defer(replay) end
 elseif s==5 then
  local display=Instance.new("Frame");display.Name="CCTVDisplay";display.Size=UDim2.new(1,-8,0,165);display.BackgroundColor3=Color3.fromRGB(12,29,32);display.BorderSizePixel=0;display.Parent=body;round(display)
  local times={"23:38","23:41","23:44","23:47","23:50"};local camera=data.camera or 1;local frame=data.frame or 0
  label(display,string.format("REC ●　CAM %02d　｜三天前 %s",camera,times[frame+1]),UDim2.fromOffset(10,7),UDim2.new(1,-20,0,27),15,blue)
  local floor=Instance.new("Frame");floor.Position=UDim2.fromScale(.07,.75);floor.Size=UDim2.fromScale(.86,.025);floor.BackgroundColor3=blue;floor.BorderSizePixel=0;floor.Parent=display
  local evidence=camera==2 and frame==3
  for i=1,evidence and 4 or 3 do
   local x=.15+(i-1)*.19+(frame%2)*.025
   local person=Instance.new("Frame");person.Size=UDim2.fromScale(.055,.26);person.Position=UDim2.fromScale(x,.45);person.BackgroundColor3=(evidence and i==4) and Color3.fromRGB(219,91,85) or Color3.fromRGB(147,171,162);person.BorderSizePixel=0;person.Parent=display
   local head=Instance.new("Frame");head.Size=UDim2.fromScale(.045,.12);head.Position=UDim2.fromScale(x+.005,.30);head.BackgroundColor3=person.BackgroundColor3;head.BorderSizePixel=0;head.Parent=display;round(head,20)
  end
  label(display,evidence and "異常：多出一名面向鏡頭的乘客" or "影像正常，繼續調整鏡頭與時間",UDim2.new(0,10,1,-30),UDim2.new(1,-20,0,24),14,evidence and Color3.fromRGB(255,172,132) or cream)
  for i=1,3 do local b=button(body,"Camera"..i,i.." 號鏡頭",UDim2.new((i-1)/3,0,0,178),UDim2.new(1/3,-8,0,40),i==camera and orange or navy);b.Activated:Connect(function() send("Camera",i) end) end
  button(body,"Rewind","◀ 倒帶",UDim2.fromOffset(0,231),UDim2.new(.28,-6,0,40),navy).Activated:Connect(function() send("Frame",math.max(0,frame-1)) end)
  local timeLabel=label(body,times[frame+1],UDim2.new(.28,0,0,231),UDim2.new(.44,-8,0,40),25);timeLabel.TextXAlignment=Enum.TextXAlignment.Center
  button(body,"Forward","前進 ▶",UDim2.new(.72,0,0,231),UDim2.new(.28,-8,0,40),navy).Activated:Connect(function() send("Frame",math.min(4,frame+1)) end)
  button(body,"SaveEvidence","截存這一格證據",UDim2.fromOffset(0,286),UDim2.new(1,-8,0,45)).Activated:Connect(function() send("Evidence") end)
 elseif s==6 then
  block("接線圖：1 號 →　　2 號 ←　　3 號 ↓",0,48)
  local arrows={"↑","→","↓","←"}
  for i=1,3 do
   local b=button(body,"CircuitDial"..i,string.format("%d 號旋鈕\n%s\n點擊轉動 90°",i,arrows[(data.dials[i] or 0)+1]),UDim2.new((i-1)/3,0,0,68),UDim2.new(1/3,-8,0,122),data.ready and Color3.fromRGB(54,142,111) or navy)
   b.TextSize=21;b.Activated:Connect(function() send("Dial",i) end)
  end
  if data.ready then
   block("供電恢復。你選擇：",203,35)
   button(body,"TrustConductor","相信站務員",UDim2.fromOffset(0,253),UDim2.new(.5,-6,0,61)).Activated:Connect(function() send("Choice","Conductor") end)
   button(body,"ReadAccidentLog","讀取事故紀錄",UDim2.new(.5,0,0,253),UDim2.new(.5,-8,0,61)).Activated:Connect(function() send("Choice","Records") end)
  else block("旋鈕轉對時，全隊共用的電路會接通。",213,50) end
 elseif s==7 then
  coreLabel=block(string.format("已穩定 %d / 3 個核心節點",data.progress or 0),0,45)
  if not data.ready then
   local track=Instance.new("Frame");track.Name="CoreGauge";track.Size=UDim2.new(1,-16,0,44);track.Position=UDim2.fromOffset(4,80);track.BackgroundColor3=navy;track.BorderSizePixel=0;track.Parent=body;round(track)
   greenZone=Instance.new("Frame");greenZone.Name="SafeZone";greenZone.Size=UDim2.fromScale(.28,1);greenZone.BackgroundColor3=Color3.fromRGB(76,180,128);greenZone.BorderSizePixel=0;greenZone.Parent=track
   gauge=Instance.new("Frame");gauge.Name="Cursor";gauge.Size=UDim2.new(0,5,1,14);gauge.Position=UDim2.fromOffset(0,-7);gauge.BackgroundColor3=cream;gauge.BorderSizePixel=0;gauge.Parent=track
   button(body,"Stabilize","穩定這個節點 [空白鍵]",UDim2.fromOffset(0,156),UDim2.new(1,-8,0,61)).Activated:Connect(function() send("Stabilize") end)
   block("失誤可再試；已完成的節點會保留。",236,40)
  else
   block("核心已穩定。這次由你決定旅程如何結束。",58,50)
   for i,ending in ipairs({{Key="Conductor",Name="相信列車長，離開"},{Key="Truth",Name="關閉核心，終止循環"},{Key="Station08",Name=data.secret and "啟動封存系統（隱藏結局）" or "封存系統未解鎖：第六站需讀事故紀錄"}}) do
    local b=button(body,"Ending"..ending.Key,ending.Name,UDim2.fromOffset(0,119+(i-1)*67),UDim2.new(1,-8,0,56),ending.Key=="Station08" and not data.secret and Color3.fromRGB(116,124,135) or navy)
    b.Activated:Connect(function() send("Ending",ending.Key) end)
   end
  end
 end
end
updates.OnClientEvent:Connect(function(nextData)
 if type(nextData)~="table" then return end
 if nextData.closed then close(false) elseif nextData.ok then activate(nextData) end
end)
UIS.InputBegan:Connect(function(input,processed)
 if not data then return end
 if input.KeyCode==Enum.KeyCode.Escape then close(true);return end
 if processed then return end
 if input.KeyCode==Enum.KeyCode.Q then close(true);return end
 if data.station==4 and input.KeyCode==Enum.KeyCode.C then photoShot()
 elseif data.station==7 and not data.ready and input.KeyCode==Enum.KeyCode.Space then send("Stabilize") end
end)
player.CharacterAdded:Connect(function() close(true) end)
local lastDistanceCheck=0
Run.RenderStepped:Connect(function()
 if not data then return end
 local now=workspace:GetServerTimeNow()
 if now-lastDistanceCheck>.25 then
  lastDistanceCheck=now
  local c=player.Character;local root=c and c:FindFirstChild("HumanoidRootPart");local h=c and c:FindFirstChildOfClass("Humanoid")
  if not root or not h or h.Health<=0 or (root.Position-data.anchor).Magnitude>19 or workspace:GetAttribute("LastTrainStation")~=data.station or workspace:GetAttribute("LastTrainTraveling") then close(true);return end
 end
 if data.station==7 and gauge and greenZone then
  local centers={.25,.65,.45};local center=centers[(data.progress or 0)+1] or .45
  greenZone.Position=UDim2.fromScale(center-.14,0)
  gauge.Position=UDim2.new(((now-data.epoch)%4)/4,-2,0,-7)
 elseif data.station==4 and data.target then
  local camera=workspace.CurrentCamera;local delta=data.target-camera.CFrame.Position
  local aligned=delta.Magnitude>0 and camera.CFrame.LookVector:Dot(delta.Unit)>math.cos(math.rad(7))
  reticle.TextColor3=aligned and Color3.fromRGB(108,241,164) or blue
  local focus=data.focus or 0
  photoGuide.Text=data.instruction..string.format("\n對準狀態：%s　穩定 %.1f / 2 秒",aligned and "已對準" or "請轉動視角尋找藍色人影",focus)..(now<photoNoticeUntil and ("\n"..photoNotice) or "")
  if now-focusAt>.35 and not focusPending and not busy then
   focusAt=now;focusPending=true;local token=data.token;local origin=camera.CFrame.Position;local direction=camera.CFrame.LookVector
   task.spawn(function()
    local ok,result=pcall(request.InvokeServer,request,token,"Focus",nil,origin,direction);focusPending=false
    if data and data.token==token and ok and result then
     if result.closed then close(false) elseif result.ok then data.focus=result.focus;data.message=result.message end
    end
   end)
  end
 end
end)
