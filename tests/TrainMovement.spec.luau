-- Execute the production travel method with a train that rejects movement.
local checks=0
local function check(ok,message) assert(ok,message);checks+=1 end
local clock=1000
local descriptor=nil
local attrs={DoorsOpen=false}
local train=setmetatable({GetAttribute=function(_,key) return attrs[key] end,
 SetAttribute=function(_,key,value) check(key=="TravelScene","Unexpected travel mutation");attrs[key]=value end,
 PivotTo=function() error("Passenger train was moved") end,
 GetPivot=function() return "fixed passenger frame" end},{__newindex=function() error("Passenger train property was changed") end})
local station=1
local gameMock={GetService=function(_,key)
 if key=="HttpService" then return {JSONEncode=function(_,data) descriptor=data;return "descriptor" end} end
 return {}
end}
local workspaceMock={GetServerTimeNow=function() return clock end,GetAttribute=function() return station end,
 BulkMoveTo=function() error("Travel must not batch-move passenger parts") end}
local Operations=(function(game,workspace,task)
-- MODULE_UNDER_TEST
end)(gameMock,workspaceMock,{wait=function(seconds) clock+=seconds end})
local op=setmetatable({Train=train,Moving=false},Operations)
for cycle=1,3 do
 for stop=1,6 do
  station=stop
  local start=clock
  op:Move(2800,42)
  check(clock==start+42,"Travel duration changed")
  check(descriptor.From==stop and descriptor.To==stop+1,"Wrong destination scene")
  check(descriptor.Distance==2800 and descriptor.Duration==42,"Wrong visual journey")
  check(descriptor.StartedAt==start,"Server clock was not shared")
  check(not op.Moving,"Moving flag stuck")
 end
end
attrs.DoorsOpen=true
check(not pcall(function() op:Move(2800,42) end),"Travel started with open doors")
attrs.DoorsOpen=false;op.Moving=true
check(not pcall(function() op:Move(2800,42) end),"Duplicate travel accepted")
op.Moving=false
check(not pcall(function() op:Move(2800,0) end),"Zero duration accepted")
print("LASTTRAIN_STATIONARY_LOGIC_PASS",checks,"checks; 18 journeys; train/character transforms forbidden")
