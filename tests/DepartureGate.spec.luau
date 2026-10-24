local Gate=require("../LastTrain_Studio_Kit/src/ServerScriptService/LastTrain/DepartureGate")
local checks=0
local function check(ok,message) assert(ok,message); checks+=1 end
local a,b,c={},{},{}
local aboard={}
local function contains(p) return aboard[p]==true end
local gate=Gate.new(0,8,3)
local function step(t,roster) return gate:Step(t,roster or {a,b},contains) end
check(not step(100,{}).Ready,"Empty server departed")
aboard[a]=true
for t=0,100 do check(not step(t).Ready,"Platform passenger left behind") end
aboard[b]=true
check(step(101).Seconds==3,"No boarding countdown")
check(not step(103.9).Ready,"Countdown ended early")
aboard[b]=false
check(step(104).State=="Boarding","Exit did not cancel countdown")
aboard[b]=true
check(step(105).Seconds==3,"Reboarding did not restart countdown")
check(step(108).Ready,"Boarded passengers never departed")
aboard[c]=false
check(not step(109,{a,b,c}).Ready,"Late joiner left behind")
check(not step(110,{a,b}).Ready,"Roster change skipped new countdown")
check(step(113,{a,b}).Ready,"Disconnected passenger blocked departure")
gate:ResetCountdown()
check(not step(114).Ready,"Reopened door did not reset countdown")
local first=Gate.new(0,8,3)
check(first:Step(2,{a},contains).State=="Dwell","Minimum station stop ignored")
check(first:Step(8,{a},contains).Seconds==3,"Dwell countdown missing")
check(not first:Step(10.99,{a},contains).Ready,"Dwell shortened countdown")
check(first:Step(11,{a},contains).Ready,"Dwell did not finish")
aboard[a]=false
check(not first:Step(12,{a},contains).Ready,"Dead/respawning passenger accepted")
print("LASTTRAIN_DEPARTURE_GATE_PASS",checks)
