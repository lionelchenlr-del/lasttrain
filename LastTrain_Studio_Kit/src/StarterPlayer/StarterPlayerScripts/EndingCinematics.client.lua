-- Local movie sets are isolated from the physical train and all server progression.
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Input=game:GetService("UserInputService")
local Lighting=game:GetService("Lighting")
local player=Players.LocalPlayer
local shared=game.ReplicatedStorage:WaitForChild("LastTrain")
local config=require(shared.Shared.GameConfig)
local controls=require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
local gui=Instance.new("ScreenGui")
gui.Name="EndingCinema";gui.IgnoreGuiInset=true;gui.ResetOnSpawn=false;gui.DisplayOrder=70;gui.Enabled=false;gui.Parent=player:WaitForChild("PlayerGui")
local function ui(kind,name,pos,size,color,parent)
 local x=Instance.new(kind);x.Name=name;x.Position=pos;x.Size=size;x.BorderSizePixel=0;x.BackgroundColor3=color;x.Parent=parent or gui;return x
end
local black=Color3.fromRGB(3,6,14)
local gold=Color3.fromRGB(244,189,97)
local blue=Color3.fromRGB(90,195,255)
local function label(name,text,pos,size,parent)
 local x=ui("TextLabel",name,pos,size,black,parent);x.BackgroundTransparency=1;x.Text=text;x.TextColor3=Color3.fromRGB(247,246,241);x.Font=Enum.Font.GothamMedium;x.TextSize=20;x.TextWrapped=true;return x
end
local top=ui("Frame","TopBar",UDim2.fromScale(0,0),UDim2.fromScale(1,.13),black)
local bottom=ui("Frame","BottomBar",UDim2.fromScale(0,.79),UDim2.fromScale(1,.21),black)
local chapter=label("Chapter","",UDim2.fromScale(.04,.02),UDim2.fromScale(.72,.09))
chapter.TextXAlignment=Enum.TextXAlignment.Left;chapter.TextSize=17
local subtitle=label("Subtitle","",UDim2.fromScale(.08,.81),UDim2.fromScale(.84,.13))
local skip=ui("TextButton","Skip",UDim2.fromScale(.81,.035),UDim2.fromScale(.15,.055),Color3.fromRGB(32,39,51))
skip.Text="略過  ▸";skip.TextColor3=Color3.new(1,1,1);skip.TextSize=16;skip.Font=Enum.Font.GothamMedium
local fade=ui("Frame","Fade",UDim2.fromScale(0,0),UDim2.fromScale(1,1),black);fade.ZIndex=5;fade.BackgroundTransparency=1
local card=ui("Frame","EndingCard",UDim2.fromScale(.1,.15),UDim2.fromScale(.8,.65),black);card.Visible=false;card.ZIndex=8
local constraint=Instance.new("UISizeConstraint");constraint.MinSize=Vector2.new(240,220);constraint.Parent=card
local title=label("Title","",UDim2.fromScale(.06,.06),UDim2.fromScale(.88,.16),card);title.TextSize=29;title.ZIndex=9
local story=label("Story","",UDim2.fromScale(.08,.25),UDim2.fromScale(.84,.42),card);story.TextSize=19;story.ZIndex=9
local replay=ui("TextButton","Replay",UDim2.fromScale(.08,.77),UDim2.fromScale(.39,.13),Color3.fromRGB(201,108,42),card)
local close=ui("TextButton","Return",UDim2.fromScale(.53,.77),UDim2.fromScale(.39,.13),Color3.fromRGB(41,51,67),card)
for _,b in ipairs({replay,close}) do b.TextColor3=Color3.new(1,1,1);b.TextSize=17;b.Font=Enum.Font.GothamBold;b.ZIndex=9 end
replay.Text="重播動畫";close.Text="返回遊戲畫面"
local action=Instance.new("BindableEvent");action.Name="Action";action.Parent=gui
local titles={Conductor="離開結局 · 晨光之後",Truth="真相結局 · 循環終止",Station08="隱藏結局 · 第八站"}
local duration=16
local origin=Vector3.new(0,2400,0)
local scene,connection,saved,key,started,seen=nil,nil,nil,nil,0,false
local hiddenUI,postEffects,atmospheres={},{},{}
local function ease(t) t=math.clamp(t,0,1);return t*t*(3-2*t) end
local function phase(t,a,b) return ease((t-a)/(b-a)) end
local function part(name,size,pos,color,material)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=CFrame.new(origin+pos);p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Parent=scene;return p
end
local function textOn(p,text,color,face)
 local s=Instance.new("SurfaceGui");s.Face=face or Enum.NormalId.Back;s.CanvasSize=Vector2.new(800,200);s.Parent=p
 local l=label("Sign",text,UDim2.fromScale(0,0),UDim2.fromScale(1,1),s);l.TextColor3=color or gold;l.TextScaled=true;return l
end
local function person(pos)
 local body=part("ConductorBody",Vector3.new(1.7,2.5,.8),pos+Vector3.new(0,2.4,0),Color3.fromRGB(25,42,63))
 local head=part("ConductorHead",Vector3.new(1.1,1.1,1),pos+Vector3.new(0,4.15,0),Color3.fromRGB(226,186,151));textOn(head,"•  •\n  ◡",Color3.fromRGB(40,31,28))
 part("ConductorCap",Vector3.new(1.4,.3,1.2),pos+Vector3.new(0,4.8,0),Color3.fromRGB(22,34,51))
 part("OrangeTie",Vector3.new(.19,1.2,.05),pos+Vector3.new(0,2.8,.43),gold)
 for _,x in ipairs({-.48,.48}) do part("Leg",Vector3.new(.65,1.3,.75),pos+Vector3.new(x,.65,0),Color3.fromRGB(20,28,41)) end
 local arm=part("WavingArm",Vector3.new(.55,2.1,.65),pos+Vector3.new(-1.15,2.6,0),body.Color)
 part("RestingArm",Vector3.new(.55,2.1,.65),pos+Vector3.new(1.15,2.6,0),body.Color)
 return arm,head
end
local function corridor(color)
 part("Floor",Vector3.new(54,1,140),Vector3.new(0,-.5,-36),Color3.fromRGB(29,34,46),Enum.Material.Metal)
 for _,x in ipairs({-25,25}) do
  part("Wall",Vector3.new(1,19,140),Vector3.new(x,9,-36),Color3.fromRGB(15,21,34))
  for z=-90,20,15 do
   part("Pillar",Vector3.new(1.4,19,2),Vector3.new(x*.94,9,z),Color3.fromRGB(65,72,84))
   part("Light",Vector3.new(.25,.18,12),Vector3.new(x*.84,12,z),color,Enum.Material.Neon)
  end
 end
 for z=-85,15,20 do
  local lamp=part("CeilingLamp",Vector3.new(8,.2,1),Vector3.new(0,14,z),color,Enum.Material.Neon)
  local light=Instance.new("PointLight");light.Color=Color3.fromRGB(197,210,231);light.Brightness=1.4;light.Range=29;light.Shadows=false;light.Parent=lamp
 end
 for _,x in ipairs({-17,17}) do part("FloorGuide",Vector3.new(.2,.04,125),Vector3.new(x,.03,-36),color,Enum.Material.Neon) end
end
local function clearScene()
 if connection then connection:Disconnect();connection=nil end
 if scene then scene:Destroy();scene=nil end
end
local function restore()
 if not saved then return end
 local camera=workspace.CurrentCamera
 if camera then camera.CameraSubject=saved.subject;camera.FieldOfView=saved.fov;camera.CFrame=saved.frame;camera.CameraType=saved.kind end
 for prop,value in pairs(saved.light) do Lighting[prop]=value end
 for uiObject,enabled in pairs(hiddenUI) do if uiObject.Parent then uiObject.Enabled=enabled end end;hiddenUI={}
 for effect,enabled in pairs(postEffects) do if effect.Parent then effect.Enabled=enabled end end;postEffects={}
 for atmosphere,values in pairs(atmospheres) do if atmosphere.Parent then for prop,value in pairs(values) do atmosphere[prop]=value end end end;atmospheres={}
 controls:Enable();player:SetAttribute("LastTrainCinematic",false);saved=nil
end
local function finish()
 if not saved then return end
 clearScene();restore();skip.Visible=false;top.Visible=false;bottom.Visible=false;chapter.Visible=false;subtitle.Visible=false;fade.BackgroundTransparency=1
 card.Visible=true;gui:SetAttribute("State","Card")
end
local function dismiss()
 clearScene();restore();gui.Enabled=false;card.Visible=false;gui:SetAttribute("State","Closed")
end
local function start(ending)
 clearScene();restore();key=ending
 local camera=workspace.CurrentCamera
 saved={kind=camera.CameraType,subject=camera.CameraSubject,frame=camera.CFrame,fov=camera.FieldOfView,light={ClockTime=Lighting.ClockTime,Brightness=Lighting.Brightness,Ambient=Lighting.Ambient,OutdoorAmbient=Lighting.OutdoorAmbient,FogEnd=Lighting.FogEnd,FogStart=Lighting.FogStart}}
 for _,other in ipairs(player.PlayerGui:GetChildren()) do
  if other:IsA("ScreenGui") and other~=gui then hiddenUI[other]=other.Enabled;other.Enabled=false end
 end
 for _,effect in ipairs(Lighting:GetChildren()) do
  if effect:IsA("PostEffect") then postEffects[effect]=effect.Enabled;effect.Enabled=false
  elseif effect:IsA("Atmosphere") then atmospheres[effect]={Density=effect.Density,Haze=effect.Haze,Glare=effect.Glare};effect.Density=0;effect.Haze=0;effect.Glare=0 end
 end
 controls:Disable();player:SetAttribute("LastTrainCinematic",true)
 camera.CameraType=Enum.CameraType.Scriptable;camera.FieldOfView=62
 Lighting.ClockTime=ending=="Conductor" and 7 or 0;Lighting.Brightness=2;Lighting.Ambient=Color3.fromRGB(145,152,169);Lighting.OutdoorAmbient=Color3.fromRGB(130,143,170);Lighting.FogEnd=100000;Lighting.FogStart=99900
 gui.Enabled=true;card.Visible=false;top.Visible=true;bottom.Visible=true;chapter.Visible=true;subtitle.Visible=true;skip.Visible=false
 title.Text=titles[ending];story.Text=config.Endings[ending];chapter.Text="末班車  /  "..titles[ending]
 gui:SetAttribute("Ending",ending);gui:SetAttribute("State","Playing")
 scene=Instance.new("Model");scene.Name="LastTrainEndingSet";scene.Parent=workspace
 local animate
 if ending=="Conductor" then
  corridor(gold)
  local left=part("ExitLeft",Vector3.new(10,14,.6),Vector3.new(-5,7,-39),Color3.fromRGB(145,152,160),Enum.Material.Metal)
  local right=part("ExitRight",left.Size,Vector3.new(5,7,-39),left.Color,Enum.Material.Metal)
  local exit=part("MorningExit",Vector3.new(20,14,.25),Vector3.new(0,7,-42),Color3.fromRGB(255,224,165),Enum.Material.Neon)
  textOn(part("ExitSign",Vector3.new(18,2,.5),Vector3.new(0,16,-39),black),"出口 EXIT  →",gold)
  local arm=person(Vector3.new(-9,0,-29))
  for i=1,14 do
   local x=(i-7.5)*7;local h=12+(i*17%25)
   part("CityBuilding",Vector3.new(5,h,6),Vector3.new(x,h/2,-75-(i%3)*9),Color3.fromRGB(111+i*3,130+i*2,153+i*2))
  end
  animate=function(t)
   local a=phase(t,2.5,7.5);left.CFrame=CFrame.new(origin+Vector3.new(-5-9*a,7,-39));right.CFrame=CFrame.new(origin+Vector3.new(5+9*a,7,-39));exit.Transparency=phase(t,6,10)
   arm.CFrame=CFrame.new(origin+Vector3.new(-10.15,3.1,-29))*CFrame.Angles(0,0,math.rad(-25+math.sin(t*3)*24))
   local p=Vector3.new(5,5,12):Lerp(Vector3.new(1,5,-50),phase(t,0,14))
   camera.CFrame=CFrame.lookAt(origin+p,origin+Vector3.new(-9,3.7,-29):Lerp(Vector3.new(0,6,-78),phase(t,3,7)))
   subtitle.Text=t<5 and "車門再次開啟。這一次，出口通往晨光。" or t<10 and "站務員揮手道別，你走向熟悉的城市。" or "身後的廣播響起——那竟然是你自己的聲音。"
  end
 elseif ending=="Truth" then
  corridor(Color3.fromRGB(109,234,204))
  local core=part("Core",Vector3.new(5,9,5),Vector3.new(0,5,-28),Color3.fromRGB(95,231,207),Enum.Material.Neon);core.Shape=Enum.PartType.Cylinder
  local rings={}
  for i=1,3 do
   local ring=Instance.new("Model");ring.Name="CoreOrbit"..i;ring.Parent=scene
   local radius=4+i*.65
   for n=1,24 do
    local a=n*math.pi/12
    local segment=part("RingArc",Vector3.new(.14,radius*math.pi/12+.035,.14),Vector3.new(math.cos(a)*radius,5+math.sin(a)*radius,-28),blue,Enum.Material.Neon)
    segment.CFrame=CFrame.new(origin+Vector3.new(math.cos(a)*radius,5+math.sin(a)*radius,-28))*CFrame.Angles(0,0,a);segment.Parent=ring
   end
   ring.WorldPivot=CFrame.new(origin+Vector3.new(0,5,-28));rings[i]=ring
  end
  local lamps,signs={},{}
  for i=1,7 do
   lamps[i]=part("StationLight"..i,Vector3.new(1.6,8,1.6),Vector3.new((i-4)*5,4,-47),gold,Enum.Material.Neon)
   signs[i]=textOn(part("StationName"..i,Vector3.new(4,1.1,.2),Vector3.new((i-4)*5,10,-47),black),tostring(i).." 站",gold)
  end
  local arm,head=person(Vector3.new(-9,0,-25));local shadow=part("OldShadow",Vector3.new(3.6,5.7,1.6),Vector3.new(-9,2.8,-26),Color3.fromRGB(44,3,7));shadow.Transparency=.18
  animate=function(t)
   local power=1-phase(t,7,12);core.Color=Color3.fromRGB(17,30,34):Lerp(Color3.fromRGB(95,231,207),power)
   for i,ring in ipairs(rings) do ring:PivotTo(CFrame.new(origin+Vector3.new(0,5,-28))*CFrame.Angles((10-(10-math.min(t,10))^2/10)*.25,i*math.pi/3,math.pi/3));for _,p in ipairs(ring:GetChildren()) do p.Transparency=.1+.9*(1-power) end end
   for i,p in ipairs(lamps) do local on=t<3+i*.85;p.Material=on and Enum.Material.Neon or Enum.Material.SmoothPlastic;p.Color=on and gold or Color3.fromRGB(25,29,36);signs[i].TextColor3=on and gold or Color3.fromRGB(65,69,78) end
   shadow.Transparency=.18+.82*phase(t,9,12);arm.CFrame=CFrame.new(origin+Vector3.new(-10.15,2.6,-25))
   local p=Vector3.new(18,8,4):Lerp(Vector3.new(-10,5,-13),phase(t,0,15));camera.CFrame=CFrame.lookAt(origin+p,origin+Vector3.new(-3*phase(t,8,12),4,-28))
   subtitle.Text=t<5 and "你關閉核心。七座車站的燈光，開始依序熄滅。" or t<10 and "環繞核心的光停止旋轉，循環終於中斷。" or "站務員恢復原貌：「謝謝你，終於有人讓這趟列車停下來。」"
  end
 else
  corridor(blue)
  local left=part("SealedLeft",Vector3.new(12,16,1),Vector3.new(-6,8,-37),Color3.fromRGB(29,40,64),Enum.Material.Metal)
  local right=part("SealedRight",left.Size,Vector3.new(6,8,-37),left.Color,Enum.Material.Metal)
  local sign=textOn(part("Station08Sign",Vector3.new(23,3,.6),Vector3.new(0,19,-37),black),"01 · 02 · 03 · 04 · 05 · 06 · 07",blue)
  local stars={}
  for i=1,90 do
   local a=i*2.399963;local r=5+(i%11)*1.6;local z=-42-i*.7
   local p=part("Star",Vector3.new(.1,.1,.6),Vector3.new(math.cos(a)*r,8+math.sin(a)*r,z),i%3==0 and Color3.fromRGB(180,119,255) or blue,Enum.Material.Neon);stars[i]=p
  end
  textOn(part("Destination",Vector3.new(24,5,1),Vector3.new(0,9,-104),black),"STATION 08",blue)
  for i=1,7 do part("Gateway",Vector3.new(34,1,1),Vector3.new(0,17,-44-i*8),i%2==0 and blue or Color3.fromRGB(166,99,250),Enum.Material.Neon) end
  animate=function(t)
   local count=math.clamp(math.floor((t-1)*1.4),0,7)
   if t<6.5 then local names={};for i=1,7 do names[i]=i<=count and "—" or string.format("%02d",i) end;sign.Text=table.concat(names," · ") else sign.Text="STATION 08" end
   local a=phase(t,6,10);left.CFrame=CFrame.new(origin+Vector3.new(-6-13*a,8,-37));right.CFrame=CFrame.new(origin+Vector3.new(6+13*a,8,-37))
   for i,p in ipairs(stars) do p.Transparency=.15+.35*(.5+.5*math.sin(t*1.7+i)) end
   camera.CFrame=CFrame.lookAt(origin+Vector3.new(0,6,8):Lerp(Vector3.new(0,7,-68),phase(t,3,15)),origin+Vector3.new(0,9,-104))
   subtitle.Text=t<6 and "封存檔案啟動。七個站名逐一消失。" or t<10 and "密封門後，浮現一條從未出現在路線圖上的月台。" or "「歡迎回來，調查員。」第八站正在等你。"
  end
 end
 started=os.clock()
 -- Rendering only changes movie props and the local camera, never the real train or character.
 connection=Run.RenderStepped:Connect(function()
  if not saved or not camera.Parent then dismiss();return end
  local t=os.clock()-started
  if t>=duration then finish();return end
  animate(t);skip.Visible=t>=2
  fade.BackgroundTransparency=math.clamp(math.min(t/.8,(duration-t)/.9),0,1)
 end)
end
local function handle(command)
 if command=="Skip" and gui:GetAttribute("State")=="Playing" and os.clock()-started>=2 then finish()
 elseif command=="Replay" and gui:GetAttribute("State")=="Card" then start(key)
 elseif command=="Close" and gui.Enabled then dismiss() end
end
action.Event:Connect(handle)
skip.Activated:Connect(function() handle("Skip") end)
replay.Activated:Connect(function() handle("Replay") end)
close.Activated:Connect(function() handle("Close") end)
Input.InputBegan:Connect(function(input,processed)
 if processed then return end
 if input.KeyCode==Enum.KeyCode.Space then handle("Skip") elseif input.KeyCode==Enum.KeyCode.Escape then handle(gui:GetAttribute("State")=="Card" and "Close" or "Skip") end
end)
player.CharacterAdded:Connect(dismiss)
shared.Remotes:WaitForChild("ObjectiveUpdate").OnClientEvent:Connect(function(_,_,completed,_,_,ending)
 if completed and titles[ending] and not seen then seen=true;task.defer(start,ending) end
end)
