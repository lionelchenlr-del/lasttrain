-- Two music decks, six bounded effect voices, and a player-owned volume mixer.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("SoundService")
local Tween=game:GetService("TweenService")
local Run=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local Content=game:GetService("ContentProvider")
local player=Players.LocalPlayer
local shared=RS:WaitForChild("LastTrain")
local config=require(shared.Shared:WaitForChild("AudioConfig"))
local bus=require(shared.Shared:WaitForChild("AudioBus"))
local remotes=shared:WaitForChild("Remotes")
local root=Instance.new("Folder");root.Name="LastTrainAudio";root.Parent=SS
local musicGroup=Instance.new("SoundGroup");musicGroup.Name="Music";musicGroup.Parent=root
local effectsGroup=Instance.new("SoundGroup");effectsGroup.Name="Effects";effectsGroup.Parent=root
local settings={Music=config.DefaultMusic,Effects=config.DefaultEffects,Muted=false}
local voices,tokens,lastCue={},{},{}
local count,nextVoice=0,0
local function applyVolume()
 musicGroup.Volume=settings.Muted and 0 or settings.Music
 effectsGroup.Volume=settings.Muted and 0 or settings.Effects
 root:SetAttribute("MusicVolume",musicGroup.Volume);root:SetAttribute("EffectsVolume",effectsGroup.Volume);root:SetAttribute("Muted",settings.Muted)
 if settings.Muted then for _,s in ipairs(voices) do s:Stop() end end
end
for i=1,6 do
 local s=Instance.new("Sound");s.Name="Effect"..i;s.SoundId="rbxassetid://"..config.BankId;s.SoundGroup=effectsGroup;s.Volume=.7;s.Parent=root;voices[i]=s;tokens[i]=0
end
local function cue(name,pitch)
 local c=config.Cues[name];if not c or settings.Muted or settings.Effects<=0 then return end
 local now=os.clock();if now-(lastCue[name] or -10)<(name=="Click" and .09 or .18) then return end;lastCue[name]=now
 nextVoice=nextVoice%#voices+1;local index=nextVoice;local s=voices[index]
 tokens[index]+=1;local token=tokens[index]
 s:Stop();s.PlaybackSpeed=math.clamp(tonumber(pitch) or 1,.6,1.6);s.Volume=name=="Rumble" and .42 or name=="Anomaly" and .4 or .7
 s:SetAttribute("Cue",name);s:SetAttribute("StopAt",now+c.Duration/s.PlaybackSpeed)
 s:Play();s.TimePosition=c.Start
 count+=1;root:SetAttribute("CueCount",count);root:SetAttribute("LastCue",name)
 task.delay(c.Duration/s.PlaybackSpeed,function() if tokens[index]==token then s:Stop() end end)
end
bus.Event:Connect(cue)
-- Include native avatar footsteps and other in-world game sounds in the effects mixer.
local function routeEffect(object)
 if object:IsA("Sound") and not object:IsDescendantOf(root) then object.SoundGroup=effectsGroup end
end
workspace.DescendantAdded:Connect(routeEffect)
for _,object in ipairs(workspace:GetDescendants()) do routeEffect(object) end
local decks,tweens={},{}
for i=1,2 do local s=Instance.new("Sound");s.Name="MusicDeck"..i;s.Looped=true;s.Volume=0;s.SoundGroup=musicGroup;s.Parent=root;decks[i]=s end
local deck,sceneKey,version=1,nil,0
local loadedTracks={}
local cinema,cinemaCycle,hiddenDone,lastEnding=nil,0,false,nil
local function choose()
 local ending=cinema and cinema.Enabled and cinema:GetAttribute("Ending")
 local state=cinema and cinema:GetAttribute("State")
 if ending and (state=="Playing" or state=="Card") then
  return "Cinema:"..ending..":"..cinemaCycle,(ending=="Station08" and "Mystery" or "Home"),1
 end
 local hidden=player:GetAttribute("HiddenRouteStation")
 if hidden==8 then return "Hidden8","Mystery",1 end
 if hidden==9 then return hiddenDone and "Hidden9Done" or "Hidden9",hiddenDone and "Home" or "Investigation",1 end
 if workspace:GetAttribute("LastTrainMode")~="Game" then return "Lobby","Night",1 end
 if lastEnding and lastEnding~="Station08" then return "After:"..lastEnding,"Home",1 end
 if workspace:GetAttribute("LastTrainTraveling") then return "Moving","Night",1.08 end
 local station=workspace:GetAttribute("LastTrainStation") or 1
 local track=station==4 and "Mystery" or (station==2 or station==3 or station==5 or station==7) and "Investigation" or "Night"
 return "Station:"..station,track,1
end
local function refreshMusic()
 local key,track,pitch=choose()
 local playback=track
 if loadedTracks[track]==false then playback=loadedTracks.Mystery and "Mystery" or loadedTracks.Night and "Night" or track end
 local mixerKey=key..":"..playback;if mixerKey==sceneKey then return end
 sceneKey=mixerKey;version+=1;local current=version;root:SetAttribute("Scene",key);root:SetAttribute("Track",track);root:SetAttribute("PlayingTrack",playback);root:SetAttribute("FallbackActive",playback~=track)
 local info=config.Tracks[playback];local previous=decks[deck];deck=deck%2+1;local target=decks[deck]
 for _,s in ipairs(decks) do if tweens[s] then tweens[s]:Cancel();tweens[s]=nil end end
 target:Stop();target.SoundId="rbxassetid://"..info.Id;target.PlaybackSpeed=pitch*(info.Rate or 1);target.TimePosition=0;target.Volume=0;target:Play()
 tweens[target]=Tween:Create(target,TweenInfo.new(1.2),{Volume=info.Volume});tweens[target]:Play()
 tweens[previous]=Tween:Create(previous,TweenInfo.new(1.2),{Volume=0});tweens[previous]:Play()
 task.delay(1.25,function() if current==version and previous~=decks[deck] then previous:Stop() end end)
end
local function attachCinema(g)
 if g.Name~="EndingCinema" or cinema==g then return end;cinema=g
 g:GetAttributeChangedSignal("State"):Connect(function()
  local state=g:GetAttribute("State")
  if state=="Playing" then cinemaCycle+=1;cue("Evidence") elseif state=="Card" then cue("Success") end
  refreshMusic()
 end)
 g:GetAttributeChangedSignal("Ending"):Connect(refreshMusic)
end
local pg=player:WaitForChild("PlayerGui")
pg.ChildAdded:Connect(attachCinema);for _,g in ipairs(pg:GetChildren()) do attachCinema(g) end
for _,name in ipairs({"LastTrainMode","LastTrainStation","LastTrainTraveling"}) do workspace:GetAttributeChangedSignal(name):Connect(refreshMusic) end
player:GetAttributeChangedSignal("HiddenRouteStation"):Connect(refreshMusic)
-- Old per-ticket/per-livery sounds were consolidated into this mixer.
remotes:WaitForChild("TicketUpdate").OnClientEvent:Connect(function(data)
 cue(data.Kind=="Rejected" and "Rejected" or "Ticket")
 if data.Anomaly then task.delay(.35,function() cue("Anomaly") end) end
end)
local lastStage,lastState=nil,nil
remotes:WaitForChild("ObjectiveUpdate").OnClientEvent:Connect(function(stage,_,completed,_,_,ending,state)
 if lastStage and stage>lastStage then cue("Success") end;lastStage=stage
 if state=="Countdown" then cue("Countdown") end
 if state=="Moving" and lastState~="Moving" then cue("Arrival") end
 if completed and ending then lastEnding=ending end
 lastState=state;refreshMusic()
end)
local challengeToken,challengeCount,challengeProgress=nil,0,0
remotes:WaitForChild("PlatformChallengeUpdate").OnClientEvent:Connect(function(s)
 if s.closed then challengeToken=nil;return end
 if s.token~=challengeToken then challengeToken=s.token;challengeCount=s.count or 0;challengeProgress=s.progress or 0;cue("Click")
 else
  if (s.count or 0)>challengeCount or (s.progress or 0)>challengeProgress then cue("Evidence") end
  challengeCount=s.count or 0;challengeProgress=s.progress or 0
 end
end)
local hiddenClues,hiddenSequence,hadTicket=0,0,false
remotes:WaitForChild("HiddenRouteUpdate").OnClientEvent:Connect(function(s)
 if (s.clues or 0)>hiddenClues or (s.sequence or 0)>hiddenSequence then cue("Evidence") end
 hiddenClues=s.clues or hiddenClues;hiddenSequence=s.sequence or hiddenSequence;hiddenDone=s.done==true
 if s.ticket and not hadTicket then cue("Ticket") end;hadTicket=s.ticket==true
 refreshMusic()
end)
remotes:WaitForChild("RoyalFeedback").OnClientEvent:Connect(function() cue("Tea") end)
game:GetService("ProximityPromptService").PromptTriggered:Connect(function(_,who) if who==player then cue("Click") end end)
local train=nil
local function hookTrain(t)
 if train then return end;train=t
 local prior=t:GetAttribute("DoorsOpen")
 t:GetAttributeChangedSignal("DoorsOpen"):Connect(function()
  local open=t:GetAttribute("DoorsOpen")
  if open~=prior then cue("Door");if open then cue("Arrival") end;prior=open end
 end)
end
task.spawn(function()
 while workspace:GetAttribute("LastTrainMode")~="Game" do workspace:GetAttributeChangedSignal("LastTrainMode"):Wait() end
 local w=workspace:WaitForChild("LastTrainWorld");hookTrain(w:WaitForChild("Props"):WaitForChild("LastTrainCar"))
end)
local rumbleAt=0
Run.Heartbeat:Connect(function()
 local active=0;for _,s in ipairs(voices) do if s.IsPlaying then active+=1 end end;root:SetAttribute("ActiveVoices",active)
 if workspace:GetAttribute("LastTrainTraveling") and not player:GetAttribute("HiddenRouteStation") and not player:GetAttribute("LastTrainCinematic") and os.clock()-rumbleAt>3.95 then rumbleAt=os.clock();cue("Rumble") end
end)
-- A small touch/keyboard settings panel. The two volume controls persist in the profile.
local gui=Instance.new("ScreenGui");gui.Name="LastTrainAudioSettings";gui.ResetOnSpawn=false;gui.DisplayOrder=56;gui.Parent=pg
local function label(parent,name,value,pos,size)
 local t=Instance.new("TextLabel");t.Name=name;t.Text=value;t.Position=pos;t.Size=size;t.BackgroundTransparency=1;t.TextColor3=Color3.fromRGB(246,241,228);t.TextSize=18;t.Font=Enum.Font.GothamMedium;t.TextWrapped=true;t.Parent=parent;return t
end
local function button(parent,name,value,pos,size,fn)
 local b=Instance.new("TextButton");b.Name=name;b.Text=value;b.Position=pos;b.Size=size;b.BackgroundColor3=Color3.fromRGB(207,110,42);b.TextColor3=Color3.new(1,1,1);b.TextSize=17;b.BorderSizePixel=0;b.Parent=parent;b.Activated:Connect(fn);local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=b;return b
end
local panel=Instance.new("Frame");panel.Name="Panel";panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.5);panel.Size=UDim2.new(.88,0,0,300);panel.BackgroundColor3=Color3.fromRGB(23,34,48);panel.BorderSizePixel=0;panel.Visible=false;panel.Parent=gui
local limit=Instance.new("UISizeConstraint");limit.MaxSize=Vector2.new(430,300);limit.MinSize=Vector2.new(260,300);limit.Parent=panel
label(panel,"Title","音樂與音效",UDim2.new(.05,0,0,14),UDim2.new(.8,0,0,34))
local musicText=label(panel,"Music","",UDim2.new(.08,0,0,71),UDim2.new(.54,0,0,35))
local effectsText=label(panel,"Effects","",UDim2.new(.08,0,0,126),UDim2.new(.54,0,0,35))
local status=label(panel,"Status","設定會保留到下次遊玩。",UDim2.new(.06,0,0,248),UDim2.new(.88,0,0,36));status.TextSize=14
local muteButton
local function render()
 musicText.Text="背景音樂  "..math.floor(settings.Music*100+.5).."%";effectsText.Text="音效  "..math.floor(settings.Effects*100+.5).."%"
 muteButton.Text=settings.Muted and "恢復聲音" or "全部靜音";applyVolume()
end
local saveVersion=0;local edited=false
local function saveLater()
 edited=true;saveVersion+=1;local token=saveVersion
 task.delay(1,function()
  if token~=saveVersion then return end
  local ok,r=pcall(remotes.AudioSettingsRequest.InvokeServer,remotes.AudioSettingsRequest,"Save",table.clone(settings))
  if token==saveVersion then status.Text=ok and r.message or "暫時無法儲存；目前音量已套用。" end
 end)
end
local function adjust(key,delta) settings[key]=math.clamp(math.floor((settings[key]+delta)*100+.5)/100,0,1);render();cue("Click");saveLater() end
for _,row in ipairs({{"Music",77},{"Effects",132}}) do
 button(panel,row[1].."Down","−",UDim2.new(.67,0,0,row[2]),UDim2.fromOffset(40,34),function() adjust(row[1],-.1) end)
 button(panel,row[1].."Up","＋",UDim2.new(.83,0,0,row[2]),UDim2.fromOffset(40,34),function() adjust(row[1],.1) end)
end
muteButton=button(panel,"Mute","全部靜音",UDim2.new(.08,0,0,193),UDim2.new(.84,0,0,40),function() settings.Muted=not settings.Muted;render();saveLater() end)
button(panel,"Close","×",UDim2.new(1,-43,0,10),UDim2.fromOffset(32,32),function() panel.Visible=false end)
local function toggle() if not player:GetAttribute("LastTrainCinematic") then panel.Visible=not panel.Visible end end
button(gui,"Open","音量 [N]",UDim2.fromOffset(18,80),UDim2.fromOffset(106,32),toggle)
UIS.InputBegan:Connect(function(i,processed) if not processed and i.KeyCode==Enum.KeyCode.N then toggle() elseif i.KeyCode==Enum.KeyCode.Escape then panel.Visible=false end end)
local settingsAction=Instance.new("BindableEvent");settingsAction.Name="Action";settingsAction.Parent=gui
settingsAction.Event:Connect(function(action,value)
 if action=="Music" or action=="Effects" then if type(value)=="number" and value==value then settings[action]=math.clamp(value,0,1);render();saveLater() end
 elseif action=="Mute" and type(value)=="boolean" then settings.Muted=value;render();saveLater()
 elseif action=="Open" then toggle() end
end)
render();refreshMusic()
task.spawn(function()
 for _=1,8 do
  local ok,r=pcall(remotes:WaitForChild("AudioSettingsRequest").InvokeServer,remotes.AudioSettingsRequest,"Get")
  if ok and r.ok then if not edited then settings=r.settings;render() end;return end
  task.wait(.75)
 end
 status.Text="目前使用預設音量；可再調整並儲存。"
end)
task.spawn(function()
 local preload={};for name,info in pairs(config.Tracks) do local s=Instance.new("Sound");s.Name="Preload"..name;s.SoundId="rbxassetid://"..info.Id;s.Volume=0;s.Parent=root;table.insert(preload,s) end
 local bank=Instance.new("Sound");bank.Name="PreloadEffects";bank.SoundId="rbxassetid://"..config.BankId;bank.Volume=0;bank.Parent=root;table.insert(preload,bank)
 for attempt=1,4 do
  local ok,err=pcall(Content.PreloadAsync,Content,preload)
  local loaded=0;for _,s in ipairs(preload) do if s.IsLoaded then loaded+=1 end;local name=s.Name:match("^Preload(.+)$");if config.Tracks[name] then loadedTracks[name]=s.IsLoaded end end
  refreshMusic()
  root:SetAttribute("ReadyCount",loaded);root:SetAttribute("Ready",loaded==5)
  if loaded==5 then
   local current=decks[deck]
   if not current.IsLoaded or not current.IsPlaying then sceneKey=nil;refreshMusic() end
   return
  end
  if attempt==1 then warn("LastTrain audio is still loading",err,loaded) end
  task.wait(attempt*8)
 end
end)
