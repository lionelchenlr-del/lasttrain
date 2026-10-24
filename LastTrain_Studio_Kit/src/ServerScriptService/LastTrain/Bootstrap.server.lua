local ReplicatedStorage = game:GetService("ReplicatedStorage")

local root = ReplicatedStorage:FindFirstChild("LastTrain")
if not root then
    root = Instance.new("Folder")
    root.Name = "LastTrain"
    root.Parent = ReplicatedStorage
end

local remotes = root:FindFirstChild("Remotes")
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name = "Remotes"
    remotes.Parent = root
end

local function ensure(className, name)
    local object = remotes:FindFirstChild(name)
    if not object then
        object = Instance.new(className)
        object.Name = name
        object.Parent = remotes
    end
    return object
end

ensure("RemoteEvent", "ObjectiveUpdate")
ensure("RemoteEvent", "TicketUpdate")
ensure("RemoteFunction", "ShopRequest")
ensure("RemoteFunction", "MatchmakingRequest")
ensure("RemoteEvent", "MatchmakingUpdate")
