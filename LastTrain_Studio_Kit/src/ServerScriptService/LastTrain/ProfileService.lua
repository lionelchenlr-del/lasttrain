-- All currency, unlock, and receipt mutations use UpdateAsync so the server owns the result.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("LastTrain"):WaitForChild("Shared"):WaitForChild("GameConfig"))
local CharacterAppearance = require(ReplicatedStorage.LastTrain.Shared:WaitForChild("CharacterAppearance"))
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
local Catalog=require(ReplicatedStorage.LastTrain.Shared.PremiumCatalog)
local Profiles = {}
local cache = {}
local locks = {}
local characterHooks = {}
local appearanceHooks = {}

local function normalize(raw)
    raw = type(raw) == "table" and raw or {}
    local result = {
        Coins = math.max(0, math.floor(tonumber(raw.Coins) or 0)),
        OwnedSkins = {},
        EquippedSkin = "PlatformWorker",
        ProcessedReceipts = {},
        OwnedPasses = {}, EditionSerials={}, EquippedLivery="Taiwan", EquippedFlashlight="Standard", FlashlightColor="Ice",
    }
    if type(raw.OwnedSkins) == "table" then
        for key, owned in pairs(raw.OwnedSkins) do
            if GameConfig.Skins[key] and owned == true then
                result.OwnedSkins[key] = true
            end
        end
    end
    local audio=type(raw.Audio)=="table" and raw.Audio or {}
    local function volume(value,default)
        return type(value)=="number" and value==value and math.clamp(value,0,1) or default
    end
    result.Audio={Music=volume(audio.Music,.45),Effects=volume(audio.Effects,.6),Muted=audio.Muted==true}
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
    if type(raw.OwnedPasses)=="table" then
        for key,owned in pairs(raw.OwnedPasses) do
            if Catalog.Items[key] and owned==true then result.OwnedPasses[key]=true end
        end
    end
    local serial=type(raw.EditionSerials)=="table" and tonumber(raw.EditionSerials.StarTrain)
    if serial and serial%1==0 and serial>=1 and serial<=500 then result.EditionSerials.StarTrain=serial end
    local livery=Catalog.Liveries[raw.EquippedLivery]
    if livery and (not livery.Pass or result.OwnedPasses[livery.Pass]) then result.EquippedLivery=raw.EquippedLivery end
    if result.OwnedPasses.NeonFlashlight and raw.EquippedFlashlight=="Neon" then result.EquippedFlashlight="Neon" end
    if raw.FlashlightColor=="Amber" or raw.FlashlightColor=="Violet" then result.FlashlightColor=raw.FlashlightColor end
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

    if character:GetAttribute("AppliedLastTrainSkin")~=skinKey then
        CharacterAppearance.Apply(character, skinKey)
        character:SetAttribute("AppliedLastTrainSkin",skinKey)
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
    for key in pairs(Catalog.Items) do player:SetAttribute("Owns_"..key,profile.OwnedPasses[key]==true) end
    player:SetAttribute("GalaxyEditionSerial",profile.EditionSerials.StarTrain)
    player:SetAttribute("EquippedLivery",profile.EquippedLivery)
    player:SetAttribute("EquippedFlashlight",profile.EquippedFlashlight)
    player:SetAttribute("FlashlightColor",profile.FlashlightColor)
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
        if not appearanceHooks[player.UserId] then
            appearanceHooks[player.UserId] = player.CharacterAppearanceLoaded:Connect(function(character)
                local latest = cache[player.UserId]
                if latest and player.Character == character then character:SetAttribute("AppliedLastTrainSkin",nil);applySkin(player, latest.EquippedSkin) end
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
    return { Audio=table.clone(profile.Audio), Coins=profile.Coins, OwnedSkins=owned, EquippedSkin=profile.EquippedSkin, OwnedPasses=table.clone(profile.OwnedPasses), EditionSerials=table.clone(profile.EditionSerials), EquippedLivery=profile.EquippedLivery, EquippedFlashlight=profile.EquippedFlashlight,FlashlightColor=profile.FlashlightColor }
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

function Profiles.SetAudioSettings(player,settings)
    return update(player.UserId,function(profile)
        profile.Audio={Music=settings.Music,Effects=settings.Effects,Muted=settings.Muted}
    end)
end

function Profiles.SetPass(player,key,owned)
    local item=Catalog.Items[key];if not item then return false end
    return update(player.UserId,function(profile)
        profile.OwnedPasses[key]=owned==true or nil
        if item.Skin then
            profile.OwnedSkins[item.Skin]=owned==true or nil
            if not owned and profile.EquippedSkin==item.Skin then profile.EquippedSkin="PlatformWorker" end
        end
        local livery=Catalog.Liveries[profile.EquippedLivery]
        if not owned and livery and livery.Pass==key then profile.EquippedLivery="Taiwan" end
        if not owned and key=="NeonFlashlight" then profile.EquippedFlashlight="Standard" end
    end)
end
function Profiles.EquipPremium(player,key,option)
    local item=Catalog.Items[key];if not item then return false,"找不到這個商品。" end
    local success,message=false,"尚未擁有這個商品。"
    local ok=update(player.UserId,function(profile)
        if not profile.OwnedPasses[key] then return end
        if item.Skin then profile.EquippedSkin=item.Skin
        elseif item.Kind=="Livery" or item.Kind=="Royal" then
            local livery=Catalog.Liveries[option]
            if not livery or (livery.Pass~=key and not (key=="RoyalCarriage" and option=="Taiwan")) then message="請選擇已解鎖的列車外觀。";return end
            profile.EquippedLivery=option
        elseif item.Kind=="Flashlight" then
            if option~="Ice" and option~="Amber" and option~="Violet" and option~="Standard" then message="找不到這種光色。";return end
            profile.EquippedFlashlight=option=="Standard" and "Standard" or "Neon"
            if option~="Standard" then profile.FlashlightColor=option end
        end
        success=true;message=item.Kind=="Access" and "已解鎖，請前往專屬座位區。" or "已套用；列車塗裝由房主在出發前決定。"
    end)
    return ok and success,ok and message or "資料儲存失敗，請稍後再試。"
end
function Profiles.GrantEdition(player,serial)
    if type(serial)~="number" or serial%1~=0 or serial<1 or serial>500 then return false end
    return update(player.UserId,function(profile)
        profile.OwnedPasses.StarTrain=true;profile.EditionSerials.StarTrain=serial
    end)
end
function Profiles.ResetLivery(player)
    return update(player.UserId,function(profile) profile.EquippedLivery="Taiwan" end)
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
    if appearanceHooks[player.UserId] then
        appearanceHooks[player.UserId]:Disconnect()
        appearanceHooks[player.UserId] = nil
    end
    if characterHooks[player.UserId] then
        characterHooks[player.UserId]:Disconnect()
        characterHooks[player.UserId] = nil
    end
end)

return Profiles
