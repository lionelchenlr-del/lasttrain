local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Catalog=require(RS.LastTrain.Shared.PremiumCatalog)
local Livery=require(RS.LastTrain.Shared.TrainLivery)
local Profiles=require(script.Parent.ProfileService)
while workspace:GetAttribute("LastTrainMode")~="Game" do workspace:GetAttributeChangedSignal("LastTrainMode"):Wait() end
local w=workspace:WaitForChild("LastTrainWorld")
while not w:GetAttribute("Ready") do w:GetAttributeChangedSignal("Ready"):Wait() end
while #Players:GetPlayers()==0 do task.wait(.1) end
local first=Players:GetPlayers()[1]
local data=first:GetJoinData().TeleportData
local hostId=workspace:GetAttribute("LastTrainHostId") or (type(data)=="table" and tonumber(data.LastTrainHostId)) or first.UserId
workspace:SetAttribute("LastTrainHostId",hostId)
local chosen=false
local function choose(p)
 if chosen or p.UserId~=hostId then return end
 task.spawn(function()
  local deadline=os.clock()+25
  while not Profiles.IsLoaded(p) and p.Parent and os.clock()<deadline do task.wait(.1) end
  local state=Profiles.GetState(p);if not state then return end
  local key=state.EquippedLivery;local style=Catalog.Liveries[key]
  if style and style.Pass then
   local item=Catalog.Items[style.Pass]
   local ok,owned=false,false
   if item.Limited then ok=true;owned=require(script.Parent.LimitedEdition).OwnedSerial(p.UserId)~=nil
   elseif item.PassId>0 then ok,owned=pcall(game:GetService("MarketplaceService").UserOwnsGamePassAsync,game:GetService("MarketplaceService"),p.UserId,item.PassId) end
   if not ok or not owned then key="Taiwan" end
  end
  if workspace:GetAttribute("LastTrainStation")~=1 or workspace:GetAttribute("LastTrainBoardingPending") then return end
  Livery.Apply(w.Props.LastTrainCar,key)
  if key=="Starfield" then w.Props.LastTrainCar:SetAttribute("EditionSerial",state.EditionSerials.StarTrain) end
  chosen=true
 end)
end
Players.PlayerAdded:Connect(choose);for _,p in ipairs(Players:GetPlayers()) do choose(p) end
