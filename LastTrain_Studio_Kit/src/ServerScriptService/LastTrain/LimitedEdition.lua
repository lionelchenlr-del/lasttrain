local DSS=game:GetService("DataStoreService")
local Run=game:GetService("RunService")
local Ledger=require(script.Parent.EditionLedger)
local Edition={}
local localOnly=Run:IsStudio() and game.PlaceId==0
local memory=Ledger.Normalize(nil)
local store
if not localOnly then
 local ok,result=pcall(DSS.GetDataStore,DSS,"LastTrain_LimitedEd_v1")
 if ok then store=result end
end
local function update(transform)
 if localOnly then local result=transform(memory);return true,result,memory end
 if not store then return false end
 local result
 local ok,state=pcall(function() return store:UpdateAsync("Galaxy500_v1",function(raw)
  local ledger=Ledger.Normalize(raw);result=transform(ledger);return ledger
 end) end)
 return ok,result,state
end
function Edition.Status(userId)
 local state
 if localOnly then state=memory else
  if not store then return nil end
  local ok,raw=pcall(store.GetAsync,store,"Galaxy500_v1");if not ok then return nil end
  state=Ledger.Normalize(raw)
 end
 local status=Ledger.Status(state)
 local claim=state.Claims[tostring(userId)]
 if claim and not claim.Owned then status.ReservedSerial=claim.Serial end
 return status
end
function Edition.Reserve(userId)
 local ok,serial=update(function(state) return Ledger.Reserve(state,userId) end)
 return ok and serial or nil,ok and "庫存已滿或編號已保留。" or "庫存連線忙碌，尚未開啟付款。"
end
function Edition.Confirm(userId,receipt)
 local ok,serial=update(function(state) return Ledger.Confirm(state,userId,receipt) end)
 return ok and serial or nil
end
function Edition.OwnedSerial(userId)
 if localOnly then local c=memory.Claims[tostring(userId)];return c and c.Owned and c.Serial or nil end
 if not store then return nil end
 local ok,raw=pcall(store.GetAsync,store,"Galaxy500_v1")
 if not ok then return nil end
 local c=Ledger.Normalize(raw).Claims[tostring(userId)]
 return c and c.Owned and c.Serial or nil
end
return Edition
