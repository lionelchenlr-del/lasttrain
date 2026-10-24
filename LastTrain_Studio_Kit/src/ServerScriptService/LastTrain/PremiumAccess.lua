local Players=game:GetService("Players")
local Profiles=require(script.Parent.ProfileService)
local Access={}
function Access.Has(player,key)
 if not key then return true end
 local state=Profiles.GetState(player)
 if state and state.OwnedPasses[key] then return true end
 if key=="RoyalCarriage" then
  local host=Players:GetPlayerByUserId(player:GetAttribute("RoyalGuestOf") or 0)
  local owner=host and Profiles.GetState(host)
  return owner~=nil and owner.OwnedPasses.RoyalCarriage==true
 end
 return false
end
return Access
