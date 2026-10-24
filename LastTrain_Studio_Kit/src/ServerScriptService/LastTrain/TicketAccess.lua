-- Per-round, per-player state. This never reads a client-provided credential.
local Access={}
Access.__index=Access
function Access.new() return setmetatable({Records={}},Access) end
function Access:HasTicket(player)
 local r=self.Records[player]; return r~=nil and r.Collected==true
end
function Access:HasEntry(player)
 local r=self.Records[player]; return r~=nil and r.Validated==true
end
function Access:Collect(player)
 if self:HasTicket(player) then return false end
 self.Records[player]={Collected=true,Validated=false}; return true
end
function Access:Validate(player)
 if not self:HasTicket(player) then return false,false end
 local r=self.Records[player]; local first=not r.Validated
 r.Validated=true; return true,first
end
function Access:Forget(player) self.Records[player]=nil end
return Access
