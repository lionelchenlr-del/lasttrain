local Players=game:GetService("Players")
local Marketplace=game:GetService("MarketplaceService")
local RS=game:GetService("ReplicatedStorage")
local Catalog=require(RS.LastTrain.Shared.PremiumCatalog)
local Profiles=require(script.Parent.ProfileService)
local Edition=require(script.Parent.LimitedEdition)
local Release=require(script.Parent.ReleaseSettings)
local function billingReady()
 return Release.BillingEnabled==true and Release.UniverseId>0 and game.GameId==Release.UniverseId and not game:GetService("RunService"):IsStudio()
end
local remotes=RS:WaitForChild("LastTrain"):WaitForChild("Remotes")
local request=remotes:WaitForChild("PremiumShopRequest")
local notice=remotes:WaitForChild("PremiumNotice")
local prices,last={},{}
local function loaded(p)
 local deadline=os.clock()+20
 repeat if Profiles.IsLoaded(p) then return true end;task.wait(.1) until not p.Parent or os.clock()>deadline
 return false
end
local function offer(key)
 local item=Catalog.Items[key]
 local id=item.ProductId or item.PassId
 if not billingReady() then return {Price=item.BasePrice,ForSale=false,Planned=true,CheckoutEnabled=false} end
 if id<=0 then return {Price=item.BasePrice,ForSale=false,Planned=true} end
 local cached=prices[key]
 if cached and os.clock()-cached.At<120 then return cached end
 local ok,info=pcall(Marketplace.GetProductInfoAsync,Marketplace,id,item.ProductId and Enum.InfoType.Product or Enum.InfoType.GamePass)
 local amount=ok and type(info)=="table" and tonumber(info.PriceInRobux) or nil
 local result={At=os.clock(),Price=amount,ForSale=amount~=nil and info.IsForSale==true,Planned=false,CheckoutEnabled=true}
 prices[key]=result;return result
end
local function verify(p,key)
 local item=Catalog.Items[key];if not item or item.PassId<=0 then return end
 for attempt=1,3 do
  local ok,owned=pcall(Marketplace.UserOwnsGamePassAsync,Marketplace,p.UserId,item.PassId)
  if ok then if p.Parent then Profiles.SetPass(p,key,owned==true) end;return owned end
  task.wait(attempt*.4)
 end
 warn("LastTrain could not refresh pass ownership: "..key)
end
local function join(p)
 task.spawn(function()
  if not loaded(p) then return end
  for _,key in ipairs(Catalog.Order) do verify(p,key) end
  local serial=Edition.OwnedSerial(p.UserId);if serial then Profiles.GrantEdition(p,serial) end
 end)
end
Players.PlayerAdded:Connect(join);for _,p in ipairs(Players:GetPlayers()) do join(p) end
Marketplace.PromptGamePassPurchaseFinished:Connect(function(p,id,bought)
 if not bought then return end
 for key,item in pairs(Catalog.Items) do
  if item.PassId==id and id>0 then task.spawn(function()
   if verify(p,key) then notice:FireClient(p,item.Name.." 已解鎖，可在商店使用。",key) end
  end);return end
 end
end)
request.OnServerInvoke=function(p,action,key,option)
 if type(action)~="string" or not loaded(p) then return {ok=false,message="資料載入中，請稍後再試。"} end
 local now=os.clock()
 if now-(last[p] or 0)<.2 then return {ok=false,message="請稍候再操作。"} end
 last[p]=now
 if action=="State" then
  local offers={};for _,k in ipairs(Catalog.Order) do offers[k]=table.clone(offer(k)) end
  offers.StarTrain.Edition=Edition.Status(p.UserId)
  if not offers.StarTrain.Edition then offers.StarTrain.ForSale=false end
  local party={};for _,member in ipairs(Players:GetPlayers()) do if member~=p then table.insert(party,{Id=member.UserId,Name=member.DisplayName}) end end
  return {ok=true,state=Profiles.GetState(p),offers=offers,party=party}
 end
 if action=="ResetLivery" then local ok=Profiles.ResetLivery(p);return {ok=ok,message=ok and "已選擇白橘列車。" or "儲存失敗。"} end
 if type(key)~="string" or not Catalog.Items[key] then return {ok=false,message="找不到這個商品。"} end
 if action=="Invite" and key=="RoyalCarriage" then
  local state=Profiles.GetState(p);local target=Players:GetPlayerByUserId(type(option)=="number" and option%1==0 and option or 0)
  if workspace:GetAttribute("LastTrainMode")~="Game" or not state.OwnedPasses.RoyalCarriage or not target or target==p then return {ok=false,message="請邀請同車的朋友。"} end
  target:SetAttribute("RoyalGuestOf",p.UserId)
  notice:FireClient(target,p.DisplayName.." 邀請你使用本局皇家座位與茶飲吧。","RoyalCarriage")
  return {ok=true,message="已邀請 "..target.DisplayName.." 使用本局皇家設施。"}
 end
 if action=="Equip" then
  local ok,message=Profiles.EquipPremium(p,key,option)
  return {ok=ok,message=message,state=Profiles.GetState(p)}
 elseif action=="Buy" then
  local state=Profiles.GetState(p)
  if state.OwnedPasses[key] then return {ok=false,message="你已經擁有這個商品。"} end
  local current=offer(key)
  if not current.ForSale then return {ok=false,message="此商品尚未上架，目前可預覽內容。"} end
  if Catalog.Items[key].Limited then
   local existing=Edition.OwnedSerial(p.UserId)
   if existing then Profiles.GrantEdition(p,existing);return {ok=false,message="你已經擁有這個限定編號。",state=Profiles.GetState(p)} end
   local serial,message=Edition.Reserve(p.UserId)
   if not serial then return {ok=false,message=message} end
   return {ok=true,id=Catalog.Items[key].ProductId,promptType="Product",serial=serial}
  end
  return {ok=true,id=Catalog.Items[key].PassId,promptType="GamePass"}
 end
 return {ok=false,message="不支援的商店操作。"}
end
Players.PlayerRemoving:Connect(function(p) last[p]=nil end)
