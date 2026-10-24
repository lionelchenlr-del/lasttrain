-- Use the normal prompt input path, including its hold duration and server
-- distance checks. This local driver exists only in the disposable test place.
local RunService=game:GetService("RunService")
assert(RunService:IsStudio(),"Studio only")
local W=workspace:WaitForChild("LastTrainWorld")
local ack=game.ReplicatedStorage:WaitForChild("StoryTestAck")
game.ReplicatedStorage.LastTrain.Remotes:WaitForChild("TicketUpdate").OnClientEvent:Connect(function(data)
 if data.Anomaly then
  task.delay(.15,function()
   local text=data.Screen.ReaderDisplay.StatusText
   ack:FireServer("Anomaly",text.Text=="你已於二十年前進站")
  end)
  task.delay(1.5,function()
   local text=data.Screen.ReaderDisplay.StatusText
   ack:FireServer("AnomalyCleared",string.find(text.Text,"驗票成功",1,true)~=nil)
  end)
 end
end)
local last=nil
local function input()
 local token=workspace:GetAttribute("StoryTestToken")
 if not token or token==last then return end
 last=token
 local name=workspace:GetAttribute("StoryTestPrompt")
 local prompt=W:WaitForChild("Objectives"):WaitForChild(name):WaitForChild("ProximityPrompt")
 -- A neighboring Seat prompt otherwise competes for the same keyboard key.
 -- Aim at the target as a player would before using the normal hold input.
 prompt.Exclusivity=Enum.ProximityPromptExclusivity.AlwaysShow
 workspace.CurrentCamera.CameraType=Enum.CameraType.Scriptable
 workspace.CurrentCamera.CFrame=CFrame.lookAt(prompt.Parent.Position+Vector3.new(0,2,4),prompt.Parent.Position)
 task.wait(1)
 prompt:InputHoldBegin(); task.wait(prompt.HoldDuration+.3); prompt:InputHoldEnd()
 print("LASTTRAIN_STORY_CLIENT_INPUT",name)
 ack:FireServer("Input",token)
end
workspace:GetAttributeChangedSignal("StoryTestToken"):Connect(function() task.spawn(input) end)
input()
