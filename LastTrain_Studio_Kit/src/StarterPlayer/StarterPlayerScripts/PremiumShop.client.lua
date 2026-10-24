local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Marketplace=game:GetService("MarketplaceService")
local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local p=Players.LocalPlayer
local Catalog=require(RS.LastTrain.Shared.PremiumCatalog)
local Appearance=require(RS.LastTrain.Shared.CharacterAppearance)
local Livery=require(RS.LastTrain.Shared.TrainLivery)
local TrainModelFactory=require(RS.LastTrain.Shared.TrainModelFactory)
local remotes=RS:WaitForChild("LastTrain"):WaitForChild("Remotes")
local request=remotes:WaitForChild("PremiumShopRequest")
local gui=Instance.new("ScreenGui");gui.Name="LastTrainPremiumShop";gui.ResetOnSpawn=false;gui.DisplayOrder=30;gui.Parent=p:WaitForChild("PlayerGui")
local navy=Color3.fromRGB(22,29,41);local orange=Color3.fromRGB(219,106,38);local white=Color3.fromRGB(248,247,242)
local function corner(v,r) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 10);c.Parent=v end
local function text(parent,name,value,pos,size,fontSize,color)
 local t=Instance.new("TextLabel");t.Name=name;t.Text=value;t.Position=pos;t.Size=size;t.Font=Enum.Font.GothamMedium;t.TextSize=fontSize or 14;t.TextColor3=color or navy;t.BackgroundTransparency=1;t.TextWrapped=true;t.TextXAlignment=Enum.TextXAlignment.Left;t.Parent=parent;return t
end
local function button(parent,name,value,pos,size)
 local b=Instance.new("TextButton");b.Name=name;b.Text=value;b.Position=pos;b.Size=size;b.BackgroundColor3=orange;b.TextColor3=white;b.Font=Enum.Font.GothamBold;b.TextSize=14;b.BorderSizePixel=0;b.Parent=parent;corner(b,8);return b
end
local open=button(gui,"OpenPremium","精品商店 [P]",UDim2.new(1,-174,0,76),UDim2.fromOffset(150,40))
local panel=Instance.new("Frame");panel.Name="PremiumPanel";panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.5);panel.Size=UDim2.fromScale(.9,.86);panel.BackgroundColor3=white;panel.Visible=false;panel.Parent=gui;corner(panel,14)
local limit=Instance.new("UISizeConstraint");limit.MinSize=Vector2.new(320,300);limit.MaxSize=Vector2.new(960,680);limit.Parent=panel
text(panel,"Title","末班精品  /  COLLECTION",UDim2.fromOffset(22,15),UDim2.new(1,-95,0,30),21)
local close=button(panel,"ClosePremium","×",UDim2.new(1,-53,0,15),UDim2.fromOffset(34,30));close.Modal=true
text(panel,"Subtitle","永久收藏 · 裝備與權益分開列明",UDim2.fromOffset(22,49),UDim2.new(1,-44,0,21),12,Color3.fromRGB(105,110,117))
local coinShop=button(panel,"CoinShop","車票幣服裝",UDim2.fromOffset(22,78),UDim2.fromOffset(128,29))
local invite=button(panel,"InviteRoyal","邀請同車朋友",UDim2.fromOffset(278,78),UDim2.fromOffset(166,29));invite.Visible=false
local party={};local inviteIndex=1
local fullButton=button(panel,"FullSizePreview","全尺寸展示",UDim2.fromOffset(454,78),UDim2.fromOffset(140,29))
local reset=button(panel,"DefaultLivery","白橘列車",UDim2.fromOffset(160,78),UDim2.fromOffset(106,29))
local cards=Instance.new("ScrollingFrame");cards.Name="Products";cards.BackgroundTransparency=1;cards.BorderSizePixel=0;cards.Position=UDim2.fromOffset(18,120);cards.Size=UDim2.new(.46,-20,1,-179);cards.ScrollBarThickness=4;cards.AutomaticCanvasSize=Enum.AutomaticSize.Y;cards.CanvasSize=UDim2.new();cards.Parent=panel
local layout=Instance.new("UIListLayout");layout.Padding=UDim.new(0,8);layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Parent=cards
local detailsScroll=Instance.new("ScrollingFrame");detailsScroll.Name="ProductDetails";detailsScroll.Position=UDim2.new(.46,8,0,120);detailsScroll.Size=UDim2.new(.54,-28,1,-160);detailsScroll.BackgroundTransparency=1;detailsScroll.BorderSizePixel=0;detailsScroll.ScrollBarThickness=3;detailsScroll.CanvasSize=UDim2.fromOffset(0,440);detailsScroll.Parent=panel
local viewport=Instance.new("ViewportFrame");viewport.Name="ProductPreview";viewport.Position=UDim2.fromOffset(0,0);viewport.Size=UDim2.new(1,-6,0,180);viewport.BackgroundColor3=Color3.fromRGB(224,228,231);viewport.Ambient=Color3.fromRGB(185,192,206);viewport.LightColor=Color3.fromRGB(255,241,217);viewport.LightDirection=Vector3.new(-1,-1,-2);viewport.Parent=detailsScroll;corner(viewport,10)
local camera=Instance.new("Camera");camera.FieldOfView=35;camera.Parent=viewport;viewport.CurrentCamera=camera
local preview=Instance.new("WorldModel");preview.Parent=viewport
local nameLabel=text(detailsScroll,"ProductName","",UDim2.fromOffset(2,194),UDim2.new(1,-10,0,34),20)
local detail=text(detailsScroll,"ProductDescription","",UDim2.fromOffset(2,233),UDim2.new(1,-10,0,65),13)
local choiceLabel=text(detailsScroll,"ChoiceLabel","",UDim2.fromOffset(2,308),UDim2.new(1,-10,0,30),12)
local cycle=button(detailsScroll,"CycleOption","切換選項",UDim2.fromOffset(2,345),UDim2.new(1,-10,0,30))
local action=button(detailsScroll,"PurchaseOrEquip","",UDim2.fromOffset(2,385),UDim2.new(1,-10,0,38))
local status=text(panel,"Status","",UDim2.fromOffset(22,0),UDim2.new(1,-44,0,30),12);status.Position=UDim2.new(0,22,1,-35)
local selected=Catalog.Order[1];local state=nil;local offers={};local buttons={};local optionIndex=1;local model=nil;local base=nil;local angle=.3;local dragging=false
local function options(key)
 if key=="RoyalCarriage" then return {"Royal","Taiwan"} end
 if key=="LiveryBundle" then return {"Sunrise","Midnight","Champagne"} end
 if key=="StarTrain" then return {"Starfield"} end
 if key=="NeonFlashlight" then return {"Ice","Amber","Violet","Standard"} end
 return {"Default"}
end
local function option() local list=options(selected);return list[(optionIndex-1)%#list+1] end
local function piece(parent,name,size,position,color,shape)
 local v=Instance.new("Part");v.Name=name;v.Size=size;v.Position=position;v.Color=color;v.Material=Enum.Material.SmoothPlastic;v.Anchored=true;v.CanCollide=false;v.Shape=shape or Enum.PartType.Block;v.Parent=parent;return v
end
local trainPhotoTemplate=nil
local trainPhoto=false
local previewBounds=Vector3.one
local function fitPreview()
 if not model or not base then return end
 local rotation=CFrame.Angles(trainPhoto and .28 or 0,angle,0)
 model:PivotTo(rotation*base)
 local aspect=math.max(viewport.AbsoluteSize.X/math.max(viewport.AbsoluteSize.Y,1),.5)
 local tangent=math.tan(math.rad(camera.FieldOfView/2));local distance=1
 for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do
  local v=rotation:VectorToWorldSpace(previewBounds*Vector3.new(x,y,z)/2)
  distance=math.max(distance,math.abs(v.Y)/tangent+v.Z,math.abs(v.X)/(tangent*aspect)+v.Z)
 end end end
 camera.CFrame=CFrame.lookAt(Vector3.new(0,0,distance*1.16),Vector3.zero)
end
local function makePreview()
 preview:ClearAllChildren();model=Instance.new("Model");model.Name="ProductModel";model.Parent=preview
 local item=Catalog.Items[selected]
 trainPhoto=not item.Skin and item.Kind~="Flashlight"
 if item.Skin and p.Character then
  local arch=p.Character.Archivable;p.Character.Archivable=true;local clone=p.Character:Clone();p.Character.Archivable=arch
  clone.Parent=model
  for _,d in ipairs(clone:GetDescendants()) do if d:IsA("LuaSourceContainer") or d:IsA("Tool") then d:Destroy() end end
  Appearance.Apply(clone,item.Skin)
  for _,d in ipairs(clone:GetDescendants()) do if d:IsA("BasePart") then d.Anchored=true;d.LocalTransparencyModifier=0 end end
  clone:PivotTo(CFrame.Angles(0,math.pi,0))
 elseif item.Kind=="Flashlight" then
  local body=piece(model,"FlashlightGrip",Vector3.new(2.8,.65,.65),Vector3.zero,navy,Enum.PartType.Cylinder);body.CFrame=CFrame.Angles(0,0,math.pi/2)
  local head=piece(model,"FlashlightHead",Vector3.new(.65,.95,.95),Vector3.new(0,1.35,0),Color3.fromRGB(52,63,75),Enum.PartType.Cylinder);head.CFrame=CFrame.new(head.Position)*CFrame.Angles(0,0,math.pi/2)
  local color=option()=="Amber" and Color3.fromRGB(255,193,99) or option()=="Violet" and Color3.fromRGB(172,156,255) or Color3.fromRGB(104,225,240)
  local ring=piece(model,"NeonRing",Vector3.new(.10,.98,.98),Vector3.new(0,1.70,0),color,Enum.PartType.Cylinder);ring.CFrame=CFrame.new(ring.Position)*CFrame.Angles(0,0,math.pi/2);ring.Material=Enum.Material.Neon
 else
  -- Cache an isolated coach so option changes do not rebuild the whole train.
  if not trainPhotoTemplate then
   local actual=TrainModelFactory.Build(nil)
   trainPhotoTemplate=actual:FindFirstChild("FrontCarriage")
   trainPhotoTemplate.Parent=nil;actual:Destroy()
  end
  local lead=trainPhotoTemplate:Clone();lead.Parent=model
  for _,d in ipairs(lead:GetDescendants()) do
   if d:IsA("JointInstance") or d:IsA("WeldConstraint") or d:IsA("LuaSourceContainer") or d:IsA("ProximityPrompt") then d:Destroy()
   elseif d:IsA("BasePart") then d.Anchored=true;d.CanCollide=false;d.CanTouch=false;d.CanQuery=false end
  end
  -- Preserve the coach name so the shared interior theme still recognizes it.
  local key=(item.Kind=="Livery" or item.Kind=="Royal") and option() or "Taiwan"
  Livery.Apply(model,key)

 end
 local box,size=model:GetBoundingBox()
 for _,part in ipairs(model:GetDescendants()) do if part:IsA("BasePart") then part.CFrame=part.CFrame-box.Position end end
 model.WorldPivot=CFrame.new();base=CFrame.new();angle=.3
 local _,bounds=model:GetBoundingBox();previewBounds=bounds
 angle=trainPhoto and -.85 or .3
 fitPreview()
end
local function render(rebuild)
 local item=Catalog.Items[selected];local owned=state and state.OwnedPasses[selected]
 local info=offers[selected]
 local serial=state and state.EditionSerials and state.EditionSerials.StarTrain
 nameLabel.Text=item.Name;detail.Text=item.Description
 local labels={Ice="冰藍光",Amber="暖橘光",Violet="紫羅蘭光",Standard="標準手電筒",Default="永久權益"}
 choiceLabel.Text=(Catalog.Liveries[option()] and Catalog.Liveries[option()].Name) or labels[option()] or ""
 if selected=="StarTrain" then
  local edition=info and info.Edition
  choiceLabel.Text=serial and string.format("永久編號 #%03d / 500",serial) or edition and edition.ReservedSerial and string.format("已保留 #%03d / 500，可繼續購買",edition.ReservedSerial) or edition and string.format("可保留 %d / 500 台 · 已領取 %d 台",edition.Available,edition.Owned) or "全球限量 500 台 · 庫存確認中"
 end
 invite.Visible=selected=="RoyalCarriage" and owned and workspace:GetAttribute("LastTrainMode")=="Game"
 invite.Text=party[inviteIndex] and ("邀請 "..party[inviteIndex].Name) or "尚無其他同車玩家"
 cycle.Visible=#options(selected)>1
 action.Text=info and info.Loading and "取得價格中…" or owned and (item.Kind=="Access" and "查看已解鎖權益" or "使用這個選項") or info and info.ForSale and ("購買 · "..tostring(info.Price).." R$") or "尚未上架 · 可預覽"
 if selected=="StarTrain" and not owned and info and info.Edition and info.Edition.Available==0 and not info.Edition.ReservedSerial then action.Text="500 台已額滿" end
 action.BackgroundColor3=owned and navy or orange
 for key,b in pairs(buttons) do
  b.BackgroundColor3=key==selected and Color3.fromRGB(232,224,211) or Color3.fromRGB(237,237,232)
  local offer=offers[key];b.Price.Text=offer and offer.Loading and "取得價格中…" or state and state.OwnedPasses[key] and "已擁有" or offer and offer.ForSale and (tostring(offer.Price).." R$") or ("預定 "..Catalog.Items[key].BasePrice.." R$ · 未上架")
 end
 if rebuild then makePreview() end
end
local personalQuotes={}
local function refresh()
 local ok,r=pcall(request.InvokeServer,request,"State")
 if ok and r and r.ok then
  state=r.state;offers=r.offers;party=r.party or {}
  for _,key in ipairs(Catalog.Order) do
   local id=Catalog.Items[key].ProductId or Catalog.Items[key].PassId
   if id>0 and offers[key] and offers[key].CheckoutEnabled~=false then
    local cached=personalQuotes[key]
    if cached and os.clock()-cached.At<120 then local quote=table.clone(cached);quote.Edition=offers[key] and offers[key].Edition;offers[key]=quote else
     offers[key]={Loading=true,ForSale=false}
     task.spawn(function()
      -- Client lookup reflects this player's regional pricing and discounts.
      local success,info=pcall(Marketplace.GetProductInfoAsync,Marketplace,id,Catalog.Items[key].ProductId and Enum.InfoType.Product or Enum.InfoType.GamePass)
      local amount=success and type(info)=="table" and tonumber(info.PriceInRobux) or nil
      local quote={At=os.clock(),Price=amount,ForSale=amount~=nil and info.IsForSale==true,Edition=offers[key] and offers[key].Edition}
      personalQuotes[key]=quote;offers[key]=quote;if panel.Visible then render(false) end
     end)
    end
   end
  end
  render(false)
 end
end
for i,key in ipairs(Catalog.Order) do
 local item=Catalog.Items[key];local b=button(cards,key,"",UDim2.new(),UDim2.new(1,-8,0,77));b.LayoutOrder=i;b.Text="";buttons[key]=b
 text(b,"Name",item.Name,UDim2.fromOffset(11,8),UDim2.new(1,-20,0,27),14)
 local price=text(b,"Price","預定 "..item.BasePrice.." R$ · 未上架",UDim2.fromOffset(11,39),UDim2.new(1,-20,0,25),12,Color3.fromRGB(111,91,67))
 b.Activated:Connect(function() selected=key;optionIndex=1;render(true) end)
end
local function visible(on)
 if on and (p:GetAttribute("PlatformTaskOpen") or p:GetAttribute("LastTrainCinematic")) then return end
 panel.Visible=on
 if on then refresh();render(true) else dragging=false end
end
-- A private display copy never moves or repaints the passenger train.
local display=nil;local savedCameraType=nil;local savedFov=nil;local controls=nil
local fullBar=Instance.new("Frame");fullBar.Name="FullPreviewControls";fullBar.AnchorPoint=Vector2.new(.5,0);fullBar.Position=UDim2.new(.5,0,0,12);fullBar.Size=UDim2.new(.94,0,0,76);fullBar.BackgroundColor3=navy;fullBar.Visible=false;fullBar.Parent=gui;corner(fullBar,10)
local barLimit=Instance.new("UISizeConstraint");barLimit.MaxSize=Vector2.new(650,76);barLimit.MinSize=Vector2.new(300,76);barLimit.Parent=fullBar
text(fullBar,"PreviewNotice","全尺寸外觀展示 · 不代表已解鎖",UDim2.fromOffset(16,8),UDim2.new(1,-32,0,23),13,white)
local exterior=button(fullBar,"Exterior","車頭與外觀",UDim2.new(.025,0,0,38),UDim2.new(.25,0,0,29))
local interior=button(fullBar,"Interior","車廂內裝",UDim2.new(.285,0,0,38),UDim2.new(.25,0,0,29))
local back=button(fullBar,"BackToShop","返回商店",UDim2.new(.725,0,0,38),UDim2.new(.25,0,0,29));back.Modal=true
local function cameraView(inside)
 if not display then return end
 local camera=workspace.CurrentCamera;camera.CameraType=Enum.CameraType.Scriptable;camera.FieldOfView=65
 if inside then camera.CFrame=CFrame.lookAt(Vector3.new(selected=="RoyalCarriage" and 78 or -4,204.2,0),Vector3.new(selected=="RoyalCarriage" and 94 or -26,selected=="RoyalCarriage" and 203.3 or 204.9,0))
 else camera.CFrame=CFrame.lookAt(Vector3.new(-116,207,-25),Vector3.new(-40,204,0)) end
end
local function closeDisplay()
 if display then display:Destroy();display=nil end
 fullBar.Visible=false;open.Visible=true
 local camera=workspace.CurrentCamera;camera.CameraType=savedCameraType or Enum.CameraType.Custom;camera.FieldOfView=savedFov or 70
 local character=p.Character;camera.CameraSubject=character and character:FindFirstChildWhichIsA("Humanoid")
 if controls then controls:Enable() end
 visible(true)
end
local function openDisplay()
 if display then display:Destroy();display=nil end
 local world=workspace:FindFirstChild("LastTrainWorld")
 local source=world and world:FindFirstChild("Props") and world.Props:FindFirstChild("LastTrainCar")
 local item=Catalog.Items[selected]
 if not source or (item.Kind~="Livery" and item.Kind~="Royal" and item.Kind~="Access") then status.Text="請在遊戲中選擇列車造型或車廂商品，再開啟全尺寸展示。";return end
 display=source:Clone();display.Name="PremiumFullPreview"
 for _,d in ipairs(display:GetDescendants()) do
  if d:IsA("JointInstance") or d:IsA("WeldConstraint") or d:IsA("LuaSourceContainer") or d:IsA("ProximityPrompt") then d:Destroy()
  elseif d:IsA("BasePart") then d.Anchored=true;d.CanCollide=false;d.CanTouch=false;d.CanQuery=false end
 end
 display:PivotTo(CFrame.new(0,200,0));Livery.Apply(display,item.Kind=="Access" and "Royal" or option())
 local ground=Instance.new("Part");ground.Name="DisplayGround";ground.Anchored=true;ground.CanCollide=false;ground.Size=Vector3.new(300,1,70);ground.Position=Vector3.new(0,197.6,0);ground.Color=Color3.fromRGB(31,39,53);ground.Material=Enum.Material.SmoothPlastic;ground.Parent=display
 display.Parent=workspace
 if not fullBar.Visible then savedCameraType=workspace.CurrentCamera.CameraType;savedFov=workspace.CurrentCamera.FieldOfView end
 controls=require(p.PlayerScripts:WaitForChild("PlayerModule")):GetControls();controls:Disable()
 panel.Visible=false;fullBar.Visible=true;open.Visible=false;cameraView(false)
end
fullButton.Activated:Connect(openDisplay)
exterior.Activated:Connect(function() cameraView(false) end)
interior.Activated:Connect(function() cameraView(true) end)
back.Activated:Connect(closeDisplay)
open.Activated:Connect(function() visible(not panel.Visible) end)
close.Activated:Connect(function() visible(false) end)
coinShop.Activated:Connect(function() visible(false);p.PlayerGui:SetAttribute("OpenLastTrainShop",true) end)
cycle.Activated:Connect(function() optionIndex+=1;render(true) end)
reset.Activated:Connect(function() local ok,r=pcall(request.InvokeServer,request,"ResetLivery");status.Text=ok and r.message or "連線忙碌。";refresh() end)
invite.Activated:Connect(function()
 local target=party[inviteIndex];if not target then status.Text="請與朋友加入同一趟列車。";return end
 local ok,r=pcall(request.InvokeServer,request,"Invite","RoyalCarriage",target.Id)
 status.Text=ok and r.message or "連線忙碌。";inviteIndex=inviteIndex%#party+1;render(false)
end)
local purchasePromptOpen=false
action.Activated:Connect(function()
 if purchasePromptOpen then status.Text="請先完成或關閉 Roblox 付款視窗。";return end
 local owned=state and state.OwnedPasses[selected]
 local ok,r=pcall(request.InvokeServer,request,owned and "Equip" or "Buy",selected,option())
 if not ok or not r then status.Text="連線忙碌，請稍後再試。";return end
 if r.ok and r.id then
  purchasePromptOpen=true
  local prompted,err=pcall(function()
   if r.promptType=="Product" then status.Text=string.format("已保留 #%03d / 500，請完成 Roblox 付款。",r.serial);Marketplace:PromptProductPurchase(p,r.id)
   else Marketplace:PromptGamePassPurchase(p,r.id) end
  end)
  if not prompted then purchasePromptOpen=false;status.Text="付款視窗未能開啟，請稍後再試。";warn("LastTrain purchase prompt unavailable",err) end
 else status.Text=r.message or "完成。" end
 if r.state then state=r.state;render(false) end
end)
Marketplace.PromptGamePassPurchaseFinished:Connect(function(who,_,bought) if who==p then purchasePromptOpen=false;if bought then task.delay(1.5,refresh) end end end)
Marketplace.PromptProductPurchaseFinished:Connect(function(userId) if userId==p.UserId then purchasePromptOpen=false;task.delay(.5,refresh) end end)
remotes:WaitForChild("PremiumNotice").OnClientEvent:Connect(function(message,key)
 if Catalog.Items[key] then selected=key;optionIndex=1 end
 status.Text=message;visible(true)
end)
UIS.InputBegan:Connect(function(input,processed)
 if not processed and input.KeyCode==Enum.KeyCode.P then if fullBar.Visible then closeDisplay() else visible(not panel.Visible) end end
 if fullBar.Visible and input.KeyCode==Enum.KeyCode.Escape then closeDisplay() elseif panel.Visible and input.KeyCode==Enum.KeyCode.Escape then visible(false) end
end)
viewport.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=true end end)
UIS.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
UIS.InputChanged:Connect(function(input) if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then angle+=input.Delta.X*.008 end end)
Run.RenderStepped:Connect(function(dt) if panel.Visible and model and base then if not dragging and not trainPhoto then angle+=dt*.15 end;fitPreview() end end)

p.PlayerGui:GetAttributeChangedSignal("OpenLastTrainPremium"):Connect(function()
 if p.PlayerGui:GetAttribute("OpenLastTrainPremium") then p.PlayerGui:SetAttribute("OpenLastTrainPremium",false);visible(true) end
end)

p.PlayerGui:GetAttributeChangedSignal("OpenLastTrainPremiumProduct"):Connect(function()
 local key=p.PlayerGui:GetAttribute("OpenLastTrainPremiumProduct")
 if Catalog.Items[key] then selected=key;optionIndex=1;p.PlayerGui:SetAttribute("OpenLastTrainPremiumProduct",nil);visible(true) end
end)

p.PlayerGui:GetAttributeChangedSignal("FullPreviewProduct"):Connect(function()
 local key=p.PlayerGui:GetAttribute("FullPreviewProduct")
 if key=="Close" then p.PlayerGui:SetAttribute("FullPreviewProduct",nil);closeDisplay();return end
 if Catalog.Items[key] then selected=key;optionIndex=1;p.PlayerGui:SetAttribute("FullPreviewProduct",nil);openDisplay() end
end)
p.PlayerGui:GetAttributeChangedSignal("FullPreviewInterior"):Connect(function() if p.PlayerGui:GetAttribute("FullPreviewInterior") then p.PlayerGui:SetAttribute("FullPreviewInterior",false);cameraView(true) end end)

for index,tab in ipairs({coinShop,reset,invite,fullButton}) do
 tab.Position=UDim2.new(.025+(index-1)*.24,0,0,78);tab.Size=UDim2.new(.22,0,0,29);tab.TextScaled=true
 local scaleLimit=Instance.new("UITextSizeConstraint");scaleLimit.MaxTextSize=14;scaleLimit.MinTextSize=10;scaleLimit.Parent=tab
end
