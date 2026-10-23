-- All currency, unlock, and receipt mutations use UpdateAsync so the server owns the result.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("LastTrain"):WaitForChild("Shared"):WaitForChild("GameConfig"))
local isUnpublishedStudioTest = RunService:IsStudio() and game.PlaceId == 0
local Store
local storeOk, storeResult = pcall(function()
    return DataStoreService:GetDataStore(GameConfig.DataStoreName)
end)
if storeOk then
    Store = storeResult
elseif isUnpublishedStudioTest then
    warn("LastTrain: Studio test is using temporary in-memory player data; publish the experience to enable saving.")
else
    warn("LastTrain: DataStore is unavailable: " .. tostring(storeResult))
end
local Profiles = {}
local cache = {}
local locks = {}
local characterHooks = {}

local function normalize(raw)
    raw = type(raw) == "table" and raw or {}
    local result = {
        Coins = math.max(0, math.floor(tonumber(raw.Coins) or 0)),
        OwnedSkins = {},
        EquippedSkin = "PlatformWorker",
        ProcessedReceipts = {},
    }
    if type(raw.OwnedSkins) == "table" then
        for key, owned in pairs(raw.OwnedSkins) do
            if GameConfig.Skins[key] and owned == true then
                result.OwnedSkins[key] = true
            end
        end
    end
    result.OwnedSkins.PlatformWorker = true
    if type(raw.EquippedSkin) == "string" and GameConfig.Skins[raw.EquippedSkin] then
        result.EquippedSkin = raw.EquippedSkin
    end
    if not result.OwnedSkins[result.EquippedSkin] then
        result.EquippedSkin = "PlatformWorker"
    end
    if type(raw.ProcessedReceipts) == "table" then
        for purchaseId, processed in pairs(raw.ProcessedReceipts) do
            if processed == true and type(purchaseId) == "string" then
                result.ProcessedReceipts[purchaseId] = true
            end
        end
    end
    return result
end

local function applySkin(player, skinKey)
    local skin = GameConfig.Skins[skinKey]
    local character = player.Character
    if not skin or not character then return end

    player:SetAttribute("FlashlightMultiplier", skin.FlashlightMultiplier or 1)
    player:SetAttribute("MonsterDetectionMultiplier", skin.MonsterDetectionMultiplier or 1)
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if humanoid then humanoid.WalkSpeed = 16 * (skin.WalkSpeedMultiplier or 1) end

    local bodyColors = character:FindFirstChildOfClass("BodyColors")
    if not bodyColors then
        bodyColors = Instance.new("BodyColors")
        bodyColors.Parent = character
    end
    local main = skin.Colors.Main
    local accent = skin.Colors.Accent
    bodyColors.HeadColor3 = accent
    bodyColors.LeftArmColor3 = main
    bodyColors.RightArmColor3 = main
    bodyColors.LeftLegColor3 = main
    bodyColors.RightLegColor3 = main
    bodyColors.TorsoColor3 = main

    local oldVisuals = character:FindFirstChild("LastTrainSkinVisuals")
    if oldVisuals then oldVisuals:Destroy() end
    local visuals = Instance.new("Folder")
    visuals.Name = "LastTrainSkinVisuals"
    visuals.Parent = character
    local head = character:FindFirstChild("Head")
    local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")

    local function weldedPart(name, parentPart, size, color, shape, offset, material)
        if not parentPart then return end
        local visual = Instance.new("Part")
        visual.Name = name
        visual.Size = size
        visual.Color = color
        visual.Material = material or Enum.Material.SmoothPlastic
        visual.Shape = shape or Enum.PartType.Block
        visual.Anchored = false
        visual.Massless = true
        visual.CanCollide = false
        visual.CanTouch = false
        visual.CanQuery = false
        visual.CastShadow = true
        visual.CFrame = parentPart.CFrame * offset
        visual.Parent = visuals
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = parentPart
        weld.Part1 = visual
        weld.Parent = visual
        return visual
    end

    if skinKey == "PlatformWorker" then
        weldedPart("ReflectiveVestStripe", torso, Vector3.new(1.9, 0.16, 0.07), skin.Colors.Accent, Enum.PartType.Block, CFrame.new(0, 0.25, -0.38), Enum.Material.Neon)
    elseif skinKey == "Conductor" then
        weldedPart("ConductorCap", head, Vector3.new(1.35, 0.22, 1.12), skin.Colors.Main, Enum.PartType.Cylinder, CFrame.new(0, 0.43, 0) * CFrame.Angles(0, 0, math.rad(90)))
        weldedPart("CapVisor", head, Vector3.new(0.76, 0.1, 0.42), skin.Colors.Accent, Enum.PartType.Block, CFrame.new(0, 0.38, -0.47))
    elseif skinKey == "Signalman" then
        weldedPart("SignalHelmet", head, Vector3.new(1.25, 0.54, 1.12), skin.Colors.Main, Enum.PartType.Ball, CFrame.new(0, 0.43, 0))
        weldedPart("HelmetBand", head, Vector3.new(1.18, 0.1, 0.12), skin.Colors.Accent, Enum.PartType.Block, CFrame.new(0, 0.47, -0.49), Enum.Material.Neon)
    elseif skinKey == "NightGuard" then
        weldedPart("NightCap", head, Vector3.new(1.18, 0.34, 1.02), skin.Colors.Main, Enum.PartType.Cylinder, CFrame.new(0, 0.42, 0) * CFrame.Angles(0, 0, math.rad(90)))
        weldedPart("RedNeckScarf", torso, Vector3.new(1.45, 0.25, 0.32), skin.Colors.Accent, Enum.PartType.Block, CFrame.new(0, 0.47, -0.37), Enum.Material.Fabric)
    end

    if skin.ShirtTemplate and skin.ShirtTemplate > 0 then
        local shirt = character:FindFirstChildOfClass("Shirt") or Instance.new("Shirt")
        shirt.ShirtTemplate = "rbxassetid://" .. tostring(skin.ShirtTemplate)
        shirt.Parent = character
    end
    if skin.PantsTemplate and skin.PantsTemplate > 0 then
        local pants = character:FindFirstChildOfClass("Pants") or Instance.new("Pants")
        pants.PantsTemplate = "rbxassetid://" .. tostring(skin.PantsTemplate)
        pants.Parent = character
    end
end

local function syncPlayer(userId, profile)
    local player = Players:GetPlayerByUserId(userId)
    if not player then return end
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end
    local coins = leaderstats:FindFirstChild("車票幣")
    if not coins then
        coins = Instance.new("IntValue")
        coins.Name = "車票幣"
        coins.Parent = leaderstats
    end
    coins.Value = profile.Coins
    player:SetAttribute("EquippedSkin", profile.EquippedSkin)
    applySkin(player, profile.EquippedSkin)
end

local function update(userId, transform)
    while locks[userId] do task.wait(0.05) end
    locks[userId] = true
    if isUnpublishedStudioTest then
        local profile = normalize(cache[userId])
        local ok, err = pcall(transform, profile)
        locks[userId] = nil
        if not ok then
            warn("LastTrain local profile update failed for user " .. tostring(userId) .. ": " .. tostring(err))
            return false, nil
        end
        cache[userId] = profile
        syncPlayer(userId, profile)
        return true, profile
    end
    if not Store then
        locks[userId] = nil
        warn("LastTrain profile update skipped because DataStore is unavailable.")
        return false, nil
    end
    local ok, stored = pcall(function()
        return Store:UpdateAsync("u_" .. tostring(userId), function(current)
            local profile = normalize(current)
            transform(profile) -- Must remain non-yielding.
            return profile
        end)
    end)
    locks[userId] = nil
    if not ok then
        warn("LastTrain profile update failed for user " .. tostring(userId) .. ": " .. tostring(stored))
        return false, nil
    end
    local profile = normalize(stored)
    cache[userId] = profile
    syncPlayer(userId, profile)
    return true, profile
end

function Profiles.Load(player)
    if cache[player.UserId] then
        syncPlayer(player.UserId, cache[player.UserId])
        return true
    end
    local ok = update(player.UserId, function(_profile) end)
    if ok and player.Parent then
        if not characterHooks[player.UserId] then
            characterHooks[player.UserId] = player.CharacterAdded:Connect(function()
                task.wait(0.15)
                local latest = cache[player.UserId]
                if latest then applySkin(player, latest.EquippedSkin) end
            end)
        end
        if player.Character then applySkin(player, cache[player.UserId].EquippedSkin) end
    end
    return ok
end

function Profiles.IsLoaded(player)
    return cache[player.UserId] ~= nil
end

function Profiles.GetState(player)
    local profile = cache[player.UserId]
    if not profile then return nil end
    local owned = {}
    for key, value in pairs(profile.OwnedSkins) do owned[key] = value end
    return { Coins = profile.Coins, OwnedSkins = owned, EquippedSkin = profile.EquippedSkin }
end

function Profiles.AwardCoins(player, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    local ok = update(player.UserId, function(profile)
        profile.Coins += amount
    end)
    return ok
end

function Profiles.BuySkin(player, skinKey)
    local skin = GameConfig.Skins[skinKey]
    if not skin then return false, "找不到這個角色。" end
    if skin.RequiresGamePass then
        return false, "此角色需要使用 Robux 購買。"
    end
    local succeeded, message = false, "購買失敗，請稍後再試。"
    local ok = update(player.UserId, function(profile)
        if profile.OwnedSkins[skinKey] then
            succeeded, message = false, "你已經擁有這個角色。"
            return
        end
        local price = math.max(0, math.floor(skin.PriceCoins or 0))
        if profile.Coins < price then
            succeeded, message = false, "車票幣不足。"
            return
        end
        profile.Coins -= price
        profile.OwnedSkins[skinKey] = true
        succeeded, message = true, "角色已解鎖。"
    end)
    if not ok then return false, "資料儲存失敗，請稍後再試。" end
    return succeeded, message
end

function Profiles.EquipSkin(player, skinKey)
    if not GameConfig.Skins[skinKey] then return false, "找不到這個角色。" end
    local succeeded, message = false, "角色切換失敗。"
    local ok = update(player.UserId, function(profile)
        if not profile.OwnedSkins[skinKey] then
            succeeded, message = false, "你尚未解鎖這個角色。"
            return
        end
        profile.EquippedSkin = skinKey
        succeeded, message = true, "已切換角色。"
    end)
    if not ok then return false, "資料儲存失敗，請稍後再試。" end
    return succeeded, message
end

function Profiles.GrantSkin(player, skinKey)
    if not GameConfig.Skins[skinKey] then return false end
    local ok = update(player.UserId, function(profile)
        profile.OwnedSkins[skinKey] = true
    end)
    return ok
end

function Profiles.GrantCoinsFromReceipt(userId, purchaseId, amount)
    if type(purchaseId) ~= "string" or purchaseId == "" then return false end
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    local granted = false
    local ok = update(userId, function(profile)
        if profile.ProcessedReceipts[purchaseId] then
            granted = true -- Roblox may retry an already-completed receipt.
            return
        end
        profile.Coins += amount
        profile.ProcessedReceipts[purchaseId] = true
        granted = true
    end)
    return ok and granted
end

Players.PlayerRemoving:Connect(function(player)
    cache[player.UserId] = nil -- Every mutation is already committed through UpdateAsync.
    if characterHooks[player.UserId] then
        characterHooks[player.UserId]:Disconnect()
        characterHooks[player.UserId] = nil
    end
end)

return Profiles
