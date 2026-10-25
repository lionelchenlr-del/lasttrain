-- Client-local cues; never grants progress, currency, or ownership.
local event=Instance.new("BindableEvent")
return {Event=event.Event,Play=function(key,pitch) event:Fire(key,pitch) end}
