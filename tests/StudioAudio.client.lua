-- Disposable native-client checks. No purchases, no synthetic audio IDs.
assert(game:GetService("RunService"):IsStudio())
local player=game.Players.LocalPlayer
local audio=game.SoundService:WaitForChild("LastTrainAudio",30)
local remotes=game.ReplicatedStorage.LastTrain.Remotes
local bus=require(game.ReplicatedStorage.LastTrain.Shared.AudioBus)
local config=require(game.ReplicatedStorage.LastTrain.Shared.AudioConfig)
local gui=player.PlayerGui:WaitForChild("LastTrainAudioSettings",30)
local seen={};local cues={}
local function record() local track=audio:GetAttribute("Track");if track then seen[track]=true end end
record();audio:GetAttributeChangedSignal("Track"):Connect(record)
audio:GetAttributeChangedSignal("LastCue"):Connect(function() cues[audio:GetAttribute("LastCue")]=true end)
local deadline=os.clock()+60
repeat task.wait(.2) until audio:GetAttribute("Ready") or os.clock()>deadline
assert(audio:GetAttribute("ReadyCount")==5,"Scene audio mappings and effects bank did not load")
for _,s in ipairs(audio:GetChildren()) do
 if s:IsA("Sound") and s.Name:find("Preload") then
  assert(s.IsLoaded and s.TimeLength>20,"Decoded audio missing length: "..s.Name)
  print("LASTTRAIN_AUDIO_ASSET_PASS",s.Name,s.SoundId,s.TimeLength)
 end
end
local unique={}
for _,info in pairs(config.Tracks) do unique[info.Id]=true end;unique[config.BankId]=true
local uniqueCount=0;for _ in pairs(unique) do uniqueCount+=1 end;assert(uniqueCount==4,"Expected three live music assets and one effects bank")
local initial=remotes.AudioSettingsRequest:InvokeServer("Get");assert(initial.ok,"Audio settings not loaded")
local invalid=remotes.AudioSettingsRequest:InvokeServer("Save",{Music=0/0,Effects=1,Muted=false});assert(not invalid.ok,"Non-finite audio setting accepted")
gui.Action:Fire("Music",.3);gui.Action:Fire("Effects",.5);task.wait(1.3)
local saved=remotes.AudioSettingsRequest:InvokeServer("Get");assert(saved.ok and saved.settings.Music==.3 and saved.settings.Effects==.5,"Audio settings failed to persist")
assert(math.abs(audio.Music.Volume-.3)<.00001 and math.abs(audio.Effects.Volume-.5)<.00001,"Mixer groups ignored settings")
gui.Action:Fire("Mute",true);task.wait(.15)
assert(audio.Music.Volume==0 and audio.Effects.Volume==0,"Mute left audible group")
local before=audio:GetAttribute("CueCount") or 0;bus.Play("Anomaly");task.wait(.2)
assert((audio:GetAttribute("CueCount") or 0)==before,"Muted effect still played")
gui.Action:Fire("Mute",false);task.wait(1.3)
assert(math.abs(audio.Music.Volume-.3)<.00001 and math.abs(audio.Effects.Volume-.5)<.00001,"Unmute lost previous volume")
local playing
for _,s in ipairs(audio:GetChildren()) do if s:IsA("Sound") and s.Name:find("MusicDeck") and s.IsPlaying then playing=s end end
assert(playing,"No actual music deck playing")
local time=playing.TimePosition;task.wait(.4);assert(playing.TimePosition~=time,"Music playback clock did not advance")
print("LASTTRAIN_AUDIO_MIXER_PASS independent controls; persistence; invalid input; mute; unmute; advancing playback")
for name in pairs(config.Cues) do bus.Play(name);task.wait(.24) end
task.wait(4.1)
local soundCount=0;local effectCount=0
for _,s in ipairs(audio:GetChildren()) do
 if s:IsA("Sound") then
  soundCount+=1
  if s.Name:match("^Effect%d+$") then effectCount+=1
   if s.IsPlaying then
    assert(os.clock()<=(s:GetAttribute("StopAt") or 0)+.2,"Expired effect voice remained playing: "..s.Name)
    local c=config.Cues[s:GetAttribute("Cue")];assert(c and s.TimePosition>=c.Start-.1 and s.TimePosition<=c.Start+c.Duration+.2,"Effect playback escaped its bank segment")
   end end
 end
end
assert(effectCount==6 and soundCount==13,"Audio object count leaked")
print("LASTTRAIN_AUDIO_EFFECT_BANK_PASS",effectCount,"voices; segment/deadline checks; 13 fixed sounds")
gui.Action:Fire("Music",initial.settings.Music);gui.Action:Fire("Effects",initial.settings.Effects);gui.Action:Fire("Mute",initial.settings.Muted);task.wait(1.3)
local function onCharacter()
 task.delay(2,function()
  assert(game.SoundService:FindFirstChild("LastTrainAudio")==audio,"Respawn duplicated mixer")
  assert(player.PlayerGui:FindFirstChild("LastTrainAudioSettings")==gui,"Respawn duplicated audio UI")
  print("LASTTRAIN_AUDIO_RESPAWN_PASS")
 end)
end
player.CharacterAdded:Connect(onCharacter)
local ending=false
remotes.HiddenRouteUpdate.OnClientEvent:Connect(function(s) if s.ending=="Station09" then ending=true end end)
deadline=os.clock()+300
repeat task.wait(.2) until ending or os.clock()>deadline
task.wait(1.5)
for _,track in ipairs({"Night","Investigation","Mystery","Home"}) do assert(seen[track],"Scene soundtrack missing: "..track) end
assert(cues.Door and cues.Ticket and cues.Rumble and cues.Success,"Journey audio events did not fire")
print("LASTTRAIN_AUDIO_ALL_PASS three original scores / four scene mixes; event effects; playback; settings; mute; respawn; hidden ending")
