local Players=game:GetService("Players")
local Profiles=require(script.Parent.ProfileService)
local remote=game.ReplicatedStorage:WaitForChild("LastTrain"):WaitForChild("Remotes"):WaitForChild("AudioSettingsRequest")
local last={}
local function finite(n) return type(n)=="number" and n==n and math.abs(n)<math.huge end
remote.OnServerInvoke=function(p,action,data)
 if not Profiles.IsLoaded(p) then return {ok=false,message="音量設定載入中。"} end
 if action=="Get" then return {ok=true,settings=Profiles.GetState(p).Audio} end
 if action~="Save" or type(data)~="table" or not finite(data.Music) or not finite(data.Effects) or type(data.Muted)~="boolean" then return {ok=false,message="音量設定格式不正確。"} end
 if os.clock()-(last[p] or -10)<.8 then return {ok=false,message="請稍候再儲存。"} end;last[p]=os.clock()
 local settings={Music=math.clamp(data.Music,0,1),Effects=math.clamp(data.Effects,0,1),Muted=data.Muted}
 local ok=Profiles.SetAudioSettings(p,settings)
 return {ok=ok,settings=settings,message=ok and "音量已儲存。" or "暫時無法儲存音量，可稍後再試。"}
end
Players.PlayerRemoving:Connect(function(p) last[p]=nil end)
