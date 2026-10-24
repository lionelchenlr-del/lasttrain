-- Server-owned departure decision. Missing/dead characters stay in the roster
-- until they respawn and board, or their player leaves the server.
local Gate={}
Gate.__index=Gate
function Gate.new(arrivalTime,minimumStop,countdown)
 return setmetatable({Arrival=arrivalTime,MinimumStop=minimumStop,Countdown=countdown,ReadySince=nil,Total=nil},Gate)
end
function Gate:ResetCountdown()
 self.ReadySince=nil
end
function Gate:Step(now,passengers,isAboard)
 local total,boarded=#passengers,0
 for _,passenger in ipairs(passengers) do if isAboard(passenger) then boarded+=1 end end
 if total~=self.Total then self.ReadySince=nil; self.Total=total end
 if total==0 or boarded~=total then
  self.ReadySince=nil
  return {State="Boarding",Ready=false,Boarded=boarded,Total=total}
 end
 if now<self.Arrival+self.MinimumStop then
  self.ReadySince=nil
  return {State="Dwell",Ready=false,Boarded=boarded,Total=total}
 end
 self.ReadySince=self.ReadySince or now
 local seconds=math.max(0,math.ceil(self.Countdown-(now-self.ReadySince)))
 return {State=seconds==0 and "Ready" or "Countdown",Ready=seconds==0,Seconds=seconds,Boarded=boarded,Total=total}
end
return Gate
