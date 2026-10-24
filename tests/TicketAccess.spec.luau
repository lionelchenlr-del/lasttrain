local Access=require("../LastTrain_Studio_Kit/src/ServerScriptService/LastTrain/TicketAccess")
local a=Access.new()
local players={{},{},{},{}}
local checks=0
local function check(v,m) assert(v,m); checks+=1 end
for _,p in ipairs(players) do
 check(not a:HasTicket(p),"New passenger already has ticket")
 check(not a:HasEntry(p),"New passenger already validated")
 local ok,first=a:Validate(p)
 check(not ok and not first,"Validation without ticket succeeded")
end
for index,p in ipairs(players) do
 check(a:Collect(p),"Free collection failed")
 check(not a:Collect(p),"Collection repeated")
 check(a:HasTicket(p) and not a:HasEntry(p),"Collection granted entry")
 local ok,first=a:Validate(p)
 check(ok and first and a:HasEntry(p),"First validation failed")
 local again,replay=a:Validate(p)
 check(again and not replay,"Anomaly replayed")
 a:Collect(p)
 check(a:HasEntry(p),"Recollection revoked validation")
 for j=index+1,#players do check(not a:HasEntry(players[j]),"One ticket unlocked another passenger") end
end
local newRound=Access.new()
check(not newRound:HasEntry(players[1]),"Ticket survived into another round")
a:Forget(players[1])
check(not a:HasTicket(players[1]) and not a:HasEntry(players[1]),"Departed passenger retained")
check(a:HasEntry(players[2]),"Removing one passenger invalidated another")
print("LASTTRAIN_TICKET_ACCESS_PASS",checks)
