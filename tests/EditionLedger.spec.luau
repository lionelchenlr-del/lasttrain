local L=require("../LastTrain_Studio_Kit/src/ServerScriptService/LastTrain/EditionLedger")
local checks=0
local function check(v,m) assert(v,m);checks+=1 end
local ledger=L.Normalize(nil)
local serials={}
for user=1,500 do
 local serial=L.Reserve(ledger,user)
 check(serial and serial>=1 and serial<=500 and not serials[serial],"Duplicate serial")
 serials[serial]=true
 check(L.Reserve(ledger,user)==serial,"Reconnect lost reservation")
end
check(L.Reserve(ledger,501)==nil,"Allocated a 501st unit")
check(L.Confirm(ledger,501,"unreserved")==nil,"Unreserved receipt granted")
for user=500,1,-1 do
 local serial=ledger.Claims[tostring(user)].Serial
 check(L.Confirm(ledger,user,"receipt-"..user)==serial,"Receipt failed")
 check(L.Confirm(ledger,user,"receipt-"..user)==serial,"Retry changed serial")
 check(L.Confirm(ledger,user,"second-receipt-"..user)==serial,"Repeat receipt created another unit")
end
local status=L.Status(ledger)
check(status.Owned==500 and status.Reserved==0 and status.Available==0,"Wrong sold-out status")
ledger=L.Normalize(ledger)
check(L.Status(ledger).Owned==500,"Reload lost global editions")
local pending=L.Normalize(nil)
check(L.Reserve(pending,17)==1,"First reservation failed")
check(L.Status(pending).Reserved==1 and L.Status(pending).Owned==0,"Reservation counted as sold")
check(L.Confirm(pending,17,"")==nil,"Empty receipt granted")
for i=1,10000 do
 local user=(i*173)%701+1
 local before=L.Status(ledger)
 L.Reserve(ledger,user);L.Confirm(ledger,user,"retry-"..user)
 local after=L.Status(ledger)
 check(after.Owned+after.Reserved<=500 and after.Available>=0,"Concurrent-order oversell")
 check(after.Owned==before.Owned,"Sold-out replay changed ownership count")
end
print("LASTTRAIN_EDITION_LEDGER_PASS",checks,"global hard cap 500; reservations; idempotent serials; retries; reload")
