assert(game:GetService("RunService"):IsStudio())
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Profiles=require(game.ServerScriptService.LastTrain.ProfileService)
local Catalog=require(RS.LastTrain.Shared.PremiumCatalog)
local ack=Instance.new("RemoteEvent");ack.Name="PremiumTestAck";ack.Parent=RS
local player
local phases={}
ack.OnServerEvent:Connect(function(p,phase) if p==player then phases[phase]=true end end)
local function waitFor(fn,message)
 local deadline=os.clock()+40
 repeat if fn() then return end;task.wait(.1) until os.clock()>deadline
 error(message)
end
waitFor(function() return #Players:GetPlayers()>0 end,"No client")
player=Players:GetPlayers()[1]
waitFor(function() return Profiles.IsLoaded(player) end,"Profile missing")
workspace:SetAttribute("PremiumTestPhase","Unowned")
waitFor(function() return phases.Unowned end,"Client unowned checks failed")
local ok=Profiles.EquipPremium(player,"StarTrain","Starfield")
assert(not ok,"Unowned livery equipped")
local Edition=require(game.ServerScriptService.LastTrain.LimitedEdition)
for _,key in ipairs(Catalog.Order) do
 if key=="StarTrain" then
  local serial=Edition.Reserve(player.UserId);assert(serial==1,"Edition reservation failed")
  assert(Edition.Confirm(player.UserId,"fixture-edition-receipt")==serial,"Edition receipt failed")
  assert(Edition.Confirm(player.UserId,"fixture-edition-receipt")==serial,"Edition receipt replay changed serial")
  assert(Profiles.GrantEdition(player,serial),"Edition profile grant failed")
 else assert(Profiles.SetPass(player,key,true),"Grant fixture failed: "..key) end
end
for _,key in ipairs(Catalog.Order) do
 local option=key=="RoyalCarriage" and "Royal" or key=="LiveryBundle" and "Midnight" or key=="StarTrain" and "Starfield" or key=="NeonFlashlight" and "Violet" or "Default"
 assert(Profiles.EquipPremium(player,key,option),"Equip failed: "..key)
end
local state=Profiles.GetState(player)
assert(state.EditionSerials.StarTrain==1,"Edition serial not restored in profile")
assert(state.EquippedLivery=="Starfield" and state.EquippedFlashlight=="Neon" and state.FlashlightColor=="Violet","Premium choices not persisted in profile")
assert(not Profiles.EquipPremium(player,"LiveryBundle","Starfield"),"Wrong bundle unlocked starfield")
local coins=state.Coins
assert(Profiles.GrantCoinsFromReceipt(player.UserId,"premium-regression",300))
assert(Profiles.GrantCoinsFromReceipt(player.UserId,"premium-regression",300))
assert(Profiles.GetState(player).Coins==coins+300,"Receipt double granted")
assert(Profiles.EquipPremium(player,"VIP","Default"))
workspace:SetAttribute("PremiumTestPhase","Owned")
waitFor(function() return phases.Owned end,"Client owned checks failed")
-- Verify the actual lobby access check with an unanchored live character.
local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
assert(root,"No character")
player.Character:PivotTo(CFrame.new(-59,3.5,56));task.wait(.5)
assert(root.Position.Z>46,"VIP rejected from lounge")
assert(Profiles.SetPass(player,"VIP",false))
task.wait(.6)
assert(root.Position.Z<46,"Unowned VIP lounge access accepted")
assert(Profiles.SetPass(player,"VIP",true))
assert(Profiles.EquipPremium(player,"VIP","Default"))
workspace:SetAttribute("PremiumTestPhase","Preview")
print("LASTTRAIN_PREMIUM_ALL_PASS eight entitlements; invalid equip; unlisted purchase rejected; profile equipment; receipt idempotency; native VIP access")
