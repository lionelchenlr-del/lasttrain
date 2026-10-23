-- The train is the only connection between platforms. Check actual position,
-- never a client-supplied attribute, when deciding whether someone is aboard.
local Safety={}
function Safety.ShouldRecover(position,aboard,station,config)
 local stationX=(station-1)*config.StationSpacing
 local inTunnel=not aboard and (math.abs(position.X-stationX)>config.PlatformHalfLength+5 or position.Y < -2.4)
 return inTunnel or position.Y < -8 or math.abs(position.Z)>45
  or position.X < -250 or position.X > config.StationSpacing*(#config.Stations-1)+250
end
return Safety
