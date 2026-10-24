-- Pure global-edition ledger. Call mutations only inside one UpdateAsync key.
local Ledger={Limit=500}
function Ledger.Normalize(raw)
 raw=type(raw)=="table" and raw or {}
 local state={Version=1,Claims={}}
 local used={}
 if type(raw.Claims)=="table" then
  for user,claim in pairs(raw.Claims) do
   if type(user)=="string" and type(claim)=="table" and type(claim.Serial)=="number"
    and claim.Serial%1==0 and claim.Serial>=1 and claim.Serial<=Ledger.Limit and not used[claim.Serial] then
    state.Claims[user]={Serial=claim.Serial,Owned=claim.Owned==true,Receipt=type(claim.Receipt)=="string" and claim.Receipt or nil}
    used[claim.Serial]=true
   end
  end
 end
 return state
end
function Ledger.Status(state)
 local owned,reserved=0,0
 for _,claim in pairs(state.Claims) do if claim.Owned then owned+=1 else reserved+=1 end end
 return {Limit=Ledger.Limit,Owned=owned,Reserved=reserved,Available=Ledger.Limit-owned-reserved}
end
function Ledger.Reserve(state,userId)
 local key=tostring(userId);local claim=state.Claims[key]
 if claim then return claim.Serial,claim.Owned and "Owned" or "Reserved" end
 local used={};for _,c in pairs(state.Claims) do used[c.Serial]=true end
 for serial=1,Ledger.Limit do
  if not used[serial] then state.Claims[key]={Serial=serial,Owned=false};return serial,"Reserved" end
 end
 return nil,"SoldOut"
end
function Ledger.Confirm(state,userId,receipt)
 if type(receipt)~="string" or receipt=="" then return nil end
 local key=tostring(userId);local claim=state.Claims[key]
 -- No unreserved sale can create a 501st copy. Checkout is reserved before
 -- the experience is allowed to open Roblox's payment dialog.
 if not claim then return nil end
 if not claim.Owned then claim.Owned=true;claim.Receipt=receipt end
 return claim.Serial
end
return Ledger
