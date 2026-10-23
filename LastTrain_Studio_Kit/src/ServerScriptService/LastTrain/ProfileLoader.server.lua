local Players = game:GetService("Players")
local Profiles = require(script.Parent:WaitForChild("ProfileService"))

local function onPlayerAdded(player)
    local ok = Profiles.Load(player)
    if not ok and player.Parent then
        player:Kick("無法載入遊戲資料，請重新加入。")
    end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(onPlayerAdded, player)
end
