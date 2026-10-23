-- The public place is the lobby. Reserved servers are private round instances.
local Workspace = game:GetService("Workspace")
local mode = game.PrivateServerId ~= "" and "Game" or "Lobby"
Workspace:SetAttribute("LastTrainMode", mode)
