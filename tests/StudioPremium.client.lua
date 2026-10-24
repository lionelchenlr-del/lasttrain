local RS=game:GetService("ReplicatedStorage")
local p=game.Players.LocalPlayer
local Catalog=require(RS.LastTrain.Shared.PremiumCatalog)
local remote=RS.LastTrain.Remotes:WaitForChild("PremiumShopRequest")
local ack=RS:WaitForChild("PremiumTestAck")
local completed={}
local function phase()
 local current=workspace:GetAttribute("PremiumTestPhase")
 if not current or completed[current] then return end
 completed[current]=true
 if current=="Unowned" then
  task.wait(1)
  local r=remote:InvokeServer("State");assert(r.ok and #Catalog.Order==8,"Catalog request failed")
  for _,key in ipairs(Catalog.Order) do assert(not r.state.OwnedPasses[key] and not r.offers[key].ForSale,"Unlisted/ownership state incorrect") end
  task.wait(.3)
  local buy=remote:InvokeServer("Buy","StarTrain");assert(not buy.ok and not buy.id,"Unlisted pass allowed billing")
  task.wait(.3)
  local invalid=remote:InvokeServer("Equip","StarTrain","Starfield");assert(not invalid.ok,"Unowned equip allowed")
  ack:FireServer("Unowned")
 elseif current=="Owned" then
  task.wait(.3)
  local r=remote:InvokeServer("State");assert(r.ok,"Owned state missing")
  for _,key in ipairs(Catalog.Order) do assert(r.state.OwnedPasses[key],"Missing unlock: "..key) end
  ack:FireServer("Owned")
 elseif current=="Preview" then
  task.wait(.5);p.PlayerGui:SetAttribute("OpenLastTrainPremium",true)
 end
end
workspace:GetAttributeChangedSignal("PremiumTestPhase"):Connect(function() task.spawn(phase) end)
phase()
